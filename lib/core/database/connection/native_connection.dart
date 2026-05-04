import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pos_database.sqlite'));
    return NativeDatabase.createBackgroundConnection(file);
  }));
}
