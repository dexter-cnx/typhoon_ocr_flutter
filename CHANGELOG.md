## 1.1.0

### Validation

- Added `ValidationIssue`, `ValidationSeverity`, `ValidationResult<T>`, and `DocumentValidator<T>`.
- Added `TyphoonOCR.validate<T>()` and `extractValidated<T>()` without changing existing `extract<T>()` behavior.
- Added built-in Thai ID, receipt, bank-slip, and passport validators with error/warning severity.
- Hardened validation dispatch to use the concrete document runtime type.
- Reject non-finite monetary values and avoid assuming whether receipt item `price` is a unit price or a line total.

### Architecture

- Refactored platform-neutral document models, parser, definitions, document types, exceptions, and validation into an internal pure-Dart core layer under `lib/src`.
- Kept `typhoon_ocr_flutter` as the only published package; no additional package is required by consumers.
- Preserved the existing `package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart` public API.

### Quality

- Added a minimum Flutter 3.16.0 / Dart 3.2 CI job.
- Enabled `public_member_api_docs` and enforce at least 80% line coverage.
- Expanded provider contract, parser edge-case, and structured-validation regression coverage.
- Restored root-package `dart pub publish --dry-run` validation for the 1.1.0 release.

## 1.0.0

Initial stable release.

### API and architecture

- Added `TyphoonOCR` with typed document extraction and pluggable providers.
- Added `DocumentDefinition<T>` registry support so consumer-defined document models can be registered without changing the extraction client.
- Changed `TyphoonDocument` to an `abstract class` so built-in models in separate Dart libraries and consumer-defined models can extend it safely.
- Added `TyphoonOCR.fromEnv()` configuration for local, cloud, and custom providers.
- Added runtime `Platform.environment` support as a fallback/override for `--dart-define`, making CLI and test configuration easier.
- Added per-request `ExtractionOptions` for prompt, mode, and timeout overrides without mutating registered document definitions.

### Providers

- Added `LocalVllmProvider` for OpenAI-compatible local/vLLM hosts.
- Added `OpentyphoonCloudProvider` for OpenTyphoon Cloud.
- Added `CustomBackendProvider` for application-owned backend endpoints.
- Added configurable request timeouts and injectable HTTP clients.
- Added typed configuration, network, timeout, API, and parsing exceptions.
- Added MIME detection for JPEG, PNG, WebP, HEIC, and HEIF images.

### Documents and parsing

- Added typed Thai ID card, receipt, bank slip, passport, and general document models.
- Added Thai national ID 13-digit checksum validation.
- Added immutable `rawMap` access so provider fields not represented by the typed model are preserved.
- Expanded receipt fields with branch, items, subtotal, VAT, total, and payment method.
- Expanded bank-slip fields with sender/receiver details, amount, fee, currency, date/time, reference, and transaction ID.
- Expanded passport fields including MRZ lines.
- Improved mixed-markdown JSON extraction, including responses containing valid metadata JSON before the actual document JSON.

### Example and documentation

- Added a camera/gallery Thai ID example application.
- Added English and Thai README documentation.
- Added provider setup examples, OpenTyphoon API-key instructions, security guidance, and `--dart-define` usage.
- Added a code walkthrough covering architecture, providers, parsing, models, tests, and extension points.

### Quality

- Added unit tests for typed extraction, custom definitions, request-level extraction overrides, Thai ID validation, parser edge cases, MIME detection, runtime environment configuration, and OpenTyphoon request contracts.
- Added GitHub Actions CI gates for formatting, static analysis, tests, example analysis, coverage generation, and package publish validation.
