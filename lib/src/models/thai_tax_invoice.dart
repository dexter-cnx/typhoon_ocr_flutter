import 'document.dart';

/// One line item extracted from a Thai tax invoice.
class ThaiTaxInvoiceItem {
  /// Item name or description.
  final String name;

  /// Item quantity when present.
  final double quantity;

  /// Unit or line price reported by OCR.
  final double price;

  /// Creates a tax-invoice line item.
  const ThaiTaxInvoiceItem({
    required this.name,
    this.quantity = 1,
    this.price = 0,
  });

  /// Creates an item from OCR JSON.
  factory ThaiTaxInvoiceItem.fromJson(Map<String, dynamic> json) =>
      ThaiTaxInvoiceItem(
        name: json['name']?.toString() ?? json['description']?.toString() ?? '',
        quantity: _asDouble(json['quantity'] ?? json['qty'], fallback: 1),
        price: _asDouble(json['price'] ?? json['amount']),
      );

  static double _asDouble(Object? value, {double fallback = 0}) {
    final parsed = _parseFormattedNumber(value);
    return parsed ?? fallback;
  }
}

/// Typed OCR result for a Thai tax invoice.
class ThaiTaxInvoice extends TyphoonDocument {
  /// Seller or company name.
  final String sellerName;

  /// Seller Thai tax ID.
  final String sellerTaxId;

  /// Branch or head-office indicator.
  final String branch;

  /// Buyer or customer name.
  final String buyerName;

  /// Buyer Thai tax ID when present.
  final String buyerTaxId;

  /// Invoice number.
  final String invoiceNumber;

  /// Invoice date as returned by OCR.
  final String invoiceDate;

  /// Extracted line items.
  final List<ThaiTaxInvoiceItem> items;

  /// Subtotal before VAT.
  final double subtotal;

  /// VAT rate as a percentage when present.
  final double vatRate;

  /// VAT amount.
  final double vatAmount;

  /// Grand total.
  final double total;

  /// Currency code or label.
  final String currency;

  /// Creates a Thai tax-invoice result.
  const ThaiTaxInvoice({
    required this.sellerName,
    this.sellerTaxId = '',
    this.branch = '',
    this.buyerName = '',
    this.buyerTaxId = '',
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.items = const [],
    this.subtotal = 0,
    this.vatRate = 0,
    this.vatAmount = 0,
    required this.total,
    this.currency = 'THB',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [ThaiTaxInvoice] from parsed OCR JSON.
  factory ThaiTaxInvoice.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) {
    final rawItems = json['items'];
    return ThaiTaxInvoice(
      sellerName: json['seller_name']?.toString() ??
          json['company_name']?.toString() ??
          '',
      sellerTaxId: json['seller_tax_id']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      buyerName: json['buyer_name']?.toString() ?? '',
      buyerTaxId: json['buyer_tax_id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceDate: json['invoice_date']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => ThaiTaxInvoiceItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      subtotal: _asDouble(json['subtotal']),
      vatRate: _asDouble(json['vat_rate']),
      vatAmount: _asDouble(json['vat_amount'] ?? json['vat']),
      total: _asDouble(json['total']),
      currency: json['currency']?.toString() ?? 'THB',
      rawMarkdown: rawMarkdown,
      rawJson: rawJson,
      rawMap: Map<String, dynamic>.unmodifiable(json),
    );
  }

  static double _asDouble(Object? value) => _parseFormattedNumber(value) ?? 0;
}

double? _parseFormattedNumber(Object? value) {
  if (value is num) return value.toDouble();
  final normalized = value
      ?.toString()
      .trim()
      .replaceAll(',', '')
      .replaceAll(RegExp(r'\s*%$'), '');
  if (normalized == null || normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
