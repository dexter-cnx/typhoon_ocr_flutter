import 'document.dart';

/// One line item extracted from a receipt.
class ReceiptItem {
  /// Item name or description.
  final String name;

  /// Item quantity.
  final double quantity;

  /// Unit or line price reported by OCR.
  final double price;

  /// Creates a receipt item.
  const ReceiptItem({
    required this.name,
    this.quantity = 1,
    this.price = 0,
  });

  /// Creates a receipt item from parsed OCR JSON.
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

/// Typed receipt OCR result with merchant, totals, and line items.
class Receipt extends TyphoonDocument {
  /// Merchant or store name.
  final String merchantName;

  /// Merchant branch label.
  final String branch;

  /// Receipt date as returned by OCR.
  final String date;

  /// Parsed receipt line items.
  final List<ReceiptItem> items;

  /// Receipt subtotal before tax or adjustments.
  final double subtotal;

  /// Value-added tax amount or value reported by OCR.
  final double vat;

  /// Receipt grand total.
  final double total;

  /// Payment method label.
  final String paymentMethod;

  /// Creates a typed receipt OCR result.
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

  /// Creates a [Receipt] from parsed OCR JSON and the raw provider payload.
  factory Receipt.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) {
    final rawItems = json['items'];
    return Receipt(
      merchantName: json['merchant_name']?.toString() ??
          json['merchant']?.toString() ??
          '',
      branch: json['branch']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) =>
                  ReceiptItem.fromJson(Map<String, dynamic>.from(item)))
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
