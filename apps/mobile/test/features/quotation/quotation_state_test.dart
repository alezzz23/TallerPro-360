import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/quotation/domain/quotation_models.dart';
import 'package:tallerpro360_mobile/features/quotation/domain/quotation_state.dart';

void main() {
  // ─── QuotationState ─────────────────────────────────────────────────────────

  group('QuotationState', () {
    test('copyWith returns same values when no params changed', () {
      final initial = QuotationState.initial();
      final copy = initial.copyWith();

      expect(copy.isLoadingFindings, initial.isLoadingFindings);
      expect(copy.isLoadingQuotation, initial.isLoadingQuotation);
      expect(copy.isSaving, initial.isSaving);
      expect(copy.findings, initial.findings);
      expect(copy.quotation, initial.quotation);
      expect(copy.errorMessage, initial.errorMessage);
      expect(copy.safetyLog, initial.safetyLog);
      expect(copy.descuento, initial.descuento);
      expect(copy.impuestosPct, initial.impuestosPct);
      expect(copy.shopSuppliesPct, initial.shopSuppliesPct);
    });

    test('copyWith with sentinel correctly updates individual fields', () {
      final initial = QuotationState.initial();

      final updated = initial.copyWith(
        isLoadingFindings: false,
        errorMessage: 'Error de prueba',
      );

      expect(updated.isLoadingFindings, false);
      expect(updated.isLoadingQuotation, true); // unchanged
      expect(updated.isSaving, false); // unchanged
      expect(updated.errorMessage, 'Error de prueba');
      expect(updated.safetyLog, null); // unchanged
    });

    test('copyWith sentinel allows clearing nullable fields to null', () {
      final withErrors = QuotationState.initial().copyWith(
        errorMessage: 'un error',
        safetyLog: 'advertencia',
      );

      final cleared = withErrors.copyWith(
        errorMessage: null,
        safetyLog: null,
      );

      expect(cleared.errorMessage, isNull);
      expect(cleared.safetyLog, isNull);
    });

    test('isLoading is true when either findings or quotation is loading', () {
      final bothLoading = QuotationState.initial();
      expect(bothLoading.isLoading, isTrue);

      final findingsLoaded = bothLoading.copyWith(isLoadingFindings: false);
      expect(findingsLoaded.isLoading, isTrue);

      final bothLoaded = findingsLoaded.copyWith(isLoadingQuotation: false);
      expect(bothLoaded.isLoading, isFalse);
    });

    test(
        'builder total computation: subtotal=1000, shopSupplies=15, '
        'impuestos≈162.4, total≈1177.4', () {
      final state = QuotationState(
        isLoadingFindings: false,
        isLoadingQuotation: false,
        isSaving: false,
        findings: const [],
        lineItems: const {
          'f1': QuotationLineItem(
            findingId: 'f1',
            descripcion: 'Cambio de pastillas',
            manoObra: 600.0,
            costoRepuesto: 400.0,
          ),
        },
        descuento: 0.0,
        impuestosPct: 0.16,
        shopSuppliesPct: 0.015,
      );

      expect(state.previewSubtotal, 1000.0);
      expect(state.previewShopSupplies, closeTo(15.0, 0.001));
      // impuestos = (1000 + 15 - 0) * 0.16 = 162.4
      expect(state.previewImpuestos, closeTo(162.4, 0.01));
      // total = 1000 + 15 + 162.4 - 0 = 1177.4
      expect(state.previewTotal, closeTo(1177.4, 0.01));
    });

    test('builder total respects non-zero descuento', () {
      final state = QuotationState(
        isLoadingFindings: false,
        isLoadingQuotation: false,
        isSaving: false,
        findings: const [],
        lineItems: const {
          'f1': QuotationLineItem(
            findingId: 'f1',
            descripcion: 'Test',
            manoObra: 1000.0,
            costoRepuesto: 0.0,
          ),
        },
        descuento: 100.0,
        impuestosPct: 0.16,
        shopSuppliesPct: 0.015,
      );

      // subtotal = 1000, shopSupplies = 15
      // impuestos = (1000 + 15 - 100) * 0.16 = 915 * 0.16 = 146.4
      // total = 1000 + 15 + 146.4 - 100 = 1061.4
      expect(state.previewSubtotal, 1000.0);
      expect(state.previewShopSupplies, closeTo(15.0, 0.001));
      expect(state.previewImpuestos, closeTo(146.4, 0.01));
      expect(state.previewTotal, closeTo(1061.4, 0.01));
    });

    test('builder preview is zero with empty lineItems', () {
      final state = QuotationState.initial().copyWith(
        isLoadingFindings: false,
        isLoadingQuotation: false,
      );

      expect(state.previewSubtotal, 0.0);
      expect(state.previewShopSupplies, 0.0);
      expect(state.previewImpuestos, 0.0);
      expect(state.previewTotal, 0.0);
    });
  });

  // ─── QuotationLineItem ───────────────────────────────────────────────────────

  group('QuotationLineItem', () {
    test('costoTotal = manoObra + costoRepuesto', () {
      const item = QuotationLineItem(
        findingId: 'f1',
        descripcion: 'Frenos',
        manoObra: 500.0,
        costoRepuesto: 250.0,
      );

      expect(item.costoTotal, 750.0);
    });

    test('costoTotal is 0 when both are 0', () {
      const item = QuotationLineItem(
        findingId: 'f1',
        descripcion: 'Revisión',
        manoObra: 0.0,
        costoRepuesto: 0.0,
      );

      expect(item.costoTotal, 0.0);
    });

    test('copyWith updates individual fields via sentinel', () {
      const item = QuotationLineItem(
        findingId: 'f1',
        descripcion: 'Original',
        manoObra: 100.0,
        costoRepuesto: 50.0,
        partId: 'p1',
      );

      final updated = item.copyWith(manoObra: 200.0);
      expect(updated.manoObra, 200.0);
      expect(updated.costoRepuesto, 50.0); // unchanged
      expect(updated.partId, 'p1'); // unchanged

      // Clearing partId via sentinel (pass null explicitly).
      final noPartId = item.copyWith(partId: null);
      expect(noPartId.partId, isNull);
    });
  });

  // ─── QuotationEstado ─────────────────────────────────────────────────────────

  group('QuotationEstado', () {
    test('label returns correct Spanish strings', () {
      expect(QuotationEstado.pendiente.label, 'Pendiente');
      expect(QuotationEstado.aprobada.label, 'Aprobada');
      expect(QuotationEstado.rechazada.label, 'Rechazada');
    });

    test('fromJson maps uppercase strings correctly', () {
      expect(QuotationEstado.fromJson('PENDIENTE'), QuotationEstado.pendiente);
      expect(QuotationEstado.fromJson('APROBADA'), QuotationEstado.aprobada);
      expect(QuotationEstado.fromJson('RECHAZADA'), QuotationEstado.rechazada);
    });

    test('fromJson falls back to pendiente for unknown value', () {
      expect(
          QuotationEstado.fromJson('UNKNOWN'), QuotationEstado.pendiente);
    });
  });

  // ─── QuotationModel ──────────────────────────────────────────────────────────

  group('QuotationModel', () {
    test('fromJson round-trip preserves all fields including estado enum', () {
      final json = <String, dynamic>{
        'id': 'qid-123',
        'order_id': 'oid-456',
        'subtotal': 1000.0,
        'impuestos': 162.4,
        'shop_supplies': 15.0,
        'descuento': 0.0,
        'total': 1177.4,
        'estado': 'PENDIENTE',
        'fecha_envio': null,
        'items': <dynamic>[],
      };

      final model = QuotationModel.fromJson(json);

      expect(model.id, 'qid-123');
      expect(model.orderId, 'oid-456');
      expect(model.subtotal, 1000.0);
      expect(model.impuestos, closeTo(162.4, 0.001));
      expect(model.shopSupplies, 15.0);
      expect(model.descuento, 0.0);
      expect(model.total, closeTo(1177.4, 0.001));
      expect(model.estado, QuotationEstado.pendiente);
      expect(model.fechaEnvio, isNull);
      expect(model.items, isEmpty);
    });

    test('fromJson parses fechaEnvio correctly', () {
      final json = <String, dynamic>{
        'id': 'q1',
        'order_id': 'o1',
        'subtotal': 0.0,
        'impuestos': 0.0,
        'shop_supplies': 0.0,
        'descuento': 0.0,
        'total': 0.0,
        'estado': 'APROBADA',
        'fecha_envio': '2026-04-11T10:30:00',
        'items': <dynamic>[],
      };

      final model = QuotationModel.fromJson(json);

      expect(model.fechaEnvio, isNotNull);
      expect(model.fechaEnvio!.year, 2026);
      expect(model.fechaEnvio!.month, 4);
      expect(model.fechaEnvio!.day, 11);
      expect(model.estado, QuotationEstado.aprobada);
    });

    test('fromJson parses items list', () {
      final json = <String, dynamic>{
        'id': 'q2',
        'order_id': 'o2',
        'subtotal': 500.0,
        'impuestos': 80.0,
        'shop_supplies': 7.5,
        'descuento': 0.0,
        'total': 587.5,
        'estado': 'RECHAZADA',
        'fecha_envio': null,
        'items': <dynamic>[
          <String, dynamic>{
            'id': 'item-1',
            'quotation_id': 'q2',
            'finding_id': 'f1',
            'part_id': null,
            'descripcion': 'Alineación',
            'mano_obra': 300.0,
            'costo_repuesto': 200.0,
            'precio_final': 500.0,
          },
        ],
      };

      final model = QuotationModel.fromJson(json);

      expect(model.estado, QuotationEstado.rechazada);
      expect(model.items.length, 1);
      expect(model.items.first.descripcion, 'Alineación');
      expect(model.items.first.manoObra, 300.0);
      expect(model.items.first.costoRepuesto, 200.0);
      expect(model.items.first.precioFinal, 500.0);
      expect(model.items.first.partId, isNull);
    });
  });

  // ─── QuotationFindingModel ────────────────────────────────────────────────────

  group('QuotationFindingModel', () {
    test('fromJson parses parts list and flags', () {
      final json = <String, dynamic>{
        'id': 'fid-1',
        'order_id': 'oid-1',
        'technician_id': 'tid-1',
        'motivo_ingreso': 'Ruido al frenar',
        'descripcion': 'Pastillas desgastadas',
        'tiempo_estimado': 60,
        'fotos': <dynamic>[],
        'es_hallazgo_adicional': false,
        'es_critico_seguridad': true,
        'safety_warning': 'Frenos en estado crítico',
        'parts': <dynamic>[
          <String, dynamic>{
            'id': 'pid-1',
            'finding_id': 'fid-1',
            'nombre': 'Pastillas Brembo',
            'origen': 'STOCK',
            'costo': 80.0,
            'margen': 0.25,
            'precio_venta': 100.0,
            'proveedor': 'AutoParts CR',
          },
        ],
      };

      final finding = QuotationFindingModel.fromJson(json);

      expect(finding.id, 'fid-1');
      expect(finding.motivo, 'Ruido al frenar');
      expect(finding.esCriticoSeguridad, isTrue);
      expect(finding.esHallazgoAdicional, isFalse);
      expect(finding.safetyWarning, 'Frenos en estado crítico');
      expect(finding.parts.length, 1);
      expect(finding.parts.first.nombre, 'Pastillas Brembo');
      expect(finding.parts.first.precioVenta, 100.0);
      expect(finding.parts.first.origen, PartOrigenQuotation.stock);
    });
  });
}
