# auth_uae_pass

Flutter package for UAE PASS authentication using `InAppWebView`, with:

- Full-screen auth webview flow
- SOP status code handling (`SOP1`, `SOP2`, `SOP3`)
- Error code handling when auth fails
- Explicit user-cancelled status
- Logout flow
- UAE PASS login button widget (English/Arabic defaults + customization)

## Installation

```yaml
dependencies:
  auth_uae_pass:
    path: ../auth_uae_pass
```

## Mobile App Deep Link Setup (Required)

Add the following in your host app to allow detection/opening of UAE PASS apps.

### Android (`AndroidManifest.xml`)

Under the `<queries>` section:

```xml
<queries>
  <!-- UAE Pass app packages for deep linking -->
  <package android:name="ae.uaepass.mainapp" />
  <package android:name="ae.uaepass.mainapp.qa" />
  <package android:name="ae.uaepass.mainapp.stg" />
</queries>
```

### iOS (`Info.plist`)

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>mailto</string>
  <string>tel</string>
  <string>uaepass</string>
  <string>uaepassqa</string>
  <string>uaepassdev</string>
  <string>uaepassstg</string>
</array>
```

`UaePassAuthRequest` defaults already include these external schemes:
`uaepass`, `uaepassqa`, `uaepassdev`, `uaepassstg`.

## UAE PASS mobile API (official)

This package follows the [mobile application authentication API](https://docs.uaepass.ae/feature-guides/authentication/mobile-application/guide/api):

- **App installed:** uses `acr_values=urn:digitalid:authentication:flow:mobileondevice` (when you pass `environment` and `applyMobileAcrValues: true`).
- **App not installed:** uses `acr_values=urn:safelayer:tws:policies:authentication:level:low` (identifier + login in embedded webview; user confirms on another device via push; authorization `code` returns in the webview — same as web integration for token/userinfo).
- **Webview:** monitors `uaepass` / `uaepassstg` (and other env) schemes, rewrites `successURL` / `failureURL` to your SP resume URL (`yourapp:///resume_authn?url=...` by default), loads the rewritten link **in the same webview**, then opens the UAE PASS app when the hub returns the deep link.
- **Resume:** when the app calls back with `yourapp:///resume_authn?url=<stored>`, the webview loads that URL so you receive the authorization `code` on your registered `redirect_uri`.

Pass `environment: UaePassEnvironment.staging` or `.production` so the package can probe `uaepassstg://` vs `uaepass://` and set the correct `acr_values`. Ensure your `redirectUri` matches the scheme you registered with UAE PASS.

### Visitor integration (first authentication)

For **visitor** integration, the first authentication call should request **unifiedId** and **profileType** via `scope`. Use `visitorIntegrationFirstAuth: true` on `UaePassAuthRequest` (sets `scope` to `kUaePassVisitorFirstAuthScope`), or build the authorize URL yourself with:

`urn:uae:digitalid:profile:general urn:uae:digitalid:profile:general:profileType urn:uae:digitalid:profile:general:unifiedId`

Then call `getAccessToken` and `getUserProfile` as in web integration.

```dart
UaePassAuthRequest(
  authorizationUrl: 'https://stg-id.uaepass.ae/idshub/authorize?...',
  redirectUri: 'myapp://callback',
  environment: UaePassEnvironment.staging,
  visitorIntegrationFirstAuth: true,
)
```

## Idhub endpoints (STG / PROD)

OAuth2 integration uses the standard idhub paths. Official reference:

| Environment | User Info | Introspect |
|-------------|-----------|------------|
| **Staging** | `https://stg-id.uaepass.ae/idshub/userinfo` | `https://stg-id.uaepass.ae/idshub/introspect` |
| **Production** | `https://id.uaepass.ae/idshub/userinfo` | `https://id.uaepass.ae/idshub/introspect` |

Use **`UaePassIdHubEndpoints`** for these URLs (and for `/authorize` + `/token` used in the authorization code flow). Introspect is for token introspection (RFC 7662); exchanging an authorization `code` for tokens uses **`/token`**, not `/introspect`.

```dart
UaePassIdHubEndpoints.tokenUrl(UaePassEnvironment.staging);
UaePassIdHubEndpoints.userInfoUrl(UaePassEnvironment.staging);
UaePassIdHubEndpoints.introspectUrl(UaePassEnvironment.production);
```

### Token introspection (resource server / SP)

To verify a client app access token before trusting it, call **POST** `.../introspect` with **Basic** authentication (`base64(client_id:client_secret)`), `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`, and form field `token=<access_token>`. Use `AuthUaePass.introspectToken` and `UaePassIntrospectRequest`:

```dart
final auth = const AuthUaePass();
final UaePassIntrospectResult? verified = await auth.introspectToken(
  request: UaePassIntrospectRequest(
    introspectUrl: UaePassIdHubEndpoints.introspectUrl(UaePassEnvironment.staging),
    clientId: 'YOUR_SP_CLIENT_ID',
    clientSecret: 'YOUR_SP_CLIENT_SECRET',
    token: accessTokenFromClient,
  ),
);
if (verified?.active == true) {
  // token valid; inspect verified.sub, verified.userClaims, etc.
}
```

### Validation decisions (SP)

Apply checks in order after **Verify Access Token** (introspect), then optionally **User information**:

1. **Mandatory:** if `active == false`, deny access.
2. **Mandatory** (when you bind tokens to a client): ensure `client_id` and/or `client_claims` match your SP expectations (e.g. SDG Digital Vault: `client_id` `sdg_digivault`, `client_claims.name`, etc.).
3. **Optional (recommended):** use `sub` from introspect as the authenticated user identifier when needed.
4. **Optional (recommended):** call **User information API** for attributes (e.g. Emirates ID) after the token is allowed.
5. **Optional:** ensure the token’s `scope` includes the URNs your resource requires.

Use `evaluateIntrospectAccess` with `UaePassTokenValidationRules`:

```dart
final decision = evaluateIntrospectAccess(
  verified,
  const UaePassTokenValidationRules(
    expectedClientId: 'sdg_digivault',
    clientClaimMatchers: <String, String>{
      'name': 'SDG Digital Vault App',
    },
    requireSub: true,
    requiredScopes: <String>['urn:uae:digitalid:profile:general'],
  ),
);
if (!decision.accessAllowed) {
  // decision.denialCode — e.g. TOKEN_INACTIVE, CLIENT_ID_MISMATCH, SCOPE_INSUFFICIENT
}
```

### User info (authenticated user)

After validating the access token (e.g. via introspect), call **GET** `.../idshub/userinfo` with **`Authorization: Bearer <access_token>`** to load the authenticated user claims (`sub`, `acr`, `mobile`, `amr`, name fields, etc.). Use `getUserProfile` with `UaePassIdHubEndpoints.userInfoUrl(env)`:

```dart
final profile = await auth.getUserProfile(
  request: UaePassUserProfileRequest(
    userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(env),
    accessToken: accessToken,
  ),
);
// profile?.acr, profile?.amr, profile?.mobile, profile?.raw (full JSON)
```

## Usage

```dart
import 'package:auth_uae_pass/auth_uae_pass.dart';
```

```dart
final auth = const AuthUaePass();
const UaePassEnvironment env = UaePassEnvironment.staging;

final authCode = await auth.signIn(
  context,
  request: UaePassAuthRequest(
    authorizationUrl: '${UaePassIdHubEndpoints.authorizeUrl(env)}?response_type=code&client_id=...',
    redirectUri: 'myapp://callback',
    cancelledUriPatterns: const <String>['cancel'],
    environment: env,
  ),
);

if (authCode != null) {
  final token = await auth.getAccessToken(
    request: UaePassAccessTokenRequest(
      tokenUrl: UaePassIdHubEndpoints.tokenUrl(env),
      clientId: 'YOUR_CLIENT_ID',
      clientSecret: 'YOUR_CLIENT_SECRET',
      redirectUri: 'myapp://callback',
      code: authCode,
    ),
  );

  final accessToken = token?.accessToken;
  if (accessToken != null) {
    final profile = await auth.getUserProfile(
      request: UaePassUserProfileRequest(
        userInfoUrl: UaePassIdHubEndpoints.userInfoUrl(env),
        accessToken: accessToken,
      ),
    );
    // profile is UaePassUserProfile
  }
}
```

### Logout

```dart
await auth.logout(
  context,
  request: const UaePassLogoutRequest(
    logoutUrl: 'https://stg-id.uaepass.ae/idshub/logout',
    redirectUri: 'myapp://callback',
  ),
);
```

### UAE PASS Login Button

```dart
UaePassLoginButton(
  onPressed: () {},
)
```

Arabic sign in default:

```dart
UaePassLoginButton(
  language: UaePassButtonLanguage.arabic,
  onPressed: () {},
)
```

English sign up:

```dart
UaePassLoginButton(
  labelType: UaePassButtonLabelType.signUp,
  onPressed: () {},
)
```

Arabic sign up:

```dart
UaePassLoginButton(
  language: UaePassButtonLanguage.arabic,
  labelType: UaePassButtonLabelType.signUp,
  onPressed: () {},
)
```

Customized style:

```dart
UaePassLoginButton(
  onPressed: () {},
  customLabel: 'Sign in with UAE PASS',
  style: const UaePassButtonStyle(
    fontSize: 16,
    borderRadius: 12,
  ),
)
```

Built-in style variants:

```dart
UaePassLoginButton(
  onPressed: () {},
  style: UaePassButtonStyle.white(),
)

UaePassLoginButton(
  onPressed: () {},
  style: UaePassButtonStyle.whiteOutline(),
)

UaePassLoginButton(
  onPressed: () {},
  style: UaePassButtonStyle.black(),
)
```
