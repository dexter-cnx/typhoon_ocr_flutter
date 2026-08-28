import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

class _PdfProvider implements TyphoonProvider {
  final List<String> pagePayloads = [];
  int? failOnPage;

  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async {
    final payload = await image.readAsString();
    pagePayloads.add(payload);
    final page = pagePayloads.length;
    if (failOnPage == page) {
      throw const TyphoonParseException('bad page');
    }
    return '{"id_number":"123456789012$page","firstname_th":"$payload"}';
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

Stream<Uint8List> _threePdfPages(Uint8List bytes, double dpi) async* {
  expect(bytes, isNotEmpty);
  expect(dpi, 144);
  for (var page = 1; page <= 3; page++) {
    yield Uint8List.fromList(utf8.encode('page-$page'));
  }
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

  test('extractFromPdf preserves source page order and typed parsing',
      () async {
    final provider = _PdfProvider();
    final ocr = TyphoonOCR(
      provider: provider,
      pdfPageRasterizer: _threePdfPages,
    );
    final directory =
        await Directory.systemTemp.createTemp('typhoon_pdf_test_');
    final pdf = File('${directory.path}${Platform.pathSeparator}sample.pdf');
    await pdf.writeAsBytes([1, 2, 3]);

    try {
      final documents = await ocr.extractFromPdf<ThaiIdCard>(pdf);

      expect(documents, hasLength(3));
      expect(
        documents.map((document) => document.firstNameTh),
        ['page-1', 'page-2', 'page-3'],
      );
      expect(provider.pagePayloads, ['page-1', 'page-2', 'page-3']);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('extractFromPdf reports the one-based failing page', () async {
    final provider = _PdfProvider()..failOnPage = 2;
    final ocr = TyphoonOCR(
      provider: provider,
      pdfPageRasterizer: _threePdfPages,
    );
    final directory =
        await Directory.systemTemp.createTemp('typhoon_pdf_test_');
    final pdf = File('${directory.path}${Platform.pathSeparator}sample.pdf');
    await pdf.writeAsBytes([1]);

    try {
      await expectLater(
        ocr.extractFromPdf<ThaiIdCard>(pdf),
        throwsA(
          isA<TyphoonPdfPageException>()
              .having((error) => error.pageNumber, 'pageNumber', 2)
              .having(
                (error) => error.cause,
                'cause',
                isA<TyphoonParseException>(),
              ),
        ),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('extractFromPdf rejects an empty page stream', () async {
    Stream<Uint8List> emptyRasterizer(Uint8List bytes, double dpi) async* {}

    final ocr = TyphoonOCR(
      provider: _PdfProvider(),
      pdfPageRasterizer: emptyRasterizer,
    );
    final directory =
        await Directory.systemTemp.createTemp('typhoon_pdf_test_');
    final pdf = File('${directory.path}${Platform.pathSeparator}sample.pdf');
    await pdf.writeAsBytes([1]);

    try {
      await expectLater(
        ocr.extractFromPdf<ThaiIdCard>(pdf),
        throwsA(
          isA<TyphoonPdfException>().having(
            (error) => error.message,
            'message',
            contains('no rasterizable pages'),
          ),
        ),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('extractFromPdf validates DPI before rasterizing', () async {
    final ocr = TyphoonOCR(
      provider: _PdfProvider(),
      pdfPageRasterizer: _threePdfPages,
    );

    await expectLater(
      ocr.extractFromPdf<ThaiIdCard>(File('unused.pdf'), dpi: 0),
      throwsArgumentError,
    );
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
