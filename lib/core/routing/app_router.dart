import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/allowlist/presentation/allowlist_routes.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/auth_routes.dart';
import '../../features/contribute/presentation/contribute_routes.dart';
import '../../features/items/presentation/item_routes.dart';
import '../../features/lists/presentation/list_routes.dart';
import '../../features/profile/presentation/profile_routes.dart';
import '../../features/public_list/presentation/public_routes.dart';
import '../widgets/placeholder_page.dart';
import 'route_paths.dart';

/// Builds the app router. Feature phases will replace the placeholder builders
/// and move route definitions into per-feature `{feature}_routes.dart` files.
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: RoutePaths.landing,
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final String loc = state.matchedLocation;
      final bool authed = authCubit.state.isAuthenticated;
      final atAuth = loc == RoutePaths.auth;
      final bool protected = loc.startsWith(RoutePaths.dashboard);

      if (protected && !authed) {
        return RoutePaths.auth;
      }
      if (atAuth && authed) {
        final String? from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty) ? from : RoutePaths.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.landing,
        builder: (context, state) => _Landing(),
      ),
      ...PublicListRoutes.routes,
      ...ContributeRoutes.routes,
      ...AuthRoutes.routes,
      ...ListRoutes.routes,
      ...ItemRoutes.routes,
      ...AllowlistRoutes.routes,
      ...ProfileRoutes.routes,
      GoRoute(
        path: RoutePaths.listContributions,
        builder: (context, state) => const PlaceholderPage(
          title: 'Contributions',
          phase: 'Contributions inbox — Phase 7',
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        PlaceholderPage(title: 'Not found', phase: state.uri.toString()),
  );
}

/// Landing page. Minimal for now — links into the seeded flows so the skeleton
/// is explorable.
class _Landing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Gift Registry',
      phase: 'Foundation skeleton — Phase 1',
      actions: [
        FilledButton(
          onPressed: () => context.go(RoutePaths.toListView('casa-nova-ana')),
          child: const Text('View a sample list'),
        ),
        OutlinedButton(
          onPressed: () => context.go(RoutePaths.auth),
          child: const Text('Sign in'),
        ),
        OutlinedButton(
          onPressed: () => context.go(RoutePaths.dashboard),
          child: const Text('Dashboard'),
        ),
      ],
    );
  }
}

/// Notifies go_router to re-run `redirect` whenever the auth stream emits.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
