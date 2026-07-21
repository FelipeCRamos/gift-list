/// Central route paths. Feature routes will move into per-feature
/// `{feature}_routes.dart` files as phases land; the templates live here so the
/// router and navigation helpers agree.
abstract final class RoutePaths {
  // Public / gated
  static const String landing = '/';
  static const String listView = '/l/:slug';
  static const String gift = '/l/:slug/gift/:itemId';
  static const String thanks = '/l/:slug/thanks';

  // Authed (creator dashboard)
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String profile = '/dashboard/profile';
  static const String listEdit = '/dashboard/lists/:id/edit';
  static const String listAllowlist = '/dashboard/lists/:id/allowlist';
  static const String listItems = '/dashboard/lists/:id/items';
  static const String listContributions = '/dashboard/lists/:id/contributions';

  // Builders for navigation.
  static String toListView(String slug) => '/l/$slug';
  static String toGift(String slug, String itemId) => '/l/$slug/gift/$itemId';
  static String toThanks(String slug) => '/l/$slug/thanks';
  static String toListEdit(String id) => '/dashboard/lists/$id/edit';
  static String toListAllowlist(String id) => '/dashboard/lists/$id/allowlist';
  static String toListItems(String id) => '/dashboard/lists/$id/items';
  static String toListContributions(String id) =>
      '/dashboard/lists/$id/contributions';
}
