import 'dart:io';

/// Contract implemented by OCR backends used by Typhoon OCR clients.
abstract class TyphoonProvider {
  /// Sends [image] to the provider using the supplied [prompt] and [mode].
  ///
  /// Returns the raw provider response for decoding by the registered document
  /// definition.
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  });
}
