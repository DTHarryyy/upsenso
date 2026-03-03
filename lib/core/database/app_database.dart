import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/core/database/tables/businesses_table.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [BusinessTemplatesTable, BusinessesTable],
  daos: [BusinessTemplatesDao, BusinessesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with a custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODO: DEBUG - Remove this section before production
  // ═══════════════════════════════════════════════════════════════════════════

  /// TODO: DEBUG - Prints all tables and their contents to console
  /// Call this method to inspect the database state during development
  /// Remove before production release
  Future<void> debugPrintAllTables() async {
    if (!kDebugMode) return; // Only run in debug mode

    debugPrint('');
    debugPrint(
      '╔══════════════════════════════════════════════════════════════╗',
    );
    debugPrint(
      '║                    DRIFT DATABASE DEBUG                      ║',
    );
    debugPrint(
      '╚══════════════════════════════════════════════════════════════╝',
    );
    debugPrint('');

    // TODO: DEBUG - Print business_templates table
    await _debugPrintBusinessTemplates();

    // TODO: DEBUG - Print businesses table
    await _debugPrintBusinesses();

    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('');
  }

  /// TODO: DEBUG - Print business_templates table contents
  Future<void> _debugPrintBusinessTemplates() async {
    debugPrint(
      '┌──────────────────────────────────────────────────────────────┐',
    );
    debugPrint(
      '│ TABLE: business_templates                                    │',
    );
    debugPrint(
      '├──────────────────────────────────────────────────────────────┤',
    );

    final templates = await select(businessTemplatesTable).get();

    if (templates.isEmpty) {
      debugPrint(
        '│ (empty)                                                      │',
      );
    } else {
      debugPrint('│ Count: ${templates.length.toString().padRight(53)}│');
      debugPrint(
        '├──────────────────────────────────────────────────────────────┤',
      );

      for (final t in templates) {
        debugPrint(
          '│ ID: ${t.id.substring(0, 8)}...                                        │',
        );
        debugPrint('│   name: ${t.name.padRight(51)}│');
        debugPrint(
          '│   defaultModules: ${_truncate(t.defaultModules, 40).padRight(41)}│',
        );
        debugPrint(
          '│   defaultRoles: ${_truncate(t.defaultRoles, 42).padRight(43)}│',
        );
        debugPrint(
          '│   defaultTaxRate: ${t.defaultTaxRate?.toString().padRight(41) ?? 'null'.padRight(41)}│',
        );
        debugPrint(
          '│   createdAt: ${t.createdAt?.toString().padRight(46) ?? 'null'.padRight(46)}│',
        );
        debugPrint(
          '├──────────────────────────────────────────────────────────────┤',
        );
      }
    }

    debugPrint(
      '└──────────────────────────────────────────────────────────────┘',
    );
    debugPrint('');
  }

  /// TODO: DEBUG - Print businesses table contents
  Future<void> _debugPrintBusinesses() async {
    debugPrint(
      '┌──────────────────────────────────────────────────────────────┐',
    );
    debugPrint(
      '│ TABLE: businesses                                            │',
    );
    debugPrint(
      '├──────────────────────────────────────────────────────────────┤',
    );

    final businesses = await select(businessesTable).get();

    if (businesses.isEmpty) {
      debugPrint(
        '│ (empty)                                                      │',
      );
    } else {
      debugPrint('│ Count: ${businesses.length.toString().padRight(53)}│');
      debugPrint(
        '├──────────────────────────────────────────────────────────────┤',
      );

      for (final b in businesses) {
        final syncLabel = _getSyncStatusLabel(b.syncStatus);
        debugPrint(
          '│ ID: ${b.id.substring(0, 8)}...                                        │',
        );
        debugPrint('│   name: ${b.name.padRight(51)}│');
        debugPrint(
          '│   ownerId: ${b.ownerId.substring(0, 8)}...                                    │',
        );
        debugPrint(
          '│   templateId: ${b.templateId.substring(0, 8)}...                                 │',
        );
        debugPrint('│   isActive: ${b.isActive.toString().padRight(47)}│');
        debugPrint('│   syncStatus: ${syncLabel.padRight(45)}│');
        debugPrint('│   syncError: ${(b.syncError ?? 'null').padRight(46)}│');
        debugPrint('│   createdAt: ${b.createdAt.toString().padRight(46)}│');
        debugPrint(
          '│   lastSyncAttempt: ${b.lastSyncAttempt?.toString().padRight(40) ?? 'null'.padRight(40)}│',
        );
        debugPrint(
          '├──────────────────────────────────────────────────────────────┤',
        );
      }
    }

    debugPrint(
      '└──────────────────────────────────────────────────────────────┘',
    );
    debugPrint('');
  }

  /// TODO: DEBUG - Helper to truncate long strings
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// TODO: DEBUG - Get human-readable sync status
  String _getSyncStatusLabel(int status) {
    switch (status) {
      case 0:
        return 'pendingUpload';
      case 1:
        return 'pendingUpdate';
      case 2:
        return 'pendingDelete';
      case 3:
        return 'synced';
      case 4:
        return 'failed';
      default:
        return 'unknown($status)';
    }
  }

  /// TODO: DEBUG - Print table counts summary
  Future<void> debugPrintTableCounts() async {
    if (!kDebugMode) return;

    final templatesCount = await (select(businessTemplatesTable)).get();
    final businessesCount = await (select(businessesTable)).get();

    debugPrint('');
    debugPrint('📊 Drift Table Counts:');
    debugPrint('   • business_templates: ${templatesCount.length}');
    debugPrint('   • businesses: ${businessesCount.length}');
    debugPrint('');
  }

  /// TODO: DEBUG - Clear all tables (use with caution!)
  Future<void> debugClearAllTables() async {
    if (!kDebugMode) return;

    debugPrint('⚠️ DEBUG: Clearing all Drift tables...');
    await delete(businessesTable).go();
    await delete(businessTemplatesTable).go();
    debugPrint('✅ DEBUG: All tables cleared');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODO: DEBUG - End of debug section
  // ═══════════════════════════════════════════════════════════════════════════
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
