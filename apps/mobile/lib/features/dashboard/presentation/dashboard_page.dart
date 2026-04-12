import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${state.visibleOrders.length} órdenes activas · Actualizado ${state.refreshedAt.toLocal().toDisplayDateTime()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
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
                            );
                          },
                          onOpenOrder: (order) => _openOrder(context, order),
                          onRejectedDrop: (order) {
                            _showSnackBar(
                              context,
                              'Movimiento no soportado en esta fase.',
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
  ) async {
    try {
      final message =
          await ref.read(dashboardControllerProvider.notifier).moveOrder(
                order: order,
                targetStatus: targetStatus,
                currentRole: currentRole,
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
        context.pushNamed('reception');
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
