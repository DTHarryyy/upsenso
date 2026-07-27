import 'package:flutter/foundation.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/synced_tables_registry.dart';

/// Free→paid first-sync backfill (design §7.2).
///
/// On a fresh Free tenant, rows are already `pendingUpload` (sync never ran),
/// so the normal `syncAll()` after arming pushes everything. This service
/// covers the deterministic edge: a tenant that synced during a trial, lapsed,
/// then edited/added rows locally, then re-upgraded — some rows are `synced`
/// locally but the server copy was frozen. `markAllForUpload()` re-queues them
/// so the re-upgrade pushes a complete, current snapshot.
///
/// Only the business-data-plane tables are touched; identity-plane rows
/// (branches/businesses/employees/devices) sync on their own and are never
/// re-queued here.
class BackfillService {
  final AppDatabase _db;

  BackfillService(this._db);

  /// Marks every previously-`synced` business row back to `pendingUpload` so
  /// the next `syncAll()` re-pushes it. Idempotent; never touches rows that are
  /// already pending. Runs in one transaction so an interrupted backfill can't
  /// leave a half-requeued database.
  Future<void> markAllForUpload() async {
    final tables = syncedTablesRegistry
        .where((t) => t.businessData)
        .map((t) => t.tableName)
        .toList();

    try {
      await _db.transaction(() async {
        for (final table in tables) {
          // SyncStatus: pendingUpload = 0, synced = 3.
          await _db.customStatement(
            'UPDATE $table SET sync_status = 0 WHERE sync_status = 3',
          );
        }
      });
      debugPrint('[Backfill] Re-queued ${tables.length} tables for upload.');
    } catch (e, st) {
      // A missing table on some platform must not abort an upgrade; the normal
      // pending rows still sync.
      debugPrint('[Backfill] Error in markAllForUpload: $e\n$st');
    }
  }
}
