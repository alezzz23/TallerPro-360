class DiagnosisPart {
  const DiagnosisPart({
    required this.id,
    required this.findingId,
    required this.nombre,
    required this.origen,
    required this.costo,
    required this.margen,
    required this.precioVenta,
    this.proveedor,
  });

  factory DiagnosisPart.fromJson(Map<String, dynamic> json) => DiagnosisPart(
        id: json['id'] as String,
        findingId: json['finding_id'] as String,
        nombre: json['nombre'] as String,
        origen: json['origen'] as String,
        costo: (json['costo'] as num).toDouble(),
        margen: (json['margen'] as num).toDouble(),
        precioVenta: (json['precio_venta'] as num).toDouble(),
        proveedor: json['proveedor'] as String?,
      );

  final String id;
  final String findingId;
  final String nombre;

  /// 'STOCK' or 'PEDIDO'
  final String origen;
  final double costo;

  /// Stored as 0–1 (e.g., 0.30 = 30 %)
  final double margen;
  final double precioVenta;
  final String? proveedor;

  /// Utility: costo / (1 - margen). Returns 0 when margen >= 1.
  static double computePrecioVenta(double costo, double margen) {
    if (margen >= 1.0) return 0.0;
    return costo / (1.0 - margen);
  }
}

class DiagnosisFinding {
  const DiagnosisFinding({
    required this.id,
    required this.orderId,
    required this.technicianId,
    required this.motivoIngreso,
    this.descripcion,
    this.tiempoEstimado,
    required this.fotos,
    required this.esHallazgoAdicional,
    required this.esCriticoSeguridad,
    required this.parts,
    this.safetyWarning,
  });

  factory DiagnosisFinding.fromJson(Map<String, dynamic> json) =>
      DiagnosisFinding(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        technicianId: json['technician_id'] as String,
        motivoIngreso: json['motivo_ingreso'] as String,
        descripcion: json['descripcion'] as String?,
        tiempoEstimado: json['tiempo_estimado'] == null
            ? null
            : (json['tiempo_estimado'] as num).toDouble(),
        fotos: (json['fotos'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
        esHallazgoAdicional: json['es_hallazgo_adicional'] as bool? ?? false,
        esCriticoSeguridad: json['es_critico_seguridad'] as bool? ?? false,
        parts: (json['parts'] as List<dynamic>? ?? <dynamic>[])
            .map((p) => DiagnosisPart.fromJson(p as Map<String, dynamic>))
            .toList(growable: false),
        safetyWarning: json['safety_warning'] as String?,
      );

  final String id;
  final String orderId;
  final String technicianId;
  final String motivoIngreso;
  final String? descripcion;
  final double? tiempoEstimado;
  final List<String> fotos;
  final bool esHallazgoAdicional;
  final bool esCriticoSeguridad;
  final List<DiagnosisPart> parts;
  final String? safetyWarning;

  static const Object _unset = Object();

  DiagnosisFinding copyWith({
    String? id,
    String? orderId,
    String? technicianId,
    String? motivoIngreso,
    Object? descripcion = _unset,
    Object? tiempoEstimado = _unset,
    List<String>? fotos,
    bool? esHallazgoAdicional,
    bool? esCriticoSeguridad,
    List<DiagnosisPart>? parts,
    Object? safetyWarning = _unset,
  }) {
    return DiagnosisFinding(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      technicianId: technicianId ?? this.technicianId,
      motivoIngreso: motivoIngreso ?? this.motivoIngreso,
      descripcion: identical(descripcion, _unset)
          ? this.descripcion
          : descripcion as String?,
      tiempoEstimado: identical(tiempoEstimado, _unset)
          ? this.tiempoEstimado
          : tiempoEstimado as double?,
      fotos: fotos ?? this.fotos,
      esHallazgoAdicional: esHallazgoAdicional ?? this.esHallazgoAdicional,
      esCriticoSeguridad: esCriticoSeguridad ?? this.esCriticoSeguridad,
      parts: parts ?? this.parts,
      safetyWarning: identical(safetyWarning, _unset)
          ? this.safetyWarning
          : safetyWarning as String?,
    );
  }
}

class DiagnosisTechnician {
  const DiagnosisTechnician({required this.id, required this.nombre});

  factory DiagnosisTechnician.fromJson(Map<String, dynamic> json) =>
      DiagnosisTechnician(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
      );

  final String id;
  final String nombre;
}
