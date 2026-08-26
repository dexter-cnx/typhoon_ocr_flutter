import 'dart:async';
import 'dart:io';

import 'definitions/default_definitions.dart';
import 'definitions/document_definition.dart';
import 'enums/document_type.dart';
import 'exceptions.dart';
import 'extraction_options.dart';
import 'models/document.dart';
import 'models/general_doc.dart';
import 'providers/custom_backend_provider.dart';
import 'providers/local_vllm_provider.dart';
import 'providers/opentyphoon_cloud_provider.dart';
import 'providers/provider.dart';

/// Type-safe Typhoon OCR client backed by a configurable [TyphoonProvider].
class TyphoonOCR {
  /// Provider used to execute OCR requests.
  final TyphoonProvider provider;
  final Map<Type, DocumentDefinition<dynamic>> _definitions;

  /// Creates a client using [provider] and optional custom document definitions.
  ///
  /// Entries in [definitions] override built-in definitions for the same Dart
  /// document model type.
  TyphoonOCR({
    required this.provider,
    Map<Type, DocumentDefinition<dynamic>> definitions = const {},
  }) : _definitions = {
          ...createDefaultDocumentDefinitions(),
          ...definitions,
        };

  /// Creates a provider from runtime environment variables or compile-time
  /// Dart defines.
  ///
  /// Runtime environment variables take precedence. This is useful for Dart
  /// CLI and tests, while Flutter applications can keep using `--dart-define`.
  ///
  /// Required configuration:
  /// - `TYPHOON_PROVIDER=local|cloud|custom`
  /// - `TYPHOON_BASE_URL` for local/custom
  /// - `TYPHOON_API_KEY` for cloud (optional Bearer token for custom)
  factory TyphoonOCR.fromEnv({Map<String, String>? environment}) {
    final runtimeEnvironment = environment ?? Platform.environment;

    const definedProvider = String.fromEnvironment('TYPHOON_PROVIDER');
    const definedBaseUrl = String.fromEnvironment('TYPHOON_BASE_URL');
    const definedApiKey = String.fromEnvironment('TYPHOON_API_KEY');
    const definedModel = String.fromEnvironment(
      'TYPHOON_MODEL',
      defaultValue: 'typhoon-ocr',
    );

    final providerName =
        runtimeEnvironment['TYPHOON_PROVIDER'] ?? definedProvider;
    final baseUrl = runtimeEnvironment['TYPHOON_BASE_URL'] ?? definedBaseUrl;
    final apiKey = runtimeEnvironment['TYPHOON_API_KEY'] ?? definedApiKey;
    final model = runtimeEnvironment['TYPHOON_MODEL'] ?? definedModel;

    switch (providerName.toLowerCase()) {
      case 'local':
      case 'vllm':
        if (baseUrl.isEmpty) {
          throw const TyphoonConfigurationException(
            'TYPHOON_BASE_URL is required for local provider.',
          );
        }
        return TyphoonOCR(
          provider: LocalVllmProvider(baseUrl: baseUrl, modelName: model),
        );
      case 'cloud':
      case 'opentyphoon':
        if (apiKey.isEmpty) {
          throw const TyphoonConfigurationException(
            'TYPHOON_API_KEY is required for cloud provider.',
          );
        }
        return TyphoonOCR(
          provider: OpentyphoonCloudProvider(apiKey: apiKey, model: model),
        );
      case 'custom':
        if (baseUrl.isEmpty) {
          throw const TyphoonConfigurationException(
            'TYPHOON_BASE_URL is required for custom provider.',
          );
        }
        return TyphoonOCR(
          provider: CustomBackendProvider(
            baseUrl: baseUrl,
            headers:
                apiKey.isEmpty ? null : {'Authorization': 'Bearer $apiKey'},
          ),
        );
      default:
        throw const TyphoonConfigurationException(
          'TYPHOON_PROVIDER must be one of: local, cloud, custom.',
        );
    }
  }

  /// Extracts [image] into the requested document model [T].
  ///
  /// [type] can select a built-in request definition while decoding still uses
  /// the definition registered for [T]. Request-scoped prompt, mode and timeout
  /// overrides can be supplied through [options].
  Future<T> extract<T extends TyphoonDocument>(
    File image, {
    DocumentType? type,
    ExtractionOptions options = const ExtractionOptions(),
  }) async {
    final definition = _definitions[T];
    if (definition == null) {
      throw UnsupportedError(
        'No document definition registered for $T. '
        'Pass a DocumentDefinition<$T> to TyphoonOCR(definitions: ...).',
      );
    }

    final effectiveDefinition = type == null
        ? definition
        : defaultDefinitionForType(type) ?? definition;
    final extraction = provider.extractRaw(
      image: image,
      prompt: options.prompt ?? effectiveDefinition.prompt,
      mode: options.mode ?? effectiveDefinition.mode,
    );

    late final String raw;
    final timeout = options.timeout;
    if (timeout == null) {
      raw = await extraction;
    } else {
      try {
        raw = await extraction.timeout(timeout);
      } on TimeoutException catch (error) {
        throw TyphoonTimeoutException(
          'OCR extraction exceeded the request timeout.',
          timeout: timeout,
          cause: error,
        );
      }
    }

    return definition.decode(raw) as T;
  }

  /// Extracts [image] using the built-in general-document definition.
  Future<GeneralDocument> extractGeneral(
    File image, {
    ExtractionOptions options = const ExtractionOptions(),
  }) =>
      extract<GeneralDocument>(
        image,
        type: DocumentType.general,
        options: options,
      );

  /// Returns a new client with [definition] registered for document model [T].
  ///
  /// The current client remains unchanged.
  TyphoonOCR withDefinition<T extends TyphoonDocument>(
    DocumentDefinition<T> definition,
  ) {
    return TyphoonOCR(
      provider: provider,
      definitions: {
        ..._definitions,
        T: definition,
      },
    );
  }
}
