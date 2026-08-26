import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../exceptions.dart';

/// Returns the MIME type inferred from the image file extension.
String imageMimeType(File image) {
  return switch (p.extension(image.path).toLowerCase()) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    '.heif' => 'image/heif',
    '.jpg' || '.jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };
}

/// Extracts text content from an OpenAI-compatible chat completion response.
String extractOpenAiMessageContent(String body) {
  try {
    final decoded = jsonDecode(body);
    final choices = decoded is Map ? decoded['choices'] : null;
    if (choices is! List || choices.isEmpty) {
      throw const TyphoonParseException(
        'Response does not contain OpenAI-compatible choices.',
      );
    }
    final first = choices.first;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    if (content is String) return content;

    if (content is List) {
      final text = content
          .whereType<Map>()
          .map((part) => part['text']?.toString() ?? '')
          .where((part) => part.isNotEmpty)
          .join('\n');
      if (text.isNotEmpty) return text;
    }

    throw const TyphoonParseException('Response message content is missing.');
  } on TyphoonException {
    rethrow;
  } on FormatException catch (error) {
    throw TyphoonParseException(
      'Provider returned invalid JSON.',
      cause: error,
    );
  }
}
