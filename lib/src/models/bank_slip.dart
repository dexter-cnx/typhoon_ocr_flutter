import 'document.dart';

/// Structured OCR result for a bank transfer slip.
class BankSlip extends TyphoonDocument {
  /// Source bank name.
  final String fromBank;

  /// Destination bank name.
  final String toBank;

  /// Source account identifier when present.
  final String fromAccount;

  /// Destination account identifier when present.
  final String toAccount;

  /// Source account holder name when present.
  final String fromName;

  /// Destination account holder name when present.
  final String toName;

  /// Transferred amount.
  final double amount;

  /// Transfer fee, or zero when unavailable.
  final double fee;

  /// Currency code or label returned by OCR.
  final String currency;

  /// Transfer date/time text returned by OCR.
  final String dateTime;

  /// Bank reference number when present.
  final String referenceNo;

  /// Transaction identifier when present.
  final String transactionId;

  /// Creates a structured bank slip result.
  const BankSlip({
    required this.fromBank,
    required this.toBank,
    this.fromAccount = '',
    this.toAccount = '',
    this.fromName = '',
    this.toName = '',
    required this.amount,
    this.fee = 0,
    this.currency = '',
    this.dateTime = '',
    this.referenceNo = '',
    this.transactionId = '',
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });

  /// Creates a [BankSlip] from decoded Typhoon JSON output.
  factory BankSlip.fromJson(
    Map<String, dynamic> json,
    String rawMarkdown, {
    String rawJson = '',
  }) =>
      BankSlip(
        fromBank: json['from_bank']?.toString() ?? '',
        toBank: json['to_bank']?.toString() ?? '',
        fromAccount: json['from_account']?.toString() ?? '',
        toAccount: json['to_account']?.toString() ?? '',
        fromName: json['from_name']?.toString() ?? '',
        toName: json['to_name']?.toString() ?? '',
        amount: _asDouble(json['amount']),
        fee: _asDouble(json['fee']),
        currency: json['currency']?.toString() ?? '',
        dateTime:
            json['datetime']?.toString() ?? json['date_time']?.toString() ?? '',
        referenceNo: json['reference_no']?.toString() ??
            json['reference']?.toString() ??
            json['ref']?.toString() ??
            '',
        transactionId: json['transaction_id']?.toString() ?? '',
        rawMarkdown: rawMarkdown,
        rawJson: rawJson,
        rawMap: Map<String, dynamic>.unmodifiable(json),
      );

  static double _asDouble(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
}
