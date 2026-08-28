import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

class PdfOcrDemoPage extends StatefulWidget {
  const PdfOcrDemoPage({super.key});

  @override
  State<PdfOcrDemoPage> createState() => _PdfOcrDemoPageState();
}

class _PdfOcrDemoPageState extends State<PdfOcrDemoPage> {
  static const _pdfTypeGroup = XTypeGroup(
    label: 'PDF',
    extensions: <String>['pdf'],
    mimeTypes: <String>['application/pdf'],
    uniformTypeIdentifiers: <String>['com.adobe.pdf'],
  );

  String? _fileName;
  List<GeneralDocument> _pages = const [];
  String? _error;
  bool _loading = false;

  Future<void> _pickAndReadPdf() async {
    try {
      final selected = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[_pdfTypeGroup],
      );
      if (selected == null || !mounted) return;

      setState(() {
        _fileName = selected.name;
        _pages = const [];
        _error = null;
        _loading = true;
      });

      final ocr = TyphoonOCR.fromEnv();
      final pages = await ocr.extractFromPdf<GeneralDocument>(
        File(selected.path),
      );

      if (!mounted) return;
      setState(() => _pages = pages);
    } on TyphoonPdfPageException catch (error, stackTrace) {
      debugPrint('PDF OCR page failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError(
        'OCR failed on PDF page ${error.pageNumber}. No page was silently skipped.\n$error',
      );
    } on TyphoonPdfException catch (error, stackTrace) {
      debugPrint('PDF processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('Could not process the PDF.\n$error');
    } catch (error, stackTrace) {
      debugPrint('PDF picker/OCR failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('PDF OCR failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-page PDF OCR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Generic PDF demo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick any PDF to demonstrate extractFromPdf<GeneralDocument>(). '
              'Each source page is rasterized and OCR results are returned in '
              'the same order.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _pickAndReadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Pick PDF'),
            ),
            if (_fileName case final fileName?) ...[
              const SizedBox(height: 12),
              Text('Selected: $fileName'),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Reading PDF pages sequentially…'),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(error),
                ),
              ),
            ],
            if (_pages.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '${_pages.length} page${_pages.length == 1 ? '' : 's'} read',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _pages.length; index++)
                _PdfPageResultCard(
                  pageNumber: index + 1,
                  document: _pages[index],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PdfPageResultCard extends StatelessWidget {
  final int pageNumber;
  final GeneralDocument document;

  const _PdfPageResultCard({
    required this.pageNumber,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final markdown = document.rawMarkdown.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page $pageNumber',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 24),
            SelectableText(
                markdown.isEmpty ? 'No OCR text returned.' : markdown),
          ],
        ),
      ),
    );
  }
}
