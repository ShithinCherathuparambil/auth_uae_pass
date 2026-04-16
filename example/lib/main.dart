import 'dart:async';

import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/material.dart';
import 'uae_pass_config.dart';

// UAE PASS Authentication Example

const String _kClientId = UaePassConfig.clientId;
const String _kClientSecret = UaePassConfig.clientSecret;

/// Registered redirect URI (must match UAE PASS app registration exactly).
const String _kRedirectUri = UaePassConfig.redirectUri;

/// App URL scheme (documented for deep linking / universal links setup).
const String _kUrlScheme = UaePassConfig.scheme;

/// Environment for UAE PASS (staging or production).
const UaePassEnvironment _kEnv = UaePassConfig.env;

void main() {
  runApp(const MyApp());
}

/// Root widget only builds [MaterialApp]. Navigation context must come from a
/// descendant (e.g. [HomePage]), not from above [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthUaePass _auth = const AuthUaePass();
  String _lastResult = 'Configure locale, then tap Sign in.';
  bool _arabicUi = false;
  UaePassEnvironment get _env => _kEnv;
  UaePassButtonLanguage get _btnLang =>
      _arabicUi ? UaePassButtonLanguage.arabic : UaePassButtonLanguage.english;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UAE PASS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Scheme: $_kUrlScheme · Client: $_kClientId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            title: const Text('Arabic UI (ui_locales)'),
            value: _arabicUi,
            onChanged: (bool v) => setState(() => _arabicUi = v),
          ),
          UaePassLoginButton(onPressed: _startAuth, language: _btnLang),
          const SizedBox(height: 12),
          UaePassLoginButton(
            language: _btnLang,
            style: const UaePassButtonStyle(
              iconAppearance: UaePassButtonIconAppearance.lightBackground,
            ),
            onPressed: _startAuth,
          ),
          const SizedBox(height: 12),
          UaePassLoginButton(
            onPressed: _startAuth,
            customLabel: 'Sign in with UAE PASS',
            style: const UaePassButtonStyle(
              backgroundColor: Color(0xFF000000),
              fontSize: 15,
              foregroundColor: Colors.white,
              borderRadius: 12,
              iconAppearance: UaePassButtonIconAppearance.darkBackground,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _startLogout, child: const Text('Logout')),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'DARK BUTTON GALLERY (24 VARIATIONS)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Matrix: 2 Backgrounds x 3 Borders x 4 Radii',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          ..._buildGallery(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'LIGHT OUTLINE GALLERY (THE 5)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Specific variations from the outline design study',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ..._buildOutlineGallery(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'LABEL VARIATIONS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Official text variations for different authentication contexts',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ..._buildLabelVariationsGallery(),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'LOGO ONLY (COMPACT)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Icon-only buttons for compact social-login layouts',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildLogoOnlyGallery(),
          const SizedBox(height: 40),
          SelectableText(_lastResult),
        ],
      ),
    );
  }

  List<Widget> _buildOutlineGallery() {
    const tealColor = Color(0xFF00B6AA);
    const greyColor = Color(0xFF98A2B3);
    const blackColor = Colors.black;

    return [
      _galleryItem(
        '1. Pill - Grey - English',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: greyColor,
            radius: 100,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '2. Pill - Teal - English',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: tealColor,
            radius: 100,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '3. Pill - Grey - English (Grayscale)',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: greyColor,
            radius: 100,
            elevation: 2,
            foregroundColor: greyColor,
            iconAppearance: UaePassButtonIconAppearance.grayscale,
          ),
        ),
      ),
      _galleryItem(
        '4. Pill - Black - English',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: blackColor,
            radius: 100,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '5. Pill - Grey (Color) - Arabic',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: greyColor,
            radius: 100,
            elevation: 2,
          ),
        ),
      ),
      Divider(color: Colors.grey.shade300, indent: 20, endIndent: 20),
      // --- REST OF THE GALLERY ---
      _galleryItem(
        '6. Teal Sharp (R:4)',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: tealColor,
            radius: 4,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '7. Teal Rounded (R:14)',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: tealColor,
            radius: 14,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '8. Black Sharp (R:4)',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: blackColor,
            radius: 4,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '9. Black Rounded (R:14)',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: blackColor,
            radius: 14,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '10. Square (R:0) - Grey',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: greyColor,
            radius: 0,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '11. Square (R:0) - Teal',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: tealColor,
            radius: 0,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '12. Rounded (R:20) - Teal',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          style: UaePassButtonStyle.outlineVariant(
            border: tealColor,
            radius: 20,
            elevation: 2,
          ),
        ),
      ),
      _galleryItem(
        '13. Rounded (R:20) - Monochrome',
        UaePassLoginButton(
          onPressed: _startAuth,
          style: UaePassButtonStyle.outlineVariant(
            border: greyColor,
            radius: 20,
            elevation: 2,
            foregroundColor: greyColor,
            iconAppearance: UaePassButtonIconAppearance.grayscale,
          ),
        ),
      ),
    ];
  }

  Widget _galleryItem(String label, Widget button) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          button,
        ],
      ),
    );
  }

  List<Widget> _buildLabelVariationsGallery() {
    return [
      _galleryItem(
        'Continue with...',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          labelType: UaePassButtonLabelType.continueWith,
        ),
      ),
      _galleryItem(
        'Login with...',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          labelType: UaePassButtonLabelType.login,
        ),
      ),
      _galleryItem(
        'Sign in with...',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          labelType: UaePassButtonLabelType.signIn,
        ),
      ),
      _galleryItem(
        'Sign up with...',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          labelType: UaePassButtonLabelType.signUp,
        ),
      ),
      _galleryItem(
        'Sign with...',
        UaePassLoginButton(
          onPressed: _startAuth,
          language: _btnLang,
          labelType: UaePassButtonLabelType.sign,
        ),
      ),
    ];
  }

  Widget _buildLogoOnlyGallery() {
    const tealColor = Color(0xFF00B6AA);
    const greyColor = Color(0xFF98A2B3);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _logoItem(
          '1. Black - R:14 - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: tealColor,
              radius: 14,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '2. Black - R:14',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.transparent,
              radius: 14,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '3. White - R:14 - Mono',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 14,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '4. Dark Grey - R:14',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: Colors.transparent,
              radius: 14,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '5. Black Circle',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.transparent,
              radius: 100,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '6. White Circle - Mono',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 100,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '7. Black Circle - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: tealColor,
              radius: 100,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '8. Dark Grey Circle',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: Colors.transparent,
              radius: 100,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '9. Black Square',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.transparent,
              radius: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '10. White Square - Mono',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 0,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '11. Black Square - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: tealColor,
              radius: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '12. Dark Grey Square',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: Colors.transparent,
              radius: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '13. White Circle - Mono (Border)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 100,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '14. Black Circle - Teal (Elevated)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: tealColor,
              radius: 100,
              elevation: 3,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '15. Dark Grey Circle (Elevated)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: Colors.transparent,
              radius: 100,
              elevation: 3,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '16. Black - R:8 - White Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.white,
              radius: 8,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '17. Dark Grey - R:8 - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: tealColor,
              radius: 8,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '18. Black Circle - White Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.white,
              radius: 100,
            ).copyWith(iconSize: 24, height: 48, borderWidth: 0.5),
          ),
        ),
        _logoItem(
          '19. Dark Grey Circle - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: tealColor,
              radius: 100,
            ).copyWith(iconSize: 24, height: 48, borderWidth: 0.5),
          ),
        ),
        _logoItem(
          '20. Black - R:20 - Flat',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.transparent,
              radius: 20,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '21. White - R:14 - Black Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 14,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '22. White - R:14 - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 14,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '23. White - R:14 - Grey (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 14,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.lightBackground,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '24. White Circle - Black Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 100,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '25. White Circle - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 100,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '26. White Circle - Grey (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 100,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '27. White Square - Black Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 0,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '28. White Square - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 0,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '29. White Square - Grey Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 0,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '30. White - R:8 - Teal Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 8,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '31. White Circle - Grey Border (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 100,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '32. White Square (R:14) - Grey Border (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 14,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '33. White Circle - Black Border (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 100,
              elevation: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '34. White Square (R:14) - Black Border (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 14,
              elevation: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '35. White Rounded (R:20) - Teal (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 20,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '36. White Rounded (R:30) - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 30,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '37. White Rounded (R:30) - Black',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 30,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '38. White Rounded (R:30) - Grey (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 30,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '39. White Rounded (R:5) - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 5,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '40. White Rounded (R:5) - Black',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 5,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '41. White Rounded (R:14) - Black (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 14,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '42. White Rounded (R:20) - Black (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 20,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '43. White Rounded (R:30) - Black (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 30,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '44. White Circle - Grey (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 100,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '45. White Square - Teal (Mono)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: tealColor,
              radius: 0,
              elevation: 1,
              iconAppearance: UaePassButtonIconAppearance.grayscale,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '46. White Square - Grey (Color)',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: greyColor,
              radius: 0,
              elevation: 1,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '47. White Circle - Black (Color) - Elevated',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 100,
              elevation: 3,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '48. Black Square - White Border',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: Colors.black,
              border: Colors.white,
              radius: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '49. Dark Grey Square - Teal',
          UaePassLoginButton(
            onPressed: _startAuth,
            language: _btnLang,
            hideLabel: true,
            style: UaePassButtonStyle.darkVariant(
              background: const Color(0xFF2D2D2D),
              border: tealColor,
              radius: 0,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
        _logoItem(
          '50. White Rounded (R:14) - Black - Elevated',
          UaePassLoginButton(
            onPressed: _startAuth,
            hideLabel: true,
            style: UaePassButtonStyle.outlineVariant(
              border: Colors.black,
              radius: 14,
              elevation: 3,
            ).copyWith(iconSize: 24, height: 48),
          ),
        ),
      ],
    );
  }

  Widget _logoItem(String label, Widget button) {
    return Tooltip(message: label, child: button);
  }

  List<Widget> _buildGallery() {
    return [
      const Text(
        'Background: Black',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text(
        'No Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.transparent,
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.transparent,
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.transparent,
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.transparent,
          radius: 100,
        ),
      ),

      const SizedBox(height: 16),
      const Text(
        'White Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.white,
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.white,
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.white,
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: Colors.white,
          radius: 100,
        ),
      ),

      const SizedBox(height: 16),
      const Text(
        'Teal Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: const Color(0xFF00B6AA),
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: const Color(0xFF00B6AA),
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: const Color(0xFF00B6AA),
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: Colors.black,
          border: const Color(0xFF00B6AA),
          radius: 100,
        ),
      ),

      const SizedBox(height: 24),
      Divider(color: Colors.grey.shade400),
      const SizedBox(height: 24),
      const Text(
        'Background: Dark Grey',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text(
        'No Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.transparent,
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.transparent,
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.transparent,
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.transparent,
          radius: 100,
        ),
      ),

      const SizedBox(height: 16),
      const Text(
        'White Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.white,
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.white,
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.white,
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: Colors.white,
          radius: 100,
        ),
      ),

      const SizedBox(height: 16),
      const Text(
        'Teal Border',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: const Color(0xFF00B6AA),
          radius: 0,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: const Color(0xFF00B6AA),
          radius: 8,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: const Color(0xFF00B6AA),
          radius: 14,
        ),
      ),
      const SizedBox(height: 12),
      UaePassLoginButton(
        onPressed: _startAuth,
        language: _btnLang,
        style: UaePassButtonStyle.darkVariant(
          background: const Color(0xFF2D2D2D),
          border: const Color(0xFF00B6AA),
          radius: 100,
        ),
      ),
    ];
  }

  Future<void> _startAuth() async {
    debugPrint('Example: Starting quick auth...');

    final UaePassAuthData result = await _auth.signInWithProfile(
      context,
      clientId: _kClientId,
      clientSecret: _kClientSecret,
      redirectUri: _kRedirectUri,
      environment: _kEnv,
      uiLocale: _arabicUi ? 'ar' : 'en',
    );

    if (!mounted) return;

    if (result.isSuccess && result.profile != null) {
      final profile = result.profile!;
      setState(() {
        final buffer = StringBuffer();

        final String sopTitle = switch (result.sopLevel) {
          UaePassSopLevel.sop1 => 'SOP1 (Simple Password)',
          UaePassSopLevel.sop2 => 'SOP2 (Biometrics)',
          UaePassSopLevel.sop3 => 'SOP3 (Verified Face ID)',
          _ => 'Login Success',
        };

        buffer.writeln('OK: $sopTitle');
        buffer.writeln('Internal Status: ${result.status.name}');
        buffer.writeln('UUID: ${profile.uuid}');
        buffer.writeln('Name: ${profile.fullNameEN}');
        buffer.writeln('Name (AR): ${profile.fullNameAR}');
        buffer.writeln('Gender: ${profile.gender}');
        buffer.writeln('Nationality: ${profile.nationalityEN}');
        if (profile.email != null) {
          buffer.writeln('Email: ${profile.email}');
        }
        if (profile.mobile != null) {
          buffer.writeln('Mobile: ${profile.mobile}');
        }
        _lastResult = buffer.toString();
      });
    } else {
      final String message = switch (result.status) {
        UaePassFlowStatus.cancelled => 'Auth cancelled by user',
        UaePassFlowStatus.error =>
          'Auth failed: ${result.errorCode ?? '-'} (${result.errorDescription ?? '-'})',
        _ => 'Auth result: ${result.status.name}',
      };
      setState(() => _lastResult = message);
    }
  }

  Future<void> _startLogout() async {
    final UaePassAuthResult result = await _auth.logout(
      context,
      env: _env,
      redirectUri: _kRedirectUri,
    );
    if (!mounted) return;
    setState(() {
      _lastResult = 'Logout: ${result.status.name}';
    });
  }
}
