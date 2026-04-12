import 'billing_models.dart';

class BillingState {
  static const Object _unset = Object();

  const BillingState({
    required this.isLoadingOrder,
    required this.isLoadingInvoice,
    required this.isLoadingNps,
    required this.isSaving,
    this.orderEstado,
    this.quotation,
    this.invoice,
    this.nps,
    required this.selectedMetodoPago,
    required this.esCredito,
    required this.saldoPendiente,
    required this.npsAtencion,
    required this.npsInstalaciones,
    required this.npsTiempos,
    required this.npsPrecios,
    required this.npsRecomendacion,
    this.npsComentarios,
    required this.orderClosed,
    this.errorMessage,
  });

  factory BillingState.initial() => const BillingState(
        isLoadingOrder: true,
        isLoadingInvoice: true,
        isLoadingNps: true,
        isSaving: false,
        selectedMetodoPago: MetodoPago.efectivo,
        esCredito: false,
        saldoPendiente: 0.0,
        npsAtencion: 7,
        npsInstalaciones: 7,
        npsTiempos: 7,
        npsPrecios: 7,
        npsRecomendacion: 8,
        orderClosed: false,
      );

  // Loading flags
  final bool isLoadingOrder;
  final bool isLoadingInvoice;
  final bool isLoadingNps;
  final bool isSaving;

  // Loaded data
  final String? orderEstado;
  final QuotationSummary? quotation;
  final InvoiceModel? invoice;
  final NpsModel? nps;

  // Invoice form
  final MetodoPago selectedMetodoPago;
  final bool esCredito;
  final double saldoPendiente;

  // NPS form
  final int npsAtencion;
  final int npsInstalaciones;
  final int npsTiempos;
  final int npsPrecios;
  final int npsRecomendacion;
  final String? npsComentarios;

  // Order state
  final bool orderClosed;

  // Error
  final String? errorMessage;

  // ─── Computed ────────────────────────────────────────────────────────────

  bool get isLoading => isLoadingOrder || isLoadingInvoice || isLoadingNps;
  bool get canCloseOrder => invoice != null && nps != null && !orderClosed;
  bool get canCreateInvoice => invoice == null && orderEstado == 'ENTREGA';
  bool get canSubmitNps => nps == null;

  // ─── copyWith with sentinel ───────────────────────────────────────────────

  BillingState copyWith({
    bool? isLoadingOrder,
    bool? isLoadingInvoice,
    bool? isLoadingNps,
    bool? isSaving,
    Object? orderEstado = _unset,
    Object? quotation = _unset,
    Object? invoice = _unset,
    Object? nps = _unset,
    MetodoPago? selectedMetodoPago,
    bool? esCredito,
    double? saldoPendiente,
    int? npsAtencion,
    int? npsInstalaciones,
    int? npsTiempos,
    int? npsPrecios,
    int? npsRecomendacion,
    Object? npsComentarios = _unset,
    bool? orderClosed,
    Object? errorMessage = _unset,
  }) {
    return BillingState(
      isLoadingOrder: isLoadingOrder ?? this.isLoadingOrder,
      isLoadingInvoice: isLoadingInvoice ?? this.isLoadingInvoice,
      isLoadingNps: isLoadingNps ?? this.isLoadingNps,
      isSaving: isSaving ?? this.isSaving,
      orderEstado: identical(orderEstado, _unset)
          ? this.orderEstado
          : orderEstado as String?,
      quotation: identical(quotation, _unset)
          ? this.quotation
          : quotation as QuotationSummary?,
      invoice:
          identical(invoice, _unset) ? this.invoice : invoice as InvoiceModel?,
      nps: identical(nps, _unset) ? this.nps : nps as NpsModel?,
      selectedMetodoPago: selectedMetodoPago ?? this.selectedMetodoPago,
      esCredito: esCredito ?? this.esCredito,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      npsAtencion: npsAtencion ?? this.npsAtencion,
      npsInstalaciones: npsInstalaciones ?? this.npsInstalaciones,
      npsTiempos: npsTiempos ?? this.npsTiempos,
      npsPrecios: npsPrecios ?? this.npsPrecios,
      npsRecomendacion: npsRecomendacion ?? this.npsRecomendacion,
      npsComentarios: identical(npsComentarios, _unset)
          ? this.npsComentarios
          : npsComentarios as String?,
      orderClosed: orderClosed ?? this.orderClosed,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
