// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AuditLogsTableTable get auditLogsTable => attachedDatabase.auditLogsTable;
  AuditLogsDaoManager get managers => AuditLogsDaoManager(this);
}

class AuditLogsDaoManager {
  final _$AuditLogsDaoMixin _db;
  AuditLogsDaoManager(this._db);
  $$AuditLogsTableTableTableManager get auditLogsTable =>
      $$AuditLogsTableTableTableManager(
        _db.attachedDatabase,
        _db.auditLogsTable,
      );
}
