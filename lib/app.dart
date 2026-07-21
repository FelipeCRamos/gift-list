import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/gl_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/gift_registry_repository.dart';
import 'data/repositories/mock/in_memory_auth_repository.dart';
import 'data/repositories/mock/in_memory_gift_registry_repository.dart';
import 'data/repositories/mock/in_memory_storage_repository.dart';
import 'data/repositories/storage_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'services/pix/emv_pix_payload_service.dart';
import 'services/pix/pix_payload_service.dart';

/// App root. Injects the repository layer (mock today; swap one binding each for
/// Supabase in Phase 8) and provides the root [AuthCubit], then hands off to
/// go_router. See docs/ARCHITECTURE.md for the DI story.
class GiftListApp extends StatelessWidget {
  const GiftListApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = InMemoryAuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<GiftRegistryRepository>(
          create: (_) => InMemoryGiftRegistryRepository(auth: authRepository),
        ),
        RepositoryProvider<StorageRepository>(
          create: (_) => InMemoryStorageRepository(),
        ),
        RepositoryProvider<PixPayloadService>(
          create: (_) => const EmvPixPayloadService(),
        ),
      ],
      child: BlocProvider<AuthCubit>(
        create: (context) =>
            AuthCubit(authRepository: context.read<AuthRepository>()),
        child: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gift Registry',
      debugShowCheckedModeBanner: false,
      theme: GlTheme.light(),
      darkTheme: GlTheme.dark(),
      routerConfig: _router,
    );
  }
}
