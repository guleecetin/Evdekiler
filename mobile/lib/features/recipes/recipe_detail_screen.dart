import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_image.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import '../shopping/shopping_repository.dart';
import 'recipe_models.dart';
import 'recipe_repository.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({
    super.key,
    required this.id,
    required this.heroTag,
  });

  final int id;
  final String heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeDetailProvider(id));

    // Fotoğraf adresi: önce zaten yüklü olan öneri listesinden (animasyon için hemen lazım)
    final imageUrl =
        ref
            .watch(recipeSuggestionsProvider)
            .maybeWhen(
              data: (list) {
                for (final s in list) {
                  if (s.id == id) return s.imageUrl;
                }
                return null;
              },
              orElse: () => null,
            ) ??
        recipe.value?.imageUrl ??
        '';

    final available = ref
        .watch(pantryItemsProvider)
        .maybeWhen(
          data: (items) => items
              .where((i) => !i.isExpired)
              .map((i) => i.ingredientId)
              .toSet(),
          orElse: () => <int>{},
        );
    final missing = recipe.maybeWhen(
      data: (r) => r.ingredients
          .where((i) => !i.isOptional && !available.contains(i.ingredientId))
          .toList(),
      orElse: () => <RecipeIngredient>[],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(tag: heroTag, child: AppImage(imageUrl)),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: recipe.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Tarif yüklenemedi: $e'),
                    data: (r) => _Content(recipe: r, available: available),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: missing.isEmpty
            ? null
            : _BottomBar(
                missingCount: missing.length,
                onPressed: () => _addMissing(context, ref, missing),
              ),
      ),
    );
  }

  Future<void> _addMissing(
    BuildContext context,
    WidgetRef ref,
    List<RecipeIngredient> missing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(shoppingRepositoryProvider).addItems([
        for (final i in missing)
          (
            ingredientId: i.ingredientId,
            name: i.name,
            quantity: i.quantity,
            unit: i.unit,
          ),
      ]);
      ref.invalidate(shoppingItemsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${missing.length} ürün alışveriş listene eklendi 🛒'),
          action: SnackBarAction(
            label: 'Listeye git',
            textColor: Colors.white,
            onPressed: () => router.go('/shopping'),
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.recipe, required this.available});

  final RecipeDetail recipe;
  final Set<int> available;

  @override
  Widget build(BuildContext context) {
    final required = recipe.ingredients.where((i) => !i.isOptional).toList();
    final have = required
        .where((i) => available.contains(i.ingredientId))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${recipe.prepMinutes} dk · ${recipe.servings} kişilik · $have/${required.length} malzeme evde',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        Text(
          recipe.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const Divider(height: 48),
        const Text(
          'Malzemeler',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final i in recipe.ingredients)
          _IngredientRow(
            ingredient: i,
            inPantry: available.contains(i.ingredientId),
          ),
        const Divider(height: 48),
        const Text(
          'Hazırlanışı',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (var n = 0; n < recipe.steps.length; n++)
          _StepRow(number: n + 1, text: recipe.steps[n]),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.inPantry});

  final RecipeIngredient ingredient;
  final bool inPantry;

  @override
  Widget build(BuildContext context) {
    final status = inPantry
        ? ('Evde', AppColors.basil)
        : (ingredient.isOptional
              ? ('İsteğe bağlı', AppColors.muted)
              : ('Eksik', AppColors.tomato));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: AppImage(ingredient.imageUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  formatQuantity(ingredient.quantity, ingredient.unit),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            status.$1,
            style: TextStyle(
              color: status.$2,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Text(
              '$number',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.missingCount, required this.onPressed});

  final int missingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$missingCount malzeme eksik',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Alışveriş listene ekleyebilirsin',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.tomato,
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: const Text('Listeye ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
