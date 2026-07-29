part of 'contributions_cubit.dart';

enum ContributionsStatus { initial, loading, ready, failure }

class ContributionsState extends Equatable {
  const ContributionsState({
    this.status = ContributionsStatus.initial,
    this.listTitle = '',
    this.contributions = const [],
    this.busyIds = const {},
    this.errorMessage,
  });

  final ContributionsStatus status;
  final String listTitle;
  final List<Contribution> contributions;
  final Set<String> busyIds;
  final String? errorMessage;

  bool get isEmpty =>
      status == ContributionsStatus.ready && contributions.isEmpty;

  /// Reservations needing the creator's action, oldest first.
  List<Contribution> get awaiting =>
      _byStatus([ContributionStatus.awaitingConfirmation]);

  /// The thank-you wall.
  List<Contribution> get confirmed => _byStatus([ContributionStatus.confirmed]);

  /// Expired reservations and rejected gifts.
  List<Contribution> get closed =>
      _byStatus([ContributionStatus.expired, ContributionStatus.cancelled]);

  List<Contribution> _byStatus(List<ContributionStatus> statuses) =>
      contributions.where((c) => statuses.contains(c.status)).toList();

  bool isBusy(String id) => busyIds.contains(id);

  ContributionsState withBusy(String id) => copyWith(busyIds: {...busyIds, id});

  ContributionsState withoutBusy(String id) =>
      copyWith(busyIds: {...busyIds}..remove(id));

  ContributionsState copyWith({
    ContributionsStatus? status,
    String? listTitle,
    List<Contribution>? contributions,
    Set<String>? busyIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContributionsState(
      status: status ?? this.status,
      listTitle: listTitle ?? this.listTitle,
      contributions: contributions ?? this.contributions,
      busyIds: busyIds ?? this.busyIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    listTitle,
    contributions,
    busyIds,
    errorMessage,
  ];
}
