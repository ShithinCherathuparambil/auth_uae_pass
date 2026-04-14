import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'auth_uae_pass_method_channel.dart';

abstract class AuthUaePassPlatform extends PlatformInterface {
  /// Constructs a AuthUaePassPlatform.
  AuthUaePassPlatform() : super(token: _token);

  static final Object _token = Object();

  static AuthUaePassPlatform _instance = MethodChannelAuthUaePass();

  /// The default instance of [AuthUaePassPlatform] to use.
  ///
  /// Defaults to [MethodChannelAuthUaePass].
  static AuthUaePassPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AuthUaePassPlatform] when
  /// they register themselves.
  static set instance(AuthUaePassPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
