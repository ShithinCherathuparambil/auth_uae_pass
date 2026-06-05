import 'uae_pass_exceptions.dart';
import 'uae_pass_mobile_api.dart';

const String kUaePassDocumentsNotVerifiedErrorCode = 'DOCUMENTS_NOT_VERIFIED';

enum UaePassFlowStatus {
  loginSuccess,
  cancelled,
  logoutSuccess,
  error,
  unknown,
}

enum UaePassSopLevel { sop1, sop2, sop3, none }

enum UaePassErrorCode { documentsNotVerified, unknown }

UaePassErrorCode? parseUaePassErrorCode(String? errorCode) {
  if (errorCode == null || errorCode.trim().isEmpty) {
    return null;
  }

  switch (errorCode.toUpperCase()) {
    case kUaePassDocumentsNotVerifiedErrorCode:
      return UaePassErrorCode.documentsNotVerified;
    default:
      return UaePassErrorCode.unknown;
  }
}

class UaePassAuthRequest {
  const UaePassAuthRequest({
    required this.authorizationUrl,
    required this.redirectUri,
    this.cancelledUriPatterns = const <String>[],
    this.externalAppSchemes = const <String>[
      'uaepass',
      'uaepassqa',
      'uaepassdev',
      'uaepassstg',
    ],
    this.headers = const <String, String>{},
    this.userAgent,
    this.deepLinkScheme,

    /// When set with [applyMobileAcrValues], the package picks
    /// `acr_values=urn:digitalid:authentication:flow:mobileondevice` vs
    /// `urn:safelayer:tws:policies:authentication:level:low` using
    /// [isUaePassAppInstalled] (see UAE PASS mobile API).
    this.environment,
    this.applyMobileAcrValues = true,

    /// Path segment for `yourapp:///resume_authn?url=` (default matches docs).
    this.resumeAuthnPath = 'resume_authn',

    /// Rewrite `uaepass*://...?successURL=&failureURL=` and handle resume in webview.
    this.enableMobileDeepLinkRewrite = true,

    /// Visitor integration: first auth uses extended `scope` for unifiedId / profileType.
    this.visitorIntegrationFirstAuth = false,
  });

  final String authorizationUrl;
  final String redirectUri;
  final List<String> cancelledUriPatterns;
  final List<String> externalAppSchemes;
  final Map<String, String> headers;
  final String? userAgent;
  final String? deepLinkScheme;
  final UaePassEnvironment? environment;
  final bool applyMobileAcrValues;
  final String resumeAuthnPath;
  final bool enableMobileDeepLinkRewrite;
  final bool visitorIntegrationFirstAuth;
}

class UaePassLogoutRequest {
  const UaePassLogoutRequest({
    required this.logoutUrl,
    required this.redirectUri,
    this.headers = const <String, String>{},
    this.userAgent,
  });

  final String logoutUrl;
  final String redirectUri;
  final Map<String, String> headers;
  final String? userAgent;
}

class UaePassAuthResult {
  const UaePassAuthResult({
    required this.status,
    this.statusCode,
    this.errorCode,
    this.errorDescription,
    this.callbackUri,
    this.sopLevel = UaePassSopLevel.none,
    this.token,
    this.profile,
  });

  final UaePassFlowStatus status;
  final String? statusCode;
  final String? errorCode;
  final String? errorDescription;
  final Uri? callbackUri;
  final UaePassSopLevel sopLevel;
  final UaePassUserToken? token;
  final UaePassUserProfile? profile;

  bool get isSuccess =>
      status == UaePassFlowStatus.loginSuccess ||
      status == UaePassFlowStatus.logoutSuccess;

  UaePassErrorCode? get typedErrorCode => parseUaePassErrorCode(errorCode);

  /// Thrown an appropriate [UaePassException] if the status is not success.
  void throwIfError() {
    if (isSuccess) return;

    if (status == UaePassFlowStatus.cancelled) {
      throw UaePassCancelledException();
    }

    if (errorCode == kUaePassDocumentsNotVerifiedErrorCode) {
      throw UaePassDocumentsNotVerifiedException(message: errorDescription);
    }

    throw UaePassException(
      errorDescription ?? 'Authentication flow failed with status: $status',
      code: errorCode,
    );
  }
}

/// Consolidated result of a full UAE PASS authentication flow (Status + Token + Profile).
class UaePassAuthData {
  const UaePassAuthData({
    required this.status,
    this.token,
    this.profile,
    this.errorCode,
    this.errorDescription,
    this.statusCode,
    this.sopLevel = UaePassSopLevel.none,
  });

  final UaePassFlowStatus status;
  final UaePassUserToken? token;
  final UaePassUserProfile? profile;
  final String? errorCode;
  final String? errorDescription;
  final String? statusCode;
  final UaePassSopLevel sopLevel;

  bool get isSuccess => status == UaePassFlowStatus.loginSuccess;

  UaePassErrorCode? get typedErrorCode => parseUaePassErrorCode(errorCode);

  /// Thrown an appropriate [UaePassException] if the status is not success.
  void throwIfError() {
    if (isSuccess) return;

    if (status == UaePassFlowStatus.cancelled) {
      throw UaePassCancelledException();
    }

    if (errorCode == kUaePassDocumentsNotVerifiedErrorCode) {
      throw UaePassDocumentsNotVerifiedException(message: errorDescription);
    }

    throw UaePassException(
      errorDescription ?? 'Authentication flow failed with status: $status',
      code: errorCode,
    );
  }
}

class UaePassAccessTokenRequest {
  const UaePassAccessTokenRequest({
    required this.tokenUrl,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.code,
    this.headers = const <String, String>{},
  });

  final String tokenUrl;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String code;
  final Map<String, String> headers;
}

class UaePassUserProfileRequest {
  const UaePassUserProfileRequest({
    required this.userInfoUrl,
    required this.accessToken,
    this.headers = const <String, String>{},
  });

  final String userInfoUrl;
  final String accessToken;
  final Map<String, String> headers;
}

/// Token introspection ([RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662)) via UAE PASS idhub `introspect`.
///
/// Uses **Basic authentication** (`Authorization: Basic base64(client_id:client_secret)`)
/// and form body `token=<access token to verify>`.
class UaePassIntrospectRequest {
  const UaePassIntrospectRequest({
    required this.introspectUrl,
    required this.clientId,
    required this.clientSecret,
    required this.token,
    this.headers = const <String, String>{},
  });

  final String introspectUrl;
  final String clientId;
  final String clientSecret;

  /// Access token issued to the client app (to verify).
  final String token;
  final Map<String, String> headers;
}

/// Parsed introspection response (`active`, claims, metadata).
class UaePassIntrospectResult {
  const UaePassIntrospectResult({
    required this.active,
    this.tokenType,
    this.scope,
    this.exp,
    this.iat,
    this.iss,
    this.clientId,
    this.clientClaims,
    this.sub,
    this.userClaims,
    this.timesVerified,
    this.raw = const <String, dynamic>{},
  });

  factory UaePassIntrospectResult.fromJson(Map<String, dynamic> json) {
    final dynamic activeRaw = json['active'];
    final bool active = activeRaw is bool
        ? activeRaw
        : activeRaw?.toString().toLowerCase() == 'true';

    Map<String, dynamic>? mapOrNull(dynamic v) {
      if (v is Map<String, dynamic>) {
        return v;
      }
      if (v is Map) {
        return v.map((dynamic k, dynamic val) => MapEntry(k.toString(), val));
      }
      return null;
    }

    return UaePassIntrospectResult(
      active: active,
      tokenType: json['token_type']?.toString(),
      scope: json['scope']?.toString(),
      exp: _parseEpochSeconds(json['exp']),
      iat: _parseEpochSeconds(json['iat']),
      iss: json['iss']?.toString(),
      clientId: json['client_id']?.toString(),
      clientClaims: mapOrNull(json['client_claims']),
      sub: json['sub']?.toString(),
      userClaims: mapOrNull(json['user_claims']),
      timesVerified: int.tryParse(json['times_verified']?.toString() ?? ''),
      raw: Map<String, dynamic>.from(json),
    );
  }

  static int? _parseEpochSeconds(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  final bool active;
  final String? tokenType;
  final String? scope;
  final int? exp;
  final int? iat;
  final String? iss;
  final String? clientId;
  final Map<String, dynamic>? clientClaims;
  final String? sub;
  final Map<String, dynamic>? userClaims;
  final int? timesVerified;
  final Map<String, dynamic> raw;

  /// Returns true if the token is active and has not yet expired.
  bool get isValid {
    if (!active) return false;
    if (exp == null) return true; // If no expiry is present, we rely on active flag
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp! > nowSeconds;
  }
}

class UaePassUserToken {
  const UaePassUserToken({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.scope,
    this.refreshToken,
    this.idToken,
    this.raw = const <String, dynamic>{},
  });

  factory UaePassUserToken.fromJson(Map<String, dynamic> json) {
    return UaePassUserToken(
      accessToken: json['access_token']?.toString(),
      tokenType: json['token_type']?.toString(),
      expiresIn: int.tryParse(json['expires_in']?.toString() ?? ''),
      scope: json['scope']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
      idToken: json['id_token']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;
  final String? scope;
  final String? refreshToken;
  final String? idToken;
  final Map<String, dynamic> raw;
}

class UaePassUserProfile {
  const UaePassUserProfile({
    this.sub,
    this.fullNameAR,
    this.gender,
    this.mobile,
    this.lastnameEN,
    this.fullNameEN,
    this.uuid,
    this.lastnameAR,
    this.idn,
    this.nationalityEN,
    this.firstnameEN,
    this.userType,
    this.nationalityAR,
    this.firstnameAR,
    this.email,
    this.acr,
    this.amr,
    this.spuuid,
    this.idType,
    this.titleEN,
    this.titleAR,
    this.profileType,
    this.unifiedId,
    this.raw = const <String, dynamic>{},
  });

  factory UaePassUserProfile.fromJson(Map<String, dynamic> json) {
    List<String>? parseAmr(dynamic v) {
      if (v is! List) {
        return null;
      }
      return v.map((dynamic e) => e.toString()).toList();
    }

    return UaePassUserProfile(
      sub: json['sub']?.toString(),
      fullNameAR: json['fullnameAR']?.toString(),
      gender: json['gender']?.toString(),
      mobile: json['mobile']?.toString(),
      lastnameEN: json['lastnameEN']?.toString(),
      fullNameEN: json['fullnameEN']?.toString(),
      uuid: json['uuid']?.toString(),
      lastnameAR: json['lastnameAR']?.toString(),
      idn: json['idn']?.toString(),
      nationalityEN: json['nationalityEN']?.toString(),
      firstnameEN: json['firstnameEN']?.toString(),
      userType: json['userType']?.toString(),
      nationalityAR: json['nationalityAR']?.toString(),
      firstnameAR: json['firstnameAR']?.toString(),
      email: json['email']?.toString(),
      acr: json['acr']?.toString(),
      amr: parseAmr(json['amr']),
      spuuid: json['spuuid']?.toString(),
      idType: json['idType']?.toString(),
      titleEN: json['titleEN']?.toString(),
      titleAR: json['titleAR']?.toString(),
      profileType: json['profileType']?.toString(),
      unifiedId: json['unifiedId']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String? sub;
  final String? fullNameAR;
  final String? gender;
  final String? mobile;
  final String? lastnameEN;
  final String? fullNameEN;
  final String? uuid;
  final String? lastnameAR;
  final String? idn;
  final String? nationalityEN;
  final String? firstnameEN;
  final String? userType;
  final String? nationalityAR;
  final String? firstnameAR;
  final String? email;

  /// Authentication Context Class Reference (e.g. authentication assurance level).
  final String? acr;

  /// Authentication methods references (AMR), as returned by userinfo.
  final List<String>? amr;
  final String? spuuid;
  final String? idType;
  final String? titleEN;
  final String? titleAR;
  final String? profileType;
  final String? unifiedId;

  /// Full JSON body from `GET /userinfo` for any additional claims.
  final Map<String, dynamic> raw;
}

class UaePassCallbackParser {
  const UaePassCallbackParser._();

  static UaePassAuthResult? parse({
    required Uri callbackUri,
    required Uri redirectUri,
    required List<String> cancelledUriPatterns,
    required bool isLogoutFlow,
    bool skipHostCheck = false,
  }) {
    final urlValue = callbackUri.toString().toLowerCase();

    for (final pattern in cancelledUriPatterns) {
      if (urlValue.contains(pattern.toLowerCase())) {
        return UaePassAuthResult(
          status: UaePassFlowStatus.cancelled,
          statusCode: 'USER_CANCELLED',
          callbackUri: callbackUri,
        );
      }
    }

    if (!skipHostCheck) {
      if (callbackUri.scheme != redirectUri.scheme ||
          callbackUri.host != redirectUri.host) {
        return null;
      }
    }

    if (isLogoutFlow) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.logoutSuccess,
        statusCode: 'LOGOUT_SUCCESS',
        callbackUri: callbackUri,
      );
    }

    final fields = <String?>[
      callbackUri.queryParameters['status'],
      callbackUri.queryParameters['status_code'],
      callbackUri.queryParameters['sop'],
      callbackUri.queryParameters['acr'],
      callbackUri.queryParameters['code'],
      callbackUri.queryParameters['error'],
      callbackUri.queryParameters['error_description'],
      callbackUri.fragment,
    ];

    final merged = fields.whereType<String>().join('|').toUpperCase();

    if (merged.contains('SOP1')) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.loginSuccess,
        statusCode: 'SOP1',
        sopLevel: UaePassSopLevel.sop1,
        callbackUri: callbackUri,
      );
    }
    if (merged.contains('SOP2')) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.loginSuccess,
        statusCode: 'SOP2',
        sopLevel: UaePassSopLevel.sop2,
        callbackUri: callbackUri,
      );
    }
    if (merged.contains('SOP3')) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.loginSuccess,
        statusCode: 'SOP3',
        sopLevel: UaePassSopLevel.sop3,
        callbackUri: callbackUri,
      );
    }
    if (merged.contains('CANCEL') ||
        merged.contains('CANCELLEDONAPP') ||
        merged.contains('ACCESS_DENIED') ||
        merged.contains('UAEPASS-CANCEL')) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.cancelled,
        statusCode: 'USER_CANCELLED',
        callbackUri: callbackUri,
      );
    }
    if (merged.contains('ERROR') ||
        callbackUri.queryParameters.containsKey('error') ||
        callbackUri.queryParameters.containsKey('error_code')) {
      final rawErrorCode = callbackUri.queryParameters['error_code'];
      final rawErrorDescription =
          callbackUri.queryParameters['error_description'] ??
          callbackUri.queryParameters['error'];
      final resolvedErrorCode =
          _isDocumentsNotVerifiedError(rawErrorCode, rawErrorDescription)
          ? kUaePassDocumentsNotVerifiedErrorCode
          : rawErrorCode;

      return UaePassAuthResult(
        status: UaePassFlowStatus.error,
        errorCode: resolvedErrorCode,
        errorDescription: rawErrorDescription,
        callbackUri: callbackUri,
      );
    }

    if (callbackUri.queryParameters.containsKey('code') ||
        callbackUri.fragment.contains('code=')) {
      return UaePassAuthResult(
        status: UaePassFlowStatus.loginSuccess,
        statusCode: 'LOGIN_SUCCESS',
        callbackUri: callbackUri,
      );
    }

    return UaePassAuthResult(
      status: UaePassFlowStatus.unknown,
      statusCode: callbackUri.queryParameters['status_code'],
      callbackUri: callbackUri,
    );
  }

  static bool _isDocumentsNotVerifiedError(
    String? errorCode,
    String? errorDescription,
  ) {
    final combined = '${errorCode ?? ''}|${errorDescription ?? ''}'
        .toLowerCase();
    return combined.contains('documents are not verified') ||
        combined.contains('document not verified') ||
        combined.contains('documents_not_verified') ||
        combined.contains('document_not_verified');
  }
}
