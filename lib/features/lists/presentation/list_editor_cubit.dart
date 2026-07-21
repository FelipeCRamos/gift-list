import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'list_editor_state.dart';

/// Edits one list's metadata, access settings, and published flag.
///
/// Enforces the `private ⇒ login_required` invariant client-side: choosing
/// `private` forces contributor auth to `login_required` and locks it
/// ([ListEditorState.authLocked]). The repository/DB reject the bad combo too;
/// this keeps the UI from ever offering it.
class ListEditorCubit extends Cubit<ListEditorState> {
  ListEditorCubit({required GiftRegistryRepository registry})
    : _registry = registry,
      super(const ListEditorState());

  final GiftRegistryRepository _registry;

  Future<void> load(String id) async {
    emit(state.copyWith(status: ListEditorStatus.loading, clearError: true));
    try {
      final GiftList list = await _registry.getMyList(id);
      emit(
        state.copyWith(
          status: ListEditorStatus.ready,
          list: list,
          visibility: list.visibility,
          contributorAuth: list.contributorAuth,
          isPublished: list.isPublished,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ListEditorStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  void setVisibility(ListVisibility visibility) {
    if (visibility == ListVisibility.private) {
      // Private implies login_required — force and lock it.
      emit(
        state.copyWith(
          visibility: visibility,
          contributorAuth: ContributorAuth.loginRequired,
        ),
      );
    } else {
      emit(state.copyWith(visibility: visibility));
    }
  }

  void setContributorAuth(ContributorAuth auth) {
    if (state.authLocked) {
      return; // Locked to login_required while private.
    }
    emit(state.copyWith(contributorAuth: auth));
  }

  Future<void> togglePublished(bool published) async {
    final GiftList? list = state.list;
    if (list == null) {
      return;
    }
    try {
      await _registry.setPublished(list.id, published);
      emit(state.copyWith(isPublished: published));
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  Future<void> save({
    required String title,
    required Occasion occasion,
    required String pixKey,
    required PixKeyType pixKeyType,
    required String merchantName,
    String? description,
    DateTime? eventDate,
    String? coverImageUrl,
  }) async {
    final GiftList? list = state.list;
    if (list == null) {
      return;
    }
    emit(state.copyWith(status: ListEditorStatus.saving, clearError: true));
    try {
      final GiftList updated = await _registry.updateList(
        list.id,
        ListUpdate(
          title: title,
          occasion: occasion,
          description: description,
          pixKey: pixKey,
          pixKeyType: pixKeyType,
          merchantName: merchantName,
          visibility: state.visibility,
          contributorAuth: state.contributorAuth,
          eventDate: eventDate,
          coverImageUrl: coverImageUrl,
        ),
      );
      emit(state.copyWith(status: ListEditorStatus.saved, list: updated));
    } catch (error) {
      emit(
        state.copyWith(
          status: ListEditorStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not save the list. Please try again.';
  }
}
