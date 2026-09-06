/// Product offence history — mirrors backend product-normalisation lookup
/// (Member 4) across previous cases. Flutter performs NO independent
/// offence logic; it only displays what the backend returns.
enum OffenceTier { none, first, second, repeat }

extension OffenceTierX on OffenceTier {
  String get label => switch (this) {
        OffenceTier.none => 'No previous offence',
        OffenceTier.first => 'First offence',
        OffenceTier.second => 'Second offence',
        OffenceTier.repeat => 'Repeat offence',
      };
}

class OffenceRecord {
  const OffenceRecord({
    required this.caseId,
    required this.businessName,
    required this.location,
    required this.date,
    required this.violationSummary,
    required this.caseStatus,
  });

  final String caseId;
  final String businessName;
  final String location;
  final DateTime date;
  final String violationSummary;
  final String caseStatus;
}

class OffenceHistory {
  const OffenceHistory({
    required this.productId,
    required this.matchedProductName,
    required this.tier,
    required this.checkedAt,
    required this.records,
    this.matchConfidence,
  });

  final String productId;

  /// Canonical product name the backend matched this package against.
  final String matchedProductName;

  final OffenceTier tier;
  final DateTime checkedAt;
  final List<OffenceRecord> records;

  /// Backend product-matching confidence (RapidFuzz score), if provided.
  final double? matchConfidence;

  bool get hasPreviousOffence => tier != OffenceTier.none;
}
