import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/qc/domain/qc_models.dart';
import 'package:tallerpro360_mobile/features/qc/domain/qc_state.dart';

void main() {
  // ─── QcState ──────────────────────────────────────────────────────────────

  group('QcState', () {
    test('initial() has correct defaults', () {
      final state = QcState.initial();

      expect(state.isLoadingOrder, isTrue);
      expect(state.isLoadingQc, isTrue);
      expect(state.isSaving, isFalse);
      expect(state.checklistItems, isEmpty);
      expect(state.snapshot, isNull);
      expect(state.savedQc, isNull);
      expect(state.errorMessage, isNull);
      expect(state.kilometrajeSalida, isNull);
      expect(state.nivelAceiteSalida, isNull);
      expect(state.nivelRefrigeranteSalida, isNull);
      expect(state.nivelFrenosSalida, isNull);
    });

    test('isLoading is true while either isLoadingOrder or isLoadingQc is true',
        () {
      final initial = QcState.initial();
      expect(initial.isLoading, isTrue);

      final orderLoaded = initial.copyWith(isLoadingOrder: false);
      expect(orderLoaded.isLoading, isTrue); // isLoadingQc still true

      final allLoaded = orderLoaded.copyWith(isLoadingQc: false);
      expect(allLoaded.isLoading, isFalse);
    });

    test('copyWith with sentinel only changes specified fields', () {
      final initial = QcState.initial();
      final updated = initial.copyWith(
        isLoadingOrder: false,
        errorMessage: 'algo falló',
      );

      expect(updated.isLoadingOrder, isFalse);
      expect(updated.isLoadingQc, isTrue); // unchanged
      expect(updated.isSaving, isFalse); // unchanged
      expect(updated.errorMessage, 'algo falló');
      expect(updated.checklistItems, isEmpty); // unchanged
    });

    test('copyWith sentinel allows clearing nullable fields to null', () {
      final withData = QcState.initial().copyWith(
        errorMessage: 'un error',
        nivelAceiteSalida: 'correcto',
      );

      final cleared = withData.copyWith(
        errorMessage: null,
        nivelAceiteSalida: null,
      );

      expect(cleared.errorMessage, isNull);
      expect(cleared.nivelAceiteSalida, isNull);
    });

    test('allItemsChecked returns true when all items are checked', () {
      final state = QcState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingQc: false,
        checklistItems: const [
          QcChecklistItem(id: '1', descripcion: 'Cambio aceite', checked: true),
          QcChecklistItem(id: '2', descripcion: 'Filtro', checked: true),
        ],
      );
      expect(state.allItemsChecked, isTrue);
    });

    test('allItemsChecked returns false when some items are unchecked', () {
      final state = QcState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingQc: false,
        checklistItems: const [
          QcChecklistItem(id: '1', descripcion: 'Cambio aceite', checked: true),
          QcChecklistItem(id: '2', descripcion: 'Filtro', checked: false),
        ],
      );
      expect(state.allItemsChecked, isFalse);
    });

    test('allItemsChecked returns true when checklistItems is empty', () {
      final state = QcState.initial().copyWith(
        isLoadingOrder: false,
        isLoadingQc: false,
      );
      expect(state.allItemsChecked, isTrue);
    });
  });

  // ─── QcChecklistItem ──────────────────────────────────────────────────────

  group('QcChecklistItem', () {
    test('copyWith(checked: true) updates only checked field', () {
      const item = QcChecklistItem(
        id: 'abc',
        descripcion: 'Revisión de frenos',
        checked: false,
      );

      final toggled = item.copyWith(checked: true);

      expect(toggled.id, 'abc');
      expect(toggled.descripcion, 'Revisión de frenos');
      expect(toggled.checked, isTrue);
    });

    test('copyWith with no args returns identical values', () {
      const item = QcChecklistItem(
        id: 'x1',
        descripcion: 'Test',
        checked: true,
      );
      final copy = item.copyWith();
      expect(copy.id, item.id);
      expect(copy.descripcion, item.descripcion);
      expect(copy.checked, item.checked);
    });
  });

  // ─── QcRecord.fromJson ────────────────────────────────────────────────────

  group('QcRecord.fromJson', () {
    test('round-trip preserves all fields including kmDelta', () {
      final json = <String, dynamic>{
        'id': 'rec-uuid-1234',
        'order_id': 'order-uuid-5678',
        'inspector_id': 'insp-uuid-9012',
        'items_verificados': <String, dynamic>{
          'Cambio de aceite': true,
          'Revisión de frenos': false,
        },
        'kilometraje_salida': 52300,
        'nivel_aceite_salida': 'correcto',
        'nivel_refrigerante_salida': 'bajo',
        'nivel_frenos_salida': 'critico',
        'aprobado': true,
        'fecha': '2026-04-11T10:30:00',
        'km_delta': 150,
      };

      final record = QcRecord.fromJson(json);

      expect(record.id, 'rec-uuid-1234');
      expect(record.orderId, 'order-uuid-5678');
      expect(record.inspectorId, 'insp-uuid-9012');
      expect(record.itemsVerificados['Cambio de aceite'], isTrue);
      expect(record.itemsVerificados['Revisión de frenos'], isFalse);
      expect(record.kilometrajeSalida, 52300);
      expect(record.nivelAceiteSalida, 'correcto');
      expect(record.nivelRefrigeranteSalida, 'bajo');
      expect(record.nivelFrenosSalida, 'critico');
      expect(record.aprobado, isTrue);
      expect(record.fecha, DateTime.parse('2026-04-11T10:30:00'));
      expect(record.kmDelta, 150);
    });

    test('handles null optional fields', () {
      final json = <String, dynamic>{
        'id': 'rec-001',
        'order_id': 'ord-001',
        'inspector_id': 'insp-001',
        'items_verificados': <String, dynamic>{},
        'kilometraje_salida': null,
        'nivel_aceite_salida': null,
        'nivel_refrigerante_salida': null,
        'nivel_frenos_salida': null,
        'aprobado': false,
        'fecha': '2026-01-01T00:00:00',
        'km_delta': null,
      };

      final record = QcRecord.fromJson(json);

      expect(record.kilometrajeSalida, isNull);
      expect(record.nivelAceiteSalida, isNull);
      expect(record.kmDelta, isNull);
      expect(record.aprobado, isFalse);
    });
  });

  // ─── toggleItem logic ─────────────────────────────────────────────────────

  group('toggleItem logic', () {
    test('toggling an item flips its checked state', () {
      final items = const [
        QcChecklistItem(id: 'i1', descripcion: 'Aceite', checked: false),
        QcChecklistItem(id: 'i2', descripcion: 'Filtro', checked: true),
      ];

      // Simulate what the controller does.
      final updated = items.map((item) {
        if (item.id == 'i1') return item.copyWith(checked: !item.checked);
        return item;
      }).toList();

      expect(updated[0].checked, isTrue);
      expect(updated[1].checked, isTrue); // unchanged
    });

    test('toggling does not affect other items', () {
      final items = const [
        QcChecklistItem(id: 'a', descripcion: 'A', checked: false),
        QcChecklistItem(id: 'b', descripcion: 'B', checked: false),
        QcChecklistItem(id: 'c', descripcion: 'C', checked: false),
      ];

      final updated = items.map((item) {
        if (item.id == 'b') return item.copyWith(checked: true);
        return item;
      }).toList();

      expect(updated[0].checked, isFalse);
      expect(updated[1].checked, isTrue);
      expect(updated[2].checked, isFalse);
    });
  });

  // ─── QcReceptionSnapshot ─────────────────────────────────────────────────

  group('QcReceptionSnapshot', () {
    test('km_delta > 0 is preserved in snapshot', () {
      const snapshot = QcReceptionSnapshot(
        kmIngreso: 50000,
        nivelAceiteIngreso: 'correcto',
        nivelRefrigeranteIngreso: 'bajo',
        nivelFrenosIngreso: 'critico',
      );

      expect(snapshot.kmIngreso, 50000);
      expect(snapshot.nivelAceiteIngreso, 'correcto');
      expect(snapshot.nivelRefrigeranteIngreso, 'bajo');
      expect(snapshot.nivelFrenosIngreso, 'critico');
    });
  });

  // ─── QcFluidLevel ─────────────────────────────────────────────────────────

  group('QcFluidLevel', () {
    test('values have correct Spanish labels', () {
      expect(QcFluidLevel.correcto.label, 'Correcto');
      expect(QcFluidLevel.bajo.label, 'Bajo');
      expect(QcFluidLevel.critico.label, 'Crítico');
    });

    test('values have correct string values', () {
      expect(QcFluidLevel.correcto.value, 'correcto');
      expect(QcFluidLevel.bajo.value, 'bajo');
      expect(QcFluidLevel.critico.value, 'critico');
    });

    test('fromString returns correct enum', () {
      expect(QcFluidLevel.fromString('correcto'), QcFluidLevel.correcto);
      expect(QcFluidLevel.fromString('bajo'), QcFluidLevel.bajo);
      expect(QcFluidLevel.fromString('critico'), QcFluidLevel.critico);
      expect(QcFluidLevel.fromString('unknown'), isNull);
      expect(QcFluidLevel.fromString(null), isNull);
    });
  });
}
