import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app.dart';
import 'photo_credits_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(body, style: text.bodyMedium?.copyWith(color: muted)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: Text('👩‍🍳', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 8),
          Center(
            child: Text(
              appName,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Text(
                snap.hasData ? 'Versión ${snap.data!.version}' : '',
                style: TextStyle(color: muted),
              ),
            ),
          ),
          const SizedBox(height: 28),
          section(
            'Aviso de salud',
            'Las recetas, los planes de alimentación y los valores '
                'nutricionales son aproximados y orientativos. No son '
                'consejo médico ni reemplazan la consulta con un médico o '
                'nutricionista. Si tienes diabetes, hipertensión, alergias, '
                'estás embarazada o sigues una dieta por indicación médica, '
                'consulta con un profesional antes de cambiar tu '
                'alimentación.',
          ),
          section(
            'Alergias',
            'Revisa siempre los ingredientes de cada receta. Las etiquetas '
                '"sin gluten" y "vegetariano" se basan en los ingredientes '
                'indicados; verifica las etiquetas de los productos que '
                'compres.',
          ),
          section(
            'Privacidad',
            'AppCocina no tiene cuentas de usuario ni recopila datos '
                'personales. Tus favoritos, tu lista de compras y tu plan '
                'se guardan solo en este teléfono y se borran si '
                'desinstalas la app.',
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhotoCreditsScreen()),
              ),
              child: const Text('Créditos de fotos'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: appName),
              child: const Text('Licencias de código abierto'),
            ),
          ),
        ],
      ),
    );
  }
}
