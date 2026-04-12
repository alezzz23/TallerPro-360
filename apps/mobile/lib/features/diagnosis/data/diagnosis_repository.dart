import 'dart:io';

import 'package:dio/dio.dart';

import '../domain/diagnosis_models.dart';

class DiagnosisException implements Exception {
  const DiagnosisException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DiagnosisRepository {
  DiagnosisRepository(this._dio);

  final Dio _dio;

  Future<List<DiagnosisFinding>> getFindings(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/findings');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => DiagnosisFinding.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo cargar los hallazgos.'));
    }
  }

  Future<DiagnosisFinding> createFinding(
    String orderId, {
    required String technicianId,
    required String motivoIngreso,
    String? descripcion,
    double? tiempoEstimado,
    bool esHallazgoAdicional = false,
    bool esCriticoSeguridad = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'technician_id': technicianId,
        'motivo_ingreso': motivoIngreso,
        'es_hallazgo_adicional': esHallazgoAdicional,
        'es_critico_seguridad': esCriticoSeguridad,
      };
      if (descripcion != null && descripcion.isNotEmpty) {
        body['descripcion'] = descripcion;
      }
      if (tiempoEstimado != null) {
        body['tiempo_estimado'] = tiempoEstimado;
      }
      final response = await _dio.post('/orders/$orderId/findings', data: body);
      return DiagnosisFinding.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo crear el hallazgo.'));
    }
  }

  Future<DiagnosisFinding> updateFinding(
    String findingId, {
    String? technicianId,
    String? descripcion,
    double? tiempoEstimado,
    bool? esCriticoSeguridad,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (technicianId != null) body['technician_id'] = technicianId;
      if (descripcion != null) body['descripcion'] = descripcion;
      if (tiempoEstimado != null) body['tiempo_estimado'] = tiempoEstimado;
      if (esCriticoSeguridad != null) {
        body['es_critico_seguridad'] = esCriticoSeguridad;
      }
      final response = await _dio.put('/findings/$findingId', data: body);
      return DiagnosisFinding.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo actualizar el hallazgo.'));
    }
  }

  Future<DiagnosisFinding> addPhoto(String findingId, String photoUrl) async {
    try {
      final response = await _dio.post(
        '/findings/$findingId/photos',
        data: {'foto_url': photoUrl},
      );
      return DiagnosisFinding.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo agregar la foto.'));
    }
  }

  Future<DiagnosisPart> addPart(
    String findingId, {
    required String nombre,
    required String origen,
    required double costo,
    required double margen,
    String? proveedor,
  }) async {
    try {
      final body = <String, dynamic>{
        'nombre': nombre,
        'origen': origen,
        'costo': costo,
        'margen': margen,
      };
      if (proveedor != null && proveedor.isNotEmpty) {
        body['proveedor'] = proveedor;
      }
      final response =
          await _dio.post('/findings/$findingId/parts', data: body);
      return DiagnosisPart.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo agregar el repuesto.'));
    }
  }

  Future<List<DiagnosisTechnician>> getTechnicians() async {
    try {
      final response = await _dio.get('/users/technicians');
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              DiagnosisTechnician.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo cargar los técnicos.'));
    }
  }

  Future<String> uploadPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
        'category': 'DIAGNOSTICO',
      });
      final response = await _dio.post('/uploads/', data: formData);
      final data = response.data as Map<String, dynamic>;
      return data['url'] as String;
    } on DioException catch (e) {
      throw DiagnosisException(
          _extractErrorMessage(e, fallback: 'No se pudo subir la foto.'));
    }
  }

  static String _extractErrorMessage(DioException error,
      {required String fallback}) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic>) {
          return first['msg'] as String? ?? fallback;
        }
      }
    }
    return fallback;
  }
}
