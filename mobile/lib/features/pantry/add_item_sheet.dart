import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import 'pantry_models.dart';
import 'pantry_repository.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _quantityController = TextEditingController(text: '1');

  Ingredient? _ingredient;
  MeasureUnit _unit = MeasureUnit.piece;
  DateTime? _expiresAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? today.add(const Duration(days: 3)),
      firstDate: today.subtract(const Duration(days: 30)),
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    final quantity = double.tryParse(
      _quantityController.text.replaceAll(',', '.'),
    );

    if (_ingredient == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir malzeme seç ve geçerli bir miktar gir.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
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
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Klavye açılınca panel yukarı kaysın
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Buzdolabına ekle',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          Autocomplete<Ingredient>(
            displayStringForOption: (i) => i.name,
            optionsBuilder: (value) => ref
                .read(pantryRepositoryProvider)
                .searchIngredients(value.text),
            onSelected: (i) => setState(() {
              _ingredient = i;
              _unit = i.defaultUnit;
            }),
            fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
                TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Malzeme',
                    hintText: 'Örn. domates',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Miktar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<MeasureUnit>(
                  key: ValueKey(_unit),
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Birim'),
                  items: [
                    for (final u in MeasureUnit.values)
                      DropdownMenuItem(value: u, child: Text(u.label)),
                  ],
                  onChanged: (u) => setState(() => _unit = u ?? _unit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded),
            label: Text(
              _expiresAt == null
                  ? 'Son kullanma tarihi (isteğe bağlı)'
                  : 'Son kullanma: ${_expiresAt!.day}.${_expiresAt!.month}.${_expiresAt!.year}',
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
