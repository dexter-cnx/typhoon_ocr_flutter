import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

void main() {
  test('validates Thai ID checksum', () {
    expect(ThaiIdCard.isValidThaiId('1234567890121'), isTrue);
    expect(ThaiIdCard.isValidThaiId('1234567890123'), isFalse);
  });

  test('accepts separators when validating checksum', () {
    expect(ThaiIdCard.isValidThaiId('1-2345-67890-12-1'), isTrue);
  });
}
