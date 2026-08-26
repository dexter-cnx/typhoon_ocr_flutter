import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/src/parsers/parser.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

void main() {
  test('parses first valid JSON object from markdown', () {
    const raw = '''
metadata {not-json}
```json
{"id_number":"1234567890121","firstname_th":"กิติพงษ์"}
```
''';

    final result = TyphoonParser.parse<ThaiIdCard>(raw);

    expect(result.idNumber, '1234567890121');
    expect(result.firstNameTh, 'กิติพงษ์');
    expect(result.rawJson, contains('"id_number"'));
    expect(result.rawMap['firstname_th'], 'กิติพงษ์');
  });

  test('prefers document JSON over valid metadata JSON', () {
    const raw = '''
metadata {"a":1}
result {"id_number":"1234567890121","firstname_th":"กิติพงษ์"}
''';

    final result = TyphoonParser.parse<ThaiIdCard>(raw);

    expect(result.idNumber, '1234567890121');
    expect(result.firstNameTh, 'กิติพงษ์');
    expect(result.rawMap.containsKey('a'), isFalse);
  });

  test('prefers sparse Thai ID fields over preceding metadata JSON', () {
    const raw = '''
metadata {"a":1}
result {"dob":"1990-01-01","address":"Chiang Mai"}
''';

    final result = TyphoonParser.parse<ThaiIdCard>(raw);

    expect(result.dob, '1990-01-01');
    expect(result.address, 'Chiang Mai');
    expect(result.rawMap.containsKey('a'), isFalse);
  });

  test('prefers sparse receipt fields over preceding metadata JSON', () {
    const raw = '''
metadata {"a":1}
result {"branch":"CNX","vat":7,"payment_method":"QR"}
''';

    final result = TyphoonParser.parse<Receipt>(raw);

    expect(result.branch, 'CNX');
    expect(result.vat, 7);
    expect(result.paymentMethod, 'QR');
    expect(result.rawMap.containsKey('a'), isFalse);
  });

  test('prefers sparse bank slip fields over preceding metadata JSON', () {
    const raw = '''
metadata {"a":1}
result {"from_name":"Alice","fee":5,"reference":"REF123"}
''';

    final result = TyphoonParser.parse<BankSlip>(raw);

    expect(result.fromName, 'Alice');
    expect(result.fee, 5);
    expect(result.referenceNo, 'REF123');
    expect(result.rawMap.containsKey('a'), isFalse);
  });

  test('prefers sparse passport fields over preceding metadata JSON', () {
    const raw = '''
metadata {"a":1}
result {"nationality":"THA","authority":"MFA","expiry_date":"2030-01-01"}
''';

    final result = TyphoonParser.parse<Passport>(raw);

    expect(result.nationality, 'THA');
    expect(result.authority, 'MFA');
    expect(result.expiryDate, '2030-01-01');
    expect(result.rawMap.containsKey('a'), isFalse);
  });

  test('falls back to empty typed fields when JSON is invalid', () {
    final result = TyphoonParser.parse<ThaiIdCard>('no structured json');

    expect(result.idNumber, isEmpty);
    expect(result.rawMarkdown, 'no structured json');
    expect(result.rawMap, isEmpty);
  });

  test('parses richer receipt fields while preserving unknown data', () {
    const raw = '''
{"merchant_name":"Shop","branch":"CNX","subtotal":100,"vat":7,"total":107,
"payment_method":"QR","items":[{"name":"Tea","quantity":2,"price":50}],"custom":"kept"}
''';

    final receipt = TyphoonParser.parse<Receipt>(raw);

    expect(receipt.branch, 'CNX');
    expect(receipt.subtotal, 100);
    expect(receipt.vat, 7);
    expect(receipt.paymentMethod, 'QR');
    expect(receipt.items.single.quantity, 2);
    expect(receipt.rawMap['custom'], 'kept');
  });

  test('parses bank slip names, fee and transaction id', () {
    const raw = '''
{"from_bank":"A","to_bank":"B","from_name":"Alice","to_name":"Bob",
"amount":250.5,"fee":5,"currency":"THB","transaction_id":"TX123"}
''';

    final slip = TyphoonParser.parse<BankSlip>(raw);

    expect(slip.fromName, 'Alice');
    expect(slip.toName, 'Bob');
    expect(slip.fee, 5);
    expect(slip.currency, 'THB');
    expect(slip.transactionId, 'TX123');
  });

  test('preserves passport MRZ lines exactly', () {
    const raw = '''
{"passport_no":"AA1234567","mrz_line1":"P<THASURNAME<<GIVEN<NAMES<<<<<<<<<<<<",
"mrz_line2":"AA1234567<THA9001011M3001012<<<<<<<<<<<<<<04"}
''';

    final passport = TyphoonParser.parse<Passport>(raw);

    expect(passport.mrzLine1, contains('<<'));
    expect(passport.mrzLine2, startsWith('AA1234567<THA'));
  });

  test('parses fenced JSON with surrounding prose', () {
    const raw = '''
OCR completed successfully.
```json
{"merchant_name":"ร้านกาแฟ","total":120}
```
Please verify the extracted fields.
''';

    final receipt = TyphoonParser.parse<Receipt>(raw);

    expect(receipt.merchantName, 'ร้านกาแฟ');
    expect(receipt.total, 120);
    expect(receipt.rawMarkdown, raw);
  });

  test('keeps Thai Unicode payloads intact', () {
    const raw = '''
{"id_number":"1234567890121","firstname_th":"กิติพงษ์","lastname_th":"เชียงใหม่","address":"อำเภอเมือง จังหวัดเชียงใหม่"}
''';

    final card = TyphoonParser.parse<ThaiIdCard>(raw);

    expect(card.firstNameTh, 'กิติพงษ์');
    expect(card.lastNameTh, 'เชียงใหม่');
    expect(card.address, 'อำเภอเมือง จังหวัดเชียงใหม่');
  });

  test('respects braces and escaped quotes inside JSON strings', () {
    const raw = r'''
{"merchant_name":"Shop {CNX}","payment_method":"say \"QR\"","total":99}
''';

    final receipt = TyphoonParser.parse<Receipt>(raw);

    expect(receipt.merchantName, 'Shop {CNX}');
    expect(receipt.paymentMethod, 'say "QR"');
    expect(receipt.total, 99);
  });

  test('returns all valid top-level JSON objects in source order', () {
    const raw = '''
metadata {"source":"camera"}
result {"merchant_name":"Cafe","total":80}
trailing {"confidence":0.98}
''';

    final objects = TyphoonParser.jsonObjects(raw);

    expect(objects, hasLength(3));
    expect(objects[0].value['source'], 'camera');
    expect(objects[1].value['merchant_name'], 'Cafe');
    expect(objects[2].value['confidence'], 0.98);
  });

  test('skips malformed JSON and continues to a later valid object', () {
    const raw = '''
invalid {"merchant_name":"Broken",}
valid {"merchant_name":"Cafe","total":80}
''';

    final receipt = TyphoonParser.parse<Receipt>(raw);

    expect(receipt.merchantName, 'Cafe');
    expect(receipt.total, 80);
  });

  test('general document preserves raw markdown when no JSON exists', () {
    const raw = '# OCR result\nชื่อร้าน: ร้านกาแฟ\nยอดรวม: 120 บาท';

    final document = TyphoonParser.parse<GeneralDocument>(raw);

    expect(document.rawMarkdown, raw);
    expect(document.rawJson, isEmpty);
    expect(document.rawMap, isEmpty);
  });
}
