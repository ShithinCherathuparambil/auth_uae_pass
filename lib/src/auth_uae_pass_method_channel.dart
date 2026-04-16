import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'auth_uae_pass_platform_interface.dart';

/// An implementation of [AuthUaePassPlatform] that uses method channels.
class MethodChannelAuthUaePass extends AuthUaePassPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('auth_uae_pass');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
