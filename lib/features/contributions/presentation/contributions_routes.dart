import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'contributions_cubit.dart';
import 'contributions_screen.dart';

/// Routes owned by the contributions inbox feature.
abstract final class ContributionsRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.listContributions,
      builder: (context, state) {
        final String id = state.pathParameters['id']!;
        return BlocProvider(
          create: (ctx) => ContributionsCubit(
            registry: ctx.read<GiftRegistryRepository>(),
            listId: id,
          )..load(),
          child: const ContributionsScreen(),
        );
      },
    ),
  ];
}
