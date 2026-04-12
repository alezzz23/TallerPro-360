import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quotation_repository.dart';
import '../domain/quotation_models.dart';
import '../domain/quotation_state.dart';

class QuotationController extends StateNotifier<QuotationState> {
  QuotationController({
    required this.orderId,
    required QuotationRepository repository,
  })  : _repository = repository,
        super(QuotationState.initial()) {
    unawaited(_loadData());
  }

  final String orderId;
  final QuotationRepository _repository;

  /// Reload findings and quotation in parallel.
  Future<void> _loadData() async {
    state = QuotationState.initial();

    // Start both requests concurrently.
    final findingsFuture = _repository.fetchFindings(orderId);
    final quotationFuture = _repository.fetchQuotation(orderId);

    List<QuotationFindingModel> findings = [];
    QuotationModel? quotation;
    String? errorMessage;

    try {
      findings = await findingsFuture;
    } catch (e) {
      errorMessage = e.toString();
    }

    try {
      quotation = await quotationFuture;
    } catch (e) {
      errorMessage ??= e.toString();
    }

    final lineItems = quotation == null
        ? _buildInitialLineItems(findings)
        : <String, QuotationLineItem>{};

    if (!mounted) return;
    state = state.copyWith(
      isLoadingFindings: false,
      isLoadingQuotation: false,
      findings: findings,
      quotation: quotation,
      lineItems: lineItems,
      errorMessage: errorMessage,
    );
  }

  Future<void> reload() => _loadData();

  Map<String, QuotationLineItem> _buildInitialLineItems(
    List<QuotationFindingModel> findings,
  ) {
    final map = <String, QuotationLineItem>{};
    for (final finding in findings) {
      final firstPart =
          finding.parts.isNotEmpty ? finding.parts.first : null;
      map[finding.id] = QuotationLineItem(
        findingId: finding.id,
        descripcion: finding.descripcion,
        manoObra: 0.0,
        costoRepuesto: firstPart?.precioVenta ?? 0.0,
        partId: firstPart?.id,
      );
    }
    return map;
  }

  // ─── Builder mutations ────────────────────────────────────────────────────

  void updateLineItemLabor(String findingId, double manoObra) {
    final current = Map<String, QuotationLineItem>.from(state.lineItems);
    final item = current[findingId];
    if (item == null) return;
    current[findingId] = item.copyWith(manoObra: manoObra);
    state = state.copyWith(lineItems: current);
  }

  void updateLineItemPart(
      String findingId, String? partId, double costoRepuesto) {
    final current = Map<String, QuotationLineItem>.from(state.lineItems);
    final item = current[findingId];
    if (item == null) return;
    current[findingId] =
        item.copyWith(partId: partId, costoRepuesto: costoRepuesto);
    state = state.copyWith(lineItems: current);
  }

  void updateDescuento(double amount) {
    state = state.copyWith(descuento: amount);
  }

  // ─── API actions ──────────────────────────────────────────────────────────

  Future<void> generateQuotation() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final request = QuotationCreateRequest(
        items: state.lineItems.values.toList(),
        impuestosPct: state.impuestosPct,
        shopSuppliesPct: state.shopSuppliesPct,
        descuento: state.descuento,
      );
      final quotation =
          await _repository.createQuotation(orderId, request);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        quotation: quotation,
        lineItems: <String, QuotationLineItem>{},
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> sendQuotation() async {
    final quotationId = state.quotation?.id;
    if (quotationId == null) return;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated = await _repository.sendQuotation(quotationId);
      if (!mounted) return;
      state = state.copyWith(isSaving: false, quotation: updated);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> applyDiscountAndResend(double descuento,
      {String? razon}) async {
    final quotationId = state.quotation?.id;
    if (quotationId == null) return;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated = await _repository.applyDiscount(
        quotationId,
        descuento,
        razon: razon,
      );
      final sent = await _repository.sendQuotation(updated.id);
      if (!mounted) return;
      state = state.copyWith(isSaving: false, quotation: sent);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> approveQuotation() async {
    final quotationId = state.quotation?.id;
    if (quotationId == null) return;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated = await _repository.approveQuotation(quotationId);
      if (!mounted) return;
      state = state.copyWith(isSaving: false, quotation: updated);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> rejectQuotation({String? razon}) async {
    final quotationId = state.quotation?.id;
    if (quotationId == null) return;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final result =
          await _repository.rejectQuotation(quotationId, razon: razon);
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        quotation: result.quotation,
        safetyLog: result.safetyLog,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}
