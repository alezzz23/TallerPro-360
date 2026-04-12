import 'dashboard_order.dart';

enum DashboardTransitionAction {
  advanceReception,
  approveQuotation,
  approveQc,
}

class DashboardTransitionPolicy {
  const DashboardTransitionPolicy({
    required this.action,
    required this.from,
    required this.to,
    required this.allowedRoles,
    required this.successMessage,
  });

  final DashboardTransitionAction action;
  final DashboardStatus from;
  final DashboardStatus to;
  final Set<String> allowedRoles;
  final String successMessage;
}

class DashboardTransitionHelper {
  DashboardTransitionHelper._();

  static const List<DashboardTransitionPolicy> _policies = [
    DashboardTransitionPolicy(
      action: DashboardTransitionAction.advanceReception,
      from: DashboardStatus.recepcion,
      to: DashboardStatus.diagnostico,
      allowedRoles: {'ASESOR', 'JEFE_TALLER', 'ADMIN'},
      successMessage: 'Orden movida a Diagnóstico.',
    ),
    DashboardTransitionPolicy(
      action: DashboardTransitionAction.approveQuotation,
      from: DashboardStatus.aprobacion,
      to: DashboardStatus.reparacion,
      allowedRoles: {'ASESOR', 'JEFE_TALLER', 'ADMIN'},
      successMessage: 'Cotización aprobada. La orden pasó a Reparación.',
    ),
    DashboardTransitionPolicy(
      action: DashboardTransitionAction.approveQc,
      from: DashboardStatus.qc,
      to: DashboardStatus.entrega,
      allowedRoles: {'JEFE_TALLER', 'ADMIN'},
      successMessage: 'QC aprobado. La orden pasó a Entrega.',
    ),
  ];

  static DashboardTransitionPolicy? policyFor({
    required DashboardStatus from,
    required DashboardStatus to,
  }) {
    for (final policy in _policies) {
      if (policy.from == from && policy.to == to) {
        return policy;
      }
    }
    return null;
  }

  static bool canStartDrag({
    required String? role,
    required DashboardStatus from,
  }) {
    if (role == null) {
      return false;
    }
    return _policies.any(
      (policy) => policy.from == from && policy.allowedRoles.contains(role),
    );
  }

  static bool canDrop({
    required String? role,
    required DashboardStatus from,
    required DashboardStatus to,
  }) {
    final policy = policyFor(from: from, to: to);
    if (policy == null || role == null) {
      return false;
    }
    return policy.allowedRoles.contains(role);
  }

  static String? rejectionReason({
    required String? role,
    required DashboardStatus from,
    required DashboardStatus to,
  }) {
    if (from == to) {
      return 'La orden ya está en esta fase.';
    }

    final policy = policyFor(from: from, to: to);
    if (policy == null) {
      return 'Movimiento no soportado en esta fase.';
    }

    if (role == null || !policy.allowedRoles.contains(role)) {
      return 'Tu rol no puede mover esta orden.';
    }

    return null;
  }
}