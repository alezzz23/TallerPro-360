import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../data/reception_repository.dart';
import '../domain/reception_state.dart';
import 'reception_controller.dart';

final receptionRepositoryProvider = Provider<ReceptionRepository>((ref) {
  final dio = ref.watch(appDioProvider);
  return ReceptionRepository(dio);
});

final receptionControllerProvider = StateNotifierProvider.autoDispose
    .family<ReceptionController, ReceptionState, String?>((ref, initialOrderId) {
  final repository = ref.watch(receptionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ReceptionController(
    repository: repository,
    advisorId: authState.userId,
    role: authState.rol,
    initialOrderId: initialOrderId,
  );
});