// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditOutboxDaoMixin on DatabaseAccessor<AppDatabase> {
  $AuditOutboxTableTable get auditOutboxTable =>
      attachedDatabase.auditOutboxTable;
  AuditOutboxDaoManager get managers => AuditOutboxDaoManager(this);
}

class AuditOutboxDaoManager {
  final _$AuditOutboxDaoMixin _db;
  AuditOutboxDaoManager(this._db);
  $$AuditOutboxTableTableTableManager get auditOutboxTable =>
      $$AuditOutboxTableTableTableManager(
        _db.attachedDatabase,
        _db.auditOutboxTable,
      );
}
