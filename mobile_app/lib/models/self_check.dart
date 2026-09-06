/// Business self-check models — mirrors backend self-check capability.
///
/// IMPORTANT PRIVACY CONTRACT:
/// Self-check is PREVENTIVE and PRIVATE. It must NOT create an enforcement
/// case, must NOT create an offence, and must NOT trigger offence-tier
/// logic. Backend (Member 1) is responsible for enforcing this isolation;
/// the Flutter UI additionally labels every self-check surface as private.
library;

import 'violation.dart';

/// One issue found during self-check, in plain business-friendly language.
class SelfCheckIssue {
  const SelfCheckIssue({
    required this.field,
    required this.issue,
    required this.requirement,
    required this.severity,
    required this.recommendedCorrection,
  });

  /// e.g. "Consumer care details".
  final String field;

  /// e.g. "Consumer-care declaration may require correction."
  final String issue;

  /// Prescribed requirement, e.g. "Rule 6(3) requires a consumer-care
  /// declaration in the prescribed format."
  final String requirement;

  final ViolationSeverity severity;

  /// e.g. "Add the required consumer-care declaration in the prescribed format."
  final String recommendedCorrection;
}

/// Result of a private self-check run.
class SelfCheckReport {
  const SelfCheckReport({
    required this.id,
    required this.productName,
    required this.performedAt,
    required this.isCompliant,
    required this.issues,
    this.imagePaths = const [],
  });

  final String id;
  final String productName;
  final DateTime performedAt;
  final bool isCompliant;
  final List<SelfCheckIssue> issues;
  final List<String> imagePaths;

  String get resultLabel => isCompliant ? 'Compliant' : 'Potential Issues Found';
}

/// Request to run a self-check on captured package images.
class PerformSelfCheckRequest {
  const PerformSelfCheckRequest({
    required this.imagePaths,
    required this.productNameHint,
  });

  final List<String> imagePaths;
  final String productNameHint;
}
