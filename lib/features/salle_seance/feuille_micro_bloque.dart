// La feuille « micro bloque » (lot CL-7, T-S4, P09).
//
// Ouverte au geste Micro quand le systeme de l'appareil refuse le micro
// (`VueSeance.microBloque`, signal du moteur, BR-1). Contenu seulement : la
// surface est celle d'`AppBottomSheet.ouvrir` (feuille du bas < 600, feuille
// bornee en tablette, dialogue centre en desktop). Aucun etat « micro actif »
// n'est montre ni envoye (P09.6).
//
// Actions (contrat B, UX_REVIEW U5) : « Continuer sans micro » au bord
// leading, « Ouvrir les reglages » au bord trailing **seulement si**
// `onOuvrirReglages` existe (aucun paquet de permission avant BR-1 : le
// bouton n'est pas rendu). Seule, « Continuer sans micro » devient l'action
// principale.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import 'actions_seance.dart';
import 'vue_seance.dart';

/// Ouvre la feuille « micro bloque » et attend sa fermeture (action, voile,
/// glissement ou `Echap`). L'appelant rend ensuite le focus au bouton Micro.
Future<void> ouvrirFeuilleMicroBloque(
  BuildContext context, {
  required VueSeance vue,
  required ActionsSeance actions,
}) async {
  final _Choix? choix = await AppBottomSheet.ouvrir<_Choix>(
    context,
    titre: t.salle.micro,
    constructeur: (BuildContext contexte) => FeuilleMicroBloque(vue: vue),
    actions: (BuildContext contexte) => ActionsMicroBloque(
      avecReglages: actions.onOuvrirReglages != null,
      onContinuer: () => Navigator.of(contexte).pop(_Choix.continuer),
      onReglages: () => Navigator.of(contexte).pop(_Choix.reglages),
    ),
  );
  // Le rappel suit la fermeture : la feuille est deja retiree.
  switch (choix) {
    case _Choix.continuer:
      actions.onContinuerSansMicro?.call();
    case _Choix.reglages:
      actions.onOuvrirReglages?.call();
    case null:
      break;
  }
}

enum _Choix { continuer, reglages }

/// Le corps de la feuille : la phrase exacte du role (S l.633, l.758).
class FeuilleMicroBloque extends StatelessWidget {
  const FeuilleMicroBloque({required this.vue, super.key});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Text(
      vue.texteMicroBloque,
      key: const ValueKey<String>('texte-micro-bloque'),
      style: palette.surfaceRaised.applyTo(
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      ),
    );
  }
}

/// Le groupe d'actions, au bord trailing (contrat B) : « Continuer sans
/// micro » puis, si la plateforme le permet, « Ouvrir les reglages ».
class ActionsMicroBloque extends StatelessWidget {
  const ActionsMicroBloque({
    required this.avecReglages,
    required this.onContinuer,
    required this.onReglages,
    super.key,
  });

  final bool avecReglages;
  final VoidCallback onContinuer;
  final VoidCallback onReglages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        // `IntrinsicWidth` : le bouton garde la largeur de son libelle.
        children: <Widget>[
          IntrinsicWidth(
            child: ActionPrincipale(
              key: const ValueKey<String>('micro-bloque-continuer'),
              libelle: t.salle.secours.continuerSansMicro,
              onPress: onContinuer,
              // Un seul CTA dominant (contrat B) : secondaire a cote des
              // reglages, principal quand il est seul.
              niveau: avecReglages
                  ? NiveauAction.secondaire
                  : NiveauAction.principale,
              pleineLargeur: false,
            ),
          ),
          if (avecReglages)
            IntrinsicWidth(
              child: ActionPrincipale(
                key: const ValueKey<String>('micro-bloque-reglages'),
                libelle: t.salle.secours.ouvrirReglages,
                onPress: onReglages,
                pleineLargeur: false,
              ),
            ),
        ],
      ),
    );
  }
}
