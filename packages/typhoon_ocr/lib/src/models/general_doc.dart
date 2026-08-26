import 'document.dart';

/// Generic OCR document used when no typed document schema is required.
class GeneralDocument extends TyphoonDocument {
  /// Creates a generic document preserving raw OCR output and parsed fields.
  const GeneralDocument({
    required super.rawMarkdown,
    super.rawJson,
    super.rawMap,
  });
}
