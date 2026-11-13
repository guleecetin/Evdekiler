import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import '../shopping/shopping_repository.dart';
import 'recipe_models.dart';
import 'recipe_repository.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = ref.watch(recipeDetailProvider(id));
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

    return Scaffold(
      body: recipe.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Tarif yüklenemedi: $e')),
        data: (r) => _RecipeBody(recipe: r, available: available),
      ),
      bottomNavigationBar: missing.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tomato,
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text('Eksikleri listeye ekle (${missing.length})'),
                  onPressed: () => _addMissing(context, ref, missing),
                ),
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
            onPressed: () => router.go('/shopping'),
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _RecipeBody extends StatelessWidget {
  const _RecipeBody({required this.recipe, required this.available});

  final RecipeDetail recipe;
  final Set<int> available;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final required = recipe.ingredients.where((i) => !i.isOptional).toList();
    final haveCount = required
        .where((i) => available.contains(i.ingredientId))
        .length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.basil,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              recipe.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.basil, AppColors.basilDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 96)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList.list(
            children: [
              Text(
                recipe.description,
                style: text.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: '${recipe.prepMinutes} dk',
                  ),
                  _InfoChip(
                    icon: Icons.people_outline_rounded,
                    label: '${recipe.servings} kişilik',
                  ),
                  _InfoChip(
                    icon: Icons.kitchen_rounded,
                    label: '$haveCount/${required.length} malzeme evde',
                    highlight: haveCount == required.length,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Malzemeler',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    for (final i in recipe.ingredients)
                      _IngredientRow(
                        ingredient: i,
                        inPantry: available.contains(i.ingredientId),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Hazırlanışı',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (var n = 0; n < recipe.steps.length; n++)
                _StepRow(number: n + 1, text: recipe.steps[n]),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.basil : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.inPantry});

  final RecipeIngredient ingredient;
  final bool inPantry;

  @override
  Widget build(BuildContext context) {
    final color = inPantry
        ? AppColors.basil
        : (ingredient.isOptional ? Colors.grey : AppColors.tomato);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            inPantry
                ? Icons.check_circle_rounded
                : Icons.add_shopping_cart_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: ingredient.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                children: [
                  if (ingredient.isOptional)
                    const TextSpan(
                      text: '  isteğe bağlı',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            formatQuantity(ingredient.quantity, ingredient.unit),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.basil,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
