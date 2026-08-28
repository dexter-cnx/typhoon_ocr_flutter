# typhoon_ocr_flutter handoff

## Current status

- Package: `typhoon_ocr_flutter` 1.2.0 code is merged on `main`; PR #17 prepares 1.3.0.
- Repository: `dexter-cnx/typhoon_ocr_flutter`.
- This repository publishes a single package only: `typhoon_ocr_flutter`.
- Platform-neutral OCR models/parsers/validation remain internal modules under `lib/src`; there is no second published core package.
- Main API: `TyphoonOCR`, providers, `ExtractionOptions`, typed document models, parser, document definitions, structured validation, and multi-page PDF extraction.
- Built-in providers: local OpenAI-compatible vLLM, OpenTyphoon Cloud, and custom multipart backend.
- Built-in documents after PR #17: Thai ID card, Thai driver license, Thai tax invoice, Tabien Baan, receipt, bank slip, passport, and general document.
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

### PR #16 — multi-page PDF extraction / 1.2.0

- Added `TyphoonOCR.extractFromPdf<T>() -> Future<List<T>>`.
- Rasterizes PDF pages to PNG locally, then reuses `extract<T>()` and the existing provider abstraction.
- Preserves source page order and processes pages sequentially.
- Defaults to 144 DPI with configurable `dpi:`.
- Added `TyphoonPdfException` and `TyphoonPdfPageException.pageNumber`.
- Deletes each temporary page immediately after its OCR request to avoid temp-storage growth on long PDFs.
- Wraps PDF setup/read/rasterization failures in typed PDF exceptions.
- Added injectable `PdfPageRasterizer` and a Flutter `printing` default renderer constrained to the 5.12.x compatibility line.
- Converted the Android example Gradle files to a Flutter-3.16-compatible Groovy plugin-DSL layout so plugin dependency resolution keeps Android embedding v2 detection working on the minimum SDK job.
- Added PDF ordering/failure/empty/DPI tests and README EN/TH documentation.
- CI run #131 passed on head `1454a1a`.
- Squash-merged on 2026-08-28 at `180d79c`.

Important PDF architecture note:

- The public model/playground supports image or PDF input, but the open-source OCR flow treats PDF pages as page images before model inference. `extractFromPdf<T>()` therefore rasterizes pages instead of sending raw PDF bytes through OpenAI-compatible vision `image_url`.
- A provider with an explicit native multi-page PDF contract may later optimize internally, but it must preserve the same public page-order and failure semantics.

## Active work

### PR #17 — Thai high-value document models / 1.3.0

Branch: `feature/thai-document-models`

Goal: add typed models for documents frequently scanned in Thai applications while keeping parsing tolerant of partial OCR output and document-generation differences.

New built-in models:

- `ThaiDriverLicense` — ใบอนุญาตขับรถ
- `ThaiTaxInvoice` — ใบกำกับภาษี
- `TabienBaan` — ทะเบียนบ้าน

Implemented scope:

1. Added `DocumentType.thaiDriverLicense`, `DocumentType.thaiTaxInvoice`, and `DocumentType.tabienBaan`.
2. Added public model exports and default `DocumentDefinition<T>` registrations for all three types.
3. Added parser key scoring/routing so mixed provider responses select the object matching the requested Thai document model.
4. Added `ThaiDriverLicense` fields for license number, Thai/English name, DOB, issue/expiry dates, class, optional national ID, and issuing authority.
5. Added `ThaiDriverLicenseValidator` with required license number, conservative name checks, complete-13-digit Thai ID checksum warnings, and date ordering only when both dates are parseable.
6. Added dedicated `ThaiTaxInvoice` / `ThaiTaxInvoiceItem` types rather than subclassing `Receipt`.
7. Added tax-invoice seller/buyer tax IDs, branch, invoice metadata, items, subtotal, VAT rate/amount, total, and currency.
8. Added `ThaiTaxInvoiceValidator` for finite/non-negative monetary values, complete tax-ID checksum warnings, subtotal+VAT≈total tolerance, VAT-rate arithmetic, and line-item invariants without requiring VAT to be 7%.
9. Added `TabienBaan` / `TabienBaanMember`, including house identity fields, neutral subdistrict/district fields, province/postal code, registrar metadata, and ordered members.
10. Parser accepts Bangkok/provincial address aliases (`khwaeng`/`tambon`, `khet`/`amphoe`) while preserving the original payload in `rawMap`.
11. Added `TabienBaanValidator` that treats partial scans as valid-with-warnings instead of assuming all pages/members must be present.
12. Added sanitized parser/validator tests with Thai-only and mixed Thai/English payloads; no personal document images are committed.
13. Updated README EN/TH and CHANGELOG for 1.3.0.

Remaining before merge/release:

- Open PR #17 and pass format/analyze/test/coverage/minimum-SDK/example-analysis/publish-dry-run.
- Address review findings if any.
- Extend the example UI selector/result renderer for the three new types only if it can be done without making PR #17 overly broad; otherwise track it as an example-only follow-up.
- Publish 1.3.0 only after the merged main branch passes release dry-run.

## Release sequencing

- `1.1.1`: docs patch baseline.
- `1.2.0`: multi-page PDF extraction — PR #16, merged at `180d79c`.
- `1.3.0`: Thai document model pack — PR #17, active.

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
