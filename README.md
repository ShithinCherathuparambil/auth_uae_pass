# UAE PASS Authentication for Flutter

A production-ready Flutter package for **UAE PASS** authentication. Built for robustness, security, and developer ease-of-use. Handles native app redirects, deep link resumption, and OIDC token flows out of the box.

[![pub package](https://img.shields.io/pub/v/auth_uae_pass.svg?label=pub&color=blue)](https://pub.dev/packages/auth_uae_pass)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-android%20|%20ios%20|%20web-blue.svg)

## 🌟 Key Features

- ⚡ **Zero-Setup Lazy Resumption**: Automatically handles deep link returns (even after app restarts) without complex `initState` logic.
- 🛡️ **Session Isolation**: Automatically clears cookies and cache before every attempt to ensure the UAE PASS server always presents a fresh transaction prompt.
- 🕵️ **Silent Logout**: Background logout via `HeadlessInAppWebView`—no more blank/black screen flickers.
- 📱 **Intelligent App Detection**: Gracefully falls back to Web/Push flows if the UAE PASS app is not installed.
- 🛠️ **Full OIDC Support**: Ready-made methods for Token Exchange, User Profile retrieval, and Introspection.
- 🎨 **Premium UI Component**: Customizable UAE PASS themed login button.

---

## 🛠️ Platform Configuration (CRITICAL)

To handle the "Coming back from UAE PASS" flow correctly, you **must** configure your native platforms to listen for your redirect URI.

### 🤖 Android (`AndroidManifest.xml`)

1. **Set Launch Mode**: Your `MainActivity` MUST be `singleTask`.
2. **Add Intent Filter**: Register your redirect scheme.
3. **Package Queries**: Allow the app to "see" UAE PASS.

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Replace with your actual scheme and optional path -->
        <data android:scheme="your_app_scheme" android:pathPrefix="/resume_authn" />
    </intent-filter>
</activity>

<!-- Allow detecting UAE PASS apps -->
<queries>
    <package android:name="ae.uaepass.mainapp" />
    <package android:name="ae.uaepass.mainapp.stg" />
    <package android:name="ae.uaepass.mainapp.qa" />
</queries>
```

### 🍎 iOS (`Info.plist`)

1. **URL Types**: Register your custom scheme.
2. **Query Schemes**: Allow the app to check for UAE PASS native apps.

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your_app_scheme</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>uaepass</string>
    <string>uaepassstg</string>
    <string>uaepassqa</string>
</array>
```

---

## 🚀 Usage

### 1. Basic Authentication

```dart
import 'package:auth_uae_pass/auth_uae_pass.dart';

final auth = const AuthUaePass();

void _onLoginTapped(BuildContext context) async {
  final result = await auth.authenticate(
    context,
    request: UaePassAuthRequest(
      environment: UaePassEnvironment.staging, // Use .production for live
      clientId: 'your_client_id',
      redirectUri: 'your_app_scheme:///resume_authn',
      deepLinkScheme: 'your_app_scheme',
    ),
  );

  if (result.status == UaePassFlowStatus.success) {
     // Access the auth code: result.callbackUri?.queryParameters['code']
  }
}
```

### 2. Full Flow (Token & Profile)

The package provides helpers to complete the OIDC handshake securely.

```dart
// 1. Get Access Token
final token = await auth.getAccessToken(
  request: UaePassAccessTokenRequest(
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret',
    code: authCode,
    redirectUri: 'your_app_scheme:///resume_authn',
    environment: UaePassEnvironment.staging,
  ),
);

// 2. Get User Profile
final profile = await auth.getUserProfile(
  request: UaePassUserProfileRequest(
    accessToken: token!.accessToken!,
    environment: UaePassEnvironment.staging,
  ),
);

print('Hello, ${profile?.fullNameEN}');
```

### 3. Silent Logout

Cleanup the session in the background without any visible WebView flicker.

```dart
await auth.logout(
  context,
  env: UaePassEnvironment.staging,
  redirectUri: 'your_app_scheme:///resume_authn',
);
```

---

## 🎨 UAE PASS Button

A theme-compliant widget for your login screen.

```dart
UaePassLoginButton(
  onPressed: _login,
  language: UaePassButtonLanguage.english, // or .arabic
  style: const UaePassButtonStyle(
    borderRadius: 12,
  ),
)
```

---

## 💡 Advanced Scenarios

### Cold Start Resumption
If your app is terminated while the user is inside the UAE PASS native app, the deep link is saved. When the user returns and you call `authenticate()` again, the package **instantly** detects the pending link and completes the login without showing a loading spinner or browser.

### Visitor Integration
To fetch `unifiedID` and `profileType`, set `visitorIntegrationFirstAuth: true` in your request:

```dart
UaePassAuthRequest(
  ...
  visitorIntegrationFirstAuth: true,
)
```

---

## 🏁 Final Checks

| Check | Success Criteria |
| :--- | :--- |
| **Android LaunchMode** | Must be `singleTask` |
| **Redirect URI** | Must match the service provider portal dashboard EXACTLY |
| **Environment** | Production credentials will NOT work in Staging environment |

---

## License

MIT License - see [LICENSE](LICENSE) for details.
