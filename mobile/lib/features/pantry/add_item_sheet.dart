import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_image.dart';
import '../recipes/recipe_repository.dart';
import 'pantry_models.dart';
import 'pantry_repository.dart';

const _forest = Color(0xFF1D3A2A);
const _forestDeep = Color(0xFF122A1C);
const _gold = Color(0xFFD8BD82);
const _cream = Color(0xFFF7F3EA);
const _border = Color(0xFFE6E1D8);

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

// Backend'deki IngredientCategory enum adları → ekranda görünen adlar
const _categories = <(String?, String)>[
  (null, 'Tümü'),
  ('Vegetable', 'Sebze'),
  ('Fruit', 'Meyve'),
  ('Dairy', 'Süt & Yumurta'),
  ('Meat', 'Et & Tavuk'),
  ('Grain', 'Tahıl'),
  ('Legume', 'Bakliyat'),
  ('Spice', 'Baharat'),
  ('Other', 'Diğer'),
];

const _herbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 260" fill="none" stroke="#D8BD82" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
<path d="M30 250C80 200 120 140 150 40"/>
<path d="M140 72c-30-6-48-24-52-50 28 4 46 22 52 50Z"/>
<path d="M150 64c26-14 50-14 70 0-22 16-46 16-70 0Z"/>
<path d="M118 128c-32 0-54-14-66-40 30-2 52 12 66 40Z"/>
<path d="M128 118c22-22 46-28 72-20-16 24-40 30-72 20Z"/>
<path d="M90 180c-30 6-56-2-74-24 28-8 54 0 74 24Z"/>
<path d="M100 168c16-26 38-38 66-36-12 28-34 40-66 36Z"/>
</svg>''';

String _imageFor(Ingredient i) => '/images/ingredients/${i.id}.jpg';

String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

// Temadan gelen kutu/çizgi stillerini tamamen kapatan sade alan
const _bareInput = InputDecoration(
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  filled: false,
  isDense: true,
  contentPadding: EdgeInsets.zero,
  hintText: '0',
);

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  // Tek giriş noktası: nereden açılırsa açılsın alt çubuğun ÜSTÜNDE açılır
  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddItemSheet(),
  );

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _quantityController = TextEditingController(text: '1');

  Ingredient? _ingredient;
  MeasureUnit _unit = MeasureUnit.piece;
  DateTime? _expiresAt;
  int?
  _preset; // null = tarih yok, -1 = takvimden seçildi, diğerleri = gün sayısı
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Birime göre mantıklı artış miktarı
  double get _step => switch (_unit.label) {
    'g' || 'gr' || 'ml' => 50,
    'kg' || 'l' || 'L' || 'lt' => 0.5,
    _ => 1,
  };

  double? get _quantity =>
      double.tryParse(_quantityController.text.replaceAll(',', '.'));

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString().replaceAll('.', ',');

  void _changeQuantity(int direction) {
    final next = (_quantity ?? 0) + direction * _step;
    if (next <= 0) return;
    _quantityController.text = _fmt(next);
    setState(() => _error = null);
  }

  void _select(Ingredient i) {
    FocusScope.of(context).unfocus(); // klavyeyi kapat
    setState(() {
      _ingredient = i;
      _unit = i.defaultUnit;
      _error = null;
    });
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _setPreset(int? days) => setState(() {
    _preset = days;
    _expiresAt = days == null ? null : _today.add(Duration(days: days));
  });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? _today.add(const Duration(days: 3)),
      firstDate: _today.subtract(const Duration(days: 30)),
      lastDate: _today.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _preset = -1;
        _expiresAt = picked;
      });
    }
  }

  Future<void> _save() async {
    final quantity = _quantity;
    if (_ingredient == null) {
      setState(() => _error = 'Önce bir malzeme seç.');
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Geçerli bir miktar gir.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    // await'ten önce al: pencere kapanınca context artık kullanılamaz
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _ingredient!.name;

    try {
      await ref
          .read(pantryRepositoryProvider)
          .addItem(
            ingredientId: _ingredient!.id,
            quantity: quantity,
            unit: _unit,
            expiresAt: _expiresAt,
          );
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(recipeSuggestionsProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('$name buzdolabına eklendi')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      // Klavye açılınca pencere yukarı kaysın
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Malzeme'),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _ingredient == null
                          ? _IngredientPicker(
                              key: const ValueKey('picker'),
                              onSelected: _select,
                            )
                          : _SelectedIngredient(
                              key: ValueKey(_ingredient!.id),
                              ingredient: _ingredient!,
                              onChange: () =>
                                  setState(() => _ingredient = null),
                            ),
                    ),
                    const SizedBox(height: 16),
                    const _Label('Miktar'),
                    _QuantityStepper(
                      controller: _quantityController,
                      unitLabel: _unit.label,
                      onMinus: () => _changeQuantity(-1),
                      onPlus: () => _changeQuantity(1),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final u in MeasureUnit.values)
                          _Pill(
                            label: u.label,
                            active: u == _unit,
                            onTap: () => setState(() => _unit = u),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const _Label('Son kullanma'),
                        const Spacer(),
                        if (_expiresAt != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              _formatDate(_expiresAt!),
                              style: const TextStyle(
                                color: AppColors.basil,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          label: 'Yok',
                          active: _preset == null,
                          onTap: () => _setPreset(null),
                        ),
                        for (final (days, label) in const [
                          (1, 'Yarın'),
                          (3, '3 gün'),
                          (7, '1 hafta'),
                          (14, '2 hafta'),
                        ])
                          _Pill(
                            label: label,
                            active: _preset == days,
                            onTap: () => _setPreset(days),
                          ),
                        _Pill(
                          label: 'Tarih seç',
                          icon: Icons.calendar_month_rounded,
                          active: _preset == -1,
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                    if (_error != null) _ErrorBox(_error!),
                    const SizedBox(height: 20),
                    _SubmitButton(
                      isSaving: _isSaving,
                      label: _ingredient == null
                          ? 'Buzdolabına ekle'
                          : '${_ingredient!.name} ekle',
                      onPressed: _isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14 + media.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Üst şerit ──────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5A40), _forest, _forestDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -10,
            width: 130,
            child: Opacity(opacity: 0.14, child: SvgPicture.string(_herbSvg)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 6, 14),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.kitchen_rounded,
                        color: _gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buzdolabına ekle',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Ne aldın? Hemen yerleştirelim.',
                            style: TextStyle(
                              color: _gold.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      tooltip: 'Kapat',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: _forest.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Malzeme seçici: arama + kategori + fotoğraflı ızgara ───

class _IngredientPicker extends ConsumerStatefulWidget {
  const _IngredientPicker({super.key, required this.onSelected});

  final ValueChanged<Ingredient> onSelected;

  @override
  ConsumerState<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends ConsumerState<_IngredientPicker> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _category;
  late Future<List<Ingredient>> _future = _load();

  // Boşken tüm katalog (kategoriye göre), yazınca arama
  Future<List<Ingredient>> _load() => ref
      .read(pantryRepositoryProvider)
      .searchIngredients(
        _query,
        category: _query.isEmpty ? _category : null,
        limit: _query.isEmpty ? 200 : 40,
      );

  void _reload() => setState(() => _future = _load());

  // Her tuşta istek atma: yazmayı 250 ms bırakınca ara
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _query = value.trim();
      _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'Domates, süt, yumurta…',
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.muted,
              size: 20,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    onPressed: () {
                      _controller.clear();
                      _query = '';
                      _reload();
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: _cream,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: border(_border),
            enabledBorder: border(_border),
            focusedBorder: border(AppColors.basil, 1.5),
          ),
        ),
        if (_query.isEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (value, label) = _categories[i];
                return _Pill(
                  label: label,
                  active: _category == value,
                  onTap: () {
                    _category = value;
                    _reload();
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          height: 248,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: FutureBuilder<List<Ingredient>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.basil,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: _reload,
                    child: const Text('Yüklenemedi, tekrar dene'),
                  ),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Malzeme bulunamadı',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                );
              }
              return GridView.builder(
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (_, i) => _IngredientTile(
                  ingredient: list[i],
                  onTap: () => widget.onSelected(list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient, required this.onTap});

  final Ingredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: AppImage(_imageFor(ingredient), fallbackEmoji: '🥕'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ingredient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _forest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedIngredient extends StatelessWidget {
  const _SelectedIngredient({
    super.key,
    required this.ingredient,
    required this.onChange,
  });

  final Ingredient ingredient;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.basil.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: AppImage(_imageFor(ingredient), fallbackEmoji: '🥕'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _forest,
                  ),
                ),
                Text(
                  'Genelde ${ingredient.defaultUnit.label} olarak eklenir',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(foregroundColor: AppColors.basil),
            child: const Text(
              'Değiştir',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Miktar ─────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.controller,
    required this.unitLabel,
    required this.onMinus,
    required this.onPlus,
  });

  final TextEditingController controller;
  final String unitLabel;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _RoundButton(icon: Icons.remove_rounded, onTap: onMinus),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _forest,
                    ),
                    decoration: _bareInput,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unitLabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          _RoundButton(icon: Icons.add_rounded, onTap: onPlus, filled: true),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _forest : Colors.white,
      shape: CircleBorder(side: BorderSide(color: filled ? _forest : _border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: filled ? _gold : _forest),
        ),
      ),
    );
  }
}

// ─── Ortak parçalar ─────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _forest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _forest : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? _gold : AppColors.muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.tomato.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.tomato,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.tomato,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  final bool isSaving;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _forest,
          disabledBackgroundColor: _forest.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _gold,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: _gold, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
