import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/widgets/sync_status_banner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/domain/auth_state.dart';
import '../application/dashboard_providers.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_order.dart';
import '../domain/dashboard_state.dart';
import 'widgets/dashboard_filter_bar.dart';
import 'widgets/kanban_column.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final role = authState.rol;
    final userId = authState.userId;
    final subtitle = _subtitleForRole(role);
    final unreadCount = ref.watch(dashboardUnreadCountProvider);
    final notificationService = ref.watch(dashboardNotificationServiceProvider);
    final dashboardAsync = ref.watch(dashboardViewStateProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TallerPro 360'),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        actions: [
          if (role != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _RoleChip(role: role),
            ),
          _NotificationActionButton(
            count: unreadCount,
            onPressed: () {
              notificationService?.markAllRead();
              if (notificationService == null) {
                ref.read(dashboardUnreadCountProvider.notifier).markAllRead();
              }
            },
          ),
          IconButton(
            tooltip: 'Actualizar tablero',
            onPressed: () {
              ref.read(dashboardControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: authState.email == null
                ? 'Cerrar sesion'
                : 'Cerrar sesion (${authState.email})',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: _canStartReception(role)
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed('reception'),
              icon: const Icon(Icons.add_road_rounded),
              label: const Text('Nueva recepcion'),
            )
          : null,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const LoadingWidget(
            message: 'Cargando tablero operativo...',
          ),
          error: (error, _) => EmptyStateWidget(
            icon: Icons.view_kanban_outlined,
            title: 'No se pudo cargar el dashboard',
            message: _messageFromError(error),
            actionLabel: 'Reintentar',
            onAction: () {
              ref.read(dashboardControllerProvider.notifier).refresh();
            },
          ),
          data: (state) {
            return Column(
              children: [
                const SyncStatusBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: DashboardFilterBar(
                    state: state,
                    onAdvisorChanged: (advisorId) {
                      ref
                          .read(dashboardFilterProvider.notifier)
                          .setAdvisor(advisorId);
                    },
                    onTechnicianChanged: (technicianId) {
                      ref
                          .read(dashboardFilterProvider.notifier)
                          .setTechnician(technicianId);
                    },
                    onPickDate: () => _pickDate(
                      context,
                      ref,
                      state.filters.selectedDate,
                    ),
                    onClearDate: () {
                      ref.read(dashboardFilterProvider.notifier).setDate(null);
                    },
                    onClearFilters: () {
                      ref.read(dashboardFilterProvider.notifier).clearAll();
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _BoardLegend(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _StatBadge(
                        icon: Icons.assignment_outlined,
                        label: '${state.visibleOrders.length} órdenes',
                      ),
                      _StatBadge(
                        icon: Icons.update_rounded,
                        label: 'Act. ${state.refreshedAt.toLocal().toDisplayDateTime()}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.inbox_outlined,
                          title: state.filters.hasActiveFilters
                              ? 'Sin coincidencias'
                              : 'Sin órdenes activas',
                          message: state.filters.hasActiveFilters
                              ? 'No hay órdenes que coincidan con los filtros seleccionados.'
                              : 'No hay órdenes activas en el taller en este momento.',
                          actionLabel: state.filters.hasActiveFilters
                              ? 'Limpiar filtros'
                              : null,
                          onAction: state.filters.hasActiveFilters
                              ? () {
                                  ref
                                      .read(dashboardFilterProvider.notifier)
                                      .clearAll();
                                }
                              : null,
                        )
                      : _DashboardBoard(
                          state: state,
                          currentRole: role,
                          onAcceptOrder: (order, targetStatus) {
                            return _moveOrder(
                              context,
                              ref,
                              order,
                              targetStatus,
                              role,
                              userId,
                            );
                          },
                          onOpenOrder: (order) => _openOrder(context, order),
                          onRejectedDrop: (order) {
                            _showSnackBar(
                              context,
                              'No puedes mover esta orden a esa fase desde el tablero.',
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? currentDate,
  ) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );

    if (selected != null) {
      ref.read(dashboardFilterProvider.notifier).setDate(selected);
    }
  }

  static Future<void> _moveOrder(
    BuildContext context,
    WidgetRef ref,
    DashboardOrder order,
    DashboardStatus targetStatus,
    String? currentRole,
    String? currentUserId,
  ) async {
    try {
      final message =
          await ref.read(dashboardControllerProvider.notifier).moveOrder(
                order: order,
                targetStatus: targetStatus,
                currentRole: currentRole,
                currentUserId: currentUserId,
              );
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, message);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(context, _messageFromError(error));
    }
  }

  static void _openOrder(BuildContext context, DashboardOrder order) {
    switch (order.status) {
      case DashboardStatus.recepcion:
        context.pushNamed(
          'reception',
          queryParameters: {'orderId': order.orderId},
        );
        break;
      case DashboardStatus.diagnostico:
        context.pushNamed(
          'diagnosis',
          pathParameters: {'orderId': order.orderId},
        );
        break;
      case DashboardStatus.aprobacion:
        context.pushNamed(
          'quotation',
          pathParameters: {'orderId': order.orderId},
        );
        break;
      case DashboardStatus.reparacion:
        context.pushNamed(
          'diagnosis',
          pathParameters: {'orderId': order.orderId},
        );
        break;
      case DashboardStatus.qc:
        context.pushNamed(
          'qc',
          pathParameters: {'orderId': order.orderId},
        );
        break;
      case DashboardStatus.entrega:
        context.pushNamed(
          'billing',
          pathParameters: {'orderId': order.orderId},
        );
        break;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static String _messageFromError(Object error) {
    if (error is DashboardException) {
      return error.message;
    }
    final message = error.toString().trim();
    return message.isEmpty ? 'Ocurrió un error inesperado.' : message;
  }

  static String _subtitleForRole(String? role) => switch (role) {
        'ASESOR' => 'Vista de asesor de servicio',
        'TECNICO' => 'Vista tecnica del taller',
        'JEFE_TALLER' => 'Vista de jefatura de taller',
        'ADMIN' => 'Vista administrativa',
        _ => 'Tablero operativo',
      };

  static bool _canStartReception(String? role) => switch (role) {
        'ASESOR' || 'JEFE_TALLER' || 'ADMIN' => true,
        _ => false,
      };
}

class _DashboardBoard extends StatelessWidget {
  const _DashboardBoard({
    required this.state,
    required this.currentRole,
    required this.onAcceptOrder,
    required this.onOpenOrder,
    required this.onRejectedDrop,
  });

  final DashboardState state;
  final String? currentRole;
  final Future<void> Function(
      DashboardOrder order, DashboardStatus targetStatus) onAcceptOrder;
  final void Function(DashboardOrder order) onOpenOrder;
  final void Function(DashboardOrder order) onRejectedDrop;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: DashboardStatus.boardColumns.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final status = DashboardStatus.boardColumns[index];
        return SizedBox(
          width: 292,
          child: KanbanColumn(
            status: status,
            orders: state.columns[status] ?? const <DashboardOrder>[],
            currentRole: currentRole,
            onAcceptOrder: onAcceptOrder,
            onOpenOrder: onOpenOrder,
            onRejectedDrop: onRejectedDrop,
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          role.replaceAll('_', ' ').toTitleCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: count > 0
          ? '$count notificaciones no leídas'
          : 'Sin notificaciones nuevas',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: -8,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardLegend extends StatelessWidget {
  const _BoardLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _LegendChip(label: 'Pendiente', color: AppColors.statusPending),
        _LegendChip(label: 'En proceso', color: AppColors.statusInProgress),
        _LegendChip(label: 'Listo', color: AppColors.statusReady),
        _LegendChip(
          label: 'Mantén presionado para mover',
          color: AppColors.secondary,
          icon: Icons.pan_tool_alt_rounded,
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
