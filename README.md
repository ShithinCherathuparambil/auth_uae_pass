# auth_uae_pass

Flutter package for UAE PASS authentication using `InAppWebView`. It provides a seamless mobile-on-device experience using deep links and handles fallback scenarios intelligently.

## Features

- **Invisible Lazy Resumption**: Zero setup in `initState`. The package automatically detects and resumes interrupted flows when you call `authenticate()`.
- **Full-screen Auth Flow**: Embedded WebView for consistent UX.
- **SOP Handling**: Support for all SOP status codes (`SOP1`, `SOP2`, `SOP3`).
- **Logout Flow**: Easy integration with the UAE PASS logout service.
- **Login Button**: Premium UAE PASS themed widget with English and Arabic support.

## Installation

```yaml
dependencies:
  auth_uae_pass:
    path: ../auth_uae_pass
```

---

## 🛠️ Configuration

To handle deep link resumption correctly (especially for cold starts), you must configure your native platforms.

### Android (`AndroidManifest.xml`)

1. **Set Launch Mode**: Set `android:launchMode="singleTask"` for your `MainActivity` to ensure deep links are delivered to the existing instance.
2. **Add Intent Filter**: Add an intent filter for your redirect scheme.

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask"
    ... >
    
    <!-- UAE PASS Callback Listener -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Your custom scheme and optional path -->
        <data android:scheme="your.app.scheme" android:pathPrefix="/resume_authn" />
    </intent-filter>
</activity>

<!-- Package Visibility for app detection -->
<queries>
    <package android:name="ae.uaepass.mainapp" />
    <package android:name="ae.uaepass.mainapp.qa" />
    <package android:name="ae.uaepass.mainapp.stg" />
</queries>
```

### iOS (`Info.plist`)

1. **Query Schemes**: Allow the app to check if UAE PASS is installed.
2. **URL Types**: Register your custom URL scheme.

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>uaepass</string>
    <string>uaepassqa</string>
    <string>uaepassstg</string>
</array>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your.app.scheme</string>
        </array>
        <key>CFBundleURLName</key>
        <string>uaepass_callback</string>
    </dict>
</array>
```

### Web

No special configuration is required for Web. Ensure your `redirectUri` is a valid web URL registered in your UAE PASS Service Provider dashboard.

---

## 🚀 Usage

The package is designed to be "invisible" until needed. You do **not** need to initialize listeners in `initState`.

### Basic Authentication

```dart
import 'package:auth_uae_pass/auth_uae_pass.dart';

final auth = const AuthUaePass();

// Call this when the user taps your login button
Future<void> login() async {
  final result = await auth.authenticate(
    context,
    request: UaePassAuthRequest(
      // Helps build the URL automatically
      environment: UaePassEnvironment.staging, 
      authorizationUrl: '...', 
      redirectUri: 'your.app.scheme:///resume_authn',
      deepLinkScheme: 'your.app.scheme',
    ),
  );

  if (result.status == UaePassFlowStatus.success) {
    print('Auth Code: ${result.code}');
  }
}
```

### Intelligent Resumption (Cold Start)
If the app was killed while the user was in the UAE PASS app, simply calling `authenticate()` again (when the user taps the button after returning) will **automatically** pick up the pending deep link and complete the login instantly without opening the browser again.

---

## 💡 Use Cases

### 1. Mobile-on-Device (Native App)
The package detects the UAE PASS app and initiates a native handshake. The user confirms their identity in the UAE PASS app and is redirected back to your app via a deep link.

### 2. App Not Installed (Web/Push Fallback)
If the UAE PASS app is not found, the package falls back to a web-based flow. The user enters their EID/Email in the WebView and receives a push notification on their registered mobile device to confirm.

### 3. Visitor Integration
For first-time authentication (retrieving `unifiedID` and `profileType`), pass `visitorIntegrationFirstAuth: true` in the `UaePassAuthRequest`. This automatically sets the required scopes:
`urn:uae:digitalid:profile:general urn:uae:digitalid:profile:general:profileType urn:uae:digitalid:profile:general:unifiedId`

### 4. Token Introspection
Verify an access token on your backend or dedicated resource server before trusting it.

```dart
final verified = await auth.introspectToken(
  request: UaePassIntrospectRequest(
    clientId: '...',
    clientSecret: '...',
    token: accessToken,
    environment: UaePassEnvironment.staging,
  ),
);
```

---

## 🎨 UAE PASS Login Button

```dart
UaePassLoginButton(
  onPressed: () => _startLogin(),
  language: UaePassButtonLanguage.english, // or .arabic
  style: const UaePassButtonStyle(
    borderRadius: 8,
  ),
)
```

---

## 🛠️ Common Gotchas

- **Launch Mode**: Ensure Android is set to `singleTask`. Otherwise, a new instance of your app might be created upon return, losing the authentication state.
- **Scheme Matching**: Ensure the `redirectUri` used in the request exactly matches the scheme registered in your `AndroidManifest.xml` and `Info.plist`.
- **Environment**: Always match the `UaePassEnvironment` (staging/production) to your credentials.
