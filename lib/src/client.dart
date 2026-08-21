import 'dart:io';

import 'definitions/default_definitions.dart';
import 'definitions/document_definition.dart';
import 'enums/document_type.dart';
import 'exceptions.dart';
import 'models/document.dart';
import 'models/general_doc.dart';
import 'providers/custom_backend_provider.dart';
import 'providers/local_vllm_provider.dart';
import 'providers/opentyphoon_cloud_provider.dart';
import 'providers/provider.dart';

class TyphoonOCR {
  final TyphoonProvider provider;
  final Map<Type, DocumentDefinition<dynamic>> _definitions;

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
            headers: apiKey.isEmpty ? null : {'Authorization': 'Bearer $apiKey'},
          ),
        );
      default:
        throw const TyphoonConfigurationException(
          'TYPHOON_PROVIDER must be one of: local, cloud, custom.',
        );
    }
  }

  Future<T> extract<T extends TyphoonDocument>(
    File image, {
    DocumentType? type,
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
    final raw = await provider.extractRaw(
      image: image,
      prompt: effectiveDefinition.prompt,
      mode: effectiveDefinition.mode,
    );
    return definition.decode(raw) as T;
  }

  Future<GeneralDocument> extractGeneral(File image) =>
      extract<GeneralDocument>(image, type: DocumentType.general);

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
