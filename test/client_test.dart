import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

class _FakeProvider implements TyphoonProvider {
  String? prompt;
  String? mode;

  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async {
    this.prompt = prompt;
    this.mode = mode;
    return '{"id_number":"1234567890121","firstname_th":"สมชาย"}';
  }
}

class _SlowProvider implements TyphoonProvider {
  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return '{"id_number":"1234567890121"}';
  }
}

final class _CustomDocument extends TyphoonDocument {
  final String value;

  const _CustomDocument({
    required this.value,
    required super.rawMarkdown,
  });
}

void main() {
  test('infers Thai ID definition and returns typed result', () async {
    final provider = _FakeProvider();
    final ocr = TyphoonOCR(provider: provider);

    final card = await ocr.extract<ThaiIdCard>(File('unused.jpg'));

    expect(card.firstNameTh, 'สมชาย');
    expect(provider.mode, 'structure');
    expect(provider.prompt, contains('Thai national ID card'));
  });

  test('custom definition owns its prompt and mode', () async {
    final provider = _FakeProvider();
    final ocr = TyphoonOCR(
      provider: provider,
      definitions: {
        _CustomDocument: DocumentDefinition<_CustomDocument>(
          type: DocumentType.general,
          prompt: 'custom prompt',
          mode: 'custom-mode',
          decode: (raw) => _CustomDocument(value: raw, rawMarkdown: raw),
        ),
      },
    );

    await ocr.extract<_CustomDocument>(File('unused.jpg'));

    expect(provider.prompt, 'custom prompt');
    expect(provider.mode, 'custom-mode');
  });

  test('request options override prompt and mode without changing definition',
      () async {
    final provider = _FakeProvider();
    final ocr = TyphoonOCR(provider: provider);

    await ocr.extract<ThaiIdCard>(
      File('unused.jpg'),
      options: const ExtractionOptions(
        prompt: 'request prompt',
        mode: 'request-mode',
      ),
    );

    expect(provider.prompt, 'request prompt');
    expect(provider.mode, 'request-mode');

    await ocr.extract<ThaiIdCard>(File('unused.jpg'));
    expect(provider.prompt, contains('Thai national ID card'));
    expect(provider.mode, 'structure');
  });

  test('request timeout throws typed timeout exception', () async {
    final ocr = TyphoonOCR(provider: _SlowProvider());

    expect(
      () => ocr.extract<ThaiIdCard>(
        File('unused.jpg'),
        options: const ExtractionOptions(
          timeout: Duration(milliseconds: 1),
        ),
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

  test('fromEnv reads runtime environment for cloud provider', () {
    final ocr = TyphoonOCR.fromEnv(
      environment: {
        'TYPHOON_PROVIDER': 'cloud',
        'TYPHOON_API_KEY': 'test-key',
        'TYPHOON_MODEL': 'test-model',
      },
    );

    expect(ocr.provider, isA<OpentyphoonCloudProvider>());
    final provider = ocr.provider as OpentyphoonCloudProvider;
    expect(provider.apiKey, 'test-key');
    expect(provider.model, 'test-model');
  });

  test('fromEnv reads runtime environment for local provider', () {
    final ocr = TyphoonOCR.fromEnv(
      environment: {
        'TYPHOON_PROVIDER': 'local',
        'TYPHOON_BASE_URL': 'http://127.0.0.1:8000',
        'TYPHOON_MODEL': 'local-model',
      },
    );

    expect(ocr.provider, isA<LocalVllmProvider>());
  });
}
