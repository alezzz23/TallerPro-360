import 'quotation_models.dart';

class QuotationState {
  static const Object _unset = Object();

  const QuotationState({
    required this.isLoadingFindings,
    required this.isLoadingQuotation,
    required this.isSaving,
    required this.findings,
    required this.lineItems,
    required this.descuento,
    required this.impuestosPct,
    required this.shopSuppliesPct,
    this.quotation,
    this.errorMessage,
    this.safetyLog,
  });

  factory QuotationState.initial() => const QuotationState(
        isLoadingFindings: true,
        isLoadingQuotation: true,
        isSaving: false,
        findings: <QuotationFindingModel>[],
        lineItems: <String, QuotationLineItem>{},
        descuento: 0.0,
        impuestosPct: 0.16,
        shopSuppliesPct: 0.015,
      );

  final bool isLoadingFindings;
  final bool isLoadingQuotation;
  final bool isSaving;
  final List<QuotationFindingModel> findings;
  final QuotationModel? quotation;
  final Map<String, QuotationLineItem> lineItems;
  final double descuento;
  final double impuestosPct;
  final double shopSuppliesPct;
  final String? errorMessage;
  final String? safetyLog;

  bool get isLoading => isLoadingFindings || isLoadingQuotation;

  // ─── Live preview (used when building a quotation) ────────────────────────

  double get previewSubtotal =>
      lineItems.values.fold(0.0, (sum, item) => sum + item.costoTotal);

  double get previewShopSupplies => previewSubtotal * shopSuppliesPct;

  double get previewImpuestos =>
      (previewSubtotal + previewShopSupplies - descuento) * impuestosPct;

  double get previewTotal =>
      previewSubtotal + previewShopSupplies + previewImpuestos - descuento;

  QuotationState copyWith({
    bool? isLoadingFindings,
    bool? isLoadingQuotation,
    bool? isSaving,
    List<QuotationFindingModel>? findings,
    Object? quotation = _unset,
    Map<String, QuotationLineItem>? lineItems,
    double? descuento,
    double? impuestosPct,
    double? shopSuppliesPct,
    Object? errorMessage = _unset,
    Object? safetyLog = _unset,
  }) {
    return QuotationState(
      isLoadingFindings: isLoadingFindings ?? this.isLoadingFindings,
      isLoadingQuotation: isLoadingQuotation ?? this.isLoadingQuotation,
      isSaving: isSaving ?? this.isSaving,
      findings: findings ?? this.findings,
      quotation: identical(quotation, _unset)
          ? this.quotation
          : quotation as QuotationModel?,
      lineItems: lineItems ?? this.lineItems,
      descuento: descuento ?? this.descuento,
      impuestosPct: impuestosPct ?? this.impuestosPct,
      shopSuppliesPct: shopSuppliesPct ?? this.shopSuppliesPct,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      safetyLog: identical(safetyLog, _unset)
          ? this.safetyLog
          : safetyLog as String?,
    );
  }
}
