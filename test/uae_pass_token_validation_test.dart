import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('denies when active is false', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{'active': false},
    );
    final UaePassTokenValidationDecision d = evaluateIntrospectAccess(
      r,
      const UaePassTokenValidationRules(),
    );
    expect(d.accessAllowed, isFalse);
    expect(d.denialCode, UaePassTokenValidationDenialCode.tokenInactive);
  });

  test('denies when introspect is null', () {
    final UaePassTokenValidationDecision d = evaluateIntrospectAccess(
      null,
      const UaePassTokenValidationRules(),
    );
    expect(d.accessAllowed, isFalse);
    expect(
      d.denialCode,
      UaePassTokenValidationDenialCode.introspectUnavailable,
    );
  });

  test('allows active token with no extra rules', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{'active': true, 'client_id': 'any'},
    );
    final UaePassTokenValidationDecision d = evaluateIntrospectAccess(
      r,
      const UaePassTokenValidationRules(),
    );
    expect(d.accessAllowed, isTrue);
  });

  test('enforces client_id', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{'active': true, 'client_id': 'sdg_digivault'},
    );
    expect(
      evaluateIntrospectAccess(
        r,
        const UaePassTokenValidationRules(expectedClientId: 'sdg_digivault'),
      ).accessAllowed,
      isTrue,
    );
    expect(
      evaluateIntrospectAccess(
        r,
        const UaePassTokenValidationRules(expectedClientId: 'other'),
      ).denialCode,
      UaePassTokenValidationDenialCode.clientIdMismatch,
    );
  });

  test('enforces client_claims', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{
        'active': true,
        'client_id': 'sdg_digivault',
        'client_claims': <String, dynamic>{
          'name': 'SDG Digital Vault App',
          'sub': 'sdg_digitalvault',
        },
      },
    );
    expect(
      evaluateIntrospectAccess(
        r,
        const UaePassTokenValidationRules(
          clientClaimMatchers: <String, String>{
            'name': 'SDG Digital Vault App',
          },
        ),
      ).accessAllowed,
      isTrue,
    );
  });

  test('enforces required scopes', () {
    final UaePassIntrospectResult
    r = UaePassIntrospectResult.fromJson(<String, dynamic>{
      'active': true,
      'scope':
          'urn:uae:digitalid:profile:general urn:uae:digitalid:profile:general:profileType',
    });
    expect(
      evaluateIntrospectAccess(
        r,
        const UaePassTokenValidationRules(
          requiredScopes: <String>['urn:uae:digitalid:profile:general'],
        ),
      ).accessAllowed,
      isTrue,
    );
    expect(
      evaluateIntrospectAccess(
        r,
        const UaePassTokenValidationRules(
          requiredScopes: <String>['urn:missing:scope'],
        ),
      ).denialCode,
      UaePassTokenValidationDenialCode.scopeInsufficient,
    );
  });
}
