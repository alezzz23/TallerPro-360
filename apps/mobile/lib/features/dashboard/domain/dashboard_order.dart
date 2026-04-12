enum DashboardStatus {
  recepcion('RECEPCION', 'Recepción'),
  diagnostico('DIAGNOSTICO', 'Diagnóstico'),
  aprobacion('APROBACION', 'Aprobación'),
  reparacion('REPARACION', 'Reparación'),
  qc('QC', 'QC'),
  entrega('ENTREGA', 'Entrega');

  const DashboardStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static const List<DashboardStatus> boardColumns = [
    DashboardStatus.recepcion,
    DashboardStatus.diagnostico,
    DashboardStatus.aprobacion,
    DashboardStatus.reparacion,
    DashboardStatus.qc,
    DashboardStatus.entrega,
  ];

  static DashboardStatus fromApi(String value) {
    for (final status in boardColumns) {
      if (status.apiValue == value) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'Estado de tablero no soportado');
  }
}

enum DashboardQuotationStatus {
  pendiente('PENDIENTE', 'Pendiente de aprobación'),
  aprobada('APROBADA', 'Cotización aprobada'),
  rechazada('RECHAZADA', 'Cotización rechazada');

  const DashboardQuotationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DashboardQuotationStatus fromApi(String value) {
    for (final status in DashboardQuotationStatus.values) {
      if (status.apiValue == value) {
        return status;
      }
    }
    throw ArgumentError.value(value, 'value', 'Estado de cotización no soportado');
  }
}

class DashboardBoardStatusResolver {
  const DashboardBoardStatusResolver._();

  static DashboardStatus resolve({
    required DashboardStatus backendStatus,
    DashboardQuotationStatus? quotationStatus,
  }) {
    if (backendStatus == DashboardStatus.diagnostico &&
        quotationStatus != null &&
        quotationStatus != DashboardQuotationStatus.aprobada) {
      return DashboardStatus.aprobacion;
    }

    return backendStatus;
  }
}

class DashboardOrder {
  DashboardOrder({
    required this.orderId,
    required this.vehicleId,
    required this.advisorId,
    required this.backendStatus,
    required this.status,
    required this.fechaIngreso,
    required this.receptionComplete,
    required List<String> technicianIds,
    this.motivoIngreso,
    this.placa,
    this.marca,
    this.modelo,
    this.customerName,
    this.quotationId,
    this.quotationStatus,
  }) : technicianIds = List.unmodifiable({
         for (final technicianId in technicianIds)
           if (technicianId.trim().isNotEmpty) technicianId.trim(),
       });

  final String orderId;
  final String vehicleId;
  final String advisorId;
  final DashboardStatus backendStatus;
  final DashboardStatus status;
  final DateTime fechaIngreso;
  final String? motivoIngreso;
  final bool receptionComplete;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String? customerName;
  final String? quotationId;
  final DashboardQuotationStatus? quotationStatus;
  final List<String> technicianIds;

  String get displayPlate {
    final plate = placa?.trim();
    return plate == null || plate.isEmpty ? 'Sin placa' : plate;
  }

  String get displayVehicle {
    final parts = [marca?.trim(), modelo?.trim()]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .cast<String>()
        .toList(growable: false);
    return parts.isEmpty ? 'Vehículo no identificado' : parts.join(' ');
  }

  String get displayCustomerName {
    final value = customerName?.trim();
    return value == null || value.isEmpty ? 'Cliente no identificado' : value;
  }

  String get displayMotive {
    final value = motivoIngreso?.trim();
    return value == null || value.isEmpty ? 'Sin motivo registrado' : value;
  }

  String get shortOrderId {
    final token = orderId.split('-').first;
    return token.length > 8 ? token.substring(0, 8).toUpperCase() : token.toUpperCase();
  }

  bool get hasQuotation => quotationId != null;

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'vehicle_id': vehicleId,
        'advisor_id': advisorId,
        'backend_status': backendStatus.apiValue,
        'status': status.apiValue,
        'fecha_ingreso': fechaIngreso.toIso8601String(),
        'motivo_ingreso': motivoIngreso,
        'reception_complete': receptionComplete,
        'placa': placa,
        'marca': marca,
        'modelo': modelo,
        'customer_name': customerName,
        'quotation_id': quotationId,
        'quotation_status': quotationStatus?.apiValue,
        'technician_ids': technicianIds,
      };

  factory DashboardOrder.fromJson(Map<String, dynamic> json) {
    final quotationStatusStr = json['quotation_status'] as String?;
    return DashboardOrder(
      orderId: json['order_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      advisorId: json['advisor_id'] as String,
      backendStatus:
          DashboardStatus.fromApi(json['backend_status'] as String),
      status: DashboardStatus.fromApi(json['status'] as String),
      fechaIngreso: DateTime.parse(json['fecha_ingreso'] as String),
      motivoIngreso: json['motivo_ingreso'] as String?,
      receptionComplete: json['reception_complete'] as bool,
      placa: json['placa'] as String?,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      customerName: json['customer_name'] as String?,
      quotationId: json['quotation_id'] as String?,
      quotationStatus: quotationStatusStr != null
          ? DashboardQuotationStatus.fromApi(quotationStatusStr)
          : null,
      technicianIds: (json['technician_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}