import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyMobileAcrValues sets mobile-on-device when app installed', () {
    final Uri base = Uri.parse(
      'https://stg-id.uaepass.ae/idshub/authorize?client_id=x&response_type=code',
    );
    final Uri withMobile = applyMobileAcrValues(
      base,
      uaePassAppInstalled: true,
    );
    expect(withMobile.queryParameters['acr_values'], kUaePassAcrMobileOnDevice);

    final Uri withWeb = applyMobileAcrValues(base, uaePassAppInstalled: false);
    expect(withWeb.queryParameters['acr_values'], kUaePassAcrWebFallback);
  });

  test('rewriteUaePassDeepLinkForSp wraps success and failure URLs', () {
    final Uri deep = Uri.parse(
      'uaepassstg://auth?successURL=https%3A%2F%2Fa.example%2Fok&failureURL=https%3A%2F%2Fb.example%2Ffail',
    );
    final Uri sp = Uri.parse('myapp://oauth/callback');
    final Uri out = rewriteUaePassDeepLinkForSp(
      uaePassDeepLink: deep,
      spRedirectUri: sp,
      resumeAuthnPath: 'resume_authn',
    );
    expect(out.queryParameters['successurl'], startsWith('myapp:'));
    expect(out.queryParameters['failureurl'], startsWith('myapp:'));
  });

  test('applyVisitorIntegrationScopes sets documented visitor scope string', () {
    final Uri base = Uri.parse(
      'https://stg-id.uaepass.ae/idshub/authorize?client_id=x&response_type=code&scope=urn%3Auae%3Adigitalid%3Aprofile%3Ageneral',
    );
    final Uri out = applyVisitorIntegrationScopes(base);
    expect(out.queryParameters['scope'], kUaePassVisitorFirstAuthScope);
    expect(out.queryParameters['scope'], contains('unifiedId'));
    expect(out.queryParameters['scope'], contains('profileType'));
  });

  test('isSpResumeAuthnCallback detects resume path and validates scheme', () {
    final Uri sp = Uri.parse('myapp://oauth/callback');
    final Uri resume = Uri.parse(
      'myapp:///resume_authn?url=https%3A%2F%2Fstg-id.uaepass.ae%2Fcb',
    );
    expect(
      isSpResumeAuthnCallback(
        uri: resume,
        spRedirectUri: sp,
        resumeAuthnPath: 'resume_authn',
        deepLinkScheme: 'myapp',
      ),
      isTrue,
    );

    // Should fail if scheme mismatch
    expect(
      isSpResumeAuthnCallback(
        uri: resume,
        spRedirectUri: sp,
        resumeAuthnPath: 'resume_authn',
        deepLinkScheme: 'otherapp',
      ),
      isFalse,
    );
  });
}
