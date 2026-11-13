import 'package:flutter/material.dart';

enum MeasureUnit {
  piece('Piece', 'adet'),
  gram('Gram', 'g'),
  kilogram('Kilogram', 'kg'),
  milliliter('Milliliter', 'ml'),
  liter('Liter', 'L');

  const MeasureUnit(this.apiValue, this.label);
  final String apiValue;
  final String label;

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

String formatQuantity(double quantity, MeasureUnit unit) {
  final q = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString().replaceAll('.', ',');
  return '$q ${unit.label}';
}

class Ingredient {
  Ingredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imageUrl,
    required this.category,
    required this.defaultUnit,
  });

  final int id;
  final String name;
  final String emoji;
  final String imageUrl;
  final String category;
  final MeasureUnit defaultUnit;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'] as int,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    imageUrl: json['imageUrl'] as String,
    category: json['category'] as String,
    defaultUnit: MeasureUnit.fromApi(json['defaultUnit'] as String),
  );
}

class PantryItem {
  PantryItem({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.emoji,
    required this.imageUrl,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiresAt,
  });

  final String id;
  final int ingredientId;
  final String ingredientName;
  final String emoji;
  final String imageUrl;
  final String category;
  final double quantity;
  final MeasureUnit unit;
  final DateTime? expiresAt;

  int? get daysLeft {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(expiresAt!.year, expiresAt!.month, expiresAt!.day);
    return day.difference(today).inDays;
  }

  bool get isUrgent => daysLeft != null && daysLeft! <= 3;
  bool get isExpired => daysLeft != null && daysLeft! < 0;

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    id: json['id'] as String,
    ingredientId: json['ingredientId'] as int,
    ingredientName: json['ingredientName'] as String,
    emoji: json['ingredientEmoji'] as String,
    imageUrl: json['imageUrl'] as String,
    category: json['category'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: MeasureUnit.fromApi(json['unit'] as String),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
  );
}
