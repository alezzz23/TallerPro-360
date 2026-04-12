enum MetodoPago {
  efectivo,
  tarjeta,
  transferencia,
  credito;

  String get label => switch (this) {
        MetodoPago.efectivo => 'Efectivo',
        MetodoPago.tarjeta => 'Tarjeta',
        MetodoPago.transferencia => 'Transferencia',
        MetodoPago.credito => 'Crédito',
      };

  String get apiValue => name.toUpperCase();

  static MetodoPago fromApi(String v) =>
      MetodoPago.values.firstWhere((e) => e.apiValue == v.toUpperCase());
}

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.orderId,
    required this.montoTotal,
    required this.metodoPago,
    required this.esCredito,
    required this.saldoPendiente,
    required this.fecha,
  });

  final String id;
  final String orderId;
  final double montoTotal;
  final MetodoPago metodoPago;
  final bool esCredito;
  final double saldoPendiente;
  final DateTime fecha;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        montoTotal: (json['monto_total'] as num).toDouble(),
        metodoPago: MetodoPago.fromApi(json['metodo_pago'] as String),
        esCredito: json['es_credito'] as bool,
        saldoPendiente: (json['saldo_pendiente'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha'] as String),
      );
}

class NpsModel {
  const NpsModel({
    required this.id,
    required this.orderId,
    required this.atencion,
    required this.instalaciones,
    required this.tiempos,
    required this.precios,
    required this.recomendacion,
    this.comentarios,
    required this.fecha,
  });

  final String id;
  final String orderId;
  final int atencion;
  final int instalaciones;
  final int tiempos;
  final int precios;
  final int recomendacion;
  final String? comentarios;
  final DateTime fecha;

  factory NpsModel.fromJson(Map<String, dynamic> json) => NpsModel(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        atencion: json['atencion'] as int,
        instalaciones: json['instalaciones'] as int,
        tiempos: json['tiempos'] as int,
        precios: json['precios'] as int,
        recomendacion: json['recomendacion'] as int,
        comentarios: json['comentarios'] as String?,
        fecha: DateTime.parse(json['fecha'] as String),
      );
}

class QuotationSummary {
  const QuotationSummary({
    required this.total,
    required this.subtotal,
    required this.impuestos,
    required this.shopSupplies,
    required this.descuento,
  });

  final double total;
  final double subtotal;
  final double impuestos;
  final double shopSupplies;
  final double descuento;

  factory QuotationSummary.fromJson(Map<String, dynamic> json) =>
      QuotationSummary(
        total: (json['total'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        impuestos: (json['impuestos'] as num).toDouble(),
        shopSupplies: (json['shop_supplies'] as num).toDouble(),
        descuento: (json['descuento'] as num).toDouble(),
      );
}
