// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employees_dao.dart';

// ignore_for_file: type=lint
mixin _$EmployeesDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTableTable get employeesTable => attachedDatabase.employeesTable;
  EmployeesDaoManager get managers => EmployeesDaoManager(this);
}

class EmployeesDaoManager {
  final _$EmployeesDaoMixin _db;
  EmployeesDaoManager(this._db);
  $$EmployeesTableTableTableManager get employeesTable =>
      $$EmployeesTableTableTableManager(
        _db.attachedDatabase,
        _db.employeesTable,
      );
}
