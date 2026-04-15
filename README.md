# UAE PASS Authentication for Flutter

A production-ready Flutter package for **UAE PASS** authentication. Built for robustness, security, and developer ease-of-use. Handles native app redirects, deep link resumption, and OIDC token flows out of the box with over 120+ UI variations.

<p align="center">
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.33.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.42.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.48.png" width="32%" />
</p>
<p align="center">
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.55.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.59.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.16.53.png" width="32%" />
</p>
<p align="center">
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.16.57.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.17.01.png" width="32%" />
  <img src="assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.17.07.png" width="32%" />
</p>

[![pub package](https://img.shields.io/pub/v/auth_uae_pass.svg?label=pub&color=blue)](https://pub.dev/packages/auth_uae_pass)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform](https://img.shields.io/badge/platform-android%20|%20ios%20|%20web-blue.svg)

## 🌟 Key Features

- ⚡ **Zero-Setup Lazy Resumption**: Automatically handles deep link returns (even after app restarts) without complex `initState` logic.
- 🛡️ **Simplified API**: One-call `signInWithProfile` handles context, token exchange, and profile retrieval.
- 🎨 **120+ Button Variations**: Dark, Outline, and Logo-only variants with customizable borders, radii, and grayscale modes.
- 🌍 **Native RTL Support**: Built-in support for Arabic (LTR/RTL flipping) compliant with official design guidelines.
- 📱 **Intelligent App Detection**: Gracefully falls back to Web/Push flows if the UAE PASS app is not installed.
- 🛠️ **SOP Level Detection**: Automatically detects and returns the Success Of Person (SOP) level (Biometrics vs Password).

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
        <data android:scheme="your_app_scheme" />
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

### 1. Simple Authentication (All-in-One)

The simplest way to integrate is using `signInWithProfile`. This method handles the browser popup, token exchange, and profile fetching in a single call.

```dart
import 'package:auth_uae_pass/auth_uae_pass.dart';

final auth = AuthUaePass();

void _login(BuildContext context) async {
  final UaePassAuthData result = await auth.signInWithProfile(
    context,
    clientId: 'your_client_id',
    clientSecret: 'your_client_secret',
    redirectUri: 'your_app_scheme://',
    environment: UaePassEnvironment.staging, // Use .production for live
    uiLocale: 'en', // 'en' or 'ar'
  );

  if (result.isSuccess && result.profile != null) {
      print('Welcome, ${result.profile!.fullNameEN}');
      print('SOP Level: ${result.sopLevel}');
  }
}
```

### 2. Silent Logout

Background logout via `HeadlessInAppWebView`—no more blank/black screen flickers. This ensures the next login attempt starts with a clean session.

```dart
void _onLogout(BuildContext context) async {
  await auth.logout(
    context,
    environment: UaePassEnvironment.staging,
    redirectUri: 'your_app_scheme://',
  );
  print('Logged out from UAE PASS session');
}
```

### 3. User Profile Data

The `signInWithProfile` method returns a `UaePassProfile` object containing comprehensive user details.

| Field | Description |
| :--- | :--- |
| `uuid` | Unique user identifier |
| `fullNameEN / fullNameAR` | User's full name in English/Arabic |
| `email` | User's verified email address (if available) |
| `mobile` | User's verified mobile number |
| `nationalityEN / nationalityAR`| User's nationality |
| `gender` | User's gender |
| `idn` | Emirates ID Number |
| `unifiedId` | Unified ID (available with Visitor Integration) |

### 4. Custom Login Button

The package includes a highly customizable login button that adheres to official branding.

![Arabic Label Variations](assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.17.07.png)

```dart
UaePassLoginButton(
  onPressed: _login,
  language: UaePassButtonLanguage.english, // or .arabic
  labelType: UaePassButtonLabelType.continueWith,
  style: UaePassButtonStyle.outlineVariant(
    border: Colors.teal,
    radius: 14,
  ),
)
```

### 5. Logo Only Variations

For compact layouts or social login grids.

![Logo Matrix](assets/screenshots/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-04-15%20at%2022.11.59.png)

```dart
UaePassLoginButton(
  onPressed: _login,
  hideLabel: true,
  style: UaePassButtonStyle.darkVariant(
    background: Colors.black,
    radius: 100, // Makes it a circle
  ).copyWith(height: 48, width: 48),
)
```

---

## 🏁 Final Checks

| Check | Success Criteria |
| :--- | :--- |
| **Android LaunchMode** | Must be `singleTask` |
| **Redirect URI** | Must match the service provider portal dashboard EXACTLY |
| **Custom Scheme** | Same as Redirect URI scheme |
| **Environment** | Production credentials will NOT work in Staging environment |

---

## 💡 Advanced Scenarios

### Cold Start Resumption
If your app is terminated while the user is inside the UAE PASS native app, the deep link is saved. When the user returns and you call `signInWithProfile()` again, the package **instantly** detects the pending link and completes the login without showing a browser popup.

### Visitor Integration
To fetch `unifiedID` and `profileType`, the first authentication must use the extended visitor scope. You can enable this in the configuration:

```dart
final result = await auth.signInWithProfile(
  context,
  // ... other params
  visitorIntegrationFirstAuth: true,
);
```

### SOP Level Detection
The package automatically identifies the "Success Of Person" level used for authentication:
- `sop1`: Simple Password.
- `sop2`: Biometrics (Fingerprint/FaceID).
- `sop3`: Verified Face ID (Official Govt verification).

Check this via `result.sopLevel` in the `UaePassAuthData`.

---

## License

MIT License - see [LICENSE](LICENSE) for details.
