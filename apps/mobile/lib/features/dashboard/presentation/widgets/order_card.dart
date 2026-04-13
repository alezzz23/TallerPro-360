import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/dashboard_order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.draggable,
    required this.onTap,
    required this.onRejectedDrop,
  });

  final DashboardOrder order;
  final bool draggable;
  final VoidCallback onTap;
  final VoidCallback onRejectedDrop;

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      label: 'Orden ${order.displayPlate}, ${order.status.label}',
      child: _ScaleFeedback(
        onTap: onTap,
        child: _buildCard(context),
      ),
    );
    if (!draggable) {
      return card;
    }

    return LongPressDraggable<DashboardOrder>(
      data: order,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Opacity(
            opacity: 0.96,
            child: _buildCard(context),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          onRejectedDrop();
        }
      },
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = AppTheme.statusColor(order.status.apiValue);
    final surfaceTint = Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      theme.colorScheme.surface,
    );
    final showReceptionIndicator =
        order.status == DashboardStatus.recepcion || !order.receptionComplete;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceTint,
          border: Border(left: BorderSide(color: accentColor, width: 5)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.displayPlate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (draggable)
                    Icon(
                      Icons.drag_indicator_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.displayVehicle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                text: order.displayCustomerName,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.build_circle_outlined,
                text: order.displayMotive,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.flag_outlined,
                    label: order.status.label,
                    color: accentColor,
                  ),
                  _MetaPill(
                    icon: Icons.confirmation_number_outlined,
                    label: '#${order.shortOrderId}',
                    color: theme.colorScheme.primary,
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: order.fechaIngreso.toLocal().toDisplayDateTime(),
                    color: theme.colorScheme.secondary,
                  ),
                  if (showReceptionIndicator)
                    _MetaPill(
                      icon: order.receptionComplete
                          ? Icons.task_alt_rounded
                          : Icons.error_outline_rounded,
                      label: order.receptionComplete
                          ? 'Recepción lista'
                          : 'Recepción pendiente',
                      color: order.receptionComplete
                          ? Colors.green.shade700
                          : theme.colorScheme.error,
                    ),
                  if (order.quotationStatus != null &&
                      order.status == DashboardStatus.aprobacion)
                    _MetaPill(
                      icon: order.quotationStatus == DashboardQuotationStatus.rechazada
                          ? Icons.warning_amber_rounded
                          : Icons.mark_chat_unread_outlined,
                      label: order.quotationStatus!.label,
                      color: order.quotationStatus == DashboardQuotationStatus.rechazada
                          ? theme.colorScheme.error
                          : accentColor,
                    ),
                  if (order.technicianIds.isNotEmpty)
                    _MetaPill(
                      icon: Icons.engineering_outlined,
                      label:
                          '${order.technicianIds.length} técnico${order.technicianIds.length == 1 ? '' : 's'}',
                      color: theme.colorScheme.tertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _ScaleFeedback extends StatefulWidget {
  const _ScaleFeedback({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_ScaleFeedback> createState() => _ScaleFeedbackState();
}

class _ScaleFeedbackState extends State<_ScaleFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(_) => _ctrl.forward();
  void _onUp(_) => _ctrl.reverse();
  void _onCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });
  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment:
          maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}