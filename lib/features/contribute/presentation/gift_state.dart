part of 'gift_cubit.dart';

enum GiftStatus {
  initial,
  loading,
  ready,
  submitting,
  awaitingPayment,
  unavailable,
  denied,
  failure,
}

class GiftState extends Equatable {
  const GiftState({
    this.status = GiftStatus.initial,
    this.list,
    this.item,
    this.remainingCents = 0,
    this.giverName = '',
    this.contribution,
    this.instruction,
    this.errorMessage,
  });

  final GiftStatus status;
  final PublicList? list;
  final GiftItem? item;
  final int remainingCents;
  final String giverName;
  final Contribution? contribution;
  final PaymentInstruction? instruction;
  final String? errorMessage;

  bool get isBusy =>
      status == GiftStatus.loading || status == GiftStatus.submitting;

  bool get isPartial => item?.allowPartial ?? false;

  GiftState copyWith({
    GiftStatus? status,
    PublicList? list,
    GiftItem? item,
    int? remainingCents,
    String? giverName,
    Contribution? contribution,
    PaymentInstruction? instruction,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GiftState(
      status: status ?? this.status,
      list: list ?? this.list,
      item: item ?? this.item,
      remainingCents: remainingCents ?? this.remainingCents,
      giverName: giverName ?? this.giverName,
      contribution: contribution ?? this.contribution,
      instruction: instruction ?? this.instruction,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    list,
    item,
    remainingCents,
    giverName,
    contribution,
    instruction,
    errorMessage,
  ];
}
