import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/labels.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import 'list_editor_cubit.dart';

/// `/dashboard/lists/:id/edit` — metadata, Pix, access settings (with the
/// private⇒login_required lock), publish toggle, and links to items/allowlist.
class ListEditorScreen extends StatefulWidget {
  const ListEditorScreen({required this.listId, super.key});

  final String listId;

  @override
  State<ListEditorScreen> createState() => _ListEditorScreenState();
}

class _ListEditorScreenState extends State<ListEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _pixKey = TextEditingController();
  final TextEditingController _merchantName = TextEditingController();
  Occasion _occasion = Occasion.other;
  PixKeyType _pixKeyType = PixKeyType.email;
  DateTime? _eventDate;
  String? _coverImageUrl;
  bool _populated = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _pixKey.dispose();
    _merchantName.dispose();
    super.dispose();
  }

  void _populate(GiftList list) {
    _title.text = list.title;
    _description.text = list.description ?? '';
    _pixKey.text = list.pixKey;
    _merchantName.text = list.merchantName;
    _occasion = list.occasion;
    _pixKeyType = list.pixKeyType;
    _eventDate = list.eventDate;
    _coverImageUrl = list.coverImageUrl;
    _populated = true;
  }

  void _save(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<ListEditorCubit>().save(
      title: _title.text.trim(),
      occasion: _occasion,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      pixKey: _pixKey.text.trim(),
      pixKeyType: _pixKeyType,
      merchantName: _merchantName.text.trim(),
      eventDate: _eventDate,
      coverImageUrl: _coverImageUrl,
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Edit list',
      body: BlocConsumer<ListEditorCubit, ListEditorState>(
        listener: (context, state) {
          if (state.status == ListEditorStatus.ready && !_populated) {
            _populate(state.list!);
          }
          if (state.status == ListEditorStatus.saved) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('List saved.')));
          }
          if (state.status == ListEditorStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Save failed.')),
            );
          }
        },
        builder: (context, state) {
          return GlAsyncView(
            loading:
                state.status == ListEditorStatus.loading ||
                state.status == ListEditorStatus.initial,
            builder: (context) => GlFormLayout(
              formKey: _formKey,
              children: _fields(context, state),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _fields(BuildContext context, ListEditorState state) {
    final ListEditorCubit cubit = context.read<ListEditorCubit>();
    return [
      TextFormField(
        controller: _title,
        decoration: const InputDecoration(labelText: 'Title'),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Required.' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<Occasion>(
        initialValue: _occasion,
        decoration: const InputDecoration(labelText: 'Occasion'),
        items: [
          for (final o in Occasion.values)
            DropdownMenuItem(value: o, child: Text(occasionLabel(o))),
        ],
        onChanged: (v) => setState(() => _occasion = v ?? _occasion),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _description,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Description (optional)'),
      ),
      const SizedBox(height: 16),
      GlImagePickerField(
        label: 'Cover photo (optional)',
        pathPrefix: 'lists/${widget.listId}/cover',
        initialUrl: _coverImageUrl,
        onChanged: (url) => setState(() => _coverImageUrl = url),
      ),
      const SizedBox(height: 16),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Event date'),
        subtitle: Text(
          _eventDate == null
              ? 'Not set'
              : '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}',
        ),
        trailing: TextButton(
          onPressed: () => _pickDate(context),
          child: const Text('Choose'),
        ),
      ),
      const Divider(height: 32),
      Text('Pix', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      TextFormField(
        controller: _pixKey,
        decoration: const InputDecoration(labelText: 'Pix key'),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Required.' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<PixKeyType>(
        initialValue: _pixKeyType,
        decoration: const InputDecoration(labelText: 'Pix key type'),
        items: [
          for (final t in PixKeyType.values)
            DropdownMenuItem(value: t, child: Text(pixKeyTypeLabel(t))),
        ],
        onChanged: (v) => setState(() => _pixKeyType = v ?? _pixKeyType),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _merchantName,
        decoration: const InputDecoration(
          labelText: 'Merchant name',
          helperText: 'Shown on the Pix code (ASCII, <=25 chars).',
        ),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Required.' : null,
      ),
      const Divider(height: 32),
      Text('Access', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _AccessControls(state: state, cubit: cubit),
      const Divider(height: 32),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Published'),
        subtitle: Text(
          state.isPublished
              ? 'Visible per the access settings above.'
              : 'Draft — only you can see it.',
        ),
        value: state.isPublished,
        onChanged: cubit.togglePublished,
      ),
      if (state.isPublished && state.list != null) ...[
        const SizedBox(height: 8),
        _ShareLink(slug: state.list!.slug, isPrivate: state.isPrivate),
      ],
      const Divider(height: 32),
      _ManageLinks(listId: widget.listId, isPrivate: state.isPrivate),
      const SizedBox(height: 24),
      GlBusyButton(
        label: 'Save',
        busy: state.status == ListEditorStatus.saving,
        onPressed: () => _save(context),
      ),
    ];
  }
}

class _AccessControls extends StatelessWidget {
  const _AccessControls({required this.state, required this.cubit});

  final ListEditorState state;
  final ListEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visibility'),
        const SizedBox(height: 8),
        SegmentedButton<ListVisibility>(
          segments: [
            for (final v in ListVisibility.values)
              ButtonSegment(value: v, label: Text(visibilityLabel(v))),
          ],
          selected: {state.visibility},
          onSelectionChanged: (s) => cubit.setVisibility(s.first),
        ),
        const SizedBox(height: 16),
        const Text('Contributors'),
        const SizedBox(height: 8),
        SegmentedButton<ContributorAuth>(
          segments: [
            for (final a in ContributorAuth.values)
              ButtonSegment(value: a, label: Text(contributorAuthLabel(a))),
          ],
          selected: {state.contributorAuth},
          onSelectionChanged: state.authLocked
              ? null
              : (s) => cubit.setContributorAuth(s.first),
        ),
        if (state.authLocked) ...[
          const SizedBox(height: 8),
          Text(
            'Private lists require login — locked to “Login required”.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shows the public share URL for a published list with a copy button.
class _ShareLink extends StatelessWidget {
  const _ShareLink({required this.slug, required this.isPrivate});

  final String slug;
  final bool isPrivate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String url = RoutePaths.shareableListUrl(slug);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Share link', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          isPrivate
              ? 'Allowlisted people can open this after signing in.'
              : 'Anyone with this link can open the list.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(url, style: theme.textTheme.bodySmall),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied — share it with friends.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageLinks extends StatelessWidget {
  const _ManageLinks({required this.listId, required this.isPrivate});

  final String listId;
  final bool isPrivate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.list_alt),
          title: const Text('Items'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(RoutePaths.toListItems(listId)),
        ),
        if (isPrivate)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline),
            title: const Text('Allowlist'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePaths.toListAllowlist(listId)),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.volunteer_activism_outlined),
          title: const Text('Contributions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(RoutePaths.toListContributions(listId)),
        ),
      ],
    );
  }
}
