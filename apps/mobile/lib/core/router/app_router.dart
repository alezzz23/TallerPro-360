import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/reception/presentation/reception_page.dart';
import '../../features/diagnosis/presentation/diagnosis_page.dart';
import '../../features/quotation/presentation/quotation_page.dart';
import '../../features/qc/presentation/qc_page.dart';
import '../../features/billing/presentation/billing_page.dart';
import '../../shared/widgets/loading_widget.dart';

// Named route constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/';
  static const String reception = '/reception';
  static const String diagnosis = '/diagnosis/:orderId';
  static const String quotation = '/quotation/:orderId';
  static const String qc = '/qc/:orderId';
  static const String billing = '/billing/:orderId';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerRefreshNotifier = RouterRefreshNotifier(ref, authStateProvider);
  ref.onDispose(routerRefreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerRefreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isBootPage = state.matchedLocation == AppRoutes.splash;
      final isLoginPage = state.matchedLocation == AppRoutes.login;

      if (!authState.isInitialized) {
        return isBootPage ? null : AppRoutes.splash;
      }

      if (!isLoggedIn) {
        return isLoginPage ? null : AppRoutes.login;
      }

      if (isBootPage || isLoginPage) {
        return _homeLocationForRole(authState.rol);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const _AuthBootstrapPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.reception,
        name: 'reception',
        builder: (_, __) => const ReceptionPage(),
      ),
      GoRoute(
        path: AppRoutes.diagnosis,
        name: 'diagnosis',
        builder: (context, state) => DiagnosisPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.quotation,
        name: 'quotation',
        builder: (context, state) => QuotationPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.qc,
        name: 'qc',
        builder: (context, state) => QcPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.billing,
        name: 'billing',
        builder: (context, state) => BillingPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

/// Notifier to trigger router refresh when auth state changes.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref, ProviderListenable<AuthState> provider) {
    ref.listen(provider, (_, __) => notifyListeners());
  }
}

String _homeLocationForRole(String? role) {
  switch (role) {
    case 'ASESOR':
    case 'TECNICO':
    case 'JEFE_TALLER':
    case 'ADMIN':
    default:
      return AppRoutes.dashboard;
  }
}

class _AuthBootstrapPage extends StatelessWidget {
  const _AuthBootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: LoadingWidget(message: 'Restaurando sesion...'),
      ),
    );
  }
}
