# typhoon_ocr_flutter

[English](README.md)

Flutter client แบบ type-safe สำหรับ Typhoon OCR รองรับทั้ง OpenTyphoon Cloud, local vLLM/OpenAI-compatible host และ backend ของคุณเอง โดยแยก provider ออกจากการ parse document model

## จุดเด่น

- **เปลี่ยน provider ได้** — ใช้ `LocalVllmProvider`, `OpentyphoonCloudProvider` หรือ `CustomBackendProvider` โดยไม่ต้องแก้ extraction logic
- **Type-safe** — รองรับ `extract<ThaiIdCard>()`, `extract<Receipt>()`, `extract<BankSlip>()`, `extract<Passport>()` และ `extract<GeneralDocument>()`
- **ตรวจ checksum บัตรประชาชนไทย** — `ThaiIdCard.isValidId` ตรวจเลขบัตรประชาชน 13 หลัก
- **เหมาะกับแนวทาง PDPA** — production สามารถเก็บ API key และ validation logic ไว้บน backend ของคุณเอง
- **Parser ทนต่อ output ที่ไม่สะอาด** — ดึง JSON object ที่ตรงกับ document type จาก markdown/text ผสมกัน และ fallback ได้เมื่อไม่มี structured JSON
- **เก็บ field ที่ยังไม่รองรับไว้** — typed result มี `rawMap`
- **ควบคุม timeout และ HTTP client ได้** — provider รองรับ injectable `http.Client` และ typed exceptions
- **ต่อยอด document type ได้** — ลงทะเบียน `DocumentDefinition<T>` เพิ่มโดยไม่ต้องแก้ `TyphoonOCR.extract`

## ติดตั้ง

```yaml
dependencies:
  typhoon_ocr_flutter: ^1.1.0
```

จากนั้นรัน:

```bash
flutter pub get
```

## วิธีขอ OpenTyphoon API key

สำหรับใช้งาน OpenTyphoon Cloud:

1. สมัครหรือเข้าสู่ระบบที่ [Typhoon Playground](https://playground.opentyphoon.ai/)
2. ไปที่เมนู **API Keys** ใน Playground/dashboard
3. กด **Create new API key** และตั้งชื่อ key ให้สื่อความหมาย เช่น Development หรือ Production
4. คัดลอก key และเก็บให้ปลอดภัยทันที เพราะเอกสาร OpenTyphoon ระบุว่าจะไม่แสดง secret นี้ซ้ำหลังสร้าง
5. นำ key ไปใช้กับ `OpentyphoonCloudProvider` หรือส่งให้ example ผ่าน `--dart-define=TYPHOON_API_KEY=...`

เอกสารทางการ:

- [Typhoon Quick Start ภาษาไทย](https://docs.opentyphoon.ai/th/quickstart/)
- [Authentication ภาษาไทย](https://docs.opentyphoon.ai/th/authentication/)
- [Typhoon OCR ภาษาไทย](https://docs.opentyphoon.ai/th/ocr/)

> **ความปลอดภัย:** ไม่ควรฝัง API key อายุยาวสำหรับ production ไว้ใน mobile app เพราะค่า `--dart-define` ถูก compile เข้า application และไม่ใช่ secret store สำหรับ production แนะนำให้ใช้ `CustomBackendProvider` แล้วเก็บ OpenTyphoon key ไว้ที่ backend

## Example

### ตัวอย่างขั้นต่ำ: อ่านบัตรประชาชนไทย

```dart
import 'dart:io';

import 'package:typhoon_ocr_flutter/typhoon_ocr_flutter.dart';

Future<void> main() async {
  final ocr = TyphoonOCR(
    provider: OpentyphoonCloudProvider(
      apiKey: 'YOUR_API_KEY',
    ),
  );

  final card = await ocr.extract<ThaiIdCard>(
    File('/path/to/id-card.jpg'),
  );

  print('ID: ${card.idNumber}');
  print('Name: ${card.firstNameTh} ${card.lastNameTh}');
  print('Valid checksum: ${card.isValidId}');
}
```

### ใช้ค่าจาก `--dart-define`

```dart
final ocr = TyphoonOCR.fromEnv();
final card = await ocr.extract<ThaiIdCard>(File('/path/id-card.jpg'));
```

ถ้ารัน Example ใน repo ด้วย OpenTyphoon Cloud ให้เริ่มจาก root ของ repo:

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=cloud \
  --dart-define=TYPHOON_API_KEY=YOUR_KEY
```

รัน Example กับ local vLLM/OpenAI-compatible host:

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=local \
  --dart-define=TYPHOON_BASE_URL=http://127.0.0.1:8000
```

### Example app ใน repo

ใน [`example/`](example/) มี Flutter example ที่:

- ถ่ายรูปบัตรประชาชนจากกล้องหรือเลือกรูปจาก Gallery
- preview รูปก่อน OCR
- เรียก `extract<ThaiIdCard>()`
- แสดง structured result
- ตรวจ checksum เลขบัตรประชาชนไทย

ตัว package หลัก **ไม่ได้** ผูกกับ `image_picker`; dependency ด้าน camera/gallery อยู่ใน example/host app เท่านั้น

ดูเพิ่มเติมที่ [`example/README.md`](example/README.md) และ [`example/lib/main.dart`](example/lib/main.dart)

## Field ของบัตรประชาชนไทย

`ThaiIdCard` มี field หลักดังนี้:

- `idNumber`
- `titleTh`
- `firstNameTh`
- `lastNameTh`
- `dob`
- `address`
- `issueDate`
- `expiryDate`
- `rawMarkdown`
- `rawJson`
- `rawMap`

## Providers

### Local vLLM / OpenAI-compatible host

```dart
final ocr = TyphoonOCR(
  provider: LocalVllmProvider(
    baseUrl: 'http://127.0.0.1:8000',
  ),
);
```

provider จะส่ง request ไปที่ `{baseUrl}/v1/chat/completions` และส่งรูปในรูปแบบ base64 data URL

### OpenTyphoon Cloud

```dart
final ocr = TyphoonOCR(
  provider: OpentyphoonCloudProvider(apiKey: apiKey),
);
```

ค่า default model คือ `typhoon-ocr` และ base URL คือ `https://api.opentyphoon.ai/v1`

### Custom backend

```dart
final ocr = TyphoonOCR(
  provider: CustomBackendProvider(
    baseUrl: 'https://api.example.com',
    headers: {'Authorization': 'Bearer session-token'},
  ),
);
```

custom provider จะส่ง multipart form ไปที่ `{baseUrl}/ocr` โดยมี `file`, `prompt` และ `mode` และรับได้ทั้ง raw markdown หรือ JSON รูปแบบ:

```json
{"markdown":"..."}
```

## การตั้งค่าด้วย `--dart-define`

| Define | ค่า / การใช้งาน |
| --- | --- |
| `TYPHOON_PROVIDER` | `local`, `cloud`, `custom` |
| `TYPHOON_BASE_URL` | จำเป็นสำหรับ `local` และ `custom` |
| `TYPHOON_API_KEY` | จำเป็นสำหรับ `cloud`; ใช้เป็น bearer token สำหรับ `custom` ได้ |
| `TYPHOON_MODEL` | ไม่บังคับ; default เป็น `typhoon-ocr` |

## Document model อื่น

- `Receipt`: branch, items, subtotal, VAT, total และ payment method
- `BankSlip`: ธนาคาร/บัญชี/ชื่อผู้ส่งและผู้รับ, amount, fee, currency, date/time, reference number และ transaction ID
- `Passport`: identity fields, issuing metadata และ `mrzLine1` / `mrzLine2`

ทุก typed document มี `rawMap` สำหรับเก็บ field ที่ provider ส่งกลับมาแต่ model ปัจจุบันยังไม่ได้ประกาศไว้

## Timeout และ Error handling

```dart
final provider = OpentyphoonCloudProvider(
  apiKey: apiKey,
  timeout: const Duration(seconds: 30),
  client: myHttpClient,
);
```

Exception หลัก:

- `TyphoonConfigurationException`
- `TyphoonNetworkException`
- `TyphoonTimeoutException`
- `TyphoonApiException`
- `TyphoonParseException`

## General document

```dart
final document = await ocr.extractGeneral(File('/path/document.png'));
print(document.rawMarkdown);
```

## เพิ่ม document type เอง

```dart
final extended = TyphoonOCR(
  provider: provider,
  definitions: {
    MyDocument: DocumentDefinition<MyDocument>(
      type: DocumentType.general,
      prompt: 'Extract my custom document as JSON ...',
      mode: 'structure',
      decode: (raw) => MyDocument.fromRaw(raw),
    ),
  },
);

final value = await extended.extract<MyDocument>(image);
```

`DocumentDefinition<T>` เป็นเจ้าของ prompt, mode, document type และ decoder ทำให้เพิ่ม type ใหม่ได้โดยไม่ต้องเพิ่ม generic branch ใน `TyphoonOCR.extract`

## Code walkthrough

รายละเอียด architecture, request flow, extension points และหน้าที่ของไฟล์สำคัญอยู่ที่ [`doc/CODE_WALKTHROUGH.md`](doc/CODE_WALKTHROUGH.md)

## Tests และ CI

รัน quality gates ในเครื่องได้ด้วย:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

GitHub Actions จะรัน format/analyze/test เมื่อ push เข้า `main` และเมื่อเปิด Pull Request โดย test ใช้ fake/mock provider จึงไม่ต้องใส่ OpenTyphoon API key ใน CI

## Privacy

OCR ของเอกสารระบุตัวบุคคลอาจเกี่ยวข้องกับข้อมูลส่วนบุคคล ผู้ใช้งาน package ต้องกำหนด deployment, logging, retention, transport security และ access control ให้เหมาะกับระบบและข้อกำหนดด้าน privacy ของตนเอง ตัว package ไม่ persist input/output OCR โดยอัตโนมัติ

## License

MIT
