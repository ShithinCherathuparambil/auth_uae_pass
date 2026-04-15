import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthUaePass {
  const AuthUaePass({http.Client? httpClient, AppLinks? appLinks})
    : _httpClient = httpClient,
      _appLinks = appLinks;

  final http.Client? _httpClient;
  final AppLinks? _appLinks;

  http.Client get _client => _httpClient ?? http.Client();
  AppLinks get _links => _appLinks ?? AppLinks();

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

  /// Ensures the global deep link listener is active.
  static void _ensureInitialized([AppLinks? links]) {
    if (_internalSubscription != null) return;
    final AppLinks appLinks = links ?? AppLinks();
    _internalSubscription = appLinks.uriLinkStream.listen((uri) {
      onDeepLinkReceived(uri);
    });
  }

  /// Call this from your app's deep link listener (e.g. app_links or uni_links)
  /// when a URL with your custom scheme is received.
  static void onDeepLinkReceived(Uri uri) {
    debugPrint('AuthUaePass: Captured link: $uri');
    _lastCapturedLink = uri;
    _deepLinkStream.add(uri);
  }

  /// Clears any buffered deep links.
  static void clearCapturedLink() {
    if (_lastCapturedLink != null) {
      debugPrint('AuthUaePass: Clearing captured link buffer');
      _lastCapturedLink = null;
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
      debugPrint(
        'AuthUaePass: Detected resumption link, launching recovery flow...',
      );
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
    debugPrint('AuthUaePass: signIn result status=${result.status}');
    if (!result.isSuccess) {
      return null;
    }

    final callbackUri = result.callbackUri;
    if (callbackUri == null) {
      return null;
    }
    final code = callbackUri.queryParameters['code'];
    debugPrint(
      'AuthUaePass: signIn retrieved code=${code != null ? '***' : 'null'}',
    );
    return code;
  }

  /// A simplified high-level method to perform the full UAE PASS authentication flow.
  ///
  /// This method:
  /// 1. Builds the authorization URL.
  /// 2. Launches the WebView for user authentication.
  /// 3. Exchanges the authorization code for an access token.
  /// 4. Fetches the user profile data.
  ///
  /// Returns a [UaePassAuthData] containing the final status, token, and profile.
  Future<UaePassAuthData> signInWithProfile(
    BuildContext context, {
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required UaePassEnvironment environment,
    String uiLocale = 'en',
    List<String> cancelledUriPatterns = const <String>[],
  }) async {
    final String authUrl = authorizationUrl(
      env: environment,
      clientId: clientId,
      redirectUri: redirectUri,
      uiLocales: uiLocale,
    );

    final authResult = await authenticate(
      context,
      request: UaePassAuthRequest(
        authorizationUrl: authUrl,
        redirectUri: redirectUri,
        environment: environment,
        cancelledUriPatterns: cancelledUriPatterns,
      ),
    );

    if (!authResult.isSuccess) {
      return UaePassAuthData(
        status: authResult.status,
        errorCode: authResult.errorCode,
        errorDescription: authResult.errorDescription,
      );
    }

    final code = authResult.callbackUri?.queryParameters['code'];
    if (code == null) {
      return UaePassAuthData(
        status: authResult.status,
        errorCode: 'MISSING_CODE',
        errorDescription: 'Authentication succeeded but no code was returned.',
      );
    }

    final token = await getAccessToken(
      request: UaePassAccessTokenRequest(
        tokenUrl: UaePassIdHubEndpoints.tokenUrl(environment),
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        code: code,
      ),
    );

    if (token == null || token.accessToken == null) {
      return UaePassAuthData(
        status: authResult.status,
        errorCode: 'TOKEN_EXCHANGE_FAILED',
        errorDescription: 'Failed to exchange authorization code for token.',
      );
    }

    final profile = await getUserProfile(
      request: UaePassUserProfileRequest(
        userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(environment),
        accessToken: token.accessToken!,
      ),
    );

    UaePassSopLevel resolvedSop = authResult.sopLevel;
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

    return UaePassAuthData(
      status: authResult.status,
      token: token,
      profile: profile,
      sopLevel: resolvedSop,
    );
  }

  Future<UaePassUserToken?> getAccessToken({
    required UaePassAccessTokenRequest request,
  }) async {
    debugPrint('AuthUaePass: getAccessToken request...');
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
      debugPrint('AuthUaePass: getAccessToken SUCCESS');
      return result;
    } catch (e) {
      debugPrint('AuthUaePass: getAccessToken ERROR: $e');
      return null;
    }
  }

  /// **GET** [userInfoUrl] with `Authorization: Bearer <access_token>` (client or validated token).
  ///
  /// Staging: `https://stg-id.uaepass.ae/idshub/userinfo` — see UAE PASS userinfo documentation.
  Future<UaePassUserProfile?> getUserProfile({
    required UaePassUserProfileRequest request,
  }) async {
    debugPrint('AuthUaePass: getUserProfile request...');
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
      debugPrint('AuthUaePass: getUserProfile SUCCESS');
      debugPrint('  - sub: ${result.sub}');
      debugPrint('  - uuid: ${result.uuid}');
      debugPrint('  - unifiedId: ${result.unifiedId}');
      debugPrint('  - fullNameEN: ${result.fullNameEN}');
      debugPrint('  - fullNameAR: ${result.fullNameAR}');
      debugPrint('  - email: ${result.email}');
      debugPrint('  - mobile: ${result.mobile}');
      debugPrint('  - idn: ${result.idn}');
      debugPrint('  - userType: ${result.userType}');
      debugPrint('  - profileType: ${result.profileType}');
      debugPrint('  - acr: ${result.acr}');
      debugPrint('  - amr: ${result.amr}');
      debugPrint('  - nationalityEN: ${result.nationalityEN}');
      debugPrint('  - nationalityAR: ${result.nationalityAR}');
      debugPrint('  - gender: ${result.gender}');
      debugPrint('  - spuuid: ${result.spuuid}');
      debugPrint('  - idType: ${result.idType}');
      debugPrint('  - titleEN: ${result.titleEN}');
      debugPrint('  - titleAR: ${result.titleAR}');
      return result;
    } catch (e) {
      debugPrint('AuthUaePass: getUserProfile ERROR: $e');
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
  }) async {
    _ensureInitialized();
    Uri? pendingUri;

    // 1. Check if we have a captured runtime link
    if (_lastCapturedLink != null) {
      pendingUri = _lastCapturedLink;
      _lastCapturedLink = null; // Consume
    }

    // 2. Check if there was an initial link (Cold Start)
    if (pendingUri == null && !_initialLinkHandled) {
      _initialLinkHandled = true;
      try {
        pendingUri = await _links.getInitialLink();
        if (pendingUri != null) {
          debugPrint(
            'AuthUaePass: Found initial link for cold start: $pendingUri',
          );
        }
      } catch (e) {
        debugPrint('AuthUaePass: Error getting initial link: $e');
      }
    }

    // 3. If a pending link exists and matches the resumption criteria, use it!
    if (pendingUri != null) {
      final bool isResumption = isSpResumeAuthnCallback(
        uri: pendingUri,
        spRedirectUri: Uri.parse(request.redirectUri),
        deepLinkScheme: request.deepLinkScheme,
        resumeAuthnPath: request.resumeAuthnPath,
      );

      if (isResumption) {
        debugPrint(
          'AuthUaePass: Resuming interrupted flow via handleResumption...',
        );
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
      final UaePassEnvironment env =
          request.environment ?? UaePassEnvironment.production;
      final bool installed = await isUaePassAppInstalled(env);
      debugPrint('AuthUaePass: app check for $env: installed=$installed');
      parsed = applyMobileAcrValues(parsed, uaePassAppInstalled: installed);
    }
    if (request.visitorIntegrationFirstAuth) {
      parsed = applyVisitorIntegrationScopes(parsed);
    }
    final String initialUrl = parsed.toString();
    debugPrint('AuthUaePass: authenticate starting with URL: $initialUrl');

    // Ensure a clean slate by clearing cookies before starting a new flow.
    // This prevents stale session state from interfering with the new request.
    try {
      final CookieManager cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      debugPrint('AuthUaePass: WebView cookies cleared');
    } catch (e) {
      debugPrint('AuthUaePass: Warning clearing cookies: $e');
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
      debugPrint('AuthUaePass: Resumption failed: No nested URL in $deepLink');
      return const UaePassAuthResult(status: UaePassFlowStatus.error);
    }

    debugPrint(
      'AuthUaePass: Resuming authentication via global entry: $nested',
    );

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
        ),
        fullscreenDialog: true,
      ),
    );

    return result ??
        const UaePassAuthResult(status: UaePassFlowStatus.cancelled);
  }

  Future<UaePassAuthResult> logout(
    BuildContext context, {
    required UaePassEnvironment env,
    required String redirectUri,
  }) async {
    debugPrint('AuthUaePass: Starting silent logout...');
    final Completer<UaePassAuthResult> completer =
        Completer<UaePassAuthResult>();
    HeadlessInAppWebView? headless;

    headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(logoutUrl(env: env, redirectUri: redirectUri)),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        clearCache: true,
      ),
      onLoadStart: (controller, url) {
        if (url == null) return;
        debugPrint('AuthUaePass: Silent logout loading $url');

        final UaePassAuthResult? result = UaePassCallbackParser.parse(
          callbackUri: Uri.parse(url.toString()),
          redirectUri: Uri.parse(redirectUri),
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: true,
        );
        if (result != null &&
            result.status == UaePassFlowStatus.logoutSuccess) {
          debugPrint('AuthUaePass: Silent logout complete');
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
          redirectUri: Uri.parse(redirectUri),
          cancelledUriPatterns: const <String>[],
          isLogoutFlow: true,
        );
        if (result != null &&
            result.status == UaePassFlowStatus.logoutSuccess) {
          debugPrint('AuthUaePass: Silent logout complete via override');
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
          debugPrint('AuthUaePass: Silent logout timed out');
          return const UaePassAuthResult(
            status: UaePassFlowStatus.logoutSuccess,
          );
        },
      );
      return result;
    } catch (e) {
      debugPrint('AuthUaePass: Error during silent logout: $e');
      return const UaePassAuthResult(status: UaePassFlowStatus.error);
    } finally {
      await headless.dispose();
    }
  }

  /// Authorize URL (acr_values applied by package when [environment] is set).
  static String authorizationUrl({
    required UaePassEnvironment env,
    required String clientId,
    required String redirectUri,
    required String uiLocales,
  }) {
    final Uri base = Uri.parse(UaePassIdHubEndpoints.authorizeUrl(env));
    final Map<String, String> q = Map<String, String>.from(
      base.queryParameters,
    );
    q['response_type'] = 'code';
    q['client_id'] = clientId;
    q['redirect_uri'] = redirectUri;
    q['scope'] = 'urn:uae:digitalid:profile:general';
    q['state'] = '${DateTime.now().millisecondsSinceEpoch}';
    q['ui_locales'] = uiLocales;
    return base.replace(queryParameters: q).toString();
  }

  static String logoutUrl({
    required UaePassEnvironment env,
    required String redirectUri,
  }) {
    final String hub = env == UaePassEnvironment.production
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
      debugPrint('AuthUaePass: WebView listener triggered for $uri');
      if (!mounted) {
        debugPrint('  - [IGNORE] WebView not mounted');
        return;
      }
      if (_didComplete) {
        debugPrint('  - [IGNORE] Flow already complete');
        return;
      }
      if (_controller == null) {
        debugPrint('  - [IGNORE] Controller is null');
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
          debugPrint('AuthUaePass: [PROCESS] Resuming flow: $nested');
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
                      debugPrint(
                        'AuthUaePass: SP callback received, invoking $nested',
                      );
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
                      debugPrint(
                        'AuthUaePass: captured successURL and failureURL',
                      );

                      final Uri rewritten = rewriteUaePassDeepLinkForSp(
                        uaePassDeepLink: dartUri,
                        spRedirectUri: spRedirect,
                        deepLinkScheme: widget.deepLinkScheme,
                        uaePassScheme: widget.uaePassScheme,
                        resumeAuthnPath: widget.resumeAuthnPath,
                      );

                      debugPrint('AuthUaePass: Rewritten URL = $rewritten');

                      try {
                        final bool launched = await launchUrl(
                          rewritten,
                          mode: LaunchMode.externalApplication,
                        );
                        debugPrint('AuthUaePass: launch success = $launched');
                      } catch (e, stack) {
                        debugPrint(
                          'AuthUaePass: Error launching rewritten deep link: $e',
                        );
                        debugPrint('AuthUaePass: StackTrace: $stack');
                      }
                      return NavigationActionPolicy.CANCEL;
                    }

                    debugPrint('AuthUaePass: Launching native URI = $dartUri');
                    try {
                      final bool launched = await launchUrl(
                        dartUri,
                        mode: LaunchMode.externalApplication,
                      );
                      debugPrint('AuthUaePass: launch success = $launched');
                    } catch (e, stack) {
                      debugPrint('AuthUaePass: Error launching native URI: $e');
                      debugPrint('AuthUaePass: StackTrace: $stack');
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
                    } catch (e) {
                      debugPrint(
                        'AuthUaePass: Error launching external URI: $e',
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (_, url) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame != true) return;
                  debugPrint(
                    'AuthUaePass: WebView Error: ${error.description}',
                  );
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
                  debugPrint(
                    'AuthUaePass: HTTP Error: ${errorResponse.statusCode}',
                  );
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
    debugPrint(
      'AuthUaePass: _UaePassWebViewPage complete with status=${result.status}',
    );
    _didComplete = true;
    final navigator = Navigator.maybeOf(context);
    if (navigator == null || !navigator.canPop()) {
      return;
    }
    navigator.pop(result);
  }
}
