import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Extends `auth.users` 1:1. Every authenticated user has one; Pix fields stay
/// null for pure contributors.
class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    this.defaultPixKey,
    this.pixKeyType,
    this.merchantCity,
  });

  final String id;
  final String displayName;
  final DateTime createdAt;
  final String? defaultPixKey;
  final PixKeyType? pixKeyType;

  /// ASCII, <=15 chars — used as Pix Merchant City (field 60).
  final String? merchantCity;

  Profile copyWith({
    String? displayName,
    String? defaultPixKey,
    PixKeyType? pixKeyType,
    String? merchantCity,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      defaultPixKey: defaultPixKey ?? this.defaultPixKey,
      pixKeyType: pixKeyType ?? this.pixKeyType,
      merchantCity: merchantCity ?? this.merchantCity,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    createdAt,
    defaultPixKey,
    pixKeyType,
    merchantCity,
  ];
}
