import 'package:drift/drift.dart';

DatabaseConnection openDatabaseConnection() {
  throw UnsupportedError(
    'Cannot open a database on this platform. '
    'Supported platforms: Android, iOS, macOS, Windows, Linux, Web.',
  );
}
