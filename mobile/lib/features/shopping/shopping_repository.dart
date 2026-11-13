import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../auth/auth_controller.dart';
import '../pantry/pantry_models.dart';

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isPurchased,
  });

  final String id;
  final int ingredientId;
  final String name;
  final double quantity;
  final MeasureUnit unit;
  final bool isPurchased;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    ingredientId: json['ingredientId'] as int,
    name: json['ingredientName'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: MeasureUnit.fromApi(json['unit'] as String),
    isPurchased: json['isPurchased'] as bool,
  );
}

class ShoppingRepository {
  ShoppingRepository(this._dio);

  final Dio _dio;

  Future<List<ShoppingItem>> getItems() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/shopping/items');
      return response.data!
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addItems(
    List<({int ingredientId, String name, double quantity, MeasureUnit unit})>
    items,
  ) async {
    try {
      await _dio.post(
        '/api/shopping/items',
        data: {
          'items': [
            for (final i in items)
              {
                'ingredientId': i.ingredientId,
                'ingredientName': i.name,
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

  Future<void> purchase(String id) async {
    try {
      await _dio.post('/api/shopping/items/$id/purchase');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/shopping/items/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(dioProvider)),
);

final shoppingItemsProvider = FutureProvider<List<ShoppingItem>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(shoppingRepositoryProvider).getItems();
});
