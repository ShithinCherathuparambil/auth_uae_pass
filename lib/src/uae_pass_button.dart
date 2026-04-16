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
    this.hideLabel = false,
  });

  final VoidCallback onPressed;
  final UaePassButtonLanguage language;
  final UaePassButtonLabelType labelType;
  final String? customLabel;
  final UaePassButtonStyle style;
  final Widget? leading;
  final bool hideLabel;

  @override
  Widget build(BuildContext context) {
    final textDirection = language == UaePassButtonLanguage.arabic
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: SizedBox(
        height: style.height,
        width: style.width ?? (hideLabel ? style.height : double.infinity),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: style.elevation,
            shadowColor: style.shadowColor,
            backgroundColor: style.backgroundColor,
            foregroundColor: style.foregroundColor,
            padding: hideLabel ? EdgeInsets.zero : style.padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(style.borderRadius),
              side: BorderSide(
                color: style.borderColor,
                width: style.borderWidth,
              ),
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
              if (!hideLabel) ...[
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
          case UaePassButtonLabelType.login:
            return 'تسجيل الدخول بالهوية الرقمية';
          case UaePassButtonLabelType.continueWith:
            return 'الاستمرار عبر الهوية الرقمية';
          case UaePassButtonLabelType.sign:
            return 'التوقيع عبر الهوية الرقمية';
        }
      case UaePassButtonLanguage.english:
        switch (selectedLabelType) {
          case UaePassButtonLabelType.signIn:
            return 'Sign in with UAE PASS';
          case UaePassButtonLabelType.signUp:
            return 'Sign up with UAE PASS';
          case UaePassButtonLabelType.login:
            return 'Login with UAE PASS';
          case UaePassButtonLabelType.continueWith:
            return 'Continue with UAE PASS';
          case UaePassButtonLabelType.sign:
            return 'Sign with UAE PASS';
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
      case UaePassButtonIconAppearance.grayscale:
        return _assetLight;
      case UaePassButtonIconAppearance.auto:
        final bool lightBg = backgroundColor.computeLuminance() > 0.5;
        return lightBg ? _assetLight : _assetDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      _assetPath(),
      package: 'auth_uae_pass',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );

    if (iconAppearance == UaePassButtonIconAppearance.grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.5, child: image),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(iconSize * 0.25),
      child: image,
    );
  }
}
