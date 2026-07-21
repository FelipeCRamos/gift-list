part of 'items_cubit.dart';

enum ItemsStatus { initial, loading, ready, failure }

class ItemsState extends Equatable {
  const ItemsState({
    this.status = ItemsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final ItemsStatus status;
  final List<GiftItem> items;
  final String? errorMessage;

  bool get isEmpty => status == ItemsStatus.ready && items.isEmpty;

  ItemsState copyWith({
    ItemsStatus? status,
    List<GiftItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
