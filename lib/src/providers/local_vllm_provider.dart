import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../exceptions.dart';
import 'provider.dart';
import 'provider_utils.dart';

/// OCR provider for a local OpenAI-compatible vLLM endpoint.
class LocalVllmProvider implements TyphoonProvider {
  /// Base URL of the local vLLM server.
  final String baseUrl;

  /// Model name sent in OpenAI-compatible requests.
  final String modelName;

  /// Optional injectable HTTP client, primarily useful for tests.
  final http.Client? client;

  /// Maximum duration allowed for a provider request.
  final Duration timeout;

  /// Creates a local OpenAI-compatible OCR provider.
  LocalVllmProvider({
    required this.baseUrl,
    this.modelName = 'typhoon-ocr',
    this.client,
    this.timeout = const Duration(seconds: 60),
  });

  @override
  Future<String> extractRaw({
    required File image,
    required String prompt,
    required String mode,
  }) async {
    final b64 = base64Encode(await image.readAsBytes());
    final mime = imageMimeType(image);
    final body = {
      'model': modelName,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': '$prompt\nMode: $mode'},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$b64'},
            },
          ],
        },
      ],
    };

    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/v1/chat/completions',
    );
    try {
      final res = await (client == null
              ? http.post(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                  body: jsonEncode(body),
                )
              : client!.post(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                  body: jsonEncode(body),
                ))
          .timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw TyphoonApiException(
          'Typhoon OCR request failed with HTTP ${res.statusCode}.',
          statusCode: res.statusCode,
          uri: uri,
          responseBody: res.body,
        );
      }
      return extractOpenAiMessageContent(res.body);
    } on TimeoutException catch (error) {
      throw TyphoonTimeoutException(
        'Typhoon OCR request timed out after ${timeout.inSeconds}s.',
        timeout: timeout,
        cause: error,
      );
    } on TyphoonException {
      rethrow;
    } on Object catch (error) {
      throw TyphoonNetworkException(
        'Unable to reach local Typhoon OCR provider.',
        cause: error,
      );
    }
  }
}
