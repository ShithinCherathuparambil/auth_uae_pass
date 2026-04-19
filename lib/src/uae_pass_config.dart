import 'uae_pass_mobile_api.dart';

/// Configuration for UAE PASS authentication.
///
/// Grouping credentials and environment settings into this object improves
/// Developer Experience (DX) by reducing the number of parameters needed in
/// [AuthUaePass] methods.
class UaePassConfig {
  const UaePassConfig({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    this.environment = UaePassEnvironment.staging,
    this.uiLocale = 'en',
    this.applyMobileAcrValues = true,
    this.deepLinkScheme,
    this.acrValues,
  });

  /// Client ID provided by UAE Pass Service Provider portal.
  final String clientId;

  /// Client Secret provided by UAE Pass Service Provider portal.
  final String clientSecret;

  /// Redirect URI registered in the UAE Pass Service Provider portal.
  /// Must match the scheme/URL exactly.
  final String redirectUri;

  /// Whether to use the staging or production environment.
  final UaePassEnvironment environment;

  /// Default UI locale for authentication screens ('en' or 'ar').
  final String uiLocale;

  /// When true, the SDK automatically detects if the UAE PASS app is installed
  /// and applies the appropriate `acr_values`.
  final bool applyMobileAcrValues;

  /// The custom URL scheme used for deep linking (e.g., 'myapp').
  /// If provided, it helps in rewriting UAE Pass internal links to use your app's scheme.
  final String? deepLinkScheme;

  /// Optional ACR values to request a specific SOP level (e.g., 'urn:uae:digitalid:profile:general:sop3').
  final String? acrValues;

  /// Returns a copy of this config with the given fields replaced.
  UaePassConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? redirectUri,
    UaePassEnvironment? environment,
    String? uiLocale,
    bool? applyMobileAcrValues,
    String? deepLinkScheme,
    String? acrValues,
  }) {
    return UaePassConfig(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      redirectUri: redirectUri ?? this.redirectUri,
      environment: environment ?? this.environment,
      uiLocale: uiLocale ?? this.uiLocale,
      applyMobileAcrValues: applyMobileAcrValues ?? this.applyMobileAcrValues,
      deepLinkScheme: deepLinkScheme ?? this.deepLinkScheme,
      acrValues: acrValues ?? this.acrValues,
    );
  }
}
