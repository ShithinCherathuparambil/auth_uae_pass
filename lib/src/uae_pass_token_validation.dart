import 'uae_pass_models.dart';

/// Reasons for denying access (SP validation guidelines; check in order).
abstract final class UaePassTokenValidationDenialCode {
  static const String tokenInactive = 'TOKEN_INACTIVE';
  static const String introspectUnavailable = 'INTROSPECT_UNAVAILABLE';
  static const String clientIdMismatch = 'CLIENT_ID_MISMATCH';
  static const String clientClaimsMismatch = 'CLIENT_CLAIMS_MISMATCH';
  static const String subMissing = 'SUB_MISSING';
  static const String scopeInsufficient = 'SCOPE_INSUFFICIENT';
}

/// Rules the SP applies after calling **Verify Access Token** (introspect).
///
/// See UAE PASS “Validation Decisions”: `active`, `client_id` / `client_claims`,
/// optional `sub`, optional `scope`.
class UaePassTokenValidationRules {
  const UaePassTokenValidationRules({
    this.expectedClientId,
    this.clientClaimMatchers = const <String, String>{},
    this.requiredScopes = const <String>[],
    this.requireSub = false,
  });

  /// If set, must equal [UaePassIntrospectResult.clientId] (e.g. `sdg_digivault`).
  final String? expectedClientId;

  /// Each key must exist under `client_claims` and the value must match exactly
  /// (after `toString()`), e.g. `name` → `SDG Digital Vault App`.
  final Map<String, String> clientClaimMatchers;

  /// Each URN must appear in the introspection `scope` string (space-separated).
  final List<String> requiredScopes;

  /// If true, `sub` must be non-empty (user identifier / uuid from introspect).
  final bool requireSub;
}

/// Outcome of applying [UaePassTokenValidationRules] to an introspect response.
class UaePassTokenValidationDecision {
  const UaePassTokenValidationDecision._({
    required this.accessAllowed,
    this.denialCode,
    this.denialDetail,
  });

  const UaePassTokenValidationDecision.allowed() : this._(accessAllowed: true);

  const UaePassTokenValidationDecision.denied({
    required String code,
    String? detail,
  }) : this._(accessAllowed: false, denialCode: code, denialDetail: detail);

  final bool accessAllowed;
  final String? denialCode;
  final String? denialDetail;
}

/// Applies SP validation in **chronological order** (mandatory first):
///
/// 1. Deny if introspect is null or `active != true`.
/// 2. If [UaePassTokenValidationRules.expectedClientId] is set, deny if `client_id` differs.
/// 3. If [UaePassTokenValidationRules.clientClaimMatchers] is non-empty, deny if any
///    key is missing or value mismatches in `client_claims`.
/// 4. If [UaePassTokenValidationRules.requireSub], deny if `sub` is null/empty.
/// 5. If [UaePassTokenValidationRules.requiredScopes] is non-empty, deny if `scope`
///    does not contain every required URN (space-separated list from introspect).
///
/// **Not covered here (by design):** calling **User information API** for Emirates ID etc.
/// — use [AuthUaePass.getUserProfile] after access is allowed.
UaePassTokenValidationDecision evaluateIntrospectAccess(
  UaePassIntrospectResult? introspect,
  UaePassTokenValidationRules rules,
) {
  if (introspect == null) {
    return const UaePassTokenValidationDecision.denied(
      code: UaePassTokenValidationDenialCode.introspectUnavailable,
      detail: 'No introspection response',
    );
  }

  if (!introspect.active) {
    return const UaePassTokenValidationDecision.denied(
      code: UaePassTokenValidationDenialCode.tokenInactive,
    );
  }

  if (rules.expectedClientId != null) {
    final String? cid = introspect.clientId;
    if (cid == null || cid != rules.expectedClientId) {
      return UaePassTokenValidationDecision.denied(
        code: UaePassTokenValidationDenialCode.clientIdMismatch,
        detail: 'expected=${rules.expectedClientId}, got=$cid',
      );
    }
  }

  if (rules.clientClaimMatchers.isNotEmpty) {
    final Map<String, dynamic>? cc = introspect.clientClaims;
    if (cc == null) {
      return const UaePassTokenValidationDecision.denied(
        code: UaePassTokenValidationDenialCode.clientClaimsMismatch,
        detail: 'client_claims missing',
      );
    }
    for (final MapEntry<String, String> e
        in rules.clientClaimMatchers.entries) {
      final dynamic v = cc[e.key];
      final String actual = v?.toString() ?? '';
      if (actual != e.value) {
        return UaePassTokenValidationDecision.denied(
          code: UaePassTokenValidationDenialCode.clientClaimsMismatch,
          detail: 'key=${e.key} expected=${e.value} got=$actual',
        );
      }
    }
  }

  if (rules.requireSub) {
    final String? sub = introspect.sub;
    if (sub == null || sub.trim().isEmpty) {
      return const UaePassTokenValidationDecision.denied(
        code: UaePassTokenValidationDenialCode.subMissing,
      );
    }
  }

  if (rules.requiredScopes.isNotEmpty) {
    if (!_scopeContainsAllUrns(introspect.scope, rules.requiredScopes)) {
      return UaePassTokenValidationDecision.denied(
        code: UaePassTokenValidationDenialCode.scopeInsufficient,
        detail: 'scope=${introspect.scope}',
      );
    }
  }

  return const UaePassTokenValidationDecision.allowed();
}

bool _scopeContainsAllUrns(
  String? scopeSpaceSeparated,
  List<String> requiredUrns,
) {
  if (requiredUrns.isEmpty) {
    return true;
  }
  if (scopeSpaceSeparated == null || scopeSpaceSeparated.trim().isEmpty) {
    return false;
  }
  final Set<String> tokens = scopeSpaceSeparated
      .split(RegExp(r'\s+'))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toSet();
  for (final String urn in requiredUrns) {
    if (!tokens.contains(urn)) {
      return false;
    }
  }
  return true;
}
