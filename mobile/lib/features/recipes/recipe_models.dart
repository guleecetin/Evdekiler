import 'package:flutter/material.dart';

import '../pantry/pantry_models.dart';

// Backend'deki RecipeCategory enum'unun karşılığı; renkler web paneliyle aynı
enum RecipeCategory {
  mainCourse(
    'MainCourse',
    'Ana yemek',
    Icons.dinner_dining_outlined,
    Color(0xFFFBE9E2),
    Color(0xFFB4532A),
  ),
  soup(
    'Soup',
    'Çorba',
    Icons.soup_kitchen_outlined,
    Color(0xFFFDF1D8),
    Color(0xFFA86A0C),
  ),
  salad(
    'Salad',
    'Salata',
    Icons.eco_outlined,
    Color(0xFFE4F1E1),
    Color(0xFF2F7A3B),
  ),
  breakfast(
    'Breakfast',
    'Kahvaltılık',
    Icons.egg_alt_outlined,
    Color(0xFFFEF6C9),
    Color(0xFF8A6D00),
  ),
  pastry(
    'Pastry',
    'Hamur işi',
    Icons.bakery_dining_outlined,
    Color(0xFFF4E8D8),
    Color(0xFF8B5A2B),
  ),
  dessert(
    'Dessert',
    'Tatlı',
    Icons.cake_outlined,
    Color(0xFFFBE4EC),
    Color(0xFFB23A68),
  ),
  snack(
    'Snack',
    'Atıştırmalık',
    Icons.cookie_outlined,
    Color(0xFFECE6FA),
    Color(0xFF6B46C1),
  );

  const RecipeCategory(
    this.apiValue,
    this.label,
    this.icon,
    this.background,
    this.foreground,
  );

  final String apiValue;
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  static RecipeCategory fromApi(String? value) =>
      values.firstWhere((c) => c.apiValue == value, orElse: () => mainCourse);
}

class RecipeSuggestion {
  RecipeSuggestion({
    required this.id,
    required this.title,
    required this.emoji,
    required this.imageUrl,
    required this.category,
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
  final RecipeCategory category;
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
        category: RecipeCategory.fromApi(json['category'] as String?),
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
    required this.category,
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
  final RecipeCategory category;
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
    category: RecipeCategory.fromApi(json['category'] as String?),
    prepMinutes: json['prepMinutes'] as int,
    servings: json['servings'] as int,
    ingredients: (json['ingredients'] as List)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList(),
    steps: (json['steps'] as List).cast<String>(),
  );
}
