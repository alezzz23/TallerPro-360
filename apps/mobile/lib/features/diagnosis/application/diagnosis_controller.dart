import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/diagnosis_repository.dart';
import '../domain/diagnosis_models.dart';
import '../domain/diagnosis_state.dart';

class DiagnosisController extends StateNotifier<DiagnosisState> {
  DiagnosisController({
    required DiagnosisRepository repository,
    required this.orderId,
    required this.currentUserId,
  })  : _repository = repository,
        super(DiagnosisState.initial()) {
    unawaited(_loadFindings());
  }

  final DiagnosisRepository _repository;
  final String orderId;
  final String? currentUserId;

  Future<void> _loadFindings() async {
    state = state.copyWith(findings: const AsyncValue.loading());
    try {
      final findings = await _repository.getFindings(orderId);
      state = state.copyWith(findings: AsyncValue.data(findings));
    } catch (e, st) {
      state = state.copyWith(findings: AsyncValue.error(e, st));
    }
  }

  Future<void> reload() => _loadFindings();

  void toggleExpanded(String findingId) {
    final current = Map<String, bool>.from(state.expandedCards);
    current[findingId] = !(current[findingId] ?? false);
    state = state.copyWith(expandedCards: current);
  }

  Future<void> loadTechnicians() async {
    if (state.techniciansLoaded || state.isLoadingTechnicians) return;
    state = state.copyWith(isLoadingTechnicians: true);
    try {
      final technicians = await _repository.getTechnicians();
      state = state.copyWith(
        technicians: technicians,
        techniciansLoaded: true,
        isLoadingTechnicians: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTechnicians: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createFinding({
    required String motivoIngreso,
    String? descripcion,
    double? tiempoEstimado,
    bool esHallazgoAdicional = false,
    bool esCriticoSeguridad = false,
  }) async {
    final techId = currentUserId;
    if (techId == null) {
      state = state.copyWith(
          errorMessage: 'No se pudo determinar el técnico actual.');
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final finding = await _repository.createFinding(
        orderId,
        technicianId: techId,
        motivoIngreso: motivoIngreso,
        descripcion: descripcion,
        tiempoEstimado: tiempoEstimado,
        esHallazgoAdicional: esHallazgoAdicional,
        esCriticoSeguridad: esCriticoSeguridad,
      );
      final current = state.findings.valueOrNull ?? <DiagnosisFinding>[];
      state = state.copyWith(
        isSaving: false,
        findings: AsyncValue.data([...current, finding]),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateFinding(
    String findingId, {
    String? descripcion,
    double? tiempoEstimado,
    bool? esCriticoSeguridad,
    String? technicianId,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated = await _repository.updateFinding(
        findingId,
        descripcion: descripcion,
        tiempoEstimado: tiempoEstimado,
        esCriticoSeguridad: esCriticoSeguridad,
        technicianId: technicianId,
      );
      _replaceFinding(updated);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addPart(
    String findingId, {
    required String nombre,
    required String origen,
    required double costo,
    required double margen,
    String? proveedor,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final part = await _repository.addPart(
        findingId,
        nombre: nombre,
        origen: origen,
        costo: costo,
        margen: margen,
        proveedor: proveedor,
      );
      final current = state.findings.valueOrNull ?? <DiagnosisFinding>[];
      final idx = current.indexWhere((f) => f.id == findingId);
      if (idx != -1) {
        final updated =
            current[idx].copyWith(parts: [...current[idx].parts, part]);
        final newList = List<DiagnosisFinding>.from(current)..[idx] = updated;
        state = state.copyWith(
            isSaving: false, findings: AsyncValue.data(newList));
      } else {
        state = state.copyWith(isSaving: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadAndAddPhoto(String findingId, File imageFile) async {
    state =
        state.copyWith(uploadingPhotoForFindingId: findingId, errorMessage: null);
    try {
      final url = await _repository.uploadPhoto(imageFile);
      final updated = await _repository.addPhoto(findingId, url);
      _replaceFinding(updated);
      state = state.copyWith(uploadingPhotoForFindingId: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        uploadingPhotoForFindingId: null,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  void _replaceFinding(DiagnosisFinding updated) {
    final current = state.findings.valueOrNull ?? <DiagnosisFinding>[];
    final idx = current.indexWhere((f) => f.id == updated.id);
    if (idx == -1) return;
    final newList = List<DiagnosisFinding>.from(current)..[idx] = updated;
    state = state.copyWith(findings: AsyncValue.data(newList));
  }
}
