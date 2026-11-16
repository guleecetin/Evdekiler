import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import 'receipt_repository.dart';
import 'receipt_review_screen.dart';

// Ana sayfadaki fiş butonu bunu çağırır
Future<void> startReceiptScan(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const _SourceSheet(),
  );
  if (source == null || !context.mounted) return;

  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2400,
    imageQuality: 95,
  );
  if (file == null || !context.mounted) return;

  // Alt menü çubuğu görünmesin diye en üstteki navigator
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ReadingDialog(),
  );

  try {
    final lines = await readReceiptLines(file.path);
    if (lines.isEmpty) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Fotoğrafta yazı bulamadık. Fişi düz bir zemine koyup yakından çek.',
          ),
        ),
      );
      return;
    }

    final result = await ref.read(receiptRepositoryProvider).parse(lines);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => ReceiptReviewScreen(result: result)),
    );
  } on ApiException catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Fiş okunamadı, tekrar dener misin?')),
    );
  }
}

// ML Kit ile fotoğraftaki yazıları okur ve fiş satırlarına dönüştürür
Future<List<String>> readReceiptLines(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final recognized = await recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    final parts = [
      for (final block in recognized.blocks)
        for (final line in block.lines)
          (rect: line.boundingBox, text: line.text),
    ];
    return groupIntoRows(parts);
  } finally {
    await recognizer.close();
  }
}

// ML Kit fişi sütunlar halinde okuyabilir ("DOMATES KG" solda, "*31,13" sağda ayrı blok).
// Aynı yükseklikteki parçaları soldan sağa birleştirerek fişin satırlarını yeniden kuruyoruz.
List<String> groupIntoRows(List<({Rect rect, String text})> parts) {
  final sorted = [...parts]
    ..sort((a, b) => a.rect.center.dy.compareTo(b.rect.center.dy));
  final rows = <List<({Rect rect, String text})>>[];

  for (final part in sorted) {
    if (rows.isNotEmpty) {
      final row = rows.last;
      final rowCenter =
          row.map((p) => p.rect.center.dy).reduce((a, b) => a + b) / row.length;
      // Dikey merkezleri satır yüksekliğinin yarısından yakınsa aynı satırdır
      if ((part.rect.center.dy - rowCenter).abs() < part.rect.height * 0.6) {
        row.add(part);
        continue;
      }
    }
    rows.add([part]);
  }

  return rows
      .map((row) {
        row.sort((a, b) => a.rect.left.compareTo(b.rect.left));
        final text = row.map((p) => p.text).join(' ').trim();
        return text.length > 200
            ? text.substring(0, 200)
            : text; // backend sınırı
      })
      .where((t) => t.isNotEmpty)
      .take(300)
      .toList();
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fişi okut',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fişi düz bir zemine koy, ışık iyi olsun ve sadece ürünler kadraja girsin.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              title: 'Fotoğraf çek',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Galeriden seç',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.basil),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ReadingDialog extends StatelessWidget {
  const _ReadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Fiş okunuyor…',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Ürünleri buzdolabı kataloğuyla eşleştiriyoruz',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
