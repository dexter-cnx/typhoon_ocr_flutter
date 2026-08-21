import 'document.dart';

class ThaiIdCard extends TyphoonDocument {
  final String idNumber;
  final String titleTh;
  final String firstNameTh;
  final String lastNameTh;
  final String dob;
  final String address;
  final String issueDate;
  final String expiryDate;

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

  /// Validates a Thai national ID using the standard 13-digit checksum.
  bool get isValidId => isValidThaiId(idNumber);

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
