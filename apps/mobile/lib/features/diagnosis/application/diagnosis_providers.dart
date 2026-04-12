import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../data/diagnosis_repository.dart';
import '../domain/diagnosis_state.dart';
import 'diagnosis_controller.dart';

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  final dio = ref.watch(appDioProvider);
  return DiagnosisRepository(dio);
});

final diagnosisControllerProvider = StateNotifierProvider.autoDispose
    .family<DiagnosisController, DiagnosisState, String>(
  (ref, orderId) {
    final repository = ref.watch(diagnosisRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    return DiagnosisController(
      repository: repository,
      orderId: orderId,
      currentUserId: authState.userId,
    );
  },
);
