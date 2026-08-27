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

# Code Walkthrough ภาษาไทย

ส่วนนี้อธิบายโครงสร้างและ execution flow ของ `typhoon_ocr_flutter` ในระดับเดียวกับส่วนภาษาอังกฤษ โดยเน้นว่าข้อมูลไหลผ่าน package อย่างไร และแต่ละ layer มีหน้าที่อะไร

## 1. Public entry point

ไฟล์หลักที่ consumer ควร import คือ:

```text
lib/typhoon_ocr_flutter.dart
```

โดยปกติ application ควร import แค่:

```dart
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';
```

barrel file นี้ export public API ที่รองรับทั้งหมด เช่น `TyphoonOCR`, providers, exceptions, document definitions, enums, validation และ built-in document models ทำให้ consumer ไม่ต้อง import ไฟล์ internal ใต้ `lib/src` โดยตรง

## 2. ภาพรวม architecture

โครงสร้างหลักแบ่งความรับผิดชอบออกจากกันดังนี้:

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

แนวคิดสำคัญคือ **transport layer กับ document parsing แยกออกจากกัน** Provider ไม่ควรรู้วิธีสร้าง `ThaiIdCard` หรือ `Receipt`; หน้าที่ของ provider คือส่ง image + prompt ไปยัง OCR backend แล้วคืน raw response ส่วน `DocumentDefinition<T>` และ parser เป็นผู้ตัดสินใจว่าจะเปลี่ยน raw response ให้เป็น model ใด

ข้อดีคือสามารถเปลี่ยน backend จาก OpenTyphoon Cloud ไป local vLLM หรือ backend ของระบบเองได้โดยไม่ต้องเปลี่ยน parsing/model layer

## 3. `TyphoonOCR` orchestration layer

ไฟล์หลัก:

```text
lib/src/client.dart
```

`TyphoonOCR` เป็นตัวประสานงานของ flow ทั้งหมด โดยทำหน้าที่หลักดังนี้:

1. รับ `File` ของรูปและ generic result type ที่ต้องการ
2. หา `DocumentDefinition<T>` ที่ตรงกับ type นั้น
3. นำ prompt และ mode จาก definition ไปเรียก provider
4. รับ raw OCR response
5. เรียก decoder ของ definition
6. คืน typed document ให้ application

ตัวอย่าง:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

caller จึงไม่ต้องรู้ว่า prompt ของบัตรประชาชนคืออะไร หรือ parser ตัวไหนต้องถูกเรียกเอง

### `TyphoonOCR.fromEnv()`

`fromEnv()` ช่วยสร้าง client จาก runtime environment หรือ `--dart-define` เช่นเลือก provider เป็น `cloud`, `local` หรือ `custom`

เหมาะกับ development, CI และ example app แต่ไม่ควรถือว่า `--dart-define` เป็น secret store เพราะค่าจะถูก compile เข้า application สำหรับ production ควรพิจารณาให้ credential อยู่ฝั่ง backend

## 4. Provider abstraction

interface อยู่ที่:

```text
lib/src/providers/provider.dart
```

provider ทุกตัว implement contract หลัก:

```dart
Future<String> extractRaw({
  required File image,
  required String prompt,
  required String mode,
});
```

จุดสำคัญคือ return type เป็น `String` ไม่ใช่ model เฉพาะชนิด เพื่อไม่ให้ network/API layer ผูกกับ document model

### OpenTyphoon Cloud

ไฟล์:

```text
lib/src/providers/opentyphoon_cloud_provider.dart
```

flow หลักคือ:

1. อ่าน bytes ของ image
2. ตรวจ MIME type
3. encode image เป็น base64
4. สร้าง request แบบ OpenAI-compatible chat completions
5. ใส่ `Authorization: Bearer <api-key>`
6. POST ไปยัง endpoint
7. map HTTP error เป็น `TyphoonApiException`
8. ดึง assistant content ออกมาเป็น raw string

provider รองรับการ inject `http.Client` ทำให้ test HTTP contract ได้โดยไม่ยิง network จริง และ application สามารถใส่ client ที่มี logging/proxy/custom transport policy ได้

### Local vLLM provider

ไฟล์:

```text
lib/src/providers/local_vllm_provider.dart
```

ใช้สำหรับ local หรือ self-hosted OpenAI-compatible endpoint เช่น runtime ที่รันผ่าน vLLM เหมาะกับกรณีต้องการควบคุม infrastructure เอง ลดการส่งข้อมูลออกภายนอก หรือทดสอบ model ภายใน network

### Custom backend provider

ไฟล์:

```text
lib/src/providers/custom_backend_provider.dart
```

เหมาะกับ production mobile app ที่ไม่ต้องการฝัง OpenTyphoon API key ใน client โดย mobile app ส่ง image/prompt/mode ไป backend ของระบบเอง แล้ว backend เป็นผู้ถือ credential และเชื่อมต่อ OCR service อีกชั้นหนึ่ง

## 5. Provider utilities และ typed exceptions

utility กลางอยู่ที่:

```text
lib/src/providers/provider_utils.dart
```

ใช้รวม logic ที่ provider หลายตัวใช้ร่วมกัน เช่น MIME detection และการดึง content จาก OpenAI-compatible response เพื่อลด duplicated code

exception หลักอยู่ที่:

```text
lib/src/exceptions.dart
```

ได้แก่:

- `TyphoonConfigurationException`
- `TyphoonNetworkException`
- `TyphoonTimeoutException`
- `TyphoonApiException`
- `TyphoonParseException`

การมี typed exception ทำให้ application แยก handling ได้ เช่น configuration error อาจต้องแจ้ง developer, timeout อาจ retry ได้, ส่วน API error อาจต้องแสดงข้อความจาก backend

## 6. Document definitions

directory:

```text
lib/src/definitions/
```

`DocumentDefinition<T>` รวมข้อมูลที่จำเป็นต่อ document type หนึ่งชนิดไว้ด้วยกัน:

- `DocumentType`
- OCR prompt
- extraction mode
- decoder

registry นี้ทำให้ `TyphoonOCR.extract<T>()` generic ได้ และยังเปิดให้เพิ่ม document type ใหม่โดยไม่แก้ client core เช่น:

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

แนวทางนี้ช่วยให้ extension point อยู่ที่ configuration แทนการเพิ่ม `if/else` หรือ `switch` ใน `TyphoonOCR`

## 7. Models และ raw data preservation

directory:

```text
lib/src/models/
```

built-in models ได้แก่:

- `ThaiIdCard`
- `Receipt`
- `BankSlip`
- `Passport`
- `GeneralDocument`

ทั้งหมดสืบทอดจาก `TyphoonDocument` ซึ่งเก็บ raw provider output ไว้ ขณะที่ model เฉพาะชนิด expose typed fields ที่ application ใช้งานได้สะดวก

### `rawMap`

structured model เก็บ field จาก provider ไว้ใน `rawMap` แม้ field นั้นยังไม่มี typed property ใน model เวอร์ชันปัจจุบัน ช่วยลด information loss เมื่อ OCR API เพิ่ม field ใหม่ก่อน package จะอัปเดต model

### Thai ID validation

`ThaiIdCard.isValidId` ตรวจ checksum เลขบัตรประชาชนไทย 13 หลักหลัง parse เสร็จ การ OCR อ่านเลขได้สำเร็จและเลขผ่าน checksum เป็นคนละเรื่องกัน จึงแยก validation ออกจาก extraction

นอกจาก checksum ยังมี structured validation layer ที่คืน `ValidationResult<T>` พร้อม issues แบบ error/warning เพื่อให้ application ตัดสินใจเองว่าจะ block, warn หรือยอมรับผล OCR

## 8. Parser

directory:

```text
lib/src/parsers/
```

parser ไม่สมมติว่า model จะตอบ JSON สะอาดเสมอ เพราะ LLM/VLM อาจตอบเป็น markdown fence, มีคำอธิบายก่อน/หลัง JSON หรือมี metadata JSON หลายก้อน

behavior หลักคือ:

1. scan mixed markdown/text หา JSON objects
2. เลือก object ที่ key ใกล้เคียง document type ที่ต้องการมากที่สุด
3. decode known fields เป็น typed model
4. เก็บ raw markdown/raw JSON ไว้ตรวจสอบย้อนหลัง
5. fallback อย่างปลอดภัยเมื่อ recover structured JSON ไม่ได้

จุดนี้เป็น resilience layer สำคัญ เพราะช่วยให้ package ทนต่อ output format ที่เปลี่ยนเล็กน้อยจาก OCR model โดยไม่ crash ทันที

## 9. End-to-end request flow

สำหรับคำสั่ง:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

flow ปกติคือ:

```text
1. App เรียก TyphoonOCR.extract<ThaiIdCard>()
2. Client หา DocumentDefinition ของ ThaiIdCard
3. Client เรียก provider.extractRaw(...)
4. Provider ส่ง image + prompt ไป OCR endpoint
5. Provider คืน raw response text
6. Definition decoder เรียก parser
7. Parser สร้าง ThaiIdCard
8. Client คืน ThaiIdCard ให้ app
9. App ตรวจ card.isValidId, rawMap หรือเรียก validate<T>() เพิ่มได้
```

ถ้าใช้ `extractValidated<T>()` package จะทำ extraction และ validation ต่อเนื่องให้ใน flow เดียว แล้วคืน `ValidationResult<T>` ที่มีทั้ง document และ issues

## 10. Example application

directory:

```text
example/
```

example app ใช้สาธิต integration ฝั่ง UI เช่น camera/gallery selection และการแสดง OCR result โดยตั้งใจไม่ดึง dependency อย่าง `image_picker` เข้ามาเป็น dependency ของ package หลัก

หลักคิดคือ package ควรรับผิดชอบ OCR client/domain logic ส่วน host app เป็นผู้เลือก UX และ media acquisition เอง

## 11. Test suite

directory:

```text
test/
```

test ครอบคลุม client orchestration, parser/model behavior, validation, MIME handling, runtime environment configuration และ HTTP contract ของ providers

provider tests ใช้ mock/fake HTTP client จึงไม่ยิง OpenTyphoon จริงและไม่ต้องมี API key ทำให้ CI deterministic และไม่สร้างค่าใช้จ่ายจาก OCR request

## 12. CI และ release gate

workflow อยู่ที่:

```text
.github/workflows/ci.yml
```

quality gate หลักประกอบด้วย:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# coverage ต้อง >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

นอกจากนี้ยังมี minimum SDK job สำหรับ Flutter 3.16.0 / Dart 3.2 เพื่อกันการเผลอใช้ API ใหม่เกิน version ที่ package ประกาศรองรับ

CI ไม่เรียก cloud OCR จริง จึงไม่ต้องเก็บ API key ใน GitHub Actions และ release ไม่ควร publish หาก format, analyze, tests, coverage, example analysis, minimum SDK หรือ publish dry-run ยังไม่ผ่าน

## 13. หลักคิดในการต่อยอด package

เวลาจะเพิ่ม feature ใหม่ ควรเลือก layer ให้ถูก:

- เพิ่ม backend/protocol ใหม่ → เพิ่ม `TyphoonProvider`
- เพิ่ม document type ใหม่ → เพิ่ม model + `DocumentDefinition<T>` + parser/decoder + validator ตามต้องการ
- เพิ่ม rule ตรวจข้อมูล → เพิ่มหรือปรับ `DocumentValidator<T>`
- เพิ่ม request-level option → พิจารณา `ExtractionOptions`
- เพิ่ม camera/gallery UX → ควรอยู่ใน host/example app ไม่ใช่ core package

การรักษา boundary แบบนี้ช่วยให้ `typhoon_ocr_flutter` ยังเป็น package เดียวที่ใช้งานง่าย แต่ภายในมี separation of concerns ชัดเจนและพร้อมขยายโดยไม่ผูก transport, parsing, validation และ UI เข้าด้วยกัน
