import 'package:dio/dio.dart';

import '../domain/dashboard_order.dart';
import '../domain/dashboard_transition.dart';

class DashboardException implements Exception {
  const DashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

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

      final dashboardOrders = orders
          .map((order) {
            final vehicle = vehiclesById[order.vehicleId];
            final customer = vehicle == null ? null : customersById[vehicle.customerId];
            final findings = findingsByOrder[order.id] ?? const <_FindingDto>[];
            return DashboardOrder(
              orderId: order.id,
              vehicleId: order.vehicleId,
              advisorId: order.advisorId,
              status: order.status,
              fechaIngreso: order.fechaIngreso,
              motivoIngreso: order.motivoIngreso,
              receptionComplete: order.receptionComplete,
              placa: vehicle?.placa,
              marca: vehicle?.marca,
              modelo: vehicle?.modelo,
              customerName: customer?.nombre,
              technicianIds: [
                for (final finding in findings) finding.technicianId,
              ],
            );
          })
          .toList(growable: false)
        ..sort((left, right) => left.fechaIngreso.compareTo(right.fechaIngreso));

      return dashboardOrders;
    } on DioException catch (error) {
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
          final quotationId = await _fetchQuotationId(order.orderId);
          await _dio.post('/quotations/$quotationId/approve');
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