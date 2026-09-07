import '../models/business.dart';

/// Business search/registration capability contract.
abstract class BusinessRepository {
  /// Searches by business name, GSTIN, or identifier. Used by the
  /// inspector's Business Search screen.
  Future<List<Business>> searchBusinesses(String query, {int limit});

  Future<Business> getBusiness(String id);

  /// Business self-registration. GSTIN verification is backend-driven
  /// (Member 6); the backend may return a business with `pending` status
  /// until verification completes.
  Future<Business> registerBusiness(BusinessRegistrationRequest request);

  Future<Business> updateBusiness(Business business);

  /// Quick-add an on-the-spot business during a raid by Inspector.
  Future<Business> quickAddBusiness({
    required String name,
    required String address,
    required BusinessType type,
    String? gstin,
    String? contactPhone,
    double? latitude,
    double? longitude,
    String? district,
    String? pincode,
  });
}
