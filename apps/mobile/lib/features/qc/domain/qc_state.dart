import 'qc_models.dart';

class QcState {
  static const Object _unset = Object();

  const QcState({
    required this.isLoadingOrder,
    required this.isLoadingQc,
    required this.isSaving,
    required this.checklistItems,
    this.snapshot,
    this.kilometrajeSalida,
    this.nivelAceiteSalida,
    this.nivelRefrigeranteSalida,
    this.nivelFrenosSalida,
    this.savedQc,
    this.errorMessage,
  });

  factory QcState.initial() => const QcState(
        isLoadingOrder: true,
        isLoadingQc: true,
        isSaving: false,
        checklistItems: <QcChecklistItem>[],
      );

  final bool isLoadingOrder;
  final bool isLoadingQc;
  final bool isSaving;

  final QcReceptionSnapshot? snapshot;

  final List<QcChecklistItem> checklistItems;

  final int? kilometrajeSalida;
  final String? nivelAceiteSalida;
  final String? nivelRefrigeranteSalida;
  final String? nivelFrenosSalida;

  final QcRecord? savedQc;

  final String? errorMessage;

  // ─── Computed ────────────────────────────────────────────────────────────

  bool get isLoading => isLoadingOrder || isLoadingQc;

  bool get allItemsChecked =>
      checklistItems.isEmpty || checklistItems.every((item) => item.checked);

  // ─── copyWith with sentinel ───────────────────────────────────────────────

  QcState copyWith({
    bool? isLoadingOrder,
    bool? isLoadingQc,
    bool? isSaving,
    List<QcChecklistItem>? checklistItems,
    Object? snapshot = _unset,
    Object? kilometrajeSalida = _unset,
    Object? nivelAceiteSalida = _unset,
    Object? nivelRefrigeranteSalida = _unset,
    Object? nivelFrenosSalida = _unset,
    Object? savedQc = _unset,
    Object? errorMessage = _unset,
  }) {
    return QcState(
      isLoadingOrder: isLoadingOrder ?? this.isLoadingOrder,
      isLoadingQc: isLoadingQc ?? this.isLoadingQc,
      isSaving: isSaving ?? this.isSaving,
      checklistItems: checklistItems ?? this.checklistItems,
      snapshot: identical(snapshot, _unset)
          ? this.snapshot
          : snapshot as QcReceptionSnapshot?,
      kilometrajeSalida: identical(kilometrajeSalida, _unset)
          ? this.kilometrajeSalida
          : kilometrajeSalida as int?,
      nivelAceiteSalida: identical(nivelAceiteSalida, _unset)
          ? this.nivelAceiteSalida
          : nivelAceiteSalida as String?,
      nivelRefrigeranteSalida: identical(nivelRefrigeranteSalida, _unset)
          ? this.nivelRefrigeranteSalida
          : nivelRefrigeranteSalida as String?,
      nivelFrenosSalida: identical(nivelFrenosSalida, _unset)
          ? this.nivelFrenosSalida
          : nivelFrenosSalida as String?,
      savedQc: identical(savedQc, _unset) ? this.savedQc : savedQc as QcRecord?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
