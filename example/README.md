# Typhoon OCR example

This example keeps capture/file-selection dependencies outside the package itself. It demonstrates both Thai ID image OCR and generic multi-page PDF OCR.

The commands below assume you start from the repository root.

## Demo flows

### Thai ID image OCR

The home screen uses `image_picker` to capture a Thai ID card or select an image from the gallery, then calls:

```dart
final card = await ocr.extract<ThaiIdCard>(image);
```

### Generic multi-page PDF OCR

Tap **Open multi-page PDF demo**, then **Pick PDF**. The demo uses `file_selector` to choose a `.pdf` file and calls:

```dart
final pages = await ocr.extractFromPdf<GeneralDocument>(pdfFile);
```

`GeneralDocument` is intentional here: the example is demonstrating that `typhoon_ocr_flutter` can rasterize and OCR arbitrary multi-page PDFs without implying that PDFs must contain receipts or another specific schema.

The UI renders `Page 1`, `Page 2`, and so on from `GeneralDocument.rawMarkdown` in source-page order. If OCR extraction fails on a rasterized page, the demo displays `TyphoonPdfPageException.pageNumber`. Rasterizer or temporary-file failures are shown as the broader `TyphoonPdfException`.

## Run with OpenTyphoon Cloud

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=cloud \
  --dart-define=TYPHOON_API_KEY=YOUR_KEY
```

Direct API keys embedded in a mobile app can be extracted. Use the cloud configuration only for development/demo. For production, prefer `CustomBackendProvider` so credentials stay on your backend.

## Run with local vLLM

```bash
cd example
flutter run \
  --dart-define=TYPHOON_PROVIDER=local \
  --dart-define=TYPHOON_BASE_URL=http://YOUR_HOST:8000
```

Android Emulator normally reaches the host machine at `10.0.2.2`. Plain HTTP may require Android cleartext-network configuration depending on your app setup.

## iOS permissions

If you generate platform folders with `flutter create .`, add these keys to `ios/Runner/Info.plist` for the Thai ID camera/gallery flow:

```xml
<key>NSCameraUsageDescription</key>
<string>Take a photo of a Thai ID card for OCR.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a Thai ID card image for OCR.</string>
```

The PDF picker uses the system document picker and does not require photo-library permission.

## macOS file access

For a sandboxed macOS example, `file_selector` requires user-selected file access. Add read-only access to both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` when needed:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

The package itself does not depend on `image_picker` or `file_selector`; these remain example/host-application concerns.
