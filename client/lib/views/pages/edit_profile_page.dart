import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clubsy/data/classes/profile_validation.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/src/core/controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const checkDelay = Duration(milliseconds: 500);

  final _auth = Get.find<AuthController>();
  late final _name = TextEditingController(text: _auth.user?['name'] ?? '');
  late final _username = TextEditingController(
    text: _auth.user?['username'] ?? '',
  );
  late final _city = TextEditingController(text: _auth.user?['homeCity'] ?? '');
  Timer? _debounce;
  bool? _available;
  bool _checking = false;
  bool _busy = false;
  String? _nameError;
  String? _usernameError;
  String? _cityError;
  String? _error;

  String get _original => _auth.user?['username'] ?? '';

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _username.dispose();
    _city.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    final u = normalizeUsername(value);
    setState(() {
      _available = null;
      _usernameError = validateUsername(value);
      _checking = false;
    });
    if (u.isEmpty || u == _original || _usernameError != null) return;
    _debounce = Timer(checkDelay, () async {
      setState(() => _checking = true);
      try {
        final free = await _auth.isUsernameAvailable(u);
        if (!mounted || normalizeUsername(_username.text) != u) return;
        setState(() {
          _available = free;
          _checking = false;
        });
      } catch (_) {
        if (mounted) setState(() => _checking = false);
      }
    });
  }

  Future<void> _save() async {
    final nameError = validateDisplayName(_name.text);
    final usernameError = validateUsername(_username.text);
    final cityError = validateHomeCity(_city.text);
    setState(() {
      _nameError = nameError;
      _usernameError = usernameError;
      _cityError = cityError;
      _error = null;
    });
    if (nameError != null || usernameError != null || cityError != null) {
      return;
    }

    final username = normalizeUsername(_username.text);
    setState(() => _busy = true);
    try {
      await _auth.updateProfile(
        name: _name.text.trim(),
        username: username.isEmpty || username == _original ? null : username,
        homeCity: _city.text.trim(),
      );
      Get.back();
      Get.snackbar('Profile updated', 'Your profile was saved');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 409) {
          _usernameError = 'That username is taken';
          _available = false;
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't save your profile");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget? _usernameStatus() {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_available == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_available == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('profileName'),
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Display name',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('profileUsername'),
            controller: _username,
            autocorrect: false,
            onChanged: _onUsernameChanged,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              helperText: _available == true
                  ? 'Available'
                  : '3-20 characters: a-z, 0-9, _',
              errorText: _usernameError,
              suffixIcon: _usernameStatus(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('profileCity'),
            controller: _city,
            decoration: InputDecoration(
              labelText: 'Home city',
              errorText: _cityError,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('profileSave'),
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
