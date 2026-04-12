import 'reception_models.dart';

class ReceptionState {
  static const Object _unset = Object();

  const ReceptionState({
    required this.canManageReception,
    required this.advisorId,
    required this.isInitialLoading,
    required this.isSubmitting,
    required this.isListening,
    required this.orderId,
    required this.orderStatus,
    required this.errorMessage,
    required this.successMessage,
    required this.progressMessage,
    required this.vehicle,
    required this.customer,
    required this.checklist,
    required this.motivoVisita,
    required this.vehicleLookupQuery,
    required this.vehicleSuggestions,
    required this.isVehicleLookupLoading,
    required this.customerLookupQuery,
    required this.customerSuggestions,
    required this.isCustomerLookupLoading,
    required this.damages,
    required this.perimeterPhotos,
    required this.signatureUrl,
    required this.loadedFromExistingOrder,
  });

  factory ReceptionState.initial({
    required bool canManageReception,
    required String? advisorId,
    String? initialOrderId,
  }) {
    return ReceptionState(
      canManageReception: canManageReception,
      advisorId: advisorId,
      isInitialLoading: initialOrderId != null,
      isSubmitting: false,
      isListening: false,
      orderId: initialOrderId,
      orderStatus: initialOrderId == null ? null : 'RECEPCION',
      errorMessage: null,
      successMessage: null,
      progressMessage: null,
      vehicle: const ReceptionVehicleDraft(),
      customer: const ReceptionCustomerDraft(),
      checklist: const ReceptionChecklistDraft(),
      motivoVisita: '',
      vehicleLookupQuery: '',
      vehicleSuggestions: const <ReceptionVehicleSuggestion>[],
      isVehicleLookupLoading: false,
      customerLookupQuery: '',
      customerSuggestions: const <ReceptionCustomerSuggestion>[],
      isCustomerLookupLoading: false,
      damages: const <ReceptionDamageDraft>[],
      perimeterPhotos: {
        for (final angle in ReceptionPerimeterAngle.values)
          angle: ReceptionPerimeterPhotoDraft(angle: angle),
      },
      signatureUrl: null,
      loadedFromExistingOrder: initialOrderId != null,
    );
  }

  final bool canManageReception;
  final String? advisorId;
  final bool isInitialLoading;
  final bool isSubmitting;
  final bool isListening;
  final String? orderId;
  final String? orderStatus;
  final String? errorMessage;
  final String? successMessage;
  final String? progressMessage;
  final ReceptionVehicleDraft vehicle;
  final ReceptionCustomerDraft customer;
  final ReceptionChecklistDraft checklist;
  final String motivoVisita;
  final String vehicleLookupQuery;
  final List<ReceptionVehicleSuggestion> vehicleSuggestions;
  final bool isVehicleLookupLoading;
  final String customerLookupQuery;
  final List<ReceptionCustomerSuggestion> customerSuggestions;
  final bool isCustomerLookupLoading;
  final List<ReceptionDamageDraft> damages;
  final Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>
      perimeterPhotos;
  final String? signatureUrl;
  final bool loadedFromExistingOrder;

  bool get isBusy => isInitialLoading || isSubmitting;

  bool get hasStoredSignature => signatureUrl?.trim().isNotEmpty ?? false;

  int get capturedPerimeterCount => ReceptionPerimeterAngle.values
      .where((angle) => photoFor(angle).hasImage)
      .length;

  bool get hasAllPerimeterPhotos =>
      capturedPerimeterCount == ReceptionPerimeterAngle.values.length;

  ReceptionPerimeterPhotoDraft photoFor(ReceptionPerimeterAngle angle) {
    return perimeterPhotos[angle] ?? ReceptionPerimeterPhotoDraft(angle: angle);
  }

  ReceptionState copyWith({
    Object? canManageReception = _unset,
    Object? advisorId = _unset,
    Object? isInitialLoading = _unset,
    Object? isSubmitting = _unset,
    Object? isListening = _unset,
    Object? orderId = _unset,
    Object? orderStatus = _unset,
    Object? errorMessage = _unset,
    Object? successMessage = _unset,
    Object? progressMessage = _unset,
    Object? vehicle = _unset,
    Object? customer = _unset,
    Object? checklist = _unset,
    Object? motivoVisita = _unset,
    Object? vehicleLookupQuery = _unset,
    Object? vehicleSuggestions = _unset,
    Object? isVehicleLookupLoading = _unset,
    Object? customerLookupQuery = _unset,
    Object? customerSuggestions = _unset,
    Object? isCustomerLookupLoading = _unset,
    Object? damages = _unset,
    Object? perimeterPhotos = _unset,
    Object? signatureUrl = _unset,
    Object? loadedFromExistingOrder = _unset,
  }) {
    return ReceptionState(
      canManageReception: identical(canManageReception, _unset)
          ? this.canManageReception
          : canManageReception as bool,
      advisorId:
          identical(advisorId, _unset) ? this.advisorId : advisorId as String?,
      isInitialLoading: identical(isInitialLoading, _unset)
          ? this.isInitialLoading
          : isInitialLoading as bool,
      isSubmitting: identical(isSubmitting, _unset)
          ? this.isSubmitting
          : isSubmitting as bool,
      isListening: identical(isListening, _unset)
          ? this.isListening
          : isListening as bool,
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      orderStatus: identical(orderStatus, _unset)
          ? this.orderStatus
          : orderStatus as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _unset)
          ? this.successMessage
          : successMessage as String?,
      progressMessage: identical(progressMessage, _unset)
          ? this.progressMessage
          : progressMessage as String?,
      vehicle: identical(vehicle, _unset)
          ? this.vehicle
          : vehicle as ReceptionVehicleDraft,
      customer: identical(customer, _unset)
          ? this.customer
          : customer as ReceptionCustomerDraft,
      checklist: identical(checklist, _unset)
          ? this.checklist
          : checklist as ReceptionChecklistDraft,
      motivoVisita: identical(motivoVisita, _unset)
          ? this.motivoVisita
          : motivoVisita as String,
      vehicleLookupQuery: identical(vehicleLookupQuery, _unset)
          ? this.vehicleLookupQuery
          : vehicleLookupQuery as String,
      vehicleSuggestions: identical(vehicleSuggestions, _unset)
          ? this.vehicleSuggestions
          : vehicleSuggestions as List<ReceptionVehicleSuggestion>,
      isVehicleLookupLoading: identical(isVehicleLookupLoading, _unset)
          ? this.isVehicleLookupLoading
          : isVehicleLookupLoading as bool,
      customerLookupQuery: identical(customerLookupQuery, _unset)
          ? this.customerLookupQuery
          : customerLookupQuery as String,
      customerSuggestions: identical(customerSuggestions, _unset)
          ? this.customerSuggestions
          : customerSuggestions as List<ReceptionCustomerSuggestion>,
      isCustomerLookupLoading: identical(isCustomerLookupLoading, _unset)
          ? this.isCustomerLookupLoading
          : isCustomerLookupLoading as bool,
      damages: identical(damages, _unset)
          ? this.damages
          : damages as List<ReceptionDamageDraft>,
      perimeterPhotos: identical(perimeterPhotos, _unset)
          ? this.perimeterPhotos
          : perimeterPhotos
              as Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>,
      signatureUrl: identical(signatureUrl, _unset)
          ? this.signatureUrl
          : signatureUrl as String?,
      loadedFromExistingOrder: identical(loadedFromExistingOrder, _unset)
          ? this.loadedFromExistingOrder
          : loadedFromExistingOrder as bool,
    );
  }
}