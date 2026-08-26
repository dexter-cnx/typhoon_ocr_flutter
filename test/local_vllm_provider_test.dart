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
    tempDir = await Directory.systemTemp.createTemp('typhoon_ocr_local_test_');
    image = File('${tempDir.path}/document.webp');
    await image.writeAsBytes(<int>[0x52, 0x49, 0x46, 0x46]);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sends OpenAI-compatible local request with WebP MIME type', () async {
    late http.Request capturedRequest;
    late Map<String, dynamic> capturedBody;

    final client = MockClient((request) async {
      capturedRequest = request;
      capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': 'ok'},
            },
          ],
        }),
        200,
      );
    });

    final provider = LocalVllmProvider(
      baseUrl: 'http://localhost:8000/',
      modelName: 'typhoon-ocr',
      client: client,
    );

    final raw = await provider.extractRaw(
      image: image,
      prompt: 'Extract',
      mode: 'structure',
    );

    expect(
      capturedRequest.url.toString(),
      'http://localhost:8000/v1/chat/completions',
    );
    expect(capturedRequest.headers['Content-Type'], 'application/json');
    expect(capturedBody['model'], 'typhoon-ocr');

    final messages = capturedBody['messages'] as List<dynamic>;
    final content =
        (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;
    expect(
      (content[0] as Map<String, dynamic>)['text'],
      'Extract\nMode: structure',
    );
    final imageUrl =
        (content[1] as Map<String, dynamic>)['image_url']
            as Map<String, dynamic>;
    expect(imageUrl['url'], startsWith('data:image/webp;base64,'));
    expect(raw, 'ok');
  });

  test('maps malformed response to TyphoonParseException', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    final provider = LocalVllmProvider(
      baseUrl: 'http://localhost:8000',
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

  test('maps HTTP 500 to TyphoonApiException', () async {
    final client = MockClient((_) async => http.Response('failure', 500));
    final provider = LocalVllmProvider(
      baseUrl: 'http://localhost:8000',
      client: client,
    );

    expect(
      () => provider.extractRaw(
        image: image,
        prompt: 'Extract',
        mode: 'structure',
      ),
      throwsA(
        isA<TyphoonApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
  });

  test('maps timeout to TyphoonTimeoutException', () async {
    final client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response('{}', 200);
    });
    final provider = LocalVllmProvider(
      baseUrl: 'http://localhost:8000',
      client: client,
      timeout: const Duration(milliseconds: 1),
    );

    expect(
      () => provider.extractRaw(
        image: image,
        prompt: 'Extract',
        mode: 'structure',
      ),
      throwsA(isA<TyphoonTimeoutException>()),
    );
  });
}
