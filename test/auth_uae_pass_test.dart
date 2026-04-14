import 'package:flutter_test/flutter_test.dart';
import 'package:auth_uae_pass/auth_uae_pass.dart';

void main() {
  group('UaePassCallbackParser', () {
    final redirectUri = Uri.parse('myapp://callback');

    test('parses SOP1 status', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback?status_code=SOP1'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.sop1);
    });

    test('parses SOP2 status', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback?sop=SOP2'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.sop2);
    });

    test('parses SOP3 status', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback#SOP3'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.sop3);
    });

    test('returns cancelled when cancel pattern is matched', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('https://id.uaepass.ae/cancel'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>['cancel'],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.cancelled);
    });

    test('returns null when callback does not match redirect host', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://other?status_code=SOP1'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );

      expect(result, isNull);
    });

    test('returns logout success for logout flow', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: true,
      );

      expect(result?.status, UaePassFlowStatus.logoutSuccess);
    });

    test('maps documents not verified errors', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse(
          'myapp://callback?error_code=123&error_description=Documents%20are%20not%20verified',
        ),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.error);
      expect(result?.errorCode, kUaePassDocumentsNotVerifiedErrorCode);
      expect(result?.typedErrorCode, UaePassErrorCode.documentsNotVerified);
    });

    test('handles variations of document not verified error', () {
      final variants = [
        'document not verified',
        'DOCUMENTS_NOT_VERIFIED',
        'document_not_verified',
      ];

      for (final variant in variants) {
        final result = UaePassCallbackParser.parse(
          callbackUri: Uri.parse('myapp://callback?error=$variant'),
          redirectUri: redirectUri,
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: false,
        );
        expect(result?.errorCode, kUaePassDocumentsNotVerifiedErrorCode);
      }
    });

    test('parses cancel from different parameters', () {
      final uris = [
        'myapp://callback?status=cancel',
        'myapp://callback?status_code=cancel',
        'myapp://callback?sop=cancel',
        'myapp://callback?code=cancel',
      ];

      for (final url in uris) {
        final result = UaePassCallbackParser.parse(
          callbackUri: Uri.parse(url),
          redirectUri: redirectUri,
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: false,
        );
        expect(result?.status, UaePassFlowStatus.cancelled);
      }
    });
    test('returns unknown for unrecognized status code', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback?status_code=FOOBAR'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );
      expect(result?.status, UaePassFlowStatus.unknown);
      expect(result?.statusCode, 'FOOBAR');
    });

    test('parses loginSuccess when code is present', () {
      final result = UaePassCallbackParser.parse(
        callbackUri: Uri.parse('myapp://callback?code=123'),
        redirectUri: redirectUri,
        cancelledUriPatterns: const <String>[],
        isLogoutFlow: false,
      );
      expect(result?.status, UaePassFlowStatus.loginSuccess);
      expect(result?.statusCode, 'LOGIN_SUCCESS');
    });
  });

  test('success helper returns true for SOP status', () {
    const result = UaePassAuthResult(
      status: UaePassFlowStatus.sop2,
      statusCode: 'SOP2',
    );

    expect(result.isSuccess, isTrue);
  });

  test('success helper returns true for loginSuccess status', () {
    const result = UaePassAuthResult(
      status: UaePassFlowStatus.loginSuccess,
    );

    expect(result.isSuccess, isTrue);
  });

  test('parses access token model payload', () {
    final token = UaePassUserToken.fromJson(<String, dynamic>{
      'access_token': 'token-123',
      'token_type': 'Bearer',
      'expires_in': 3600,
      'scope': 'urn:uae:digitalid:profile:general',
    });

    expect(token.accessToken, 'token-123');
    expect(token.tokenType, 'Bearer');
    expect(token.expiresIn, 3600);
  });

  test('parses UAEPASS user profile payload', () {
    final profile = UaePassUserProfile.fromJson(<String, dynamic>{
      'fullnameEN': 'Jane Doe',
      'fullnameAR': 'جين دو',
      'email': 'jane@example.com',
      'uuid': 'uuid-1',
      'spuuid': 'sp-1',
      'profileType': '2',
      'unifiedId': 'un-1',
      'nationalityEN': 'Emirati',
      'gender': 'Female',
    });

    expect(profile.fullNameEN, 'Jane Doe');
    expect(profile.fullNameAR, 'جين دو');
    expect(profile.email, 'jane@example.com');
    expect(profile.uuid, 'uuid-1');
    expect(profile.spuuid, 'sp-1');
    expect(profile.profileType, '2');
    expect(profile.unifiedId, 'un-1');
    expect(profile.nationalityEN, 'Emirati');
    expect(profile.gender, 'Female');
  });

  test('parses userinfo acr and amr', () {
    final profile = UaePassUserProfile.fromJson(<String, dynamic>{
      'sub': '800F475AC0E7A9ED01B2D5D2C25A59B3',
      'acr': 'urn:safelayer:tws:policies:authentication:level:high',
      'mobile': '9715555555555',
      'amr': <String>[
        'urn:safelayer:tws:policies:authentication:adaptive:methods:mobileid',
        'urn:uae:authentication:method:verified',
      ],
    });

    expect(profile.sub, '800F475AC0E7A9ED01B2D5D2C25A59B3');
    expect(profile.acr, contains('level:high'));
    expect(profile.mobile, '9715555555555');
    expect(profile.amr, hasLength(2));
    expect(profile.raw['acr'], profile.acr);
  });
}
