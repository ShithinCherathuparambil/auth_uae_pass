import 'package:auth_uae_pass/auth_uae_pass.dart';

/// Temporary configuration for UAE PASS authentication.
/// Delete this file or clear the values when no longer needed.
class UaePassConfig {
  static const String clientSecret = 'your_client_secret';
  static const String clientId = 'your_client_id';
  static const String scheme = 'uaepassdemo';
  static const String redirectUri = 'https://your-redirect-uri.com';
  static const UaePassEnvironment env = UaePassEnvironment.staging;
  static const String authInProgressKey = 'uae_pass_auth_in_progress';
}
