/// Per-request overrides for a Typhoon OCR extraction.
///
/// Any value left null falls back to the registered document definition or
/// provider defaults.
class ExtractionOptions {
  /// Overrides the prompt used for this extraction only.
  final String? prompt;

  /// Overrides the provider mode used for this extraction only.
  final String? mode;

  /// Limits how long the caller waits for this extraction.
  ///
  /// When exceeded, [TyphoonOCR] throws a `TyphoonTimeoutException`.
  final Duration? timeout;

  /// Creates request-scoped OCR extraction overrides.
  const ExtractionOptions({
    this.prompt,
    this.mode,
    this.timeout,
  });
}
