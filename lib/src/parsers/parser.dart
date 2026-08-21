import 'dart:convert';

import '../models/bank_slip.dart';
import '../models/document.dart';
import '../models/general_doc.dart';
import '../models/passport.dart';
import '../models/receipt.dart';
import '../models/thai_id_card.dart';

class ParsedJsonObject {
  final Map<String, dynamic> value;
  final String rawJson;

  const ParsedJsonObject(this.value, this.rawJson);
}

class TyphoonParser {
  static T parse<T extends TyphoonDocument>(String raw) {
    final parsed = firstJsonObject(raw);
    final json = parsed?.value ?? const <String, dynamic>{};
    final rawJson = parsed?.rawJson ?? '';

    if (T == ThaiIdCard) {
      return ThaiIdCard.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == Receipt) {
      return Receipt.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == BankSlip) {
      return BankSlip.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == Passport) {
      return Passport.fromJson(json, raw, rawJson: rawJson) as T;
    }
    if (T == GeneralDocument) {
      return GeneralDocument(
        rawMarkdown: raw,
        rawJson: rawJson,
        rawMap: Map<String, dynamic>.unmodifiable(json),
      ) as T;
    }

    throw UnsupportedError('No parser registered for document type $T.');
  }

  /// Finds the first syntactically valid JSON object in a mixed markdown/text response.
  static ParsedJsonObject? firstJsonObject(String raw) {
    for (
      var start = raw.indexOf('{');
      start >= 0;
      start = raw.indexOf('{', start + 1)
    ) {
      var depth = 0;
      var inString = false;
      var escaped = false;

      for (var i = start; i < raw.length; i++) {
        final char = raw[i];
        if (inString) {
          if (escaped) {
            escaped = false;
          } else if (char == r'\') {
            escaped = true;
          } else if (char == '"') {
            inString = false;
          }
          continue;
        }

        if (char == '"') {
          inString = true;
        } else if (char == '{') {
          depth++;
        } else if (char == '}') {
          depth--;
          if (depth == 0) {
            final candidate = raw.substring(start, i + 1);
            try {
              final decoded = jsonDecode(candidate);
              if (decoded is Map) {
                return ParsedJsonObject(
                  Map<String, dynamic>.from(decoded),
                  candidate,
                );
              }
            } on FormatException {
              break;
            }
          }
        }
      }
    }
    return null;
  }
}
