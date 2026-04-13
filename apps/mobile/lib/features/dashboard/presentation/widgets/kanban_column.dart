import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/dashboard_order.dart';
import '../../domain/dashboard_transition.dart';
import 'order_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.orders,
    required this.currentRole,
    required this.onAcceptOrder,
    required this.onOpenOrder,
    required this.onRejectedDrop,
  });

  final DashboardStatus status;
  final List<DashboardOrder> orders;
  final String? currentRole;
  final Future<void> Function(DashboardOrder order, DashboardStatus targetStatus)
      onAcceptOrder;
  final void Function(DashboardOrder order) onOpenOrder;
  final void Function(DashboardOrder order) onRejectedDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = AppTheme.statusColor(status.apiValue);

    return DragTarget<DashboardOrder>(
      onWillAcceptWithDetails: (details) {
        final candidate = details.data;
        return DashboardTransitionHelper.canDrop(
          role: currentRole,
          order: candidate,
          to: status,
        );
      },
      onAcceptWithDetails: (details) {
        unawaited(onAcceptOrder(details.data, status));
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHighlighted
                ? accentColor.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlighted
                  ? accentColor
                  : theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, color: accentColor),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 32,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sin órdenes',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return OrderCard(
                            order: order,
                            draggable: DashboardTransitionHelper.canStartDrag(
                              role: currentRole,
                              order: order,
                            ),
                            onTap: () => onOpenOrder(order),
                            onRejectedDrop: () => onRejectedDrop(order),
                          );
                        },
                      ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}