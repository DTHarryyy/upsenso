import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/core/seeding/default_business_templates.dart';
import 'package:pos/features/business/domain/entities/business_template.dart';

part 'business_templates_dao.g.dart';

@DriftAccessor(tables: [BusinessTemplatesTable])
class BusinessTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessTemplatesDaoMixin {
  BusinessTemplatesDao(super.db);

  Future<List<BusinessTemplatesTableData>> getAllTemplates() =>
      select(businessTemplatesTable).get();

  Stream<List<BusinessTemplatesTableData>> watchAllTemplates() =>
      select(businessTemplatesTable).watch();

  Future<BusinessTemplatesTableData?> getTemplateById(String id) => (select(
    businessTemplatesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<BusinessTemplatesTableData?> getTemplateByCode(String code) => (select(
    businessTemplatesTable,
  )..where((t) => t.code.equals(code))).getSingleOrNull();

  /// Insert or replace templates when syncing from server.
  // ignore: avoid_renaming_method_parameters
  Future<void> upsertTemplates(List<BusinessTemplate> templates) async {
    await batch((b) {
      for (final tpl in templates) {
        b.insert(
          businessTemplatesTable,
          BusinessTemplatesTableCompanion.insert(
            id: tpl.id,
            code: Value(tpl.code),
            name: tpl.name,
            version: Value(tpl.version),
            isActive: Value(tpl.isActive),
            createdAt: Value(tpl.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> clearAll() => delete(businessTemplatesTable).go();

  /// Convert a cached table row to the domain entity.\n  /// [description] is not stored locally; the server provides it when online.\n  /// [defaultCategories] is derived from [DefaultCategories] via template code.
  static BusinessTemplate toEntity(BusinessTemplatesTableData data) {
    // Map known UUIDs → code for rows cached before the schema upgrade.
    final code = data.code.isNotEmpty
        ? data.code
        : DefaultBusinessTemplates.codeFromId(data.id);

    return BusinessTemplate(
      id: data.id,
      code: code,
      name: data.name,
      description: '',
      version: data.version,
      isActive: data.isActive,
      createdAt: data.createdAt,
    );
  }
}
