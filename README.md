# UAE PASS Flutter SDK: Official Digital Identity & Secure Login

[![pub package](https://img.shields.io/pub/v/auth_uae_pass.svg?label=pub&color=blue)](https://pub.dev/packages/auth_uae_pass)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-square&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=flat-square&logo=ios&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=flat-square&logo=google-chrome&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The definitive, production-ready Flutter package for **UAE PASS**, the United Arab Emirates' official digital identity and smart login solution. Built for security, speed, and seamless developer experience (DX), this SDK simplifies **OAuth 2.0 / OIDC** integration, native app redirects, and **Emirates ID** profile retrieval.

---

## 🎥 Interactive Showcase

<table>
  <tr>
    <td align="center"><b>Authentication Flow</b></td>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/gif/uae_pass_login.gif" width="320" alt="UAE PASS Authentication Flow"/></td>

  </tr>
</table>

---

## 🌟 Why this UAE PASS SDK?

*   **⚡ Lazy Initialization**: Optimize app startup by initializing the SDK only when needed, or use the global singleton pattern.
*   **📂 Full Profile Retrieval**: Get authenticated user data including Emirates ID (IDN), Email, Full Name, and Gender.
*   **🛡️ SOP Level Detection**: Automatically detect verification levels (`sop1`, `sop2`, `sop3`) for high-security applications.
*   **📱 App Presence Probing**: Easily check if the UAE PASS application is installed on Android or iOS.
*   **🔍 Token Introspection & Validation**: Fully inspect token status and apply custom Service Provider validation policies.
*   **🧹 Silent Session Clearing**: Complete support for clearing web view cookies and silent logging out.
*   **📱 Cold Start Support**: Robust deep link handling even if the app was killed in the background.
*   **🌐 Web & Desktop Support**: Fully compatible with Flutter Web, providing a seamless browser-based OIDC flow.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Configure Native Platforms

To handle the "Coming back from UAE PASS" flow correctly, you **must** configure your native platforms to listen for your redirect URI.

#### 🤖 Android (`AndroidManifest.xml`)
Copy-paste this structure into your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application ... >
        <activity
            android:name=".MainActivity"
            android:exported="true"
            <!-- 1. CRITICAL: Change launchMode to singleTask -->
            android:launchMode="singleTask" 
            ...>
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- 2. ADD THIS: UAE PASS Custom Scheme Intent Filter -->
            <!-- Use your deepLinkScheme (e.g. ae.myapp.com) as the scheme -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="ae.myapp.com" android:host="resume_authn" />
            </intent-filter>
        </activity>
    </application>

    <!-- 3. ADD THIS: Package Visibility (Required for Android 11+) -->
    <queries>
        <package android:name="ae.uaepass.mainapp" />
        <package android:name="ae.uaepass.mainapp.stg" />
        <package android:name="ae.uaepass.mainapp.qa" />
    </queries>
</manifest>
```

#### 🍎 iOS (`Info.plist`)
Copy-paste this into your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ae.myapp.com</string>
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

### Step 2: Choose Your Initialization Pattern

The SDK supports two patterns for managing instance lifecycles based on your app's architecture.

#### Pattern A: On-Demand / Lazy Initialization (Recommended for multi-login screens)
If your app supports multiple login methods (Google, Apple, Phone, UAE PASS), initialize the SDK **only** when the user selects UAE PASS.

```dart
void _loginWithUaePass() async {
  // 1. Initialize locally on-demand
  final auth = AuthUaePass(
    config: const UaePassConfig(
      clientId: "your_client_id",
      clientSecret: "your_client_secret",
      redirectUri: "https://your-registered-callback.com", 
      environment: UaePassEnvironment.staging,
      deepLinkScheme: "ae.myapp.com",
    ),
    onEvent: (event) {
      if (event == UaePassEvent.authStarted) HapticFeedback.mediumImpact();
    },
  );

  // 2. Start the flow
  final result = await auth.signInWithProfile(context);

  if (result.isSuccess) {
    print("Welcome, ${result.profile?.fullNameEN}");
  }
}
```

#### Pattern B: Global Singleton Pattern
If UAE PASS is the primary auth provider, initialize the SDK at startup (e.g., in `main()`) and retrieve the instance anywhere.

```dart
// 1. In main.dart or your initialization service
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  AuthUaePass.initialize(
    const UaePassConfig(
      clientId: "your_client_id",
      clientSecret: "your_client_secret",
      redirectUri: "https://your-registered-callback.com", 
      environment: UaePassEnvironment.staging,
      deepLinkScheme: "ae.myapp.com",
    ),
    onEvent: (event) => print("UAE PASS Event: $event"),
  );
  
  runApp(const MyApp());
}

// 2. In your login page widget
void _login() async {
  final result = await AuthUaePass.instance.signInWithProfile(context);
  if (result.isSuccess) {
    print("Success: ${result.profile?.idn}");
  }
}
```

---

### Step 3: Trigger the Authentication

Trigger the authentication flow using standard Flutter buttons:

```dart
ElevatedButton(
  onPressed: _loginWithUaePass,
  child: const Text('Login with UAE PASS'),
)
```

---

## 🛠️ Advanced Features & Guides

### 1. App Presence Probing
Checking if the UAE PASS application is installed on the user's device allows you to customize the user interface or display direct help messages.

```dart
final auth = AuthUaePass.instance;
final bool isInstalled = await auth.isAppInstalled();

if (isInstalled) {
  print("UAE PASS App is installed on this device!");
} else {
  print("UAE PASS App is not installed. Will fallback to Web/Push confirmation flow.");
}
```

### 2. Silent Logout / Session Clearing
To perform a complete logout and clear browser-cached cookies (to ensure a fresh login experience next time), trigger a silent background logout:

```dart
final auth = AuthUaePass.instance;
final result = await auth.logout(context);

if (result.isSuccess) {
  print("Silent logout complete and session cookies cleared.");
}
```

### 3. Token Introspection & SP Validation Rules
Check user token validity on the server side or locally via OIDC token introspection (RFC 7662), and apply Service Provider validation decisions.

```dart
final auth = AuthUaePass.instance;

// 1. Send token info request to introspect
final introspectResult = await auth.introspectToken(
  request: UaePassIntrospectRequest(
    introspectUrl: UaePassIdHubEndpoints.introspectUrl(UaePassEnvironment.staging),
    clientId: "your_client_id",
    clientSecret: "your_client_secret",
    token: "access_token_to_verify",
  ),
);

if (introspectResult != null && introspectResult.isValid) {
  // 2. Validate against SP guidelines (Client ID, Required Scopes, and active flag)
  final decision = evaluateIntrospectAccess(
    introspectResult,
    const UaePassTokenValidationRules(
      expectedClientId: "your_client_id",
      requireSub: true,
      requiredScopes: ["urn:uae:digitalid:profile:general"],
    ),
  );

  if (decision.accessAllowed) {
    print("Access allowed: Token is valid and matches SP policies.");
  } else {
    print("Access denied: ${decision.denialCode} - ${decision.denialDetail}");
  }
}
```

### 4. Global Event Stream
Listen to critical flow checkpoints to feed custom analytics or show loading overlays.

```dart
final auth = AuthUaePass(
  config: myConfig,
  onEvent: (event) {
    switch (event) {
      case UaePassEvent.authStarted:
        _showLoadingOverlay();
        break;
      case UaePassEvent.webviewLoaded:
        _hideLoadingOverlay();
        break;
      case UaePassEvent.loginSuccess:
        _celebrate();
        break;
      default:
        break;
    }
  },
);
```

### 5. Dedicated SOP3 Upgrade
If your app needs biometric verification (FaceID) for high-trust operations (e.g. transfers, official document signs), launch the specialized SOP3 upgrade:

```dart
void _verifyFaceID() async {
  final auth = AuthUaePass.instance;
  final result = await auth.upgradeToSOP3(context);
  
  if (result.isSuccess && result.sopLevel == UaePassSopLevel.sop3) {
    print("User authenticated with highest verification assurance (SOP3).");
  }
}
```

---

## 🛠️ Key Concepts

### Success Of Person (SOP) Levels
The SDK automatically detects the verification level used by the user. Perfect for apps requiring high-trust biometrics for financial or government services.

| Level | Name | Description | Verification Method |
| :--- | :--- | :--- | :--- |
| `sop1` | Basic | User authenticated via password. | Password |
| `sop2` | Verified | User authenticated via Fingerprint/FaceID. | Biometrics |
| `sop3` | FaceID | Official government-verified face recognition. | Face Verification |

---

## 📂 API Reference

### Auth Result (`UaePassAuthData`)

When you call `signInWithProfile` or `upgradeToSOP3`, you receive a `UaePassAuthData` object containing the flow results.

| Field | Type | Description |
| :--- | :--- | :--- |
| `status` | `UaePassFlowStatus` | The overall status of the authentication flow (`loginSuccess`, `cancelled`, `error`, `unknown`). |
| `token` | `UaePassUserToken?` | OIDC tokens (Access, ID, Refresh) and expiry details. Available on success. |
| `profile` | `UaePassUserProfile?` | Decoded user profile details like Emirates ID, Full Name, Email, and Mobile. Available on success. |
| `errorCode` | `String?` | Machine-readable error code if the status is `error` (e.g., `DOCUMENTS_NOT_VERIFIED`). |
| `errorDescription` | `String?` | Human-readable error message explaining why the flow failed. |
| `statusCode` | `String?` | The raw status code returned from the UAE PASS callback (e.g., `SOP1`, `USER_CANCELLED`). |
| `sopLevel` | `UaePassSopLevel` | The detected Success Of Person level for the current session (`sop1`, `sop2`, `sop3`). |

### User Tokens (`UaePassUserToken`)

| Field | Type | Description |
| :--- | :--- | :--- |
| `accessToken` | `String?` | The token used to access the userinfo endpoint and other protected resources. |
| `tokenType` | `String?` | Typically "Bearer". |
| `expiresIn` | `int?` | Duration in seconds until the access token expires. |
| `scope` | `String?` | The granted scopes for this session (e.g., `openid`, `profile`, `idn`). |
| `refreshToken` | `String?` | Used to obtain new access tokens when the current one expires. |
| `idToken` | `String?` | The JWT containing identity claims about the authenticated user. |

### User Profile (`UaePassUserProfile`)

Identity information about the user. Fields are populated depending on the scopes granted.

| Field | Type | Description |
| :--- | :--- | :--- |
| **`idn`** | `String?` | **Emirates ID Number** (The most critical field for local apps). |
| `fullNameEN` | `String?` | User's full name in English. |
| `fullNameAR` | `String?` | User's full name in Arabic. |
| `firstnameEN` | `String?` | First name in English. |
| `lastnameEN` | `String?` | Last name in English. |
| `email` | `String?` | Registered email address. |
| `mobile` | `String?` | Registered mobile number. |
| `gender` | `String?` | User's gender. |
| `nationalityEN`| `String?` | Nationality in English. |
| `userType` | `String?` | e.g., citizen, resident, or visitor. |
| `acr` | `String?` | Authentication Context Class Reference (shows verification level). |
| `amr` | `List<String>?`| Authentication Methods References. |
| `uuid` | `String?` | Unique persistent identifier for the user. |
| `spuuid` | `String?` | Service Provider specific UUID. |
| `unifiedId` | `String?` | Unified ID (useful for visitor/profile mapping). |

---

## ⚠️ Common Pitfalls

### 1. The "Triple Slash" Intent Error
Ensure your native configuration matches your `deepLinkScheme` exactly. The SDK is optimized to avoid URL parsing errors, but any mismatch in the `AndroidManifest.xml` host will cause the redirect to fail.

### 2. HTTPS vs Custom Schemes
Your `redirectUri` **must** be the HTTPS URL registered in the UAE PASS portal. However, for mobile redirection, you should use a `deepLinkScheme` (e.g. `ae.myapp.com`) to ensure the response is captured by your app and not the external browser.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Developed by **Shithin Cp** ([shithincp@gmail.com](mailto:shithincp@gmail.com))
