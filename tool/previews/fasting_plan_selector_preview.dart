import 'package:fasting_app/ui/components/local_fasting_status_section.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FastingPlanSelectorPreviewApp());
}

class FastingPlanSelectorPreviewApp extends StatelessWidget {
  const FastingPlanSelectorPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFB58C52);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      home: const _PreviewSurface(),
    );
  }
}

class _PreviewSurface extends StatefulWidget {
  const _PreviewSurface();

  @override
  State<_PreviewSurface> createState() => _PreviewSurfaceState();
}

class _PreviewSurfaceState extends State<_PreviewSurface> {
  static final _previewTime = DateTime.utc(2026, 6, 21, 4, 15);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Fasting Status',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start and end a local Fasting Session without Firebase.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LocalFastingStatusSection(
                    nowUtc: () => _previewTime,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
