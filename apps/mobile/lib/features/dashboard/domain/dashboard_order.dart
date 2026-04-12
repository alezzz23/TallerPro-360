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

class DashboardOrder {
  DashboardOrder({
    required this.orderId,
    required this.vehicleId,
    required this.advisorId,
    required this.status,
    required this.fechaIngreso,
    required this.receptionComplete,
    required List<String> technicianIds,
    this.motivoIngreso,
    this.placa,
    this.marca,
    this.modelo,
    this.customerName,
  }) : technicianIds = List.unmodifiable({
         for (final technicianId in technicianIds)
           if (technicianId.trim().isNotEmpty) technicianId.trim(),
       });

  final String orderId;
  final String vehicleId;
  final String advisorId;
  final DashboardStatus status;
  final DateTime fechaIngreso;
  final String? motivoIngreso;
  final bool receptionComplete;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String? customerName;
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
}