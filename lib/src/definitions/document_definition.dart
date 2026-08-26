import '../enums/document_type.dart';
import '../models/document.dart';

/// Decodes a raw provider response into a typed OCR document.
typedef DocumentDecoder<T extends TyphoonDocument> = T Function(String raw);

/// Describes how a document type is requested from and decoded after OCR.
class DocumentDefinition<T extends TyphoonDocument> {
  /// Built-in category associated with this definition.
  final DocumentType type;

  /// Prompt sent to the OCR provider by default.
  final String prompt;

  /// Provider mode sent with the OCR request by default.
  final String mode;

  /// Converts the raw provider response into [T].
  final DocumentDecoder<T> decode;

  /// Creates an immutable document definition.
  const DocumentDefinition({
    required this.type,
    required this.prompt,
    required this.mode,
    required this.decode,
  });
}
