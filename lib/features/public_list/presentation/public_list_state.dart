part of 'public_list_cubit.dart';

enum PublicListStatus { initial, loading, ready, failure }

class PublicListState extends Equatable {
  const PublicListState({
    this.status = PublicListStatus.initial,
    this.list,
    this.progress = const {},
    this.errorMessage,
  });

  final PublicListStatus status;
  final PublicList? list;
  final Map<String, ItemProgress> progress;
  final String? errorMessage;

  ItemProgress? progressFor(String itemId) => progress[itemId];

  PublicListState copyWith({
    PublicListStatus? status,
    PublicList? list,
    Map<String, ItemProgress>? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublicListState(
      status: status ?? this.status,
      list: list ?? this.list,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, list, progress, errorMessage];
}
