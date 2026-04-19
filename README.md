# UAE PASS Flutter SDK: Official Digital Identity & Secure Login

[![pub package](https://img.shields.io/pub/v/auth_uae_pass.svg?label=pub&color=blue)](https://pub.dev/packages/auth_uae_pass)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat-square&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=flat-square&logo=ios&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=flat-square&logo=google-chrome&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The definitive, production-ready Flutter package for **UAE PASS**, the United Arab Emirates' official digital identity and smart login solution. Built for security, speed, and seamless developer experience (DX), this SDK simplifies **OAuth 2.0 / OIDC** integration, native app redirects, and **Emirates ID** profile retrieval with over 120+ customizable UI variations.

![Official UAE PASS Flutter SDK - Secure Authentication Showcase](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/uae_pass_sdk_showcase_1776589380172.png)


---

## 🌟 Why this UAE PASS SDK?

*   **⚡ Lazy Initialization**: Optimize app startup by initializing the SDK only when needed.
*   **📂 Full Profile Retrieval**: Get authenticated user data including Emirates ID (IDN), Email, and Full Name.
*   **🛡️ SOP Level Detection**: Automatically detect verification levels (`sop1`, `sop2`, `sop3`) for high-security applications.
*   **📱 Cold Start Support**: Robust deep link handling even if the app was killed in the background.
*   **🎨 120+ UI Variations**: Official-style buttons that fit any design system (Dark, Light, Outline, Labels).
*   **🌐 Web & Desktop Support**: Fully compatible with Flutter Web, providing a seamless browser-based OIDC flow.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Configure Native Platforms (CRITICAL)

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

### Step 2: Implementation (Lazy Pattern)

For apps with multiple login options (Google, Email, Phone), we recommend initializing the SDK **only** when the user selects UAE PASS. This keeps your startup lifecycle clean.

```dart
void _loginWithUaePass() async {
  // 1. Initialize locally (on-demand)
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

> [!TIP]
> **Cold Start Support**: Even if the SDK is initialized "late," it automatically checks for any pending resumption links from the OS (e.g., if the app was killed in the background), ensuring the user's flow is never broken.

---

### Step 3: Add the Official Button

The `UaePassLoginButton` follows official brand guidelines and supports a built-in loading state.

```dart
UaePassLoginButton(
  onPressed: _loginWithUaePass,
  isLoading: _myLoadingVariable, 
  language: UaePassButtonLanguage.english, // or .arabic
)
```

---

## 🎨 UI Components Gallery

The SDK provides over 120+ variations of the official UAE PASS button, catering to every design system.

### 🖤 Button Gallery

| Dark & Grey Variants | Outlined & Labels | Compact & Logo Only |
| :---: | :---: | :---: |
| [![UAE PASS Dark & Grey Button Variants](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_showcase_1776590628965.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_showcase_1776590628965.png) | [![UAE PASS Outlined & Label Button Variants](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_labels_showcase_1776590649780.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_labels_showcase_1776590649780.png) | [![UAE PASS Compact Logo-Only Buttons](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_logo_only_showcase_1776590675207.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_logo_only_showcase_1776590675207.png) |
| **Dark Black (English)** | **Outlined (English)** | **Logo Only (Minimal)** |
| [![UAE PASS English Dark Black Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_black_en.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_black_en.png) | [![UAE PASS English Outlined Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_en.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_en.png) | [![UAE PASS Logo-Only Minimal View](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_logo_only.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_logo_only.png) |
| **Dark Black (Arabic)** | **Outlined (Arabic)** | |
| [![UAE PASS Arabic Dark Black Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_black_ar.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_black_ar.png) | [![UAE PASS Arabic Outlined Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_ar.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_outline_ar.png) | |
| **Dark Grey (English)** | **Labels (English)** | |
| [![UAE PASS English Dark Grey Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_grey_en.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_grey_en.png) | [![UAE PASS English Login Label Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_labels_en.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_labels_en.png) | |
| **Dark Grey (Arabic)** | **Labels (Arabic)** | |
| [![UAE PASS Arabic Dark Grey Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_grey_ar.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_dark_grey_ar.png) | [![UAE PASS Arabic Login Label Variant](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_labels_ar.png)](https://raw.githubusercontent.com/ShithinCherathuparambil/auth_uae_pass/main/assets/screenshots/gallery_labels_ar.png) | |


---

## 🛠️ Key Concepts

### Success Of Person (SOP) Levels
The SDK automatically detects the verification level used by the user. Perfect for apps requiring high-trust biometrics for financial or government services.

| Level | Name | Description | Verification Method |
| :--- | :--- | :--- | :--- |
| `sop1` | Basic | User authenticated via password. | Password |
| `sop2` | Verified | User authenticated via Fingerprint/FaceID. | Biometrics |
| `sop3` | FaceID | Official government-verified face recognition. | Face Verification |

### Auth Result (UaePassAuthData)

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

#### User Tokens (UaePassUserToken)

Contains the OIDC tokens issued by UAE PASS.

| Field | Type | Description |
| :--- | :--- | :--- |
| `accessToken` | `String?` | The token used to access the userinfo endpoint and other protected resources. |
| `tokenType` | `String?` | Typically "Bearer". |
| `expiresIn` | `int?` | Duration in seconds until the access token expires. |
| `scope` | `String?` | The granted scopes for this session (e.g., `openid`, `profile`, `idn`). |
| `refreshToken` | `String?` | Used to obtain new access tokens when the current one expires. |
| `idToken` | `String?` | The JWT containing identity claims about the authenticated user. |

#### User Profile (UaePassUserProfile)

Contains detailed identity information about the user. All fields are optional depending on the scopes granted.

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

## 💎 Pro Features

### 1. Global Event Stream
You can provide an `onEvent` callback to track milestones like `webviewLoaded` or `tokenExchanged`. This is perfect for driving your own custom loading overlays or analytics.

```dart
final auth = AuthUaePass(
  config: myConfig,
  onEvent: (event) => MyAnalytics.log('UAE_PASS: $event'),
);
```

### 2. Dedicated SOP3 Upgrade
For apps requiring high security (FaceID/Biometrics) for sensitive actions, use the specialized upgrade method.

```dart
void _verifyFaceID() async {
  final auth = AuthUaePass(config: myConfig);
  final result = await auth.upgradeToSOP3(context);
}
```

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
