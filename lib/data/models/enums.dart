/// Domain enums with stable wire values matching the Postgres text enums.
///
/// Each enum carries the exact string persisted in the database so the mock
/// and Supabase repositories agree on serialization.
library;

enum Occasion {
  newHome('new_home'),
  birthday('birthday'),
  wedding('wedding'),
  baby('baby'),
  graduation('graduation'),
  other('other');

  const Occasion(this.wire);

  final String wire;

  static Occasion fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

enum PixKeyType {
  email('email'),
  phone('phone'),
  cpf('cpf'),
  cnpj('cnpj'),
  evp('evp');

  const PixKeyType(this.wire);

  final String wire;

  static PixKeyType fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// List visibility axis. Named `ListVisibility` to avoid clashing with
/// Flutter's `Visibility` widget.
enum ListVisibility {
  public('public'),
  private('private');

  const ListVisibility(this.wire);

  final String wire;

  static ListVisibility fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Contributor authentication axis. `private` implies `loginRequired`.
enum ContributorAuth {
  anonymous('anonymous'),
  loginRequired('login_required');

  const ContributorAuth(this.wire);

  final String wire;

  static ContributorAuth fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

enum ContributionStatus {
  awaitingConfirmation('awaiting_confirmation'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  expired('expired');

  const ContributionStatus(this.wire);

  final String wire;

  static ContributionStatus fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Derived per-item state exposed by the access-aware progress read.
enum ItemState {
  open('open'),
  reserved('reserved'),
  complete('complete');

  const ItemState(this.wire);

  final String wire;

  static ItemState fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}
