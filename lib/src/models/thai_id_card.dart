import 'document.dart';

/// Structured OCR result for a Thai national identity card.
class ThaiIdCard extends TyphoonDocument {
  /// Thai national ID number.
  final String idNumber;

  /// Thai-language title, such as นาย, นาง, or นางสาว.
  final String titleTh;

  /// Thai-language first name.
  final String firstNameTh;

  /// Thai-language last name.
  final String lastNameTh;

  /// Date of birth text returned by OCR.
  final String dob;

  /// Address text returned by OCR.
  final String address;

  /// Card issue date text returned by OCR.
  final String issueDate;

  /// Card expiry date text returned by OCR.
  final String expiryDate;

  /// Creates a structured Thai ID card result.
  const ThaiIdCard({
    required this.idNumber,
    required this.titleTh,
    required this.firstNameTh,
    required this.lastNameTh,
    this.dob = '',
    this.address = '',
    this.issueDate = '',
    this.expiryDate = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [ThaiIdCard] from decoded Typhoon JSON output.
  factory ThaiIdCard.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) {
    return ThaiIdCard(
      idNumber: json['id_number']?.toString() ?? '',
      titleTh: json['title_th']?.toString() ?? '',
      firstNameTh: json['firstname_th']?.toString() ?? '',
      lastNameTh: json['lastname_th']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      issueDate: json['issue_date']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
      rawMarkdown: rawMarkdown,
      rawJson: rawJson,
      rawMap: Map<String, dynamic>.unmodifiable(json),
    );
  }

  /// Whether [idNumber] passes the standard Thai 13-digit checksum.
  bool get isValidId => isValidThaiId(idNumber);

  /// Validates [value] using the Thai national ID 13-digit checksum.
  static bool isValidThaiId(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 13) return false;

    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * (13 - i);
    }
    final checkDigit = (11 - (sum % 11)) % 10;
    return checkDigit == int.parse(digits[12]);
  }
}
