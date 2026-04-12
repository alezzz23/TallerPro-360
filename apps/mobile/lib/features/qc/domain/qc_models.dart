// ─── QcFluidLevel ─────────────────────────────────────────────────────────────

enum QcFluidLevel {
  correcto,
  bajo,
  critico;

  String get label => switch (this) {
        QcFluidLevel.correcto => 'Correcto',
        QcFluidLevel.bajo => 'Bajo',
        QcFluidLevel.critico => 'Crítico',
      };

  String get value => switch (this) {
        QcFluidLevel.correcto => 'correcto',
        QcFluidLevel.bajo => 'bajo',
        QcFluidLevel.critico => 'critico',
      };

  static QcFluidLevel? fromString(String? value) => switch (value) {
        'correcto' => QcFluidLevel.correcto,
        'bajo' => QcFluidLevel.bajo,
        'critico' => QcFluidLevel.critico,
        _ => null,
      };
}

// ─── QcChecklistItem ──────────────────────────────────────────────────────────

class QcChecklistItem {
  const QcChecklistItem({
    required this.id,
    required this.descripcion,
    required this.checked,
  });

  final String id;
  final String descripcion;
  final bool checked;

  QcChecklistItem copyWith({
    String? id,
    String? descripcion,
    bool? checked,
  }) {
    return QcChecklistItem(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      checked: checked ?? this.checked,
    );
  }
}

// ─── QcReceptionSnapshot ──────────────────────────────────────────────────────

class QcReceptionSnapshot {
  const QcReceptionSnapshot({
    this.kmIngreso,
    this.nivelAceiteIngreso,
    this.nivelRefrigeranteIngreso,
    this.nivelFrenosIngreso,
  });

  final int? kmIngreso;
  final String? nivelAceiteIngreso;
  final String? nivelRefrigeranteIngreso;
  final String? nivelFrenosIngreso;
}

// ─── QcRecord ─────────────────────────────────────────────────────────────────

class QcRecord {
  const QcRecord({
    required this.id,
    required this.orderId,
    required this.inspectorId,
    required this.itemsVerificados,
    required this.aprobado,
    required this.fecha,
    this.kilometrajeSalida,
    this.nivelAceiteSalida,
    this.nivelRefrigeranteSalida,
    this.nivelFrenosSalida,
    this.kmDelta,
  });

  factory QcRecord.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items_verificados'] as Map<String, dynamic>? ?? {};
    final items = itemsRaw.map(
      (key, value) => MapEntry(key, value as bool),
    );

    return QcRecord(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      inspectorId: json['inspector_id'] as String,
      itemsVerificados: items,
      kilometrajeSalida: json['kilometraje_salida'] as int?,
      nivelAceiteSalida: json['nivel_aceite_salida'] as String?,
      nivelRefrigeranteSalida: json['nivel_refrigerante_salida'] as String?,
      nivelFrenosSalida: json['nivel_frenos_salida'] as String?,
      aprobado: json['aprobado'] as bool,
      fecha: DateTime.parse(json['fecha'] as String),
      kmDelta: json['km_delta'] as int?,
    );
  }

  final String id;
  final String orderId;
  final String inspectorId;
  final Map<String, bool> itemsVerificados;
  final int? kilometrajeSalida;
  final String? nivelAceiteSalida;
  final String? nivelRefrigeranteSalida;
  final String? nivelFrenosSalida;
  final bool aprobado;
  final DateTime fecha;
  final int? kmDelta;
}
