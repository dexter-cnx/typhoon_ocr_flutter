import '../models/bank_slip.dart';
import '../models/passport.dart';
import '../models/receipt.dart';
import '../models/tabien_baan.dart';
import '../models/thai_driver_license.dart';
import '../models/thai_id_card.dart';
import '../models/thai_tax_invoice.dart';
import 'validation.dart';

/// Creates validators for all built-in structured document models.
Map<Type, DocumentValidator<dynamic>> createDefaultDocumentValidators() => {
      ThaiIdCard: const ThaiIdCardValidator(),
      ThaiDriverLicense: const ThaiDriverLicenseValidator(),
      ThaiTaxInvoice: const ThaiTaxInvoiceValidator(),
      TabienBaan: const TabienBaanValidator(),
      Receipt: const ReceiptValidator(),
      BankSlip: const BankSlipValidator(),
      Passport: const PassportValidator(),
    };

/// Validates fields and checksum invariants on a Thai ID card.
class ThaiIdCardValidator extends DocumentValidator<ThaiIdCard> {
  /// Creates a Thai ID card validator.
  const ThaiIdCardValidator();

  @override
  ValidationResult<ThaiIdCard> validate(ThaiIdCard document) {
    final issues = <ValidationIssue>[];
    final digits = document.idNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'thai_id.id_number.required',
          field: 'idNumber',
          message: 'Thai ID number is required.',
        ),
      );
    } else if (!document.isValidId) {
      issues.add(
        const ValidationIssue(
          code: 'thai_id.id_number.invalid_checksum',
          field: 'idNumber',
          message: 'Thai ID number does not pass the 13-digit checksum.',
        ),
      );
    }

    _requiredText(
      issues,
      document.firstNameTh,
      'firstNameTh',
      'thai_id.first_name.required',
    );
    _requiredText(
      issues,
      document.lastNameTh,
      'lastNameTh',
      'thai_id.last_name.required',
    );
    _warningText(issues, document.dob, 'dob', 'thai_id.dob.missing');

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates strong invariants on a Thai driver license without assuming one
/// historical card layout.
class ThaiDriverLicenseValidator extends DocumentValidator<ThaiDriverLicense> {
  /// Creates a Thai driver-license validator.
  const ThaiDriverLicenseValidator();

  @override
  ValidationResult<ThaiDriverLicense> validate(ThaiDriverLicense document) {
    final issues = <ValidationIssue>[];

    _requiredText(
      issues,
      document.licenseNumber,
      'licenseNumber',
      'thai_driver_license.number.required',
    );
    if (document.firstNameTh.trim().isEmpty && document.nameEn.trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'thai_driver_license.name.missing',
          message: 'No Thai or English driver name was extracted.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    _validateCompleteThaiId(
      issues,
      document.nationalId,
      field: 'nationalId',
      code: 'thai_driver_license.national_id.invalid_checksum',
    );

    final issueDate = _parseLooseDate(document.issueDate);
    final expiryDate = _parseLooseDate(document.expiryDate);
    if (issueDate != null && expiryDate != null && issueDate > expiryDate) {
      issues.add(
        const ValidationIssue(
          code: 'thai_driver_license.dates.invalid_order',
          field: 'expiryDate',
          message: 'License issue date is later than its expiry date.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates Thai tax IDs and invoice arithmetic using OCR-safe tolerances.
class ThaiTaxInvoiceValidator extends DocumentValidator<ThaiTaxInvoice> {
  /// Creates a Thai tax-invoice validator.
  const ThaiTaxInvoiceValidator();

  @override
  ValidationResult<ThaiTaxInvoice> validate(ThaiTaxInvoice document) {
    final issues = <ValidationIssue>[];

    _requiredText(
      issues,
      document.sellerName,
      'sellerName',
      'thai_tax_invoice.seller_name.required',
    );
    if (!document.total.isFinite || document.total <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'thai_tax_invoice.total.non_positive',
          field: 'total',
          message: 'Tax-invoice total must be finite and greater than zero.',
        ),
      );
    }
    if (!document.subtotal.isFinite || document.subtotal < 0) {
      issues.add(
        const ValidationIssue(
          code: 'thai_tax_invoice.subtotal.negative',
          field: 'subtotal',
          message: 'Tax-invoice subtotal must be finite and non-negative.',
        ),
      );
    }
    if (!document.vatAmount.isFinite || document.vatAmount < 0) {
      issues.add(
        const ValidationIssue(
          code: 'thai_tax_invoice.vat_amount.negative',
          field: 'vatAmount',
          message: 'VAT amount must be finite and non-negative.',
        ),
      );
    }
    if (!document.vatRate.isFinite || document.vatRate < 0) {
      issues.add(
        const ValidationIssue(
          code: 'thai_tax_invoice.vat_rate.negative',
          field: 'vatRate',
          message: 'VAT rate must be finite and non-negative.',
        ),
      );
    }

    _validateCompleteThaiId(
      issues,
      document.sellerTaxId,
      field: 'sellerTaxId',
      code: 'thai_tax_invoice.seller_tax_id.invalid_checksum',
    );
    _validateCompleteThaiId(
      issues,
      document.buyerTaxId,
      field: 'buyerTaxId',
      code: 'thai_tax_invoice.buyer_tax_id.invalid_checksum',
    );

    if (document.total.isFinite &&
        document.subtotal.isFinite &&
        document.vatAmount.isFinite &&
        document.total > 0 &&
        document.subtotal > 0 &&
        !_approximatelyEqual(
          document.subtotal + document.vatAmount,
          document.total,
        )) {
      issues.add(
        const ValidationIssue(
          code: 'thai_tax_invoice.total.inconsistent',
          field: 'total',
          message: 'Total is inconsistent with subtotal plus VAT amount.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    if (document.vatRate > 0 &&
        document.subtotal > 0 &&
        document.vatAmount >= 0) {
      final expectedVat = document.subtotal * document.vatRate / 100;
      if (!_approximatelyEqual(expectedVat, document.vatAmount)) {
        issues.add(
          const ValidationIssue(
            code: 'thai_tax_invoice.vat.inconsistent',
            field: 'vatAmount',
            message: 'VAT amount is inconsistent with subtotal and VAT rate.',
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    for (var index = 0; index < document.items.length; index++) {
      final item = document.items[index];
      if (item.name.trim().isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'thai_tax_invoice.item.name.required',
            field: 'items[$index].name',
            message:
                'Tax-invoice item name is required when an item is present.',
          ),
        );
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        issues.add(
          ValidationIssue(
            code: 'thai_tax_invoice.item.quantity.non_positive',
            field: 'items[$index].quantity',
            message: 'Item quantity must be finite and greater than zero.',
          ),
        );
      }
      if (!item.price.isFinite || item.price < 0) {
        issues.add(
          ValidationIssue(
            code: 'thai_tax_invoice.item.price.negative',
            field: 'items[$index].price',
            message: 'Item price must be finite and non-negative.',
          ),
        );
      }
    }

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates a Tabien Baan while preserving Bangkok/provincial address terms
/// and allowing partial-page scans.
class TabienBaanValidator extends DocumentValidator<TabienBaan> {
  /// Creates a Tabien Baan validator.
  const TabienBaanValidator();

  @override
  ValidationResult<TabienBaan> validate(TabienBaan document) {
    final issues = <ValidationIssue>[];

    if (document.houseCode.trim().isEmpty &&
        document.houseNumber.trim().isEmpty &&
        document.registrationNumber.trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'tabien_baan.house_identity.missing',
          message:
              'No house code, house number, or registration number was extracted.',
          severity: ValidationSeverity.warning,
        ),
      );
    }
    _warningText(
      issues,
      document.province,
      'province',
      'tabien_baan.province.missing',
    );

    for (var index = 0; index < document.members.length; index++) {
      final member = document.members[index];
      _validateCompleteThaiId(
        issues,
        member.nationalId,
        field: 'members[$index].nationalId',
        code: 'tabien_baan.member.national_id.invalid_checksum',
      );
      if (member.firstNameTh.trim().isEmpty &&
          member.lastNameTh.trim().isEmpty &&
          member.nationalId.trim().isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'tabien_baan.member.identity.missing',
            field: 'members[$index]',
            message: 'Household member has no extracted identity fields.',
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates monetary and line-item invariants on a receipt.
class ReceiptValidator extends DocumentValidator<Receipt> {
  /// Creates a receipt validator.
  const ReceiptValidator();

  @override
  ValidationResult<Receipt> validate(Receipt document) {
    final issues = <ValidationIssue>[];

    _requiredText(
      issues,
      document.merchantName,
      'merchantName',
      'receipt.merchant_name.required',
    );
    if (!document.total.isFinite || document.total <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.total.non_positive',
          field: 'total',
          message: 'Receipt total must be finite and greater than zero.',
        ),
      );
    }
    if (!document.subtotal.isFinite || document.subtotal < 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.subtotal.negative',
          field: 'subtotal',
          message: 'Receipt subtotal must be finite and cannot be negative.',
        ),
      );
    }
    if (!document.vat.isFinite || document.vat < 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.vat.negative',
          field: 'vat',
          message: 'Receipt VAT must be finite and cannot be negative.',
        ),
      );
    }

    for (var index = 0; index < document.items.length; index++) {
      final item = document.items[index];
      if (item.name.trim().isEmpty) {
        issues.add(
          ValidationIssue(
            code: 'receipt.item.name.required',
            field: 'items[$index].name',
            message: 'Receipt item name is required.',
          ),
        );
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        issues.add(
          ValidationIssue(
            code: 'receipt.item.quantity.non_positive',
            field: 'items[$index].quantity',
            message:
                'Receipt item quantity must be finite and greater than zero.',
          ),
        );
      }
      if (!item.price.isFinite || item.price < 0) {
        issues.add(
          ValidationIssue(
            code: 'receipt.item.price.negative',
            field: 'items[$index].price',
            message:
                'Receipt item price must be finite and cannot be negative.',
          ),
        );
      }
    }

    if (document.total.isFinite &&
        document.subtotal.isFinite &&
        document.vat.isFinite &&
        document.total > 0 &&
        document.subtotal > 0) {
      final expectedTotal = document.subtotal + document.vat;
      if (!_approximatelyEqual(expectedTotal, document.total)) {
        issues.add(
          const ValidationIssue(
            code: 'receipt.total.inconsistent',
            field: 'total',
            message: 'Receipt total is inconsistent with subtotal plus VAT.',
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates transfer amount and identity fields on a bank slip.
class BankSlipValidator extends DocumentValidator<BankSlip> {
  /// Creates a bank slip validator.
  const BankSlipValidator();

  @override
  ValidationResult<BankSlip> validate(BankSlip document) {
    final issues = <ValidationIssue>[];

    _requiredText(
      issues,
      document.fromBank,
      'fromBank',
      'bank_slip.from_bank.required',
    );
    _requiredText(
      issues,
      document.toBank,
      'toBank',
      'bank_slip.to_bank.required',
    );
    if (!document.amount.isFinite || document.amount <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'bank_slip.amount.non_positive',
          field: 'amount',
          message: 'Transfer amount must be finite and greater than zero.',
        ),
      );
    }
    if (!document.fee.isFinite || document.fee < 0) {
      issues.add(
        const ValidationIssue(
          code: 'bank_slip.fee.negative',
          field: 'fee',
          message: 'Transfer fee must be finite and cannot be negative.',
        ),
      );
    }
    _warningText(
      issues,
      document.currency,
      'currency',
      'bank_slip.currency.missing',
    );
    _warningText(
      issues,
      document.dateTime,
      'dateTime',
      'bank_slip.datetime.missing',
    );
    if (document.referenceNo.trim().isEmpty &&
        document.transactionId.trim().isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'bank_slip.reference.missing',
          message: 'No reference number or transaction ID was extracted.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    return ValidationResult(document: document, issues: issues);
  }
}

/// Validates passport identity fields and basic TD3 MRZ consistency.
class PassportValidator extends DocumentValidator<Passport> {
  /// Creates a passport validator.
  const PassportValidator();

  @override
  ValidationResult<Passport> validate(Passport document) {
    final issues = <ValidationIssue>[];
    final passportNo = document.passportNo.trim();

    if (passportNo.isEmpty) {
      issues.add(
        const ValidationIssue(
          code: 'passport.number.required',
          field: 'passportNo',
          message: 'Passport number is required.',
        ),
      );
    } else if (!RegExp(r'^[A-Za-z0-9]{5,12}$').hasMatch(passportNo)) {
      issues.add(
        const ValidationIssue(
          code: 'passport.number.invalid_format',
          field: 'passportNo',
          message: 'Passport number has an unexpected format.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    _requiredText(
      issues,
      document.surname,
      'surname',
      'passport.surname.required',
    );
    _requiredText(
      issues,
      document.givenNames,
      'givenNames',
      'passport.given_names.required',
    );

    final countryCode = document.countryCode.trim();
    if (countryCode.isNotEmpty &&
        !RegExp(r'^[A-Za-z]{3}$').hasMatch(countryCode)) {
      issues.add(
        const ValidationIssue(
          code: 'passport.country_code.invalid_format',
          field: 'countryCode',
          message: 'Passport country code should contain three letters.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    final sex = document.sex.trim().toUpperCase();
    if (sex.isNotEmpty && !const {'M', 'F', 'X', '<'}.contains(sex)) {
      issues.add(
        const ValidationIssue(
          code: 'passport.sex.invalid_value',
          field: 'sex',
          message: 'Passport sex marker has an unexpected value.',
          severity: ValidationSeverity.warning,
        ),
      );
    }

    final mrzLine1 = document.mrzLine1.trim();
    final mrzLine2 = document.mrzLine2.trim();
    if (mrzLine1.isNotEmpty && mrzLine1.length != 44) {
      issues.add(
        const ValidationIssue(
          code: 'passport.mrz_line1.invalid_length',
          field: 'mrzLine1',
          message: 'TD3 passport MRZ line 1 should contain 44 characters.',
          severity: ValidationSeverity.warning,
        ),
      );
    }
    if (mrzLine2.isNotEmpty && mrzLine2.length != 44) {
      issues.add(
        const ValidationIssue(
          code: 'passport.mrz_line2.invalid_length',
          field: 'mrzLine2',
          message: 'TD3 passport MRZ line 2 should contain 44 characters.',
          severity: ValidationSeverity.warning,
        ),
      );
    }
    if (passportNo.isNotEmpty && mrzLine2.isNotEmpty) {
      final normalizedMrz = mrzLine2.replaceAll('<', '').toUpperCase();
      final normalizedNumber =
          passportNo.replaceAll(RegExp(r'\s'), '').toUpperCase();
      if (!normalizedMrz.startsWith(normalizedNumber)) {
        issues.add(
          const ValidationIssue(
            code: 'passport.number.mrz_mismatch',
            field: 'passportNo',
            message: 'Passport number does not match MRZ line 2.',
            severity: ValidationSeverity.warning,
          ),
        );
      }
    }

    return ValidationResult(document: document, issues: issues);
  }
}

void _validateCompleteThaiId(
  List<ValidationIssue> issues,
  String value, {
  required String field,
  required String code,
}) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 13 && !ThaiIdCard.isValidThaiId(digits)) {
    issues.add(
      ValidationIssue(
        code: code,
        field: field,
        message: '$field does not pass the Thai 13-digit checksum.',
        severity: ValidationSeverity.warning,
      ),
    );
  }
}

void _requiredText(
  List<ValidationIssue> issues,
  String value,
  String field,
  String code,
) {
  if (value.trim().isEmpty) {
    issues.add(
      ValidationIssue(
        code: code,
        field: field,
        message: '$field is required.',
      ),
    );
  }
}

void _warningText(
  List<ValidationIssue> issues,
  String value,
  String field,
  String code,
) {
  if (value.trim().isEmpty) {
    issues.add(
      ValidationIssue(
        code: code,
        field: field,
        message: '$field was not extracted.',
        severity: ValidationSeverity.warning,
      ),
    );
  }
}

int? _parseLooseDate(String value) {
  final parts =
      RegExp(r'\d+').allMatches(value).map((m) => m.group(0)!).toList();
  if (parts.length < 3) return null;

  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  final third = int.tryParse(parts[2]);
  if (first == null || second == null || third == null) return null;

  late final int year;
  late final int month;
  late final int day;
  if (parts[0].length == 4) {
    year = first;
    month = second;
    day = third;
  } else {
    day = first;
    month = second;
    year = third;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return year * 10000 + month * 100 + day;
}

bool _approximatelyEqual(double left, double right) {
  final magnitude = left.abs() > right.abs() ? left.abs() : right.abs();
  final tolerance = magnitude * 0.02 > 0.01 ? magnitude * 0.02 : 0.01;
  return (left - right).abs() <= tolerance;
}
