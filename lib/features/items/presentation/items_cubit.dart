import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/gift_registry_repository.dart';

part 'items_state.dart';

/// Item CRUD + ordering for one list.
class ItemsCubit extends Cubit<ItemsState> {
  ItemsCubit({required GiftRegistryRepository registry, required this.listId})
    : _registry = registry,
      super(const ItemsState());

  final GiftRegistryRepository _registry;
  final String listId;

  Future<void> load() async {
    emit(state.copyWith(status: ItemsStatus.loading, clearError: true));
    try {
      final List<GiftItem> items = await _registry.itemsForList(listId);
      emit(state.copyWith(status: ItemsStatus.ready, items: items));
    } catch (error) {
      emit(
        state.copyWith(
          status: ItemsStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> add(NewItem data) async {
    try {
      final GiftItem created = await _registry.addItem(
        listId,
        NewItem(
          title: data.title,
          targetAmountCents: data.targetAmountCents,
          allowPartial: data.allowPartial,
          position: state.items.length,
          description: data.description,
          imageUrl: data.imageUrl,
        ),
      );
      emit(state.copyWith(items: [...state.items, created]));
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  Future<void> edit(String id, ItemUpdate data) async {
    try {
      final GiftItem updated = await _registry.updateItem(id, data);
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id == id) updated else item,
          ],
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  Future<void> remove(String id) async {
    try {
      await _registry.removeItem(id);
      emit(
        state.copyWith(items: state.items.where((i) => i.id != id).toList()),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  /// Moves an item and persists the new 0-based positions.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<GiftItem> items = [...state.items];
    var target = newIndex;
    if (target > oldIndex) {
      target -= 1;
    }
    final GiftItem moved = items.removeAt(oldIndex);
    items.insert(target, moved);
    emit(state.copyWith(items: items));
    try {
      for (var i = 0; i < items.length; i++) {
        if (items[i].position != i) {
          await _registry.updateItem(items[i].id, ItemUpdate(position: i));
        }
      }
      emit(
        state.copyWith(
          items: [
            for (var i = 0; i < items.length; i++)
              items[i].copyWith(position: i),
          ],
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: _messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Could not update items. Please try again.';
  }
}
