import 'package:appcheck/appcheck.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// UAE PASS mobile authentication API (acr values, deep links).
/// See: https://docs.uaepass.ae/feature-guides/authentication/mobile-application/guide/api
const String kUaePassAcrMobileOnDevice = 'urn:digitalid:authentication:flow:mobileondevice';

/// Used when the UAE PASS app is not installed (web / push flow).
/// User enters identifier in webview; confirmation via push on another device (see mobile API).
const String kUaePassAcrWebFallback = 'urn:safelayer:tws:policies:authentication:level:low';

/// Standard `scope` value (general profile).
const String kUaePassScopeGeneral = 'urn:uae:digitalid:profile:general';

/// Visitor integration — additional claims (first authentication only per docs).
const String kUaePassScopeProfileType = 'urn:uae:digitalid:profile:general:profileType';
const String kUaePassScopeUnifiedId = 'urn:uae:digitalid:profile:general:unifiedId';

/// Space-separated `scope` for visitor integration **first** authentication call
/// (`unifiedID` and `profileType`).
const String kUaePassVisitorFirstAuthScope =
    'urn:uae:digitalid:profile:general urn:uae:digitalid:profile:general:profileType urn:uae:digitalid:profile:general:unifiedId';

/// Merges [kUaePassVisitorFirstAuthScope] into the existing `scope` on [authorizeUri].
Uri applyVisitorIntegrationScopes(Uri authorizeUri) {
  final Map<String, String> params =
      Map<String, String>.from(authorizeUri.queryParameters);
  final String existing = params['scope'] ?? '';
  final Set<String> scopes = existing.split(' ').where((s) => s.isNotEmpty).toSet();
  scopes.addAll(kUaePassVisitorFirstAuthScope.split(' '));
  params['scope'] = scopes.join(' ');
  return authorizeUri.replace(queryParameters: params);
}

enum UaePassEnvironment {
  /// Staging: `uaepassstg://` (see official docs).
  staging,

  /// Production: `uaepass://`.
  production,
}

/// Probes whether the UAE PASS app is installed.
///
/// **Android**: Checks via package ID (`ae.uaepass.mainapp.stg` or `ae.uaepass.mainapp`).
/// Requires `<queries>` in `AndroidManifest.xml`.
///
/// **iOS**: Checks via URL scheme (`uaepass://` or `uaepassstg://`).
/// Requires `LSApplicationQueriesSchemes` in `Info.plist`.
///
/// **Web**: Always returns `false` (Web/Push flow fallback).
Future<bool> isUaePassAppInstalled(UaePassEnvironment environment) async {
  if (kIsWeb) return false;
  debugPrint('AuthUaePass: Starting app check for $environment');

  final AppCheck appCheck = AppCheck();

  if (defaultTargetPlatform == TargetPlatform.android) {
    final List<String> packageIds = switch (environment) {
      UaePassEnvironment.staging => <String>[
          'ae.uaepass.mainapp.stg',
          'ae.uaepass.mainapp.qa',
          'ae.uaepass.mainapp.dev',
        ],
      UaePassEnvironment.production => <String>['ae.uaepass.mainapp'],
    };

    debugPrint('AuthUaePass: Probing Android packages: ${packageIds.join(', ')}');
    for (final String packageId in packageIds) {
      try {
        final bool installed = await appCheck.isAppInstalled(packageId);
        debugPrint('AuthUaePass: Package $packageId installed status: $installed');
        if (installed) {
          debugPrint('AuthUaePass: detected Android package $packageId');
          return true;
        }
      } catch (e) {
        debugPrint('AuthUaePass: Error checking package $packageId: $e');
      }
    }
  }

  final List<String> schemes = switch (environment) {
    UaePassEnvironment.staging => <String>['uaepassstg', 'uaepassqa', 'uaepassdev'],
    UaePassEnvironment.production => <String>['uaepass'],
  };

  debugPrint('AuthUaePass: Probing schemes: ${schemes.join(', ')}');
  for (final String scheme in schemes) {
    final Uri probe = Uri.parse('$scheme://');
    try {
      final bool canLaunch = await canLaunchUrl(probe);
      debugPrint('AuthUaePass: Scheme $scheme canLaunch status: $canLaunch');
      if (canLaunch) {
        debugPrint('AuthUaePass: detected $scheme app via canLaunchUrl');
        return true;
      }
    } catch (e) {
      debugPrint('AuthUaePass: Error probing scheme $scheme: $e');
    }
  }

  debugPrint('AuthUaePass: No app detected after all probes.');
  return false;
}

/// Sets or replaces `acr_values` on the authorize URL per the mobile API.
Uri applyMobileAcrValues(
  Uri authorizeUri, {
  required bool uaePassAppInstalled,
}) {
  final Map<String, String> params = Map<String, String>.from(authorizeUri.queryParameters);
  params['acr_values'] =
      uaePassAppInstalled ? kUaePassAcrMobileOnDevice : kUaePassAcrWebFallback;
  return authorizeUri.replace(queryParameters: params);
}

/// `yourapp:///resume_authn?url=<originalSuccessOrFailureUrl>` (SP scheme + resume path).
Uri buildSpResumeUri({
  required Uri spRedirectUri,
  String? deepLinkScheme,
  required String resumeAuthnPath,
  required String wrappedUrl,
}) {
  final String normalizedPath =
      resumeAuthnPath.startsWith('/') ? resumeAuthnPath : '/$resumeAuthnPath';
  final String scheme = deepLinkScheme ?? spRedirectUri.scheme;
  final bool isWeb = scheme == 'http' || scheme == 'https';

  if (isWeb) {
    return Uri(
      scheme: scheme,
      host: spRedirectUri.host,
      path: normalizedPath,
      queryParameters: <String, String>{'url': wrappedUrl},
    );
  }

  // For custom schemes, ensure we don't end up with triple slashes unless intended.
  // Standard format yourapp://resume_authn?url=...
  return Uri.parse('$scheme://$normalizedPath')
      .replace(queryParameters: <String, String>{'url': wrappedUrl});
}

/// Rewrites `uaepass*://...?successURL=...&failureURL=...` so success/failure point at the SP app.
///
/// Per docs, SP replaces hub URLs with `successURL=yourapp:///resume_authn?url=<url1>` etc.
Uri rewriteUaePassDeepLinkForSp({
  required Uri uaePassDeepLink,
  required Uri spRedirectUri,
  String? deepLinkScheme,
  String? uaePassScheme,
  required String resumeAuthnPath,
}) {
  Uri targetLink = uaePassDeepLink;

  // If the link is an Android intent URL, transform it back to a standard scheme URL
  if (targetLink.scheme.toLowerCase() == 'intent') {
    final String frag = targetLink.fragment;
    String baseScheme = uaePassScheme ?? 'uaepassstg';
    
    // Attempt to extract explicit scheme from fragment (e.g. scheme=uaepassstg)
    final RegExp schemeRegex = RegExp(r'scheme=([^;]+)');
    final Match? match = schemeRegex.firstMatch(frag);
    if (match != null && match.groupCount >= 1) {
      baseScheme = match.group(1)!;
    }
    
    // Create the normal URI instead of intent URI
    targetLink = targetLink.replace(scheme: baseScheme, fragment: '');
  }

  final Map<String, String> qp =
      Map<String, String>.from(targetLink.queryParameters);

  // Identify raw values before we start deleting keys
  final String? successRaw =
      qp['successURL'] ?? qp['successurl'] ?? qp['successUrl'];
  final String? failureRaw =
      qp['failureURL'] ?? qp['failureurl'] ?? qp['failureUrl'];

  if (successRaw == null || failureRaw == null) {
    return targetLink;
  }

  // Remove all variations to avoid duplicate parameters in the final URL
  qp.remove('successURL');
  qp.remove('successurl');
  qp.remove('successUrl');
  qp.remove('failureURL');
  qp.remove('failureurl');
  qp.remove('failureUrl');

  String wrap(String original) {
    return buildSpResumeUri(
      spRedirectUri: spRedirectUri,
      deepLinkScheme: deepLinkScheme,
      resumeAuthnPath: resumeAuthnPath,
      wrappedUrl: original,
    ).toString();
  }

  qp['successurl'] = wrap(successRaw);
  qp['failureurl'] = wrap(failureRaw);

  final Uri rewritten = targetLink.replace(queryParameters: qp);
  if (uaePassScheme != null && uaePassScheme.isNotEmpty && rewritten.scheme != uaePassScheme) {
    return rewritten.replace(scheme: uaePassScheme);
  }
  return rewritten;
}

bool isUaePassNativeScheme(Uri uri) {
  final String scheme = uri.scheme.toLowerCase();
  const Set<String> known = <String>{
    'uaepass',
    'uaepassqa',
    'uaepassdev',
    'uaepassstg',
  };
  
  if (known.contains(scheme)) {
    return true;
  }
  
  // Handle Android intent:// deep links
  if (scheme == 'intent') {
    final String fragment = uri.fragment.toLowerCase();
    for (final k in known) {
      if (fragment.contains('scheme=$k')) return true;
    }
  }
  
  return false;
}

bool isSpResumeAuthnCallback({
  required Uri uri,
  required Uri spRedirectUri,
  String? deepLinkScheme,
  required String resumeAuthnPath,
}) {
  final String expectedScheme = (deepLinkScheme ?? spRedirectUri.scheme).toLowerCase();
  debugPrint('AuthUaePass: Resumption check for $uri');
  debugPrint('  - Scheme: ${uri.scheme} (expected: $expectedScheme)');
  debugPrint('  - Host: ${uri.host}');
  debugPrint('  - Path: ${uri.path}');
  debugPrint('  - Query: ${uri.queryParameters.keys.join(',')}');

  if (uri.scheme.toLowerCase() != expectedScheme) {
    debugPrint('AuthUaePass: [REJECT] Scheme mismatch');
    return false;
  }
  
  // Normalize both by ensuring they start with / and have no trailing /
  String normalize(String s) {
    String res = s.startsWith('/') ? s : '/$s';
    if (res.endsWith('/') && res.length > 1) {
      res = res.substring(0, res.length - 1);
    }
    return res.toLowerCase();
  }

  final String normalizedTarget = normalize(resumeAuthnPath);
  
  // Construct path from host + path if standard custom scheme parsing puts the path in host
  // e.g. com.example://resume_authn?url=...
  String actualPath = uri.path;
  if (uri.host.isNotEmpty && uri.path.isEmpty) {
    actualPath = '/${uri.host}';
  } else if (uri.path.isEmpty) {
    actualPath = '/';
  }
  
  final String normalizedActual = normalize(actualPath);
  debugPrint('  - Normalized Path: $normalizedActual (expected: $normalizedTarget)');

  if (normalizedActual != normalizedTarget) {
    debugPrint('AuthUaePass: [REJECT] Path mismatch');
    return false;
  }
  
  final String? nested = uri.queryParameters['url'];
  if (nested == null || nested.isEmpty) {
    debugPrint('AuthUaePass: [REJECT] Missing "url" query parameter');
    return false;
  }
  
  debugPrint('AuthUaePass: [ACCEPT] Resumption criteria met');
  return true;
}

String? nestedUrlFromResumeCallback(Uri uri) => uri.queryParameters['url'];
