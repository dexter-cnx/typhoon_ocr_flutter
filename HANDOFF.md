# typhoon_ocr_flutter handoff

## Current status

- Flutter package: `typhoon_ocr_flutter` 1.1.0 release candidate.
- Pure-Dart core package: `typhoon_ocr` 1.0.0, staged under `packages/typhoon_ocr` and ready for first publish.
- Repository: `dexter-cnx/typhoon_ocr_flutter`.
- Main Flutter API: `TyphoonOCR`, providers, `ExtractionOptions`, typed document models, parser, definitions, and structured validation.
- Core API contains platform-neutral document models, parser, definitions, document types, typed exceptions, and validators with no Flutter SDK dependency.
- Built-in providers: local OpenAI-compatible vLLM, OpenTyphoon Cloud, and custom multipart backend.
- Built-in documents: Thai ID card, receipt, bank slip, passport, and general document.
- CI enforces formatting, analysis, tests, >=80% line coverage, example analysis, core publish dry-run, and minimum Flutter 3.16.0 / Dart 3.2 compatibility.

## Completed work

### PR #7 — package quality baseline

- Raised the declared Flutter minimum to 3.16.0 for Dart 3.2 compatibility.
- Added the minimum-SDK CI job.
- Enabled `public_member_api_docs`.
- Enforced >=80% line coverage.
- Kept stable format/analyze/test/example/publish validation gates.
- Squash-merged on 2026-08-26.

### PR #8 — structured document validation

- Added `ValidationIssue`, `ValidationSeverity`, `ValidationResult<T>`, and `DocumentValidator<T>`.
- Added `TyphoonOCR.validate<T>()`, `extractValidated<T>()`, and immutable custom-validator registration.
- Added Thai ID, receipt, bank-slip, and passport validators.
- Validation dispatch uses the document runtime type.
- Numeric validation rejects non-finite OCR values.
- Receipt validation avoids assuming whether extracted `price` is unit or line price.
- Squash-merged on 2026-08-26 at `550c4be`.

### PR #9 — pure-Dart core split

- Added `packages/typhoon_ocr` with Dart SDK `>=3.2.0 <4.0.0` and no Flutter dependency.
- Moved document models, parser, definitions, `DocumentType`, typed exceptions, and structured validators into the core package.
- `typhoon_ocr_flutter` now depends on and re-exports the core package, preserving the public Flutter barrel API.
- Added core analyze/test/publish validation on stable Dart and minimum Dart 3.2.
- Added self-contained core `LICENSE` and `CHANGELOG.md` for pub.dev publication.
- Squash-merged on 2026-08-26 at `143b88a`.

## Active work

### PR #10 — release 1.1.0

Branch: `release/1.1.0`

Phase 1 (current):

- Bump `typhoon_ocr_flutter` to 1.1.0.
- Keep `publish_to: none` and the local path dependency temporarily so CI remains resolvable before the core package exists on pub.dev.
- Update release notes and documentation for structured validation and the pure-Dart split.
- Validate `typhoon_ocr` 1.0.0 publication contents with `dart pub publish --dry-run`.

Phase 2 (after `typhoon_ocr` 1.0.0 is actually published):

1. Replace the Flutter path dependency with `typhoon_ocr: ^1.0.0`.
2. Remove `publish_to: none` from the Flutter package.
3. Restore Flutter `dart pub publish --dry-run` in CI while retaining core publish validation.
4. Re-run stable + minimum SDK CI and confirm coverage remains >=80%.
5. Publish `typhoon_ocr_flutter` 1.1.0 only after every required check is green.

## Publication commands

Core first:

```bash
cd packages/typhoon_ocr
dart pub get
dart analyze
dart test
dart pub publish --dry-run
dart pub publish
```

After pub.dev resolves `typhoon_ocr: ^1.0.0`, finalize the Flutter package:

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

Do not publish the Flutter package while it still contains the local path dependency or `publish_to: none`.
