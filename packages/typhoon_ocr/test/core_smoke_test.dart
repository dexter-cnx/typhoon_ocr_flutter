import 'package:test/test.dart';
import 'package:typhoon_ocr/typhoon_ocr.dart';

void main() {
  test('core parses and validates Thai ID without Flutter', () {
    const raw =
        '{"id_number":"1234567890121","firstname_th":"สมชาย","lastname_th":"ใจดี","dob":"01/01/2533"}';
    final document = TyphoonParser.parse<ThaiIdCard>(raw);
    final result = const ThaiIdCardValidator().validate(document);

    expect(document.idNumber, '1234567890121');
    expect(result.isValid, isTrue);
  });
}
