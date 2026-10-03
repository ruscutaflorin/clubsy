import 'package:flutter/material.dart';

/// "Couldn't refresh — showing data from 21:04 · Retry"
class ErrorBanner extends StatelessWidget {
  final String error;
  final DateTime? savedAt;
  final VoidCallback onRetry;

  const ErrorBanner({
    super.key,
    required this.error,
    required this.onRetry,
    this.savedAt,
  });

  static String _hhmm(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final text = savedAt != null
        ? "Couldn't refresh — showing data from ${_hhmm(savedAt!)}"
        : "Couldn't refresh — $error";
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('errorBanner'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
