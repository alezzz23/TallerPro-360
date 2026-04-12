import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ─── Tables ──────────────────────────────────────────────────────────────────

/// Cache of the active orders list (for offline Dashboard Kanban).
class CachedOrders extends Table {
  /// UUID string — primary key
  TextColumn get orderId => text()();

  /// Full JSON blob of the assembled DashboardOrder
  TextColumn get jsonBlob => text()();

  /// When this entry was last fetched from the server
  DateTimeColumn get cachedAt => dateTime()();

  /// Server ETag (optional, for conditional requests)
  TextColumn get serverEtag => text().nullable()();

  @override
  Set<Column> get primaryKey => {orderId};
}

/// Pending write operations to replay when connectivity is restored.
class OfflineSyncQueue extends Table {
  IntColumn get id => integer()();

  /// The affected order UUID (nullable for non-order-specific ops)
  TextColumn get orderId => text().nullable()();

  /// Full API path, e.g. '/api/v1/orders/xxx/reception-checklist'
  TextColumn get endpoint => text()();

  /// HTTP method: 'POST', 'PUT', 'PATCH'
  TextColumn get httpMethod => text()();

  /// Serialized JSON body
  TextColumn get bodyJson => text()();

  /// When this operation was enqueued
  DateTimeColumn get createdAt => dateTime()();

  /// Number of replay attempts (max 3)
  IntColumn get attemptCount => integer()();

  /// Last failure reason (if any)
  TextColumn get failureReason => text().nullable()();

  /// True once successfully replayed
  BoolColumn get completed => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── DAOs ────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [CachedOrders])
class CachedOrdersDao extends DatabaseAccessor<AppDatabase>
    with _$CachedOrdersDaoMixin {
  CachedOrdersDao(super.db);

  Future<List<CachedOrder>> allCachedOrders() => select(cachedOrders).get();

  Future<void> upsertOrder(CachedOrdersCompanion entry) =>
      into(cachedOrders).insertOnConflictUpdate(entry);

  Future<void> upsertOrders(List<CachedOrdersCompanion> entries) =>
      batch((b) => b.insertAllOnConflictUpdate(cachedOrders, entries));

  Future<void> deleteOrder(String orderId) =>
      (delete(cachedOrders)..where((t) => t.orderId.equals(orderId))).go();

  Future<void> clearAll() => delete(cachedOrders).go();
}

@DriftAccessor(tables: [OfflineSyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<List<OfflineSyncQueueData>> pendingEntries() =>
      (select(offlineSyncQueue)
            ..where((t) => t.completed.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> enqueue(OfflineSyncQueueCompanion entry) =>
      into(offlineSyncQueue).insert(entry);

  Future<void> markCompleted(int id) =>
      (update(offlineSyncQueue)..where((t) => t.id.equals(id)))
          .write(const SyncQueueCompanion(completed: Value(true)));

  Future<void> incrementAttemptFor(OfflineSyncQueueData entry, String? reason) async {
    await (update(offlineSyncQueue)..where((t) => t.id.equals(entry.id))).write(
      OfflineSyncQueueCompanion(
        attemptCount: Value(entry.attemptCount + 1),
        failureReason: Value(reason),
      ),
    );
  }

  /// Mark entry as permanently failed (max attempts exhausted, e.g. 4xx).
  Future<void> permanentlyFail(int id, String reason) =>
      (update(offlineSyncQueue)..where((t) => t.id.equals(id))).write(
        OfflineSyncQueueCompanion(
          attemptCount: const Value(3),
          failureReason: Value(reason),
        ),
      );

  /// Remove duplicate operations for same orderId+endpoint+method, keep only newest.
  /// Uses Last-Write-Wins (LWW) deduplication.
  Future<void> deduplicateLww() async {
    final all = await pendingEntries(); // already sorted by createdAt ASC
    // Group by key, keep the LAST (newest / highest id) entry
    final Map<String, int> latestIdByKey = {};
    for (final entry in all) {
      final key = '${entry.orderId}|${entry.endpoint}|${entry.httpMethod}';
      latestIdByKey[key] = entry.id; // overwrites → last wins
    }
    // Mark all entries that are NOT the latest for their key as completed (skip)
    for (final entry in all) {
      final key = '${entry.orderId}|${entry.endpoint}|${entry.httpMethod}';
      if (latestIdByKey[key] != entry.id) {
        await markCompleted(entry.id);
      }
    }
  }

  Future<int> pendingCount() async {
    final items = await pendingEntries();
    return items.length;
  }

  Future<void> clearCompleted() =>
      (delete(offlineSyncQueue)..where((t) => t.completed.equals(true))).go();
}

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [CachedOrders, OfflineSyncQueue],
  daos: [CachedOrdersDao, SyncQueueDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'tallerpro360.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final cachedOrdersDaoProvider = Provider<CachedOrdersDao>((ref) {
  return ref.watch(appDatabaseProvider).cachedOrdersDao;
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao;
});
