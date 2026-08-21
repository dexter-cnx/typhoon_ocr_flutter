import 'document.dart';

class Passport extends TyphoonDocument {
  final String passportNo;
  final String type;
  final String countryCode;
  final String surname;
  final String givenNames;
  final String nationality;
  final String dob;
  final String placeOfBirth;
  final String sex;
  final String issueDate;
  final String expiryDate;
  final String authority;
  final String mrzLine1;
  final String mrzLine2;

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
