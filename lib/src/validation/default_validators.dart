import '../models/bank_slip.dart';
import '../models/passport.dart';
import '../models/receipt.dart';
import '../models/thai_id_card.dart';
import 'validation.dart';

/// Creates validators for all built-in structured document models.
Map<Type, DocumentValidator<dynamic>> createDefaultDocumentValidators() => {
      ThaiIdCard: const ThaiIdCardValidator(),
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
    if (document.total <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.total.non_positive',
          field: 'total',
          message: 'Receipt total must be greater than zero.',
        ),
      );
    }
    if (document.subtotal < 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.subtotal.negative',
          field: 'subtotal',
          message: 'Receipt subtotal cannot be negative.',
        ),
      );
    }
    if (document.vat < 0) {
      issues.add(
        const ValidationIssue(
          code: 'receipt.vat.negative',
          field: 'vat',
          message: 'Receipt VAT cannot be negative.',
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
      if (item.quantity <= 0) {
        issues.add(
          ValidationIssue(
            code: 'receipt.item.quantity.non_positive',
            field: 'items[$index].quantity',
            message: 'Receipt item quantity must be greater than zero.',
          ),
        );
      }
      if (item.price < 0) {
        issues.add(
          ValidationIssue(
            code: 'receipt.item.price.negative',
            field: 'items[$index].price',
            message: 'Receipt item price cannot be negative.',
          ),
        );
      }
    }

    if (document.total > 0 && document.subtotal > 0) {
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

    if (document.items.isNotEmpty && document.subtotal > 0) {
      final itemTotal = document.items.fold<double>(
        0,
        (sum, item) => sum + (item.quantity * item.price),
      );
      if (!_approximatelyEqual(itemTotal, document.subtotal)) {
        issues.add(
          const ValidationIssue(
            code: 'receipt.subtotal.items_mismatch',
            field: 'subtotal',
            message: 'Receipt subtotal does not match the extracted line items.',
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
    if (document.amount <= 0) {
      issues.add(
        const ValidationIssue(
          code: 'bank_slip.amount.non_positive',
          field: 'amount',
          message: 'Transfer amount must be greater than zero.',
        ),
      );
    }
    if (document.fee < 0) {
      issues.add(
        const ValidationIssue(
          code: 'bank_slip.fee.negative',
          field: 'fee',
          message: 'Transfer fee cannot be negative.',
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

bool _approximatelyEqual(double left, double right) {
  final magnitude = left.abs() > right.abs() ? left.abs() : right.abs();
  final tolerance = magnitude * 0.02 > 0.01 ? magnitude * 0.02 : 0.01;
  return (left - right).abs() <= tolerance;
}
