// ─── Enums ────────────────────────────────────────────────────────────────────

enum QuotationEstado {
  pendiente,
  aprobada,
  rechazada;

  String get label => switch (this) {
        QuotationEstado.pendiente => 'Pendiente',
        QuotationEstado.aprobada => 'Aprobada',
        QuotationEstado.rechazada => 'Rechazada',
      };

  static QuotationEstado fromJson(String value) =>
      switch (value.toUpperCase()) {
        'PENDIENTE' => QuotationEstado.pendiente,
        'APROBADA' => QuotationEstado.aprobada,
        'RECHAZADA' => QuotationEstado.rechazada,
        _ => QuotationEstado.pendiente,
      };
}

enum PartOrigenQuotation {
  stock,
  pedido;

  static PartOrigenQuotation fromJson(String value) =>
      switch (value.toUpperCase()) {
        'PEDIDO' => PartOrigenQuotation.pedido,
        _ => PartOrigenQuotation.stock,
      };
}

// ─── Part Model ───────────────────────────────────────────────────────────────

class QuotationPartModel {
  const QuotationPartModel({
    required this.id,
    required this.findingId,
    required this.nombre,
    required this.origen,
    required this.costo,
    required this.margen,
    required this.precioVenta,
    this.proveedor,
  });

  factory QuotationPartModel.fromJson(Map<String, dynamic> json) =>
      QuotationPartModel(
        id: json['id'] as String,
        findingId: json['finding_id'] as String,
        nombre: json['nombre'] as String,
        origen: PartOrigenQuotation.fromJson(json['origen'] as String),
        costo: (json['costo'] as num).toDouble(),
        margen: (json['margen'] as num).toDouble(),
        precioVenta: (json['precio_venta'] as num).toDouble(),
        proveedor: json['proveedor'] as String?,
      );

  final String id;
  final String findingId;
  final String nombre;
  final PartOrigenQuotation origen;
  final double costo;
  final double margen;
  final double precioVenta;
  final String? proveedor;
}

// ─── Finding Model ────────────────────────────────────────────────────────────

class QuotationFindingModel {
  const QuotationFindingModel({
    required this.id,
    required this.motivo,
    required this.descripcion,
    required this.esHallazgoAdicional,
    required this.esCriticoSeguridad,
    required this.parts,
    this.safetyWarning,
  });

  factory QuotationFindingModel.fromJson(Map<String, dynamic> json) =>
      QuotationFindingModel(
        id: json['id'] as String,
        motivo: json['motivo_ingreso'] as String,
        descripcion: json['descripcion'] as String,
        esHallazgoAdicional: json['es_hallazgo_adicional'] as bool,
        esCriticoSeguridad: json['es_critico_seguridad'] as bool,
        safetyWarning: json['safety_warning'] as String?,
        parts: (json['parts'] as List<dynamic>)
            .map((e) =>
                QuotationPartModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String id;
  final String motivo;
  final String descripcion;
  final bool esHallazgoAdicional;
  final bool esCriticoSeguridad;
  final String? safetyWarning;
  final List<QuotationPartModel> parts;
}

// ─── Line Item (builder state) ────────────────────────────────────────────────

class QuotationLineItem {
  static const Object _unset = Object();

  const QuotationLineItem({
    required this.findingId,
    required this.descripcion,
    required this.manoObra,
    required this.costoRepuesto,
    this.partId,
  });

  final String findingId;
  final String? partId;
  final String descripcion;
  final double manoObra;
  final double costoRepuesto;

  double get costoTotal => manoObra + costoRepuesto;

  QuotationLineItem copyWith({
    Object? partId = _unset,
    String? descripcion,
    double? manoObra,
    double? costoRepuesto,
  }) {
    return QuotationLineItem(
      findingId: findingId,
      partId: identical(partId, _unset) ? this.partId : partId as String?,
      descripcion: descripcion ?? this.descripcion,
      manoObra: manoObra ?? this.manoObra,
      costoRepuesto: costoRepuesto ?? this.costoRepuesto,
    );
  }
}

// ─── Quotation Item Model (from API) ─────────────────────────────────────────

class QuotationItemModel {
  const QuotationItemModel({
    required this.id,
    required this.quotationId,
    required this.findingId,
    required this.descripcion,
    required this.manoObra,
    required this.costoRepuesto,
    required this.precioFinal,
    this.partId,
  });

  factory QuotationItemModel.fromJson(Map<String, dynamic> json) =>
      QuotationItemModel(
        id: json['id'] as String,
        quotationId: json['quotation_id'] as String,
        findingId: json['finding_id'] as String,
        partId: json['part_id'] as String?,
        descripcion: json['descripcion'] as String,
        manoObra: (json['mano_obra'] as num).toDouble(),
        costoRepuesto: (json['costo_repuesto'] as num).toDouble(),
        precioFinal: (json['precio_final'] as num).toDouble(),
      );

  final String id;
  final String quotationId;
  final String findingId;
  final String? partId;
  final String descripcion;
  final double manoObra;
  final double costoRepuesto;
  final double precioFinal;
}

// ─── Quotation Model (from API) ───────────────────────────────────────────────

class QuotationModel {
  const QuotationModel({
    required this.id,
    required this.orderId,
    required this.subtotal,
    required this.impuestos,
    required this.shopSupplies,
    required this.descuento,
    required this.total,
    required this.estado,
    required this.items,
    this.fechaEnvio,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) => QuotationModel(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        subtotal: (json['subtotal'] as num).toDouble(),
        impuestos: (json['impuestos'] as num).toDouble(),
        shopSupplies: (json['shop_supplies'] as num).toDouble(),
        descuento: (json['descuento'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        estado: QuotationEstado.fromJson(json['estado'] as String),
        fechaEnvio: json['fecha_envio'] != null
            ? DateTime.parse(json['fecha_envio'] as String)
            : null,
        items: (json['items'] as List<dynamic>)
            .map((e) =>
                QuotationItemModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String id;
  final String orderId;
  final double subtotal;
  final double impuestos;
  final double shopSupplies;
  final double descuento;
  final double total;
  final QuotationEstado estado;
  final DateTime? fechaEnvio;
  final List<QuotationItemModel> items;
}

// ─── Create Request ───────────────────────────────────────────────────────────

class QuotationCreateRequest {
  const QuotationCreateRequest({
    required this.items,
    this.impuestosPct = 0.16,
    this.shopSuppliesPct = 0.015,
    this.descuento = 0.0,
  });

  final List<QuotationLineItem> items;
  final double impuestosPct;
  final double shopSuppliesPct;
  final double descuento;

  Map<String, dynamic> toJson() => {
        'items': items
            .map(
              (item) => {
                'finding_id': item.findingId,
                'part_id': item.partId,
                'descripcion': item.descripcion,
                'mano_obra': item.manoObra,
                'costo_repuesto': item.costoRepuesto,
              },
            )
            .toList(),
        'impuestos_pct': impuestosPct,
        'shop_supplies_pct': shopSuppliesPct,
        'descuento': descuento,
      };
}
