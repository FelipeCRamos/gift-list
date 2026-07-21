import 'package:equatable/equatable.dart';

/// One permitted contact for a `private` list. At least one of email/phone is
/// non-null (DB CHECK). Phone is deferred until SMS auth is funded — email is
/// the free path.
class AllowlistEntry extends Equatable {
  const AllowlistEntry({this.id, this.email, this.phone});

  final String? id;

  /// Lowercased.
  final String? email;

  /// E.164.
  final String? phone;

  @override
  List<Object?> get props => [id, email, phone];
}
