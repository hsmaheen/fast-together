import 'package:flutter/material.dart';

class PrivacyOnboarding extends StatelessWidget {
  const PrivacyOnboarding({required this.onAcknowledged, super.key});

  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Privacy overview',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.primary,
                  semanticLabel: 'Privacy',
                ),
                const SizedBox(height: 16),
                Text(
                  'Your fasting stays private',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Personal Fasting Activity, including your history, is private to your App Account.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Sharing is your choice',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'If you choose to share with a Fasting Circle later, Circle Members will only see your current Shared Fasting Activity, not your personal history. You decide whether to enable sharing when that feature is available.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('privacyOnboardingAcknowledgeButton'),
                    onPressed: onAcknowledged,
                    child: const Text('I understand'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
