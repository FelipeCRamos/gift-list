part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, ready, saving, saved, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  bool get isBusy =>
      status == ProfileStatus.loading || status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
