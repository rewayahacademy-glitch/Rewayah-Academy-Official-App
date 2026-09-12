import 'package:flutter/material.dart';

import 'env.dart';

/// L'ecran affiche quand la configuration de compilation manque.
///
/// Il existe parce que le garde-fou d'origine etait un `assert` : retire de
/// toute version release, il laissait une compilation sans
/// `--dart-define-from-file` demarrer normalement, puis mourir sur un ecran
/// gris des que le premier provider touchait le client Supabase
/// (`LateInitializationError`). Trois deploiements de suite sont partis ainsi
/// le 12 septembre 2026 sans que rien ne le signale : une panne muette coute
/// plus cher qu'un demarrage refuse.
///
/// Il ne depend volontairement d'AUCUN jeton, theme, traduction ni provider.
/// C'est l'ecran de dernier recours : il doit s'afficher meme quand le reste
/// de l'application ne peut pas se construire, donc il ne peut rien exiger.
class EcranConfigurationAbsente extends StatelessWidget {
  const EcranConfigurationAbsente({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Configuration absente',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cette version a ete compilee sans ses cles. Elle ne peut '
                  "joindre aucune donnee, et aucun ecran de l'application ne "
                  'fonctionnerait.',
                ),
                const SizedBox(height: 24),
                const Text(Env.aideConfiguration),
                const SizedBox(height: 24),
                const SelectableText(
                  'flutter build web --release '
                  '--dart-define-from-file=dart_define.json',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
