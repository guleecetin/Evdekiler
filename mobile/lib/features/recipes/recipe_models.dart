import '../pantry/pantry_models.dart';

class RecipeSuggestion {
  RecipeSuggestion({
    required this.id,
    required this.title,
    required this.emoji,
    required this.imageUrl,
    required this.prepMinutes,
    required this.servings,
    required this.haveCount,
    required this.requiredCount,
    required this.matchPercent,
    required this.missing,
  });

  final int id;
  final String title;
  final String emoji;
  final String imageUrl;
  final int prepMinutes;
  final int servings;
  final int haveCount;
  final int requiredCount;
  final int matchPercent;
  final List<String> missing;

  bool get isReady => missing.isEmpty;

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) =>
      RecipeSuggestion(
        id: json['id'] as int,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        imageUrl: json['imageUrl'] as String,
        prepMinutes: json['prepMinutes'] as int,
        servings: json['servings'] as int,
        haveCount: json['haveCount'] as int,
        requiredCount: json['requiredCount'] as int,
        matchPercent: json['matchPercent'] as int,
        missing: (json['missing'] as List).cast<String>(),
      );
}

class RecipeIngredient {
  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isOptional,
  });

  final int ingredientId;
  final String name;
  final double quantity;
  final MeasureUnit unit;
  final bool isOptional;

  String get imageUrl => '/images/ingredients/$ingredientId.jpg';

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        ingredientId: json['ingredientId'] as int,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: MeasureUnit.fromApi(json['unit'] as String),
        isOptional: json['isOptional'] as bool,
      );
}

class RecipeDetail {
  RecipeDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.imageUrl,
    required this.prepMinutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });

  final int id;
  final String title;
  final String description;
  final String emoji;
  final String imageUrl;
  final int prepMinutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) => RecipeDetail(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String,
    emoji: json['emoji'] as String,
    imageUrl: json['imageUrl'] as String,
    prepMinutes: json['prepMinutes'] as int,
    servings: json['servings'] as int,
    ingredients: (json['ingredients'] as List)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList(),
    steps: (json['steps'] as List).cast<String>(),
  );
}
