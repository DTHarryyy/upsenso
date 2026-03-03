import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/business/data/models/business_template_model.dart';
import 'package:pos/features/business/domain/entities/business.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDs remote;
  BusinessRepositoryImpl(this.remote);

  @override
  Future<List<BusinessTemplate>> getBusinessTemplates() async {
    final data = await remote.getBusinessTemplates();
    return data.map((json) => BusinessTemplateModel.fromJson(json)).toList();
  }

  @override
  Future<Business> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
  }) async {
    final data = await remote.createBusiness(
      name: name,
      ownerId: ownerId,
      templateId: templateId,
    );
    return BusinessModel.fromJson(data);
  }

  @override
  Future<Business?> getBusinessByOwner(String ownerId) async {
    final data = await remote.getBusinessByOwner(ownerId);
    return data != null ? BusinessModel.fromJson(data) : null;
  }

  @override
  Future<Business?> getBusinessById(String businessId) async {
    final data = await remote.getBusinessById(businessId);
    return data != null ? BusinessModel.fromJson(data) : null;
  }
}
