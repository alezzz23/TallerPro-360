enum ReceptionFluidLevel {
  correcto('Correcto', 'CORRECTO'),
  bajo('Bajo', 'BAJO'),
  critico('Critico', 'CRITICO');

  const ReceptionFluidLevel(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static ReceptionFluidLevel? fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'CORRECTO':
      case 'OK':
      case 'NORMAL':
        return ReceptionFluidLevel.correcto;
      case 'BAJO':
      case 'LOW':
        return ReceptionFluidLevel.bajo;
      case 'CRITICO':
      case 'CRITICAL':
        return ReceptionFluidLevel.critico;
      default:
        return null;
    }
  }
}

enum ReceptionPerimeterAngle {
  frontal('Frontal', 'FRONTAL'),
  izquierdo('Izquierdo', 'IZQUIERDO'),
  derecho('Derecho', 'DERECHO'),
  trasero('Trasero', 'TRASERO');

  const ReceptionPerimeterAngle(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static ReceptionPerimeterAngle? fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'FRONTAL':
        return ReceptionPerimeterAngle.frontal;
      case 'IZQUIERDO':
        return ReceptionPerimeterAngle.izquierdo;
      case 'DERECHO':
        return ReceptionPerimeterAngle.derecho;
      case 'TRASERO':
        return ReceptionPerimeterAngle.trasero;
      default:
        return null;
    }
  }
}

class ReceptionVehicleDraft {
  const ReceptionVehicleDraft({
    this.id,
    this.customerId,
    this.marca = '',
    this.modelo = '',
    this.placa = '',
    this.vin = '',
    this.kilometraje,
    this.color = '',
  });

  final String? id;
  final String? customerId;
  final String marca;
  final String modelo;
  final String placa;
  final String vin;
  final int? kilometraje;
  final String color;

  bool get isExisting => id != null;

  ReceptionVehicleDraft copyWith({
    String? id,
    String? customerId,
    String? marca,
    String? modelo,
    String? placa,
    String? vin,
    int? kilometraje,
    String? color,
  }) {
    return ReceptionVehicleDraft(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      placa: placa ?? this.placa,
      vin: vin ?? this.vin,
      kilometraje: kilometraje ?? this.kilometraje,
      color: color ?? this.color,
    );
  }
}

class ReceptionCustomerDraft {
  const ReceptionCustomerDraft({
    this.id,
    this.nombre = '',
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.whatsapp = '',
  });

  final String? id;
  final String nombre;
  final String telefono;
  final String email;
  final String direccion;
  final String whatsapp;

  bool get isExisting => id != null;

  ReceptionCustomerDraft copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? whatsapp,
  }) {
    return ReceptionCustomerDraft(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}

class ReceptionChecklistDraft {
  const ReceptionChecklistDraft({
    this.nivelAceite,
    this.nivelRefrigerante,
    this.nivelFrenos,
    this.llantaRepuesto = false,
    this.kitCarretera = false,
    this.botiquin = false,
    this.extintor = false,
    this.documentosRecibidos = '',
  });

  final ReceptionFluidLevel? nivelAceite;
  final ReceptionFluidLevel? nivelRefrigerante;
  final ReceptionFluidLevel? nivelFrenos;
  final bool llantaRepuesto;
  final bool kitCarretera;
  final bool botiquin;
  final bool extintor;
  final String documentosRecibidos;

  ReceptionChecklistDraft copyWith({
    ReceptionFluidLevel? nivelAceite,
    ReceptionFluidLevel? nivelRefrigerante,
    ReceptionFluidLevel? nivelFrenos,
    bool? llantaRepuesto,
    bool? kitCarretera,
    bool? botiquin,
    bool? extintor,
    String? documentosRecibidos,
  }) {
    return ReceptionChecklistDraft(
      nivelAceite: nivelAceite ?? this.nivelAceite,
      nivelRefrigerante: nivelRefrigerante ?? this.nivelRefrigerante,
      nivelFrenos: nivelFrenos ?? this.nivelFrenos,
      llantaRepuesto: llantaRepuesto ?? this.llantaRepuesto,
      kitCarretera: kitCarretera ?? this.kitCarretera,
      botiquin: botiquin ?? this.botiquin,
      extintor: extintor ?? this.extintor,
      documentosRecibidos: documentosRecibidos ?? this.documentosRecibidos,
    );
  }
}

class ReceptionDamageDraft {
  const ReceptionDamageDraft({
    required this.localId,
    required this.zoneKey,
    required this.zoneLabel,
    required this.description,
    required this.reconocidoPorCliente,
    this.id,
    this.isPersisted = false,
  });

  final String localId;
  final String? id;
  final String zoneKey;
  final String zoneLabel;
  final String description;
  final bool reconocidoPorCliente;
  final bool isPersisted;

  ReceptionDamageDraft copyWith({
    String? localId,
    String? id,
    String? zoneKey,
    String? zoneLabel,
    String? description,
    bool? reconocidoPorCliente,
    bool? isPersisted,
  }) {
    return ReceptionDamageDraft(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      zoneKey: zoneKey ?? this.zoneKey,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      description: description ?? this.description,
      reconocidoPorCliente:
          reconocidoPorCliente ?? this.reconocidoPorCliente,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }
}

class ReceptionPerimeterPhotoDraft {
  const ReceptionPerimeterPhotoDraft({
    required this.angle,
    this.localPath,
    this.remoteUrl,
  });

  final ReceptionPerimeterAngle angle;
  final String? localPath;
  final String? remoteUrl;

  bool get hasImage =>
      (localPath?.trim().isNotEmpty ?? false) ||
      (remoteUrl?.trim().isNotEmpty ?? false);

  ReceptionPerimeterPhotoDraft copyWith({
    ReceptionPerimeterAngle? angle,
    String? localPath,
    String? remoteUrl,
  }) {
    return ReceptionPerimeterPhotoDraft(
      angle: angle ?? this.angle,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
    );
  }
}

class ReceptionVehicleSuggestion {
  const ReceptionVehicleSuggestion({
    required this.vehicleId,
    required this.customerId,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.vin,
    required this.customerName,
    required this.customerContact,
  });

  final String vehicleId;
  final String customerId;
  final String placa;
  final String marca;
  final String modelo;
  final String vin;
  final String customerName;
  final String customerContact;

  String get vehicleLabel => '$marca $modelo'.trim();
}

class ReceptionCustomerSuggestion {
  const ReceptionCustomerSuggestion({
    required this.customerId,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.whatsapp,
  });

  final String customerId;
  final String nombre;
  final String telefono;
  final String email;
  final String whatsapp;

  String get contactLabel {
    final contact = whatsapp.isNotEmpty ? whatsapp : telefono;
    if (contact.isNotEmpty) {
      return contact;
    }
    return email;
  }
}

class ReceptionOrderSnapshot {
  const ReceptionOrderSnapshot({
    required this.orderId,
    required this.orderStatus,
    required this.vehicle,
    required this.customer,
    required this.motivoVisita,
    required this.kilometrajeIngreso,
    required this.checklist,
    required this.damages,
    required this.perimeterPhotos,
    required this.signatureUrl,
    required this.receptionComplete,
  });

  final String orderId;
  final String orderStatus;
  final ReceptionVehicleDraft vehicle;
  final ReceptionCustomerDraft customer;
  final String motivoVisita;
  final int? kilometrajeIngreso;
  final ReceptionChecklistDraft checklist;
  final List<ReceptionDamageDraft> damages;
  final Map<ReceptionPerimeterAngle, ReceptionPerimeterPhotoDraft>
      perimeterPhotos;
  final String? signatureUrl;
  final bool receptionComplete;
}