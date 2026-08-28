# Code Walkthrough

This document explains the architecture and execution flow of `typhoon_ocr_flutter` 1.3.x. It covers typed image OCR, multi-page PDF extraction, structured validation, built-in Thai document models, provider boundaries, parsing, testing, and extension points.

## 1. Public entry point

Applications should normally import only:

```dart
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';
```

The barrel file `lib/typhoon_ocr_flutter.dart` exports the supported public API: `TyphoonOCR`, providers, document definitions, `DocumentType`, typed models, validation types, PDF rasterization hooks, and typed exceptions.

## 2. High-level architecture

```text
Application
   |
   v
TyphoonOCR
   |
   +--> DocumentDefinition<T>
   |      - DocumentType
   |      - prompt
   |      - mode
   |      - decoder
   |
   +--> TyphoonProvider
   |      +--> OpentyphoonCloudProvider
   |      +--> LocalVllmProvider
   |      +--> CustomBackendProvider
   |
   +--> optional PDF rasterizer
          PDF bytes -> ordered PNG pages

Provider raw output
   |
   v
TyphoonParser / definition decoder
   |
   v
Typed TyphoonDocument
   |
   +--> rawMarkdown
   +--> rawJson
   +--> rawMap
   |
   v
optional DocumentValidator<T>
   |
   v
ValidationResult<T>
```

The key architectural rule is separation of concerns: providers transport images and return raw OCR output; definitions describe a document schema; parsers create typed models; validators evaluate extracted values independently of transport.

## 3. `TyphoonOCR`

Main file: `lib/src/client.dart`.

For image extraction:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

The client:

1. resolves the `DocumentDefinition<T>`;
2. combines the definition with request-level `ExtractionOptions`;
3. calls `provider.extractRaw(...)`;
4. sends raw provider output to the definition decoder;
5. returns the typed document.

`withDefinition(...)` and `withValidator(...)` return clients with additional registrations without changing the existing extraction pipeline.

### Validation APIs

```dart
final result = ocr.validate(document);
```

or:

```dart
final result = await ocr.extractValidated<ThaiTaxInvoice>(image);
```

`ValidationResult<T>` retains the document and exposes issues separated by severity. Extraction success and business/data validity are intentionally distinct concepts.

### `TyphoonOCR.fromEnv()`

`fromEnv()` selects cloud, local, or custom providers from runtime environment values or `--dart-define`. This is useful for examples and development, but compile-time defines are not a secure production secret store.

## 4. Provider abstraction

Interface: `lib/src/providers/provider.dart`.

Providers implement a raw transport contract:

```dart
Future<String> extractRaw({
  required File image,
  required String prompt,
  required String mode,
});
```

The return value is deliberately a raw `String`; provider implementations do not construct `ThaiIdCard`, `Receipt`, or other domain models.

### OpenTyphoon Cloud

`lib/src/providers/opentyphoon_cloud_provider.dart`

The provider reads image bytes, determines MIME type, sends an OpenAI-compatible vision request, applies the configured model/timeout, maps network/API failures to typed exceptions, and returns assistant content.

### Local vLLM / OpenAI-compatible provider

`lib/src/providers/local_vllm_provider.dart`

This targets a local or self-hosted OpenAI-compatible endpoint. The document definition and parser layers remain identical to the cloud path.

### Custom backend

`lib/src/providers/custom_backend_provider.dart`

This uploads `file`, `prompt`, and `mode` as multipart data to an application-owned backend. It is the preferred boundary when production API credentials should stay off the mobile client.

## 5. Provider utilities and typed exceptions

Shared utilities live in `lib/src/providers/provider_utils.dart`, including MIME handling and OpenAI-compatible response extraction.

Typed exceptions live in `lib/src/exceptions.dart`:

- `TyphoonConfigurationException`
- `TyphoonNetworkException`
- `TyphoonTimeoutException`
- `TyphoonApiException`
- `TyphoonParseException`
- `TyphoonPdfException`
- `TyphoonPdfPageException`

`TyphoonPdfPageException.pageNumber` is one-based so applications can report the failing source PDF page directly.

## 6. Document definitions

Definitions live under `lib/src/definitions/`.

`DocumentDefinition<T>` owns four things:

- `DocumentType`
- OCR prompt
- extraction mode
- decoder

Built-in definitions are created by `createDefaultDocumentDefinitions()`.

A consumer can add another model without editing `TyphoonOCR`:

```dart
final extended = TyphoonOCR(
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

This registry design avoids a growing document-specific switch inside the client.

## 7. Built-in models

Models live under `lib/src/models/` and extend `TyphoonDocument`.

Built-in types in 1.3.x are:

- `ThaiIdCard`
- `ThaiDriverLicense`
- `ThaiTaxInvoice`
- `TabienBaan`
- `Receipt`
- `BankSlip`
- `Passport`
- `GeneralDocument`

Every structured model preserves provider data through `rawMarkdown`, `rawJson`, and an unmodifiable `rawMap` snapshot.

### Thai ID card

Provides the standard Thai identity fields and `ThaiIdCard.isValidId`, which performs the 13-digit checksum locally.

### Thai driver license

Provides license number, Thai/English names, DOB, issue/expiry dates, license class, optional national ID, and issuing metadata. Its validator only checks strong invariants: complete Thai IDs and date order when both dates can be interpreted.

### Thai tax invoice

This is intentionally separate from `Receipt`. It contains seller/buyer identities and tax IDs, branch/head-office metadata, invoice number/date, line items, subtotal, VAT rate/amount, total, and currency.

OCR numeric strings such as `1,000.00` and `7%` are normalized before numeric parsing. Validation uses OCR-safe arithmetic tolerance and does not assume every tax document must use a 7% VAT rate.

### Tabien Baan

Provides house registration metadata, house code/number, address components, registrar metadata, and ordered `TabienBaanMember` entries.

Regional address aliases are handled conservatively: `tambon`/`khwaeng` map to neutral `subdistrict`, while `amphoe`/`khet` map to neutral `district`. Alias selection uses the first non-empty value, and original provider fields remain available in `rawMap`.

Partial-page scans are valid inputs; absence of unseen members or pages is not treated as proof that the source registration is incomplete.

## 8. Parser

Parser: `lib/src/parsers/parser.dart`.

Real VLM responses are not always clean JSON, so `TyphoonParser`:

1. scans mixed text/Markdown for syntactically valid JSON objects;
2. scores objects against expected keys for the requested model;
3. chooses the best matching object;
4. decodes known fields into the typed model;
5. preserves the exact selected JSON substring and complete raw response;
6. falls back safely when structured JSON cannot be recovered.

The expected-key sets include all built-in structured document types, including the 1.3.x Thai models.

## 9. Structured validation

Validation code lives under `lib/src/validation/`.

`createDefaultDocumentValidators()` registers validators for built-in structured models. Validators return `ValidationIssue` values with `error` or `warning` severity.

Examples of current invariants:

- Thai ID: required identity fields and checksum.
- Thai driver license: required license number, complete-ID checksum, parseable issue/expiry ordering.
- Thai tax invoice: positive/finite totals, VAT arithmetic, subtotal/total consistency, item values, complete tax-ID checksum.
- Tabien Baan: warnings for missing house identity/province and complete member-ID checks without rejecting partial scans.
- Receipt: totals, VAT/subtotal consistency, and item values.
- Bank slip: amount/fee and basic transfer identity fields.
- Passport: number format, identity fields, country code, sex marker, and basic TD3 MRZ consistency.

Warnings are preferred when OCR ambiguity or document-generation differences make a strict error unsafe.

## 10. Multi-page PDF extraction

PDF rasterization is implemented through `lib/src/pdf_rasterizer.dart` and orchestrated by `TyphoonOCR.extractFromPdf<T>()`.

```dart
final pages = await ocr.extractFromPdf<Receipt>(
  File('invoices.pdf'),
  dpi: 144,
);
```

Flow:

```text
PDF File
  -> read bytes
  -> PdfPageRasterizer
  -> ordered PNG page stream
  -> temporary page image
  -> existing extract<T>() pipeline
  -> delete page image immediately
  -> append typed result
  -> repeat sequentially
  -> List<T>
```

The default rasterizer uses `Printing.raster`. Processing is sequential to preserve page order and avoid request bursts. Temporary page files are removed after each page, and the temporary directory is cleaned in the outer `finally` path.

The public semantics are fail-whole-operation: if one page fails, extraction throws `TyphoonPdfPageException` with the one-based page number instead of silently dropping that page.

A custom `PdfPageRasterizer` can be injected for testing or alternative rendering environments.

## 11. End-to-end flows

### Image + typed parsing

```text
App -> extract<ThaiIdCard>()
    -> resolve definition
    -> provider.extractRaw()
    -> parser
    -> ThaiIdCard
    -> app
```

### Image + validation

```text
App -> extractValidated<ThaiTaxInvoice>()
    -> extract<ThaiTaxInvoice>()
    -> ThaiTaxInvoiceValidator
    -> ValidationResult<ThaiTaxInvoice>
```

### PDF

```text
App -> extractFromPdf<Receipt>()
    -> rasterize page 1 -> extract<Receipt>()
    -> rasterize page 2 -> extract<Receipt>()
    -> ...
    -> ordered List<Receipt>
```

## 12. Example application

The `example/` application demonstrates camera/gallery integration for Thai ID OCR while keeping `image_picker` and UI-specific dependencies outside the package itself.

The package is therefore usable with any host capture flow that can provide an image `File`.

## 13. Tests

Tests live in `test/` and cover:

- client orchestration and request options;
- provider HTTP contracts and environment configuration;
- parser recovery from mixed model output;
- built-in models and raw data preservation;
- structured validation;
- Thai driver-license, tax-invoice, and Tabien Baan regression cases;
- PDF ordering, page failure, empty page streams, and DPI validation using an injected fake rasterizer;
- MIME handling and typed exceptions.

Network tests use fake/mock clients and do not require an OpenTyphoon API key.

## 14. CI and compatibility

`.github/workflows/ci.yml` enforces:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# line coverage >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

A separate job validates the declared compatibility floor with Flutter 3.16.0 / Dart 3.2. The default PDF dependency remains on the compatible `printing` 5.12.x line.

---

# Code Walkthrough ภาษาไทย

ส่วนนี้อธิบาย architecture และ execution flow ของ `typhoon_ocr_flutter` 1.3.x ให้ตรงกับ implementation ปัจจุบัน ทั้ง image OCR, PDF หลายหน้า, structured validation และ document model ไทยชุดใหม่

## 1. Public API

consumer ควร import ผ่าน barrel file เดียว:

```dart
import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';
```

ไฟล์ `lib/typhoon_ocr_flutter.dart` export `TyphoonOCR`, providers, definitions, `DocumentType`, models, validation, PDF rasterizer hooks และ typed exceptions ที่เป็น public API

## 2. Architecture หลัก

```text
Application
   |
   v
TyphoonOCR
   |
   +--> DocumentDefinition<T>
   |      - type / prompt / mode / decoder
   |
   +--> TyphoonProvider
   |      - OpenTyphoon Cloud
   |      - local vLLM / OpenAI-compatible
   |      - custom backend
   |
   +--> PDF rasterizer (เมื่ออ่าน PDF)

raw OCR output
   |
   v
TyphoonParser
   |
   v
Typed TyphoonDocument
   |
   v
DocumentValidator<T> (optional)
   |
   v
ValidationResult<T>
```

หลักสำคัญคือ **transport, parsing และ validation แยกออกจากกัน** provider ไม่ต้องรู้จัก field ของบัตรประชาชนหรือใบกำกับภาษี ส่วน parser ไม่ต้องรู้ว่า request ถูกส่งผ่าน cloud, local หรือ backend ของแอป

## 3. `TyphoonOCR`

ไฟล์ `lib/src/client.dart` เป็น orchestration layer

ตัวอย่าง image extraction:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

client จะหา `DocumentDefinition<ThaiIdCard>`, นำ prompt/mode ไปเรียก provider, รับ raw output, ส่งเข้า decoder/parser แล้วคืน `ThaiIdCard`

ถ้าต้องการ extraction + validation ในคำสั่งเดียว:

```dart
final result = await ocr.extractValidated<ThaiTaxInvoice>(image);
```

หรือมี document อยู่แล้ว:

```dart
final result = ocr.validate(document);
```

แนวคิดคือ OCR สำเร็จไม่ได้แปลว่าข้อมูลต้อง valid เสมอ จึงแยกสองขั้นตอนออกจากกันอย่างชัดเจน

## 4. Provider layer

contract อยู่ที่ `lib/src/providers/provider.dart`:

```dart
Future<String> extractRaw({
  required File image,
  required String prompt,
  required String mode,
});
```

return เป็น raw `String` เพื่อให้ network/API layer ไม่ผูกกับ model

- `OpentyphoonCloudProvider` ส่ง image แบบ OpenAI-compatible vision request
- `LocalVllmProvider` ใช้กับ local/self-hosted OpenAI-compatible endpoint
- `CustomBackendProvider` ส่ง multipart ไป backend ของระบบ เหมาะกับ production ที่ไม่ต้องการฝัง API key ใน mobile app

provider รองรับ timeout และ injectable `http.Client` เพื่อให้ test และปรับ transport policy ได้

## 5. Typed exceptions

exception หลักอยู่ใน `lib/src/exceptions.dart`:

- configuration/network/timeout/API/parse exceptions
- `TyphoonPdfException`
- `TyphoonPdfPageException`

กรณี PDF ถ้าหน้าใด OCR ไม่สำเร็จ `pageNumber` จะเป็นเลขหน้าแบบเริ่มจาก 1 ทำให้ UI แจ้งผู้ใช้ได้ตรงกับเอกสารจริง

## 6. Document definitions

`DocumentDefinition<T>` รวม `DocumentType`, prompt, mode และ decoder ของ document type หนึ่งชนิดไว้ด้วยกัน

จึงสามารถเพิ่ม model ใหม่โดย register definition โดยไม่ต้องแก้ `TyphoonOCR.extract<T>()` core

built-in definitions อยู่ใน `lib/src/definitions/default_definitions.dart`

## 7. Built-in models ใน 1.3.x

ปัจจุบันมี:

- `ThaiIdCard`
- `ThaiDriverLicense`
- `ThaiTaxInvoice`
- `TabienBaan`
- `Receipt`
- `BankSlip`
- `Passport`
- `GeneralDocument`

structured model ทุกตัวเก็บทั้ง typed fields และ raw data ผ่าน `rawMarkdown`, `rawJson`, `rawMap`

### `ThaiDriverLicense`

เก็บเลขใบขับขี่, ชื่อไทย/อังกฤษ, วันเกิด, วันออก/หมดอายุ, ประเภทใบอนุญาต, national ID เมื่อมี และข้อมูล authority/province

validator จะไม่บังคับ historical format ใด format หนึ่ง แต่ตรวจ checksum เมื่อ national ID ครบ 13 หลัก และตรวจ issue date <= expiry date เฉพาะเมื่อ parse วันที่ได้จริง

### `ThaiTaxInvoice`

แยก model จาก `Receipt` เพราะ semantics ต่างกันชัดเจน มี seller/buyer tax ID, branch/สำนักงานใหญ่, invoice metadata, items, subtotal, VAT rate/amount, total และ currency

ตัวเลข OCR ที่มาเป็น string เช่น `"1,000.00"` หรือ `"7%"` จะ normalize ก่อน parse เพื่อไม่ให้ silently กลายเป็น 0

validator ตรวจ arithmetic ด้วย tolerance ที่เผื่อ OCR rounding และ **ไม่บังคับว่าทุกเอกสารต้อง VAT 7%**

### `TabienBaan`

เก็บ house code/เลขที่บ้าน/registration metadata, address components และ `TabienBaanMember` ตามลำดับ source

คำ `ตำบล/แขวง` map เข้า `subdistrict` และ `อำเภอ/เขต` map เข้า `district` โดยเลือก alias ตัวแรกที่ไม่ว่าง และยังเก็บ field ต้นฉบับทั้งหมดใน `rawMap`

validator ตั้งใจ tolerant ต่อ partial scan เพราะการไม่เห็นสมาชิกหรือบางหน้าไม่ได้แปลว่าไม่มีข้อมูลนั้นในทะเบียนบ้านต้นฉบับ

## 8. Parser

`TyphoonParser` ใน `lib/src/parsers/parser.dart` รองรับ output ที่มี markdown, metadata JSON หรือหลาย JSON object

ขั้นตอนหลัก:

1. scan หา JSON object ที่ parse ได้
2. เทียบ key กับ expected keys ของ document type
3. เลือก object ที่ match มากที่สุด
4. สร้าง typed model
5. เก็บ raw JSON substring และ raw response ทั้งหมด
6. fallback อย่างปลอดภัยเมื่อไม่มี structured JSON ที่ recover ได้

expected keys รองรับ document ไทยใหม่ทั้งสามตัวแล้ว

## 9. Structured validation

validation อยู่ใน `lib/src/validation/`

`ValidationResult<T>` แยก issue เป็น error/warning ทำให้ application เลือก policy เองว่าจะ block หรือแค่แจ้งเตือน

ตัวอย่าง invariants:

- Thai ID: required fields + checksum
- ใบขับขี่: license number, complete national ID checksum, date order
- ใบกำกับภาษี: finite/positive totals, subtotal/VAT/total consistency, VAT calculation, item values, complete tax-ID checksum
- ทะเบียนบ้าน: house/province warnings และ member ID checksum เฉพาะเลขที่ครบ
- Receipt/BankSlip/Passport: validation ตาม semantics ของแต่ละเอกสาร

กรณีข้อมูล OCR กำกวมหรือ format เอกสารเปลี่ยนตามยุค จะ prefer warning มากกว่า hard error

## 10. PDF หลายหน้า

API:

```dart
final receipts = await ocr.extractFromPdf<Receipt>(
  File('invoices.pdf'),
  dpi: 144,
);
```

flow จริงคือ:

```text
PDF bytes
 -> Printing.raster / PdfPageRasterizer
 -> PNG page 1
 -> extract<T>() เดิม
 -> ลบ temp page 1
 -> PNG page 2
 -> extract<T>() เดิม
 -> ...
 -> List<T> ตามลำดับหน้า
```

ไม่ได้ส่ง raw PDF เข้า OpenAI-compatible `image_url` โดยตรง เพราะ provider contract ปัจจุบันเป็น image-oriented การ rasterize ก่อนจึงทำให้ provider abstraction เดิมใช้ต่อได้ทุก backend

ประมวลผลแบบ sequential เพื่อรักษาลำดับหน้าและไม่ burst request ถ้าหน้าใด fail จะ fail ทั้ง operation พร้อม `TyphoonPdfPageException.pageNumber` แทนการ drop หน้าเงียบ ๆ

`PdfPageRasterizer` inject ได้ ทำให้ unit test ไม่ต้องใช้ native PDF engine และเปิดทางให้ใช้ renderer อื่นในอนาคต

## 11. End-to-end flow

Image:

```text
App -> extract<T>() -> definition -> provider -> raw text -> parser -> typed model
```

Image + validation:

```text
App -> extractValidated<T>() -> extract<T>() -> validator -> ValidationResult<T>
```

PDF:

```text
App -> extractFromPdf<T>() -> rasterize ทีละหน้า -> extract<T>() -> ordered List<T>
```

## 12. Example app

`example/` เน้น Thai ID camera/gallery integration และตั้งใจเก็บ UI dependency เช่น `image_picker` ไว้ฝั่ง host app ไม่ดึงเข้ามาใน package หลัก

ดังนั้น package OCR core ยังไม่ผูกกับวิธี capture รูปของ application

## 13. Tests

ชุด test ครอบคลุม client orchestration, providers, parser, models, validation, Thai models ใหม่, numeric normalization, address alias fallback, PDF ordering/failure/empty stream/DPI และ MIME handling

PDF tests ใช้ fake rasterizer และ provider tests ใช้ mock client จึงไม่ต้องมี API key หรือ native renderer ใน CI

## 14. CI และ compatibility

CI ตรวจ:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
# coverage >= 80%
(cd example && flutter pub get && flutter analyze)
dart pub publish --dry-run
```

มี minimum-SDK job แยกสำหรับ Flutter 3.16.0 / Dart 3.2 และ dependency `printing` ถูกจำกัดอยู่สาย 5.12.x เพื่อไม่ยก compatibility floor โดยไม่ตั้งใจ
