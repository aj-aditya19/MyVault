import 'package:flutter/material.dart';

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final packages = const [
      {
        'name': 'flutter',
        'license': 'BSD 3-Clause',
        'purpose': 'UI toolkit and framework',
      },
      {
        'name': 'encrypt',
        'license': 'MIT',
        'purpose': 'Encrypt/decrypt local task and money data',
      },
      {
        'name': 'path_provider',
        'license': 'BSD 3-Clause',
        'purpose': 'Access application document directory',
      },
      {
        'name': 'material_design_icons_flutter',
        'license': 'Apache 2.0',
        'purpose': 'Icon support for modern UI elements',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Licenses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.64),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MyVault',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'This app includes open-source packages. Their licenses are listed below for transparency and compliance.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...packages.map(
            (pkg) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withValues(alpha: 0.72),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'License: ${pkg['license']!}',
                    style: TextStyle(color: scheme.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg['purpose']!,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'MyVault',
                applicationVersion: '1.0.0',
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('View Full Flutter Licenses'),
          ),
        ],
      ),
    );
  }
}
