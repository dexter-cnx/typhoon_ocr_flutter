import 'document.dart';

/// One registered person extracted from a Thai house-registration document.
class TabienBaanMember {
  /// Thai national ID when present.
  final String nationalId;

  /// Thai honorific or title.
  final String titleTh;

  /// Thai first name.
  final String firstNameTh;

  /// Thai last name.
  final String lastNameTh;

  /// Date of birth as returned by OCR.
  final String dateOfBirth;

  /// Relationship or registration role when present.
  final String relationship;

  /// Creates a registered household member.
  const TabienBaanMember({
    this.nationalId = '',
    this.titleTh = '',
    this.firstNameTh = '',
    this.lastNameTh = '',
    this.dateOfBirth = '',
    this.relationship = '',
  });

  /// Creates a household member from OCR JSON.
  factory TabienBaanMember.fromJson(Map<String, dynamic> json) =>
      TabienBaanMember(
        nationalId: json['national_id']?.toString() ?? '',
        titleTh: json['title_th']?.toString() ?? '',
        firstNameTh: json['firstname_th']?.toString() ?? '',
        lastNameTh: json['lastname_th']?.toString() ?? '',
        dateOfBirth: json['dob']?.toString() ?? '',
        relationship: json['relationship']?.toString() ?? '',
      );
}

/// Typed OCR result for a Thai Tabien Baan (house registration).
class TabienBaan extends TyphoonDocument {
  /// House-registration or book number when present.
  final String registrationNumber;

  /// House code.
  final String houseCode;

  /// House number.
  final String houseNumber;

  /// Village or building detail.
  final String village;

  /// Road or street.
  final String road;

  /// Subdistrict (`tambon` / `khwaeng`).
  final String subdistrict;

  /// District (`amphoe` / `khet`).
  final String district;

  /// Province.
  final String province;

  /// Postal code when present.
  final String postalCode;

  /// Registered household members in source order.
  final List<TabienBaanMember> members;

  /// Registrar or issuing metadata when present.
  final String registrar;

  /// Creates a Tabien Baan OCR result.
  const TabienBaan({
    this.registrationNumber = '',
    this.houseCode = '',
    this.houseNumber = '',
    this.village = '',
    this.road = '',
    this.subdistrict = '',
    this.district = '',
    this.province = '',
    this.postalCode = '',
    this.members = const [],
    this.registrar = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [TabienBaan] from parsed OCR JSON.
  factory TabienBaan.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) {
    final rawMembers = json['members'];
    return TabienBaan(
      registrationNumber: json['registration_number']?.toString() ??
          json['book_number']?.toString() ??
          '',
      houseCode: json['house_code']?.toString() ?? '',
      houseNumber: json['house_number']?.toString() ?? '',
      village: json['village']?.toString() ??
          json['building']?.toString() ??
          '',
      road: json['road']?.toString() ?? '',
      subdistrict: json['subdistrict']?.toString() ??
          json['tambon']?.toString() ??
          json['khwaeng']?.toString() ??
          '',
      district: json['district']?.toString() ??
          json['amphoe']?.toString() ??
          json['khet']?.toString() ??
          '',
      province: json['province']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      members: rawMembers is List
          ? rawMembers
              .whereType<Map>()
              .map((member) => TabienBaanMember.fromJson(
                    Map<String, dynamic>.from(member),
                  ))
              .toList(growable: false)
          : const [],
      registrar: json['registrar']?.toString() ?? '',
      rawMarkdown: rawMarkdown,
      rawJson: rawJson,
      rawMap: Map<String, dynamic>.unmodifiable(json),
    );
  }
}
