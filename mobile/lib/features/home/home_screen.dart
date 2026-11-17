import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_logo.dart';
import '../auth/auth_controller.dart';
import '../pantry/add_item_sheet.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import '../receipts/receipt_reader.dart';
import '../recipes/recipe_models.dart';
import '../recipes/recipe_repository.dart';

const _forest = Color(0xFF1D3A2A);
const _forestDeep = Color(0xFF122A1C);
const _gold = Color(0xFFD8BD82);

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

const _categoryLabel = {
  'Vegetable': 'Sebze',
  'Fruit': 'Meyve',
  'Dairy': 'Süt & Yumurta',
  'Meat': 'Et & Tavuk',
  'Grain': 'Tahıl',
  'Legume': 'Bakliyat',
  'Spice': 'Baharat',
  'Other': 'Diğer',
};

(String, Color) expiryInfo(int days) => switch (days) {
  < 0 => ('Süresi geçti', const Color(0xFFC13515)),
  0 => ('Bugün', AppColors.tomato),
  1 => ('Yarın', AppColors.tomato),
  <= 3 => ('$days gün', AppColors.tomato),
  _ => ('$days gün', AppColors.basil),
};

TextStyle _display(double size, {Color color = _forest}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );

String _fold(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ç', 'c')
    .replaceAll('ğ', 'g')
    .replaceAll('ı', 'i')
    .replaceAll('ö', 'o')
    .replaceAll('ş', 's')
    .replaceAll('ü', 'u');

class _FridgeGroup {
  _FridgeGroup(this.items);

  final List<PantryItem> items;

  PantryItem get first => items.first;
  String get name => first.ingredientName;
  String get imageUrl => first.imageUrl;
  String get emoji => first.emoji;
  String get category => first.category;

  int? get daysLeft {
    final days = items.map((i) => i.daysLeft).whereType<int>();
    return days.isEmpty ? null : days.reduce(min);
  }

  String get quantityText {
    final sums = <MeasureUnit, double>{};
    for (final i in items) {
      sums[i.unit] = (sums[i.unit] ?? 0) + i.quantity;
    }
    return sums.entries.map((e) => formatQuantity(e.value, e.key)).join(' + ');
  }
}

List<_FridgeGroup> _groupItems(List<PantryItem> list) {
  final map = <int, List<PantryItem>>{};
  for (final item in list) {
    map.putIfAbsent(item.ingredientId, () => []).add(item);
  }

  final groups = map.values.map(_FridgeGroup.new).toList();
  groups.sort((a, b) {
    final da = a.daysLeft, db = b.daysLeft;
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return a.name.compareTo(b.name);
  });
  return groups;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _category;
  String _query = '';

  // Alt çubuğun ÜSTÜNDE açılır (useRootNavigator AddItemSheet.show içinde)
  void _openAddSheet() => AddItemSheet.show(context);

  @override
  Widget build(BuildContext context) {
    final name = ref
        .watch(currentUserProvider)
        .maybeWhen(
          data: (p) => p.displayName.split(' ').first,
          orElse: () => '',
        );
    final items = ref.watch(pantryItemsProvider);
    final suggestions = ref
        .watch(recipeSuggestionsProvider)
        .maybeWhen(data: (l) => l, orElse: () => const <RecipeSuggestion>[]);

    final list = items.maybeWhen(
      data: (l) => l,
      orElse: () => const <PantryItem>[],
    );
    final groupCount = _groupItems(list).length;
    final urgentCount = list.where((i) => i.isUrgent).length;
    final readyCount = suggestions.where((s) => s.isReady).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: RefreshIndicator(
            color: _forest,
            onRefresh: () => ref.refresh(pantryItemsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    name: name,
                    groupCount: groupCount,
                    urgentCount: urgentCount,
                    readyCount: readyCount,
                    onLogout: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    onAdd: _openAddSheet,
                    onScan: () => startReceiptScan(context, ref),
                  ),
                ),
                ...items.when<List<Widget>>(
                  loading: () => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoader(
                        compact: true,
                        message: 'Buzdolabın açılıyor…',
                      ),
                    ),
                  ],
                  error: (e, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('$e'),
                      ),
                    ),
                  ],
                  data: (list) => _content(list, suggestions),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    List<PantryItem> list,
    List<RecipeSuggestion> suggestions,
  ) {
    if (list.isEmpty) {
      return [SliverToBoxAdapter(child: _EmptyFridge(onAdd: _openAddSheet))];
    }

    final urgent = list.where((i) => i.isUrgent).toList();
    final groups = _groupItems(list);
    final categories = groups.map((g) => g.category).toSet().toList();

    final q = _fold(_query.trim());
    final filtered = groups.where((g) {
      if (_category != null && g.category != _category) return false;
      if (q.isNotEmpty && !_fold(g.name).contains(q)) return false;
      return true;
    }).toList();

    return [
      if (suggestions.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Bu akşam ne pişirsen?',
            subtitle: 'Buzdolabındakilere göre',
            action: 'Tümü',
            onAction: () => context.go('/recipes'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: min(6, suggestions.length),
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _RecipeMiniCard(recipe: suggestions[i]),
            ),
          ),
        ),
      ],
      if (urgent.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Önce bunları kullan',
            subtitle: 'Bozulmadan değerlendir',
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: urgent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _UrgentCard(item: urgent[i]),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: 'Buzdolabında',
          subtitle: '${groups.length} çeşit ürün',
        ),
      ),
      SliverToBoxAdapter(
        child: _FridgeSearch(onChanged: (v) => setState(() => _query = v)),
      ),
      SliverToBoxAdapter(
        child: _CategoryChips(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
      if (filtered.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Center(
              child: Text(
                'Aradığın ürün buzdolabında yok.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _GroupCard(group: filtered[i]),
              childCount: filtered.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
          ),
        ),
    ];
  }
}

// ─── Üst kısım: yeşil başlık alanı + taşan iki buton ─────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.groupCount,
    required this.urgentCount,
    required this.readyCount,
    required this.onLogout,
    required this.onAdd,
    required this.onScan,
  });

  final String name;
  final int groupCount;
  final int urgentCount;
  final int readyCount;
  final VoidCallback onLogout;
  final VoidCallback onAdd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Container(
              width: double.infinity,
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
                    right: -50,
                    top: top - 20,
                    width: 200,
                    child: Transform.flip(
                      flipX: true,
                      child: Opacity(
                        opacity: 0.13,
                        child: SvgPicture.string(_herbSvg),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 14, 16, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppLogo(size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name.isEmpty ? 'Merhaba' : 'Merhaba $name',
                                style: TextStyle(
                                  color: _gold.withValues(alpha: 0.95),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _ProfileMenu(name: name, onLogout: onLogout),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Buzdolabın',
                          style: _display(34, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              icon: Icons.kitchen_outlined,
                              text: '$groupCount çeşit ürün',
                            ),
                            if (urgentCount > 0)
                              _StatChip(
                                icon: Icons.schedule_rounded,
                                text: '$urgentCount tanesi acil',
                                dot: AppColors.tomato,
                              ),
                            if (readyCount > 0)
                              _StatChip(
                                icon: Icons.restaurant_rounded,
                                text: '$readyCount tarif hazır',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _QuickActions(onAdd: onAdd, onScan: onScan),
        ),
      ],
    );
  }
}

// Avatar + açılan profil menüsü
class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.name, required this.onLogout});

  final String name;
  final VoidCallback onLogout;

  Widget _avatar(double radius) => CircleAvatar(
    radius: radius,
    backgroundColor: _gold,
    child: Text(
      name.isEmpty ? '?' : name[0].toUpperCase(),
      style: const TextStyle(color: _forest, fontWeight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (_) => onLogout(),
      offset: const Offset(0, 50),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: _forest.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      constraints: const BoxConstraints(minWidth: 210),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false, // sadece bilgi, tıklanmaz
          child: Row(
            children: [
              _avatar(18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Hesabın' : name,
                    style: const TextStyle(
                      color: _forest,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const Text(
                    'Evdekiler hesabın',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tomato.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: AppColors.tomato,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Çıkış yap',
                style: TextStyle(
                  color: AppColors.tomato,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
        ),
        child: _avatar(18),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text, this.dot});

  final IconData icon;
  final String text;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            )
          else
            Icon(icon, size: 15, color: _gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// İki net eylem: tek simge, tek kelime
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAdd, required this.onScan});

  final VoidCallback onAdd;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final shadow = [
      BoxShadow(
        color: _forest.withValues(alpha: 0.20),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ActionButton(
            label: 'Malzeme ekle',
            icon: Icons.add_rounded,
            background: Colors.white,
            foreground: _forest,
            iconColor: AppColors.basil,
            shadow: shadow,
            onTap: onAdd,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _ActionButton(
            label: 'Fiş okut',
            icon: Icons.receipt_long_rounded,
            background: _forest,
            foreground: Colors.white,
            iconColor: _gold,
            border: _gold.withValues(alpha: 0.5),
            shadow: shadow,
            onTap: onScan,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.iconColor,
    required this.shadow,
    required this.onTap,
    this.border,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color iconColor;
  final Color? border;
  final List<BoxShadow> shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: shadow,
      ),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: border == null ? BorderSide.none : BorderSide(color: border!),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FridgeSearch extends StatelessWidget {
  const _FridgeSearch({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: c, width: w),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buzdolabında ara…',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.85),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: border(const Color(0xFFE6E1D8)),
          enabledBorder: border(const Color(0xFFE6E1D8)),
          focusedBorder: border(AppColors.basil, 1.5),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _display(22)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.basil),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tarif şeridi ───────────────────────────────────────────

class _RecipeMiniCard extends StatelessWidget {
  const _RecipeMiniCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final tag = 'home-${recipe.id}';
    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}?hero=$tag'),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 160,
                  width: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(recipe.imageUrl, fallbackEmoji: recipe.emoji),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x66000000)],
                            stops: [0.55, 1],
                          ),
                        ),
                      ),
                      if (recipe.isReady)
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: _Badge('Hemen yapılabilir'),
                        ),
                      Positioned(
                        bottom: 10,
                        left: 12,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.prepMinutes} dk',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: _forest,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              recipe.isReady
                  ? 'Malzemeler evde'
                  : '${recipe.missing.length} malzeme eksik',
              style: TextStyle(
                color: recipe.isReady ? AppColors.basil : AppColors.muted,
                fontSize: 13,
                fontWeight: recipe.isReady ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _forest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: _gold),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Acil ürünler ───────────────────────────────────────────

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color) = expiryInfo(item.daysLeft!);
    return Container(
      width: 244,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _forest.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(width: 5, color: color),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: AppImage(item.imageUrl, fallbackEmoji: item.emoji),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ingredientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _forest,
                    ),
                  ),
                  Text(
                    formatQuantity(item.quantity, item.unit),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kategori çipleri ───────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String?, String)>[
      (null, 'Tümü'),
      for (final c in categories) (c, _categoryLabel[c] ?? c),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = tabs[i];
          final active = selected == value;
          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _forest : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _forest : const Color(0xFFE6E1D8),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Gruplanmış ürün kartı ──────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _FridgeGroup group;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true, // alt çubuğun üstünde açılsın
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => _BatchSheet(group: group),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _forest.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppImage(group.imageUrl, fallbackEmoji: group.emoji),
                  ),
                  if (group.daysLeft != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _ExpiryPill(days: group.daysLeft!),
                    ),
                  if (group.items.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _forest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${group.items.length} parti',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _forest,
                    ),
                  ),
                  Text(
                    group.quantityText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchSheet extends ConsumerWidget {
  const _BatchSheet({required this.group});

  final _FridgeGroup group;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PantryItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(pantryRepositoryProvider).deleteItem(item.id);
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(recipeSuggestionsProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${group.name} buzdolabından çıkarıldı')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = [...group.items]
      ..sort((a, b) => (a.daysLeft ?? 9999).compareTo(b.daysLeft ?? 9999));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: AppImage(group.imageUrl, fallbackEmoji: group.emoji),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: _display(22)),
                      Text(
                        'Toplam ${group.quantityText}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Partiler',
              style: TextStyle(fontWeight: FontWeight.w800, color: _forest),
            ),
            const SizedBox(height: 4),
            for (final item in batches)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatQuantity(item.quantity, item.unit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (item.daysLeft != null)
                      _ExpiryPill(days: item.daysLeft!, outlined: true),
                    if (item.daysLeft == null)
                      const Text(
                        'Tarih yok',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    IconButton(
                      onPressed: () => _delete(context, ref, item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.muted,
                      ),
                      tooltip: 'Bu partiyi çıkar',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({required this.days, this.outlined = false});

  final int days;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final (label, color) = expiryInfo(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: AppColors.line) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
      child: Column(
        children: [
          const AppLogo(size: 72),
          const SizedBox(height: 18),
          Text('Buzdolabın bomboş', style: _display(24)),
          const SizedBox(height: 8),
          const Text(
            'Evdeki malzemelerini ekle\nya da market fişini okut.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _forest,
              minimumSize: const Size(200, 52),
            ),
            child: const Text('İlk ürünü ekle'),
          ),
        ],
      ),
    );
  }
}
