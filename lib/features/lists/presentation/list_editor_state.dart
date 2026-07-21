part of 'list_editor_cubit.dart';

enum ListEditorStatus { initial, loading, ready, saving, saved, failure }

class ListEditorState extends Equatable {
  const ListEditorState({
    this.status = ListEditorStatus.initial,
    this.list,
    this.visibility = ListVisibility.public,
    this.contributorAuth = ContributorAuth.anonymous,
    this.isPublished = false,
    this.errorMessage,
  });

  final ListEditorStatus status;
  final GiftList? list;
  final ListVisibility visibility;
  final ContributorAuth contributorAuth;
  final bool isPublished;
  final String? errorMessage;

  /// Contributor auth is locked to `login_required` whenever the list is
  /// private (the `private ⇒ login_required` invariant).
  bool get authLocked => visibility == ListVisibility.private;

  bool get isPrivate => visibility == ListVisibility.private;

  ListEditorState copyWith({
    ListEditorStatus? status,
    GiftList? list,
    ListVisibility? visibility,
    ContributorAuth? contributorAuth,
    bool? isPublished,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ListEditorState(
      status: status ?? this.status,
      list: list ?? this.list,
      visibility: visibility ?? this.visibility,
      contributorAuth: contributorAuth ?? this.contributorAuth,
      isPublished: isPublished ?? this.isPublished,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    list,
    visibility,
    contributorAuth,
    isPublished,
    errorMessage,
  ];
}
