/// Type-safe OCR models and provider integrations for Typhoon OCR.
library typhoon_ocr_flutter;

export 'src/definitions/default_definitions.dart';
export 'src/definitions/document_definition.dart';
export 'src/enums/document_type.dart';
export 'src/exceptions.dart';
export 'src/models/bank_slip.dart';
export 'src/models/document.dart';
export 'src/models/general_doc.dart';
export 'src/models/passport.dart';
export 'src/models/receipt.dart';
export 'src/models/thai_id_card.dart';
export 'src/parsers/parser.dart';
export 'src/pdf_rasterizer.dart';
export 'src/validation/default_validators.dart';
export 'src/validation/validation.dart';

export 'src/client.dart';
export 'src/extraction_options.dart';
export 'src/providers/custom_backend_provider.dart';
export 'src/providers/local_vllm_provider.dart';
export 'src/providers/opentyphoon_cloud_provider.dart';
export 'src/providers/provider.dart';
