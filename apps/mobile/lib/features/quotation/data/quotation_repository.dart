import 'package:dio/dio.dart';

import '../domain/quotation_models.dart';

class QuotationException implements Exception {
  const QuotationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuotationRepository {
  QuotationRepository(this._dio);

  final Dio _dio;

  Future<List<QuotationFindingModel>> fetchFindings(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/findings');
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              QuotationFindingModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo cargar los hallazgos.'));
    }
  }

  /// Returns null when no quotation exists yet (HTTP 404).
  Future<QuotationModel?> fetchQuotation(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/quotation');
      return QuotationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo cargar la cotización.'));
    }
  }

  Future<QuotationModel> createQuotation(
    String orderId,
    QuotationCreateRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/quotation',
        data: request.toJson(),
      );
      return QuotationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo crear la cotización.'));
    }
  }

  Future<QuotationModel> sendQuotation(String quotationId) async {
    try {
      final response = await _dio.post('/quotations/$quotationId/send');
      return QuotationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo enviar la cotización.'));
    }
  }

  Future<QuotationModel> applyDiscount(
    String quotationId,
    double descuento, {
    String? razon,
  }) async {
    try {
      final body = <String, dynamic>{'descuento': descuento};
      if (razon != null) body['razon'] = razon;
      final response = await _dio.put(
        '/quotations/$quotationId/discount',
        data: body,
      );
      return QuotationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo aplicar el descuento.'));
    }
  }

  Future<QuotationModel> approveQuotation(String quotationId) async {
    try {
      final response = await _dio.post('/quotations/$quotationId/approve');
      return QuotationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo aprobar la cotización.'));
    }
  }

  Future<({QuotationModel quotation, String? safetyLog})> rejectQuotation(
    String quotationId, {
    String? razon,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (razon != null) body['razon'] = razon;
      final response = await _dio.post(
        '/quotations/$quotationId/reject',
        data: body,
      );
      final data = response.data as Map<String, dynamic>;
      return (
        quotation: QuotationModel.fromJson(data),
        safetyLog: data['safety_log'] as String?,
      );
    } on DioException catch (e) {
      throw QuotationException(
          _extractErrorMessage(e, fallback: 'No se pudo rechazar la cotización.'));
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return fallback;
  }
}
