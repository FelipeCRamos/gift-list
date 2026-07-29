import '../../data/models/enums.dart';

/// Human-readable labels for domain enums, kept out of the widgets so screens
/// stay declarative. (English for now; localization is a later concern.)
String occasionLabel(Occasion occasion) {
  switch (occasion) {
    case Occasion.newHome:
      return 'New home';
    case Occasion.birthday:
      return 'Birthday';
    case Occasion.wedding:
      return 'Wedding';
    case Occasion.baby:
      return 'Baby shower';
    case Occasion.graduation:
      return 'Graduation';
    case Occasion.other:
      return 'Other';
  }
}

String pixKeyTypeLabel(PixKeyType type) => type.name.toUpperCase();

String visibilityLabel(ListVisibility visibility) {
  switch (visibility) {
    case ListVisibility.public:
      return 'Public';
    case ListVisibility.private:
      return 'Private';
  }
}

String contributorAuthLabel(ContributorAuth auth) {
  switch (auth) {
    case ContributorAuth.anonymous:
      return 'Anonymous';
    case ContributorAuth.loginRequired:
      return 'Login required';
  }
}

String contributionStatusLabel(ContributionStatus status) {
  switch (status) {
    case ContributionStatus.awaitingConfirmation:
      return 'Awaiting confirmation';
    case ContributionStatus.confirmed:
      return 'Confirmed';
    case ContributionStatus.cancelled:
      return 'Cancelled';
    case ContributionStatus.expired:
      return 'Expired';
  }
}
