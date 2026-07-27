import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'list_gate_state.dart';

/// Resolves how to render `/l/:slug` before any content read, using the
/// anon-readable `list_access_info` plus the session (and, for private lists, an
/// access probe). Emits one of the [GateStatus] values so the UI shows the right
/// prompt without leaking list contents.
class ListGateCubit extends Cubit<ListGateState> {
  ListGateCubit({
    required GiftRegistryRepository registry,
    required AuthRepository auth,
    required this.slug,
  }) : _registry = registry,
       _auth = auth,
       super(const ListGateState());

  final GiftRegistryRepository _registry;
  final AuthRepository _auth;
  final String slug;

  Future<void> resolve() async {
    emit(const ListGateState());
    try {
      final ListAccessInfo info = await _registry.getListAccessInfo(slug);
      if (!info.exists) {
        emit(const ListGateState(status: GateStatus.notFound));
        return;
      }
      final signedIn = _auth.currentUser != null;

      if (info.visibility == ListVisibility.public) {
        if (info.contributorAuth == ContributorAuth.anonymous) {
          emit(ListGateState(status: GateStatus.ready, info: info));
        } else if (signedIn) {
          emit(ListGateState(status: GateStatus.ready, info: info));
        } else {
          emit(ListGateState(status: GateStatus.needsLogin, info: info));
        }
        return;
      }

      // Private.
      if (!signedIn) {
        emit(ListGateState(status: GateStatus.private, info: info));
        return;
      }
      // Signed in — probe access (allowlist membership is server-side only).
      try {
        await _registry.getPublicList(slug);
        emit(ListGateState(status: GateStatus.ready, info: info));
      } on AccessDeniedException {
        emit(ListGateState(status: GateStatus.noAccess, info: info));
      }
    } catch (error) {
      emit(
        ListGateState(
          status: GateStatus.error,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not open this list. Please try again.';
  }
}
