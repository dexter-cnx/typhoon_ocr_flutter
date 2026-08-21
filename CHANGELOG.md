## 1.0.0
- Fix `TyphoonDocument` base type: use `abstract class` so built-in models in separate Dart libraries and consumer-defined document models can extend it.

- Added local vLLM, OpenTyphoon Cloud, and custom backend providers.
- Added typed Thai ID, receipt, bank slip, passport, and general document extraction.
- Added Thai national ID checksum validation.
- Added camera/gallery Thai ID example application.
- Added immutable `rawMap` access for structured OCR fields.
- Expanded receipt, bank slip, and passport schemas, including passport MRZ lines.
- Moved prompts/modes into document definitions for cleaner extensibility.
- Added configurable provider timeouts, injectable HTTP clients, and typed exceptions.
- Improved mixed-markdown JSON parsing and MIME handling.
