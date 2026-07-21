import 'package:equatable/equatable.dart';

/// An item on a list. Completion is derived from confirmed contributions, not
/// stored here (see `ItemProgress`).
class GiftItem extends Equatable {
  const GiftItem({
    required this.id,
    required this.listId,
    required this.title,
    required this.targetAmountCents,
    required this.allowPartial,
    required this.position,
    required this.createdAt,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String listId;
  final String title;

  /// Integer BRL cents.
  final int targetAmountCents;

  /// true = quota/"cotas" style (multiple partial gifts); false = single full
  /// contribution.
  final bool allowPartial;
  final int position;
  final DateTime createdAt;
  final String? description;
  final String? imageUrl;

  GiftItem copyWith({
    String? title,
    int? targetAmountCents,
    bool? allowPartial,
    int? position,
    String? description,
    String? imageUrl,
  }) {
    return GiftItem(
      id: id,
      listId: listId,
      title: title ?? this.title,
      targetAmountCents: targetAmountCents ?? this.targetAmountCents,
      allowPartial: allowPartial ?? this.allowPartial,
      position: position ?? this.position,
      createdAt: createdAt,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    listId,
    title,
    targetAmountCents,
    allowPartial,
    position,
    createdAt,
    description,
    imageUrl,
  ];
}

class NewItem extends Equatable {
  const NewItem({
    required this.title,
    required this.targetAmountCents,
    this.allowPartial = false,
    this.position = 0,
    this.description,
    this.imageUrl,
  });

  final String title;
  final int targetAmountCents;
  final bool allowPartial;
  final int position;
  final String? description;
  final String? imageUrl;

  @override
  List<Object?> get props => [
    title,
    targetAmountCents,
    allowPartial,
    position,
    description,
    imageUrl,
  ];
}

/// Partial update. A null field means "leave unchanged".
class ItemUpdate extends Equatable {
  const ItemUpdate({
    this.title,
    this.description,
    this.imageUrl,
    this.targetAmountCents,
    this.allowPartial,
    this.position,
  });

  final String? title;
  final String? description;
  final String? imageUrl;
  final int? targetAmountCents;
  final bool? allowPartial;
  final int? position;

  @override
  List<Object?> get props => [
    title,
    description,
    imageUrl,
    targetAmountCents,
    allowPartial,
    position,
  ];
}
