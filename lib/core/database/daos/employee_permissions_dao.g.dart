// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_permissions_dao.dart';

// ignore_for_file: type=lint
mixin _$EmployeePermissionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeePermissionsTableTable get employeePermissionsTable =>
      attachedDatabase.employeePermissionsTable;
  EmployeePermissionsDaoManager get managers =>
      EmployeePermissionsDaoManager(this);
}

class EmployeePermissionsDaoManager {
  final _$EmployeePermissionsDaoMixin _db;
  EmployeePermissionsDaoManager(this._db);
  $$EmployeePermissionsTableTableTableManager get employeePermissionsTable =>
      $$EmployeePermissionsTableTableTableManager(
        _db.attachedDatabase,
        _db.employeePermissionsTable,
      );
}
