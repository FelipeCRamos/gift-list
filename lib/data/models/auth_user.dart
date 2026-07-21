import 'package:equatable/equatable.dart';

/// The authenticated caller. `null` everywhere means an anonymous visitor.
class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
