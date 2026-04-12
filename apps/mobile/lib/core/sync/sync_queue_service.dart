import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Simple service to enqueue write operations from repositories/controllers.
class SyncQueueService {
  SyncQueueService(this._dao);
  final SyncQueueDao _dao;

  Future<void> enqueue({
    String? orderId,
    required String endpoint,
    required String httpMethod,
    required String bodyJson,
  }) async {
    await _dao.enqueue(
      OfflineSyncQueueCompanion.insert(
        orderId: Value(orderId),
        endpoint: endpoint,
        httpMethod: httpMethod,
        bodyJson: bodyJson,
        createdAt: DateTime.now().toUtc(),
        attemptCount: 0,
        completed: false,
      ),
    );
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService(ref.watch(syncQueueDaoProvider));
});
