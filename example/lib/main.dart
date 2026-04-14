import 'dart:async';

import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/material.dart';

// =============================================================================
// WARNING: Temporary Highlight staging credentials for local example ONLY.
// Rotate keys, remove secrets from source, and use env / secure storage before
// production or any public repository.
// =============================================================================

const String _kClientId = 'auh_highlight_mob_stage';
const String _kClientSecret = 'xfGKpgaaoaTVedNf';

/// Registered redirect URI (must match UAE PASS app registration exactly).
const String _kRedirectUri =
    'https://highlight-business-portal.vercel.app/api/auth/callback/uaepass';

/// App URL scheme (documented for deep linking / universal links setup).
const String _kUrlScheme = 'com.example.authpassuae';

/// `false` = STG idhub; `true` = production idhub.
const bool _kIsProduction = false;

void main() {
  runApp(const MyApp());
}

/// Root widget only builds [MaterialApp]. Navigation context must come from a
/// descendant (e.g. [HighlightHomePage]), not from above [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HighlightHomePage(),
    );
  }
}

class HighlightHomePage extends StatefulWidget {
  const HighlightHomePage({super.key});

  @override
  State<HighlightHomePage> createState() => _HighlightHomePageState();
}

class _HighlightHomePageState extends State<HighlightHomePage> {
  final AuthUaePass _auth = const AuthUaePass();
  String _lastResult = 'Configure locale, then tap Sign in.';
  bool _arabicUi = false;
  StreamSubscription<Uri>? _linkSubscription;

  UaePassAuthRequest get _defaultRequest => UaePassAuthRequest(
    authorizationUrl: _authorizationUrl(),
    redirectUri: _kRedirectUri,
    deepLinkScheme: _kUrlScheme,
    cancelledUriPatterns: const <String>['cancel'],
    environment: _env,
  );

  UaePassEnvironment get _env => _kIsProduction
      ? UaePassEnvironment.production
      : UaePassEnvironment.staging;

  String _authorizationUrl() {
    return _auth.authorizationUrl(
      env: _env,
      clientId: _kClientId,
      redirectUri: _kRedirectUri,
      uiLocales: _arabicUi ? 'ar' : 'en',
    );
  }

  @override
  void initState() {
    super.initState();
    _linkSubscription = _auth.listenToDeepLinks(
      context: context,
      defaultRequest: _defaultRequest,
      onResult: _processResult,
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UAE PASS — Highlight (STG example)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Scheme: $_kUrlScheme · Client: $_kClientId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            title: const Text('Arabic UI (ui_locales)'),
            value: _arabicUi,
            onChanged: (bool v) => setState(() => _arabicUi = v),
          ),
          UaePassLoginButton(onPressed: _startAuth),
          const SizedBox(height: 12),
          UaePassLoginButton(
            language: UaePassButtonLanguage.arabic,
            style: const UaePassButtonStyle(
              iconAppearance: UaePassButtonIconAppearance.lightBackground,
            ),
            onPressed: _startAuth,
          ),
          const SizedBox(height: 12),
          UaePassLoginButton(
            onPressed: _startAuth,
            customLabel: 'Sign in with UAE PASS',
            style: const UaePassButtonStyle(
              backgroundColor: Color(0xFF000000),
              fontSize: 15,
              foregroundColor: Colors.white,
              borderRadius: 12,
              iconAppearance: UaePassButtonIconAppearance.darkBackground,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _startLogout, child: const Text('Logout')),
          const SizedBox(height: 20),
          SelectableText(_lastResult),
        ],
      ),
    );
  }

  Future<void> _startAuth() async {
    final String authUrl = _authorizationUrl();
    debugPrint('Example: Starting auth with final URL: $authUrl');

    final UaePassAuthResult result = await _auth.authenticate(
      context,
      request: _defaultRequest,
    );

    if (!mounted) return;
    _processResult(result);
  }

  Future<void> _processResult(UaePassAuthResult result) async {
    final String? code = result.callbackUri?.queryParameters['code'];
    if (code != null) {
      final UaePassUserToken? token = await _auth.getAccessToken(
        request: UaePassAccessTokenRequest(
          tokenUrl: UaePassIdHubEndpoints.tokenUrl(_env),
          clientId: _kClientId,
          clientSecret: _kClientSecret,
          redirectUri: _kRedirectUri,
          code: code,
        ),
      );
      if (token != null) {
        final profile = await _auth.getUserProfile(
          request: UaePassUserProfileRequest(
            userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(_env),
            accessToken: token.accessToken!,
          ),
        );
        if (!mounted) return;
        setState(() {
          if (profile != null) {
            final buffer = StringBuffer();
            buffer.writeln('OK: got token & profile.');
            buffer.writeln('UUID: ${profile.uuid}');
            buffer.writeln('Name: ${profile.fullNameEN}');
            buffer.writeln('Name (AR): ${profile.fullNameAR}');
            buffer.writeln('Gender: ${profile.gender}');
            buffer.writeln('Nationality: ${profile.nationalityEN}');
            if (profile.email != null) {
              buffer.writeln('Email: ${profile.email}');
            }
            if (profile.mobile != null) {
              buffer.writeln('Mobile: ${profile.mobile}');
            }
            _lastResult = buffer.toString();
          } else {
            _lastResult = 'Token OK, but getUserProfile failed.';
          }
        });
      } else {
        setState(() {
          _lastResult =
              'Code received but token exchange failed. '
              'status=${result.status.name}; check redirect_uri and client.';
        });
      }
      return;
    }

    final String message = switch (result.status) {
      UaePassFlowStatus.sop1 ||
      UaePassFlowStatus.sop2 ||
      UaePassFlowStatus.sop3 => 'Auth success: ${result.status}',
      UaePassFlowStatus.cancelled => 'Auth cancelled by user',
      UaePassFlowStatus.error =>
        'Auth failed: ${result.errorCode ?? '-'} (${result.errorDescription ?? '-'})',
      _ => 'Auth result: ${result.status.name} · no code in callback',
    };

    setState(() => _lastResult = message);
  }

  Future<void> _startLogout() async {
    final UaePassAuthResult result = await _auth.logout(
      context,
      env: _env,
      redirectUri: _kRedirectUri,
    );
    if (!mounted) return;
    setState(() {
      _lastResult = 'Logout: ${result.status.name}';
    });
  }
}
