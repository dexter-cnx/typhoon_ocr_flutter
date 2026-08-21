import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/src/providers/provider_utils.dart';

void main() {
  test('detects PNG MIME type', () {
    expect(imageMimeType(File('sample.png')), 'image/png');
  });

  test('detects WebP MIME type', () {
    expect(imageMimeType(File('sample.webp')), 'image/webp');
  });

  test('detects JPEG MIME type case-insensitively', () {
    expect(imageMimeType(File('sample.JPEG')), 'image/jpeg');
  });

  test('falls back for unknown extensions', () {
    expect(imageMimeType(File('sample.bin')), 'application/octet-stream');
  });
}
