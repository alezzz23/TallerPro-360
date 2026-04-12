import 'package:flutter_test/flutter_test.dart';
import 'package:tallerpro360_mobile/features/reception/domain/reception_models.dart';
import 'package:tallerpro360_mobile/features/reception/domain/reception_state.dart';
import 'package:tallerpro360_mobile/features/reception/domain/reception_validator.dart';

void main() {
  test('advance validation reports missing media and signature', () {
    final state = ReceptionState.initial(
      canManageReception: true,
      advisorId: 'advisor-1',
    ).copyWith(
      customer: const ReceptionCustomerDraft(nombre: 'Carlos Perez'),
      vehicle: const ReceptionVehicleDraft(
        marca: 'Mazda',
        modelo: '3',
        placa: 'ABC123',
        kilometraje: 80214,
      ),
      motivoVisita: 'Vibracion al frenar.',
      checklist: const ReceptionChecklistDraft(
        nivelAceite: ReceptionFluidLevel.correcto,
        nivelRefrigerante: ReceptionFluidLevel.bajo,
        nivelFrenos: ReceptionFluidLevel.critico,
        documentosRecibidos: 'Tarjeta de propiedad',
      ),
      perimeterPhotos: {
        ReceptionPerimeterAngle.frontal: const ReceptionPerimeterPhotoDraft(
          angle: ReceptionPerimeterAngle.frontal,
          remoteUrl: 'https://example.com/frontal.jpg',
        ),
      },
    );

    final issues = ReceptionValidator.advanceIssues(
      state,
      hasPendingSignature: false,
    );

    expect(
      issues.any((item) => item.startsWith('fotos de perimetro')),
      isTrue,
    );
    expect(issues, contains('firma del cliente'));
  });

  test('advance validation passes when reception is complete', () {
    final state = ReceptionState.initial(
      canManageReception: true,
      advisorId: 'advisor-1',
    ).copyWith(
      customer: const ReceptionCustomerDraft(nombre: 'Laura Diaz'),
      vehicle: const ReceptionVehicleDraft(
        marca: 'Toyota',
        modelo: 'Corolla',
        placa: 'XYZ987',
        kilometraje: 45612,
      ),
      motivoVisita: 'Mantenimiento preventivo con ruido trasero.',
      checklist: const ReceptionChecklistDraft(
        nivelAceite: ReceptionFluidLevel.correcto,
        nivelRefrigerante: ReceptionFluidLevel.correcto,
        nivelFrenos: ReceptionFluidLevel.correcto,
        llantaRepuesto: true,
        kitCarretera: true,
        botiquin: true,
        extintor: true,
        documentosRecibidos: 'Tarjeta de propiedad, SOAT',
      ),
      perimeterPhotos: {
        for (final angle in ReceptionPerimeterAngle.values)
          angle: ReceptionPerimeterPhotoDraft(
            angle: angle,
            remoteUrl: 'https://example.com/${angle.apiValue.toLowerCase()}.jpg',
          ),
      },
      signatureUrl: 'https://example.com/signature.png',
    );

    final issues = ReceptionValidator.advanceIssues(
      state,
      hasPendingSignature: false,
    );

    expect(issues, isEmpty);
  });
}