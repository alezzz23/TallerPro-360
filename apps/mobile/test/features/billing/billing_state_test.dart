import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/billing/domain/billing_models.dart';
import 'package:tallerpro360_mobile/features/billing/domain/billing_state.dart';

void main() {
  // ─── BillingState.initial() defaults ─────────────────────────────────────

  group('BillingState.initial()', () {
    test('has correct MetodoPago default', () {
      final s = BillingState.initial();
      expect(s.selectedMetodoPago, MetodoPago.efectivo);
    });

    test('NPS scores default: 7 except recomendacion=8', () {
      final s = BillingState.initial();
      expect(s.npsAtencion, 7);
      expect(s.npsInstalaciones, 7);
      expect(s.npsTiempos, 7);
      expect(s.npsPrecios, 7);
      expect(s.npsRecomendacion, 8);
    });

    test('isLoading is true (all three loading flags set)', () {
      final s = BillingState.initial();
      expect(s.isLoading, isTrue);
    });

    test('canCloseOrder is false initially', () {
      final s = BillingState.initial();
      expect(s.canCloseOrder, isFalse);
    });
  });

  // ─── copyWith sentinel ────────────────────────────────────────────────────

  group('copyWith sentinel', () {
    test('updates only specified fields', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        npsAtencion: 9,
      );
      // Changed
      expect(s.npsAtencion, 9);
      expect(s.isLoading, isFalse);
      // Unchanged
      expect(s.npsInstalaciones, 7);
      expect(s.npsRecomendacion, 8);
      expect(s.selectedMetodoPago, MetodoPago.efectivo);
    });

    test('nullable sentinel: setting errorMessage to null works', () {
      final s = BillingState.initial()
          .copyWith(errorMessage: 'err')
          .copyWith(errorMessage: null);
      expect(s.errorMessage, isNull);
    });

    test('nullable sentinel: omitting errorMessage preserves it', () {
      final s1 = BillingState.initial().copyWith(errorMessage: 'persistido');
      final s2 = s1.copyWith(npsAtencion: 5);
      expect(s2.errorMessage, 'persistido');
    });
  });

  // ─── canCloseOrder ────────────────────────────────────────────────────────

  final invoice = InvoiceModel(
    id: 'inv-1',
    orderId: 'ord-1',
    montoTotal: 10000,
    metodoPago: MetodoPago.efectivo,
    esCredito: false,
    saldoPendiente: 0,
    fecha: DateTime(2026, 4, 11),
  );

  final nps = NpsModel(
    id: 'nps-1',
    orderId: 'ord-1',
    atencion: 8,
    instalaciones: 7,
    tiempos: 9,
    precios: 7,
    recomendacion: 10,
    fecha: DateTime(2026, 4, 11),
  );

  group('canCloseOrder', () {
    test('false when invoice is null', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        nps: nps,
      );
      expect(s.canCloseOrder, isFalse);
    });

    test('false when nps is null', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        invoice: invoice,
      );
      expect(s.canCloseOrder, isFalse);
    });

    test('true when both invoice and nps are set and orderClosed=false', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        invoice: invoice,
        nps: nps,
        orderClosed: false,
      );
      expect(s.canCloseOrder, isTrue);
    });

    test('false when orderClosed=true (already closed)', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        invoice: invoice,
        nps: nps,
        orderClosed: true,
      );
      expect(s.canCloseOrder, isFalse);
    });
  });

  // ─── canCreateInvoice ─────────────────────────────────────────────────────

  group('canCreateInvoice', () {
    test('true only when invoice==null && orderEstado==ENTREGA', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        orderEstado: 'ENTREGA',
      );
      expect(s.canCreateInvoice, isTrue);
    });

    test('false when invoice already exists', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        orderEstado: 'ENTREGA',
        invoice: invoice,
      );
      expect(s.canCreateInvoice, isFalse);
    });

    test('false when orderEstado is not ENTREGA', () {
      final s = BillingState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingInvoice: false,
        isLoadingNps: false,
        orderEstado: 'QC',
      );
      expect(s.canCreateInvoice, isFalse);
    });
  });

  // ─── canSubmitNps ─────────────────────────────────────────────────────────

  group('canSubmitNps', () {
    test('false when nps is non-null', () {
      final s = BillingState.initial().copyWith(nps: nps);
      expect(s.canSubmitNps, isFalse);
    });

    test('true when nps is null', () {
      final s = BillingState.initial();
      expect(s.canSubmitNps, isTrue);
    });
  });

  // ─── MetodoPago ───────────────────────────────────────────────────────────

  group('MetodoPago', () {
    test('efectivo.apiValue == EFECTIVO', () {
      expect(MetodoPago.efectivo.apiValue, 'EFECTIVO');
    });

    test('fromApi(TARJETA) == tarjeta', () {
      expect(MetodoPago.fromApi('TARJETA'), MetodoPago.tarjeta);
    });

    test('fromApi is case-insensitive', () {
      expect(MetodoPago.fromApi('transferencia'), MetodoPago.transferencia);
    });
  });

  // ─── InvoiceModel.fromJson ────────────────────────────────────────────────

  group('InvoiceModel.fromJson', () {
    test('round-trip preserves montoTotal and metodoPago enum', () {
      final json = {
        'id': 'abc-123',
        'order_id': 'ord-456',
        'monto_total': 15750.50,
        'metodo_pago': 'TARJETA',
        'es_credito': false,
        'saldo_pendiente': 0.0,
        'fecha': '2026-04-11T10:00:00',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.montoTotal, 15750.50);
      expect(model.metodoPago, MetodoPago.tarjeta);
      expect(model.id, 'abc-123');
      expect(model.orderId, 'ord-456');
      expect(model.esCredito, isFalse);
    });

    test('int monto_total is coerced to double', () {
      final json = {
        'id': 'x',
        'order_id': 'y',
        'monto_total': 5000,
        'metodo_pago': 'EFECTIVO',
        'es_credito': false,
        'saldo_pendiente': 0,
        'fecha': '2026-04-11T00:00:00',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.montoTotal, isA<double>());
      expect(model.montoTotal, 5000.0);
    });
  });

  // ─── NpsModel.fromJson ────────────────────────────────────────────────────

  group('NpsModel.fromJson', () {
    test('preserves all 5 scores and comentarios', () {
      final json = {
        'id': 'nps-99',
        'order_id': 'ord-99',
        'atencion': 8,
        'instalaciones': 6,
        'tiempos': 9,
        'precios': 7,
        'recomendacion': 10,
        'comentarios': 'Excelente servicio',
        'fecha': '2026-04-11T12:30:00',
      };
      final model = NpsModel.fromJson(json);
      expect(model.atencion, 8);
      expect(model.instalaciones, 6);
      expect(model.tiempos, 9);
      expect(model.precios, 7);
      expect(model.recomendacion, 10);
      expect(model.comentarios, 'Excelente servicio');
    });

    test('comentarios is null when not provided', () {
      final json = {
        'id': 'nps-00',
        'order_id': 'ord-00',
        'atencion': 5,
        'instalaciones': 5,
        'tiempos': 5,
        'precios': 5,
        'recomendacion': 5,
        'comentarios': null,
        'fecha': '2026-04-11T08:00:00',
      };
      final model = NpsModel.fromJson(json);
      expect(model.comentarios, isNull);
    });
  });
}
