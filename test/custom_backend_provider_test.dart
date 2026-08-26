import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

void main() {
  late Directory tempDir;
  late File image;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('typhoon_ocr_custom_test_');
    image = File('${tempDir.path}/receipt.png');
    await image.writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sends multipart fields, headers and image MIME type', () async {
    late http.Request capturedRequest;
    late String body;

    final client = MockClient((request) async {
      capturedRequest = request;
      body = latin1.decode(request.bodyBytes);
      return http.Response('{"markdown":"# OCR result"}', 200);
    });

    final provider = CustomBackendProvider(
      baseUrl: 'https://example.test/',
      headers: const {'Authorization': 'Bearer test-key'},
      client: client,
    );

    final raw = await provider.extractRaw(
      image: image,
      prompt: 'Extract receipt',
      mode: 'structure',
    );

    expect(capturedRequest.url.toString(), 'https://example.test/ocr');
    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.headers['Authorization'], 'Bearer test-key');
    expect(
      capturedRequest.headers['Content-Type'],
      startsWith('multipart/form-data;'),
    );
    expect(body, contains('name="prompt"'));
    expect(body, contains('Extract receipt'));
    expect(body, contains('name="mode"'));
    expect(body, contains('structure'));
    expect(body, contains('name="file"'));
    expect(body, contains('filename="receipt.png"'));
    expect(body, contains('Content-Type: image/png'));
    expect(raw, '# OCR result');
  });

  test('returns raw markdown when response is not JSON', () async {
    final client = MockClient(
      (_) async => http.Response('# raw markdown', 200),
    );
    final provider = CustomBackendProvider(
      baseUrl: 'https://example.test',
      client: client,
    );

    final raw = await provider.extractRaw(
      image: image,
      prompt: 'Extract',
      mode: 'text',
    );

    expect(raw, '# raw markdown');
  });

  for (final statusCode in <int>[400, 401, 500]) {
    test('maps HTTP $statusCode to TyphoonApiException', () async {
      final client = MockClient(
        (_) async => http.Response('{"error":"backend failure"}', statusCode),
      );
      final provider = CustomBackendProvider(
        baseUrl: 'https://example.test',
        client: client,
      );

      expect(
        () => provider.extractRaw(
          image: image,
          prompt: 'Extract',
          mode: 'structure',
        ),
        throwsA(
          isA<TyphoonApiException>()
              .having((error) => error.statusCode, 'statusCode', statusCode)
              .having(
                (error) => error.responseBody,
                'responseBody',
                contains('backend failure'),
              ),
        ),
      );
    });
  }

  test('maps timeout to TyphoonTimeoutException', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response('{}', 200);
    });
    final provider = CustomBackendProvider(
      baseUrl: 'https://example.test',
      client: client,
      timeout: const Duration(milliseconds: 1),
    );

    expect(
      () => provider.extractRaw(
        image: image,
        prompt: 'Extract',
        mode: 'structure',
      ),
      throwsA(
        isA<TyphoonTimeoutException>().having(
          (error) => error.timeout,
          'timeout',
          const Duration(milliseconds: 1),
        ),
      ),
    );
  });
}
