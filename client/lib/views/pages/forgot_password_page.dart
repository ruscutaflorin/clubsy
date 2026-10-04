import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

/// Two steps: ask for a code by email, then enter it with a new password.
class ForgotPasswordPage extends StatefulWidget {
  final AuthService? authService;

  const ForgotPasswordPage({super.key, this.authService});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final AuthService _auth = widget.authService ?? AuthService();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String fallback) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : fallback);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_email.text.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    await _run(() async {
      await _auth.requestPasswordReset(_email.text.trim());
      if (mounted) setState(() => _codeSent = true);
    }, "Couldn't send the code");
  }

  Future<void> _reset() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    await _run(() async {
      await _auth.resetPassword(
        _email.text.trim(),
        _code.text.trim(),
        _password.text,
      );
      Get.snackbar('Password reset', 'Sign in with your new password');
      Get.back();
    }, "Couldn't reset your password");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('resetEmailField'),
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_codeSent) ...[
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'If that email has an account, we sent a 6-digit code. '
                'It is valid for 15 minutes.',
              ),
            ),
            TextField(
              key: const Key('resetCodeField'),
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            TextField(
              key: const Key('resetPasswordField'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            TextField(
              key: const Key('resetConfirmField'),
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                key: const Key('resetError'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('resetSubmit'),
            onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
            child: Text(_codeSent ? 'Reset password' : 'Send code'),
          ),
        ],
      ),
    );
  }
}
