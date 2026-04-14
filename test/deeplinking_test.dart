import 'package:flutter_test/flutter_test.dart';
import 'package:auth_uae_pass/src/uae_pass_mobile_api.dart';

void main() {
  test('rewrite fails intentionally to print urls', () {
    final initialDeepLink = Uri.parse('uaepassstg://digitalid.ae?successURL=https://highlight.app/callback?status=ok&failureURL=https://highlight.app/callback?status=error');
    final spRedirect = Uri.parse('https://highlight.app/callback');
    
    final rewritten = rewriteUaePassDeepLinkForSp(
      uaePassDeepLink: initialDeepLink,
      spRedirectUri: spRedirect,
      resumeAuthnPath: 'resume_authn',
    );
    
    final successurl = rewritten.queryParameters['successurl'];
    expect(successurl, startsWith('https://highlight.app/resume_authn?url=https%3A%2F%2Fhighlight.app'));
  });
}
