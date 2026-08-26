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
import 'validation/default_validators.dart';
import 'validation/validation.dart';

/// Type-safe Typhoon OCR client backed by a configurable [TyphoonProvider].
class TyphoonOCR {
  /// Provider used to execute OCR requests.
  final TyphoonProvider provider;
  final Map<Type, DocumentDefinition<dynamic>> _definitions;
  final Map<Type, DocumentValidator<dynamic>> _validators;

  /// Creates a client using [provider] and optional custom definitions or validators.
  ///
  /// Entries in [definitions] and [validators] override built-in registrations for
  /// the same Dart document model type.
  TyphoonOCR({
    required this.provider,
    Map<Type, DocumentDefinition<dynamic>> definitions = const {},
    Map<Type, DocumentValidator<dynamic>> validators = const {},
  })  : _definitions = {
          ...createDefaultDocumentDefinitions(),
          ...definitions,
        },
        _validators = {
          ...createDefaultDocumentValidators(),
          ...validators,
        };

  /// Creates a provider from runtime environment variables or compile-time
  /// Dart defines.
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

  /// Extracts and validates [image] as document model [T].
  Future<ValidationResult<T>> extractValidated<T extends TyphoonDocument>(
    File image, {
    DocumentType? type,
    ExtractionOptions options = const ExtractionOptions(),
  }) async {
    final document = await extract<T>(image, type: type, options: options);
    return validate<T>(document);
  }

  /// Validates an already parsed [document] using its concrete document type.
  ValidationResult<T> validate<T extends TyphoonDocument>(T document) {
    final validator = _validators[document.runtimeType];
    if (validator == null) {
      return ValidationResult<T>(document: document);
    }

    final result = validator.validate(document);
    return ValidationResult<T>(
      document: document,
      issues: result.issues,
    );
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
  TyphoonOCR withDefinition<T extends TyphoonDocument>(
    DocumentDefinition<T> definition,
  ) {
    return TyphoonOCR(
      provider: provider,
      definitions: {
        ..._definitions,
        T: definition,
      },
      validators: _validators,
    );
  }

  /// Returns a new client with [validator] registered for document model [T].
  TyphoonOCR withValidator<T extends TyphoonDocument>(
    DocumentValidator<T> validator,
  ) {
    return TyphoonOCR(
      provider: provider,
      definitions: _definitions,
      validators: {
        ..._validators,
        T: validator,
      },
    );
  }
}
