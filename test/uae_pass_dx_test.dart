import 'package:flutter_test/flutter_test.dart';
import 'package:auth_uae_pass/auth_uae_pass.dart';

void main() {
  group('UaePassConfig', () {
    test('creates config with correct values', () {
      final config = UaePassConfig(
        clientId: 'test-id',
        clientSecret: 'test-secret',
        redirectUri: 'test://callback',
        environment: UaePassEnvironment.staging,
      );

      expect(config.clientId, 'test-id');
      expect(config.clientSecret, 'test-secret');
      expect(config.redirectUri, 'test://callback');
      expect(config.environment, UaePassEnvironment.staging);
    });

    test('copyWith works correctly', () {
      final config = UaePassConfig(
        clientId: 'test-id',
        clientSecret: 'test-secret',
        redirectUri: 'test://callback',
      );

      final updated = config.copyWith(clientId: 'new-id');
      expect(updated.clientId, 'new-id');
      expect(updated.clientSecret, 'test-secret');
    });
  });

  group('UaePassAuthData throwIfError', () {
    test('does not throw on success', () {
      const data = UaePassAuthData(status: UaePassFlowStatus.loginSuccess);
      expect(() => data.throwIfError(), returnsNormally);
    });

    test('throws UaePassCancelledException on cancelled status', () {
      const data = UaePassAuthData(status: UaePassFlowStatus.cancelled);
      expect(() => data.throwIfError(), throwsA(isA<UaePassCancelledException>()));
    });

    test('throws UaePassDocumentsNotVerifiedException on specific error code', () {
      const data = UaePassAuthData(
        status: UaePassFlowStatus.error,
        errorCode: kUaePassDocumentsNotVerifiedErrorCode,
      );
      expect(
        () => data.throwIfError(),
        throwsA(isA<UaePassDocumentsNotVerifiedException>()),
      );
    });

    test('throws generic UaePassException on other errors', () {
      const data = UaePassAuthData(
        status: UaePassFlowStatus.error,
        errorCode: 'SOME_ERROR',
        errorDescription: 'Something went wrong',
      );
      expect(
        () => data.throwIfError(),
        throwsA(
          isA<UaePassException>()
              .having((e) => e.code, 'code', 'SOME_ERROR')
              .having((e) => e.message, 'message', 'Something went wrong'),
        ),
      );
    });
  });

  group('UaePassLogger', () {
    test('can set log level without errors', () {
      UaePassLogger.setLogLevel(UaePassLogLevel.none);
      UaePassLogger.setLogLevel(UaePassLogLevel.verbose);
      UaePassLogger.d('Test log');
      UaePassLogger.i('Test info');
      UaePassLogger.e('Test error');
    });
  });
}
