import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_image.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import '../recipes/recipe_repository.dart';
import 'receipt_models.dart';
import 'receipt_repository.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  const ReceiptReviewScreen({super.key, required this.result});

  final ReceiptScanResult result;

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late final List<ReceiptCandidate> _items = [...widget.result.items];
  late final List<String> _unmatched = [...widget.result.unmatched];
  bool _saving = false;

  List<ReceiptCandidate> get _selected =>
      _items.where((i) => i.selected).toList();

  // Tanınmayan satıra malzeme seç → listeye ekle, sistem öğrensin
  Future<void> _resolve(String line) async {
    final ingredient = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _IngredientPicker(line: line),
    );
    if (ingredient == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final candidate = await ref
          .read(receiptRepositoryProvider)
          .resolve(line, ingredient.id);
      setState(() {
        _unmatched.remove(line);
        _items.add(candidate);
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Eklendi. Bu yazılışı öğrenmemiz için öneri olarak kaydettik 🧠',
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editQuantity(ReceiptCandidate item) async {
    final controller = TextEditingController(
      text: item.quantity
          .toString()
          .replaceAll(RegExp(r'\.0$'), '')
          .replaceAll('.', ','),
    );
    var unit = item.unit;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(item.name),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Miktar'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<MeasureUnit>(
                value: unit,
                items: [
                  for (final u in MeasureUnit.values)
                    DropdownMenuItem(value: u, child: Text(u.label)),
                ],
                onChanged: (u) => setDialogState(() => unit = u ?? unit),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    final value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (saved == true && value != null && value > 0) {
      setState(() {
        item.quantity = value;
        item.unit = unit;
      });
    }
  }

  Future<void> _save() async {
    final selected = _selected;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(receiptRepositoryProvider).addAll(selected);
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(recipeSuggestionsProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${selected.length} ürün buzdolabına eklendi 🧊'),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;
    final nothing = _items.isEmpty && _unmatched.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Fiş sonuçları',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: nothing
          ? const _NothingFound()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  _items.isEmpty
                      ? 'Ürün tanıyamadık'
                      : 'Fişinde ${_items.length} ürün bulduk',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Eklemek istemediklerinin işaretini kaldır, miktara dokunarak düzelt.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                for (final item in _items) ...[
                  _CandidateTile(
                    item: item,
                    onToggle: () =>
                        setState(() => item.selected = !item.selected),
                    onEditQuantity: () => _editQuantity(item),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_unmatched.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Tanıyamadıklarımız (${_unmatched.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bir ürünse dokun ve seç; uygulama bu yazılışı öğrensin.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  for (final line in _unmatched)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _resolve(line),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.line,
                              style: BorderStyle.solid,
                            ),
                            color: const Color(0xFFFAFAFA),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppColors.basil,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Ürünü seç',
                                style: TextStyle(
                                  color: AppColors.basil,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: FilledButton(
                    onPressed: selectedCount == 0 || _saving ? null : _save,
                    child: Text(
                      _saving
                          ? 'Ekleniyor…'
                          : 'Buzdolabına ekle ($selectedCount)',
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Malzeme seçici (tanınmayan satır için) ─────────────────

class _IngredientPicker extends ConsumerStatefulWidget {
  const _IngredientPicker({required this.line});

  final String line;

  @override
  ConsumerState<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends ConsumerState<_IngredientPicker> {
  List<Ingredient> _results = [];
  Timer? _debounce;
  bool _loading = false;

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _loading = true);
      try {
        final results = await ref
            .read(pantryRepositoryProvider)
            .searchIngredients(query.trim());
        if (mounted) setState(() => _results = results);
      } catch (_) {
        if (mounted) setState(() => _results = []);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Klavye açılınca sayfa yukarı kaysın
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu hangi ürün?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.line,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Malzeme ara… (ör. çay)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final ing = _results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: AppImage(
                            ing.imageUrl,
                            fallbackEmoji: ing.emoji,
                          ),
                        ),
                      ),
                      title: Text(
                        ing.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, ing),
                    );
                  },
                ),
              ),
              const Text(
                'Aradığın ürün yoksa katalogda henüz bulunmuyor; yakında eklenecek.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ürün satırı ────────────────────────────────────────────

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.item,
    required this.onToggle,
    required this.onEditQuantity,
  });

  final ReceiptCandidate item;
  final VoidCallback onToggle;
  final VoidCallback onEditQuantity;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: item.selected ? 1 : 0.45,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.selected ? AppColors.basil : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.selected ? AppColors.basil : Colors.white,
                  border: Border.all(
                    color: item.selected
                        ? AppColors.basil
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: item.selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: AppImage(item.imageUrl, fallbackEmoji: '🛒'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!item.highConfidence) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Kontrol et',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.lines.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEditQuantity,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(formatQuantity(item.quantity, item.unit)),
                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NothingFound extends StatelessWidget {
  const _NothingFound();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Fişte tanıdığımız bir ürün bulamadık',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Fişi düz bir zemine koyup, iyi ışıkta ve yakından tekrar çekmeyi dene.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
