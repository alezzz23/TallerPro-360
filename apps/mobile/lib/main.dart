import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TallerPro360App()));
}

class TallerPro360App extends ConsumerWidget {
  const TallerPro360App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncEngineProvider); // eagerly initialize sync engine
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TallerPro 360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
