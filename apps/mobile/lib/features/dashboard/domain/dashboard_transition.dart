import 'dashboard_order.dart';

enum DashboardTransitionAction {
  advanceReception,
  approveQuotation,
  startQc,
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
      action: DashboardTransitionAction.startQc,
      from: DashboardStatus.reparacion,
      to: DashboardStatus.qc,
      allowedRoles: {'TECNICO', 'JEFE_TALLER', 'ADMIN'},
      successMessage: 'Orden enviada a Control de Calidad.',
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
    required DashboardOrder order,
  }) {
    if (role == null) {
      return false;
    }
    return _policies.any(
      (policy) =>
          policy.from == order.status &&
          policy.allowedRoles.contains(role) &&
          _preconditionFailure(policy: policy, order: order) == null,
    );
  }

  static bool canDrop({
    required String? role,
    required DashboardOrder order,
    required DashboardStatus to,
  }) {
    final policy = policyFor(from: order.status, to: to);
    if (policy == null || role == null) {
      return false;
    }
    if (!policy.allowedRoles.contains(role)) {
      return false;
    }
    return _preconditionFailure(policy: policy, order: order) == null;
  }

  static String? rejectionReason({
    required String? role,
    required DashboardOrder order,
    required DashboardStatus to,
  }) {
    final from = order.status;

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

    return _preconditionFailure(policy: policy, order: order);
  }

  static String? _preconditionFailure({
    required DashboardTransitionPolicy policy,
    required DashboardOrder order,
  }) {
    switch (policy.action) {
      case DashboardTransitionAction.approveQuotation:
        if (order.quotationStatus == DashboardQuotationStatus.pendiente) {
          return null;
        }
        if (order.quotationStatus == DashboardQuotationStatus.rechazada) {
          return 'La cotización fue rechazada. Reenvíala antes de pasar a Reparación.';
        }
        return 'Primero debes generar una cotización pendiente para pasar a Reparación.';
      case DashboardTransitionAction.advanceReception:
      case DashboardTransitionAction.startQc:
      case DashboardTransitionAction.approveQc:
        return null;
    }
  }
}