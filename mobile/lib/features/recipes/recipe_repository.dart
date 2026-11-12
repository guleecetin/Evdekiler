import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../pantry/pantry_repository.dart';
import 'recipe_models.dart';

class RecipeRepository {
  RecipeRepository(this._dio);

  final Dio _dio;

  Future<List<RecipeSuggestion>> getSuggestions() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/recipes/suggestions',
      );
      return response.data!
          .map((e) => RecipeSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<RecipeDetail> getById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/recipes/$id');
      return RecipeDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(ref.watch(dioProvider)),
);

final recipeSuggestionsProvider = FutureProvider<List<RecipeSuggestion>>((ref) {
  // Buzdolabı değişince öneriler de yeniden yüklensin
  ref.watch(pantryItemsProvider);
  return ref.watch(recipeRepositoryProvider).getSuggestions();
});

final recipeDetailProvider = FutureProvider.family<RecipeDetail, int>(
  (ref, id) => ref.watch(recipeRepositoryProvider).getById(id),
);
