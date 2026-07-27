// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlement_dao.dart';

// ignore_for_file: type=lint
mixin _$EntitlementDaoMixin on DatabaseAccessor<AppDatabase> {
  $EntitlementCacheTableTable get entitlementCacheTable =>
      attachedDatabase.entitlementCacheTable;
  $ResourceUsageCacheTableTable get resourceUsageCacheTable =>
      attachedDatabase.resourceUsageCacheTable;
  EntitlementDaoManager get managers => EntitlementDaoManager(this);
}

class EntitlementDaoManager {
  final _$EntitlementDaoMixin _db;
  EntitlementDaoManager(this._db);
  $$EntitlementCacheTableTableTableManager get entitlementCacheTable =>
      $$EntitlementCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.entitlementCacheTable,
      );
  $$ResourceUsageCacheTableTableTableManager get resourceUsageCacheTable =>
      $$ResourceUsageCacheTableTableTableManager(
        _db.attachedDatabase,
        _db.resourceUsageCacheTable,
      );
}
