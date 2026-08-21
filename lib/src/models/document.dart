abstract class TyphoonDocument {
  final String rawMarkdown;
  final String rawJson;

  /// Parsed fields returned by the OCR model, including fields that are not
  /// represented by the typed model yet.
  final Map<String, dynamic> rawMap;

  const TyphoonDocument({
    required this.rawMarkdown,
    this.rawJson = '',
    this.rawMap = const <String, dynamic>{},
  });
}
