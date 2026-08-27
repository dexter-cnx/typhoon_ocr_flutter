# typhoon_ocr_flutter handoff

## Current status

- Package: `typhoon_ocr_flutter` 1.1.1 release candidate.
- Repository: `dexter-cnx/typhoon_ocr_flutter`.
- This repository publishes a single package only: `typhoon_ocr_flutter`.
- Platform-neutral OCR code is kept as an internal pure-Dart core layer under `lib/src`, not as a separately published package.
- Main API: `TyphoonOCR`, providers, `ExtractionOptions`, typed document models, parser, document definitions, and structured validation.
- Built-in providers: local OpenAI-compatible vLLM, OpenTyphoon Cloud, and custom multipart backend.
- Built-in documents: Thai ID card, receipt, bank slip, passport, and general document.
- CI enforces formatting, analysis, tests, >=80% line coverage, example analysis, package publish dry-run, and minimum Flutter 3.16.0 / Dart 3.2 compatibility.

## Completed work

### PR #7 — package quality baseline

- Raised the declared Flutter minimum to 3.16.0 for Dart 3.2 compatibility.
- Added the minimum-SDK CI job.
- Enabled `public_member_api_docs`.
- Enforced >=80% line coverage.

### PR #8 — structured document validation

- Added `ValidationIssue`, `ValidationSeverity`, `ValidationResult<T>`, and `DocumentValidator<T>`.
- Added `TyphoonOCR.validate<T>()`, `extractValidated<T>()`, and immutable custom-validator registration.
- Added Thai ID, receipt, bank-slip, and passport validators.
- Validation dispatch uses the concrete document runtime type.
- Numeric validation rejects non-finite OCR values.
- Receipt validation avoids assuming whether extracted `price` is unit or line price.
- Squash-merged on 2026-08-26 at `550c4be`.

### PR #9 — internal pure-Dart core refactor

- Refactored platform-neutral models, parser, definitions, document type, exceptions, and validators away from provider/client concerns.
- The initial implementation temporarily introduced a nested `packages/typhoon_ocr` package boundary; this was not intended to become a separately published package.
- PR #10 folded that code back into `typhoon_ocr_flutter/lib/src` while preserving the architectural separation and public API.
- Squash-merged on 2026-08-26 at `143b88a`.

### PR #10 — `typhoon_ocr_flutter` 1.1.0 release

- Restored the single-package layout and root package publish validation.
- Kept the pure-Dart core as internal modules under `lib/src`.
- Preserved validation/parser/model features and source-compatible public exports.
- Released and published `typhoon_ocr_flutter` 1.1.0.

### PR #11 — README install version correction

- Updated English and Thai README installation snippets from 1.0.0 to 1.1.0 on GitHub.

### PR #12 — portfolio status metadata

- Added `.portfolio/status_en.json` and `.portfolio/status_th.json` plus maintenance documentation.

## Active work

### PR #13 — `typhoon_ocr_flutter` 1.1.1 docs-only patch release

Branch: `release/1.1.1`

Goals:

1. Bump package version to 1.1.1.
2. Update English and Thai README installation snippets to `typhoon_ocr_flutter: ^1.1.1` so pub.dev shows the correct current version.
3. Expand the Thai section of `doc/CODE_WALKTHROUGH.md` to cover architecture and execution flow at similar depth to the English section.
4. Sync portfolio metadata to version 1.1.1.
5. Keep API/runtime behavior unchanged.
6. Pass full stable + minimum SDK CI, >=80% coverage, example analysis, and `dart pub publish --dry-run` before publishing.

## Planned work after 1.1.1

### PR #14 — multi-page PDF extraction

Goal: allow callers to send a PDF directly to Typhoon OCR and receive one typed document result per page.

Target API:

```dart
final docs = await ocr.extractFromPdf<Receipt>(
  File('invoices.pdf'),
); // List<Receipt>
```

Planned scope:

1. Add a public `extractFromPdf<T extends TyphoonDocument>()` API that returns `Future<List<T>>`.
2. Reuse the existing provider abstraction instead of adding provider-specific PDF APIs at the package surface.
3. Ensure provider request building preserves `application/pdf` and the original filename when the backend accepts PDF uploads directly.
4. Define page ordering explicitly: returned items must match source PDF page order.
5. Define partial-failure semantics before implementation. Preferred direction: fail the whole operation by default if a page cannot be parsed, while preserving page index in the exception; consider a later opt-in best-effort API rather than silently dropping pages.
6. Reuse the existing typed parser/document-definition pipeline for every page result rather than creating a separate PDF parsing stack.
7. Support `ExtractionOptions` consistently with image extraction where the backend capability allows it.
8. Add PDF-specific exceptions/error metadata where needed, including page index and malformed/unsupported PDF response cases.
9. Add unit tests for single-page PDF, multi-page PDF, page ordering, malformed page payloads, empty PDFs/responses, provider errors, and generic type parsing.
10. Add mocked-provider tests so CI does not depend on a live Typhoon endpoint.
11. Update English/Thai README and `doc/CODE_WALKTHROUGH.md` with PDF examples and behavior guarantees.
12. Add an example app path/file-picker flow for selecting a PDF without forcing PDF UI dependencies into the core package.
13. Keep the first PDF release backward-compatible with all existing image APIs.

Design note:

- Typhoon OCR already accepts PDF input, so the preferred implementation is direct PDF upload to the provider rather than rasterizing pages locally in Flutter. Local PDF-to-image conversion should only be considered as a separate fallback feature if a provider cannot accept PDFs.

### PR #15 — Thai high-value document models

Goal: add typed models for documents that are frequently scanned in Thai applications.

New built-in models:

- `ThaiDriverLicense` — ใบอนุญาตขับรถ
- `ThaiTaxInvoice` — ใบกำกับภาษี
- `TabienBaan` — ทะเบียนบ้าน

Planned scope:

1. Add document type/definition entries, typed models, parser mapping, exports, and dartdoc for all three models.
2. Add structured validators and keep validation semantics aligned with the existing `ValidationResult<T>` pipeline.
3. Avoid over-validating OCR output where Thai document formats vary by generation or issuing authority; use warnings for suspicious values and errors only for strong invariants.
4. Add representative fixtures covering Thai-only and Thai/English mixed text.
5. Document nullability carefully so missing OCR fields do not force consumers to catch parser failures for optional document fields.

#### `ThaiDriverLicense`

Initial field set to evaluate against real Typhoon OCR output:

- license number
- Thai/English name
- date of birth
- issue date
- expiry date
- license type/class
- national ID number where present
- issuing authority / province where available

Validation candidates:

- date ordering (`issueDate <= expiryDate`)
- Thai national ID checksum only when a complete 13-digit ID is present
- basic license-number normalization without assuming one historical card format

#### `ThaiTaxInvoice`

Initial field set:

- seller/company name
- seller tax ID
- branch/head-office indicator
- buyer/customer name
- buyer tax ID where present
- invoice number
- invoice date
- line items
- subtotal
- VAT rate/amount
- total amount
- currency

Validation candidates:

- Thai tax ID format/checksum when enough evidence is available
- subtotal/VAT/total arithmetic with OCR-safe tolerance
- explicit handling of 7% VAT without hard-coding that every document must use 7%
- line-item validation that does not assume extracted unit price versus line total semantics

Architecture note:

- Reuse receipt primitives only where the concepts are genuinely identical. Prefer a dedicated tax-invoice model over subclassing `Receipt` if tax IDs, branch information, VAT semantics, and invoice metadata would otherwise make `Receipt` ambiguous.

#### `TabienBaan`

Initial field set:

- house registration number / book number where present
- house code
- address components
- village/building details where present
- subdistrict (`tambon` / `khwaeng`)
- district (`amphoe` / `khet`)
- province
- postal code where present
- registered persons / household members when returned by the OCR schema
- registrar/issue metadata where available

Validation candidates:

- normalize Thai address components without forcing Bangkok and provincial terminology into the same field names
- preserve multiple household members as an ordered list
- validate Thai national IDs only for members where a complete ID is returned
- avoid assuming everyทะเบียนบ้าน scan contains all pages or all members

Testing/documentation:

1. Add parser tests for complete and partial payloads for every new document type.
2. Add validator tests for valid, warning, and error cases.
3. Add JSON fixtures based on sanitized sample outputs rather than personal documents.
4. Add README examples for each type.
5. Extend the example app selector/result rendering so the new types can be exercised manually.
6. Keep coverage >=80% and require format/analyze/test/example analyze/publish dry-run before release.

### Suggested release sequencing

- `1.1.1`: docs-only correction already in progress.
- `1.2.0`: multi-page PDF extraction (`PR #14`) because it expands the public API without breaking existing callers.
- `1.3.0`: Thai document model pack (`PR #15`).
- If implementation risk stays low and review remains manageable, PR #14 and #15 may ship together as one minor release, but keeping them separate is preferred for easier review, rollback, and changelog clarity.

## Release discipline

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# CI must confirm line coverage >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
dart pub publish
```

Do not publish if format, analysis, tests, coverage, example analysis, minimum SDK validation, or publish dry-run is red.
