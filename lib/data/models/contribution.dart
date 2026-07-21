import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A gift toward an item. `contributorId` is set when the giver is signed in,
/// null when anonymous. Progress counts `confirmed` rows only.
class Contribution extends Equatable {
  const Contribution({
    required this.id,
    required this.itemId,
    required this.listId,
    required this.giverName,
    required this.amountCents,
    required this.status,
    required this.pixTxid,
    required this.createdAt,
    required this.expiresAt,
    this.contributorId,
    this.giverMessage,
    this.confirmedAt,
  });

  final String id;
  final String itemId;
  final String listId;

  /// Typed for anonymous; prefilled from profile for signed-in givers.
  final String giverName;
  final int amountCents;
  final ContributionStatus status;

  /// Reference embedded in the BR Code (field 62.05) for cross-checking.
  final String pixTxid;
  final DateTime createdAt;

  /// Soft reservation TTL. Treated as expired at read time (lazy expiry).
  final DateTime expiresAt;
  final String? contributorId;
  final String? giverMessage;
  final DateTime? confirmedAt;

  Contribution copyWith({ContributionStatus? status, DateTime? confirmedAt}) {
    return Contribution(
      id: id,
      itemId: itemId,
      listId: listId,
      giverName: giverName,
      amountCents: amountCents,
      status: status ?? this.status,
      pixTxid: pixTxid,
      createdAt: createdAt,
      expiresAt: expiresAt,
      contributorId: contributorId,
      giverMessage: giverMessage,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemId,
    listId,
    giverName,
    amountCents,
    status,
    pixTxid,
    createdAt,
    expiresAt,
    contributorId,
    giverMessage,
    confirmedAt,
  ];
}

/// Payload for creating a contribution. The repository/service assigns
/// `status`, `pixTxid`, and `expiresAt`.
class NewContribution extends Equatable {
  const NewContribution({
    required this.itemId,
    required this.listId,
    required this.giverName,
    required this.amountCents,
    this.contributorId,
    this.giverMessage,
  });

  final String itemId;
  final String listId;
  final String giverName;
  final int amountCents;
  final String? contributorId;
  final String? giverMessage;

  @override
  List<Object?> get props => [
    itemId,
    listId,
    giverName,
    amountCents,
    contributorId,
    giverMessage,
  ];
}
