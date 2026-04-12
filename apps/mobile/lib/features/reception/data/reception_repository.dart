import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../domain/reception_models.dart';

class ReceptionException implements Exception {
  const ReceptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceptionRepository {
  ReceptionRepository(this._dio);

  final Dio _dio;

  Future<List<ReceptionVehicleSuggestion>> searchVehicles(String query) async {
    try {
      final response = await _dio.get(
        '/vehicles/',
        queryParameters: {'q': query, 'limit': 6},
      );
      final data = _asMap(response.data);
      final vehicles = _asListOfMaps(data['items'])
          .map(_vehicleFromJson)
          .toList(growable: false);
      if (vehicles.isEmpty) {
        return const <ReceptionVehicleSuggestion>[];
      }

      final customerIds = {
        for (final vehicle in vehicles)
          if (vehicle.customerId != null) vehicle.customerId!,
      };
      final customerEntries = await Future.wait(
        customerIds.map((customerId) async {
          try {
            final customer = await fetchCustomer(customerId);
            return MapEntry(customerId, customer);
          } catch (_) {
            return null;
          }
        }),
      );
      final customersById = {
        for (final entry in customerEntries.whereType<MapEntry<String, ReceptionCustomerDraft>>())
          entry.key: entry.value,
      };

      return vehicles
          .map(
            (vehicle) => ReceptionVehicleSuggestion(
              vehicleId: vehicle.id ?? '',
              customerId: vehicle.customerId ?? '',
              placa: vehicle.placa,
              marca: vehicle.marca,
              modelo: vehicle.modelo,
              vin: vehicle.vin,
              customerName:
                  customersById[vehicle.customerId]?.nombre ?? 'Cliente sin nombre',
              customerContact:
                  customersById[vehicle.customerId]?.whatsapp.isNotEmpty == true
                      ? customersById[vehicle.customerId]!.whatsapp
                      : customersById[vehicle.customerId]?.telefono ?? '',
            ),
          )
          .where((item) => item.vehicleId.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo buscar el vehiculo.',
        ),
      );
    }
  }

  Future<List<ReceptionCustomerSuggestion>> searchCustomers(String query) async {
    try {
      final response = await _dio.get(
        '/customers/',
        queryParameters: {'q': query, 'limit': 6},
      );
      final data = _asMap(response.data);
      return _asListOfMaps(data['items'])
          .map(_customerFromJson)
          .map(
            (customer) => ReceptionCustomerSuggestion(
              customerId: customer.id ?? '',
              nombre: customer.nombre,
              telefono: customer.telefono,
              email: customer.email,
              whatsapp: customer.whatsapp,
            ),
          )
          .where((item) => item.customerId.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo buscar el cliente.',
        ),
      );
    }
  }

  Future<ReceptionVehicleDraft> fetchVehicle(String vehicleId) async {
    try {
      final response = await _dio.get('/vehicles/$vehicleId');
      return _vehicleFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo cargar el vehiculo.',
        ),
      );
    }
  }

  Future<ReceptionCustomerDraft> fetchCustomer(String customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId');
      return _customerFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo cargar el cliente.',
        ),
      );
    }
  }

  Future<({ReceptionVehicleDraft vehicle, ReceptionCustomerDraft customer})>
      loadVehicleContext(String vehicleId) async {
    final vehicle = await fetchVehicle(vehicleId);
    final customerId = vehicle.customerId;
    if (customerId == null || customerId.isEmpty) {
      throw const ReceptionException(
        'El vehiculo seleccionado no tiene cliente asociado.',
      );
    }
    final customer = await fetchCustomer(customerId);
    return (vehicle: vehicle, customer: customer);
  }

  Future<ReceptionOrderSnapshot> loadOrderDraft(String orderId) async {
    try {
      final orderResponse = await _dio.get('/orders/$orderId');
      final order = _asMap(orderResponse.data);
      final vehicle = await fetchVehicle(_requireString(order['vehicle_id'], field: 'vehicle_id'));
      final customerId = vehicle.customerId;
      if (customerId == null || customerId.isEmpty) {
        throw const ReceptionException('La orden no tiene cliente asociado.');
      }
      final customer = await fetchCustomer(customerId);
      final checklistSnapshot = await _tryFetchChecklist(orderId);
      final damages = await _fetchDamages(orderId);
      final photos = await _fetchPerimeterPhotos(orderId);
      final perimeterMap = {
        for (final angle in ReceptionPerimeterAngle.values)
          angle: ReceptionPerimeterPhotoDraft(angle: angle),
        ...photos,
      };

      return ReceptionOrderSnapshot(
        orderId: _requireString(order['id'], field: 'id'),
        orderStatus: _readString(order['estado']) ?? 'RECEPCION',
        vehicle: vehicle.copyWith(
          kilometraje: _readInt(order['kilometraje_ingreso']) ?? vehicle.kilometraje,
        ),
        customer: customer,
        motivoVisita: _readString(order['motivo_ingreso']) ?? '',
        kilometrajeIngreso: _readInt(order['kilometraje_ingreso']),
        checklist: checklistSnapshot?.checklist ?? const ReceptionChecklistDraft(),
        damages: damages,
        perimeterPhotos: perimeterMap,
        signatureUrl: checklistSnapshot?.signatureUrl,
        receptionComplete: _readBool(order['reception_complete']),
      );
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo cargar la recepcion activa.',
        ),
      );
    }
  }

  Future<ReceptionCustomerDraft> createCustomer(
    ReceptionCustomerDraft customer,
  ) async {
    try {
      final response = await _dio.post('/customers/', data: _customerPayload(customer));
      return _customerFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo crear el cliente.',
        ),
      );
    }
  }

  Future<ReceptionCustomerDraft> updateCustomer(
    ReceptionCustomerDraft customer,
  ) async {
    if (customer.id == null || customer.id!.isEmpty) {
      throw const ReceptionException('No hay cliente para actualizar.');
    }
    try {
      final response = await _dio.put(
        '/customers/${customer.id}',
        data: _customerPayload(customer),
      );
      return _customerFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo actualizar el cliente.',
        ),
      );
    }
  }

  Future<ReceptionVehicleDraft> createVehicle(
    ReceptionVehicleDraft vehicle, {
    required String customerId,
  }) async {
    try {
      final response = await _dio.post(
        '/vehicles/',
        data: _vehiclePayload(vehicle, customerId: customerId),
      );
      return _vehicleFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo crear el vehiculo.',
        ),
      );
    }
  }

  Future<ReceptionVehicleDraft> updateVehicle(
    ReceptionVehicleDraft vehicle, {
    required String customerId,
  }) async {
    if (vehicle.id == null || vehicle.id!.isEmpty) {
      throw const ReceptionException('No hay vehiculo para actualizar.');
    }
    try {
      final response = await _dio.put(
        '/vehicles/${vehicle.id}',
        data: _vehiclePayload(vehicle, customerId: customerId),
      );
      return _vehicleFromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo actualizar el vehiculo.',
        ),
      );
    }
  }

  Future<String> createOrder({
    required String vehicleId,
    required String advisorId,
    required int kilometrajeIngreso,
    required String motivoIngreso,
  }) async {
    try {
      final response = await _dio.post(
        '/orders/',
        data: {
          'vehicle_id': vehicleId,
          'advisor_id': advisorId,
          'kilometraje_ingreso': kilometrajeIngreso,
          'motivo_ingreso': motivoIngreso,
        },
      );
      return _requireString(_asMap(response.data)['id'], field: 'id');
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo crear la orden de servicio.',
        ),
      );
    }
  }

  Future<void> upsertChecklist(
    String orderId,
    ReceptionChecklistDraft checklist,
  ) async {
    try {
      await _dio.post(
        '/orders/$orderId/reception-checklist',
        data: {
          'nivel_aceite': checklist.nivelAceite?.apiValue,
          'nivel_refrigerante': checklist.nivelRefrigerante?.apiValue,
          'nivel_frenos': checklist.nivelFrenos?.apiValue,
          'llanta_repuesto': checklist.llantaRepuesto,
          'kit_carretera': checklist.kitCarretera,
          'botiquin': checklist.botiquin,
          'extintor': checklist.extintor,
          'documentos_recibidos': checklist.documentosRecibidos.trim(),
        },
      );
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo guardar el checklist de recepcion.',
        ),
      );
    }
  }

  Future<void> addDamage(String orderId, ReceptionDamageDraft damage) async {
    try {
      await _dio.post(
        '/orders/$orderId/damages',
        data: {
          'ubicacion': damage.zoneKey,
          'descripcion': damage.description.trim(),
          'reconocido_por_cliente': damage.reconocidoPorCliente,
        },
      );
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo registrar un dano preexistente.',
        ),
      );
    }
  }

  Future<void> upsertPerimeterPhoto(
    String orderId,
    ReceptionPerimeterPhotoDraft photo,
  ) async {
    final remoteUrl = photo.remoteUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      throw const ReceptionException('La foto de perimetro no tiene URL cargada.');
    }
    try {
      await _dio.post(
        '/orders/$orderId/perimeter-photos',
        data: {
          'angulo': photo.angle.apiValue,
          'foto_url': remoteUrl,
        },
      );
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo guardar una foto de perimetro.',
        ),
      );
    }
  }

  Future<String> uploadReceptionPhoto(String localPath) async {
    return _uploadMedia(
      file: await MultipartFile.fromFile(
        localPath,
        filename: path.basename(localPath),
      ),
      category: 'reception',
      fallbackMessage: 'No se pudo subir la foto.',
    );
  }

  Future<String> uploadSignature(Uint8List bytes) async {
    return _uploadMedia(
      file: MultipartFile.fromBytes(bytes, filename: 'firma_cliente.png'),
      category: 'signature',
      fallbackMessage: 'No se pudo subir la firma del cliente.',
    );
  }

  Future<void> setClientSignature(String orderId, String signatureUrl) async {
    try {
      await _dio.post(
        '/orders/$orderId/client-signature',
        data: {'firma_cliente_url': signatureUrl},
      );
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo asociar la firma del cliente.',
        ),
      );
    }
  }

  Future<void> advanceOrder(String orderId) async {
    try {
      await _dio.put('/orders/$orderId/advance');
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo avanzar la orden a diagnostico.',
        ),
      );
    }
  }

  Future<String> _uploadMedia({
    required MultipartFile file,
    required String category,
    required String fallbackMessage,
  }) async {
    try {
      final response = await _dio.post(
        '/uploads/',
        data: FormData.fromMap({'file': file, 'category': category}),
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return _requireString(_asMap(response.data)['url'], field: 'url');
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(error, fallback: fallbackMessage),
      );
    }
  }

  Future<_ChecklistSnapshot?> _tryFetchChecklist(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/reception-checklist');
      final data = _asMap(response.data);
      return _ChecklistSnapshot(
        checklist: _checklistFromJson(data),
        signatureUrl: _readString(data['firma_cliente_url']),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo cargar el checklist de recepcion.',
        ),
      );
    }
  }

  Future<List<ReceptionDamageDraft>> _fetchDamages(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/damages');
      return _asListOfMaps(response.data)
          .map(_damageFromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudieron cargar los danos registrados.',
        ),
      );
    }
  }

  Future<Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>>
      _fetchPerimeterPhotos(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/perimeter-photos');
      final photos = _asListOfMaps(response.data)
          .map(_perimeterPhotoFromJson)
          .whereType<ReceptionPerimeterPhotoDraft>()
          .toList(growable: false);
      return {
        for (final photo in photos) photo.angle: photo,
      };
    } on DioException catch (error) {
      throw ReceptionException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudieron cargar las fotos de perimetro.',
        ),
      );
    }
  }

  ReceptionVehicleDraft _vehicleFromJson(Map<String, dynamic> json) {
    return ReceptionVehicleDraft(
      id: _readString(json['id']),
      customerId: _readString(json['customer_id']),
      marca: _readString(json['marca']) ?? '',
      modelo: _readString(json['modelo']) ?? '',
      placa: _readString(json['placa']) ?? '',
      vin: _readString(json['vin']) ?? '',
      kilometraje: _readInt(json['kilometraje']),
      color: _readString(json['color']) ?? '',
    );
  }

  ReceptionCustomerDraft _customerFromJson(Map<String, dynamic> json) {
    return ReceptionCustomerDraft(
      id: _readString(json['id']),
      nombre: _readString(json['nombre']) ?? '',
      telefono: _readString(json['telefono']) ?? '',
      email: _readString(json['email']) ?? '',
      direccion: _readString(json['direccion']) ?? '',
      whatsapp: _readString(json['whatsapp']) ?? '',
    );
  }

  ReceptionChecklistDraft _checklistFromJson(Map<String, dynamic> json) {
    return ReceptionChecklistDraft(
      nivelAceite: ReceptionFluidLevel.fromApi(_readString(json['nivel_aceite'])),
      nivelRefrigerante:
          ReceptionFluidLevel.fromApi(_readString(json['nivel_refrigerante'])),
      nivelFrenos: ReceptionFluidLevel.fromApi(_readString(json['nivel_frenos'])),
      llantaRepuesto: _readBool(json['llanta_repuesto']),
      kitCarretera: _readBool(json['kit_carretera']),
      botiquin: _readBool(json['botiquin']),
      extintor: _readBool(json['extintor']),
      documentosRecibidos: _readString(json['documentos_recibidos']) ?? '',
    );
  }

  ReceptionDamageDraft _damageFromJson(Map<String, dynamic> json) {
    final serverId = _readString(json['id']) ?? '';
    final zoneKey = _readString(json['ubicacion']) ?? 'zona';
    return ReceptionDamageDraft(
      localId: serverId,
      id: serverId,
      zoneKey: zoneKey,
      zoneLabel: _humanizeZone(zoneKey),
      description: _readString(json['descripcion']) ?? '',
      reconocidoPorCliente: _readBool(json['reconocido_por_cliente']),
      isPersisted: true,
    );
  }

  ReceptionPerimeterPhotoDraft? _perimeterPhotoFromJson(
    Map<String, dynamic> json,
  ) {
    final angle = ReceptionPerimeterAngle.fromApi(_readString(json['angulo']));
    if (angle == null) {
      return null;
    }
    return ReceptionPerimeterPhotoDraft(
      angle: angle,
      remoteUrl: _readString(json['foto_url']),
    );
  }

  static Map<String, dynamic> _customerPayload(ReceptionCustomerDraft customer) {
    return {
      'nombre': customer.nombre.trim(),
      'telefono': _readNullableTrimmed(customer.telefono),
      'email': _readNullableTrimmed(customer.email),
      'direccion': _readNullableTrimmed(customer.direccion),
      'whatsapp': _readNullableTrimmed(customer.whatsapp),
    };
  }

  static Map<String, dynamic> _vehiclePayload(
    ReceptionVehicleDraft vehicle, {
    required String customerId,
  }) {
    return {
      'customer_id': customerId,
      'marca': vehicle.marca.trim(),
      'modelo': vehicle.modelo.trim(),
      'placa': vehicle.placa.trim().toUpperCase(),
      'vin': _readNullableTrimmed(vehicle.vin),
      'kilometraje': vehicle.kilometraje,
      'color': _readNullableTrimmed(vehicle.color),
    };
  }

  static String _humanizeZone(String zoneKey) {
    return zoneKey
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _extractErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return fallback;
  }
}

Map<String, dynamic> _asMap(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const ReceptionException('Respuesta invalida del servidor.');
}

List<Map<String, dynamic>> _asListOfMaps(Object? data) {
  if (data is List) {
    return data.map((item) => _asMap(item)).toList(growable: false);
  }
  throw const ReceptionException('Se esperaba una lista valida del servidor.');
}

String _requireString(Object? value, {required String field}) {
  final resolved = _readString(value);
  if (resolved != null && resolved.isNotEmpty) {
    return resolved;
  }
  throw ReceptionException('Falta el campo requerido: $field.');
}

String? _readString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.trim().toLowerCase() == 'true';
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}

String? _readNullableTrimmed(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

class _ChecklistSnapshot {
  const _ChecklistSnapshot({
    required this.checklist,
    required this.signatureUrl,
  });

  final ReceptionChecklistDraft checklist;
  final String? signatureUrl;
}