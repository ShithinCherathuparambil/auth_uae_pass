import 'uae_pass_models.dart';

/// Stub implementation of [openWebPopupPlaceholder] for non-web platforms.
dynamic openWebPopupPlaceholder() {
  return null;
}

/// Stub implementation of [openWebPopup] for non-web platforms.
Future<UaePassAuthResult> openWebPopup({
  required String initialUrl,
  required String redirectUri,
  dynamic popupWindow,
  List<String> cancelledUriPatterns = const <String>[],
  bool isLogoutFlow = false,
}) async {
  throw UnimplementedError('openWebPopup is only supported on the Web platform.');
}
