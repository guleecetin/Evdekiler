import '../pantry/pantry_models.dart';

// Fişte bulunan ve onay ekranında düzenlenebilen bir ürün
class ReceiptCandidate {
  ReceiptCandidate({
    required this.ingredientId,
    required this.name,
    required this.imageUrl,
    required this.highConfidence,
    required this.lines,
    required this.quantity,
    required this.unit,
  });

  final int ingredientId;
  final String name;
  final String imageUrl;
  final bool highConfidence;
  final List<String> lines; // fişteki orijinal satırlar

  // Kullanıcı onay ekranında değiştirebilir
  double quantity;
  MeasureUnit unit;
  bool selected = true;

  factory ReceiptCandidate.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredient'] as Map<String, dynamic>;
    return ReceiptCandidate(
      ingredientId: ingredient['id'] as int,
      name: ingredient['name'] as String,
      imageUrl: ingredient['imageUrl'] as String,
      highConfidence: json['confidence'] == 'High',
      lines: (json['lines'] as List).cast<String>(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: MeasureUnit.fromApi(json['unit'] as String),
    );
  }
}

class ReceiptScanResult {
  ReceiptScanResult({required this.items, required this.unmatched});

  final List<ReceiptCandidate> items;
  final List<String> unmatched;

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) =>
      ReceiptScanResult(
        items: (json['items'] as List)
            .map((e) => ReceiptCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        unmatched: (json['unmatched'] as List).cast<String>(),
      );
}
