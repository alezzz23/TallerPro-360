import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_state.dart';
import '../application/billing_controller.dart';
import '../data/billing_repository.dart';
import '../domain/billing_state.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.watch(appDioProvider));
});

final billingControllerProvider = StateNotifierProvider.autoDispose
    .family<BillingController, BillingState, String>(
  (ref, orderId) {
    return BillingController(
      orderId: orderId,
      dio: ref.watch(appDioProvider),
    );
  },
);
