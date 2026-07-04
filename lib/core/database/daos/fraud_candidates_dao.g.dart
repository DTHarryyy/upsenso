// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraud_candidates_dao.dart';

// ignore_for_file: type=lint
mixin _$FraudCandidatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $FraudCandidatesTableTable get fraudCandidatesTable =>
      attachedDatabase.fraudCandidatesTable;
  FraudCandidatesDaoManager get managers => FraudCandidatesDaoManager(this);
}

class FraudCandidatesDaoManager {
  final _$FraudCandidatesDaoMixin _db;
  FraudCandidatesDaoManager(this._db);
  $$FraudCandidatesTableTableTableManager get fraudCandidatesTable =>
      $$FraudCandidatesTableTableTableManager(
        _db.attachedDatabase,
        _db.fraudCandidatesTable,
      );
}
