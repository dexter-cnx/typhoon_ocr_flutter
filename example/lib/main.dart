import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

import 'pdf_demo_page.dart';

void main() {
  runApp(const TyphoonOcrExampleApp());
}

class TyphoonOcrExampleApp extends StatelessWidget {
  const TyphoonOcrExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Typhoon OCR',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ThaiIdScanPage(),
    );
  }
}

class ThaiIdScanPage extends StatefulWidget {
  const ThaiIdScanPage({super.key});

  @override
  State<ThaiIdScanPage> createState() => _ThaiIdScanPageState();
}

class _ThaiIdScanPageState extends State<ThaiIdScanPage> {
  final _picker = ImagePicker();

  File? _image;
  ThaiIdCard? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _recoverLostPickerData();
  }

  Future<void> _recoverLostPickerData() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;

      if (response.exception case final exception?) {
        _showError('Could not recover camera result: $exception');
        return;
      }

      final files = response.files;
      if (files == null || files.isEmpty) {
        _showError(
          'The camera returned to the app, but no image could be recovered. '
          'Please scan the card again.',
        );
        return;
      }

      debugPrint(
        'Recovered image_picker result after Android process restart.',
      );
      await _scanImage(File(files.first.path));
    } catch (error, stackTrace) {
      debugPrint('Failed to recover image_picker data: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('Failed to recover camera result: $error');
    }
  }

  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2200,
      );
      if (picked == null) return;

      await _scanImage(File(picked.path));
    } catch (error, stackTrace) {
      debugPrint('Image picker failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('Could not open or read the selected image: $error');
    }
  }

  Future<void> _scanImage(File image) async {
    if (!mounted) return;

    setState(() {
      _image = image;
      _result = null;
      _error = null;
      _loading = true;
    });

    try {
      final ocr = TyphoonOCR.fromEnv();
      final result = await ocr.extract<ThaiIdCard>(image);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error, stackTrace) {
      debugPrint('Typhoon OCR failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('OCR failed: $error');
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

  void _openPdfDemo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PdfOcrDemoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Typhoon OCR example')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Thai ID image OCR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _PreviewCard(image: _image),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndScan(ImageSource.camera),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan card'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndScan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _openPdfDemo,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open multi-page PDF demo'),
            ),
            if (_loading) ...[
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Reading Thai ID card…'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(_error!),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 24),
              _ThaiIdResultCard(result: result),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final File? image;

  const _PreviewCard({required this.image});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 56),
                    SizedBox(height: 8),
                    Text('Place the whole ID card inside the frame'),
                  ],
                ),
              )
            : Image.file(image!, fit: BoxFit.cover),
      ),
    );
  }
}

class _ThaiIdResultCard extends StatelessWidget {
  final ThaiIdCard result;

  const _ThaiIdResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final valid = result.isValidId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'OCR result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Chip(
                  avatar: Icon(
                    valid
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                    size: 18,
                  ),
                  label: Text(valid ? 'Valid ID checksum' : 'Check ID number'),
                ),
              ],
            ),
            const Divider(height: 24),
            _field('ID number', result.idNumber),
            _field('Title', result.titleTh),
            _field('First name', result.firstNameTh),
            _field('Last name', result.lastNameTh),
            _field('Date of birth', result.dob),
            _field('Address', result.address),
            _field('Issue date', result.issueDate),
            _field('Expiry date', result.expiryDate),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: SelectableText(value.isEmpty ? '—' : value)),
          ],
        ),
      );
}
