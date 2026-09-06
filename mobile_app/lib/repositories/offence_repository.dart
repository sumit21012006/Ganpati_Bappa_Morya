import '../models/offence_history.dart';

/// Product offence history capability contract.
///
/// The SAME product identity is resolved by the backend (product
/// normalisation / matching — Member 4). Flutter performs NO independent
/// offence logic and never computes tiers itself.
abstract class OffenceRepository {
  /// Returns previous offence info for a product, or a record with
  /// [OffenceTier.none] when the product has no prior case history.
  Future<OffenceHistory> getProductOffenceHistory(String productId);

  /// Checks a specific business+product combination (re-offence lookup).
  Future<OffenceHistory> getProductOffenceHistoryForBusiness(
    String productId,
    String businessId,
  );
}
