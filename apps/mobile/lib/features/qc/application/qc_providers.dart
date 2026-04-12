import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../application/qc_controller.dart';
import '../data/qc_repository.dart';
import '../domain/qc_state.dart';

final qcRepositoryProvider = Provider<QcRepository>((ref) {
  return QcRepository(ref.watch(appDioProvider));
});

final qcControllerProvider = StateNotifierProvider.autoDispose
    .family<QcController, QcState, String>(
  (ref, orderId) {
    return QcController(
      orderId: orderId,
      dio: ref.watch(appDioProvider),
    );
  },
);
