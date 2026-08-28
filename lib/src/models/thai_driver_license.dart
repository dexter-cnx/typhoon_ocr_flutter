import 'document.dart';

/// Typed OCR result for a Thai driver license.
class ThaiDriverLicense extends TyphoonDocument {
  /// Driver-license number as printed on the card.
  final String licenseNumber;

  /// Thai honorific or title.
  final String titleTh;

  /// Thai first name.
  final String firstNameTh;

  /// Thai last name.
  final String lastNameTh;

  /// English name when present.
  final String nameEn;

  /// Date of birth as returned by OCR.
  final String dateOfBirth;

  /// License issue date as returned by OCR.
  final String issueDate;

  /// License expiry date as returned by OCR.
  final String expiryDate;

  /// License class or type.
  final String licenseClass;

  /// Thai national ID when present.
  final String nationalId;

  /// Issuing authority or province when present.
  final String issuingAuthority;

  /// Creates a Thai driver-license result.
  const ThaiDriverLicense({
    required this.licenseNumber,
    this.titleTh = '',
    this.firstNameTh = '',
    this.lastNameTh = '',
    this.nameEn = '',
    this.dateOfBirth = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.licenseClass = '',
    this.nationalId = '',
    this.issuingAuthority = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [ThaiDriverLicense] from parsed OCR JSON.
  factory ThaiDriverLicense.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) =>
      ThaiDriverLicense(
        licenseNumber: json['license_number']?.toString() ?? '',
        titleTh: json['title_th']?.toString() ?? '',
        firstNameTh: json['firstname_th']?.toString() ?? '',
        lastNameTh: json['lastname_th']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        dateOfBirth: json['dob']?.toString() ?? '',
        issueDate: json['issue_date']?.toString() ?? '',
        expiryDate: json['expiry_date']?.toString() ?? '',
        licenseClass: json['license_class']?.toString() ?? '',
        nationalId: json['national_id']?.toString() ?? '',
        issuingAuthority: json['issuing_authority']?.toString() ?? '',
        rawMarkdown: rawMarkdown,
        rawJson: rawJson,
        rawMap: Map<String, dynamic>.unmodifiable(json),
      );
}
