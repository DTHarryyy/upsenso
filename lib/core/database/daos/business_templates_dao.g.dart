// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_templates_dao.dart';

// ignore_for_file: type=lint
mixin _$BusinessTemplatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BusinessTemplatesTableTable get businessTemplatesTable =>
      attachedDatabase.businessTemplatesTable;
  BusinessTemplatesDaoManager get managers => BusinessTemplatesDaoManager(this);
}

class BusinessTemplatesDaoManager {
  final _$BusinessTemplatesDaoMixin _db;
  BusinessTemplatesDaoManager(this._db);
  $$BusinessTemplatesTableTableTableManager get businessTemplatesTable =>
      $$BusinessTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.businessTemplatesTable,
      );
}
