import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/dashboard/domain/dashboard_order.dart';
import 'package:tallerpro360_mobile/features/dashboard/domain/dashboard_transition.dart';

void main() {
  group('DashboardTransitionHelper', () {
    test('allows supported transitions for permitted roles', () {
      expect(
        DashboardTransitionHelper.canDrop(
          role: 'ASESOR',
          from: DashboardStatus.recepcion,
          to: DashboardStatus.diagnostico,
        ),
        isTrue,
      );

      expect(
        DashboardTransitionHelper.canDrop(
          role: 'JEFE_TALLER',
          from: DashboardStatus.qc,
          to: DashboardStatus.entrega,
        ),
        isTrue,
      );
    });

    test('rejects unsupported and unauthorized transitions with clear reasons', () {
      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'TECNICO',
          from: DashboardStatus.recepcion,
          to: DashboardStatus.diagnostico,
        ),
        'Tu rol no puede mover esta orden.',
      );

      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'ADMIN',
          from: DashboardStatus.diagnostico,
          to: DashboardStatus.reparacion,
        ),
        'Movimiento no soportado en esta fase.',
      );

      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'ADMIN',
          from: DashboardStatus.aprobacion,
          to: DashboardStatus.aprobacion,
        ),
        'La orden ya está en esta fase.',
      );
    });
  });
}