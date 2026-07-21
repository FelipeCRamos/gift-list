import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'items_cubit.dart';
import 'items_screen.dart';

/// Routes owned by the items feature.
abstract final class ItemRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.listItems,
      builder: (context, state) {
        final String id = state.pathParameters['id']!;
        return BlocProvider(
          create: (ctx) => ItemsCubit(
            registry: ctx.read<GiftRegistryRepository>(),
            listId: id,
          )..load(),
          child: const ItemsScreen(),
        );
      },
    ),
  ];
}
