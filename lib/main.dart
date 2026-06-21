import 'package:fasting_app/ui/components/local_fasting_status_section.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FastingApp());
}

class FastingApp extends StatelessWidget {
  const FastingApp({super.key});

  static const _seedColor = Color(0xFFB58C52);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fasting App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
      ),
      home: const FastingHomePage(),
    );
  }
}

class FastingHomePage extends StatelessWidget {
  const FastingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting App'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LocalFastingStatusSection(
                    nowUtc: () => DateTime.now().toUtc(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
