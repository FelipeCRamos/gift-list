import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'gift_item.dart';

/// Anon-readable gate metadata returned by `list_access_info(slug)`. Carries no
/// items, amounts, or allowlist — only what the UI needs to render the right
/// gate ("sign in" vs "private") before any access-checked content read.
class ListAccessInfo extends Equatable {
  const ListAccessInfo({
    required this.exists,
    this.title,
    this.coverImageUrl,
    this.visibility,
    this.contributorAuth,
  });

  const ListAccessInfo.notFound()
    : exists = false,
      title = null,
      coverImageUrl = null,
      visibility = null,
      contributorAuth = null;

  final bool exists;
  final String? title;
  final String? coverImageUrl;
  final ListVisibility? visibility;
  final ContributorAuth? contributorAuth;

  @override
  List<Object?> get props => [
    exists,
    title,
    coverImageUrl,
    visibility,
    contributorAuth,
  ];
}

/// Access-checked public view of a list: the fields a contributor needs to
/// render items and build a Pix payload. No owner PII, no other givers' data.
class PublicList extends Equatable {
  const PublicList({
    required this.slug,
    required this.title,
    required this.occasion,
    required this.merchantName,
    required this.merchantCity,
    required this.pixKey,
    required this.pixKeyType,
    required this.items,
    this.description,
    this.coverImageUrl,
    this.eventDate,
  });

  final String slug;
  final String title;
  final Occasion occasion;
  final String merchantName;
  final String merchantCity;
  final String pixKey;
  final PixKeyType pixKeyType;
  final List<GiftItem> items;
  final String? description;
  final String? coverImageUrl;
  final DateTime? eventDate;

  @override
  List<Object?> get props => [
    slug,
    title,
    occasion,
    merchantName,
    merchantCity,
    pixKey,
    pixKeyType,
    items,
    description,
    coverImageUrl,
    eventDate,
  ];
}

/// PII-free per-item progress from `public_item_progress(slug)`.
class ItemProgress extends Equatable {
  const ItemProgress({
    required this.itemId,
    required this.targetAmountCents,
    required this.confirmedCents,
    required this.reservedCents,
    required this.state,
  });

  final String itemId;
  final int targetAmountCents;
  final int confirmedCents;

  /// Sum of non-expired `awaiting_confirmation` contributions.
  final int reservedCents;
  final ItemState state;

  @override
  List<Object?> get props => [
    itemId,
    targetAmountCents,
    confirmedCents,
    reservedCents,
    state,
  ];
}
