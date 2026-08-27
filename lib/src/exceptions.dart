/// Base exception for Typhoon OCR failures.
class TyphoonException implements Exception {
  /// Human-readable failure description.
  final String message;

  /// Optional underlying error that caused this exception.
  final Object? cause;

  /// Creates a Typhoon OCR exception.
  const TyphoonException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

/// Indicates invalid or missing Typhoon OCR configuration.
class TyphoonConfigurationException extends TyphoonException {
  /// Creates a configuration exception.
  const TyphoonConfigurationException(super.message, {super.cause});
}

/// Indicates a transport-level failure while contacting an OCR provider.
class TyphoonNetworkException extends TyphoonException {
  /// Creates a network exception.
  const TyphoonNetworkException(super.message, {super.cause});
}

/// Indicates that an OCR request exceeded its configured timeout.
class TyphoonTimeoutException extends TyphoonNetworkException {
  /// Timeout duration that was exceeded.
  final Duration timeout;

  /// Creates a timeout exception.
  const TyphoonTimeoutException(
    super.message, {
    required this.timeout,
    super.cause,
  });
}

/// Indicates a non-success HTTP response from an OCR provider.
class TyphoonApiException extends TyphoonException {
  /// HTTP status code returned by the provider.
  final int statusCode;

  /// Request URI when available.
  final Uri? uri;

  /// Provider response body when available.
  final String? responseBody;

  /// Creates an API exception for a failed provider response.
  const TyphoonApiException(
    super.message, {
    required this.statusCode,
    this.uri,
    this.responseBody,
    super.cause,
  });

  @override
  String toString() {
    final details = <String>[
      '$runtimeType: $message',
      'statusCode: $statusCode',
      if (uri != null) 'uri: $uri',
      if (responseBody != null && responseBody!.isNotEmpty)
        'responseBody: $responseBody',
    ];
    return details.join('\n');
  }
}

/// Indicates that a provider response could not be parsed into a document.
class TyphoonParseException extends TyphoonException {
  /// Creates a parse exception.
  const TyphoonParseException(super.message, {super.cause});
}

/// Indicates that a PDF could not be rasterized or contained no readable pages.
class TyphoonPdfException extends TyphoonException {
  /// Creates a PDF extraction exception.
  const TyphoonPdfException(super.message, {super.cause});
}

/// Indicates OCR or parsing failure for one page of a PDF document.
class TyphoonPdfPageException extends TyphoonPdfException {
  /// One-based page number that failed.
  final int pageNumber;

  /// Creates a PDF page exception for [pageNumber].
  const TyphoonPdfPageException(
    super.message, {
    required this.pageNumber,
    super.cause,
  });

  @override
  String toString() => '$runtimeType: page $pageNumber: $message';
}
