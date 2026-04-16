import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UaePassIntrospectResult parses inactive token only', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{'active': false},
    );
    expect(r.active, isFalse);
    expect(r.tokenType, isNull);
  });

  test('UaePassIntrospectResult parses full valid response', () {
    final UaePassIntrospectResult r = UaePassIntrospectResult.fromJson(
      <String, dynamic>{
        'active': true,
        'token_type': 'Bearer',
        'scope': 'urn:uae:digitalid:profile:general',
        'exp': 1735689600,
        'iat': 1735603200,
        'iss': 'https://stg-id.uaepass.ae',
        'client_id': 'client-1',
        'client_claims': <String, dynamic>{'foo': 'bar'},
        'sub': 'user-sub',
        'user_claims': <String, dynamic>{'name': 'Test'},
        'times_verified': 0,
      },
    );
    expect(r.active, isTrue);
    expect(r.tokenType, 'Bearer');
    expect(r.scope, contains('urn:uae'));
    expect(r.exp, 1735689600);
    expect(r.iat, 1735603200);
    expect(r.clientId, 'client-1');
    expect(r.sub, 'user-sub');
    expect(r.timesVerified, 0);
    expect(r.clientClaims?['foo'], 'bar');
    expect(r.userClaims?['name'], 'Test');
  });
}
