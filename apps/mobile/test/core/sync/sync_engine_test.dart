import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

import 'package:tallerpro360_mobile/core/database/app_database.dart';
import 'package:tallerpro360_mobile/core/sync/sync_status.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  // ── SyncState unit tests ──────────────────────────────────────────────────

  group('SyncState', () {
    test('initial has correct defaults', () {
      const state = SyncState();
      expect(state.status, SyncStatus.idle);
      expect(state.pendingCount, 0);
      expect(state.lastError, isNull);
    });

    test('copyWith only changes specified fields', () {
      const original = SyncState(
        status: SyncStatus.idle,
        pendingCount: 0,
        lastError: null,
      );

      final updated = original.copyWith(
        status: SyncStatus.syncing,
        pendingCount: 3,
      );

      expect(updated.status, SyncStatus.syncing);
      expect(updated.pendingCount, 3);
      expect(updated.lastError, isNull); // unchanged

      final withError = original.copyWith(lastError: 'oops');
      expect(withError.status, SyncStatus.idle); // unchanged
      expect(withError.lastError, 'oops');
    });
  });

  // ── SyncStatus enum ───────────────────────────────────────────────────────

  group('SyncStatus enum', () {
    test('has all required values', () {
      expect(SyncStatus.values, containsAll([
        SyncStatus.idle,
        SyncStatus.syncing,
        SyncStatus.success,
        SyncStatus.failed,
        SyncStatus.offline,
      ]));
    });
  });

  // ── CachedOrdersDao ───────────────────────────────────────────────────────

  group('CachedOrdersDao', () {
    late AppDatabase db;
    late CachedOrdersDao dao;

    setUp(() {
      db = openTestDb();
      dao = db.cachedOrdersDao;
    });

    tearDown(() => db.close());

    test('upsertOrder then allCachedOrders returns entry', () async {
      await dao.upsertOrder(
        CachedOrdersCompanion.insert(
          orderId: 'order-1',
          jsonBlob: '{"key":"value"}',
          cachedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final all = await dao.allCachedOrders();
      expect(all, hasLength(1));
      expect(all.first.orderId, 'order-1');
      expect(all.first.jsonBlob, '{"key":"value"}');
    });

    test('upsertOrder on same orderId replaces (upsert semantics)', () async {
      await dao.upsertOrder(
        CachedOrdersCompanion.insert(
          orderId: 'order-1',
          jsonBlob: '{"v":1}',
          cachedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await dao.upsertOrder(
        CachedOrdersCompanion.insert(
          orderId: 'order-1',
          jsonBlob: '{"v":2}',
          cachedAt: DateTime.utc(2026, 1, 2),
        ),
      );

      final all = await dao.allCachedOrders();
      expect(all, hasLength(1));
      expect(all.first.jsonBlob, '{"v":2}');
    });
  });

  // ── SyncQueueDao ─────────────────────────────────────────────────────────

  group('SyncQueueDao', () {
    late AppDatabase db;
    late SyncQueueDao dao;

    setUp(() {
      db = openTestDb();
      dao = db.syncQueueDao;
    });

    tearDown(() => db.close());

    OfflineSyncQueueCompanion _entry({
      String? orderId,
      String endpoint = '/api/v1/orders',
      String method = 'POST',
      String body = '{}',
    }) =>
        OfflineSyncQueueCompanion.insert(
          orderId: Value(orderId),
          endpoint: endpoint,
          httpMethod: method,
          bodyJson: body,
          createdAt: DateTime.now().toUtc(),
          attemptCount: 0,
          completed: false,
        );

    test('enqueue then pendingEntries returns entry', () async {
      await dao.enqueue(_entry(orderId: 'o1'));
      final pending = await dao.pendingEntries();
      expect(pending, hasLength(1));
      expect(pending.first.orderId, 'o1');
    });

    test('markCompleted → entry no longer in pendingEntries', () async {
      final id = await dao.enqueue(_entry(orderId: 'o2'));
      await dao.markCompleted(id);
      final pending = await dao.pendingEntries();
      expect(pending, isEmpty);
    });

    test('incrementAttemptFor increments attemptCount', () async {
      final id = await dao.enqueue(_entry(orderId: 'o3'));
      final entries = await dao.pendingEntries();
      final entry = entries.first;
      expect(entry.attemptCount, 0);

      await dao.incrementAttemptFor(entry, 'network error');

      final updated = await dao.pendingEntries();
      expect(updated.first.attemptCount, 1);
      expect(updated.first.failureReason, 'network error');
    });

    test('attemptCount < 3 should be retried, >= 3 should be skipped', () async {
      await dao.enqueue(_entry(orderId: 'o4'));
      final entries = await dao.pendingEntries();
      final entry = entries.first;

      // Under max — retryable
      expect(entry.attemptCount < 3, isTrue);

      // Permanently fail it
      await dao.permanentlyFail(entry.id, '4xx');
      final after = await dao.pendingEntries();
      // still in pending (completed=false) but attemptCount >= 3
      expect(after.first.attemptCount, 3);
      // Engine would skip it: attemptCount >= _kMaxAttempts(3)
    });

    test('deduplicateLww keeps only newest entry for same key', () async {
      const endpoint = '/api/v1/orders/o5/reception-checklist';

      await dao.enqueue(_entry(
        orderId: 'o5',
        endpoint: endpoint,
        method: 'PUT',
        body: '{"v":1}',
      ));
      await dao.enqueue(_entry(
        orderId: 'o5',
        endpoint: endpoint,
        method: 'PUT',
        body: '{"v":2}',
      ));
      await dao.enqueue(_entry(
        orderId: 'o5',
        endpoint: endpoint,
        method: 'PUT',
        body: '{"v":3}',
      ));

      await dao.deduplicateLww();
      final pending = await dao.pendingEntries();

      // Only the last (newest) entry should remain pending
      expect(pending, hasLength(1));
      expect(pending.first.bodyJson, '{"v":3}');
    });

    test('deduplicateLww preserves entries with different keys', () async {
      await dao.enqueue(_entry(orderId: 'a', endpoint: '/a', method: 'POST'));
      await dao.enqueue(_entry(orderId: 'b', endpoint: '/b', method: 'POST'));
      await dao.enqueue(_entry(orderId: 'c', endpoint: '/c', method: 'POST'));

      await dao.deduplicateLww();
      final pending = await dao.pendingEntries();
      expect(pending, hasLength(3));
    });

    test('LWW dedup with mixed same and different keys', () async {
      const ep = '/orders/x/confirm';
      await dao.enqueue(_entry(orderId: 'x', endpoint: ep, method: 'POST', body: '{"v":1}'));
      await dao.enqueue(_entry(orderId: 'x', endpoint: ep, method: 'POST', body: '{"v":2}'));
      await dao.enqueue(_entry(orderId: 'y', endpoint: '/orders/y/confirm', method: 'POST'));

      await dao.deduplicateLww();
      final pending = await dao.pendingEntries();

      // One for x (newest v:2), one for y → 2 total
      expect(pending, hasLength(2));
      final xEntry = pending.firstWhere((e) => e.orderId == 'x');
      expect(xEntry.bodyJson, '{"v":2}');
    });
  });
}
