import 'document.dart';

/// Typed passport OCR result, including identity fields and MRZ lines.
class Passport extends TyphoonDocument {
  /// Passport document number.
  final String passportNo;

  /// Passport document type code.
  final String type;

  /// Issuing country code.
  final String countryCode;

  /// Holder surname.
  final String surname;

  /// Holder given names.
  final String givenNames;

  /// Holder nationality code or label.
  final String nationality;

  /// Holder date of birth.
  final String dob;

  /// Holder place of birth.
  final String placeOfBirth;

  /// Holder sex marker.
  final String sex;

  /// Passport issue date.
  final String issueDate;

  /// Passport expiry date.
  final String expiryDate;

  /// Issuing authority.
  final String authority;

  /// First machine-readable zone line.
  final String mrzLine1;

  /// Second machine-readable zone line.
  final String mrzLine2;

  /// Creates a typed passport OCR result.
  const Passport({
    required this.passportNo,
    this.type = '',
    this.countryCode = '',
    this.surname = '',
    this.givenNames = '',
    this.nationality = '',
    this.dob = '',
    this.placeOfBirth = '',
    this.sex = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.authority = '',
    this.mrzLine1 = '',
    this.mrzLine2 = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [Passport] from parsed OCR JSON and the raw provider payload.
  factory Passport.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) =>
      Passport(
        passportNo: json['passport_no']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        countryCode: json['country_code']?.toString() ?? '',
        surname: json['surname']?.toString() ?? '',
        givenNames: json['given_names']?.toString() ?? '',
        nationality: json['nationality']?.toString() ?? '',
        dob: json['dob']?.toString() ?? '',
        placeOfBirth: json['place_of_birth']?.toString() ?? '',
        sex: json['sex']?.toString() ?? '',
        issueDate: json['issue_date']?.toString() ?? '',
        expiryDate: json['expiry_date']?.toString() ?? '',
        authority: json['authority']?.toString() ?? '',
        mrzLine1: json['mrz_line1']?.toString() ?? '',
        mrzLine2: json['mrz_line2']?.toString() ?? '',
        rawMarkdown: rawMarkdown,
        rawJson: rawJson,
        rawMap: Map<String, dynamic>.unmodifiable(json),
      );
}
