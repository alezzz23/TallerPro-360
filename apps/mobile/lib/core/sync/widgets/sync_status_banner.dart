import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity_service.dart';
import '../sync_engine.dart';
import '../sync_status.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncEngineProvider);

    // Offline
    if (isOnlineAsync.valueOrNull == false) {
      return const _Banner(
        color: Color(0xFFB45309), // amber-700
        icon: Icons.cloud_off,
        message: 'Sin conexión — mostrando datos guardados',
      );
    }

    // Syncing
    if (syncState.status == SyncStatus.syncing) {
      return _Banner(
        color: Theme.of(context).primaryColor,
        icon: Icons.sync,
        message: 'Sincronizando ${syncState.pendingCount} cambios...',
        showSpinner: true,
      );
    }

    // Failed with pending items
    if (syncState.status == SyncStatus.failed && syncState.pendingCount > 0) {
      return _Banner(
        color: Colors.orange.shade800,
        icon: Icons.sync_problem,
        message:
            '${syncState.pendingCount} cambios pendientes de sincronización',
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final Color color;
  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          showSpinner
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
