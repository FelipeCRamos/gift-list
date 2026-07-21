import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/widgets.dart';
import 'allowlist_cubit.dart';

/// `/dashboard/lists/:id/allowlist` — manage the permitted emails for a private
/// list. Only reachable when the list is private.
class AllowlistScreen extends StatefulWidget {
  const AllowlistScreen({super.key});

  @override
  State<AllowlistScreen> createState() => _AllowlistScreenState();
}

class _AllowlistScreenState extends State<AllowlistScreen> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _add(BuildContext context) {
    final String value = _email.text.trim();
    if (!_isValidEmail(value)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid email.')));
      return;
    }
    context.read<AllowlistCubit>().addEmail(value);
    _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Allowlist',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Add email',
                      hintText: 'guest@example.com',
                    ),
                    onSubmitted: (_) => _add(context),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _add(context),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AllowlistCubit, AllowlistState>(
              builder: (context, state) {
                return GlAsyncView(
                  loading:
                      state.status == AllowlistStatus.loading ||
                      state.status == AllowlistStatus.initial,
                  error: state.status == AllowlistStatus.failure
                      ? state.errorMessage
                      : null,
                  onRetry: () => context.read<AllowlistCubit>().load(),
                  isEmpty: state.isEmpty,
                  empty: const GlEmptyState(
                    icon: Icons.mail_outline,
                    title: 'No one on the allowlist',
                    message: 'Add the emails allowed to view this list.',
                  ),
                  builder: (context) => ListView(
                    children: [
                      for (final entry in state.entries)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(entry.email ?? entry.phone ?? '—'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove',
                            onPressed: () =>
                                context.read<AllowlistCubit>().remove(entry),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

bool _isValidEmail(String value) =>
    value.contains('@') && value.contains('.') && !value.contains(' ');
