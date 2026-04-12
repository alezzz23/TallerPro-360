import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/diagnosis/domain/diagnosis_models.dart';
import 'package:tallerpro360_mobile/features/diagnosis/domain/diagnosis_state.dart';

void main() {
  group('DiagnosisState.copyWith', () {
    test('preserves all fields when no overrides given', () {
      final original = DiagnosisState(
        findings: AsyncValue.data([
          DiagnosisFinding(
            id: 'f1',
            orderId: 'o1',
            technicianId: 't1',
            motivoIngreso: 'Ruido al frenar',
            fotos: const [],
            esHallazgoAdicional: false,
            esCriticoSeguridad: false,
            parts: const [],
          ),
        ]),
        isSaving: true,
        errorMessage: 'some error',
        expandedCards: const {'f1': true},
        technicians: const [DiagnosisTechnician(id: 't1', nombre: 'Carlos')],
        techniciansLoaded: true,
        isLoadingTechnicians: false,
        uploadingPhotoForFindingId: 'f1',
      );

      final copy = original.copyWith();

      expect(copy.isSaving, original.isSaving);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.expandedCards, original.expandedCards);
      expect(copy.technicians, original.technicians);
      expect(copy.techniciansLoaded, original.techniciansLoaded);
      expect(copy.uploadingPhotoForFindingId,
          original.uploadingPhotoForFindingId);
    });

    test('overrides errorMessage to null using sentinel', () {
      final original = DiagnosisState(
        findings: const AsyncValue.loading(),
        isSaving: false,
        errorMessage: 'error original',
        expandedCards: const {},
        technicians: const [],
        techniciansLoaded: false,
        isLoadingTechnicians: false,
        uploadingPhotoForFindingId: null,
      );

      final copy = original.copyWith(errorMessage: null);

      expect(copy.errorMessage, isNull);
    });

    test('overrides isSaving independently', () {
      final original = DiagnosisState.initial();
      final copy = original.copyWith(isSaving: true);

      expect(copy.isSaving, isTrue);
      expect(copy.errorMessage, isNull);
    });

    test('overrides uploadingPhotoForFindingId to null using sentinel', () {
      final original = DiagnosisState(
        findings: const AsyncValue.loading(),
        isSaving: false,
        errorMessage: null,
        expandedCards: const {},
        technicians: const [],
        techniciansLoaded: false,
        isLoadingTechnicians: false,
        uploadingPhotoForFindingId: 'finding-abc',
      );

      final cleared = original.copyWith(uploadingPhotoForFindingId: null);

      expect(cleared.uploadingPhotoForFindingId, isNull);
    });

    test('expandedCards toggle is independent per finding', () {
      final original = DiagnosisState.initial();
      final updated = original.copyWith(
        expandedCards: {'f1': true, 'f2': false},
      );

      expect(updated.expandedCards['f1'], isTrue);
      expect(updated.expandedCards['f2'], isFalse);
      expect(updated.expandedCards['f3'], isNull);
    });
  });

  group('DiagnosisPart.computePrecioVenta', () {
    test('calculates precio_venta correctly with 30% margin', () {
      // costo=100, margen=0.30 → 100 / 0.70 ≈ 142.857
      final result = DiagnosisPart.computePrecioVenta(100.0, 0.30);
      expect(result, closeTo(142.857, 0.001));
    });

    test('calculates precio_venta with 0% margin equals costo', () {
      final result = DiagnosisPart.computePrecioVenta(200.0, 0.0);
      expect(result, closeTo(200.0, 0.001));
    });

    test('calculates precio_venta with 50% margin', () {
      // costo=100, margen=0.50 → 100 / 0.50 = 200
      final result = DiagnosisPart.computePrecioVenta(100.0, 0.50);
      expect(result, closeTo(200.0, 0.001));
    });

    test('returns 0 when margin >= 100% to avoid division by zero', () {
      final result = DiagnosisPart.computePrecioVenta(100.0, 1.0);
      expect(result, equals(0.0));
    });

    test('calculates with decimal costo', () {
      // costo=49.99, margen=0.25 → 49.99 / 0.75 ≈ 66.653
      final result = DiagnosisPart.computePrecioVenta(49.99, 0.25);
      expect(result, closeTo(66.653, 0.001));
    });
  });

  group('DiagnosisFinding.fromJson', () {
    test('parses correctly from full JSON', () {
      final json = {
        'id': 'f1',
        'order_id': 'o1',
        'technician_id': 't1',
        'motivo_ingreso': 'Test motivo',
        'descripcion': 'Test desc',
        'tiempo_estimado': 2.5,
        'fotos': ['http://example.com/1.jpg', 'http://example.com/2.jpg'],
        'es_hallazgo_adicional': true,
        'es_critico_seguridad': false,
        'parts': [],
        'safety_warning': null,
      };

      final finding = DiagnosisFinding.fromJson(json);

      expect(finding.id, 'f1');
      expect(finding.orderId, 'o1');
      expect(finding.technicianId, 't1');
      expect(finding.motivoIngreso, 'Test motivo');
      expect(finding.descripcion, 'Test desc');
      expect(finding.tiempoEstimado, 2.5);
      expect(finding.fotos, hasLength(2));
      expect(finding.esHallazgoAdicional, isTrue);
      expect(finding.esCriticoSeguridad, isFalse);
      expect(finding.parts, isEmpty);
      expect(finding.safetyWarning, isNull);
    });

    test('handles null optional fields gracefully', () {
      final json = {
        'id': 'f2',
        'order_id': 'o2',
        'technician_id': 't2',
        'motivo_ingreso': 'Sin descripción',
        'descripcion': null,
        'tiempo_estimado': null,
        'fotos': null,
        'es_hallazgo_adicional': null,
        'es_critico_seguridad': null,
        'parts': null,
        'safety_warning': null,
      };

      final finding = DiagnosisFinding.fromJson(json);

      expect(finding.descripcion, isNull);
      expect(finding.tiempoEstimado, isNull);
      expect(finding.fotos, isEmpty);
      expect(finding.esHallazgoAdicional, isFalse);
      expect(finding.esCriticoSeguridad, isFalse);
      expect(finding.parts, isEmpty);
    });
  });
}
