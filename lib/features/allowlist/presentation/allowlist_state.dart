part of 'allowlist_cubit.dart';

enum AllowlistStatus { initial, loading, ready, failure }

class AllowlistState extends Equatable {
  const AllowlistState({
    this.status = AllowlistStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  final AllowlistStatus status;
  final List<AllowlistEntry> entries;
  final String? errorMessage;

  bool get isEmpty => status == AllowlistStatus.ready && entries.isEmpty;

  AllowlistState copyWith({
    AllowlistStatus? status,
    List<AllowlistEntry>? entries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AllowlistState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}
