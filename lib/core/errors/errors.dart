/// Typed errors thrown by repositories. Cubits translate these into UI states;
/// exceptions never leak to the widget tree.
library;

/// Base type for all repository-layer failures.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The caller is not allowed to view/act on the requested resource (RLS denial
/// or gate failure).
class AccessDeniedException extends AppException {
  const AccessDeniedException([super.message = 'Access denied']);
}

/// Authentication is required but the caller is anonymous.
class NotAuthenticatedException extends AppException {
  const NotAuthenticatedException([super.message = 'Authentication required']);
}

/// The requested resource does not exist.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

/// A domain rule was violated (e.g. private + anonymous, or a bad Pix field).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// A generic backend/repository failure.
class RepositoryException extends AppException {
  const RepositoryException([super.message = 'Something went wrong']);
}
