// PT-B : l'onglet Coran de l'eleve adulte en demonstration
// (`/demo/adulte?ecran=coran`).
//
// Decision deleguee par le directeur (04/10) : AUCUN corpus coranique n'est
// embarque dans la demonstration. Le texte du Coran ne vit que sur le
// serveur (migration 0013), et la demonstration n'appelle aucun serveur
// (K-28). L'onglet ne mene donc ni a une page provisoire, ni au lecteur
// reel (qui ne pourrait afficher que son erreur reseau et un « Reessayer »
// voue a l'echec, K-59) : il dit honnetement que le Coran est disponible
// apres connexion.
//
// Les cinq etats, sans lecture : rien ne se charge (aucune attente), rien
// ne peut echouer (aucune erreur), et la page est la meme hors ligne
// (`reseau=coupe`) : elle ne depend d'aucun reseau. Le seul contenu est
// l'etat « indisponible » d'`EtatSysteme`, sans bouton (rien a reessayer).
//
// Dans l'application, l'onglet Coran de `/eleve/adulte` mene a la vraie page
// Coran (`/eleve/coran`, `MushafPage`), prouve par
// `test/features/accueil_adulte/coran_adulte_test.dart`. Le rendu du Coran
// n'est pas touche.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../compte/carte_rubriques.dart' show ColonneSousPage;

/// La page Coran de l'eleve adulte en demonstration : le Coran est
/// disponible apres connexion. Aucun appel serveur, aucun corpus.
class CoranDemoAdulte extends StatelessWidget {
  /// Cree la page.
  const CoranDemoAdulte({super.key});

  /// La cle de l'etat « disponible apres connexion ».
  static const Key etatKey = ValueKey<String>('coran-adulte-demo-connexion');

  @override
  Widget build(BuildContext context) => PageShell(
    titre: t.adulte.nav.coran,
    child: ColonneSousPage(
      child: EtatSysteme(
        key: etatKey,
        nature: NatureEtat.indisponible,
        titre: t.adulte.coranDemo.titre,
        phrase: t.adulte.coranDemo.phrase,
        // Pour la trace et les tests seulement, jamais affiche.
        dependance: 'PT-B',
      ),
    ),
  );
}
