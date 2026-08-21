import '../enums/document_type.dart';
import '../models/document.dart';

typedef DocumentDecoder<T extends TyphoonDocument> = T Function(String raw);

class DocumentDefinition<T extends TyphoonDocument> {
  final DocumentType type;
  final String prompt;
  final String mode;
  final DocumentDecoder<T> decode;

  const DocumentDefinition({
    required this.type,
    required this.prompt,
    required this.mode,
    required this.decode,
  });
}
