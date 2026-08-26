import '../models/document.dart';

/// Severity assigned to a document validation issue.
enum ValidationSeverity {
  /// The document can still be used, but a field deserves attention.
  warning,

  /// The document violates a required invariant and should be treated invalid.
  error,
}

/// One structured validation finding for an OCR document.
class ValidationIssue {
  /// Stable machine-readable issue code.
  final String code;

  /// Document field associated with the issue, when applicable.
  final String? field;

  /// Human-readable description of the validation finding.
  final String message;

  /// Severity of the finding.
  final ValidationSeverity severity;

  /// Creates a structured validation issue.
  const ValidationIssue({
    required this.code,
    required this.message,
    this.field,
    this.severity = ValidationSeverity.error,
  });
}

/// Parsed OCR document together with its structured validation findings.
class ValidationResult<T extends TyphoonDocument> {
  /// Parsed document that was validated.
  final T document;

  /// Immutable list of validation findings.
  final List<ValidationIssue> issues;

  /// Creates a validation result for [document].
  ValidationResult({
    required this.document,
    Iterable<ValidationIssue> issues = const [],
  }) : issues = List<ValidationIssue>.unmodifiable(issues);

  /// Whether no error-severity findings were reported.
  bool get isValid => errors.isEmpty;

  /// Error-severity validation findings.
  List<ValidationIssue> get errors => List<ValidationIssue>.unmodifiable(
        issues.where((issue) => issue.severity == ValidationSeverity.error),
      );

  /// Warning-severity validation findings.
  List<ValidationIssue> get warnings => List<ValidationIssue>.unmodifiable(
        issues.where((issue) => issue.severity == ValidationSeverity.warning),
      );
}

/// Contract implemented by validators for one document model type.
abstract class DocumentValidator<T extends TyphoonDocument> {
  /// Creates a document validator.
  const DocumentValidator();

  /// Validates [document] and returns structured findings.
  ValidationResult<T> validate(T document);
}
