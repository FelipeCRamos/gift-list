import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_form_cubit.dart';
import 'sign_in_screen.dart';

/// Routes owned by the auth feature.
abstract final class AuthRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.auth,
      builder: (context, state) => BlocProvider(
        create: (ctx) =>
            AuthFormCubit(authRepository: ctx.read<AuthRepository>()),
        child: const SignInScreen(),
      ),
    ),
  ];
}
