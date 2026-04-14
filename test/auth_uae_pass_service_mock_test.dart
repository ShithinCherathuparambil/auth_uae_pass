import 'dart:convert';
import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  late MockClient mockClient;
  late AuthUaePass auth;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockClient();
    auth = AuthUaePass(httpClient: mockClient);
  });

  group('AuthUaePass Service API', () {
    const env = UaePassEnvironment.staging;

    test('getAccessToken returns token on success', () async {
      final responseData = {
        'access_token': 'test_access_token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'profile',
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(responseData), 200));

      final token = await auth.getAccessToken(
        request: UaePassAccessTokenRequest(
          tokenUrl: UaePassIdHubEndpoints.tokenUrl(env),
          clientId: 'client_id',
          clientSecret: 'client_secret',
          redirectUri: 'myapp://callback',
          code: 'auth_code',
        ),
      );

      expect(token, isNotNull);
      expect(token?.accessToken, 'test_access_token');
      expect(token?.expiresIn, 3600);
      
      // Verify headers
      final captured = verify(() => mockClient.post(
            any(),
            headers: captureAny(named: 'headers'),
            body: any(named: 'body'),
          )).captured;
      
      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], contains('Basic'));
      expect(headers['Content-Type'], contains('application/x-www-form-urlencoded'));
    });

    test('getUserProfile returns profile on success', () async {
      final responseData = {
        'sub': 'sub_123',
        'fullnameEN': 'John Doe',
        'mobile': '971501234567',
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(responseData), 200));

      final profile = await auth.getUserProfile(
        request: UaePassUserProfileRequest(
          userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(env),
          accessToken: 'token_123',
        ),
      );

      expect(profile, isNotNull);
      expect(profile?.sub, 'sub_123');
      expect(profile?.fullNameEN, 'John Doe');
      expect(profile?.mobile, '971501234567');
      
      // Verify authorization header
      final captured = verify(() => mockClient.get(
            any(),
            headers: captureAny(named: 'headers'),
          )).captured;
      
      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], 'Bearer token_123');
    });

    test('introspectToken returns verified result on success', () async {
      final responseData = {
        'active': true,
        'sub': 'user_abc',
        'client_id': 'my_client',
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(responseData), 200));

      final result = await auth.introspectToken(
        request: UaePassIntrospectRequest(
          introspectUrl: UaePassIdHubEndpoints.introspectUrl(env),
          clientId: 'client_id',
          clientSecret: 'client_secret',
          token: 'token_to_verify',
        ),
      );

      expect(result, isNotNull);
      expect(result?.active, isTrue);
      expect(result?.sub, 'user_abc');
    });

    test('handles API errors gracefully by returning null', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      final result = await auth.getAccessToken(
        request: UaePassAccessTokenRequest(
          tokenUrl: 'url',
          clientId: 'id',
          clientSecret: 'secret',
          redirectUri: 'uri',
          code: 'code',
        ),
      );

      expect(result, isNull);
    });
  });
}
