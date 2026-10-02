import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a bundled legal document (plain text / minimal markdown).
class LegalPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalPage({super.key, required this.title, required this.assetPath});

  const LegalPage.privacy({super.key})
    : title = 'Privacy Policy',
      assetPath = 'assets/legal/privacy.md';

  const LegalPage.terms({super.key})
    : title = 'Terms of Use',
      assetPath = 'assets/legal/terms.md';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load this document'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _LegalBody(snapshot.data!),
          );
        },
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  final String text;

  const _LegalBody(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) continue;
      if (line.startsWith('## ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(line.substring(3), style: theme.titleMedium),
          ),
        );
      } else if (line.startsWith('# ')) {
        children.add(Text(line.substring(2), style: theme.headlineSmall));
      } else if (line.startsWith('- ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text('• ${line.substring(2)}', style: theme.bodyMedium),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(line, style: theme.bodyMedium),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
