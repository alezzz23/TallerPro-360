import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnosis_models.dart';

class DiagnosisState {
  static const Object _unset = Object();

  const DiagnosisState({
    required this.findings,
    required this.isSaving,
    required this.errorMessage,
    required this.expandedCards,
    required this.technicians,
    required this.techniciansLoaded,
    required this.isLoadingTechnicians,
    required this.uploadingPhotoForFindingId,
  });

  factory DiagnosisState.initial() => const DiagnosisState(
        findings: AsyncValue.loading(),
        isSaving: false,
        errorMessage: null,
        expandedCards: <String, bool>{},
        technicians: <DiagnosisTechnician>[],
        techniciansLoaded: false,
        isLoadingTechnicians: false,
        uploadingPhotoForFindingId: null,
      );

  final AsyncValue<List<DiagnosisFinding>> findings;
  final bool isSaving;
  final String? errorMessage;
  final Map<String, bool> expandedCards;
  final List<DiagnosisTechnician> technicians;
  final bool techniciansLoaded;
  final bool isLoadingTechnicians;
  final String? uploadingPhotoForFindingId;

  DiagnosisState copyWith({
    AsyncValue<List<DiagnosisFinding>>? findings,
    bool? isSaving,
    Object? errorMessage = _unset,
    Map<String, bool>? expandedCards,
    List<DiagnosisTechnician>? technicians,
    bool? techniciansLoaded,
    bool? isLoadingTechnicians,
    Object? uploadingPhotoForFindingId = _unset,
  }) {
    return DiagnosisState(
      findings: findings ?? this.findings,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      expandedCards: expandedCards ?? this.expandedCards,
      technicians: technicians ?? this.technicians,
      techniciansLoaded: techniciansLoaded ?? this.techniciansLoaded,
      isLoadingTechnicians: isLoadingTechnicians ?? this.isLoadingTechnicians,
      uploadingPhotoForFindingId: identical(uploadingPhotoForFindingId, _unset)
          ? this.uploadingPhotoForFindingId
          : uploadingPhotoForFindingId as String?,
    );
  }
}
