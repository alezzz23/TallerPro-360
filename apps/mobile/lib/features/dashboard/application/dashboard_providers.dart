import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../data/dashboard_repository.dart';
import '../data/notification_service.dart';
import '../domain/dashboard_filter_state.dart';
import '../domain/dashboard_state.dart';
import 'dashboard_controller.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(appDioProvider);
  return DashboardRepository(dio);
});

class DashboardFilterNotifier extends Notifier<DashboardFilterState> {
  @override
  DashboardFilterState build() => const DashboardFilterState();

  void setAdvisor(String? advisorId) {
    state = state.copyWith(advisorId: advisorId);
  }

  void setTechnician(String? technicianId) {
    state = state.copyWith(technicianId: technicianId);
  }

  void setDate(DateTime? selectedDate) {
    state = state.copyWith(selectedDate: selectedDate);
  }

  void clearAll() {
    state = const DashboardFilterState();
  }
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilterState>(
  DashboardFilterNotifier.new,
);

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardState>>(
        (ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});

final dashboardViewStateProvider = Provider<AsyncValue<DashboardState>>((ref) {
  final rawState = ref.watch(dashboardControllerProvider);
  final filters = ref.watch(dashboardFilterProvider);
  return rawState.whenData((state) => state.withFilters(filters));
});

class DashboardUnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
  }

  void markAllRead() {
    state = 0;
  }
}

final dashboardUnreadCountProvider =
    NotifierProvider<DashboardUnreadCountNotifier, int>(
        DashboardUnreadCountNotifier.new);

final dashboardNotificationServiceProvider =
    Provider.autoDispose<NotificationService?>((ref) {
  final token = ref.watch(authStateProvider.select((state) => state.token));
  if (token == null || token.isEmpty) {
    return null;
  }

  final service = NotificationService(
    token: token,
    onNotification: () {
      ref.read(dashboardUnreadCountProvider.notifier).increment();
      unawaited(
        ref.read(dashboardControllerProvider.notifier).refresh(silent: true),
      );
    },
    onMarkAllRead: () {
      ref.read(dashboardUnreadCountProvider.notifier).markAllRead();
    },
  );

  unawaited(service.connect());
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
