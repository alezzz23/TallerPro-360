import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../application/quotation_controller.dart';
import '../data/quotation_repository.dart';
import '../domain/quotation_state.dart';

final quotationRepositoryProvider = Provider<QuotationRepository>((ref) {
  return QuotationRepository(ref.watch(appDioProvider));
});

final quotationControllerProvider = StateNotifierProvider.autoDispose
    .family<QuotationController, QuotationState, String>(
  (ref, orderId) {
    final repository = ref.watch(quotationRepositoryProvider);
    return QuotationController(
      orderId: orderId,
      repository: repository,
    );
  },
);
