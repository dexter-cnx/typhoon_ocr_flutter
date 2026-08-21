import 'document.dart';

class ReceiptItem {
  final String name;
  final double quantity;
  final double price;

  const ReceiptItem({
    required this.name,
    this.quantity = 1,
    this.price = 0,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: json['name']?.toString() ?? json['description']?.toString() ?? '',
        quantity: _asDouble(
          json['quantity'] ?? json['qty'],
          fallback: 1,
        ),
        price: _asDouble(json['price']),
      );

  static double _asDouble(Object? value, {double fallback = 0}) =>
      double.tryParse(value?.toString() ?? '') ?? fallback;
}

class Receipt extends TyphoonDocument {
  final String merchantName;
  final String branch;
  final String date;
  final List<ReceiptItem> items;
  final double subtotal;
  final double vat;
  final double total;
  final String paymentMethod;

  const Receipt({
    required this.merchantName,
    this.branch = '',
    this.date = '',
    this.items = const [],
    this.subtotal = 0,
    this.vat = 0,
    required this.total,
    this.paymentMethod = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  factory Receipt.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) {
    final rawItems = json['items'];
    return Receipt(
      merchantName:
          json['merchant_name']?.toString() ?? json['merchant']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => ReceiptItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
      subtotal: _asDouble(json['subtotal']),
      vat: _asDouble(json['vat']),
      total: _asDouble(json['total']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      rawMarkdown: rawMarkdown,
      rawJson: rawJson,
      rawMap: Map<String, dynamic>.unmodifiable(json),
    );
  }

  static double _asDouble(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
