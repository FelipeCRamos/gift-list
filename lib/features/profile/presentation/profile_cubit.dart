import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'profile_state.dart';

/// Loads and saves the signed-in user's profile (display name, default Pix key,
/// merchant city). A missing profile row is presented as a blank editable draft.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GiftRegistryRepository registry,
    required AuthRepository auth,
  }) : _registry = registry,
       _auth = auth,
       super(const ProfileState());

  final GiftRegistryRepository _registry;
  final AuthRepository _auth;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final Profile? existing = await _registry.getMyProfile();
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          profile: existing ?? _blankProfile(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> save(Profile draft) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final Profile saved = await _registry.saveMyProfile(draft);
      emit(state.copyWith(status: ProfileStatus.saved, profile: saved));
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Profile _blankProfile() {
    final AuthUser? user = _auth.currentUser;
    final String id = user?.id ?? '';
    final String fallbackName = user?.email.split('@').first ?? '';
    return Profile(
      id: id,
      displayName: fallbackName,
      createdAt: DateTime.now(),
    );
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not load your profile. Please try again.';
  }
}
