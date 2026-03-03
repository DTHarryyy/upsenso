import '../entities/business.dart';
import '../entities/business_template.dart';

abstract class BusinessRepository {
  /// Fetch all available business templates
  Future<List<BusinessTemplate>> getBusinessTemplates();

  /// Create a new business with initial branch
  Future<Business> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
    required String branchName,
  });

  /// Get business by owner ID
  Future<Business?> getBusinessByOwner(String ownerId);

  /// Get business by ID
  Future<Business?> getBusinessById(String businessId);
}
