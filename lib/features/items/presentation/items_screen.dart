import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatting/brl_money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import 'items_cubit.dart';

/// `/dashboard/lists/:id/items` — item CRUD, allow-partial toggle, ordering.
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final _ItemFormResult? result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => const _ItemDialog(),
    );
    if (result != null && context.mounted) {
      context.read<ItemsCubit>().add(
        NewItem(
          title: result.title,
          targetAmountCents: result.amountCents,
          allowPartial: result.allowPartial,
          description: result.description,
        ),
      );
    }
  }

  Future<void> _edit(BuildContext context, GiftItem item) async {
    final _ItemFormResult? result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => _ItemDialog(item: item),
    );
    if (result != null && context.mounted) {
      context.read<ItemsCubit>().edit(
        item.id,
        ItemUpdate(
          title: result.title,
          description: result.description,
          targetAmountCents: result.amountCents,
          allowPartial: result.allowPartial,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Items',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: BlocBuilder<ItemsCubit, ItemsState>(
        builder: (context, state) {
          return GlAsyncView(
            loading:
                state.status == ItemsStatus.loading ||
                state.status == ItemsStatus.initial,
            error: state.status == ItemsStatus.failure
                ? state.errorMessage
                : null,
            onRetry: () => context.read<ItemsCubit>().load(),
            isEmpty: state.isEmpty,
            empty: GlEmptyState(
              icon: Icons.list_alt_outlined,
              title: 'No items yet',
              message: 'Add the gifts people can contribute to.',
              action: FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
            builder: (context) => ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.items.length,
              onReorder: (oldIndex, newIndex) =>
                  context.read<ItemsCubit>().reorder(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final GiftItem item = state.items[index];
                return _ItemTile(
                  key: ValueKey(item.id),
                  item: item,
                  onEdit: () => _edit(context, item),
                  onDelete: () => context.read<ItemsCubit>().remove(item.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final GiftItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlListCard(
      onTap: onEdit,
      child: Row(
        children: [
          const Icon(Icons.drag_indicator),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  centsToBrl(item.targetAmountCents) +
                      (item.allowPartial ? ' · partial ok' : ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ItemFormResult {
  const _ItemFormResult({
    required this.title,
    required this.amountCents,
    required this.allowPartial,
    this.description,
  });

  final String title;
  final int amountCents;
  final bool allowPartial;
  final String? description;
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({this.item});

  final GiftItem? item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  bool _allowPartial = false;

  @override
  void initState() {
    super.initState();
    final GiftItem? item = widget.item;
    if (item != null) {
      _title.text = item.title;
      _description.text = item.description ?? '';
      _amount.text = (item.targetAmountCents / 100).toStringAsFixed(2);
      _allowPartial = item.allowPartial;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _ItemFormResult(
        title: _title.text.trim(),
        amountCents: tryParseReaisToCents(_amount.text)!,
        allowPartial: _allowPartial,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add item' : 'Edit item'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target amount',
                  prefixText: r'R$ ',
                ),
                validator: (v) => tryParseReaisToCents(v ?? '') == null
                    ? 'Enter a valid amount.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow partial contributions'),
                subtitle: const Text('Quota / “cotas” style.'),
                value: _allowPartial,
                onChanged: (v) => setState(() => _allowPartial = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
