import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../auth/auth_controller.dart';
import 'pantry_models.dart';

class PantryRepository {
  PantryRepository(this._dio);

  final Dio _dio;

  Future<List<PantryItem>> getItems() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/pantry/items');
      return response.data!
          .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Ingredient>> searchIngredients(String search) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/pantry/ingredients',
        queryParameters: {'search': search},
      );
      return response.data!
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addItem({
    required int ingredientId,
    required double quantity,
    required MeasureUnit unit,
    DateTime? expiresAt,
  }) async {
    try {
      await _dio.post(
        '/api/pantry/items',
        data: {
          'ingredientId': ingredientId,
          'quantity': quantity,
          'unit': unit.apiValue,
          'expiresAt': expiresAt == null ? null : _formatDate(expiresAt),
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete('/api/pantry/items/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // Backend DateOnly bekliyor: "2026-11-12"
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final pantryRepositoryProvider = Provider<PantryRepository>(
  (ref) => PantryRepository(ref.watch(dioProvider)),
);

final pantryItemsProvider = FutureProvider<List<PantryItem>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(pantryRepositoryProvider).getItems();
});
