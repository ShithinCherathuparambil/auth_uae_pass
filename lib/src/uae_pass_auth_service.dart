import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthUaePass {
  const AuthUaePass({this.config, this.onEvent, http.Client? httpClient})
    : _httpClient = httpClient;

  static AuthUaePass? _instance;

  /// Returns the global singleton instance of [AuthUaePass].
  ///
  /// You must call [AuthUaePass.initialize] before accessing this.
  static AuthUaePass get instance {
    if (_instance == null) {
      throw UaePassException(
        'AuthUaePass is not initialized. Call AuthUaePass.initialize(config) first.',
      );
    }
    return _instance!;
  }

  /// Initializes the global [AuthUaePass] singleton with your configuration.
  static void initialize(
    UaePassConfig config, {
    void Function(UaePassEvent)? onEvent,
  }) {
    _instance = AuthUaePass(config: config, onEvent: onEvent);
  }

  /// Optional configuration for UAE Pass service.
  /// If provided, methods like [signInWithProfile] will use these credentials.
  final UaePassConfig? config;

  /// Optional callback to listen for SDK events (analytics, haptics, etc.).
  final void Function(UaePassEvent event)? onEvent;

  final http.Client? _httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  /// Internal stream for native deep link returns.
  static final StreamController<Uri> _deepLinkStream =
      StreamController<Uri>.broadcast();

  static bool _isFlowInProgress = false;

  /// Internal Buffer for deep links received while no flow is active.
  static Uri? _lastCapturedLink;
  static bool _initialLinkHandled = false;
  static StreamSubscription<Uri>? _internalSubscription;

  /// Returns the global deep link stream.
  @visibleForTesting
  static Stream<Uri> listenToDeepLinkStream() => _deepLinkStream.stream;

  /// For testing purposes only. Resets the internal static state.
  @visibleForTesting
  static void reset() {
    _lastCapturedLink = null;
    _isFlowInProgress = false;
    _internalSubscription?.cancel();
    _internalSubscription = null;
    _initialLinkHandled = false;
  }

  /// Ensures the global deep link listener is active and checks for initial links.
  static Future<void> _ensureInitialized([AppLinks? links]) async {
    if (_internalSubscription != null) return;
    final AppLinks appLinks = links ?? AppLinks();

    _internalSubscription = appLinks.uriLinkStream.listen((uri) {
      onDeepLinkReceived(uri);
    });

    // Check for cold start links if not already handled
    if (!_initialLinkHandled) {
      try {
        final initialUri = await appLinks.getInitialLink();
        if (initialUri != null) {
          UaePassLogger.d('Cold start link detected: $initialUri');
          onDeepLinkReceived(initialUri);
        }
      } catch (e) {
        UaePassLogger.e('Error checking initial link', e);
      }
      _initialLinkHandled = true;
    }
  }

  /// Call this from your app's deep link listener (e.g. app_links or uni_links)
  /// when a URL with your custom scheme is received.
  static void onDeepLinkReceived(Uri uri) {
    UaePassLogger.d('Captured link: $uri');
    _lastCapturedLink = uri;
    _deepLinkStream.add(uri);
  }

  /// Clears any buffered deep links.
  static void clearCapturedLink() {
    if (_lastCapturedLink != null) {
      UaePassLogger.d('Clearing captured link buffer');
      _lastCapturedLink = null;
    }
  }

  /// Probes whether the UAE PASS app is installed on this device.
  ///
  /// Useful for showing conditional UI like "Install UAE PASS".
  Future<bool> isAppInstalled([UaePassEnvironment? environment]) async {
    final UaePassEnvironment targetEnv =
        environment ?? config?.environment ?? UaePassEnvironment.production;
    return isUaePassAppInstalled(targetEnv);
  }

  /// Internal Safety Guardian: Warns developers about common mismatch errors.
  void _validateRedirectUri(String? redirectUri) {
    if (!kDebugMode || redirectUri == null) return;
    if (!redirectUri.startsWith('https://')) {
      UaePassLogger.w(
        '--- SAFETY GUARDIAN WARNING ---\n'
        'Your redirectUri ($redirectUri) does not start with https://.\n'
        'UAE PASS portal registration REQUIRES an HTTPS callback.\n'
        'Custom schemes (like myapp://) should be set in deepLinkScheme, NOT redirectUri.\n'
        '-------------------------------',
      );
    }
  }

  @Deprecated(
    'Setup is now handled internally. You can remove this from initState.',
  )
  StreamSubscription<Uri>? listenToDeepLinks({
    required BuildContext context,
    required UaePassAuthRequest defaultRequest,
    required void Function(UaePassAuthResult) onResult,
    bool autoResumeOnColdStart = false,
  }) {
    _ensureInitialized();
    final AppLinks appLinks = AppLinks();

    // Legacy support for user's explicit onResult handling
    return appLinks.uriLinkStream.listen((uri) {
      if (!_isFlowInProgress) {
        if (!context.mounted) return;
        _handleGlobalResumption(
          context: context,
          uri: uri,
          request: defaultRequest,
          onResult: onResult,
        );
      }
    });
  }

  void _handleGlobalResumption({
    required BuildContext context,
    required Uri uri,
    required UaePassAuthRequest request,
    required void Function(UaePassAuthResult) onResult,
  }) {
    // We reuse the utility from uae_pass_mobile_api.dart for consistency
    final bool isResumption = isSpResumeAuthnCallback(
      uri: uri,
      spRedirectUri: Uri.parse(request.redirectUri),
      deepLinkScheme: request.deepLinkScheme,
      resumeAuthnPath: request.resumeAuthnPath,
    );

    if (isResumption) {
      UaePassLogger.i('Detected resumption link, launching recovery flow...');
      authenticateWithResumption(
        context,
        deepLink: uri,
        originalRequest: request,
      ).then(onResult);
    }
  }

  Future<String?> signIn(
    BuildContext context, {
    required UaePassAuthRequest request,
  }) async {
    final result = await authenticate(context, request: request);
    UaePassLogger.d('signIn result status=${result.status}');
    if (!result.isSuccess) {
      return null;
    }

    final callbackUri = result.callbackUri;
    if (callbackUri == null) {
      return null;
    }
    final code = callbackUri.queryParameters['code'];
    UaePassLogger.d('signIn retrieved code=${code != null ? '***' : 'null'}');
    return code;
  }

  /// A simplified high-level method to perform the full UAE PASS authentication flow.
  ///
  /// This method handles the browser popup, token exchange, and profile fetching
  /// in a single call.
  ///
  /// ### Parameters:
  /// - [clientId]: Your Service Provider client ID (e.g. `your_app_stg`).
  /// - [clientSecret]: Your Service Provider client secret.
  /// - [redirectUri]: The **exact HTTPS URL** registered in the UAE PASS portal.
  /// - [environment]: Use [UaePassEnvironment.staging] for testing.
  /// - [deepLinkScheme]: Your app's custom scheme (e.g. `ae.myapp.com`). **CRITICAL**:
  ///   Providing this ensures the return redirect works reliably on all devices.
  /// - [uiLocale]: The language of the login screens (`'en'` or `'ar'`).
  ///
  /// Returns a [UaePassAuthData] containing the final status, token, and profile.
  /// Throws a [UaePassException] if configuration is missing or the flow fails.
  Future<UaePassAuthData> signInWithProfile(
    BuildContext context, {
    String? clientId,
    String? clientSecret,
    String? redirectUri,
    UaePassEnvironment? environment,
    String? uiLocale,
    String? deepLinkScheme,
    String? acrValues,
    List<String> cancelledUriPatterns = const <String>[],
    UaePassConfig? configOverride,
  }) async {
    final effectiveConfig = configOverride ?? config;
    final resolvedClientId = clientId ?? effectiveConfig?.clientId;
    final resolvedClientSecret = clientSecret ?? effectiveConfig?.clientSecret;
    final resolvedRedirectUri = redirectUri ?? effectiveConfig?.redirectUri;
    final resolvedEnvironment = environment ?? effectiveConfig?.environment;
    final resolvedUiLocale = uiLocale ?? effectiveConfig?.uiLocale ?? 'en';
    final resolvedDeepLinkScheme =
        deepLinkScheme ?? effectiveConfig?.deepLinkScheme;
    final resolvedAcrValues = acrValues ?? effectiveConfig?.acrValues;

    _validateRedirectUri(resolvedRedirectUri);

    if (resolvedClientId == null ||
        resolvedClientSecret == null ||
        resolvedRedirectUri == null ||
        resolvedEnvironment == null) {
      throw UaePassException(
        'Missing required UAE Pass configuration. Provide a config in the constructor, '
        'pass a configOverride, or provide individual parameters.',
      );
    }

    // Safety check: UAE Pass requires HTTPS for redirectUri in production.
    if (!resolvedRedirectUri.startsWith('https://')) {
      UaePassLogger.e(
        'CRITICAL: redirectUri must start with https:// for UAE PASS. '
        'Detected: $resolvedRedirectUri. This WILL cause failures in the production app.',
      );
    }

    onEvent?.call(UaePassEvent.authStarted);

    final String authUrl = authorizationUrl(
      environment: resolvedEnvironment,
      clientId: resolvedClientId,
      redirectUri: resolvedRedirectUri,
      uiLocales: resolvedUiLocale,
      acrValues: resolvedAcrValues,
    );

    final authResult = await authenticate(
      context,
      request: UaePassAuthRequest(
        authorizationUrl: authUrl,
        redirectUri: resolvedRedirectUri,
        environment: resolvedEnvironment,
        deepLinkScheme: resolvedDeepLinkScheme,
        cancelledUriPatterns: cancelledUriPatterns,
      ),
      onEvent: onEvent,
    );

    if (!authResult.isSuccess) {
      if (authResult.status == UaePassFlowStatus.cancelled) {
        onEvent?.call(UaePassEvent.cancelled);
      } else {
        onEvent?.call(UaePassEvent.error);
      }
      return UaePassAuthData(
        status: authResult.status,
        errorCode: authResult.errorCode,
        errorDescription: authResult.errorDescription,
        statusCode: authResult.statusCode,
      );
    }

    onEvent?.call(UaePassEvent.webviewLoaded);

    final code = authResult.callbackUri?.queryParameters['code'];
    if (code == null) {
      return UaePassAuthData(
        status: authResult.status,
        errorCode: 'MISSING_CODE',
        errorDescription: 'Authentication succeeded but no code was returned.',
        statusCode: authResult.statusCode,
      );
    }

    final token = await getAccessToken(
      request: UaePassAccessTokenRequest(
        tokenUrl: UaePassIdHubEndpoints.tokenUrl(resolvedEnvironment),
        clientId: resolvedClientId,
        clientSecret: resolvedClientSecret,
        redirectUri: resolvedRedirectUri,
        code: code,
      ),
    );

    if (token == null || token.accessToken == null) {
      onEvent?.call(UaePassEvent.error);
      return UaePassAuthData(
        status: authResult.status,
        errorCode: 'TOKEN_EXCHANGE_FAILED',
        errorDescription: 'Failed to exchange authorization code for token.',
        statusCode: authResult.statusCode,
      );
    }

    onEvent?.call(UaePassEvent.tokenExchanged);

    final profile = await getUserProfile(
      request: UaePassUserProfileRequest(
        userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(resolvedEnvironment),
        accessToken: token.accessToken!,
      ),
    );

    UaePassSopLevel resolvedSop = authResult.sopLevel;
    if (resolvedSop == UaePassSopLevel.none) {
      final String? profileType =
          profile?.userType?.toUpperCase() ??
          profile?.profileType?.toUpperCase();

      if (profileType != null) {
        if (profileType.contains('SOP1')) {
          resolvedSop = UaePassSopLevel.sop1;
        } else if (profileType.contains('SOP2')) {
          resolvedSop = UaePassSopLevel.sop2;
        } else if (profileType.contains('SOP3')) {
          resolvedSop = UaePassSopLevel.sop3;
        }
      }

      // If still none, check ACR as backup
      if (resolvedSop == UaePassSopLevel.none && profile?.acr != null) {
        final String acr = profile!.acr!.toLowerCase();
        if (acr.endsWith(':sop1')) {
          resolvedSop = UaePassSopLevel.sop1;
        } else if (acr.endsWith(':sop2')) {
          resolvedSop = UaePassSopLevel.sop2;
        } else if (acr.endsWith(':sop3')) {
          resolvedSop = UaePassSopLevel.sop3;
        }
      }
    }

    onEvent?.call(UaePassEvent.profileFetched);
    onEvent?.call(UaePassEvent.loginSuccess);

    return UaePassAuthData(
      status: authResult.status,
      token: token,
      profile: profile,
      statusCode: authResult.statusCode,
      sopLevel: resolvedSop,
    );
  }

  /// Specialized method to trigger a FaceID/Biometric upgrade flow.
  ///
  /// This specifically requests the SOP3 (Verification level 3) by appending
  /// the official UAE PASS biometric upgrade string to the ACR values.
  Future<UaePassAuthData> upgradeToSOP3(
    BuildContext context, {
    String? clientId,
    String? clientSecret,
    String? redirectUri,
    UaePassEnvironment? environment,
    String? uiLocale,
    String? deepLinkScheme,
  }) async {
    UaePassLogger.i('Triggering SOP3 Upgrade flow...');
    return signInWithProfile(
      context,
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      environment: environment,
      uiLocale: uiLocale,
      deepLinkScheme: deepLinkScheme,
      acrValues: 'urn:uae:digitalid:profile:general:sop3',
    );
  }

  Future<UaePassUserToken?> getAccessToken({
    required UaePassAccessTokenRequest request,
  }) async {
    UaePassLogger.d('getAccessToken request...');
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('${request.clientId}:${request.clientSecret}'))}';
    try {
      final response = await _client.post(
        Uri.parse(request.tokenUrl),
        headers: <String, String>{
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
          ...request.headers,
        },
        body: <String, String>{
          'redirect_uri': request.redirectUri,
          'client_id': request.clientId,
          'client_secret': request.clientSecret,
          'grant_type': 'authorization_code',
          'code': request.code,
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final result = UaePassUserToken.fromJson(data);
      UaePassLogger.i('getAccessToken SUCCESS');
      return result;
    } catch (e, stack) {
      UaePassLogger.e('getAccessToken ERROR', e, stack);
      return null;
    }
  }

  /// **GET** [userInfoUrl] with `Authorization: Bearer <access_token>` (client or validated token).
  ///
  /// Staging: `https://stg-id.uaepass.ae/idshub/userinfo` — see UAE PASS userinfo documentation.
  Future<UaePassUserProfile?> getUserProfile({
    required UaePassUserProfileRequest request,
  }) async {
    UaePassLogger.d('getUserProfile request...');
    try {
      final response = await _client.get(
        Uri.parse(request.userInfoUrl),
        headers: <String, String>{
          'Authorization': 'Bearer ${request.accessToken}',
          'Accept': 'application/json',
          ...request.headers,
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final result = UaePassUserProfile.fromJson(data);
      UaePassLogger.i('getUserProfile SUCCESS');
      UaePassLogger.d('  - sub: ${result.sub}');
      UaePassLogger.d('  - uuid: ${result.uuid}');
      UaePassLogger.d('  - unifiedId: ${result.unifiedId}');
      UaePassLogger.d('  - fullNameEN: ${result.fullNameEN}');
      UaePassLogger.d('  - fullNameAR: ${result.fullNameAR}');
      UaePassLogger.d('  - email: ${result.email}');
      UaePassLogger.d('  - mobile: ${result.mobile}');
      UaePassLogger.d('  - idn: ${result.idn}');
      UaePassLogger.d('  - userType: ${result.userType}');
      UaePassLogger.d('  - profileType: ${result.profileType}');
      UaePassLogger.d('  - acr: ${result.acr}');
      UaePassLogger.d('  - amr: ${result.amr}');
      UaePassLogger.d('  - nationalityEN: ${result.nationalityEN}');
      UaePassLogger.d('  - nationalityAR: ${result.nationalityAR}');
      UaePassLogger.d('  - gender: ${result.gender}');
      UaePassLogger.d('  - spuuid: ${result.spuuid}');
      UaePassLogger.d('  - idType: ${result.idType}');
      UaePassLogger.d('  - titleEN: ${result.titleEN}');
      UaePassLogger.d('  - titleAR: ${result.titleAR}');
      return result;
    } catch (e, stack) {
      UaePassLogger.e('getUserProfile ERROR', e, stack);
      return null;
    }
  }

  /// Verifies an access token via idhub **introspect** using **Basic** auth (SP credentials).
  ///
  /// POST `introspectUrl` with `Authorization: Basic base64(client_id:client_secret)` and
  /// body `token=<token>`. Returns parsed JSON on 200 or 400 when the body is valid JSON.
  Future<UaePassIntrospectResult?> introspectToken({
    required UaePassIntrospectRequest request,
  }) async {
    try {
      final String basicAuth = base64Encode(
        utf8.encode('${request.clientId}:${request.clientSecret}'),
      );
      final http.Response response = await _client.post(
        Uri.parse(request.introspectUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Authorization': 'Basic $basicAuth',
          ...request.headers,
        },
        body: <String, String>{'token': request.token},
      );

      if (response.body.isEmpty) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return UaePassIntrospectResult.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<UaePassAuthResult> authenticate(
    BuildContext context, {
    required UaePassAuthRequest request,
    void Function(UaePassEvent)? onEvent,
  }) async {
    await _ensureInitialized();
    Uri? pendingUri;

    // 1. Check if we have a captured runtime link (from stream listener or initial check)
    if (_lastCapturedLink != null) {
      pendingUri = _lastCapturedLink;
      _lastCapturedLink = null; // Consume
    }

    // 2. If a pending link exists and matches the resumption criteria, use it!
    if (pendingUri != null) {
      final bool isResumption = isSpResumeAuthnCallback(
        uri: pendingUri,
        spRedirectUri: Uri.parse(request.redirectUri),
        deepLinkScheme: request.deepLinkScheme,
        resumeAuthnPath: request.resumeAuthnPath,
      );

      if (isResumption) {
        UaePassLogger.i('Resuming interrupted flow via handleResumption...');
        if (!context.mounted) {
          return const UaePassAuthResult(status: UaePassFlowStatus.cancelled);
        }
        return authenticateWithResumption(
          context,
          deepLink: pendingUri,
          originalRequest: request,
        );
      }
    }

    Uri parsed = Uri.parse(request.authorizationUrl);
    if (request.applyMobileAcrValues) {
      final UaePassEnvironment environment =
          request.environment ?? UaePassEnvironment.production;
      final bool installed = await isUaePassAppInstalled(environment);
      UaePassLogger.d('app check for $environment: installed=$installed');
      parsed = applyMobileAcrValues(parsed, uaePassAppInstalled: installed);
    }
    if (request.visitorIntegrationFirstAuth) {
      parsed = applyVisitorIntegrationScopes(parsed);
    }
    final String initialUrl = parsed.toString();
    UaePassLogger.i('authenticate starting with URL: $initialUrl');

    // Ensure a clean slate by clearing cookies before starting a new flow.
    // This prevents stale session state from interfering with the new request.
    try {
      final CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      UaePassLogger.d('WebView cookies cleared');
    } catch (e, stack) {
      UaePassLogger.e('Warning clearing cookies', e, stack);
    }

    if (!context.mounted) {
      return const UaePassAuthResult(status: UaePassFlowStatus.cancelled);
    }

    final String uaePassScheme =
        (request.environment == UaePassEnvironment.staging)
        ? 'uaepassstg'
        : 'uaepass';

    final result = await Navigator.of(context).push<UaePassAuthResult>(
      MaterialPageRoute<UaePassAuthResult>(
        builder: (_) => _UaePassWebViewPage(
          initialUrl: initialUrl,
          redirectUri: request.redirectUri,
          cancelledUriPatterns: request.cancelledUriPatterns,
          externalAppSchemes: request.externalAppSchemes,
          headers: request.headers,
          userAgent: request.userAgent,
          isLogoutFlow: false,
          resumeAuthnPath: request.resumeAuthnPath,
          deepLinkScheme: request.deepLinkScheme,
          uaePassScheme: uaePassScheme,
          enableMobileDeepLinkRewrite: request.enableMobileDeepLinkRewrite,
        ),
        fullscreenDialog: true,
      ),
    );

    return result ??
        const UaePassAuthResult(status: UaePassFlowStatus.cancelled);
  }

  /// Use this when the app is restarted via a deep link (cold start) or when
  /// the main flow was interrupted. It extracts the nested URL and opens a
  /// new WebView to complete the authentication.
  Future<UaePassAuthResult> authenticateWithResumption(
    BuildContext context, {
    required Uri deepLink,
    required UaePassAuthRequest originalRequest,
  }) async {
    final String? nested = nestedUrlFromResumeCallback(deepLink);
    if (nested == null || nested.isEmpty) {
      UaePassLogger.e('Resumption failed: No nested URL in $deepLink');
      return const UaePassAuthResult(status: UaePassFlowStatus.error);
    }

    UaePassLogger.i('Resuming authentication via global entry: $nested');

    final String uaePassScheme =
        (originalRequest.environment == UaePassEnvironment.staging)
        ? 'uaepassstg'
        : 'uaepass';

    final result = await Navigator.of(context).push<UaePassAuthResult>(
      MaterialPageRoute<UaePassAuthResult>(
        builder: (_) => _UaePassWebViewPage(
          initialUrl: nested,
          redirectUri: originalRequest.redirectUri,
          cancelledUriPatterns: originalRequest.cancelledUriPatterns,
          externalAppSchemes: originalRequest.externalAppSchemes,
          headers: originalRequest.headers,
          userAgent: originalRequest.userAgent,
          isLogoutFlow: false,
          resumeAuthnPath: originalRequest.resumeAuthnPath,
          deepLinkScheme: originalRequest.deepLinkScheme,
          uaePassScheme: uaePassScheme,
          enableMobileDeepLinkRewrite:
              originalRequest.enableMobileDeepLinkRewrite,
          onEvent: onEvent,
        ),
        fullscreenDialog: true,
      ),
    );

    return result ??
        const UaePassAuthResult(status: UaePassFlowStatus.cancelled);
  }

  Future<UaePassAuthResult> logout(
    BuildContext context, {
    UaePassEnvironment? environment,
    String? redirectUri,
    UaePassConfig? configOverride,
  }) async {
    final effectiveConfig = configOverride ?? config;
    final resolvedEnvironment = environment ?? effectiveConfig?.environment;
    final resolvedRedirectUri = redirectUri ?? effectiveConfig?.redirectUri;

    if (resolvedEnvironment == null || resolvedRedirectUri == null) {
      throw UaePassException(
        'Missing required UAE Pass configuration for logout. '
        'Provide config in constructor or pass environment/redirectUri.',
      );
    }

    _validateRedirectUri(resolvedRedirectUri);

    UaePassLogger.i('Starting silent logout...');
    onEvent?.call(UaePassEvent.logoutStarted);
    final Completer<UaePassAuthResult> completer =
        Completer<UaePassAuthResult>();
    HeadlessInAppWebView? headless;

    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          logoutUrl(
            environment: resolvedEnvironment,
            redirectUri: resolvedRedirectUri,
          ),
        ),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        clearCache: true,
      ),
      onLoadStart: (controller, url) {
        if (url == null) return;
        UaePassLogger.d('Silent logout loading $url');

        final UaePassAuthResult? result = UaePassCallbackParser.parse(
          callbackUri: Uri.parse(url.toString()),
          redirectUri: Uri.parse(resolvedRedirectUri),
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: true,
        );
        if (result != null &&
            result.status == UaePassFlowStatus.logoutSuccess) {
          UaePassLogger.i('Silent logout complete');
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        }
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final WebUri? url = navigationAction.request.url;
        if (url == null) return NavigationActionPolicy.ALLOW;

        final UaePassAuthResult? result = UaePassCallbackParser.parse(
          callbackUri: Uri.parse(url.toString()),
          redirectUri: Uri.parse(resolvedRedirectUri),
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: true,
        );
        if (result != null &&
            result.status == UaePassFlowStatus.logoutSuccess) {
          UaePassLogger.i('Silent logout complete via override');
          if (!completer.isCompleted) {
            completer.complete(result);
          }
          return NavigationActionPolicy.CANCEL;
        }
        return NavigationActionPolicy.ALLOW;
      },
    );

    try {
      await headless.run();
      // Wait for completion with a reasonable timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          UaePassLogger.i('Silent logout timed out');
          return const UaePassAuthResult(
            status: UaePassFlowStatus.logoutSuccess,
          );
        },
      );

      if (result.status == UaePassFlowStatus.logoutSuccess) {
        onEvent?.call(UaePassEvent.logoutSuccess);
      }
      return result;
    } catch (e, stack) {
      UaePassLogger.e('Error during silent logout', e, stack);
      onEvent?.call(UaePassEvent.error);
      return const UaePassAuthResult(status: UaePassFlowStatus.error);
    } finally {
      await headless.dispose();
    }
  }

  /// Authorize URL (acr_values applied by package when [environment] is set).
  static String authorizationUrl({
    required UaePassEnvironment environment,
    required String clientId,
    required String redirectUri,
    required String uiLocales,
    String? acrValues,
  }) {
    final Uri base = Uri.parse(UaePassIdHubEndpoints.authorizeUrl(environment));
    final Map<String, String> q = Map<String, String>.from(
      base.queryParameters,
    );
    q['response_type'] = 'code';
    q['client_id'] = clientId;
    q['redirect_uri'] = redirectUri;
    q['scope'] = 'urn:uae:digitalid:profile:general';
    q['state'] = '${DateTime.now().millisecondsSinceEpoch}';
    q['ui_locales'] = uiLocales;
    if (acrValues != null) {
      q['acr_values'] = acrValues;
    }
    return base.replace(queryParameters: q).toString();
  }

  static String logoutUrl({
    required UaePassEnvironment environment,
    required String redirectUri,
  }) {
    final String hub = environment == UaePassEnvironment.production
        ? 'https://id.uaepass.ae/idshub/logout'
        : 'https://stg-id.uaepass.ae/idshub/logout';
    return Uri.parse(hub)
        .replace(queryParameters: <String, String>{'redirect_uri': redirectUri})
        .toString();
  }
}

class _UaePassWebViewPage extends StatefulWidget {
  const _UaePassWebViewPage({
    required this.initialUrl,
    required this.redirectUri,
    required this.cancelledUriPatterns,
    required this.externalAppSchemes,
    required this.headers,
    required this.userAgent,
    required this.isLogoutFlow,
    required this.resumeAuthnPath,
    required this.deepLinkScheme,
    required this.uaePassScheme,
    required this.enableMobileDeepLinkRewrite,
    this.onEvent,
  });

  final String initialUrl;
  final String redirectUri;
  final List<String> cancelledUriPatterns;
  final List<String> externalAppSchemes;
  final Map<String, String> headers;
  final String? userAgent;
  final bool isLogoutFlow;
  final String resumeAuthnPath;
  final String? deepLinkScheme;
  final String uaePassScheme;
  final bool enableMobileDeepLinkRewrite;
  final void Function(UaePassEvent)? onEvent;

  @override
  State<_UaePassWebViewPage> createState() => _UaePassWebViewPageState();
}

class _UaePassWebViewPageState extends State<_UaePassWebViewPage> {
  bool _isLoading = true;
  bool _didComplete = false;
  InAppWebViewController? _controller;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    AuthUaePass._isFlowInProgress = true;
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    AuthUaePass._isFlowInProgress = false;
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _setupDeepLinkListener() {
    if (!widget.enableMobileDeepLinkRewrite) return;

    _deepLinkSubscription = AuthUaePass._deepLinkStream.stream.listen((
      uri,
    ) async {
      UaePassLogger.d('WebView listener triggered for $uri');
      if (!mounted) {
        UaePassLogger.d('  - [IGNORE] WebView not mounted');
        return;
      }
      if (_didComplete) {
        UaePassLogger.d('  - [IGNORE] Flow already complete');
        return;
      }
      if (_controller == null) {
        UaePassLogger.d('  - [IGNORE] Controller is null');
        return;
      }

      final Uri spRedirect = Uri.parse(widget.redirectUri);
      if (isSpResumeAuthnCallback(
        uri: uri,
        spRedirectUri: spRedirect,
        deepLinkScheme: widget.deepLinkScheme,
        resumeAuthnPath: widget.resumeAuthnPath,
      )) {
        final String? nested = nestedUrlFromResumeCallback(uri);
        if (nested != null && nested.isNotEmpty) {
          UaePassLogger.i('[PROCESS] Resuming flow: $nested');
          widget.onEvent?.call(UaePassEvent.resumptionCaptured);
          // Clear the global buffer as we are consuming it now
          AuthUaePass.clearCapturedLink();
          await _controller!.loadUrl(
            urlRequest: URLRequest(url: WebUri(nested)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  userAgent: widget.userAgent,
                  supportZoom: false,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  clearCache: true,
                  cacheMode: CacheMode.LOAD_NO_CACHE,
                ),
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.initialUrl),
                  headers: widget.headers,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final WebUri? uri = navigationAction.request.url;
                  if (uri == null) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  final Uri dartUri = Uri.parse(uri.toString());
                  final Uri spRedirect = Uri.parse(widget.redirectUri);

                  if (widget.enableMobileDeepLinkRewrite &&
                      isSpResumeAuthnCallback(
                        uri: dartUri,
                        spRedirectUri: spRedirect,
                        deepLinkScheme: widget.deepLinkScheme,
                        resumeAuthnPath: widget.resumeAuthnPath,
                      )) {
                    final String? nested = nestedUrlFromResumeCallback(dartUri);
                    if (nested != null && nested.isNotEmpty) {
                      UaePassLogger.i('SP callback received, invoking $nested');
                      widget.onEvent?.call(UaePassEvent.resumptionCaptured);
                      // Clear the global buffer as we are consuming it now
                      AuthUaePass.clearCapturedLink();
                      await controller.loadUrl(
                        urlRequest: URLRequest(url: WebUri(nested)),
                      );
                      return NavigationActionPolicy.CANCEL;
                    }
                  }

                  final UaePassAuthResult? parsedResult = _parseResult(uri);
                  if (parsedResult != null) {
                    _complete(parsedResult);
                    return NavigationActionPolicy.CANCEL;
                  }

                  if (widget.enableMobileDeepLinkRewrite &&
                      isUaePassNativeScheme(dartUri)) {
                    final Map<String, String> qp = dartUri.queryParameters;
                    final String? success =
                        qp['successURL'] ??
                        qp['successurl'] ??
                        qp['successUrl'];
                    final String? failure =
                        qp['failureURL'] ??
                        qp['failureurl'] ??
                        qp['failureUrl'];

                    if (success != null && failure != null) {
                      UaePassLogger.d('captured successURL and failureURL');

                      final Uri rewritten = rewriteUaePassDeepLinkForSp(
                        uaePassDeepLink: dartUri,
                        spRedirectUri: spRedirect,
                        deepLinkScheme: widget.deepLinkScheme,
                        uaePassScheme: widget.uaePassScheme,
                        resumeAuthnPath: widget.resumeAuthnPath,
                      );

                      UaePassLogger.d('Rewritten URL = $rewritten');

                      try {
                        final bool launched = await launchUrl(
                          rewritten,
                          mode: LaunchMode.externalApplication,
                        );
                        UaePassLogger.d('launch success = $launched');
                      } catch (e, stack) {
                        UaePassLogger.e(
                          'Error launching rewritten deep link',
                          e,
                          stack,
                        );
                      }
                      return NavigationActionPolicy.CANCEL;
                    }

                    UaePassLogger.d('Launching native URI = $dartUri');
                    try {
                      final bool launched = await launchUrl(
                        dartUri,
                        mode: LaunchMode.externalApplication,
                      );
                      UaePassLogger.d('launch success = $launched');
                    } catch (e, stack) {
                      UaePassLogger.e('Error launching native URI', e, stack);
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  final String scheme = dartUri.scheme.toLowerCase();
                  if (widget.externalAppSchemes.any(
                    (String s) => s.toLowerCase() == scheme,
                  )) {
                    try {
                      await launchUrl(
                        dartUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e, stack) {
                      UaePassLogger.e('Error launching external URI', e, stack);
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                  widget.onEvent?.call(UaePassEvent.webviewLoaded);
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame != true) return;
                  UaePassLogger.e('WebView Error: ${error.description}');
                  _complete(
                    UaePassAuthResult(
                      status: UaePassFlowStatus.error,
                      errorCode: 'WEBVIEW_ERROR',
                      errorDescription: error.description,
                    ),
                  );
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  if (request.isForMainFrame != true) return;
                  UaePassLogger.e('HTTP Error: ${errorResponse.statusCode}');
                  _complete(
                    UaePassAuthResult(
                      status: UaePassFlowStatus.error,
                      errorCode: 'HTTP_ERROR_${errorResponse.statusCode}',
                      errorDescription: 'Status: ${errorResponse.statusCode}',
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ),
      ),
    );
  }

  UaePassAuthResult? _parseResult(WebUri uri) {
    return UaePassCallbackParser.parse(
      callbackUri: Uri.parse(uri.toString()),
      redirectUri: Uri.parse(widget.redirectUri),
      cancelledUriPatterns: widget.cancelledUriPatterns,
      isLogoutFlow: widget.isLogoutFlow,
    );
  }

  void _complete(UaePassAuthResult result) {
    if (!mounted || _didComplete) return;
    UaePassLogger.i(
      '_UaePassWebViewPage complete with status=${result.status}',
    );
    _didComplete = true;
    final navigator = Navigator.maybeOf(context);
    if (navigator == null || !navigator.canPop()) {
      return;
    }
    navigator.pop(result);
  }
}
