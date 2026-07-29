import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/formatting/brl_money.dart';
import '../../../core/formatting/labels.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import 'contributions_cubit.dart';

/// `/dashboard/lists/:id/contributions` — the creator's inbox: confirm/reject
/// pending reservations and see the confirmed thank-you wall.
class ContributionsScreen extends StatelessWidget {
  const ContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContributionsCubit, ContributionsState>(
      listenWhen: (a, b) =>
          b.errorMessage != null && a.errorMessage != b.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        return GlPageScaffold(
          title: state.listTitle.isEmpty ? 'Contributions' : state.listTitle,
          body: GlAsyncView(
            loading:
                state.status == ContributionsStatus.loading ||
                state.status == ContributionsStatus.initial,
            error: state.status == ContributionsStatus.failure
                ? state.errorMessage
                : null,
            onRetry: () => context.read<ContributionsCubit>().load(),
            isEmpty: state.isEmpty,
            empty: const GlEmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No contributions yet',
              message: 'Gifts people reserve will show up here to confirm.',
            ),
            builder: (context) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (state.awaiting.isNotEmpty)
                  _Section(
                    title: 'Needs confirmation',
                    children: [
                      for (final c in state.awaiting)
                        _ContributionCard(
                          contribution: c,
                          busy: state.isBusy(c.id),
                          onConfirm: () =>
                              context.read<ContributionsCubit>().confirm(c.id),
                          onReject: () =>
                              context.read<ContributionsCubit>().reject(c.id),
                        ),
                    ],
                  ),
                if (state.confirmed.isNotEmpty)
                  _Section(
                    title: 'Confirmed',
                    children: [
                      for (final c in state.confirmed)
                        _ContributionCard(contribution: c),
                    ],
                  ),
                if (state.closed.isNotEmpty)
                  _Section(
                    title: 'Closed',
                    children: [
                      for (final c in state.closed)
                        _ContributionCard(contribution: c, muted: true),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.contribution,
    this.busy = false,
    this.muted = false,
    this.onConfirm,
    this.onReject,
  });

  final Contribution contribution;
  final bool busy;
  final bool muted;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? subtle = muted ? theme.colorScheme.outline : null;
    return GlListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contribution.giverName,
                  style: theme.textTheme.titleMedium?.copyWith(color: subtle),
                ),
              ),
              Text(
                centsToBrl(contribution.amountCents),
                style: theme.textTheme.titleMedium?.copyWith(color: subtle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            contributionStatusLabel(contribution.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtle ?? theme.colorScheme.outline,
            ),
          ),
          if (contribution.giverMessage != null) ...[
            const SizedBox(height: 8),
            Text(contribution.giverMessage!, style: theme.textTheme.bodyMedium),
          ],
          if (onConfirm != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onReject,
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                GlBusyButton(
                  label: 'Confirm',
                  busy: busy,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
