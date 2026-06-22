// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'po_number_sequences_dao.dart';

// ignore_for_file: type=lint
mixin _$PoNumberSequencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PoNumberSequencesTableTable get poNumberSequencesTable =>
      attachedDatabase.poNumberSequencesTable;
  PoNumberSequencesDaoManager get managers => PoNumberSequencesDaoManager(this);
}

class PoNumberSequencesDaoManager {
  final _$PoNumberSequencesDaoMixin _db;
  PoNumberSequencesDaoManager(this._db);
  $$PoNumberSequencesTableTableTableManager get poNumberSequencesTable =>
      $$PoNumberSequencesTableTableTableManager(
        _db.attachedDatabase,
        _db.poNumberSequencesTable,
      );
}
