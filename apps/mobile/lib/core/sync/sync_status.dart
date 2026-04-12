/// Represents the current state of the background sync engine.
enum SyncStatus {
  idle, // Nothing to sync
  syncing, // Actively processing queue
  success, // Last sync completed without errors
  failed, // Last sync had unrecoverable errors
  offline, // Device is offline
}

class SyncState {
  final SyncStatus status;
  final int pendingCount; // Number of pending queue items
  final String? lastError;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastError,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
  }) =>
      SyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError ?? this.lastError,
      );
}
