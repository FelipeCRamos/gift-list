import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/brl_money.dart';
import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import 'public_list_cubit.dart';

/// The contributor-facing list content: header + items with PII-free progress.
/// Assumes a [PublicListCubit] is provided above it.
class PublicListView extends StatelessWidget {
  const PublicListView({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicListCubit, PublicListState>(
      builder: (context, state) {
        final PublicList? list = state.list;
        return GlPageScaffold(
          title: list?.title ?? 'Gift list',
          body: GlAsyncView(
            loading:
                state.status == PublicListStatus.loading ||
                state.status == PublicListStatus.initial,
            error: state.status == PublicListStatus.failure
                ? state.errorMessage
                : null,
            onRetry: () => context.read<PublicListCubit>().load(),
            builder: (context) =>
                _Content(slug: slug, list: list!, state: state),
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.slug, required this.list, required this.state});

  final String slug;
  final PublicList list;
  final PublicListState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (list.description != null && list.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(list.description!, style: theme.textTheme.bodyLarge),
          ),
        for (final item in list.items)
          _ItemCard(
            slug: slug,
            item: item,
            progress: state.progressFor(item.id),
          ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.slug,
    required this.item,
    required this.progress,
  });

  final String slug;
  final GiftItem item;
  final ItemProgress? progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int confirmed = progress?.confirmedCents ?? 0;
    final int target = item.targetAmountCents;
    final double fraction = target == 0
        ? 0.0
        : (confirmed / target).clamp(0.0, 1.0);
    final ItemState itemState = progress?.state ?? ItemState.open;

    return GlListCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title, style: theme.textTheme.titleMedium),
              ),
              _StateBadge(state: itemState),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${centsToBrl(confirmed)} of ${centsToBrl(target)}',
                style: theme.textTheme.bodySmall,
              ),
              _ContributeButton(slug: slug, item: item, state: itemState),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContributeButton extends StatelessWidget {
  const _ContributeButton({
    required this.slug,
    required this.item,
    required this.state,
  });

  final String slug;
  final GiftItem item;
  final ItemState state;

  @override
  Widget build(BuildContext context) {
    if (state == ItemState.complete) {
      return const Text('Complete 🎉');
    }
    // A full-amount item that's reserved is locked until the reservation clears.
    final bool locked = state == ItemState.reserved && !item.allowPartial;
    return FilledButton(
      onPressed: locked
          ? null
          : () => context.push(RoutePaths.toGift(slug, item.id)),
      child: Text(locked ? 'Reserved' : 'Contribute'),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final ItemState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (String label, Color color) = switch (state) {
      ItemState.open => ('Open', theme.colorScheme.primary),
      ItemState.reserved => ('Reserved', theme.colorScheme.tertiary),
      ItemState.complete => ('Complete', theme.colorScheme.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
