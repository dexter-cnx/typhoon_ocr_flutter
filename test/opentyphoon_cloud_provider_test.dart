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
    tempDir = await Directory.systemTemp.createTemp('typhoon_ocr_test_');
    image = File('${tempDir.path}/id-card.jpg');
    await image.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sends authenticated OpenAI-compatible OCR request', () async {
    late http.Request capturedRequest;
    late Map<String, dynamic> capturedBody;

    final client = MockClient((request) async {
      capturedRequest = request;
      capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '{"id_number":"123"}'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final provider = OpentyphoonCloudProvider(
      apiKey: 'test-key',
      baseUrl: 'https://example.test/v1/',
      model: 'typhoon-ocr',
      client: client,
    );

    final raw = await provider.extractRaw(
      image: image,
      prompt: 'Extract Thai ID',
      mode: 'structure',
    );

    expect(
      capturedRequest.url.toString(),
      'https://example.test/v1/chat/completions',
    );
    expect(capturedRequest.headers['Authorization'], 'Bearer test-key');
    expect(capturedRequest.headers['Content-Type'], startsWith('application/json'));
    expect(capturedBody['model'], 'typhoon-ocr');

    final messages = capturedBody['messages'] as List<dynamic>;
    final message = messages.single as Map<String, dynamic>;
    final content = message['content'] as List<dynamic>;

    final textPart = content[0] as Map<String, dynamic>;
    expect(textPart['text'], 'Extract Thai ID\nMode: structure');

    final imagePart = content[1] as Map<String, dynamic>;
    final imageUrl = imagePart['image_url'] as Map<String, dynamic>;
    expect(imageUrl['url'], startsWith('data:image/jpeg;base64,'));

    expect(raw, '{"id_number":"123"}');
  });

  test('changes cloud request text when mode changes', () async {
    final requestTexts = <String>[];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = body['messages'] as List<dynamic>;
      final message = messages.single as Map<String, dynamic>;
      final content = message['content'] as List<dynamic>;
      requestTexts.add((content[0] as Map<String, dynamic>)['text'] as String);

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': '{}'},
            },
          ],
        }),
        200,
      );
    });

    final provider = OpentyphoonCloudProvider(
      apiKey: 'test-key',
      baseUrl: 'https://example.test/v1',
      client: client,
    );

    await provider.extractRaw(
      image: image,
      prompt: 'Extract',
      mode: 'structure',
    );
    await provider.extractRaw(
      image: image,
      prompt: 'Extract',
      mode: 'text',
    );

    expect(requestTexts, <String>[
      'Extract\nMode: structure',
      'Extract\nMode: text',
    ]);
  });

  for (final statusCode in <int>[400, 401, 500]) {
    test('maps HTTP $statusCode to TyphoonApiException', () async {
      final client = MockClient(
        (_) async => http.Response('{"error":"provider failure"}', statusCode),
      );

      final provider = OpentyphoonCloudProvider(
        apiKey: 'test-key',
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
                contains('provider failure'),
              ),
        ),
      );
    });
  }

  test('maps provider timeout to TyphoonTimeoutException', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response('{}', 200);
    });

    final provider = OpentyphoonCloudProvider(
      apiKey: 'test-key',
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

  test('maps malformed JSON response to TyphoonParseException', () async {
    final client = MockClient((_) async => http.Response('not-json', 200));
    final provider = OpentyphoonCloudProvider(
      apiKey: 'test-key',
      client: client,
    );

    expect(
      () => provider.extractRaw(
        image: image,
        prompt: 'Extract',
        mode: 'structure',
      ),
      throwsA(isA<TyphoonParseException>()),
    );
  });

  test('rejects OpenAI-compatible response without choices', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    final provider = OpentyphoonCloudProvider(
      apiKey: 'test-key',
      client: client,
    );

    expect(
      () => provider.extractRaw(
        image: image,
        prompt: 'Extract',
        mode: 'structure',
      ),
      throwsA(isA<TyphoonParseException>()),
    );
  });
}
