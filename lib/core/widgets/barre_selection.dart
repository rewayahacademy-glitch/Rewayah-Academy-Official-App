// La barre de selection d'une liste (promue de `lib/features/comptable/paiements/`
// vers le core par `ADM-20`, `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`
// section 4 : « promue vers `lib/core/widgets/`, jamais recopiee »).
//
// Collee en bas d'une page (`PageShell.actions`) des qu'une ligne est retenue.
// Elle dit **combien** de lignes sont retenues, jamais un total : un total est
// rendu par la source, l'ecran n'additionne rien (CPT-PAY-1, FI6).
//
// Deux gestes seulement, et un seul bouton plein :
//
//   * « Tout relacher » est un bouton discret (tertiaire) ;
//   * l'action de la selection est le seul bouton plein (K-56). **Un bouton qui
//     ne peut pas aboutir n'est pas rendu** : sans [onAction] (hors ligne,
//     destination absente, droit absent), la [phrase] dit pourquoi a sa place.
//
// L'ecran donne ses textes ; la barre ne contient aucun libelle propre, de sorte
// que le Comptable (« Payer la selection ») et les Candidatures (« Agir sur la
// selection ») partagent le meme composant.

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';

/// La barre de selection.
class BarreSelection extends StatelessWidget {
  /// Cree la barre.
  const BarreSelection({
    required this.titre,
    required this.phrase,
    required this.libelleRelacher,
    required this.onRelacher,
    this.libelleAction,
    this.onAction,
    this.avantActions,
    super.key,
  });

  /// Combien de lignes sont retenues (« 3 candidatures retenues »).
  final String titre;

  /// Une phrase sous le titre : ce que l'action fera, ou pourquoi elle n'est
  /// pas offerte (hors ligne, pas encore ouverte).
  final String phrase;

  /// Le libelle de « Tout relacher ».
  final String libelleRelacher;

  /// Relache toute la selection.
  final VoidCallback onRelacher;

  /// Le libelle de l'action de la selection.
  final String? libelleAction;

  /// L'action de la selection, ou `null` : elle n'est alors pas rendue (jamais
  /// grisee) et [phrase] dit pourquoi.
  final VoidCallback? onAction;

  /// Un complement pose entre la phrase et les boutons (l'export de la
  /// selection du Comptable).
  final Widget? avantActions;

  /// La cle de l'action de la selection.
  static const Key cleAction = ValueKey<String>('barre-selection-action');

  /// La cle de « Tout relacher ».
  static const Key cleRelacher = ValueKey<String>('barre-selection-relacher');

  /// La cle de la barre.
  static const Key cleBarre = ValueKey<String>('barre-selection');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? action = onAction;
    final Widget? complement = avantActions;
    return Semantics(
      key: cleBarre,
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            phrase,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          if (complement != null) ...<Widget>[complement, Ecart.vMd],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: <Widget>[
              ActionPrincipale(
                key: cleRelacher,
                libelle: libelleRelacher,
                niveau: NiveauAction.tertiaire,
                onPress: onRelacher,
              ),
              if (action != null && libelleAction != null)
                ActionPrincipale(
                  key: cleAction,
                  libelle: libelleAction!,
                  onPress: action,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
