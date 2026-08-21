import 'document.dart';

class BankSlip extends TyphoonDocument {
  final String fromBank;
  final String toBank;
  final String fromAccount;
  final String toAccount;
  final String fromName;
  final String toName;
  final double amount;
  final double fee;
  final String currency;
  final String dateTime;
  final String referenceNo;
  final String transactionId;

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
