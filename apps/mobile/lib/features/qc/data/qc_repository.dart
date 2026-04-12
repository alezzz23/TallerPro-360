import 'package:dio/dio.dart';

import '../domain/qc_models.dart';

class QcException implements Exception {
  const QcException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QcRepository {
  QcRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo cargar la orden.'));
    }
  }

  /// Returns null if no reception checklist exists (HTTP 404).
  Future<Map<String, dynamic>?> fetchChecklist(String orderId) async {
    try {
      final response =
          await _dio.get('/orders/$orderId/reception-checklist');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo cargar el checklist de recepción.'));
    }
  }

  /// Returns null if no quotation exists (HTTP 404).
  Future<Map<String, dynamic>?> fetchQuotation(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/quotation');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo cargar la cotización.'));
    }
  }

  /// Returns null if no QC record exists (HTTP 404).
  Future<QcRecord?> fetchQc(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/qc');
      return QcRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo cargar el registro de QC.'));
    }
  }

  Future<QcRecord> saveQc(
    String orderId, {
    required String inspectorId,
    required Map<String, bool> itemsVerificados,
    int? kilometrajeSalida,
    String? nivelAceiteSalida,
    String? nivelRefrigeranteSalida,
    String? nivelFrenosSalida,
    bool aprobado = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'inspector_id': inspectorId,
        'items_verificados': itemsVerificados,
        'aprobado': aprobado,
        if (kilometrajeSalida != null) 'kilometraje_salida': kilometrajeSalida,
        if (nivelAceiteSalida != null) 'nivel_aceite_salida': nivelAceiteSalida,
        if (nivelRefrigeranteSalida != null)
          'nivel_refrigerante_salida': nivelRefrigeranteSalida,
        if (nivelFrenosSalida != null) 'nivel_frenos_salida': nivelFrenosSalida,
      };
      final response = await _dio.post('/orders/$orderId/qc', data: body);
      return QcRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo guardar el QC.'));
    }
  }

  Future<QcRecord> approveQc(String orderId) async {
    try {
      final response = await _dio.put('/orders/$orderId/qc/approve');
      return QcRecord.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QcException(
          _extractMessage(e, fallback: 'No se pudo aprobar el QC.'));
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
