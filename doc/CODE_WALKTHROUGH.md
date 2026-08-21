# Code Walkthrough

This document explains the main architecture and execution flow of `typhoon_ocr_flutter`.

## 1. Public entry point

The package barrel file is:

```text
lib/typhoon_ocr_flutter.dart
```

Applications should normally import only:

```dart
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';
```

The barrel exports the client, providers, exceptions, document definitions, enums, and built-in models that make up the supported public API.

## 2. High-level architecture

The package is split into five main responsibilities:

```text
Application
   |
   v
TyphoonOCR client
   |
   +--> DocumentDefinition<T>
   |      - document type
   |      - prompt
   |      - mode
   |      - decoder
   |
   +--> TyphoonProvider
          |
          +--> OpentyphoonCloudProvider
          +--> LocalVllmProvider
          +--> CustomBackendProvider

Provider raw output
   |
   v
Parser / decoder
   |
   v
Typed TyphoonDocument
```

The important design rule is that transport and document parsing are separate. A provider only needs to return raw OCR text. A definition decides how that raw text becomes a typed model.

## 3. `TyphoonOCR`

Main file:

```text
lib/src/client.dart
```

`TyphoonOCR` is the orchestration layer. Its main responsibilities are:

1. receive a `File` and requested generic result type;
2. locate the matching `DocumentDefinition<T>`;
3. pass the definition's prompt and mode to the configured provider;
4. receive raw OCR output;
5. invoke the definition decoder; and
6. return the typed document model.

Typical call:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

This means callers do not need to manually choose parsing functions or copy document prompts into application code.

### `TyphoonOCR.fromEnv()`

`fromEnv()` provides a convenience configuration path based on runtime environment variables or compile-time `--dart-define` values. It can select the cloud, local, or custom backend provider.

This is convenient for development and examples, but a mobile `--dart-define` value should not be treated as a secure secret store.

## 4. Provider abstraction

Interface:

```text
lib/src/providers/provider.dart
```

Each provider implements:

```dart
Future<String> extractRaw({
  required File image,
  required String prompt,
  required String mode,
});
```

The provider contract intentionally returns a raw `String`. This keeps network/API concerns independent from model parsing.

### OpenTyphoon Cloud

File:

```text
lib/src/providers/opentyphoon_cloud_provider.dart
```

Flow:

1. read image bytes;
2. determine image MIME type;
3. base64-encode the image;
4. build an OpenAI-compatible chat-completions request;
5. add `Authorization: Bearer <api-key>`;
6. POST to `/chat/completions`;
7. convert non-2xx responses into `TyphoonApiException`; and
8. extract assistant message content from the response body.

The provider supports an injected `http.Client`, which is important for unit testing and application-level HTTP customization.

### Local vLLM provider

File:

```text
lib/src/providers/local_vllm_provider.dart
```

This provider targets a local or self-hosted OpenAI-compatible endpoint. It is useful when Typhoon OCR is hosted with vLLM or another compatible runtime.

### Custom backend provider

File:

```text
lib/src/providers/custom_backend_provider.dart
```

This provider is the recommended production boundary when API credentials should remain outside the mobile application. It uploads the image, prompt, and mode to an application-owned backend.

## 5. Provider utilities and exceptions

Shared provider helpers:

```text
lib/src/providers/provider_utils.dart
```

These helpers centralize concerns such as MIME detection and extraction of OpenAI-compatible response content.

Typed exceptions:

```text
lib/src/exceptions.dart
```

Main exception types include:

- `TyphoonConfigurationException`
- `TyphoonNetworkException`
- `TyphoonTimeoutException`
- `TyphoonApiException`
- `TyphoonParseException`

Consumers can catch these types instead of interpreting arbitrary strings.

## 6. Document definitions

Directory:

```text
lib/src/definitions/
```

A `DocumentDefinition<T>` groups together everything required to extract one document type:

- `DocumentType`
- OCR prompt
- extraction mode
- decoder

This registry-based design is what lets `TyphoonOCR.extract<T>()` remain generic and extensible.

A custom document can be added without editing the core client:

```dart
final ocr = TyphoonOCR(
  provider: provider,
  definitions: {
    MyDocument: DocumentDefinition<MyDocument>(
      type: DocumentType.general,
      prompt: 'Return my document as JSON',
      mode: 'structure',
      decode: MyDocument.fromRaw,
    ),
  },
);
```

## 7. Models

Directory:

```text
lib/src/models/
```

Built-in models include:

- `ThaiIdCard`
- `Receipt`
- `BankSlip`
- `Passport`
- `GeneralDocument`

All extend the common `TyphoonDocument` base class.

The base model keeps raw provider output available, while structured models expose normalized typed fields.

### `rawMap`

Structured models preserve provider fields in `rawMap` even when a field is not yet represented by a typed property. This reduces information loss when the OCR API evolves.

### Thai ID validation

`ThaiIdCard.isValidId` checks the standard Thai 13-digit national ID checksum locally after OCR parsing. OCR success and checksum validity are intentionally separate concerns.

## 8. Parser

Directory:

```text
lib/src/parsers/
```

The parser is designed for real model output rather than assuming the response is always a clean JSON string.

Its behavior includes:

1. scanning mixed markdown/text for JSON objects;
2. preferring the object whose keys best match the requested document type;
3. decoding known fields into the requested model;
4. retaining raw markdown/JSON data; and
5. returning safe empty structured fields when structured JSON cannot be recovered.

This is useful because LLM/VLM responses may include markdown fences, metadata JSON, or explanatory text around the document JSON.

## 9. End-to-end request flow

For:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

the normal execution path is:

```text
1. App calls TyphoonOCR.extract<ThaiIdCard>()
2. Client resolves the ThaiIdCard DocumentDefinition
3. Client calls provider.extractRaw(...)
4. Provider sends image + prompt to OCR endpoint
5. Provider returns raw response text
6. Definition decoder invokes parser
7. Parser creates ThaiIdCard
8. Client returns ThaiIdCard to the app
9. App may inspect card.isValidId and card.rawMap
```

## 10. Example application

Directory:

```text
example/
```

The example demonstrates UI/integration concerns without forcing them into the package dependency graph. `image_picker` belongs to the example rather than the package itself.

## 11. Test suite

Directory:

```text
test/
```

The suite covers client orchestration, parser/model behavior, MIME handling, runtime environment configuration, and the OpenTyphoon provider HTTP contract.

Provider tests use mock HTTP clients. They do not call OpenTyphoon and do not require an API key.

## 12. CI

Workflow:

```text
.github/workflows/ci.yml
```

The CI quality gate runs:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

No cloud OCR call is made in CI, so secrets are not required.

---

# สรุป Code Walkthrough ภาษาไทย

โครงสร้างหลักของ package แยกเป็น 3 ชั้นสำคัญ:

1. **`TyphoonOCR`** เป็นตัว orchestrate การ extract และเลือก `DocumentDefinition<T>`
2. **Provider** รับผิดชอบเฉพาะการส่งรูป/prompt ไปยัง OCR backend และคืน raw string
3. **Definition + Parser + Model** รับผิดชอบแปลง raw output เป็น typed document

ข้อดีของการแยกแบบนี้คือสามารถเปลี่ยนจาก OpenTyphoon Cloud ไป local vLLM หรือ backend ของระบบเองได้โดยไม่ต้องเปลี่ยน model parsing และสามารถเพิ่ม document type ใหม่ผ่าน `DocumentDefinition<T>` โดยไม่ต้องแก้ generic extraction logic

สำหรับ production mobile app ควรพิจารณา `CustomBackendProvider` เพื่อไม่ให้ OpenTyphoon API key อยู่ในตัวแอป ส่วน test และ CI ใช้ fake/mock client จึงไม่ต้องมี API key และไม่ยิง OCR service จริง
