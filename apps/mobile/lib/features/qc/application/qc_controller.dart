import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/qc_repository.dart';
import '../domain/qc_models.dart';
import '../domain/qc_state.dart';

class QcController extends StateNotifier<QcState> {
  QcController({
    required this.orderId,
    required Dio dio,
  })  : _repository = QcRepository(dio),
        super(QcState.initial()) {
    unawaited(init());
  }

  final String orderId;
  final QcRepository _repository;

  /// Parallel fetch of order context, quotation items, and existing QC record.
  Future<void> init() async {
    state = QcState.initial();

    // Launch all requests in parallel.
    final orderFuture = _repository.fetchOrder(orderId);
    final checklistFuture = _repository.fetchChecklist(orderId);
    final quotationFuture = _repository.fetchQuotation(orderId);
    final qcFuture = _repository.fetchQc(orderId);

    Map<String, dynamic>? orderData;
    Map<String, dynamic>? checklistData;
    Map<String, dynamic>? quotationData;
    QcRecord? existingQc;
    String? errorMessage;

    try {
      orderData = await orderFuture;
    } catch (e) {
      errorMessage = e.toString();
    }

    try {
      checklistData = await checklistFuture;
    } catch (_) {
      // Non-critical — proceed without ingress fluid levels.
    }

    try {
      quotationData = await quotationFuture;
    } catch (_) {
      // No quotation = empty checklist.
    }

    try {
      existingQc = await qcFuture;
    } catch (_) {
      // No existing QC is fine.
    }

    if (!mounted) return;

    // Build snapshot from order km + checklist fluid levels.
    final QcReceptionSnapshot? snapshot = orderData == null
        ? null
        : QcReceptionSnapshot(
            kmIngreso: orderData['kilometraje_ingreso'] as int?,
            nivelAceiteIngreso: checklistData?['nivel_aceite'] as String?,
            nivelRefrigeranteIngreso:
                checklistData?['nivel_refrigerante'] as String?,
            nivelFrenosIngreso: checklistData?['nivel_frenos'] as String?,
          );

    // Build checklist from quotation items or from existing QC items_verificados.
    List<QcChecklistItem> checklistItems;
    if (existingQc != null && existingQc.itemsVerificados.isNotEmpty) {
      // Pre-fill from saved QC.
      checklistItems = existingQc.itemsVerificados.entries
          .map(
            (e) => QcChecklistItem(
              id: e.key,
              descripcion: e.key,
              checked: e.value,
            ),
          )
          .toList();
    } else if (quotationData != null) {
      final rawItems =
          (quotationData['items'] as List<dynamic>? ?? []);
      checklistItems = rawItems.map((raw) {
        final item = raw as Map<String, dynamic>;
        final desc = item['descripcion'] as String? ?? '';
        return QcChecklistItem(
          id: item['id'] as String? ?? desc,
          descripcion: desc,
          checked: false,
        );
      }).toList();
    } else {
      checklistItems = const [];
    }

    state = state.copyWith(
      isLoadingOrder: false,
      isLoadingQc: false,
      snapshot: snapshot,
      checklistItems: checklistItems,
      // Pre-fill form from existing QC record if available.
      kilometrajeSalida: existingQc?.kilometrajeSalida,
      nivelAceiteSalida: existingQc?.nivelAceiteSalida,
      nivelRefrigeranteSalida: existingQc?.nivelRefrigeranteSalida,
      nivelFrenosSalida: existingQc?.nivelFrenosSalida,
      savedQc: existingQc,
      errorMessage: errorMessage,
    );
  }

  // ─── Checklist ────────────────────────────────────────────────────────────

  void toggleItem(String itemId) {
    final updated = state.checklistItems.map((item) {
      if (item.id == itemId) return item.copyWith(checked: !item.checked);
      return item;
    }).toList();
    state = state.copyWith(checklistItems: updated);
  }

  // ─── Form fields ──────────────────────────────────────────────────────────

  void setKmSalida(int? value) {
    state = state.copyWith(kilometrajeSalida: value);
  }

  void setNivelAceite(String? value) {
    state = state.copyWith(nivelAceiteSalida: value);
  }

  void setNivelRefrigerante(String? value) {
    state = state.copyWith(nivelRefrigeranteSalida: value);
  }

  void setNivelFrenos(String? value) {
    state = state.copyWith(nivelFrenosSalida: value);
  }

  // ─── Persist ──────────────────────────────────────────────────────────────

  Future<void> saveProgress(String inspectorId) async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, errorMessage: null);

    final itemsVerificados = {
      for (final item in state.checklistItems) item.descripcion: item.checked,
    };

    try {
      final record = await _repository.saveQc(
        orderId,
        inspectorId: inspectorId,
        itemsVerificados: itemsVerificados,
        kilometrajeSalida: state.kilometrajeSalida,
        nivelAceiteSalida: state.nivelAceiteSalida,
        nivelRefrigeranteSalida: state.nivelRefrigeranteSalida,
        nivelFrenosSalida: state.nivelFrenosSalida,
        aprobado: false,
      );
      if (!mounted) return;
      state = state.copyWith(isSaving: false, savedQc: record);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  /// Only for JEFE_TALLER / ADMIN. Advances order to ENTREGA.
  Future<void> approveQc() async {
    // Validation.
    if (!state.allItemsChecked || state.kilometrajeSalida == null) return;
    if (state.isSaving) return;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final record = await _repository.approveQc(orderId);
      if (!mounted) return;
      state = state.copyWith(isSaving: false, savedQc: record);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}
