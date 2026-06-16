// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_sequences_dao.dart';

// ignore_for_file: type=lint
mixin _$InvoiceSequencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $InvoiceSequencesTableTable get invoiceSequencesTable =>
      attachedDatabase.invoiceSequencesTable;
  InvoiceSequencesDaoManager get managers => InvoiceSequencesDaoManager(this);
}

class InvoiceSequencesDaoManager {
  final _$InvoiceSequencesDaoMixin _db;
  InvoiceSequencesDaoManager(this._db);
  $$InvoiceSequencesTableTableTableManager get invoiceSequencesTable =>
      $$InvoiceSequencesTableTableTableManager(
        _db.attachedDatabase,
        _db.invoiceSequencesTable,
      );
}
