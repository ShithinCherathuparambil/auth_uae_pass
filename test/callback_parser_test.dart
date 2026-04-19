import 'package:flutter_test/flutter_test.dart';
import 'package:auth_uae_pass/auth_uae_pass.dart';

void main() {
  group('UaePassCallbackParser - Cancellation Verification', () {
    final redirectUri = Uri.parse('https://example.com/callback');

    test('should map access_denied to cancelled status', () {
      final callbackUri = Uri.parse('https://example.com/callback?error=access_denied&error_description=User+cancelled');
      
      final result = UaePassCallbackParser.parse(
        callbackUri: callbackUri,
        redirectUri: redirectUri,
        cancelledUriPatterns: [],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.cancelled);
      expect(result?.statusCode, 'USER_CANCELLED');
    });

    test('should map explicit cancel to cancelled status', () {
      final callbackUri = Uri.parse('https://example.com/callback?status=cancel');
      
      final result = UaePassCallbackParser.parse(
        callbackUri: callbackUri,
        redirectUri: redirectUri,
        cancelledUriPatterns: [],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.cancelled);
    });

    test('should handle UAEPASS-CANCEL fragment (often seen in native redirects)', () {
      final callbackUri = Uri.parse('https://example.com/callback#UAEPASS-CANCEL');
      
      final result = UaePassCallbackParser.parse(
        callbackUri: callbackUri,
        redirectUri: redirectUri,
        cancelledUriPatterns: [],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.cancelled);
    });

    test('should respect custom cancelledUriPatterns', () {
      final callbackUri = Uri.parse('https://example.com/failure_page');
      
      final result = UaePassCallbackParser.parse(
        callbackUri: callbackUri,
        redirectUri: redirectUri,
        cancelledUriPatterns: ['failure_page'],
        isLogoutFlow: false,
      );

      expect(result?.status, UaePassFlowStatus.cancelled);
    });
  });
}
