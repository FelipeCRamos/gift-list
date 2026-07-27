import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'list_gate_cubit.dart';
import 'public_list_cubit.dart';
import 'public_list_view.dart';

/// `/l/:slug` — renders the right gate for the list's access settings, and the
/// list content once access is granted.
class ListGateScreen extends StatelessWidget {
  const ListGateScreen({required this.slug, super.key});

  final String slug;

  void _signIn(BuildContext context) {
    context.push(RoutePaths.authFrom(RoutePaths.toListView(slug)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListGateCubit, ListGateState>(
      builder: (context, state) {
        switch (state.status) {
          case GateStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case GateStatus.ready:
            return BlocProvider(
              create: (ctx) => PublicListCubit(
                registry: ctx.read<GiftRegistryRepository>(),
                slug: slug,
              )..load(),
              child: PublicListView(slug: slug),
            );
          case GateStatus.needsLogin:
            return _Gate(
              title: state.info?.title ?? 'Sign in required',
              icon: Icons.lock_outline,
              message: 'This list requires you to sign in to view it.',
              actionLabel: 'Sign in',
              onAction: () => _signIn(context),
            );
          case GateStatus.private:
            return _Gate(
              title: state.info?.title ?? 'Private list',
              icon: Icons.lock_outline,
              message: 'This list is private — sign in to check your access.',
              actionLabel: 'Sign in',
              onAction: () => _signIn(context),
            );
          case GateStatus.noAccess:
            return const _Gate(
              title: 'No access',
              icon: Icons.block,
              message: "You're signed in, but not on this list's guest list.",
            );
          case GateStatus.notFound:
            return const _Gate(
              title: 'List not found',
              icon: Icons.search_off,
              message: 'This link may be wrong or the list was removed.',
            );
          case GateStatus.error:
            return _Gate(
              title: 'Something went wrong',
              icon: Icons.error_outline,
              message: state.errorMessage ?? 'Please try again.',
              actionLabel: 'Retry',
              onAction: () => context.read<ListGateCubit>().resolve(),
            );
        }
      },
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.title,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Gift list',
      body: GlEmptyState(
        icon: icon,
        title: title,
        message: message,
        action: actionLabel == null
            ? null
            : FilledButton(onPressed: onAction, child: Text(actionLabel!)),
      ),
    );
  }
}
