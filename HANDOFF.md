# typhoon_ocr_flutter handoff

## Current status

- Package: `typhoon_ocr_flutter` 1.1.1 published baseline; 1.2.0 is under development in PR #16.
- Repository: `dexter-cnx/typhoon_ocr_flutter`.
- This repository publishes a single package only: `typhoon_ocr_flutter`.
- Platform-neutral OCR models/parsers/validation remain internal modules under `lib/src`; there is no second published core package.
- Main API: `TyphoonOCR`, providers, `ExtractionOptions`, typed document models, parser, document definitions, structured validation, and multi-page PDF extraction in 1.2.0.
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
- The temporary nested core package was folded back into `typhoon_ocr_flutter/lib/src` in PR #10.
- Squash-merged on 2026-08-26 at `143b88a`.

### PR #10 — `typhoon_ocr_flutter` 1.1.0 release

- Restored the single-package layout and root package publish validation.
- Preserved validation/parser/model features and source-compatible public exports.
- Released and published `typhoon_ocr_flutter` 1.1.0.

### PR #11 — README install version correction

- Updated English and Thai README installation snippets from 1.0.0 to 1.1.0 on GitHub.

### PR #12 — portfolio status metadata

- Added `.portfolio/status_en.json` and `.portfolio/status_th.json` plus maintenance documentation.

### PR #14 — `typhoon_ocr_flutter` 1.1.1 docs patch

- Corrected the package version shown by pub.dev README content.
- Expanded the Thai code walkthrough.
- Kept runtime/API behavior unchanged.

### PR #15 — roadmap sync

- Added the multi-page PDF and Thai high-value document plans to this handoff.
- Corrected future PR numbering after review.
- Merged on 2026-08-28 at `8a28f65`.

## Active work

### PR #16 — multi-page PDF extraction / 1.2.0

Branch: `feature/multi-page-pdf`

Target API:

```dart
final docs = await ocr.extractFromPdf<Receipt>(
  File('invoices.pdf'),
); // List<Receipt>
```

Implemented direction:

1. Add `TyphoonOCR.extractFromPdf<T extends TyphoonDocument>() -> Future<List<T>>`.
2. Rasterize each PDF page to PNG locally, then reuse the existing `extract<T>()` pipeline and provider abstraction.
3. Preserve source PDF page order and process pages sequentially for deterministic results and to avoid provider request bursts.
4. Default to 144 DPI and expose `dpi:` for callers that need a different OCR/rendering trade-off.
5. Fail the whole PDF operation when one page fails; expose the one-based page via `TyphoonPdfPageException.pageNumber` instead of silently dropping pages.
6. Add `TyphoonPdfException` for PDF read/rasterization/empty-document failures.
7. Make the rasterizer injectable through `PdfPageRasterizer` so unit tests do not require a native PDF engine and advanced callers can replace the renderer.
8. Use Flutter `printing` for the default renderer. Keep it constrained to the 5.12.x line because 5.13+ raises the minimum Flutter/Dart requirements above the package's current compatibility floor.
9. Reuse `DocumentType`, `ExtractionOptions`, document definitions, parser, validation-compatible typed models, and provider behavior unchanged for each rasterized page.
10. Add regression tests for ordered typed results, partial failure page metadata, empty page streams, and invalid DPI.
11. Update README EN/TH, CHANGELOG, and handoff for the 1.2.0 behavior.
12. Keep all existing image APIs source-compatible.

Important design correction from the original roadmap:

- Typhoon OCR's public model/playground supports image or PDF input, but the open-source OCR flow treats PDF pages as page images before model inference. OpenAI-compatible vision requests are still image-oriented. PR #16 therefore performs page rasterization in Flutter instead of sending raw `application/pdf` bytes through `image_url`.
- Direct native PDF upload may be added later as an optional provider optimization only for a backend with an explicit multi-page PDF contract. It must not change `extractFromPdf<T>()` semantics.

Remaining before merge/release:

- CI format/analyze/test/coverage/minimum-SDK/publish-dry-run must be green.
- Address Codex review findings, if any.
- Add example-app PDF picker only if it can be done without raising the package compatibility floor or destabilizing the current example; otherwise track it as a follow-up example-only PR.
- Publish 1.2.0 only after PR #16 is merged and the pub.dev dry-run remains clean.

## Planned next work

### PR #17 — Thai high-value document models / 1.3.0

Goal: add typed models for documents frequently scanned in Thai applications.

New built-in models:

- `ThaiDriverLicense` — ใบอนุญาตขับรถ
- `ThaiTaxInvoice` — ใบกำกับภาษี
- `TabienBaan` — ทะเบียนบ้าน

Common scope:

1. Add document type/definition entries, typed models, parser mapping, exports, and dartdoc.
2. Add structured validators using the existing `ValidationResult<T>` pipeline.
3. Prefer warnings for suspicious OCR values and errors only for strong invariants because Thai document formats vary by generation and issuing authority.
4. Add sanitized Thai-only and Thai/English fixtures; do not commit personal documents.
5. Keep optional OCR fields nullable rather than turning missing optional fields into parser failures.
6. Add parser tests for complete/partial payloads and validator tests for valid/warning/error cases.
7. Extend README EN/TH and the example result rendering.

#### `ThaiDriverLicense`

Initial field candidates:

- license number
- Thai/English name
- date of birth
- issue date
- expiry date
- license type/class
- national ID number where present
- issuing authority / province where available

Validation candidates:

- `issueDate <= expiryDate`
- Thai national ID checksum only when a complete 13-digit ID is present
- license-number normalization without assuming one historical card format

#### `ThaiTaxInvoice`

Initial field candidates:

- seller/company name
- seller tax ID
- branch/head-office indicator
- buyer/customer name
- buyer tax ID where present
- invoice number/date
- line items
- subtotal
- VAT rate/amount
- total amount
- currency

Validation candidates:

- Thai tax ID format/checksum when enough evidence is available
- subtotal/VAT/total arithmetic with OCR-safe tolerance
- support 7% VAT without assuming every tax document must use 7%
- do not assume item `price` always means unit price versus line total

Architecture:

- Use a dedicated tax-invoice model. Reuse receipt primitives only where semantics are actually identical.

#### `TabienBaan`

Initial field candidates:

- house registration/book number where present
- house code
- address components
- village/building details where present
- subdistrict (`tambon` / `khwaeng`)
- district (`amphoe` / `khet`)
- province
- postal code where present
- ordered registered-person/household-member list
- registrar/issue metadata where available

Validation candidates:

- normalize Thai address components without collapsing Bangkok and provincial terminology into misleading field names
- validate national IDs only for members where a complete ID is present
- do not assume every scan contains every page/member

## Release sequencing

- `1.1.1`: docs patch baseline.
- `1.2.0`: multi-page PDF extraction — PR #16.
- `1.3.0`: Thai document model pack — PR #17.

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
