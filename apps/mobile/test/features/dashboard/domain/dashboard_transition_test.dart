import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/dashboard/domain/dashboard_order.dart';
import 'package:tallerpro360_mobile/features/dashboard/domain/dashboard_transition.dart';

void main() {
  group('DashboardTransitionHelper', () {
    DashboardOrder buildOrder({
      required DashboardStatus status,
      DashboardQuotationStatus? quotationStatus,
    }) {
      return DashboardOrder(
        orderId: 'order-1',
        vehicleId: 'vehicle-1',
        advisorId: 'advisor-1',
        backendStatus: status,
        status: status,
        fechaIngreso: DateTime(2026, 4, 11, 8),
        receptionComplete: true,
        quotationStatus: quotationStatus,
        technicianIds: const ['tech-1'],
      );
    }

    test('allows supported transitions for permitted roles', () {
      expect(
        DashboardTransitionHelper.canDrop(
          role: 'ASESOR',
          order: buildOrder(status: DashboardStatus.recepcion),
          to: DashboardStatus.diagnostico,
        ),
        isTrue,
      );

      expect(
        DashboardTransitionHelper.canDrop(
          role: 'JEFE_TALLER',
          order: buildOrder(status: DashboardStatus.qc),
          to: DashboardStatus.entrega,
        ),
        isTrue,
      );

      expect(
        DashboardTransitionHelper.canDrop(
          role: 'TECNICO',
          order: buildOrder(status: DashboardStatus.reparacion),
          to: DashboardStatus.qc,
        ),
        isTrue,
      );
    });

    test('rejects unsupported and unauthorized transitions with clear reasons', () {
      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'TECNICO',
          order: buildOrder(status: DashboardStatus.recepcion),
          to: DashboardStatus.diagnostico,
        ),
        'Tu rol no puede mover esta orden.',
      );

      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'ADMIN',
          order: buildOrder(status: DashboardStatus.diagnostico),
          to: DashboardStatus.reparacion,
        ),
        'Movimiento no soportado en esta fase.',
      );

      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'ADMIN',
          order: buildOrder(
            status: DashboardStatus.aprobacion,
            quotationStatus: DashboardQuotationStatus.rechazada,
          ),
          to: DashboardStatus.reparacion,
        ),
        'La cotización fue rechazada. Reenvíala antes de pasar a Reparación.',
      );

      expect(
        DashboardTransitionHelper.rejectionReason(
          role: 'ADMIN',
          order: buildOrder(status: DashboardStatus.aprobacion),
          to: DashboardStatus.aprobacion,
        ),
        'La orden ya está en esta fase.',
      );
    });
  });
}