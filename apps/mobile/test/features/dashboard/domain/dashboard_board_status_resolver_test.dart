import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/dashboard/domain/dashboard_order.dart';

void main() {
  group('DashboardBoardStatusResolver', () {
    test('moves diagnostic orders with active quotation into approval column', () {
      expect(
        DashboardBoardStatusResolver.resolve(
          backendStatus: DashboardStatus.diagnostico,
          quotationStatus: DashboardQuotationStatus.pendiente,
        ),
        DashboardStatus.aprobacion,
      );

      expect(
        DashboardBoardStatusResolver.resolve(
          backendStatus: DashboardStatus.diagnostico,
          quotationStatus: DashboardQuotationStatus.rechazada,
        ),
        DashboardStatus.aprobacion,
      );
    });

    test('keeps backend workflow phase when approval is not pending', () {
      expect(
        DashboardBoardStatusResolver.resolve(
          backendStatus: DashboardStatus.diagnostico,
        ),
        DashboardStatus.diagnostico,
      );

      expect(
        DashboardBoardStatusResolver.resolve(
          backendStatus: DashboardStatus.reparacion,
          quotationStatus: DashboardQuotationStatus.pendiente,
        ),
        DashboardStatus.reparacion,
      );
    });
  });
}