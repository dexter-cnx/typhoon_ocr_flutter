import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

void main() {
  group('ThaiIdCardValidator', () {
    test('accepts a valid Thai ID with required names', () {
      const document = ThaiIdCard(
        idNumber: '1234567890121',
        titleTh: 'นาย',
        firstNameTh: 'สมชาย',
        lastNameTh: 'ใจดี',
        dob: '01/01/2533',
        rawMarkdown: '',
      );
      final result = const ThaiIdCardValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.document, same(document));
    });

    test('reports required, checksum and optional-field findings', () {
      const missing = ThaiIdCard(
        idNumber: '',
        titleTh: '',
        firstNameTh: '',
        lastNameTh: '',
        rawMarkdown: '',
      );
      const invalid = ThaiIdCard(
        idNumber: '1234567890123',
        titleTh: 'นาย',
        firstNameTh: 'สมชาย',
        lastNameTh: 'ใจดี',
        dob: '01/01/2533',
        rawMarkdown: '',
      );
      final missingResult = const ThaiIdCardValidator().validate(missing);
      final invalidResult = const ThaiIdCardValidator().validate(invalid);
      expect(missingResult.isValid, isFalse);
      expect(
        missingResult.issues.map((issue) => issue.code),
        containsAll(<String>[
          'thai_id.id_number.required',
          'thai_id.first_name.required',
          'thai_id.last_name.required',
          'thai_id.dob.missing',
        ]),
      );
      expect(
        invalidResult.errors.single.code,
        'thai_id.id_number.invalid_checksum',
      );
    });
  });

  group('ReceiptValidator', () {
    test('accepts internally consistent receipt values', () {
      const document = Receipt(
        merchantName: 'Cafe',
        items: <ReceiptItem>[
          ReceiptItem(name: 'Tea', quantity: 2, price: 40),
        ],
        subtotal: 80,
        vat: 5.6,
        total: 85.6,
        rawMarkdown: '',
      );
      final result = const ReceiptValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('reports invalid money and line-item values', () {
      const document = Receipt(
        merchantName: '',
        items: <ReceiptItem>[
          ReceiptItem(name: '', quantity: 0, price: -1),
        ],
        subtotal: -1,
        vat: -1,
        total: 0,
        rawMarkdown: '',
      );
      final result = const ReceiptValidator().validate(document);
      final codes = result.issues.map((issue) => issue.code).toSet();
      expect(result.isValid, isFalse);
      expect(
        codes,
        containsAll(<String>{
          'receipt.merchant_name.required',
          'receipt.total.non_positive',
          'receipt.subtotal.negative',
          'receipt.vat.negative',
          'receipt.item.name.required',
          'receipt.item.quantity.non_positive',
          'receipt.item.price.negative',
        }),
      );
    });

    test('rejects non-finite monetary and line-item values', () {
      const document = Receipt(
        merchantName: 'Cafe',
        items: <ReceiptItem>[
          ReceiptItem(
            name: 'Tea',
            quantity: double.infinity,
            price: double.nan,
          ),
        ],
        subtotal: double.nan,
        vat: double.infinity,
        total: double.nan,
        rawMarkdown: '',
      );
      final result = const ReceiptValidator().validate(document);
      final codes = result.errors.map((issue) => issue.code).toSet();
      expect(result.isValid, isFalse);
      expect(
        codes,
        containsAll(<String>{
          'receipt.total.non_positive',
          'receipt.subtotal.negative',
          'receipt.vat.negative',
          'receipt.item.quantity.non_positive',
          'receipt.item.price.negative',
        }),
      );
    });

    test('warns when total disagrees with subtotal plus VAT', () {
      const document = Receipt(
        merchantName: 'Cafe',
        subtotal: 80,
        vat: 5,
        total: 100,
        rawMarkdown: '',
      );
      final result = const ReceiptValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(
        result.warnings.map((issue) => issue.code),
        contains('receipt.total.inconsistent'),
      );
    });

    test('does not infer whether item price is unit or line total', () {
      const document = Receipt(
        merchantName: 'Cafe',
        items: <ReceiptItem>[
          ReceiptItem(name: 'Tea', quantity: 2, price: 80),
        ],
        subtotal: 80,
        vat: 0,
        total: 80,
        rawMarkdown: '',
      );
      final result = const ReceiptValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });
  });

  group('BankSlipValidator', () {
    test('accepts complete transfer data', () {
      const document = BankSlip(
        fromBank: 'Bank A',
        toBank: 'Bank B',
        amount: 100,
        fee: 0,
        currency: 'THB',
        dateTime: '2026-08-26 10:00',
        referenceNo: 'REF123',
        rawMarkdown: '',
      );
      final result = const BankSlipValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('reports invalid required fields and missing metadata', () {
      const document = BankSlip(
        fromBank: '',
        toBank: '',
        amount: 0,
        fee: -1,
        rawMarkdown: '',
      );
      final result = const BankSlipValidator().validate(document);
      final codes = result.issues.map((issue) => issue.code).toSet();
      expect(result.isValid, isFalse);
      expect(
        codes,
        containsAll(<String>{
          'bank_slip.from_bank.required',
          'bank_slip.to_bank.required',
          'bank_slip.amount.non_positive',
          'bank_slip.fee.negative',
          'bank_slip.currency.missing',
          'bank_slip.datetime.missing',
          'bank_slip.reference.missing',
        }),
      );
    });

    test('rejects non-finite amount and fee values', () {
      const document = BankSlip(
        fromBank: 'Bank A',
        toBank: 'Bank B',
        amount: double.nan,
        fee: double.infinity,
        currency: 'THB',
        dateTime: '2026-08-26 10:00',
        referenceNo: 'REF123',
        rawMarkdown: '',
      );
      final result = const BankSlipValidator().validate(document);
      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        containsAll(<String>[
          'bank_slip.amount.non_positive',
          'bank_slip.fee.negative',
        ]),
      );
    });
  });

  group('PassportValidator', () {
    test('accepts complete passport data without validation errors', () {
      const document = Passport(
        passportNo: 'AA1234567',
        countryCode: 'THA',
        surname: 'DOE',
        givenNames: 'JOHN',
        sex: 'M',
        mrzLine1: 'P<THADOE<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
        mrzLine2: 'AA1234567<THA9001011M3001012<<<<<<<<<<<<<<04',
        rawMarkdown: '',
      );
      final result = const PassportValidator().validate(document);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports required fields and warns about suspicious formats', () {
      const requiredMissing = Passport(
        passportNo: '',
        surname: '',
        givenNames: '',
        rawMarkdown: '',
      );
      const suspicious = Passport(
        passportNo: 'A-1',
        countryCode: 'TH',
        surname: 'DOE',
        givenNames: 'JOHN',
        sex: 'UNKNOWN',
        mrzLine1: 'SHORT',
        mrzLine2: 'ZZZZZZZZZ',
        rawMarkdown: '',
      );
      final missingResult = const PassportValidator().validate(
        requiredMissing,
      );
      final suspiciousResult = const PassportValidator().validate(suspicious);
      final suspiciousCodes =
          suspiciousResult.warnings.map((issue) => issue.code).toSet();
      expect(missingResult.isValid, isFalse);
      expect(
        missingResult.errors.map((issue) => issue.code),
        containsAll(<String>[
          'passport.number.required',
          'passport.surname.required',
          'passport.given_names.required',
        ]),
      );
      expect(
        suspiciousCodes,
        containsAll(<String>{
          'passport.number.invalid_format',
          'passport.country_code.invalid_format',
          'passport.sex.invalid_value',
          'passport.mrz_line1.invalid_length',
          'passport.mrz_line2.invalid_length',
          'passport.number.mrz_mismatch',
        }),
      );
    });
  });

  group('TyphoonOCR validation registry', () {
    test('uses built-in validator and accepts unregistered documents', () {
      final client = TyphoonOCR(provider: _NoopProvider());
      const thaiId = ThaiIdCard(
        idNumber: '1234567890123',
        titleTh: '',
        firstNameTh: 'A',
        lastNameTh: 'B',
        dob: 'x',
        rawMarkdown: '',
      );
      const general = GeneralDocument(rawMarkdown: 'hello');
      expect(client.validate(thaiId).isValid, isFalse);
      expect(client.validate(general).isValid, isTrue);
      expect(client.validate(general).issues, isEmpty);
    });

    test('dispatches validation from the document runtime type', () {
      final client = TyphoonOCR(provider: _NoopProvider());
      const TyphoonDocument document = ThaiIdCard(
        idNumber: '1234567890123',
        titleTh: 'นาย',
        firstNameTh: 'A',
        lastNameTh: 'B',
        dob: 'x',
        rawMarkdown: '',
      );
      final result = client.validate(document);
      expect(result.isValid, isFalse);
      expect(
        result.errors.single.code,
        'thai_id.id_number.invalid_checksum',
      );
    });

    test('allows a custom validator to be registered immutably', () {
      final original = TyphoonOCR(provider: _NoopProvider());
      final customized = original.withValidator<_CustomDocument>(
        const _CustomValidator(),
      );
      const document = _CustomDocument(rawMarkdown: 'raw');
      expect(original.validate(document).isValid, isTrue);
      expect(customized.validate(document).isValid, isFalse);
      expect(
        customized.validate(document).errors.single.code,
        'custom.invalid',
      );
    });
  });
}

class _NoopProvider extends TyphoonProvider {
  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async =>
      '{}';
}

class _CustomDocument extends TyphoonDocument {
  const _CustomDocument({required super.rawMarkdown});
}

class _CustomValidator extends DocumentValidator<_CustomDocument> {
  const _CustomValidator();

  @override
  ValidationResult<_CustomDocument> validate(_CustomDocument document) {
    return ValidationResult<_CustomDocument>(
      document: document,
      issues: const <ValidationIssue>[
        ValidationIssue(code: 'custom.invalid', message: 'invalid'),
      ],
    );
  }
}
