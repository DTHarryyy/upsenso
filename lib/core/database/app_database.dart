import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:pos/core/database/tables/business_templates_table.dart';
import 'package:pos/core/database/tables/businesses_table.dart';
import 'package:pos/core/database/tables/branches_table.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [BusinessTemplatesTable, BusinessesTable, BranchesTable],
  daos: [BusinessTemplatesDao, BusinessesDao, BranchesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing with a custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from v1 to v2: Add branches table
        if (from < 2) {
          await m.createTable(branchesTable);
        }
      },
    );
  }

  // Debug helpers for inspecting local Drift data during development.

  /// Prints all tables and their contents to the console in debug mode.
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

    await _debugPrintBusinessTemplates();

    await _debugPrintBusinesses();

    await _debugPrintBranches();

    debugPrint(
      '═══════════════════════════════════════════════════════════════',
    );
    debugPrint('');
  }

  /// Prints business_templates table contents.
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

  /// Prints businesses table contents.
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

  /// Truncates long strings for compact debug output.
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Returns a human-readable sync status label.
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

  /// Prints table counts summary.
  Future<void> debugPrintTableCounts() async {
    if (!kDebugMode) return;

    final templatesCount = await (select(businessTemplatesTable)).get();
    final businessesCount = await (select(businessesTable)).get();
    final branchesCount = await (select(branchesTable)).get();

    debugPrint('');
    debugPrint('Drift table counts:');
    debugPrint(' - business_templates: ${templatesCount.length}');
    debugPrint(' - businesses: ${businessesCount.length}');
    debugPrint(' - branches: ${branchesCount.length}');
    debugPrint('');
  }

  /// Clears all local tables in debug mode.
  Future<void> debugClearAllTables() async {
    if (!kDebugMode) return;

    debugPrint('Clearing all Drift tables...');
    await delete(branchesTable).go();
    await delete(businessesTable).go();
    await delete(businessTemplatesTable).go();
    debugPrint('All Drift tables cleared.');
  }

  /// Prints branches table contents.
  Future<void> _debugPrintBranches() async {
    debugPrint(
      '┌──────────────────────────────────────────────────────────────┐',
    );
    debugPrint(
      '│ TABLE: branches                                              │',
    );
    debugPrint(
      '├──────────────────────────────────────────────────────────────┤',
    );

    final branches = await select(branchesTable).get();

    if (branches.isEmpty) {
      debugPrint(
        '│ (empty)                                                      │',
      );
    } else {
      debugPrint('│ Count: ${branches.length.toString().padRight(53)}│');
      debugPrint(
        '├──────────────────────────────────────────────────────────────┤',
      );

      for (final b in branches) {
        final syncLabel = _getSyncStatusLabel(b.syncStatus);
        debugPrint(
          '│ ID: ${b.id.substring(0, 8)}...                                        │',
        );
        debugPrint('│   name: ${b.name.padRight(51)}│');
        debugPrint(
          '│   businessId: ${b.businessId.substring(0, 8)}...                                 │',
        );
        debugPrint('│   address: ${(b.address ?? 'null').padRight(48)}│');
        debugPrint('│   phone: ${(b.phone ?? 'null').padRight(50)}│');
        debugPrint('│   isActive: ${b.isActive.toString().padRight(47)}│');
        debugPrint('│   syncStatus: ${syncLabel.padRight(45)}│');
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
