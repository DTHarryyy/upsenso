/// Represents the synchronization status of a local record
enum SyncStatus {
  /// Record exists only locally and needs to be uploaded
  pendingUpload,

  /// Record was updated locally and needs to sync changes to server
  pendingUpdate,

  /// Record was deleted locally and needs deletion synced to server
  pendingDelete,

  /// Record is fully synced with the server
  synced,

  /// Sync failed - will retry on next sync cycle
  failed,
}

extension SyncStatusExtension on SyncStatus {
  /// Convert to database integer value
  int toInt() {
    switch (this) {
      case SyncStatus.pendingUpload:
        return 0;
      case SyncStatus.pendingUpdate:
        return 1;
      case SyncStatus.pendingDelete:
        return 2;
      case SyncStatus.synced:
        return 3;
      case SyncStatus.failed:
        return 4;
    }
  }

  /// Create from database integer value
  static SyncStatus fromInt(int value) {
    switch (value) {
      case 0:
        return SyncStatus.pendingUpload;
      case 1:
        return SyncStatus.pendingUpdate;
      case 2:
        return SyncStatus.pendingDelete;
      case 3:
        return SyncStatus.synced;
      case 4:
        return SyncStatus.failed;
      default:
        return SyncStatus.pendingUpload;
    }
  }

  /// Check if record needs to be synced
  bool get needsSync =>
      this == SyncStatus.pendingUpload ||
      this == SyncStatus.pendingUpdate ||
      this == SyncStatus.pendingDelete ||
      this == SyncStatus.failed;

  /// Human-readable label
  String get label {
    switch (this) {
      case SyncStatus.pendingUpload:
        return 'Pending Upload';
      case SyncStatus.pendingUpdate:
        return 'Pending Update';
      case SyncStatus.pendingDelete:
        return 'Pending Delete';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync Failed';
    }
  }
}
