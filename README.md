# typhoon_ocr_flutter

[ภาษาไทย](README_TH.md)

Type-safe Flutter client for Typhoon OCR. It supports local OpenAI-compatible vLLM hosts, OpenTyphoon Cloud, and your own backend without coupling document parsing to a specific host.

## Features

- **Host agnostic** — swap `LocalVllmProvider`, `OpentyphoonCloudProvider`, or `CustomBackendProvider` without changing extraction code.
- **Type safe** — built-in models include `ThaiIdCard`, `ThaiDriverLicense`, `ThaiTaxInvoice`, `TabienBaan`, `Receipt`, `BankSlip`, `Passport`, and `GeneralDocument`.
- **Multi-page PDF** — `extractFromPdf<T>()` rasterizes every page and returns `List<T>` in source-page order.
- **Thai validation** — built-in validators cover Thai ID checksums, driver-license dates, tax-invoice arithmetic, and conservative Tabien Baan member checks.
- **PDPA-friendly deployment option** — keep credentials and validation logic on your own backend with `CustomBackendProvider`.
- **Resilient parsing** — extracts the best matching valid JSON object from mixed markdown/text and falls back without crashing when structured JSON is unavailable.
- **Raw field access** — every parsed typed result exposes a read-only-by-convention `rawMap` snapshot so newly returned OCR fields are not lost.
- **Operational controls** — providers support injectable `http.Client` instances and configurable request timeouts with typed exceptions.
- **Extensible definitions** — register an additional `DocumentDefinition<T>` without changing `TyphoonOCR` extraction logic.

## Installation

```yaml
dependencies:
  typhoon_ocr_flutter: ^1.3.0
```

Then run:

```bash
flutter pub get
```

## Getting an OpenTyphoon API key

For the hosted OpenTyphoon API:

1. Sign up or sign in to the [Typhoon Playground](https://playground.opentyphoon.ai/).
2. Open **API Keys** in the Playground/dashboard.
3. Choose **Create new API key** and give the key a descriptive name.
4. Copy the key immediately and store it securely. OpenTyphoon documents that the secret is not shown again after creation.
5. Use the key with `OpentyphoonCloudProvider` or pass it to the demo with `--dart-define=TYPHOON_API_KEY=...`.

Official references:

- [Typhoon Quick Start](https://docs.opentyphoon.ai/en/quickstart/)
- [Typhoon Authentication](https://docs.opentyphoon.ai/en/authentication/)
- [Typhoon OCR documentation](https://docs.opentyphoon.ai/en/ocr/)

> **Security:** do not embed a long-lived production API key in a mobile application. `--dart-define` values are compiled into the application and are not a secret store. For production, prefer `CustomBackendProvider` and keep the OpenTyphoon key on your backend.

## Example

### Minimal Thai ID extraction

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

### Thai driver license

```dart
final license = await ocr.extract<ThaiDriverLicense>(
  File('/path/to/driver-license.jpg'),
);
final validation = ocr.validate(license);

print(license.licenseNumber);
print('${license.firstNameTh} ${license.lastNameTh}');
print(validation.warnings);
```

### Thai tax invoice

```dart
final invoice = await ocr.extract<ThaiTaxInvoice>(
  File('/path/to/tax-invoice.jpg'),
);

print(invoice.sellerTaxId);
print(invoice.invoiceNumber);
print(invoice.vatAmount);
print(invoice.total);
```

### Tabien Baan

```dart
final registration = await ocr.extract<TabienBaan>(
  File('/path/to/tabien-baan.jpg'),
);

print('${registration.houseNumber} ${registration.district}');
for (final member in registration.members) {
  print('${member.firstNameTh} ${member.lastNameTh}');
}
```

`TabienBaan` is intentionally tolerant of partial-page scans. Missing pages or members are not treated as proof that the source registration is incomplete.

### Multi-page PDF extraction

```dart
final receipts = await ocr.extractFromPdf<Receipt>(
  File('/path/to/invoices.pdf'),
);

for (final receipt in receipts) {
  print('${receipt.merchantName}: ${receipt.total}');
}
```

PDF pages are rasterized to PNG and processed sequentially in source-page order. The default resolution is 144 DPI and can be changed with `dpi:`. If a page fails, `TyphoonPdfPageException.pageNumber` identifies the failing page using a one-based page number; the method does not silently drop failed pages.

The default rasterizer is backed by the Flutter `printing` plugin. Advanced users can inject `pdfPageRasterizer:` into `TyphoonOCR` to integrate a different PDF renderer or to test without a platform PDF engine.

### Configure from `--dart-define`

```dart
final ocr = TyphoonOCR.fromEnv();
final card = await ocr.extract<ThaiIdCard>(File('/path/id-card.jpg'));
```

To run the repository example app with OpenTyphoon Cloud, start from the repository root:

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=cloud \
  --dart-define=TYPHOON_API_KEY=YOUR_KEY
```

Run the example with a local OpenAI-compatible/vLLM host:

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=local \
  --dart-define=TYPHOON_BASE_URL=http://127.0.0.1:8000
```

### Full example application

The repository contains a Flutter example app under [`example/`](example/) that:

- captures a Thai ID image with the camera or selects one from the gallery;
- previews the selected image;
- runs `extract<ThaiIdCard>()`;
- renders the structured result; and
- validates the Thai national ID checksum.

The package itself does **not** depend on `image_picker`; camera/gallery dependencies stay in the host/example application.

See [`example/README.md`](example/README.md) and [`example/lib/main.dart`](example/lib/main.dart).

## Built-in Thai document fields

### Thai ID card

`ThaiIdCard` exposes ID number, Thai title/name, DOB, address, issue/expiry dates, and raw provider data.

### Thai driver license

`ThaiDriverLicense` exposes license number, Thai/English name fields, DOB, issue/expiry dates, license class, national ID when present, and issuing authority/province metadata.

### Thai tax invoice

`ThaiTaxInvoice` exposes seller/buyer identities and tax IDs, branch/head-office label, invoice number/date, line items, subtotal, VAT rate/amount, total, and currency. Validation checks arithmetic with OCR-safe tolerance and does not require every invoice to use a 7% VAT rate.

### Tabien Baan

`TabienBaan` exposes house registration/book metadata, house code/number, village/building, road, subdistrict, district, province, postal code, registrar metadata, and ordered `TabienBaanMember` entries. Bangkok (`khwaeng`/`khet`) and provincial (`tambon`/`amphoe`) aliases map to neutral `subdistrict`/`district` fields without changing the preserved `rawMap`.

## Providers

### Local vLLM / OpenAI-compatible host

```dart
final ocr = TyphoonOCR(
  provider: LocalVllmProvider(
    baseUrl: 'http://127.0.0.1:8000',
  ),
);
```

The provider posts to `{baseUrl}/v1/chat/completions` and sends the image as a base64 data URL.

### OpenTyphoon Cloud

```dart
final ocr = TyphoonOCR(
  provider: OpentyphoonCloudProvider(apiKey: apiKey),
);
```

The default model is `typhoon-ocr` and the default base URL is `https://api.opentyphoon.ai/v1`.

### Custom backend

```dart
final ocr = TyphoonOCR(
  provider: CustomBackendProvider(
    baseUrl: 'https://api.example.com',
    headers: {'Authorization': 'Bearer session-token'},
  ),
);
```

The custom provider posts multipart form data to `{baseUrl}/ocr` with `file`, `prompt`, and `mode`. It accepts either raw markdown or JSON shaped as:

```json
{"markdown":"..."}
```

## `--dart-define` configuration

Supported defines:

| Define | Values / usage |
| --- | --- |
| `TYPHOON_PROVIDER` | `local`, `cloud`, `custom` |
| `TYPHOON_BASE_URL` | Required for `local` and `custom` |
| `TYPHOON_API_KEY` | Required for `cloud`; optional bearer token for `custom` |
| `TYPHOON_MODEL` | Optional; defaults to `typhoon-ocr` |

## Other structured document fields

- `Receipt`: branch, items, subtotal, VAT, total, and payment method.
- `BankSlip`: sender/receiver bank, account, name, amount, fee, currency, date/time, reference number, and transaction ID.
- `Passport`: identity fields, issuing metadata, and `mrzLine1` / `mrzLine2`.

All parsed typed documents expose `rawMap` for provider fields that are not represented by the current model. Built-in parsers wrap this map with `Map.unmodifiable`.

## Timeout and error handling

Each built-in provider accepts a timeout and an optional `http.Client`:

```dart
final provider = OpentyphoonCloudProvider(
  apiKey: apiKey,
  timeout: const Duration(seconds: 30),
  client: myHttpClient,
);
```

Provider and PDF failures use typed exceptions:

- `TyphoonConfigurationException`
- `TyphoonNetworkException`
- `TyphoonTimeoutException`
- `TyphoonApiException`
- `TyphoonParseException`
- `TyphoonPdfException`
- `TyphoonPdfPageException`

## General documents

```dart
final document = await ocr.extractGeneral(File('/path/document.png'));
print(document.rawMarkdown);
```

## Custom document definition

`TyphoonOCR` uses a type-to-definition registry. An extension can register another model without modifying the client extraction logic:

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

final value = await extended.extract<MyDocument>(image);
```

A custom `DocumentDefinition<T>` owns its prompt, mode, document type, and decoder.

## Code walkthrough

Architecture, request flow, extension points, and file-by-file responsibilities are documented in [`doc/CODE_WALKTHROUGH.md`](doc/CODE_WALKTHROUGH.md).

## Tests and CI

Run the local quality gates with:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

GitHub Actions runs the same format/analyze/test gates on pushes to `main` and on pull requests. Tests use fake/mock providers and do not require an OpenTyphoon API key. PDF unit tests inject a fake rasterizer, so CI does not require a platform PDF renderer.

## Privacy

OCR of identity documents can involve personal data. Choose deployment, logging, retention, transport security, and backend access controls appropriate to your application and applicable privacy requirements. This package does not itself persist OCR input or output.

## License

MIT
