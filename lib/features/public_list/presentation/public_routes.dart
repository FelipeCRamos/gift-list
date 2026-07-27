import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'list_gate_cubit.dart';
import 'list_gate_screen.dart';

/// Routes owned by the public (contributor) list feature.
abstract final class PublicListRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.listView,
      builder: (context, state) {
        final String slug = state.pathParameters['slug']!;
        return BlocProvider(
          create: (ctx) => ListGateCubit(
            registry: ctx.read<GiftRegistryRepository>(),
            auth: ctx.read<AuthRepository>(),
            slug: slug,
          )..resolve(),
          child: ListGateScreen(slug: slug),
        );
      },
    ),
  ];
}
