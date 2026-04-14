import 'uae_pass_mobile_api.dart';

/// UAE PASS idhub OAuth2-related URLs (staging vs production).
///
/// Userinfo and introspect match official STG/PROD tables. For the authorization
/// code flow, use [stagingToken] / [productionToken] (not introspect) for
/// `grant_type=authorization_code`.
abstract final class UaePassIdHubEndpoints {
  static const String _stagingBase = 'https://stg-id.uaepass.ae/idshub';
  static const String _productionBase = 'https://id.uaepass.ae/idshub';

  // --- Staging ---

  static const String stagingAuthorize = '$_stagingBase/authorize';
  static const String stagingToken = '$_stagingBase/token';
  static const String stagingUserInfo = '$_stagingBase/userinfo';
  static const String stagingIntrospect = '$_stagingBase/introspect';

  // --- Production ---

  static const String productionAuthorize = '$_productionBase/authorize';
  static const String productionToken = '$_productionBase/token';
  static const String productionUserInfo = '$_productionBase/userinfo';
  static const String productionIntrospect = '$_productionBase/introspect';

  static String authorizeUrl(UaePassEnvironment environment) {
    return switch (environment) {
      UaePassEnvironment.staging => stagingAuthorize,
      UaePassEnvironment.production => productionAuthorize,
    };
  }

  /// OAuth2 token endpoint (authorization code, refresh, etc.).
  static String tokenUrl(UaePassEnvironment environment) {
    return switch (environment) {
      UaePassEnvironment.staging => stagingToken,
      UaePassEnvironment.production => productionToken,
    };
  }

  static String userInfoUrl(UaePassEnvironment environment) {
    return switch (environment) {
      UaePassEnvironment.staging => stagingUserInfo,
      UaePassEnvironment.production => productionUserInfo,
    };
  }

  /// RFC 7662-style token introspection endpoint (not the OAuth2 code exchange URL).
  static String introspectUrl(UaePassEnvironment environment) {
    return switch (environment) {
      UaePassEnvironment.staging => stagingIntrospect,
      UaePassEnvironment.production => productionIntrospect,
    };
  }
}
