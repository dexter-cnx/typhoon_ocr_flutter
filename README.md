# typhoon_ocr_flutter

Type-safe Flutter client for Typhoon OCR. It supports local OpenAI-compatible vLLM hosts, OpenTyphoon Cloud, and your own backend without coupling document parsing to a specific host.

## Features

- **Host agnostic** — swap `LocalVllmProvider`, `OpentyphoonCloudProvider`, or `CustomBackendProvider` without changing extraction code.
- **Type safe** — `extract<ThaiIdCard>()`, `extract<Receipt>()`, `extract<BankSlip>()`, `extract<Passport>()`, and `extract<GeneralDocument>()`.
- **Thai ID checksum** — `ThaiIdCard.isValidId` performs the standard 13-digit checksum validation.
- **PDPA-friendly deployment option** — keep credentials and validation logic on your own backend with `CustomBackendProvider`.
- **Resilient parsing** — extracts the first valid JSON object from mixed markdown/text and falls back without crashing when structured JSON is unavailable.
- **Raw field access** — every parsed typed result exposes a read-only-by-convention `rawMap` snapshot so newly returned OCR fields are not lost.
- **Operational controls** — providers support injectable `http.Client` instances and configurable request timeouts with typed exceptions.
- **Extensible definitions** — register an additional `DocumentDefinition<T>` without changing `TyphoonOCR` extraction logic.

## Installation

```yaml
dependencies:
  typhoon_ocr_flutter: ^1.0.0
```

## Thai ID card

```dart
final ocr = TyphoonOCR(
  provider: OpentyphoonCloudProvider(apiKey: apiKey),
);

final card = await ocr.extract<ThaiIdCard>(File('/path/id-card.jpg'));

print(card.firstNameTh);
print(card.lastNameTh);
print(card.isValidId);
```

Returned Thai ID fields:

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

The provider posts to `{baseUrl}/v1/chat/completions` and sends the image as a base64 data URL.

### OpenTyphoon Cloud

```dart
final ocr = TyphoonOCR(
  provider: OpentyphoonCloudProvider(apiKey: '...'),
);
```

### Custom backend

```dart
final ocr = TyphoonOCR(
  provider: CustomBackendProvider(
    baseUrl: 'https://api.example.com',
    headers: {'Authorization': 'Bearer session-token'},
  ),
);
```

The custom provider posts multipart form data to `{baseUrl}/ocr` with:

- `file`
- `prompt`
- `mode`

It accepts either raw markdown or JSON shaped as:

```json
{"markdown":"..."}
```

## `--dart-define` configuration

```dart
final ocr = TyphoonOCR.fromEnv();
```

Supported defines:

| Define | Values / usage |
| --- | --- |
| `TYPHOON_PROVIDER` | `local`, `cloud`, `custom` |
| `TYPHOON_BASE_URL` | Required for `local` and `custom` |
| `TYPHOON_API_KEY` | Required for `cloud`; optional bearer token for `custom` |
| `TYPHOON_MODEL` | Optional; defaults to `typhoon-ocr` |

Do not ship a long-lived production API key inside a mobile app. `--dart-define` values are compiled into the application and are not a secret store. Prefer a custom backend for production credentials and sensitive workflows.


## Rich document fields

Built-in structured models include practical fields beyond the minimum schema:

- `Receipt`: branch, items, subtotal, VAT, total, and payment method.
- `BankSlip`: sender/receiver bank, account, name, amount, fee, currency, date/time, reference number, and transaction ID.
- `Passport`: identity fields, issuing metadata, and `mrzLine1` / `mrzLine2`.

All parsed typed documents also expose `rawMap` for provider fields that are not represented by the current model. The built-in parsers wrap this map with `Map.unmodifiable`.

## Timeout and error handling

Each built-in provider accepts a timeout and an optional `http.Client`:

```dart
final provider = OpentyphoonCloudProvider(
  apiKey: apiKey,
  timeout: const Duration(seconds: 30),
  client: myHttpClient,
);
```

Provider failures use typed exceptions: `TyphoonConfigurationException`, `TyphoonNetworkException`, `TyphoonTimeoutException`, `TyphoonApiException`, and `TyphoonParseException`.

## General documents

```dart
final document = await ocr.extractGeneral(File('/path/document.png'));
print(document.rawMarkdown);
```

## Custom document definition

`TyphoonOCR` uses a type-to-definition registry. A package extension can register another model without modifying the client extraction logic:

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

A custom `DocumentDefinition<T>` owns its prompt, mode, document type, and decoder, so extending the package does not require another generic-type branch inside `TyphoonOCR.extract`.

## Example app

See `example/lib/main.dart` for a camera/gallery Thai ID card scanner that previews the image, runs `extract<ThaiIdCard>()`, displays extracted fields, and checks the Thai ID checksum.

## Privacy

OCR of identity documents can involve personal data. Choose deployment, logging, retention, transport security, and backend access controls appropriate to your application and applicable privacy requirements. This package does not itself persist OCR input or output.

## License

MIT
