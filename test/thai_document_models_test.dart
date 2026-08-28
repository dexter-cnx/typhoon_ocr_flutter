import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

void main() {
  group('ThaiDriverLicense', () {
    test('parses typed fields and raw map', () {
      const raw = '''
metadata {"request_id":"abc"}
{"license_number":"DL123","firstname_th":"สมชาย","lastname_th":"ใจดี","name_en":"SOMCHAI JAIDEE","dob":"01/01/2533","issue_date":"01/01/2567","expiry_date":"01/01/2572","license_class":"private","national_id":"1234567890121"}
''';

      final document = TyphoonParser.parse<ThaiDriverLicense>(raw);

      expect(document.licenseNumber, 'DL123');
      expect(document.firstNameTh, 'สมชาย');
      expect(document.nameEn, 'SOMCHAI JAIDEE');
      expect(document.rawMap['license_class'], 'private');
    });

    test('warns for reversed dates and invalid complete national ID', () {
      const document = ThaiDriverLicense(
        licenseNumber: 'DL123',
        firstNameTh: 'สมชาย',
        issueDate: '01/01/2572',
        expiryDate: '01/01/2567',
        nationalId: '1234567890123',
        rawMarkdown: '',
      );

      final result = const ThaiDriverLicenseValidator().validate(document);
      final codes = result.warnings.map((issue) => issue.code).toSet();

      expect(codes, contains('thai_driver_license.dates.invalid_order'));
      expect(
        codes,
        contains('thai_driver_license.national_id.invalid_checksum'),
      );
    });
  });

  group('ThaiTaxInvoice', () {
    test('parses items, VAT, totals, and tax IDs', () {
      const raw = '''
{"seller_name":"บริษัท ตัวอย่าง จำกัด","seller_tax_id":"1234567890121","branch":"สำนักงานใหญ่","buyer_name":"ลูกค้า","invoice_number":"INV-001","invoice_date":"2026-08-28","items":[{"name":"บริการ","quantity":1,"price":100}],"subtotal":100,"vat_rate":7,"vat_amount":7,"total":107,"currency":"THB"}
''';

      final document = TyphoonParser.parse<ThaiTaxInvoice>(raw);

      expect(document.sellerName, 'บริษัท ตัวอย่าง จำกัด');
      expect(document.items.single.name, 'บริการ');
      expect(document.vatRate, 7);
      expect(document.total, 107);
    });

    test('warns on inconsistent VAT arithmetic', () {
      const document = ThaiTaxInvoice(
        sellerName: 'บริษัท ตัวอย่าง จำกัด',
        subtotal: 100,
        vatRate: 7,
        vatAmount: 20,
        total: 120,
        rawMarkdown: '',
      );

      final result = const ThaiTaxInvoiceValidator().validate(document);

      expect(
        result.warnings.map((issue) => issue.code),
        contains('thai_tax_invoice.vat.inconsistent'),
      );
    });
  });

  group('TabienBaan', () {
    test('parses address aliases and preserves member order', () {
      const raw = '''
{"house_code":"12345678901","house_number":"99/1","khwaeng":"ลาดยาว","khet":"จตุจักร","province":"กรุงเทพมหานคร","members":[{"firstname_th":"สมชาย","lastname_th":"ใจดี"},{"firstname_th":"สมหญิง","lastname_th":"ใจดี"}]}
''';

      final document = TyphoonParser.parse<TabienBaan>(raw);

      expect(document.subdistrict, 'ลาดยาว');
      expect(document.district, 'จตุจักร');
      expect(document.members.map((member) => member.firstNameTh), [
        'สมชาย',
        'สมหญิง',
      ]);
    });

    test('allows partial scans with warnings instead of hard errors', () {
      const document = TabienBaan(rawMarkdown: 'partial page');

      final result = const TabienBaanValidator().validate(document);

      expect(result.isValid, isTrue);
      expect(result.warnings, isNotEmpty);
    });
  });

  test('default definitions register all new Thai document types', () {
    final definitions = createDefaultDocumentDefinitions();

    expect(definitions[ThaiDriverLicense]?.type, DocumentType.thaiDriverLicense);
    expect(definitions[ThaiTaxInvoice]?.type, DocumentType.thaiTaxInvoice);
    expect(definitions[TabienBaan]?.type, DocumentType.tabienBaan);
  });
}
