import 'dart:convert';

import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthUaePass Service Tests', () {
    test('getAccessToken returns token on 200 success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'test-token',
            'token_type': 'Bearer',
            'expires_in': 3600,
          }),
          200,
        );
      });

      final auth = AuthUaePass(httpClient: mockClient);
      final result = await auth.getAccessToken(
        request: const UaePassAccessTokenRequest(
          tokenUrl: 'https://test.com/token',
          clientId: 'id',
          clientSecret: 'secret',
          redirectUri: 'uri',
          code: 'code',
        ),
      );

      expect(result, isNotNull);
      expect(result?.accessToken, 'test-token');
      expect(result?.tokenType, 'Bearer');
    });

    test('getAccessToken returns null on error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 400);
      });

      final auth = AuthUaePass(httpClient: mockClient);
      final result = await auth.getAccessToken(
        request: const UaePassAccessTokenRequest(
          tokenUrl: 'https://test.com/token',
          clientId: 'id',
          clientSecret: 'secret',
          redirectUri: 'uri',
          code: 'code',
        ),
      );

      expect(result, isNull);
    });

    test('getUserProfile returns profile on 200 success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'sub': 'user-123',
            'fullnameEN': 'John Doe',
            'email': 'john@example.com',
            'uuid': 'uuid-123',
          }),
          200,
        );
      });

      final auth = AuthUaePass(httpClient: mockClient);
      final result = await auth.getUserProfile(
        request: const UaePassUserProfileRequest(
          userInfoUrl: 'https://test.com/userinfo',
          accessToken: 'token',
        ),
      );

      expect(result, isNotNull);
      expect(result?.sub, 'user-123');
      expect(result?.fullNameEN, 'John Doe');
      expect(result?.email, 'john@example.com');
    });

    test('introspectToken returns result on success', () async {
      final mockClient = MockClient((request) async {
        // Verify basic auth header
        final authHeader = request.headers['Authorization'];
        expect(authHeader, startsWith('Basic '));

        return http.Response(
          jsonEncode({
            'active': true,
            'client_id': 'test-client',
            'sub': 'test-sub',
          }),
          200,
        );
      });

      final auth = AuthUaePass(httpClient: mockClient);
      final result = await auth.introspectToken(
        request: const UaePassIntrospectRequest(
          introspectUrl: 'https://test.com/introspect',
          clientId: 'id',
          clientSecret: 'secret',
          token: 'token',
        ),
      );

      expect(result, isNotNull);
      expect(result?.active, isTrue);
      expect(result?.clientId, 'test-client');
      expect(result?.sub, 'test-sub');
    });

    test('introspectToken returns null on empty body', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final auth = AuthUaePass(httpClient: mockClient);
      final result = await auth.introspectToken(
        request: const UaePassIntrospectRequest(
          introspectUrl: 'https://test.com/introspect',
          clientId: 'id',
          clientSecret: 'secret',
          token: 'token',
        ),
      );

      expect(result, isNull);
    });
  });
}
