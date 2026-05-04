// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:drift/drift.dart';

DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    // ignore: deprecated_member_use
    final storage = await DriftWebStorage.indexedDbIfSupported('pos_database');
    // ignore: deprecated_member_use
    return DatabaseConnection(WebDatabase.withStorage(storage));
  }));
}
