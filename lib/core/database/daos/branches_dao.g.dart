// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branches_dao.dart';

// ignore_for_file: type=lint
mixin _$BranchesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BranchesTableTable get branchesTable => attachedDatabase.branchesTable;
  BranchesDaoManager get managers => BranchesDaoManager(this);
}

class BranchesDaoManager {
  final _$BranchesDaoMixin _db;
  BranchesDaoManager(this._db);
  $$BranchesTableTableTableManager get branchesTable =>
      $$BranchesTableTableTableManager(_db.attachedDatabase, _db.branchesTable);
}
