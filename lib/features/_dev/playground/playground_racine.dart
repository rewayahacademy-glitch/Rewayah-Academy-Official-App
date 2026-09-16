/// L'enveloppe hors ligne du Playground developpement.
///
/// Ce fichier est le point d'entree quand `Env.playgroundActif` est vrai
/// (`lib/app.dart` et `lib/core/config/env.dart`). La vraie application
/// (`RewayahApp`) n'est pas touchee : elle est remontee sous un nouveau
/// `ProviderScope` pour chaque personne du banc d'essai, exactement comme un
/// test de widget. Changer de personne demonte l'ancien conteneur et en monte
/// un neuf, donc chaque surcharge repart de zero.
///
/// Il n'y a pas de bouton de retour vers ce menu depuis l'application :
/// c'est une porte d'entree de developpement, pas un ecran de produit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';
import 'package:rewayah_academy/features/_dev/playground/faux.dart';
import 'package:rewayah_academy/features/_dev/playground/persona.dart';

/// Point d'entree du Playground : le menu des personnes, puis la vraie app.
class PlaygroundRacine extends StatefulWidget {
  /// Cree la racine.
  const PlaygroundRacine({super.key});

  @override
  State<PlaygroundRacine> createState() => _PlaygroundRacineState();
}

class _PlaygroundRacineState extends State<PlaygroundRacine> {
  late final List<Persona> _personas =
      personasDuBench(maintenant: DateTime.now());

  /// Personne montee, ou null tant que le menu est affiche.
  Persona? _montage;

  @override
  Widget build(BuildContext context) {
    final Persona? montee = _montage;
    if (montee == null) {
      return MaterialApp(
        title: 'Rewayah — Playground',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        ),
        home: _Menu(
          personas: _personas,
          onChoisir: (Persona personne) =>
              setState(() => _montage = personne),
        ),
      );
    }

    // La cle par personne garantit un conteneur neuf a chaque changement :
    // sans elle, Flutter reutilise l'element du `ProviderScope` precedent et
    // Riverpod regle des providers perimes sur le nouveau montage.
    return ProviderScope(
      key: ValueKey<String>(montee.id),
      overrides: montee.surcharges,
      child: const _HoteApp(),
    );
  }
}

/// Passe-vole de diagnostic : imprime l'etat de session que l'application
/// lit vraiment, puis la rend.
class _HoteApp extends ConsumerWidget {
  const _HoteApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SourceSession source = ref.watch(sourceSessionProvider);
    final SessionState session = ref.watch(sessionProvider);
    // ignore: avoid_print
    print(
      'PLAYGROUND: source=${source.runtimeType} '
      'sourceEtat(porte)=${source is FausseSourceSession ? source.etat.porte : 'real'} '
      'appSession(porte)=${session.porte} '
      'appSession(resolue)=${session.resolue} '
      'role=${session.role} statut=${session.accountStatus}',
    );
    return const RewayahApp();
  }
}

/// Le menu des personnes du banc d'essai.
class _Menu extends StatelessWidget {
  const _Menu({required this.personas, required this.onChoisir});

  final List<Persona> personas;
  final ValueChanged<Persona> onChoisir;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Playground — choisir une personne')),
      body: ListView.separated(
        itemCount: personas.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final Persona personne = personas[index];
          return ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(personne.libelle),
            subtitle: Text(personne.id),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onChoisir(personne),
          );
        },
      ),
      bottomSheet: SizedBox(
        height: 40,
        child: Center(
          child: Text(
            '${personas.length} personnes, infrastructure remplacee (hors ligne)',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}