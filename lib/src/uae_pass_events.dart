/// Events emitted by the UAE PASS SDK for analytics and tracking.
enum UaePassEvent {
  /// Authentication flow has been initiated.
  authStarted,

  /// The internal WebView has been loaded.
  webviewLoaded,

  /// Redirection back to the app (resumption) has been captured.
  resumptionCaptured,

  /// Authorization code successfully exchanged for a token.
  tokenExchanged,

  /// User profile successfully fetched.
  profileFetched,

  /// The user has successfully logged in.
  loginSuccess,

  /// The user cancelled the authentication flow.
  cancelled,

  /// An error occurred during the authentication flow.
  error,

  /// Logout flow has been initiated.
  logoutStarted,

  /// Logout completed successfully.
  logoutSuccess,
}
