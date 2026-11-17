import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/page_header.dart';
import 'recipe_models.dart';
import 'recipe_repository.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  RecipeCategory? _category; // null = Tümü

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(recipeSuggestionsProvider);
    final all = suggestions.maybeWhen(
      data: (l) => l,
      orElse: () => const <RecipeSuggestion>[],
    );
    final readyCount = all.where((r) => r.isReady).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: RefreshIndicator(
            color: Brand.forest,
            onRefresh: () => ref.refresh(recipeSuggestionsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PageHeader(
                    title: 'Tarifler',
                    subtitle: 'Buzdolabındakilere göre sıraladık',
                    icon: Icons.restaurant_menu_rounded,
                    chips: [
                      if (all.isNotEmpty)
                        HeaderChip(
                          icon: Icons.menu_book_rounded,
                          text: '${all.length} tarif',
                        ),
                      if (readyCount > 0)
                        HeaderChip(
                          icon: Icons.check_circle_rounded,
                          text: '$readyCount hemen yapılabilir',
                        ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryChips(
                    selected: _category,
                    onSelected: (c) => setState(() => _category = c),
                  ),
                ),
                ...suggestions.when<List<Widget>>(
                  loading: () => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppLoader(
                        compact: true,
                        message: 'Tarifler hazırlanıyor…',
                      ),
                    ),
                  ],
                  error: (e, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Öneriler yüklenemedi: $e'),
                      ),
                    ),
                  ],
                  data: (list) {
                    final filtered = _category == null
                        ? list
                        : list.where((r) => r.category == _category).toList();

                    if (filtered.isEmpty) {
                      return [
                        SliverToBoxAdapter(
                          child: _EmptyCategory(category: _category),
                        ),
                      ];
                    }

                    return [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        sliver: SliverList.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _RecipeCard(recipe: filtered[i]),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Kategori çipleri ───────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final RecipeCategory? selected;
  final ValueChanged<RecipeCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <RecipeCategory?>[null, ...RecipeCategory.values];

    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = items[i];
          final active = c == selected;
          final fg = c?.foreground ?? Brand.forest;

          return GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active ? fg : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? fg : Brand.border),
              ),
              child: Row(
                children: [
                  Icon(
                    c?.icon ?? Icons.grid_view_rounded,
                    size: 16,
                    color: active ? Colors.white : fg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c?.label ?? 'Tümü',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tarif kartı ────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final tag = 'list-${recipe.id}';
    final c = recipe.category;

    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}?hero=$tag'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Brand.forest.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(recipe.imageUrl, fallbackEmoji: recipe.emoji),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x55000000)],
                            stops: [0.6, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: recipe.isReady
                            ? const _Pill(
                                text: 'Hemen yapılabilir',
                                icon: Icons.check_rounded,
                                background: Brand.forest,
                                foreground: Colors.white,
                                iconColor: Brand.gold,
                              )
                            : _Pill(
                                text:
                                    '${recipe.haveCount}/${recipe.requiredCount} malzeme evde',
                                background: Colors.white,
                                foreground: AppColors.ink,
                              ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: _Pill(
                          text: c.label,
                          icon: c.icon,
                          background: c.background,
                          foreground: c.foreground,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _Pill(
                          text: '${recipe.prepMinutes} dk',
                          icon: Icons.schedule_rounded,
                          background: Colors.black.withValues(alpha: 0.45),
                          foreground: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Brand.forest,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        recipe.isReady
                            ? Icons.check_circle_rounded
                            : Icons.shopping_basket_outlined,
                        size: 15,
                        color: recipe.isReady
                            ? AppColors.basil
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.isReady
                              ? 'Tüm malzemeler evde'
                              : 'Eksik: ${recipe.missing.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: recipe.isReady
                                ? AppColors.basil
                                : AppColors.muted,
                            fontWeight: recipe.isReady
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings} kişilik',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconColor,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});

  final RecipeCategory? category;

  @override
  Widget build(BuildContext context) {
    final c = category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: c?.background ?? Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Brand.forest.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(
              c?.icon ?? Icons.kitchen_outlined,
              size: 40,
              color: c?.foreground ?? AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            c == null ? 'Henüz öneri yok' : '${c.label} önerisi yok',
            style: brandDisplay(20),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buzdolabındakilerle eşleşen tarif bulamadık.\nBirkaç malzeme daha eklemeyi dene.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              height: 1.4,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
