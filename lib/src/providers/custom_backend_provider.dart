import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../exceptions.dart';
import 'provider.dart';
import 'provider_utils.dart';

/// OCR provider for a custom multipart backend exposing a `/ocr` endpoint.
class CustomBackendProvider implements TyphoonProvider {
  /// Base URL of the custom backend.
  final String baseUrl;

  /// Optional HTTP headers included with each request.
  final Map<String, String>? headers;

  /// Optional injectable HTTP client, primarily useful for tests.
  final http.Client? client;

  /// Maximum duration allowed for upload and response processing.
  final Duration timeout;

  /// Creates a custom multipart OCR provider.
  CustomBackendProvider({
    required this.baseUrl,
    this.headers,
    this.client,
    this.timeout = const Duration(seconds: 60),
  });

  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/ocr');
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = prompt
      ..fields['mode'] = mode
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType.parse(imageMimeType(image)),
        ),
      );

    if (headers != null) request.headers.addAll(headers!);

    try {
      final streamed =
          await (client == null ? request.send() : client!.send(request))
              .timeout(timeout);
      final response =
          await http.Response.fromStream(streamed).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TyphoonApiException(
          'Typhoon OCR backend request failed with HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
          uri: uri,
          responseBody: response.body,
        );
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['markdown'] != null) {
          return decoded['markdown'].toString();
        }
      } on FormatException {
        // Raw markdown is a supported response format.
      }
      return response.body;
    } on TimeoutException catch (error) {
      throw TyphoonTimeoutException(
        'Custom OCR backend request timed out after ${timeout.inSeconds}s.',
        timeout: timeout,
        cause: error,
      );
    } on TyphoonException {
      rethrow;
    } on Object catch (error) {
      throw TyphoonNetworkException(
        'Unable to reach custom OCR backend.',
        cause: error,
      );
    }
  }
}
