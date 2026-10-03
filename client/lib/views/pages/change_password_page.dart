import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_new.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Get.find<AuthController>().changePassword(_current.text, _new.text);
      Get.snackbar('Password changed', 'Your password was updated');
      Get.back();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException && e.statusCode == 401
            ? 'Wrong password'
            : e is ApiException
            ? e.message
            : "Couldn't change your password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('currentPasswordField'),
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          TextField(
            key: const Key('newPasswordField'),
            controller: _new,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          TextField(
            key: const Key('confirmPasswordField'),
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                key: const Key('changePasswordError'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('changePasswordSubmit'),
            onPressed: _busy ? null : _submit,
            child: const Text('Change password'),
          ),
        ],
      ),
    );
  }
}
