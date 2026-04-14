import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('staging endpoints match idshub STG URLs', () {
    expect(
      UaePassIdHubEndpoints.stagingUserInfo,
      'https://stg-id.uaepass.ae/idshub/userinfo',
    );
    expect(
      UaePassIdHubEndpoints.stagingIntrospect,
      'https://stg-id.uaepass.ae/idshub/introspect',
    );
  });

  test('production endpoints match idshub PROD URLs', () {
    expect(
      UaePassIdHubEndpoints.productionUserInfo,
      'https://id.uaepass.ae/idshub/userinfo',
    );
    expect(
      UaePassIdHubEndpoints.productionIntrospect,
      'https://id.uaepass.ae/idshub/introspect',
    );
  });

  test('selectors follow environment for all URL types', () {
    expect(
      UaePassIdHubEndpoints.authorizeUrl(UaePassEnvironment.staging),
      UaePassIdHubEndpoints.stagingAuthorize,
    );
    expect(
      UaePassIdHubEndpoints.authorizeUrl(UaePassEnvironment.production),
      UaePassIdHubEndpoints.productionAuthorize,
    );

    expect(
      UaePassIdHubEndpoints.tokenUrl(UaePassEnvironment.staging),
      UaePassIdHubEndpoints.stagingToken,
    );
    expect(
      UaePassIdHubEndpoints.tokenUrl(UaePassEnvironment.production),
      UaePassIdHubEndpoints.productionToken,
    );

    expect(
      UaePassIdHubEndpoints.userInfoUrl(UaePassEnvironment.staging),
      UaePassIdHubEndpoints.stagingUserInfo,
    );
    expect(
      UaePassIdHubEndpoints.userInfoUrl(UaePassEnvironment.production),
      UaePassIdHubEndpoints.productionUserInfo,
    );

    expect(
      UaePassIdHubEndpoints.introspectUrl(UaePassEnvironment.staging),
      UaePassIdHubEndpoints.stagingIntrospect,
    );
    expect(
      UaePassIdHubEndpoints.introspectUrl(UaePassEnvironment.production),
      UaePassIdHubEndpoints.productionIntrospect,
    );
  });
}
