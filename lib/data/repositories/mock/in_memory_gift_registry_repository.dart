import 'dart:math';

import '../../../core/errors/errors.dart';
import '../../models/models.dart';
import '../auth_repository.dart';
import '../gift_registry_repository.dart';
import 'seed_data.dart';

/// In-memory [GiftRegistryRepository]. Mirrors the intended Postgres behavior
/// (access checks, lazy reservation expiry, PII-free progress) closely enough to
/// build and test the whole UI without Supabase. The real RLS guarantees arrive
/// in the Supabase phase — see docs/ARCHITECTURE.md.
class InMemoryGiftRegistryRepository implements GiftRegistryRepository {
  InMemoryGiftRegistryRepository({
    required AuthRepository auth,
    bool seed = true,
  }) : _auth = auth {
    if (seed) {
      _seed();
    }
  }

  final AuthRepository _auth;
  final Random _rng = Random();

  final Map<String, Profile> _profiles = {};
  final Map<String, GiftList> _lists = {};
  final Map<String, List<AllowlistEntry>> _allowlist = {};
  final Map<String, GiftItem> _items = {};
  final Map<String, Contribution> _contributions = {};

  static const Duration reservationTtl = Duration(minutes: 45);

  void _seed() {
    _profiles[SeedData.ownerId] = SeedData.ownerProfile();
    for (final GiftList l in SeedData.lists()) {
      _lists[l.id] = l;
    }
    _allowlist.addAll(SeedData.allowlist());
    for (final GiftItem i in SeedData.items()) {
      _items[i.id] = i;
    }
    for (final Contribution c in SeedData.contributions()) {
      _contributions[c.id] = c;
    }
  }

  // --- helpers ---------------------------------------------------------------

  String? get _uid => _auth.currentUser?.id;
  String? get _email => _auth.currentUser?.email.toLowerCase();

  String _requireUid() {
    final String? uid = _uid;
    if (uid == null) {
      throw const NotAuthenticatedException();
    }
    return uid;
  }

  String _newId(String prefix) {
    final String n = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final String t = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '$prefix-$t$n';
  }

  String _newTxid() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  String _slugify(String title) {
    final String base = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    var slug = base.isEmpty ? 'list' : base;
    while (_lists.values.any((l) => l.slug == slug)) {
      slug = '$base-${_rng.nextInt(9000) + 1000}';
    }
    return slug;
  }

  GiftList _ownedList(String id) {
    final GiftList? list = _lists[id];
    if (list == null) {
      throw const NotFoundException('List not found');
    }
    if (list.ownerId != _uid) {
      throw const AccessDeniedException();
    }
    return list;
  }

  GiftItem _ownedItem(String id) {
    final GiftItem? item = _items[id];
    if (item == null) {
      throw const NotFoundException('Item not found');
    }
    _ownedList(item.listId);
    return item;
  }

  bool _isExpired(Contribution c) =>
      c.status == ContributionStatus.awaitingConfirmation &&
      c.expiresAt.isBefore(DateTime.now());

  /// Replicates `has_list_access(list_id)` from the spec.
  bool _hasListAccess(GiftList list) {
    if (list.ownerId == _uid) {
      return true;
    }
    if (!list.isPublished) {
      return false;
    }
    switch (list.visibility) {
      case ListVisibility.public:
        return list.contributorAuth == ContributorAuth.anonymous ||
            _uid != null;
      case ListVisibility.private:
        if (_email == null) {
          return false;
        }
        final List<AllowlistEntry> entries = _allowlist[list.id] ?? const [];
        return entries.any((e) => e.email?.toLowerCase() == _email);
    }
  }

  GiftList? _listBySlug(String slug) {
    for (final GiftList l in _lists.values) {
      if (l.slug == slug) {
        return l;
      }
    }
    return null;
  }

  // --- profile ---------------------------------------------------------------

  @override
  Future<Profile?> getMyProfile() async => _profiles[_requireUid()];

  @override
  Future<Profile> saveMyProfile(Profile profile) async {
    final String uid = _requireUid();
    final saved = profile.id == uid
        ? profile
        : Profile(
            id: uid,
            displayName: profile.displayName,
            createdAt: profile.createdAt,
            defaultPixKey: profile.defaultPixKey,
            pixKeyType: profile.pixKeyType,
            merchantCity: profile.merchantCity,
          );
    _profiles[uid] = saved;
    return saved;
  }

  // --- lists -----------------------------------------------------------------

  @override
  Future<GiftList> createList(NewList data) async {
    final String uid = _requireUid();
    _validateAccessCombo(data.visibility, data.contributorAuth);
    final list = GiftList(
      id: _newId('list'),
      ownerId: uid,
      slug: _slugify(data.title),
      title: data.title,
      occasion: data.occasion,
      pixKey: data.pixKey,
      pixKeyType: data.pixKeyType,
      merchantName: data.merchantName,
      visibility: data.visibility,
      contributorAuth: data.contributorAuth,
      isPublished: false,
      createdAt: DateTime.now(),
      description: data.description,
      coverImageUrl: data.coverImageUrl,
      eventDate: data.eventDate,
    );
    _lists[list.id] = list;
    return list;
  }

  @override
  Future<GiftList> updateList(String id, ListUpdate data) async {
    final GiftList list = _ownedList(id);
    final ListVisibility visibility = data.visibility ?? list.visibility;
    final ContributorAuth auth = data.contributorAuth ?? list.contributorAuth;
    _validateAccessCombo(visibility, auth);
    final GiftList updated = list.copyWith(
      title: data.title,
      occasion: data.occasion,
      description: data.description,
      coverImageUrl: data.coverImageUrl,
      pixKey: data.pixKey,
      pixKeyType: data.pixKeyType,
      merchantName: data.merchantName,
      visibility: data.visibility,
      contributorAuth: data.contributorAuth,
      eventDate: data.eventDate,
    );
    _lists[id] = updated;
    return updated;
  }

  @override
  Future<void> setPublished(String id, bool published) async {
    final GiftList list = _ownedList(id);
    _lists[id] = list.copyWith(isPublished: published);
  }

  @override
  Future<List<GiftList>> myLists() async {
    final String uid = _requireUid();
    final List<GiftList> mine =
        _lists.values.where((l) => l.ownerId == uid).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  @override
  Future<GiftList> getMyList(String id) async => _ownedList(id);

  void _validateAccessCombo(ListVisibility v, ContributorAuth a) {
    if (v == ListVisibility.private && a == ContributorAuth.anonymous) {
      throw const ValidationException(
        'A private list requires login_required contributors.',
      );
    }
  }

  // --- allowlist -------------------------------------------------------------

  @override
  Future<List<AllowlistEntry>> getAllowlist(String listId) async {
    _ownedList(listId);
    return List.unmodifiable(_allowlist[listId] ?? const []);
  }

  @override
  Future<void> setAllowlist(String listId, List<AllowlistEntry> entries) async {
    _ownedList(listId);
    _allowlist[listId] = entries
        .map(
          (e) => AllowlistEntry(
            id: e.id ?? _newId('al'),
            email: e.email?.trim().toLowerCase(),
            phone: e.phone?.trim(),
          ),
        )
        .toList();
  }

  // --- items -----------------------------------------------------------------

  @override
  Future<GiftItem> addItem(String listId, NewItem data) async {
    _ownedList(listId);
    final item = GiftItem(
      id: _newId('item'),
      listId: listId,
      title: data.title,
      targetAmountCents: data.targetAmountCents,
      allowPartial: data.allowPartial,
      position: data.position,
      createdAt: DateTime.now(),
      description: data.description,
      imageUrl: data.imageUrl,
    );
    _items[item.id] = item;
    return item;
  }

  @override
  Future<GiftItem> updateItem(String id, ItemUpdate data) async {
    final GiftItem item = _ownedItem(id);
    final GiftItem updated = item.copyWith(
      title: data.title,
      description: data.description,
      imageUrl: data.imageUrl,
      targetAmountCents: data.targetAmountCents,
      allowPartial: data.allowPartial,
      position: data.position,
    );
    _items[id] = updated;
    return updated;
  }

  @override
  Future<void> removeItem(String id) async {
    _ownedItem(id);
    _items.remove(id);
    _contributions.removeWhere((_, c) => c.itemId == id);
  }

  @override
  Future<List<GiftItem>> itemsForList(String listId) async {
    _ownedList(listId);
    return _itemsSorted(listId);
  }

  List<GiftItem> _itemsSorted(String listId) {
    final List<GiftItem> list =
        _items.values.where((i) => i.listId == listId).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  // --- contributions inbox ---------------------------------------------------

  @override
  Future<List<Contribution>> contributionsForList(String listId) async {
    _ownedList(listId);
    final List<Contribution> rows =
        _contributions.values.where((c) => c.listId == listId).map((c) {
          return _isExpired(c)
              ? c.copyWith(status: ContributionStatus.expired)
              : c;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  @override
  Future<void> confirmContribution(String id) async {
    final Contribution c = _requireOwnedContribution(id);
    _contributions[id] = c.copyWith(
      status: ContributionStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
  }

  @override
  Future<void> rejectContribution(String id) async {
    final Contribution c = _requireOwnedContribution(id);
    _contributions[id] = c.copyWith(status: ContributionStatus.cancelled);
  }

  Contribution _requireOwnedContribution(String id) {
    final Contribution? c = _contributions[id];
    if (c == null) {
      throw const NotFoundException('Contribution not found');
    }
    _ownedList(c.listId);
    return c;
  }

  // --- public / contributor --------------------------------------------------

  @override
  Future<ListAccessInfo> getListAccessInfo(String slug) async {
    final GiftList? list = _listBySlug(slug);
    if (list == null) {
      return const ListAccessInfo.notFound();
    }
    // Unpublished drafts are invisible to everyone but the owner.
    if (!list.isPublished && list.ownerId != _uid) {
      return const ListAccessInfo.notFound();
    }
    return ListAccessInfo(
      exists: true,
      title: list.title,
      coverImageUrl: list.coverImageUrl,
      visibility: list.visibility,
      contributorAuth: list.contributorAuth,
    );
  }

  @override
  Future<PublicList> getPublicList(String slug) async {
    final GiftList list = _requireAccessibleList(slug);
    final Profile? ownerProfile = _profiles[list.ownerId];
    return PublicList(
      slug: list.slug,
      title: list.title,
      occasion: list.occasion,
      merchantName: list.merchantName,
      merchantCity: ownerProfile?.merchantCity ?? '',
      pixKey: list.pixKey,
      pixKeyType: list.pixKeyType,
      items: _itemsSorted(list.id),
      description: list.description,
      coverImageUrl: list.coverImageUrl,
      eventDate: list.eventDate,
    );
  }

  @override
  Future<List<ItemProgress>> publicProgress(String slug) async {
    final GiftList list = _requireAccessibleList(slug);
    return _itemsSorted(list.id).map(_progressFor).toList();
  }

  ItemProgress _progressFor(GiftItem item) {
    var confirmed = 0;
    var reserved = 0;
    for (final Contribution c in _contributions.values) {
      if (c.itemId != item.id) {
        continue;
      }
      if (c.status == ContributionStatus.confirmed) {
        confirmed += c.amountCents;
      } else if (c.status == ContributionStatus.awaitingConfirmation &&
          !_isExpired(c)) {
        reserved += c.amountCents;
      }
    }
    final ItemState state;
    if (confirmed >= item.targetAmountCents) {
      state = ItemState.complete;
    } else if (reserved > 0) {
      state = ItemState.reserved;
    } else {
      state = ItemState.open;
    }
    return ItemProgress(
      itemId: item.id,
      targetAmountCents: item.targetAmountCents,
      confirmedCents: confirmed,
      reservedCents: reserved,
      state: state,
    );
  }

  GiftList _requireAccessibleList(String slug) {
    final GiftList? list = _listBySlug(slug);
    if (list == null) {
      throw const NotFoundException('List not found');
    }
    if (!_hasListAccess(list)) {
      throw const AccessDeniedException();
    }
    return list;
  }

  @override
  Future<Contribution> createContribution(NewContribution data) async {
    final GiftItem? item = _items[data.itemId];
    if (item == null) {
      throw const NotFoundException('Item not found');
    }
    final GiftList? list = _lists[item.listId];
    if (list == null) {
      throw const NotFoundException('List not found');
    }
    if (!list.isPublished || !_hasListAccess(list)) {
      throw const AccessDeniedException();
    }
    // Enforce the auth mode (mirrors the contributions INSERT policy).
    if (list.contributorAuth == ContributorAuth.loginRequired && _uid == null) {
      throw const NotAuthenticatedException();
    }

    // Enforce availability (allow_partial cap / whole-item reservation). The
    // repository is authoritative; the cubit mirrors this for UX.
    if (data.amountCents < 1) {
      throw const ValidationException('Amount must be greater than zero.');
    }
    final ItemProgress progress = _progressFor(item);
    final int remaining =
        item.targetAmountCents -
        progress.confirmedCents -
        progress.reservedCents;
    if (item.allowPartial) {
      if (data.amountCents > remaining) {
        throw const ValidationException(
          'That is more than the amount still open for this item.',
        );
      }
    } else {
      if (progress.confirmedCents > 0 || progress.reservedCents > 0) {
        throw const ValidationException('This item is no longer available.');
      }
      if (data.amountCents != item.targetAmountCents) {
        throw const ValidationException('This item must be gifted in full.');
      }
    }

    final now = DateTime.now();
    final contribution = Contribution(
      id: _newId('contrib'),
      itemId: data.itemId,
      listId: item.listId,
      giverName: data.giverName,
      amountCents: data.amountCents,
      status: ContributionStatus.awaitingConfirmation,
      pixTxid: _newTxid(),
      createdAt: now,
      expiresAt: now.add(reservationTtl),
      contributorId: _uid,
      giverMessage: data.giverMessage,
    );
    _contributions[contribution.id] = contribution;
    return contribution;
  }
}
