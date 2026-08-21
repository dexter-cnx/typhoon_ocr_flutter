class TyphoonException implements Exception {
  final String message;
  final Object? cause;

  const TyphoonException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

class TyphoonConfigurationException extends TyphoonException {
  const TyphoonConfigurationException(super.message, {super.cause});
}

class TyphoonNetworkException extends TyphoonException {
  const TyphoonNetworkException(super.message, {super.cause});
}

class TyphoonTimeoutException extends TyphoonNetworkException {
  final Duration timeout;

  const TyphoonTimeoutException(
    super.message, {
    required this.timeout,
    super.cause,
  });
}

class TyphoonApiException extends TyphoonException {
  final int statusCode;
  final Uri? uri;
  final String? responseBody;

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

class TyphoonParseException extends TyphoonException {
  const TyphoonParseException(super.message, {super.cause});
}
