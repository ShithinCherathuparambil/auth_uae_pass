// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, uri_does_not_exist
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'uae_pass_models.dart';
import 'uae_pass_logger.dart';

/// Opens a blank popup window synchronously during the user gesture to avoid popup blockers.
dynamic openWebPopupPlaceholder() {
  final width = 600;
  final height = 700;
  final screenWidth = html.window.screen?.width ?? 1024;
  final screenHeight = html.window.screen?.height ?? 768;
  final left = (screenWidth - width) ~/ 2;
  final top = (screenHeight - height) ~/ 2;

  UaePassLogger.i('WebPopup: Opening placeholder popup synchronously...');
  return html.window.open(
    'about:blank',
    'uae_pass_auth',
    'width=$width,height=$height,left=$left,top=$top,scrollbars=yes,status=no,resizable=yes',
  );
}

/// Web implementation of [openWebPopup] using a popup window.
Future<UaePassAuthResult> openWebPopup({
  required String initialUrl,
  required String redirectUri,
  dynamic popupWindow,
  List<String> cancelledUriPatterns = const <String>[],
  bool isLogoutFlow = false,
}) async {
  final completer = Completer<UaePassAuthResult>();

  dynamic popup = popupWindow;
  if (popup == null) {
    // Center the popup window on screen
    final width = 600;
    final height = 700;
    final screenWidth = html.window.screen?.width ?? 1024;
    final screenHeight = html.window.screen?.height ?? 768;
    final left = (screenWidth - width) ~/ 2;
    final top = (screenHeight - height) ~/ 2;

    UaePassLogger.i('WebPopup: Opening authentication popup...');
    popup = html.window.open(
      'about:blank',
      'uae_pass_auth',
      'width=$width,height=$height,left=$left,top=$top,scrollbars=yes,status=no,resizable=yes',
    );
  }

  if (popup == null) {
    UaePassLogger.e('WebPopup: Failed to open popup window. It might have been blocked by a popup blocker.');
    return const UaePassAuthResult(
      status: UaePassFlowStatus.error,
      errorCode: 'POPUP_BLOCKED',
      errorDescription: 'Popup blocker prevented opening the UAE PASS login window.',
    );
  }

  // Navigate the popup window to the initialUrl using js_util to bypass Dart's LocationCrossFrame restrictions
  UaePassLogger.i('WebPopup: Navigating popup to authorization endpoint.');
  try {
    final locationObj = js_util.getProperty(popup, 'location');
    js_util.setProperty(locationObj, 'href', initialUrl);
  } catch (e, stack) {
    UaePassLogger.e('WebPopup: Error setting popup location', e, stack);
  }

  Timer? timeoutTimer;
  // Safety timeout: auto-reject if flow takes more than 5 minutes without response
  timeoutTimer = Timer(const Duration(minutes: 5), () {
    if (!completer.isCompleted) {
      UaePassLogger.w('WebPopup: Authentication timed out after 5 minutes.');
      completer.complete(
        const UaePassAuthResult(
          status: UaePassFlowStatus.error,
          errorCode: 'TIMEOUT',
          errorDescription: 'The authentication flow timed out.',
        ),
      );
      try {
        popup.close();
      } catch (_) {}
    }
  });

  // 1. Listen for postMessage (for cross-origin callbacks or specific redirect handlers)
  StreamSubscription<html.MessageEvent>? messageSub;
  messageSub = html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map) {
        final type = data['type'];
        if (type == 'uae_pass_callback') {
          // If the backend pre-exchanged the token and profile, return them directly
          if (data['token'] != null && data['profile'] != null) {
            UaePassLogger.i('WebPopup: Received token and profile directly via postMessage.');
            final tokenMap = Map<String, dynamic>.from(data['token'] as Map);
            final profileMap = Map<String, dynamic>.from(data['profile'] as Map);
            final token = UaePassUserToken.fromJson(tokenMap);
            final profile = UaePassUserProfile.fromJson(profileMap);
            
            timeoutTimer?.cancel();
            if (!completer.isCompleted) {
              completer.complete(UaePassAuthResult(
                status: UaePassFlowStatus.loginSuccess,
                statusCode: 'LOGIN_SUCCESS',
                token: token,
                profile: profile,
              ));
            }
            try { popup.close(); } catch (_) {}
            return;
          }

          final url = data['url'] ?? data['uri'] ?? data['callbackUrl'];
          if (url is String) {
            UaePassLogger.i('WebPopup: Received callback URL via postMessage: $url');
            final uri = Uri.parse(url);
            final result = UaePassCallbackParser.parse(
              callbackUri: uri,
              redirectUri: Uri.parse(redirectUri),
              cancelledUriPatterns: cancelledUriPatterns,
              isLogoutFlow: isLogoutFlow,
              skipHostCheck: true, // Trusted postMessage data bypasses host check
            );
            if (result != null) {
              timeoutTimer?.cancel();
              if (!completer.isCompleted) {
                completer.complete(result);
              }
              try { popup.close(); } catch (_) {}
            }
          }
        }
      }
    } catch (e, stack) {
      UaePassLogger.e('WebPopup: Error processing message event', e, stack);
    }
  });

  // 2. Poll the popup URL (for same-origin redirect) and check if closed
  Timer.periodic(const Duration(milliseconds: 200), (timer) {
    if (popup.closed == true) {
      timer.cancel();
      messageSub?.cancel();
      timeoutTimer?.cancel();
      if (!completer.isCompleted) {
        UaePassLogger.i('WebPopup: Popup window was closed by the user.');
        completer.complete(
          const UaePassAuthResult(
            status: UaePassFlowStatus.cancelled,
            statusCode: 'USER_CANCELLED',
          ),
        );
      }
      return;
    }

    try {
      final location = popup.location;
      final currentUrl = (location as html.Location).href;
      if (currentUrl.isNotEmpty && currentUrl != 'about:blank') {
        final uri = Uri.parse(currentUrl);
        final redirectUriUri = Uri.parse(redirectUri);

        final String currentOrigin = html.window.location.origin.toLowerCase();
        final String uriOrigin = '${uri.scheme}://${uri.host}';
        final bool isSameOrigin = uriOrigin.toLowerCase() == currentOrigin;
        final bool isRedirectUriHost = uri.scheme == redirectUriUri.scheme && uri.host == redirectUriUri.host;

        if (isSameOrigin || isRedirectUriHost) {
          final result = UaePassCallbackParser.parse(
            callbackUri: uri,
            redirectUri: redirectUriUri,
            cancelledUriPatterns: cancelledUriPatterns,
            isLogoutFlow: isLogoutFlow,
            skipHostCheck: isSameOrigin, // Skip host check if it redirected back to frontend origin
          );
          if (result != null) {
            timer.cancel();
            messageSub?.cancel();
            timeoutTimer?.cancel();
            if (!completer.isCompleted) {
              UaePassLogger.i('WebPopup: Successfully parsed redirect URL from popup location.');
              completer.complete(result);
            }
            popup.close();
          }
        }
      }
    } catch (_) {
      // Ignore SecurityError/CORS exception when the popup is on a different origin (e.g. stg-id.uaepass.ae).
      // This is expected until the popup redirects back to the app's same origin.
    }
  });

  return completer.future;
}
