import 'package:flutter/material.dart';

import 'uae_pass_models.dart';

class UaePassLoginButton extends StatelessWidget {
  const UaePassLoginButton({
    super.key,
    required this.onPressed,
    this.language = UaePassButtonLanguage.english,
    this.labelType = UaePassButtonLabelType.signIn,
    this.customLabel,
    this.style = const UaePassButtonStyle(),
    this.leading,
  });

  final VoidCallback onPressed;
  final UaePassButtonLanguage language;
  final UaePassButtonLabelType labelType;
  final String? customLabel;
  final UaePassButtonStyle style;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final textDirection = language == UaePassButtonLanguage.arabic
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: SizedBox(
        height: style.height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foregroundColor,
            padding: style.padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(style.borderRadius),
              side: BorderSide(color: style.borderColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              leading ??
                  _DefaultLogo(
                    iconSize: style.iconSize,
                    backgroundColor: style.backgroundColor,
                    iconAppearance: style.iconAppearance,
                  ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  customLabel ?? _defaultLabel(language, labelType),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: style.fontSize,
                    fontWeight: style.fontWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _defaultLabel(
    UaePassButtonLanguage selectedLanguage,
    UaePassButtonLabelType selectedLabelType,
  ) {
    switch (selectedLanguage) {
      case UaePassButtonLanguage.arabic:
        switch (selectedLabelType) {
          case UaePassButtonLabelType.signIn:
            return 'تسجيل الدخول بالهوية الرقمية';
          case UaePassButtonLabelType.signUp:
            return 'إنشاء حساب بالهوية الرقمية';
        }
      case UaePassButtonLanguage.english:
        switch (selectedLabelType) {
          case UaePassButtonLabelType.signIn:
            return 'Sign in with UAE PASS';
          case UaePassButtonLabelType.signUp:
            return 'Sign up with UAE PASS';
        }
    }
  }
}

class _DefaultLogo extends StatelessWidget {
  const _DefaultLogo({
    required this.iconSize,
    required this.backgroundColor,
    required this.iconAppearance,
  });

  final double iconSize;
  final Color backgroundColor;
  final UaePassButtonIconAppearance iconAppearance;

  static const String _assetDark = 'assets/uae_pass_icon.png';
  static const String _assetLight = 'assets/uae_pass_icon_light.png';

  String _assetPath() {
    switch (iconAppearance) {
      case UaePassButtonIconAppearance.lightBackground:
        return _assetLight;
      case UaePassButtonIconAppearance.darkBackground:
        return _assetDark;
      case UaePassButtonIconAppearance.auto:
        final bool lightBg = backgroundColor.computeLuminance() > 0.5;
        return lightBg ? _assetLight : _assetDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(iconSize * 0.25),
      child: Image.asset(
        _assetPath(),
        package: 'auth_uae_pass',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
