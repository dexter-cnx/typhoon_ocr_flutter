import 'dart:convert';

import '../models/bank_slip.dart';
import '../models/document.dart';
import '../models/general_doc.dart';
import '../models/passport.dart';
import '../models/receipt.dart';
import '../models/tabien_baan.dart';
import '../models/thai_driver_license.dart';
import '../models/thai_id_card.dart';
import '../models/thai_tax_invoice.dart';

/// A decoded JSON object together with its exact source substring.
class ParsedJsonObject {
  /// Decoded JSON map.
  final Map<String, dynamic> value;

  /// Exact JSON substring extracted from the provider response.
  final String rawJson;

  /// Creates a parsed JSON object wrapper.
  const ParsedJsonObject(this.value, this.rawJson);
}

/// Parser that selects and decodes structured JSON from OCR responses.
class TyphoonParser {
  static const _thaiIdKeys = <String>{
    'id_number',
    'title_th',
    'firstname_th',
    'lastname_th',
    'dob',
    'address',
    'issue_date',
    'expiry_date',
  };

  static const _thaiDriverLicenseKeys = <String>{
    'license_number',
    'title_th',
    'firstname_th',
    'lastname_th',
    'name_en',
    'dob',
    'issue_date',
    'expiry_date',
    'license_class',
    'national_id',
    'issuing_authority',
  };

  static const _thaiTaxInvoiceKeys = <String>{
    'seller_name',
    'company_name',
    'seller_tax_id',
    'branch',
    'buyer_name',
    'buyer_tax_id',
    'invoice_number',
    'invoice_date',
    'items',
    'subtotal',
    'vat_rate',
    'vat_amount',
    'vat',
    'total',
    'currency',
  };

  static const _tabienBaanKeys = <String>{
    'registration_number',
    'book_number',
    'house_code',
    'house_number',
    'village',
    'building',
    'road',
    'subdistrict',
    'tambon',
    'khwaeng',
    'district',
    'amphoe',
    'khet',
    'province',
    'postal_code',
    'members',
    'registrar',
  };

  static const _receiptKeys = <String>{
    'merchant_name',
    'merchant',
    'branch',
    'date',
    'items',
    'subtotal',
    'vat',
    'total',
    'payment_method',
  };

  static const _bankSlipKeys = <String>{
    'from_bank',
    'to_bank',
    'from_account',
    'to_account',
    'from_name',
    'to_name',
    'amount',
    'fee',
    'currency',
    'datetime',
    'date_time',
    'reference_no',
    'reference',
    'ref',
    'transaction_id',
  };

  static const _passportKeys = <String>{
    'passport_no',
    'type',
    'country_code',
    'surname',
    'given_names',
    'nationality',
    'dob',
    'place_of_birth',
    'sex',
    'issue_date',
    'expiry_date',
    'authority',
    'mrz_line1',
    'mrz_line2',
  };

  /// Parses [raw] into the supported typed document [T].
  static T parse<T extends TyphoonDocument>(String raw) {
    final parsed = _bestJsonObjectFor<T>(raw);
    final json = parsed?.value ?? const <String, dynamic>{};
    final rawJson = parsed?.rawJson ?? '';

    if (T == ThaiIdCard) {
      return ThaiIdCard.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == ThaiDriverLicense) {
      return ThaiDriverLicense.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == ThaiTaxInvoice) {
      return ThaiTaxInvoice.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == TabienBaan) {
      return TabienBaan.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == Receipt) {
      return Receipt.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == BankSlip) {
      return BankSlip.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == Passport) {
      return Passport.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == GeneralDocument) {
      return GeneralDocument(
        rawMarkdown: raw,
        rawJson: rawJson,
        rawMap: Map<String, dynamic>.unmodifiable(json),
      ) as T;
    }

    throw UnsupportedError('No parser registered for document type $T.');
  }

  static ParsedJsonObject? _bestJsonObjectFor<T extends TyphoonDocument>(
    String raw,
  ) {
    final objects = jsonObjects(raw);
    if (objects.isEmpty) return null;

    final expectedKeys = _expectedKeysFor<T>();
    if (expectedKeys.isEmpty) return objects.first;

    ParsedJsonObject? best;
    var bestScore = 0;
    for (final object in objects) {
      final score = object.value.keys.where(expectedKeys.contains).length;
      if (score > bestScore) {
        best = object;
        bestScore = score;
      }
    }

    return best ?? objects.first;
  }

  static Set<String> _expectedKeysFor<T extends TyphoonDocument>() {
    if (T == ThaiIdCard) return _thaiIdKeys;
    if (T == ThaiDriverLicense) return _thaiDriverLicenseKeys;
    if (T == ThaiTaxInvoice) return _thaiTaxInvoiceKeys;
    if (T == TabienBaan) return _tabienBaanKeys;
    if (T == Receipt) return _receiptKeys;
    if (T == BankSlip) return _bankSlipKeys;
    if (T == Passport) return _passportKeys;
    return const <String>{};
  }

  /// Finds the first syntactically valid JSON object in a mixed markdown/text
  /// response.
  static ParsedJsonObject? firstJsonObject(String raw) {
    final objects = jsonObjects(raw);
    return objects.isEmpty ? null : objects.first;
  }

  /// Finds all top-level syntactically valid JSON objects embedded in mixed
  /// markdown/text while respecting braces inside JSON strings.
  static List<ParsedJsonObject> jsonObjects(String raw) {
    final objects = <ParsedJsonObject>[];
    var depth = 0;
    var inString = false;
    var escaped = false;
    int? start;

    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"' && depth > 0) {
        inString = true;
      } else if (char == '{') {
        if (depth == 0) {
          start = i;
        }
        depth++;
      } else if (char == '}' && depth > 0) {
        depth--;
        if (depth == 0 && start != null) {
          final candidate = raw.substring(start, i + 1);
          try {
            final decoded = jsonDecode(candidate);
            if (decoded is Map) {
              objects.add(
                ParsedJsonObject(
                  Map<String, dynamic>.from(decoded),
                  candidate,
                ),
              );
            }
          } on FormatException {
            // Keep scanning for a later valid top-level JSON object.
          }
          start = null;
        }
      }
    }

    return objects;
  }
}
