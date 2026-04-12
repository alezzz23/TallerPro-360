import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_order.dart';
import '../domain/dashboard_state.dart';
import '../domain/dashboard_transition.dart';

class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  DashboardController(this._repository) : super(const AsyncValue.loading()) {
    unawaited(loadBoard());
  }

  final DashboardRepository _repository;

  Future<void> loadBoard({bool silent = false}) async {
    final previous = state.valueOrNull;

    if (!silent || previous == null) {
      state = const AsyncValue.loading();
    }

    try {
      final orders = await _repository.fetchDashboardOrders();
      state = AsyncValue.data(DashboardState.fromOrders(orders));
    } catch (error, stackTrace) {
      if (silent && previous != null) {
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh({bool silent = false}) {
    return loadBoard(silent: silent);
  }

  Future<String> moveOrder({
    required DashboardOrder order,
    required DashboardStatus targetStatus,
    required String? currentRole,
    required String? currentUserId,
  }) async {
    final rejection = DashboardTransitionHelper.rejectionReason(
      role: currentRole,
      order: order,
      to: targetStatus,
    );

    if (rejection != null) {
      throw DashboardException(rejection);
    }

    final message = await _repository.moveOrder(
      order: order,
      targetStatus: targetStatus,
      currentUserId: currentUserId,
    );
    await refresh(silent: true);
    return message;
  }
}