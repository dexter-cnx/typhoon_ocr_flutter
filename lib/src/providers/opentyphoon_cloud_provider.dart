import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../exceptions.dart';
import 'provider.dart';
import 'provider_utils.dart';

/// OCR provider for the OpenTyphoon cloud OpenAI-compatible API.
class OpentyphoonCloudProvider implements TyphoonProvider {
  /// API key used for bearer authentication.
  final String apiKey;

  /// Base URL of the OpenTyphoon API.
  final String baseUrl;

  /// Model name sent in chat-completion requests.
  final String model;

  /// Optional injectable HTTP client, primarily useful for tests.
  final http.Client? client;

  /// Maximum duration allowed for a provider request.
  final Duration timeout;

  /// Creates an authenticated OpenTyphoon cloud OCR provider.
  OpentyphoonCloudProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.opentyphoon.ai/v1',
    this.model = 'typhoon-ocr',
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
      'model': model,
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
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions',
    );
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      final encodedBody = jsonEncode(body);
      final res = await (client == null
              ? http.post(uri, headers: headers, body: encodedBody)
              : client!.post(uri, headers: headers, body: encodedBody))
          .timeout(timeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw TyphoonApiException(
          'OpenTyphoon request failed with HTTP ${res.statusCode}.',
          statusCode: res.statusCode,
          uri: uri,
          responseBody: res.body,
        );
      }
      return extractOpenAiMessageContent(res.body);
    } on TimeoutException catch (error) {
      throw TyphoonTimeoutException(
        'OpenTyphoon request timed out after ${timeout.inSeconds}s.',
        timeout: timeout,
        cause: error,
      );
    } on TyphoonException {
      rethrow;
    } on Object catch (error) {
      throw TyphoonNetworkException(
        'Unable to reach OpenTyphoon cloud provider.',
        cause: error,
      );
    }
  }
}
