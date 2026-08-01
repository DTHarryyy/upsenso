import '../entities/business.dart';
import '../entities/business_template.dart';

abstract class BusinessRepository {
  /// Fetch all available business templates
  Future<List<BusinessTemplate>> getBusinessTemplates();

  /// Create a new business with its initial branch.
  ///
  /// [businessId] / [branchId] let the CALLER keep one stable identity across
  /// retries. Pass the same ids when retrying a failed attempt — minting fresh
  /// ones per try is what orphaned 8 businesses on 2026-07-26. Omit them and
  /// the repository mints a pair.
  Future<Business> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
    required String branchName,
    String? businessId,
    String? branchId,
  });

  /// Get business by owner ID
  Future<Business?> getBusinessByOwner(String ownerId);

  /// Get business by ID
  Future<Business?> getBusinessById(String businessId);
}
