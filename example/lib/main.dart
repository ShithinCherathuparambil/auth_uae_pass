import 'package:auth_uae_pass/auth_uae_pass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _kClientSecret = 'YOUR_CLIENT_SECRET';
const String _kClientId = 'YOUR_CLIENT_ID';
const String _kScheme = 'YOUR_DEEP_LINK_SCHEME';
const String _kRedirectUri =
    'https://your-registered-callback.com/api/auth/callback/uaepass';
const UaePassEnvironment _kEnv = UaePassEnvironment.staging;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UAE PASS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00B6AA)),
        useMaterial3: true,
      ),
      home: const UaePassScreen(),
    );
  }
}

class UaePassScreen extends StatefulWidget {
  const UaePassScreen({super.key});

  @override
  State<UaePassScreen> createState() => _UaePassScreenState();
}

class _UaePassScreenState extends State<UaePassScreen> {
  UaePassAuthData? _authData;
  bool _isLoading = false;

  void _startAuth() async {
    setState(() {
      _authData = null;
      _isLoading = true;
    });

    final auth = AuthUaePass(
      config: const UaePassConfig(
        clientId: _kClientId,
        clientSecret: _kClientSecret,
        redirectUri: _kRedirectUri,
        environment: _kEnv,
        deepLinkScheme: _kScheme,
      ),
      onEvent: (event) {
        if (event == UaePassEvent.authStarted) HapticFeedback.mediumImpact();
        if (event == UaePassEvent.error) HapticFeedback.heavyImpact();
      },
    );

    try {
      final result = await auth.signInWithProfile(context);
      if (result.isSuccess) {
        setState(() => _authData = result);
        HapticFeedback.lightImpact();
      } else {
        setState(() => _authData = result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${result.errorDescription ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    setState(() => _isLoading = true);
    final auth = AuthUaePass(
      config: const UaePassConfig(
        clientId: _kClientId,
        clientSecret: _kClientSecret,
        redirectUri: _kRedirectUri,
        environment: _kEnv,
      ),
    );

    try {
      await auth.logout(
        context,
        environment: _kEnv,
        redirectUri: _kRedirectUri,
      );
      setState(() => _authData = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _simulateMockLogin() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UAE PASS SDK'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _startAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Login with UAE PASS'),
                ),
                const SizedBox(height: 16),
                if (kIsWeb) ...[
                  OutlinedButton(
                    onPressed: _simulateMockLogin,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Simulate Successful Login (Mock Web)'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_authData != null)
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Clear Session'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                const SizedBox(height: 32),
                if (_authData != null && _authData!.isSuccess)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B6AA),
                            ),
                          ),
                          const Divider(height: 24),
                          _infoRow('Name', _authData!.profile?.fullNameEN),
                          _infoRow('Emirates ID', _authData!.profile?.idn),
                          _infoRow('Email', _authData!.profile?.email),
                          _infoRow('Mobile', _authData!.profile?.mobile),
                          _infoRow(
                            'Nationality',
                            _authData!.profile?.nationalityEN,
                          ),
                          _infoRow('SOP Level', _authData!.sopLevel.toString()),
                        ],
                      ),
                    ),
                  ),
                if (_authData?.status == UaePassFlowStatus.error)
                  _errorWidget(
                    title: "Authentication Failed",
                    description: _authData!.errorDescription ?? "Unknown error",
                  ),
                if (_authData?.status == UaePassFlowStatus.cancelled)
                  _errorWidget(
                    title: "Authentication Cancelled",
                    description: "Cancelled by user",
                  ),
                if (_authData != null &&
                    !_authData!.isSuccess &&
                    _authData!.status != UaePassFlowStatus.error &&
                    _authData!.status != UaePassFlowStatus.cancelled)
                  _errorWidget(
                    title: "Unexpected Status: ${_authData!.status.name}",
                    description:
                        "Raw Status Code: ${_authData!.statusCode ?? 'None'}",
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget({required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade800),
          ),
          if (_authData?.errorCode != null || _authData?.statusCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  if (_authData?.errorCode != null)
                    Text(
                      'Error Code: ${_authData!.errorCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  if (_authData?.statusCode != null)
                    Text(
                      'Status Code: ${_authData!.statusCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}
