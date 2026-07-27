part of 'list_gate_cubit.dart';

/// The gate decision for `/l/:slug`.
/// - [loading]: resolving.
/// - [ready]: access granted — load and show the list.
/// - [needsLogin]: public but login_required, and no session.
/// - [private]: private list viewed without a session.
/// - [noAccess]: signed in but not on the allowlist.
/// - [notFound]: unknown slug (or an unpublished draft to a non-owner).
/// - [error]: unexpected failure.
enum GateStatus {
  loading,
  ready,
  needsLogin,
  private,
  noAccess,
  notFound,
  error,
}

class ListGateState extends Equatable {
  const ListGateState({
    this.status = GateStatus.loading,
    this.info,
    this.errorMessage,
  });

  final GateStatus status;
  final ListAccessInfo? info;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, info, errorMessage];
}
