import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/barre_precedent_suivant.dart';

/// Une fleche de page du Mushaf, ronde, hors de la page.
///
/// Le bouton rond est celui de `BarrePrecedentSuivant` ([FlecheRonde]), mais posee **de chaque cote de la page**
/// et non sous elle. Le glyphe est celui des jetons ; il est retourne ici,
/// selon le cote, jamais selon la langue de l'interface : un Mushaf se feuillette
/// de la droite vers la gauche en francais comme en arabe.
class FlechePageMushaf extends StatelessWidget {
  /// Cree une fleche.
  const FlechePageMushaf({
    required this.libelle,
    required this.versLaGauche,
    required this.onPress,
    this.cote,
    super.key,
  });

  /// Le cote du disque ; par defaut la cible tactile (la salle, S0.2 : plus
  /// grand, reference 4 du directeur).
  final double? cote;

  /// Ce que le lecteur d'ecran annonce.
  final String libelle;

  /// Vrai : fleche du bord gauche, qui pointe vers la gauche.
  final bool versLaGauche;

  /// `null` : borne atteinte, la fleche n'est pas rendue (sa place reste).
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) => FlecheRonde(
    libelle: libelle,
    onPress: onPress,
    retourne: versLaGauche,
    cote: cote,
  );
}

/// La page encadree de ses deux fleches (tablette et bureau).
///
/// Les fleches sont symetriques, centrees verticalement, dans deux colonnes
/// reservees : elles ne chevauchent jamais le texte. **La page suivante est a
/// gauche**, comme quand on feuillette un livre arabe : la fleche de gauche est
/// « page suivante », celle de droite « page precedente ». Les touches
/// gauche et droite font de meme.
class PageAvecFlechesMushaf extends StatelessWidget {
  /// Cree l'encadrement.
  const PageAvecFlechesMushaf({
    required this.libellePrecedente,
    required this.libelleSuivante,
    required this.onPrecedente,
    required this.onSuivante,
    required this.child,
    this.cote,
    this.focusAuto = true,
    super.key,
  });

  /// Le cote des fleches ; par defaut la cible tactile.
  final double? cote;

  /// Vrai : la page prend le focus clavier a l'ouverture (lecteur du Coran).
  /// La salle le laisse a ses propres raccourcis.
  final bool focusAuto;

  /// Le libelle de la fleche de droite.
  final String libellePrecedente;

  /// Le libelle de la fleche de gauche.
  final String libelleSuivante;

  /// `null` a la premiere page.
  final VoidCallback? onPrecedente;

  /// `null` a la derniere page.
  final VoidCallback? onSuivante;

  /// La page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): ?onSuivante,
        const SingleActivator(LogicalKeyboardKey.arrowRight): ?onPrecedente,
      },
      child: Focus(
        autofocus: focusAuto,
        // Les fleches du clavier appartiennent a la page, pas a un champ : le
        // focus reste sur elle tant qu'aucun autre controle ne le prend.
        child: Directionality(
          // Cote physique : gauche et droite ne suivent pas la langue.
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              FlechePageMushaf(
                libelle: libelleSuivante,
                versLaGauche: true,
                onPress: onSuivante,
                cote: cote,
              ),
              Expanded(
                child: Directionality(textDirection: sens, child: child),
              ),
              FlechePageMushaf(
                libelle: libellePrecedente,
                versLaGauche: false,
                onPress: onPrecedente,
                cote: cote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
