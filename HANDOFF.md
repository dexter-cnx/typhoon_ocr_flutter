# typhoon_ocr_flutter handoff

## Current status

- Flutter package: `typhoon_ocr_flutter` 1.0.0.
- Repository: `dexter-cnx/typhoon_ocr_flutter`.
- Main API: `TyphoonOCR`, `TyphoonProvider`, typed document models, document definitions, parser, and structured validation.
- Built-in providers: local OpenAI-compatible vLLM, OpenTyphoon Cloud, and custom multipart backend.
- Built-in documents: Thai ID card, receipt, bank slip, passport, and general document.
- Request-level `ExtractionOptions` can override prompt, mode, and timeout.
- Structured validation exposes typed issues/results with error and warning severity.
- CI enforces formatting, analysis, tests, >=80% line coverage, example analysis, and minimum Flutter 3.16.0 / Dart 3.2 compatibility.

## Completed work

### PR #2 — public API dartdoc coverage

- Expanded public API documentation and library-level docs.

### PR #3 — request options and quality hardening

- Added request-scoped `ExtractionOptions`.
- Preserved `extract<T>()` compatibility.
- Hardened request timeout and provider mode behavior.

### PR #4 — public API documentation expansion

- Completed dartdoc coverage needed by `public_member_api_docs`.

### PR #5 — provider contract hardening

- Added mocked contract coverage for OpenTyphoon Cloud, custom multipart backend, and local vLLM.
- Covered request shape, auth/headers, MIME handling, HTTP error mapping, timeouts, and malformed responses.

### PR #6 — parser edge cases

- Added fenced JSON, surrounding prose, Thai Unicode, escaping, malformed JSON recovery, multiple-object, and Markdown fallback coverage.
- Fixed nested-object duplicate emission.

### PR #7 — package quality baseline

- Raised the declared Flutter minimum to 3.16.0 for Dart 3.2 compatibility.
- Added the minimum-SDK CI job.
- Enabled `public_member_api_docs`.
- Enforced >=80% line coverage.
- Kept stable format/analyze/test/example/publish dry-run gates.
- Squash-merged on 2026-08-26.

### PR #8 — structured document validation

- Added `ValidationIssue`, `ValidationSeverity`, `ValidationResult<T>`, and `DocumentValidator<T>`.
- Added `TyphoonOCR.validate<T>()`, `extractValidated<T>()`, and immutable custom-validator registration.
- Added Thai ID, receipt, bank-slip, and passport validators.
- Validation dispatch uses the document runtime type.
- Numeric validation rejects non-finite OCR values.
- Receipt validation avoids assuming whether extracted `price` is unit or line price.
- Squash-merged on 2026-08-26 at `550c4be`.

## Active work

### PR #9 — pure-Dart core split

Branch: `feature/pure-dart-core-split`

Goal: make the platform-neutral OCR domain reusable without Flutter while keeping the existing Flutter package API source-compatible.

Scope:

- Add `packages/typhoon_ocr` with Dart SDK `>=3.2.0 <4.0.0` and no Flutter dependency.
- Move document models, parser, document definitions, `DocumentType`, typed exceptions, and structured validators into the pure-Dart package.
- Make `typhoon_ocr_flutter` depend on and re-export `typhoon_ocr`.
- Keep `TyphoonOCR`, providers, environment wiring, `File` request handling, and `ExtractionOptions` in the Flutter-facing package.
- Run core analyze/tests on both stable Dart and the minimum Dart 3.2 toolchain.
- Keep existing Flutter tests as compatibility coverage against the re-exported core types.

Release sequencing constraint:

- PR #9 intentionally uses a local path dependency while the core package is staged inside the monorepo.
- During this staging PR, CI validates the core publish dry-run instead of the Flutter publish dry-run because pub.dev packages cannot be published with path dependencies.
- Do not treat the staged `main` state as publish-ready until the release PR replaces the path dependency with the hosted core version.

## Next PR — release 1.1.0

### PR #10 — publish core + Flutter 1.1.0 release preparation

Planned sequence:

1. Publish the pure-Dart `typhoon_ocr` package from `packages/typhoon_ocr`.
2. Replace the Flutter package path dependency with a hosted `typhoon_ocr` version constraint.
3. Restore `dart pub publish --dry-run` for `typhoon_ocr_flutter` in CI.
4. Bump `typhoon_ocr_flutter` from 1.0.0 to 1.1.0.
5. Update CHANGELOG and README/README_TH with structured validation and pure-Dart architecture examples.
6. Run stable + minimum SDK CI, core publish dry-run, Flutter publish dry-run, example analysis, and >=80% coverage.
7. Publish/tag only after every required check is green.

## Release discipline

For the final 1.1.0 release state:

```bash
(cd packages/typhoon_ocr && dart pub get && dart analyze && dart test && dart pub publish --dry-run)
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# CI must confirm line coverage >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

CI must also pass on Flutter 3.16.0 / Dart 3.2. Do not publish if either SDK job is red, public API docs lint fails, coverage is below 80%, the example does not analyze cleanly, or either package publish dry-run fails.
