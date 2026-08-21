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
}
