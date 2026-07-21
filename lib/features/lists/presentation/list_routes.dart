import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'list_editor_cubit.dart';
import 'list_editor_screen.dart';
import 'lists_cubit.dart';
import 'lists_screen.dart';

/// Routes owned by the lists feature (dashboard home + list editor).
abstract final class ListRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.dashboard,
      builder: (context, state) => BlocProvider(
        create: (ctx) =>
            ListsCubit(registry: ctx.read<GiftRegistryRepository>())..load(),
        child: const ListsScreen(),
      ),
    ),
    GoRoute(
      path: RoutePaths.listEdit,
      builder: (context, state) {
        final String id = state.pathParameters['id']!;
        return BlocProvider(
          create: (ctx) =>
              ListEditorCubit(registry: ctx.read<GiftRegistryRepository>())
                ..load(id),
          child: ListEditorScreen(listId: id),
        );
      },
    ),
  ];
}
