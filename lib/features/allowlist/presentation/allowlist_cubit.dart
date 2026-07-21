import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'allowlist_state.dart';

/// Manages a private list's email allowlist. Phone entries are deferred until
/// SMS auth is funded, so this only handles emails.
class AllowlistCubit extends Cubit<AllowlistState> {
  AllowlistCubit({
    required GiftRegistryRepository registry,
    required this.listId,
  }) : _registry = registry,
       super(const AllowlistState());

  final GiftRegistryRepository _registry;
  final String listId;

  Future<void> load() async {
    emit(state.copyWith(status: AllowlistStatus.loading, clearError: true));
    try {
      final List<AllowlistEntry> entries = await _registry.getAllowlist(listId);
      emit(state.copyWith(status: AllowlistStatus.ready, entries: entries));
    } catch (error) {
      emit(
        state.copyWith(
          status: AllowlistStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> addEmail(String email) async {
    final String normalized = email.trim().toLowerCase();
    final bool exists = state.entries.any((e) => e.email == normalized);
    if (normalized.isEmpty || exists) {
      return;
    }
    final List<AllowlistEntry> next = [
      ...state.entries,
      AllowlistEntry(email: normalized),
    ];
    await _persist(next);
  }

  Future<void> remove(AllowlistEntry entry) async {
    final List<AllowlistEntry> next = state.entries
        .where((e) => e != entry)
        .toList();
    await _persist(next);
  }

  Future<void> _persist(List<AllowlistEntry> entries) async {
    try {
      await _registry.setAllowlist(listId, entries);
      final List<AllowlistEntry> saved = await _registry.getAllowlist(listId);
      emit(state.copyWith(entries: saved));
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not update the allowlist. Please try again.';
  }
}
