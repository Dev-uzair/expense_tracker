import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const int maxCategoryNameLength = 30;

// FR-CAT-005: required, at most 30 characters, unique within its type.
String? validateCategoryName(
  String? value, {
  required String type,
  required List<Category> existing,
  String? editingId,
}) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Please enter a name';
  if (name.length > maxCategoryNameLength) {
    return 'At most $maxCategoryNameLength characters';
  }
  final taken = existing.any(
    (c) =>
        c.id != editingId &&
        c.type == type &&
        c.name.trim().toLowerCase() == name.toLowerCase(),
  );
  if (taken) return 'Another $type category already has this name';
  return null;
}

// Adds a category, or edits/deletes [category] when one is given.
class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? category;
  final String initialType;

  const CategoryFormScreen({
    super.key,
    this.category,
    this.initialType = 'expense',
  });

  bool get isEditing => category != null;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _type;
  late String _icon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name);
    _type = c?.type ?? widget.initialType;
    _icon = categoryIcons.containsKey(c?.categoryIcon)
        ? c!.categoryIcon!
        : 'tag';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<Category> get _allCategories =>
      ref.read(categoryNotifierProvider).value ?? const [];

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(categoryNotifierProvider.notifier);
    final name = _nameController.text.trim();

    setState(() => _saving = true);
    try {
      if (widget.category case final existing?) {
        await notifier.updateCategory(
          existing.copyWith(name: name, categoryIcon: _icon),
        );
      } else {
        await notifier.addCategory(
          Category(
            id: const Uuid().v4(),
            name: name,
            type: _type,
            categoryIcon: _icon,
          ),
        );
      }
      if (!mounted) return;
      _showMessage(widget.isEditing ? 'Category updated' : 'Category added');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Failed to save category: $e');
    }
  }

  Future<void> _delete() async {
    final category = widget.category!;
    final sameType =
        _allCategories
            .where((c) => c.type == category.type && c.id != category.id)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    if (sameType.isEmpty) {
      _showMessage(
        'You need at least one ${category.type} category, so this one '
        "can't be deleted.",
      );
      return;
    }

    final transactions =
        ref.read(transactionNotifierProvider).value ?? const [];
    final inUse = transactions.where((t) => t.categoryId == category.id).length;

    // FR-CAT-008/009: transactions must be moved to another category first.
    final moveTo = await showDialog<Category>(
      context: context,
      builder: (context) => _DeleteCategoryDialog(
        category: category,
        transactionCount: inUse,
        candidates: sameType,
      ),
    );
    if (moveTo == null || !mounted) return;

    try {
      if (inUse > 0) {
        await ref
            .read(transactionNotifierProvider.notifier)
            .reassignCategory(category.id, moveTo.id);
      }
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);
      if (!mounted) return;
      _showMessage(
        inUse > 0
            ? 'Category deleted; $inUse transaction(s) moved to ${moveTo.name}'
            : 'Category deleted',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showMessage('Failed to delete category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Category' : 'Add Category'),
        backgroundColor: colors.inversePrimary,
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              maxLength: maxCategoryNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => validateCategoryName(
                value,
                type: _type,
                existing: _allCategories,
                editingId: widget.category?.id,
              ),
            ),
            const SizedBox(height: 12),
            // Changing the type of an existing category would leave its
            // transactions under the wrong type, so it is fixed once created.
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: widget.isEditing
                  ? null
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            Text('Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: key, value: icon)
                    in categoryIcons.entries)
                  Semantics(
                    label: key,
                    selected: key == _icon,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _icon = key),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: key == _icon ? colors.primaryContainer : null,
                          border: Border.all(
                            color: key == _icon
                                ? colors.primary
                                : colors.outlineVariant,
                            width: key == _icon ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteCategoryDialog extends StatefulWidget {
  final Category category;
  final int transactionCount;
  final List<Category> candidates;

  const _DeleteCategoryDialog({
    required this.category,
    required this.transactionCount,
    required this.candidates,
  });

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  late Category _moveTo = widget.candidates.firstWhere(
    (c) => c.name.toLowerCase().startsWith('other'),
    orElse: () => widget.candidates.first,
  );

  @override
  Widget build(BuildContext context) {
    final count = widget.transactionCount;
    return AlertDialog(
      title: Text('Delete "${widget.category.name}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count == 0)
            const Text('No transactions use this category.')
          else ...[
            Text('$count transaction(s) use this category. Move them to:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              initialValue: _moveTo,
              isExpanded: true,
              items: [
                for (final c in widget.candidates)
                  DropdownMenuItem(value: c, child: Text(c.name)),
              ],
              onChanged: (c) => setState(() => _moveTo = c!),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(_moveTo),
          child: Text(count == 0 ? 'Delete' : 'Move and delete'),
        ),
      ],
    );
  }
}
