# typhoon_ocr_flutter handoff

## Current status

- Package: `typhoon_ocr_flutter` 1.0.0
- Public repository: `dexter-cnx/typhoon_ocr_flutter`
- Main API: `TyphoonOCR`, `TyphoonProvider`, typed document models, document definitions and parser.
- Built-in providers: local OpenAI-compatible vLLM, OpenTyphoon Cloud and custom multipart backend.
- Built-in document types: Thai ID card, receipt, bank slip, passport and general document.
- Thai ID example supports Camera and Gallery selection and typed `ThaiIdCard` extraction.
- `TyphoonDocument` is an `abstract class` so built-in and consumer-defined document models can extend it across Dart libraries.
- Models retain `rawMarkdown`, `rawJson` and immutable `rawMap` data.
- Typed exception hierarchy, configurable provider timeout and injectable HTTP clients are present.
- Request-level `ExtractionOptions` can override prompt, mode and timeout without changing registered definitions.

## Completed quality work

### PR #2 — public API dartdoc coverage

- Added library-level documentation and expanded model/API dartdoc coverage.
- CI passed and PR #2 was squash-merged on 2026-08-26.

### PR #3 — request options and quality hardening

- Added request-scoped `ExtractionOptions` for prompt, mode and timeout.
- Preserved existing `extract<T>(image, type: ...)` compatibility.
- Added example validation, coverage generation and publish dry-run to CI.
- Fixed cloud mode propagation so cloud and local providers honor request mode consistently.

### PR #4 — public API documentation expansion

- Expanded dartdoc across client, definitions, provider contracts, document types and typed exceptions.
- Prepared the exported API for a strict `public_member_api_docs` lint gate.

### PR #5 — provider contract hardening

- Added deterministic mocked contract coverage for OpenTyphoon Cloud, custom multipart backend and local vLLM.
- Covered request shape, auth/headers, JPEG/PNG/WebP MIME behavior, HTTP 400/401/500 mapping, provider timeouts and malformed responses.
- CI passed all provider contract tests before merge.

### PR #6 — parser edge cases

- Added regression coverage for fenced JSON, surrounding prose, Thai Unicode, escaped quotes/braces, malformed JSON recovery, multiple JSON objects and raw Markdown fallback.
- Fixed `jsonObjects()` so nested objects are not emitted as separate top-level objects.
- Review feedback was resolved and CI passed before merge.

## Current quality baseline work

### PR #7 — package quality baseline

Scope:

- Align the declared Flutter minimum with Dart `>=3.2.0`; Flutter `>=3.16.0` is the compatible baseline because Flutter 3.16 ships with Dart 3.2.
- Add a dedicated CI job running Flutter 3.16.0 so the minimum supported toolchain is continuously tested.
- Enable `public_member_api_docs` as a required analyzer lint.
- Enforce at least 80% package line coverage from `coverage/lcov.info`.
- Keep stable Flutter format/analyze/test, example analyze and `dart pub publish --dry-run` checks.

## Quality roadmap

### Near-term / before the next publish

1. Get PR #7 green on both stable Flutter and the minimum Flutter 3.16.0 job.
2. If the documentation lint exposes remaining public declarations, document them rather than weakening the lint.
3. If line coverage is below 80%, add focused tests rather than lowering the threshold unless uncovered code is intentionally unreachable/platform-only.
4. Re-run `dart pub publish --dry-run` after all quality gates pass.

### Later / 1.1+

- Structured document validation beyond `ThaiIdCard.isValidId`, including errors/warnings for missing or suspicious OCR fields.
- Extend request options with model/generation settings only if provider APIs need them; keep provider-specific controls out of the core API when possible.
- Consider a pure-Dart core split if Flutter APIs remain unnecessary in `lib/`, while retaining Flutter example/capture integration separately.
- Consider raising the coverage threshold above 80% after the validation layer is covered.

## Release discipline

Before publishing:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# CI must confirm line coverage >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

CI must also pass on Flutter 3.16.0, the declared minimum Flutter baseline.

Do not publish if either SDK job is red, public API docs lint fails, coverage is below the threshold, the example does not analyze cleanly, or publish dry-run fails.
