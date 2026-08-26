/// Base type for all typed OCR documents returned by the package.
abstract class TyphoonDocument {
  /// Full raw Markdown or text returned by the OCR provider.
  final String rawMarkdown;

  /// Raw JSON object selected by the parser, when one was found.
  final String rawJson;

  /// Parsed fields returned by the OCR model, including fields that are not
  /// represented by the typed model yet.
  final Map<String, dynamic> rawMap;

  /// Creates a document with its raw provider payload and parsed fields.
  const TyphoonDocument({
    required this.rawMarkdown,
    this.rawJson = '',
    this.rawMap = const <String, dynamic>{},
  });
}
