part of 'lists_cubit.dart';

enum ListsStatus { initial, loading, ready, failure }

class ListsState extends Equatable {
  const ListsState({
    this.status = ListsStatus.initial,
    this.lists = const [],
    this.profile,
    this.errorMessage,
  });

  final ListsStatus status;
  final List<GiftList> lists;
  final Profile? profile;
  final String? errorMessage;

  bool get isEmpty => status == ListsStatus.ready && lists.isEmpty;

  ListsState copyWith({
    ListsStatus? status,
    List<GiftList>? lists,
    Profile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ListsState(
      status: status ?? this.status,
      lists: lists ?? this.lists,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, lists, profile, errorMessage];
}
