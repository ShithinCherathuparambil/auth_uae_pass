export 'web_auth_stub.dart'
    if (dart.library.html) 'web_auth_real.dart'
    if (dart.library.js_util) 'web_auth_real.dart';
