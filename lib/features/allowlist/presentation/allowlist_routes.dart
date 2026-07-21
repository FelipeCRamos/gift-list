import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'allowlist_cubit.dart';
import 'allowlist_screen.dart';

/// Routes owned by the allowlist feature.
abstract final class AllowlistRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.listAllowlist,
      builder: (context, state) {
        final String id = state.pathParameters['id']!;
        return BlocProvider(
          create: (ctx) => AllowlistCubit(
            registry: ctx.read<GiftRegistryRepository>(),
            listId: id,
          )..load(),
          child: const AllowlistScreen(),
        );
      },
    ),
  ];
}
