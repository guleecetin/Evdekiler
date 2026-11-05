import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  factory ApiException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        'Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.',
      );
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      // 400: alan bazlı doğrulama hataları
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(first.first.toString(), statusCode: status);
        }
      }
      // 401, 409 vb.: tek mesaj
      final detail = data['detail'];
      if (detail is String) {
        return ApiException(detail, statusCode: status);
      }
    }

    return ApiException(
      'Bir şeyler ters gitti. Lütfen tekrar dene.',
      statusCode: status,
    );
  }
}
