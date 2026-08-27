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
