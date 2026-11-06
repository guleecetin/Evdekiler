import 'package:flutter/material.dart';

enum MeasureUnit {
  piece('Piece', 'adet'),
  gram('Gram', 'g'),
  kilogram('Kilogram', 'kg'),
  milliliter('Milliliter', 'ml'),
  liter('Liter', 'L');

  const MeasureUnit(this.apiValue, this.label);
  final String apiValue; // backend'e giden değer
  final String label; // ekranda görünen

  static MeasureUnit fromApi(String value) =>
      values.firstWhere((u) => u.apiValue == value);
}

const categoryTint = {
  'Vegetable': Color(0xFFE3F1DF),
  'Fruit': Color(0xFFFDE8D7),
  'Dairy': Color(0xFFFFF5D6),
  'Meat': Color(0xFFFBE0DC),
  'Grain': Color(0xFFF3EAD8),
  'Legume': Color(0xFFEDE3D6),
  'Spice': Color(0xFFFBE3E0),
  'Other': Color(0xFFE8ECEF),
};

class Ingredient {
  Ingredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.defaultUnit,
  });

  final int id;
  final String name;
  final String emoji;
  final String category;
  final MeasureUnit defaultUnit;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'] as int,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    category: json['category'] as String,
    defaultUnit: MeasureUnit.fromApi(json['defaultUnit'] as String),
  );
}

class PantryItem {
  PantryItem({
    required this.id,
    required this.ingredientName,
    required this.emoji,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiresAt,
  });

  final String id;
  final String ingredientName;
  final String emoji;
  final String category;
  final double quantity;
  final MeasureUnit unit;
  final DateTime? expiresAt;

  /// Bugünden kaç gün sonra bitiyor (tarih yoksa null)
  int? get daysLeft {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return day.difference(today).inDays;
  }

  bool get isUrgent => daysLeft != null && daysLeft! <= 3;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    id: json['id'] as String,
    ingredientName: json['ingredientName'] as String,
    emoji: json['ingredientEmoji'] as String,
    category: json['category'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: MeasureUnit.fromApi(json['unit'] as String),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
  );
}
