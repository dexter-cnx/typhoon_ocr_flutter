# Thai ID card scan example

This example keeps camera/gallery dependencies outside the package itself. It uses `image_picker` only in the example app.

The commands below assume you start from the repository root.

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

If you generate platform folders with `flutter create .`, add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Take a photo of a Thai ID card for OCR.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select a Thai ID card image for OCR.</string>
```
