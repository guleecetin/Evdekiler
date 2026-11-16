import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'receipt_models.dart';

class ReceiptRepository {
  ReceiptRepository(this._dio);

  final Dio _dio;

  Future<ReceiptScanResult> parse(List<String> lines) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pantry/receipts/parse',
        data: {'lines': lines},
      );
      return ReceiptScanResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // Tanınmayan satır için kullanıcının seçtiği malzeme: ürün döner, backend öneri kaydeder
  Future<ReceiptCandidate> resolve(String line, int ingredientId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/pantry/receipts/resolve',
        data: {'line': line, 'ingredientId': ingredientId},
      );
      return ReceiptCandidate.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addAll(List<ReceiptCandidate> items) async {
    try {
      await _dio.post(
        '/api/pantry/items/bulk',
        data: {
          'items': [
            for (final i in items)
              {
                'ingredientId': i.ingredientId,
                'quantity': i.quantity,
                'unit': i.unit.apiValue,
              },
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(ref.watch(dioProvider)),
);
