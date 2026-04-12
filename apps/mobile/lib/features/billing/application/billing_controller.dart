import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/billing_repository.dart';
import '../domain/billing_models.dart';
import '../domain/billing_state.dart';

class BillingController extends StateNotifier<BillingState> {
  BillingController({
    required this.orderId,
    required Dio dio,
  })  : _repository = BillingRepository(dio),
        super(BillingState.initial()) {
    unawaited(init());
  }

  final String orderId;
  final BillingRepository _repository;

  /// Parallel fetch of order, quotation, invoice, and NPS.
  Future<void> init() async {
    state = BillingState.initial();

    // Launch all requests in parallel.
    final orderFuture = _repository.fetchOrder(orderId);
    final quotationFuture = _repository.fetchQuotation(orderId);
    final invoiceFuture = _repository.fetchInvoice(orderId);
    final npsFuture = _repository.fetchNps(orderId);

    Map<String, dynamic>? orderData;
    QuotationSummary? quotation;
    InvoiceModel? invoice;
    NpsModel? nps;
    String? errorMessage;

    try {
      orderData = await orderFuture;
    } catch (e) {
      errorMessage = e.toString();
    }

    try {
      quotation = await quotationFuture;
    } catch (_) {
      // No approved quotation — proceed without.
    }

    try {
      invoice = await invoiceFuture;
    } catch (_) {
      // No invoice yet — expected.
    }

    try {
      nps = await npsFuture;
    } catch (_) {
      // No NPS yet — expected.
    }

    if (!mounted) return;

    final orderEstado = orderData?['estado'] as String?;
    final orderClosed = orderEstado == 'CERRADA';

    state = state.copyWith(
      isLoadingOrder: false,
      isLoadingInvoice: false,
      isLoadingNps: false,
      orderEstado: orderEstado,
      quotation: quotation,
      invoice: invoice,
      nps: nps,
      orderClosed: orderClosed,
      errorMessage: errorMessage,
    );
  }

  // ─── Invoice form ─────────────────────────────────────────────────────────

  void setMetodoPago(MetodoPago m) {
    final isCredito = m == MetodoPago.credito;
    state = state.copyWith(
      selectedMetodoPago: m,
      esCredito: isCredito,
      saldoPendiente: isCredito ? state.saldoPendiente : 0.0,
    );
  }

  void setEsCredito(bool v) => state = state.copyWith(esCredito: v);

  void setSaldoPendiente(double v) => state = state.copyWith(saldoPendiente: v);

  // ─── NPS form ─────────────────────────────────────────────────────────────

  void setNpsScore(String category, int value) {
    switch (category) {
      case 'atencion':
        state = state.copyWith(npsAtencion: value);
      case 'instalaciones':
        state = state.copyWith(npsInstalaciones: value);
      case 'tiempos':
        state = state.copyWith(npsTiempos: value);
      case 'precios':
        state = state.copyWith(npsPrecios: value);
      case 'recomendacion':
        state = state.copyWith(npsRecomendacion: value);
    }
  }

  void setNpsComentarios(String? text) => state = state.copyWith(
      npsComentarios: (text == null || text.isEmpty) ? null : text);

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> createInvoice() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final invoice = await _repository.createInvoice(
        orderId,
        metodoPago: state.selectedMetodoPago,
        esCredito: state.esCredito,
        saldoPendiente: state.saldoPendiente,
      );
      if (!mounted) return;
      state = state.copyWith(isSaving: false, invoice: invoice);
    } on BillingException catch (e) {
      if (!mounted) return;
      // 409: invoice already exists — reload silently.
      if (e.message == 'La factura ya fue generada') {
        try {
          final existing = await _repository.fetchInvoice(orderId);
          if (!mounted) return;
          state = state.copyWith(isSaving: false, invoice: existing);
        } catch (_) {
          if (!mounted) return;
          state = state.copyWith(isSaving: false);
        }
      } else {
        state = state.copyWith(isSaving: false, errorMessage: e.message);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> submitNps() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final nps = await _repository.createNps(
        orderId,
        atencion: state.npsAtencion,
        instalaciones: state.npsInstalaciones,
        tiempos: state.npsTiempos,
        precios: state.npsPrecios,
        recomendacion: state.npsRecomendacion,
        comentarios: state.npsComentarios,
      );
      if (!mounted) return;
      state = state.copyWith(isSaving: false, nps: nps);
    } on BillingException catch (e) {
      if (!mounted) return;
      // 409: NPS already exists — reload silently.
      if (e.message == 'La encuesta NPS ya fue enviada') {
        try {
          final existing = await _repository.fetchNps(orderId);
          if (!mounted) return;
          state = state.copyWith(isSaving: false, nps: existing);
        } catch (_) {
          if (!mounted) return;
          state = state.copyWith(isSaving: false);
        }
      } else {
        state = state.copyWith(isSaving: false, errorMessage: e.message);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> closeOrder() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _repository.closeOrder(orderId);
      if (!mounted) return;
      state = state.copyWith(isSaving: false, orderClosed: true);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }
}
