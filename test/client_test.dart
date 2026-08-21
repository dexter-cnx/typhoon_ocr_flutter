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
}
