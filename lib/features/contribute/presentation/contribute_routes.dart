import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';
import '../../../services/payments/payment_instruction_service.dart';
import 'gift_cubit.dart';
import 'gift_page.dart';
import 'thanks_page.dart';

/// Routes owned by the contribute feature: the gift form + Pix payment view and
/// the post-payment thank-you page.
abstract final class ContributeRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: RoutePaths.gift,
      builder: (context, state) {
        final String slug = state.pathParameters['slug']!;
        final String itemId = state.pathParameters['itemId']!;
        return BlocProvider(
          create: (ctx) => GiftCubit(
            registry: ctx.read<GiftRegistryRepository>(),
            payments: ctx.read<PaymentInstructionService>(),
            auth: ctx.read<AuthRepository>(),
            slug: slug,
            itemId: itemId,
          )..load(),
          child: GiftPage(slug: slug, itemId: itemId),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.thanks,
      builder: (context, state) =>
          ThanksPage(slug: state.pathParameters['slug']!),
    ),
  ];
}
