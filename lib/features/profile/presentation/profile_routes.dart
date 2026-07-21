import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import 'profile_cubit.dart';
import 'profile_screen.dart';

/// Routes owned by the profile feature (under the authed dashboard).
abstract final class ProfileRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.profile,
      builder: (context, state) => BlocProvider(
        create: (ctx) => ProfileCubit(
          registry: ctx.read<GiftRegistryRepository>(),
          auth: ctx.read<AuthRepository>(),
        )..load(),
        child: const ProfileScreen(),
      ),
    ),
  ];
}
