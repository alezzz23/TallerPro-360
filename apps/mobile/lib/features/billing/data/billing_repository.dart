import 'package:dio/dio.dart';

import '../domain/billing_models.dart';

class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BillingRepository {
  BillingRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo cargar la orden.'));
    }
  }

  /// Returns null if no approved quotation exists (HTTP 404).
  Future<QuotationSummary?> fetchQuotation(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/quotation');
      return QuotationSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo cargar la cotización.'));
    }
  }

  /// Returns null if no invoice exists (HTTP 404).
  Future<InvoiceModel?> fetchInvoice(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/invoice');
      return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo cargar la factura.'));
    }
  }

  /// Returns null if no NPS survey exists (HTTP 404).
  Future<NpsModel?> fetchNps(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/nps');
      return NpsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo cargar la encuesta NPS.'));
    }
  }

  Future<InvoiceModel> createInvoice(
    String orderId, {
    required MetodoPago metodoPago,
    required bool esCredito,
    required double saldoPendiente,
  }) async {
    try {
      final body = <String, dynamic>{
        'metodo_pago': metodoPago.apiValue,
        'es_credito': esCredito,
        'saldo_pendiente': saldoPendiente,
      };
      final response = await _dio.post('/orders/$orderId/invoice', data: body);
      return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const BillingException('La factura ya fue generada');
      }
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo generar la factura.'));
    }
  }

  Future<NpsModel> createNps(
    String orderId, {
    required int atencion,
    required int instalaciones,
    required int tiempos,
    required int precios,
    required int recomendacion,
    String? comentarios,
  }) async {
    try {
      final body = <String, dynamic>{
        'atencion': atencion,
        'instalaciones': instalaciones,
        'tiempos': tiempos,
        'precios': precios,
        'recomendacion': recomendacion,
        if (comentarios != null && comentarios.isNotEmpty)
          'comentarios': comentarios,
      };
      final response = await _dio.post('/orders/$orderId/nps', data: body);
      return NpsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const BillingException('La encuesta NPS ya fue enviada');
      }
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo enviar la encuesta NPS.'));
    }
  }

  Future<void> closeOrder(String orderId) async {
    try {
      await _dio.put('/orders/$orderId/close');
    } on DioException catch (e) {
      throw BillingException(
          _extractMessage(e, fallback: 'No se pudo cerrar la orden.'));
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _extractMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return fallback;
  }
}
