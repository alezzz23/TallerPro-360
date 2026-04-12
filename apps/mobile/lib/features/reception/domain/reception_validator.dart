import 'reception_models.dart';
import 'reception_state.dart';

class ReceptionValidator {
  ReceptionValidator._();

  static List<String> draftIssues(ReceptionState state) {
    final issues = <String>[];

    if (state.advisorId == null || state.advisorId!.isEmpty) {
      issues.add('sesion del asesor');
    }
    if (state.customer.nombre.trim().isEmpty) {
      issues.add('nombre del cliente');
    }
    if (state.vehicle.marca.trim().isEmpty) {
      issues.add('marca');
    }
    if (state.vehicle.modelo.trim().isEmpty) {
      issues.add('modelo');
    }
    if (state.vehicle.placa.trim().isEmpty) {
      issues.add('placa');
    }
    if (state.vehicle.kilometraje == null || state.vehicle.kilometraje! <= 0) {
      issues.add('kilometraje de ingreso');
    }
    if (state.motivoVisita.trim().isEmpty) {
      issues.add('motivo de visita');
    }

    return issues;
  }

  static List<String> advanceIssues(
    ReceptionState state, {
    required bool hasPendingSignature,
  }) {
    final issues = draftIssues(state);

    if (state.checklist.nivelAceite == null) {
      issues.add('nivel de aceite');
    }
    if (state.checklist.nivelRefrigerante == null) {
      issues.add('nivel de refrigerante');
    }
    if (state.checklist.nivelFrenos == null) {
      issues.add('nivel de frenos');
    }
    if (state.checklist.documentosRecibidos.trim().isEmpty) {
      issues.add('documentos recibidos');
    }

    final missingAngles = ReceptionPerimeterAngle.values
      .where((angle) => !state.photoFor(angle).hasImage)
      .map((angle) => angle.label.toLowerCase())
        .toList(growable: false);
    if (missingAngles.isNotEmpty) {
      issues.add('fotos de perimetro (${missingAngles.join(', ')})');
    }

    if (!state.hasStoredSignature && !hasPendingSignature) {
      issues.add('firma del cliente');
    }

    return issues;
  }
}