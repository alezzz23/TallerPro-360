import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reception_repository.dart';
import '../domain/reception_models.dart';
import '../domain/reception_state.dart';
import '../domain/reception_validator.dart';

class ReceptionController extends StateNotifier<ReceptionState> {
  ReceptionController({
    required ReceptionRepository repository,
    required String? advisorId,
    required String? role,
    required String? initialOrderId,
  })  : _repository = repository,
        super(
          ReceptionState.initial(
            canManageReception: _allowedRoles.contains(role),
            advisorId: advisorId,
            initialOrderId: initialOrderId,
          ),
        ) {
    if (initialOrderId != null) {
      unawaited(_loadExisting(initialOrderId));
    }
  }

  static const _allowedRoles = {'ASESOR', 'JEFE_TALLER', 'ADMIN'};

  final ReceptionRepository _repository;

  Timer? _vehicleLookupTimer;
  Timer? _customerLookupTimer;
  int _vehicleLookupVersion = 0;
  int _customerLookupVersion = 0;

  @override
  void dispose() {
    _vehicleLookupTimer?.cancel();
    _customerLookupTimer?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    final orderId = state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }
    await _loadExisting(orderId, silent: false);
  }

  void clearFeedback() {
    if (state.errorMessage == null && state.successMessage == null) {
      return;
    }
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  void setListening(bool isListening) {
    if (state.isListening == isListening) {
      return;
    }
    state = state.copyWith(isListening: isListening);
  }

  void updateVehicleLookupQuery(String value) {
    final query = value.trim();
    state = state.copyWith(
      vehicleLookupQuery: value,
      vehicleSuggestions: query.length < 2
          ? const <ReceptionVehicleSuggestion>[]
          : state.vehicleSuggestions,
      isVehicleLookupLoading: query.length >= 2,
    );
    _vehicleLookupTimer?.cancel();

    if (query.length < 2) {
      state = state.copyWith(
        vehicleSuggestions: const <ReceptionVehicleSuggestion>[],
        isVehicleLookupLoading: false,
      );
      return;
    }

    final version = ++_vehicleLookupVersion;
    _vehicleLookupTimer = Timer(const Duration(milliseconds: 320), () async {
      try {
        final suggestions = await _repository.searchVehicles(query);
        if (version != _vehicleLookupVersion) {
          return;
        }
        state = state.copyWith(
          vehicleSuggestions: suggestions,
          isVehicleLookupLoading: false,
        );
      } catch (error) {
        if (version != _vehicleLookupVersion) {
          return;
        }
        state = state.copyWith(
          isVehicleLookupLoading: false,
          errorMessage: _messageFromError(error),
        );
      }
    });
  }

  void updateCustomerLookupQuery(String value) {
    final query = value.trim();
    state = state.copyWith(
      customerLookupQuery: value,
      customerSuggestions: query.length < 2
          ? const <ReceptionCustomerSuggestion>[]
          : state.customerSuggestions,
      isCustomerLookupLoading: query.length >= 2,
    );
    _customerLookupTimer?.cancel();

    if (query.length < 2) {
      state = state.copyWith(
        customerSuggestions: const <ReceptionCustomerSuggestion>[],
        isCustomerLookupLoading: false,
      );
      return;
    }

    final version = ++_customerLookupVersion;
    _customerLookupTimer = Timer(const Duration(milliseconds: 320), () async {
      try {
        final suggestions = await _repository.searchCustomers(query);
        if (version != _customerLookupVersion) {
          return;
        }
        state = state.copyWith(
          customerSuggestions: suggestions,
          isCustomerLookupLoading: false,
        );
      } catch (error) {
        if (version != _customerLookupVersion) {
          return;
        }
        state = state.copyWith(
          isCustomerLookupLoading: false,
          errorMessage: _messageFromError(error),
        );
      }
    });
  }

  Future<void> selectVehicleSuggestion(ReceptionVehicleSuggestion suggestion) async {
    state = state.copyWith(
      isVehicleLookupLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final context = await _repository.loadVehicleContext(suggestion.vehicleId);
      state = state.copyWith(
        vehicle: context.vehicle,
        customer: context.customer,
        vehicleLookupQuery: '',
        vehicleSuggestions: const <ReceptionVehicleSuggestion>[],
        isVehicleLookupLoading: false,
        customerLookupQuery: '',
        customerSuggestions: const <ReceptionCustomerSuggestion>[],
      );
    } catch (error) {
      state = state.copyWith(
        isVehicleLookupLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> selectCustomerSuggestion(ReceptionCustomerSuggestion suggestion) async {
    state = state.copyWith(
      isCustomerLookupLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final customer = await _repository.fetchCustomer(suggestion.customerId);
      state = state.copyWith(
        customer: customer,
        customerLookupQuery: '',
        customerSuggestions: const <ReceptionCustomerSuggestion>[],
        isCustomerLookupLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isCustomerLookupLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  void detachVehicleSelection() {
    state = state.copyWith(
      vehicle: ReceptionVehicleDraft(
        marca: state.vehicle.marca,
        modelo: state.vehicle.modelo,
        placa: state.vehicle.placa,
        vin: state.vehicle.vin,
        kilometraje: state.vehicle.kilometraje,
        color: state.vehicle.color,
      ),
    );
  }

  void detachCustomerSelection() {
    state = state.copyWith(
      customer: ReceptionCustomerDraft(
        nombre: state.customer.nombre,
        telefono: state.customer.telefono,
        email: state.customer.email,
        direccion: state.customer.direccion,
        whatsapp: state.customer.whatsapp,
      ),
    );
  }

  void updateVehicleDraft({
    String? marca,
    String? modelo,
    String? placa,
    String? vin,
    int? kilometraje,
    String? color,
  }) {
    state = state.copyWith(
      vehicle: state.vehicle.copyWith(
        marca: marca,
        modelo: modelo,
        placa: placa,
        vin: vin,
        kilometraje: kilometraje,
        color: color,
      ),
    );
  }

  void updateCustomerDraft({
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? whatsapp,
  }) {
    state = state.copyWith(
      customer: state.customer.copyWith(
        nombre: nombre,
        telefono: telefono,
        email: email,
        direccion: direccion,
        whatsapp: whatsapp,
      ),
    );
  }

  void setMotivoVisita(String value) {
    state = state.copyWith(motivoVisita: value);
  }

  void updateChecklist({
    ReceptionFluidLevel? nivelAceite,
    ReceptionFluidLevel? nivelRefrigerante,
    ReceptionFluidLevel? nivelFrenos,
    bool? llantaRepuesto,
    bool? kitCarretera,
    bool? botiquin,
    bool? extintor,
    String? documentosRecibidos,
  }) {
    state = state.copyWith(
      checklist: state.checklist.copyWith(
        nivelAceite: nivelAceite,
        nivelRefrigerante: nivelRefrigerante,
        nivelFrenos: nivelFrenos,
        llantaRepuesto: llantaRepuesto,
        kitCarretera: kitCarretera,
        botiquin: botiquin,
        extintor: extintor,
        documentosRecibidos: documentosRecibidos,
      ),
    );
  }

  void addDamage({
    required String zoneKey,
    required String zoneLabel,
    required String description,
    required bool reconocidoPorCliente,
  }) {
    final damage = ReceptionDamageDraft(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      zoneKey: zoneKey,
      zoneLabel: zoneLabel,
      description: description,
      reconocidoPorCliente: reconocidoPorCliente,
    );
    state = state.copyWith(
      damages: [...state.damages, damage],
    );
  }

  void updateDamageRecognition(String localId, bool value) {
    state = state.copyWith(
      damages: [
        for (final damage in state.damages)
          if (damage.localId == localId)
            damage.copyWith(reconocidoPorCliente: value)
          else
            damage,
      ],
    );
  }

  void removeDamage(String localId) {
    state = state.copyWith(
      damages: state.damages
          .where((damage) => damage.localId != localId || damage.isPersisted)
          .toList(growable: false),
    );
  }

  void setPerimeterPhoto(ReceptionPerimeterAngle angle, String localPath) {
    final nextPhotos = Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>.from(
      state.perimeterPhotos,
    );
    nextPhotos[angle] = state.photoFor(angle).copyWith(localPath: localPath);
    state = state.copyWith(perimeterPhotos: nextPhotos);
  }

  void clearPerimeterPhoto(ReceptionPerimeterAngle angle) {
    final current = state.photoFor(angle);
    if (current.remoteUrl != null && current.remoteUrl!.isNotEmpty) {
      return;
    }
    final nextPhotos = Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>.from(
      state.perimeterPhotos,
    );
    nextPhotos[angle] = ReceptionPerimeterPhotoDraft(angle: angle);
    state = state.copyWith(perimeterPhotos: nextPhotos);
  }

  Future<bool> saveDraft({Uint8List? signatureBytes}) {
    return _persist(advance: false, signatureBytes: signatureBytes);
  }

  Future<bool> saveAndAdvance({Uint8List? signatureBytes}) {
    return _persist(advance: true, signatureBytes: signatureBytes);
  }

  Future<void> _loadExisting(String orderId, {bool silent = false}) async {
    state = state.copyWith(
      isInitialLoading: !silent,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final snapshot = await _repository.loadOrderDraft(orderId);
      _applySnapshot(snapshot);
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> _persist({
    required bool advance,
    Uint8List? signatureBytes,
  }) async {
    if (!state.canManageReception) {
      state = state.copyWith(
        errorMessage: 'Tu rol actual no puede registrar una recepcion.',
      );
      return false;
    }

    final issues = advance
        ? ReceptionValidator.advanceIssues(
            state,
            hasPendingSignature: signatureBytes != null,
          )
        : ReceptionValidator.draftIssues(state);
    if (issues.isNotEmpty) {
      state = state.copyWith(
        errorMessage: 'Falta completar: ${issues.join(', ')}.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      successMessage: null,
      progressMessage: advance
          ? 'Preparando recepcion para diagnostico...'
          : 'Guardando borrador de recepcion...',
    );

    try {
      var customer = state.customer;
      state = state.copyWith(progressMessage: 'Guardando cliente...');
      if (customer.isExisting) {
        customer = await _repository.updateCustomer(customer);
      } else {
        customer = await _repository.createCustomer(customer);
      }
      state = state.copyWith(customer: customer);

      var vehicle = state.vehicle.copyWith(customerId: customer.id);
      state = state.copyWith(progressMessage: 'Guardando vehiculo...');
      if (vehicle.isExisting) {
        vehicle = await _repository.updateVehicle(
          vehicle,
          customerId: customer.id!,
        );
      } else {
        vehicle = await _repository.createVehicle(
          vehicle,
          customerId: customer.id!,
        );
      }
      state = state.copyWith(vehicle: vehicle);

      var orderId = state.orderId;
      if (orderId == null || orderId.isEmpty) {
        state = state.copyWith(progressMessage: 'Creando orden de servicio...');
        orderId = await _repository.createOrder(
          vehicleId: vehicle.id!,
          advisorId: state.advisorId!,
          kilometrajeIngreso: vehicle.kilometraje!,
          motivoIngreso: state.motivoVisita.trim(),
        );
        state = state.copyWith(orderId: orderId, loadedFromExistingOrder: true);
      }

      state = state.copyWith(progressMessage: 'Actualizando checklist...');
      await _repository.upsertChecklist(orderId, state.checklist);

      final newDamages = state.damages.where((damage) => !damage.isPersisted);
      for (final damage in newDamages) {
        state = state.copyWith(
          progressMessage: 'Registrando dano en ${damage.zoneLabel.toLowerCase()}...',
        );
        await _repository.addDamage(orderId, damage);
      }

      for (final photo in state.perimeterPhotos.values.where((item) =>
          item.localPath != null && item.localPath!.trim().isNotEmpty)) {
        state = state.copyWith(
          progressMessage:
              'Subiendo foto ${photo.angle.label.toLowerCase()}...',
        );
        final url = await _repository.uploadReceptionPhoto(photo.localPath!);
        await _repository.upsertPerimeterPhoto(
          orderId,
          photo.copyWith(remoteUrl: url),
        );
      }

      if (signatureBytes != null) {
        state = state.copyWith(progressMessage: 'Subiendo firma del cliente...');
        final signatureUrl = await _repository.uploadSignature(signatureBytes);
        await _repository.setClientSignature(orderId, signatureUrl);
      }

      if (advance) {
        state = state.copyWith(progressMessage: 'Enviando a diagnostico...');
        await _repository.advanceOrder(orderId);
      }

      final snapshot = await _repository.loadOrderDraft(orderId);
      _applySnapshot(
        snapshot,
        successMessage: advance
            ? 'Recepcion enviada a diagnostico.'
            : 'Borrador guardado con exito.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        progressMessage: null,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  void _applySnapshot(
    ReceptionOrderSnapshot snapshot, {
    String? successMessage,
  }) {
    state = state.copyWith(
      isInitialLoading: false,
      isSubmitting: false,
      progressMessage: null,
      orderId: snapshot.orderId,
      orderStatus: snapshot.orderStatus,
      vehicle: snapshot.vehicle.copyWith(
        kilometraje: snapshot.kilometrajeIngreso ?? snapshot.vehicle.kilometraje,
      ),
      customer: snapshot.customer,
      checklist: snapshot.checklist,
      motivoVisita: snapshot.motivoVisita,
      damages: snapshot.damages,
      perimeterPhotos: snapshot.perimeterPhotos,
      signatureUrl: snapshot.signatureUrl,
      successMessage: successMessage,
      vehicleLookupQuery: '',
      vehicleSuggestions: const <ReceptionVehicleSuggestion>[],
      isVehicleLookupLoading: false,
      customerLookupQuery: '',
      customerSuggestions: const <ReceptionCustomerSuggestion>[],
      isCustomerLookupLoading: false,
      loadedFromExistingOrder: true,
    );
  }

  static String _messageFromError(Object error) {
    if (error is ReceptionException) {
      return error.message;
    }
    final message = error.toString().trim();
    return message.isEmpty
        ? 'Ocurrio un error inesperado en recepcion.'
        : message;
  }
}