// Les etats transverses du controle (CT-9) : acces perdu ou absent
// (P-CTR-01).
//
// Refus par defaut (C7, doc 08 §9.5) : autorisation perdue, incertaine ou
// inconnue, rien du contenu precedent ne reste affiche ; les messages sont
// generiques et ne revelent aucun detail de securite. La barriere reste le
// serveur (BR-1) : cette garde n'est qu'une commodite d'affichage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/page_etat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/espaces_compte.dart';

/// Garde l'espace Controle : [child] n'est rendu que si la capacite
/// Controle est active. Retiree pendant la navigation, la page entiere,
/// barre comprise, laisse place au refus generique.
class GardeControle extends ConsumerWidget {
  /// Cree la garde.
  const GardeControle({required this.child, super.key});

  /// L'espace Controle.
  final Widget child;

  /// La cle du refus.
  static const Key refusKey = ValueKey<String>('controle-acces-refuse');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EspacesCompte espaces = ref.watch(espacesCompteProvider);
    return switch (espaces.accesControle) {
      AccesControle.actif => child,
      AccesControle.enAttente => PageShell(
        child: Semantics(
          label: t.controleur.controle.chargement,
          child: const Skeleton(hauteur: 180),
        ),
      ),
      AccesControle.refuse => PageEtat(
        key: refusKey,
        nature: NatureEtat.accesRefuse,
        titre: t.controleur.acces.revoque,
        libelleAction: t.controleur.acces.revenir,
        onAction: () =>
            GoRouter.of(context)
                .go(ref.read(adressesEspacesProvider).monEspace(espaces)),
      ),
    };
  }
}
