import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/dashboard_order.dart';
import '../domain/dashboard_transition.dart';

class DashboardException implements Exception {
  const DashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardRepository {
  DashboardRepository(this._dio, [this._cache]);

  final Dio _dio;
  final CachedOrdersDao? _cache;

  Future<List<DashboardOrder>> fetchDashboardOrders() async {
    try {
      final orders = await _fetchActiveOrders();
      if (orders.isEmpty) {
        return const [];
      }

      final vehiclesById = await _fetchVehiclesById({
        for (final order in orders) order.vehicleId,
      });
      final customersById = await _fetchCustomersById({
        for (final vehicle in vehiclesById.values) vehicle.customerId,
      });

      final findingsEntries = await Future.wait(
        orders.map((order) async {
          final findings = await _fetchFindings(order.id);
          return MapEntry(order.id, findings);
        }),
      );
      final findingsByOrder = Map<String, List<_FindingDto>>.fromEntries(findingsEntries);

      final quotationEntries = await Future.wait(
        orders.map((order) async {
          final quotation = switch (order.status) {
            DashboardStatus.diagnostico || DashboardStatus.aprobacion =>
              await _fetchQuotation(order.id),
            _ => null,
          };
          return MapEntry(order.id, quotation);
        }),
      );
      final quotationsByOrder = Map<String, _QuotationDto?>.fromEntries(quotationEntries);

      final dashboardOrders = orders
          .map((order) {
            final vehicle = vehiclesById[order.vehicleId];
            final customer = vehicle == null ? null : customersById[vehicle.customerId];
            final findings = findingsByOrder[order.id] ?? const <_FindingDto>[];
            final quotation = quotationsByOrder[order.id];
            final boardStatus = DashboardBoardStatusResolver.resolve(
              backendStatus: order.status,
              quotationStatus: quotation?.status,
            );
            return DashboardOrder(
              orderId: order.id,
              vehicleId: order.vehicleId,
              advisorId: order.advisorId,
              backendStatus: order.status,
              status: boardStatus,
              fechaIngreso: order.fechaIngreso,
              motivoIngreso: order.motivoIngreso,
              receptionComplete: order.receptionComplete,
              placa: vehicle?.placa,
              marca: vehicle?.marca,
              modelo: vehicle?.modelo,
              customerName: customer?.nombre,
              quotationId: quotation?.id,
              quotationStatus: quotation?.status,
              technicianIds: [
                for (final finding in findings) finding.technicianId,
              ],
            );
          })
          .toList(growable: false)
        ..sort((left, right) => left.fechaIngreso.compareTo(right.fechaIngreso));

      // Persist result to local cache for offline use
      if (_cache != null) {
        final now = DateTime.now().toUtc();
        await _cache.upsertOrders([
          for (final order in dashboardOrders)
            CachedOrdersCompanion.insert(
              orderId: order.orderId,
              jsonBlob: jsonEncode(order.toJson()),
              cachedAt: now,
            ),
        ]);
      }

      return dashboardOrders;
    } on DioException catch (error) {
      // Try serving from cache when offline or network error
      if (_cache != null) {
        final cached = await _cache.allCachedOrders();
        if (cached.isNotEmpty) {
          return cached
              .map((row) => DashboardOrder.fromJson(
                    jsonDecode(row.jsonBlob) as Map<String, dynamic>,
                  ))
              .toList(growable: false)
            ..sort((a, b) => a.fechaIngreso.compareTo(b.fechaIngreso));
        }
      }
      throw DashboardException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo cargar el tablero operativo.',
        ),
      );
    }
  }

  Future<String> moveOrder({
    required DashboardOrder order,
    required DashboardStatus targetStatus,
    required String? currentUserId,
  }) async {
    final policy = DashboardTransitionHelper.policyFor(
      from: order.status,
      to: targetStatus,
    );

    if (policy == null) {
      throw const DashboardException('Movimiento no soportado en esta fase.');
    }

    try {
      switch (policy.action) {
        case DashboardTransitionAction.advanceReception:
          await _dio.put('/orders/${order.orderId}/advance');
          break;
        case DashboardTransitionAction.approveQuotation:
          final quotationId = order.quotationId ?? await _fetchQuotationId(order.orderId);
          await _dio.post('/quotations/$quotationId/approve');
          break;
        case DashboardTransitionAction.startQc:
          final inspectorId = _readString(currentUserId);
          if (inspectorId == null) {
            throw const DashboardException(
              'No se pudo identificar al inspector para iniciar Control de Calidad.',
            );
          }
          await _dio.post(
            '/orders/${order.orderId}/qc',
            data: {
              'inspector_id': inspectorId,
              'items_verificados': <String, dynamic>{},
              'aprobado': true,
            },
          );
          break;
        case DashboardTransitionAction.approveQc:
          await _dio.put('/orders/${order.orderId}/qc/approve');
          break;
      }

      return policy.successMessage;
    } on DioException catch (error) {
      throw DashboardException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo mover la orden.',
        ),
      );
    }
  }

  Future<List<_OrderDto>> _fetchActiveOrders() async {
    final pages = await Future.wait(
      DashboardStatus.boardColumns.map(_fetchOrdersByStatus),
    );
    return pages.expand((items) => items).toList(growable: false);
  }

  Future<List<_OrderDto>> _fetchOrdersByStatus(DashboardStatus status) async {
    const pageSize = 100;
    final orders = <_OrderDto>[];
    var offset = 0;
    var total = pageSize;

    while (offset < total) {
      final response = await _dio.get(
        '/orders/',
        queryParameters: {
          'estado': status.apiValue,
          'limit': pageSize,
          'offset': offset,
        },
      );
      final data = _asMap(response.data);
      final items = _asListOfMaps(data['items'])
          .map(_OrderDto.fromJson)
          .toList(growable: false);
      final resolvedTotal = _readInt(data['total']) ?? items.length;

      orders.addAll(items);
      offset += items.length;
      total = resolvedTotal;

      if (items.isEmpty) {
        break;
      }
    }

    return orders;
  }

  Future<Map<String, _VehicleDto>> _fetchVehiclesById(Set<String> vehicleIds) async {
    if (vehicleIds.isEmpty) {
      return const <String, _VehicleDto>{};
    }

    const pageSize = 100;
    final vehicles = <String, _VehicleDto>{};
    var offset = 0;
    var total = pageSize;

    while (offset < total && vehicles.length < vehicleIds.length) {
      final response = await _dio.get(
        '/vehicles/',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );
      final data = _asMap(response.data);
      final items = _asListOfMaps(data['items'])
          .map(_VehicleDto.fromJson)
          .toList(growable: false);
      final resolvedTotal = _readInt(data['total']) ?? items.length;

      for (final vehicle in items) {
        if (vehicleIds.contains(vehicle.id)) {
          vehicles[vehicle.id] = vehicle;
        }
      }

      offset += items.length;
      total = resolvedTotal;

      if (items.isEmpty) {
        break;
      }
    }

    return vehicles;
  }

  Future<Map<String, _CustomerDto>> _fetchCustomersById(Set<String> customerIds) async {
    if (customerIds.isEmpty) {
      return const <String, _CustomerDto>{};
    }

    const pageSize = 100;
    final customers = <String, _CustomerDto>{};
    var offset = 0;
    var total = pageSize;

    while (offset < total && customers.length < customerIds.length) {
      final response = await _dio.get(
        '/customers/',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );
      final data = _asMap(response.data);
      final items = _asListOfMaps(data['items'])
          .map(_CustomerDto.fromJson)
          .toList(growable: false);
      final resolvedTotal = _readInt(data['total']) ?? items.length;

      for (final customer in items) {
        if (customerIds.contains(customer.id)) {
          customers[customer.id] = customer;
        }
      }

      offset += items.length;
      total = resolvedTotal;

      if (items.isEmpty) {
        break;
      }
    }

    return customers;
  }

  Future<List<_FindingDto>> _fetchFindings(String orderId) async {
    final response = await _dio.get('/orders/$orderId/findings');
    return _asListOfMaps(response.data)
        .map(_FindingDto.fromJson)
        .toList(growable: false);
  }

  Future<_QuotationDto?> _fetchQuotation(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/quotation');
      return _QuotationDto.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw DashboardException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo recuperar la cotización de la orden.',
        ),
      );
    }
  }

  Future<String> _fetchQuotationId(String orderId) async {
    final response = await _dio.get('/orders/$orderId/quotation');
    final data = _asMap(response.data);
    return _requireString(data['id'], field: 'id');
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

class _OrderDto {
  const _OrderDto({
    required this.id,
    required this.vehicleId,
    required this.advisorId,
    required this.status,
    required this.fechaIngreso,
    required this.receptionComplete,
    this.motivoIngreso,
  });

  final String id;
  final String vehicleId;
  final String advisorId;
  final DashboardStatus status;
  final DateTime fechaIngreso;
  final bool receptionComplete;
  final String? motivoIngreso;

  factory _OrderDto.fromJson(Map<String, dynamic> json) {
    return _OrderDto(
      id: _requireString(json['id'], field: 'id'),
      vehicleId: _requireString(json['vehicle_id'], field: 'vehicle_id'),
      advisorId: _requireString(json['advisor_id'], field: 'advisor_id'),
      status: DashboardStatus.fromApi(
        _requireString(json['estado'], field: 'estado'),
      ),
      fechaIngreso: DateTime.parse(
        _requireString(json['fecha_ingreso'], field: 'fecha_ingreso'),
      ),
      receptionComplete: json['reception_complete'] == true,
      motivoIngreso: _readString(json['motivo_ingreso']),
    );
  }
}

class _VehicleDto {
  const _VehicleDto({
    required this.id,
    required this.customerId,
    required this.placa,
    required this.marca,
    required this.modelo,
  });

  final String id;
  final String customerId;
  final String placa;
  final String marca;
  final String modelo;

  factory _VehicleDto.fromJson(Map<String, dynamic> json) {
    return _VehicleDto(
      id: _requireString(json['id'], field: 'id'),
      customerId: _requireString(json['customer_id'], field: 'customer_id'),
      placa: _readString(json['placa']) ?? '',
      marca: _readString(json['marca']) ?? '',
      modelo: _readString(json['modelo']) ?? '',
    );
  }
}

class _CustomerDto {
  const _CustomerDto({
    required this.id,
    required this.nombre,
  });

  final String id;
  final String nombre;

  factory _CustomerDto.fromJson(Map<String, dynamic> json) {
    return _CustomerDto(
      id: _requireString(json['id'], field: 'id'),
      nombre: _readString(json['nombre']) ?? '',
    );
  }
}

class _FindingDto {
  const _FindingDto({required this.technicianId});

  final String technicianId;

  factory _FindingDto.fromJson(Map<String, dynamic> json) {
    return _FindingDto(
      technicianId: _requireString(json['technician_id'], field: 'technician_id'),
    );
  }
}

class _QuotationDto {
  const _QuotationDto({
    required this.id,
    required this.status,
  });

  final String id;
  final DashboardQuotationStatus status;

  factory _QuotationDto.fromJson(Map<String, dynamic> json) {
    return _QuotationDto(
      id: _requireString(json['id'], field: 'id'),
      status: DashboardQuotationStatus.fromApi(
        _requireString(json['estado'], field: 'estado'),
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, data) => MapEntry(key.toString(), data));
  }
  throw const DashboardException('Respuesta inesperada del servidor.');
}

List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
  if (value is List) {
    return value.map(_asMap).toList(growable: false);
  }
  throw const DashboardException('Respuesta inesperada del servidor.');
}

String _requireString(dynamic value, {required String field}) {
  final resolved = _readString(value);
  if (resolved == null || resolved.isEmpty) {
    throw DashboardException('Falta el campo requerido: $field.');
  }
  return resolved;
}

String? _readString(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}