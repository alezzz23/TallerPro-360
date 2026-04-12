import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../database/app_database.dart';
import 'connectivity_service.dart';
import 'sync_status.dart';

/// Maximum number of replay attempts before a queue item is permanently failed.
const int _kMaxAttempts = 3;

class SyncEngine extends StateNotifier<SyncState> {
  SyncEngine({
    required Ref ref,
    required SyncQueueDao queueDao,
    required Dio dio,
  })  : _ref = ref,
        _queueDao = queueDao,
        _dio = dio,
        super(const SyncState());

  final Ref _ref;
  final SyncQueueDao _queueDao;
  final Dio _dio;

  bool _isSyncing = false;

  /// Connect to connectivity stream — call once during init.
  void init() {
    _ref.listen(isOnlineProvider, (_, next) {
      next.whenData((online) {
        if (online && !_isSyncing) {
          processQueue();
        } else if (!online) {
          state = state.copyWith(status: SyncStatus.offline);
        }
      });
    });
    // Kick off an initial check + sync if online.
    _ref.read(connectivityServiceProvider).isOnline.then((online) {
      if (online) processQueue();
    });
  }

  /// Enqueue a pending write operation.
  Future<void> enqueue({
    String? orderId,
    required String endpoint,
    required String httpMethod,
    required Map<String, dynamic> body,
  }) async {
    await _queueDao.enqueue(
      OfflineSyncQueueCompanion.insert(
        orderId: Value(orderId),
        endpoint: endpoint,
        httpMethod: httpMethod,
        bodyJson: jsonEncode(body),
        createdAt: DateTime.now().toUtc(),
        attemptCount: 0,
        completed: false,
      ),
    );
    final count = await _queueDao.pendingCount();
    state = state.copyWith(pendingCount: count);
  }

  /// Process all pending queue items.
  /// Applies LWW deduplication before processing.
  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      await _queueDao.deduplicateLww();

      final pending = await _queueDao.pendingEntries();
      if (pending.isEmpty) {
        state = state.copyWith(status: SyncStatus.idle, pendingCount: 0);
        return;
      }

      bool hadErrors = false;

      for (final entry in pending) {
        if (entry.completed) continue;
        if (entry.attemptCount >= _kMaxAttempts) {
          hadErrors = true;
          continue;
        }

        try {
          final body = jsonDecode(entry.bodyJson) as Map<String, dynamic>;
          final method = entry.httpMethod.toUpperCase();

          Response<dynamic> response;
          switch (method) {
            case 'POST':
              response = await _dio.post(entry.endpoint, data: body);
            case 'PUT':
              response = await _dio.put(entry.endpoint, data: body);
            case 'PATCH':
              response = await _dio.patch(entry.endpoint, data: body);
            default:
              response = await _dio.post(entry.endpoint, data: body);
          }

          if ((response.statusCode ?? 0) >= 200 &&
              (response.statusCode ?? 0) < 300) {
            await _queueDao.markCompleted(entry.id);
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode ?? 0;
          if (statusCode >= 400 && statusCode < 500) {
            // Client error (4xx) — will not succeed on retry; max out attempts
            await _queueDao.permanentlyFail(
              entry.id,
              'HTTP $statusCode — permanent failure',
            );
            hadErrors = true;
          } else {
            // Network / server error — increment and retry next time
            await _queueDao.incrementAttemptFor(entry, e.message);
            hadErrors = true;
          }
        }
      }

      await _queueDao.clearCompleted();
      final remaining = await _queueDao.pendingCount();
      state = state.copyWith(
        status: hadErrors ? SyncStatus.failed : SyncStatus.success,
        pendingCount: remaining,
        lastError: hadErrors
            ? 'Algunos cambios no pudieron sincronizarse'
            : null,
      );
    } finally {
      _isSyncing = false;
    }
  }
}

final syncEngineProvider =
    StateNotifierProvider<SyncEngine, SyncState>((ref) {
  final engine = SyncEngine(
    ref: ref,
    queueDao: ref.watch(syncQueueDaoProvider),
    dio: ref.watch(appDioProvider),
  );
  engine.init();
  return engine;
});
