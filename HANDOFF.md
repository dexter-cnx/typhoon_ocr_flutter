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

- Added library-level documentation.
- Documented the primary `ThaiIdCard` API including checksum validation.
- Documented the `BankSlip` public API.
- CI passed and PR #2 was squash-merged into `main` on 2026-08-26.

### PR #3 — `chore/api-quality-hardening`

Current scope:

- Validate the example app in CI, not only the package.
- Generate test coverage with `flutter test --coverage`.
- Keep `dart pub publish --dry-run` as a required CI check.
- Add request-level `ExtractionOptions` with prompt, mode and timeout overrides.
- Preserve backward compatibility for existing `extract<T>(image, type: ...)` calls.
- Add tests proving request overrides do not mutate document definitions and timeout failures use `TyphoonTimeoutException`.
- Record project state and next work in this handoff.

## Quality roadmap

### Near-term / before the next publish

1. Expand dartdoc coverage from the pub.dev threshold toward 80–100% of exported API.
2. Enable `public_member_api_docs` only after exported APIs are documented enough that the lint does not make CI fail.
3. Add/extend mocked provider tests for:
   - request headers and request bodies,
   - JPEG/PNG/WebP MIME handling,
   - HTTP 400/401/500 mapping to typed exceptions,
   - timeout behavior,
   - malformed provider responses.
4. Extend parser tests for:
   - fenced JSON,
   - text before/after JSON,
   - multiple JSON objects,
   - braces and escaped quotes inside string values,
   - malformed JSON,
   - Thai Unicode payloads,
   - raw Markdown fallback.
5. Review the claimed minimum Flutter/Dart versions against versions actually covered by CI. Do not claim a compatibility floor that is not tested.

### Later / 1.1+

- Extend request options with model/generation settings only if provider APIs need them; keep provider-specific controls out of the core API when possible.
- Structured document validation beyond `ThaiIdCard.isValidId` with errors/warnings for missing or suspicious OCR fields.
- Consider a pure-Dart core split if Flutter APIs remain unnecessary in `lib/`, while retaining the Flutter example/capture integration separately.
- Consider optional coverage reporting/thresholds once the test surface stabilizes.

## Release discipline

Before publishing:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

Do not publish if the example does not analyze cleanly or if package CI is red.
