import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/labels.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'lists_cubit.dart';

/// `/dashboard` — the owner's lists, with create + navigation into each editor.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final ListsCubit cubit = context.read<ListsCubit>();
    final NewList? draft = await showDialog<NewList>(
      context: context,
      builder: (_) => _CreateListDialog(profile: cubit.state.profile),
    );
    if (draft == null) {
      return;
    }
    final GiftList? created = await cubit.create(draft);
    if (created != null && context.mounted) {
      context.push(RoutePaths.toListEdit(created.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'My lists',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
          onPressed: () => context.push(RoutePaths.profile),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () => context.read<AuthCubit>().signOut(),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
      body: BlocConsumer<ListsCubit, ListsState>(
        listenWhen: (a, b) =>
            b.errorMessage != null && a.errorMessage != b.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          return GlAsyncView(
            loading:
                state.status == ListsStatus.loading ||
                state.status == ListsStatus.initial,
            error: state.status == ListsStatus.failure
                ? state.errorMessage
                : null,
            onRetry: () => context.read<ListsCubit>().load(),
            isEmpty: state.isEmpty,
            empty: GlEmptyState(
              icon: Icons.card_giftcard_outlined,
              title: 'No lists yet',
              message: 'Create your first gift list to get started.',
              action: FilledButton.icon(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add),
                label: const Text('New list'),
              ),
            ),
            builder: (context) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: state.lists.length,
              itemBuilder: (context, index) =>
                  _ListTile(list: state.lists[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.list});

  final GiftList list;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlListCard(
      onTap: () => context.push(RoutePaths.toListEdit(list.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(list.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  occasionLabel(list.occasion),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _Tag(
                      label: list.isPublished ? 'Published' : 'Draft',
                      color: list.isPublished
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    _Tag(label: visibilityLabel(list.visibility)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color c = color ?? theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: c)),
    );
  }
}

/// Minimal create form. Prefills Pix fields from the owner's profile; the editor
/// refines everything afterward.
class _CreateListDialog extends StatefulWidget {
  const _CreateListDialog({required this.profile});

  final Profile? profile;

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _pixKey = TextEditingController();
  final TextEditingController _merchantName = TextEditingController();
  Occasion _occasion = Occasion.other;
  PixKeyType _pixKeyType = PixKeyType.email;

  @override
  void initState() {
    super.initState();
    final Profile? profile = widget.profile;
    if (profile != null) {
      _pixKey.text = profile.defaultPixKey ?? '';
      _pixKeyType = profile.pixKeyType ?? PixKeyType.email;
      _merchantName.text = profile.displayName;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _pixKey.dispose();
    _merchantName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      NewList(
        title: _title.text.trim(),
        occasion: _occasion,
        pixKey: _pixKey.text.trim(),
        pixKeyType: _pixKeyType,
        merchantName: _merchantName.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New list'),
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
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Occasion>(
                initialValue: _occasion,
                decoration: const InputDecoration(labelText: 'Occasion'),
                items: [
                  for (final o in Occasion.values)
                    DropdownMenuItem(value: o, child: Text(occasionLabel(o))),
                ],
                onChanged: (value) =>
                    setState(() => _occasion = value ?? _occasion),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pixKey,
                decoration: const InputDecoration(labelText: 'Pix key'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PixKeyType>(
                initialValue: _pixKeyType,
                decoration: const InputDecoration(labelText: 'Pix key type'),
                items: [
                  for (final t in PixKeyType.values)
                    DropdownMenuItem(value: t, child: Text(pixKeyTypeLabel(t))),
                ],
                onChanged: (value) =>
                    setState(() => _pixKeyType = value ?? _pixKeyType),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchantName,
                decoration: const InputDecoration(
                  labelText: 'Merchant name',
                  helperText: 'Shown on the Pix code.',
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required.' : null,
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
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
