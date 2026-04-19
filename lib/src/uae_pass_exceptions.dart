/// Base class for all UAE PASS related exceptions.
class UaePassException implements Exception {
  UaePassException(this.message, {this.code});

  /// Human-readable error message.
  final String message;

  /// Optional technical error code.
  final String? code;

  @override
  String toString() => 'UaePassException: $message ${code != null ? '($code)' : ''}';
}

/// Thrown when authentication is cancelled by the user.
class UaePassCancelledException extends UaePassException {
  UaePassCancelledException() : super('User cancelled the authentication flow.', code: 'USER_CANCELLED');
}

/// Thrown when there is an error during the OAuth2 token exchange.
class UaePassTokenException extends UaePassException {
  UaePassTokenException(super.message, {super.code});
}

/// Thrown when there is an error fetching the user profile.
class UaePassProfileException extends UaePassException {
  UaePassProfileException(super.message, {super.code});
}

/// Thrown when the user's documents are not verified on UAE PASS.
class UaePassDocumentsNotVerifiedException extends UaePassException {
  UaePassDocumentsNotVerifiedException({String? message})
      : super(
          message ?? 'User documents are not verified in UAE PASS app.',
          code: 'DOCUMENTS_NOT_VERIFIED',
        );
}
