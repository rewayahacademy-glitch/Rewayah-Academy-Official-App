// Mode demonstration tuteur (P2-07) : repere visible sur tous les ecrans.
//
// Une bande en tete, posee par `RewayahApp.builder`, pour qu'aucune capture
// de l'apercu ne passe pour la production (SUPERPOS-1 : dans le flux, plus
// par-dessus).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Le libelle du repere, traduit (K-41) : `commun.demonstration.repere`.
String get libelleRepereDemonstration => t.commun.demonstration.repere;

/// Le repere « Démonstration » de l'apercu, sur tous les ecrans.
///
/// SUPERPOS-1 (decision du 05/10/2026, prise par delegation) : le repere
/// etait un ruban d'angle peint **par-dessus** l'application (`Banner`) ; a
/// 320 en texte double, il couvrait le bouton du compte de la coquille admin,
/// et en arabe le debut du titre de la page. Il devient une bande fine, en
/// tete, **dans le flux** : elle prend sa place et pousse l'application
/// dessous, qui ne recoit plus la zone sure du haut (la bande la porte). Le
/// registre est doux (`washAccent`) : une seule zone pleine par ecran, celle
/// de l'action principale. Le mot reste en entier a 320 en texte double.
///
/// **Clavier ouvert, la bande se ferme** (decide par delegation le 05/10) :
/// a 320 x 640, un clavier de 300 ne laisse que 340 de vue ; la bande y
/// prenait la hauteur qui manquait a la page sous la feuille de refus (14 de
/// debordement). Le repere revient des que le clavier se ferme ; l'arbre de
/// l'application ne change pas de place (son etat est garde).
class RepereDemonstration extends StatelessWidget {
  /// Cree le repere.
  const RepereDemonstration({super.key, required this.child});

  /// Le rendu de l'application.
  final Widget? child;

  /// La bande du repere (tests, captures).
  static const Key bandeKey = ValueKey<String>('repere-demonstration');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.washAccent;
    final bool clavier = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le repere est lu une fois, en entier (revue P2-10, constat 2).
        if (!clavier)
          Semantics(
            container: true,
            label: t.commun.demonstration.repereLu,
            excludeSemantics: true,
            // Pose au-dessus du navigateur, hors de tout `Material` : sans
            // lui, le texte heriterait du style d'erreur de `MaterialApp`.
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                key: bandeKey,
                decoration: BoxDecoration(
                  color: paire.background,
                  border: Border(bottom: palette.borderHairline.asBorderSide()),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      libelleRepereDemonstration,
                      textAlign: TextAlign.center,
                      style: paire.applyTo(
                        Theme.of(context).textTheme.labelMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          // Un conteneur semantique propre : la barriere d'une route
          // (`BlockSemantics`) masque les noeuds peints avant elle dans le
          // meme conteneur, donc la bande, sans lui.
          //
          // TB-12 (UX-21) : `explicitChildNodes` garde a chaque descendant son
          // propre noeud. Sans lui, pose directement sur une salle
          // (observateurs de /demo/salle), ce conteneur absorbait l'ecran
          // entier : un seul noeud lu, « Quitter » compris, sans cible
          // separee.
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: MediaQuery.removePadding(
              context: context,
              // Clavier ouvert, sans bande : l'application garde la zone
              // sure du haut.
              removeTop: !clavier,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
