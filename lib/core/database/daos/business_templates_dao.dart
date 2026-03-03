import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';

part 'business_templates_dao.g.dart';

@DriftAccessor(tables: [BusinessTemplatesTable])
class BusinessTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessTemplatesDaoMixin {
  BusinessTemplatesDao(super.db);

  /// Get all templates
  Future<List<BusinessTemplatesTableData>> getAllTemplates() {
    return select(businessTemplatesTable).get();
  }

  /// Watch all templates (for reactive UI)
  Stream<List<BusinessTemplatesTableData>> watchAllTemplates() {
    return select(businessTemplatesTable).watch();
  }

  /// Get template by ID
  Future<BusinessTemplatesTableData?> getTemplateById(String id) {
    return (select(
      businessTemplatesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert or replace templates (used when syncing from server)
  Future<void> upsertTemplates(List<BusinessTemplate> templates) async {
    await batch((batch) {
      for (final template in templates) {
        batch.insert(
          businessTemplatesTable,
          BusinessTemplatesTableCompanion.insert(
            id: template.id,
            name: template.name,
            defaultModules: jsonEncode(template.defaultModules),
            defaultRoles: jsonEncode(template.defaultRoles),
            defaultPermissions: jsonEncode(template.defaultPermissions),
            defaultTaxRate: Value(template.defaultTaxRate),
            createdAt: Value(template.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Clear all templates (for full refresh)
  Future<void> clearAll() {
    return delete(businessTemplatesTable).go();
  }

  /// Convert table data to domain entity
  static BusinessTemplate toEntity(BusinessTemplatesTableData data) {
    return BusinessTemplate(
      id: data.id,
      name: data.name,
      defaultModules: Map<String, dynamic>.from(
        jsonDecode(data.defaultModules),
      ),
      defaultRoles: (jsonDecode(data.defaultRoles) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      defaultPermissions: Map<String, dynamic>.from(
        jsonDecode(data.defaultPermissions),
      ),
      defaultTaxRate: data.defaultTaxRate,
      createdAt: data.createdAt,
    );
  }
}
