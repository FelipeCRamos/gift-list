import '../models/models.dart';

/// The single cross-feature data boundary for lists, items, allowlist,
/// contributions, and the public/contributor reads. Supabase (and the in-memory
/// mock) implement this; the UI and cubits never see the backend.
///
/// Access-checked methods throw [AccessDeniedException] when the caller lacks
/// access; missing resources throw [NotFoundException].
abstract class GiftRegistryRepository {
  // --- Owner: profile ---
  Future<Profile?> getMyProfile();
  Future<Profile> saveMyProfile(Profile profile);

  // --- Owner: lists ---
  Future<GiftList> createList(NewList data);
  Future<GiftList> updateList(String id, ListUpdate data);
  Future<void> setPublished(String id, bool published);
  Future<List<GiftList>> myLists();
  Future<GiftList> getMyList(String id);

  // --- Owner: allowlist ---
  Future<List<AllowlistEntry>> getAllowlist(String listId);
  Future<void> setAllowlist(String listId, List<AllowlistEntry> entries);

  // --- Owner: items ---
  Future<GiftItem> addItem(String listId, NewItem data);
  Future<GiftItem> updateItem(String id, ItemUpdate data);
  Future<void> removeItem(String id);
  Future<List<GiftItem>> itemsForList(String listId);

  // --- Owner: contributions inbox ---
  Future<List<Contribution>> contributionsForList(String listId);
  Future<void> confirmContribution(String id);
  Future<void> rejectContribution(String id);

  // --- Public / contributor ---
  /// Anon-readable gate metadata; never throws for access — returns
  /// [ListAccessInfo.notFound] when the slug is unknown.
  Future<ListAccessInfo> getListAccessInfo(String slug);

  /// Access-checked; throws [AccessDeniedException] per the gate rules.
  Future<PublicList> getPublicList(String slug);

  /// Access-checked, PII-free per-item progress.
  Future<List<ItemProgress>> publicProgress(String slug);

  /// Creates a contribution (anonymous or authenticated).
  Future<Contribution> createContribution(NewContribution data);
}
