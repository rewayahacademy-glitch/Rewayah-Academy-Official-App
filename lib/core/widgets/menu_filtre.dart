import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Une valeur proposee par un [MenuFiltre].
@immutable
class EntreeFiltre<T> {
  /// Cree une entree.
  const EntreeFiltre({
    required this.valeur,
    required this.libelle,
    this.compteur,
  });

  /// La valeur retenue. **Nulle pour l'entree « tous »**, qui relache le
  /// filtre.
  final T? valeur;

  /// Le libelle lisible.
  final String libelle;

  /// Combien d'elements portent cette valeur. Rendu a cote du libelle : c'est
  /// lui qui dit ou regarder.
  final int? compteur;
}

/// Un axe de filtre **ouvert**, rendu en menu et non en pastilles.
///
/// **Pourquoi ce composant existe**, et ce qu'il remplace : `ADM-04` rendait
/// une pastille par type d'evenement et une par acteur, `ADM-08` une par etat
/// et une par role. Le vocabulaire d'evenements vit en base et grandit a
/// chaque migration, la liste des acteurs grandit avec l'academie : le journal
/// portait donc une vingtaine de boutons qui repoussaient la liste sous le
/// pli, et l'operateur l'a dit sans detour le 18 septembre 2026.
///
/// La regle qui en sort, et qui vaut pour tout ecran d'administration :
///
///   * **un axe ferme se rend en pastilles** -- la periode a trois valeurs, un
///     etat de compte en a quatre : ce sont de vrais selecteurs, tout se voit
///     d'un coup d'oeil et un tap suffit ;
///   * **un axe ouvert se rend en menu** -- une liste qui grandit avec les
///     donnees ne peut pas s'etaler, sinon l'accent finit par decorer un
///     inventaire au lieu de porter la selection (registre produit : « accent
///     color used for primary actions, current selection, and state
///     indicators only, not decoration »).
///
/// `PopupMenuButton` et non `DropdownMenu` : un `DropdownMenu` est un champ de
/// saisie, et un filtre n'est pas une saisie. Le bouton porte la selection
/// courante, ce qui evite d'avoir a ouvrir le menu pour savoir ou l'on en est.
class MenuFiltre<T> extends StatelessWidget {
  /// Cree un menu de filtre.
  const MenuFiltre({
    required this.libelle,
    required this.valeur,
    required this.entrees,
    required this.onChoix,
    super.key,
  });

  /// Le nom de l'axe : « Événement », « Acteur », « Rôle ».
  final String libelle;

  /// La valeur courante. Nulle quand le filtre est relache.
  final T? valeur;

  /// Les valeurs proposees, l'entree « tous » comprise.
  final List<EntreeFiltre<T>> entrees;

  /// Ce qui se passe quand une valeur est choisie.
  final void Function(T? valeur) onChoix;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool actif = valeur != null;

    final EntreeFiltre<T>? retenue = entrees
        .where((EntreeFiltre<T> e) => e.valeur == valeur)
        .firstOrNull;

    // Le bouton dit l'axe quand rien n'est filtre, et la valeur retenue
    // sinon : sans cela il faudrait ouvrir le menu pour savoir ou l'on en est.
    final String texte = actif && retenue != null ? retenue.libelle : libelle;

    return PopupMenuButton<_Choix<T>>(
      tooltip: libelle,
      position: PopupMenuPosition.under,
      onSelected: (_Choix<T> choix) => onChoix(choix.valeur),
      itemBuilder: (BuildContext _) => <PopupMenuEntry<_Choix<T>>>[
        for (final EntreeFiltre<T> entree in entrees)
          PopupMenuItem<_Choix<T>>(
            // Enveloppee : `PopupMenuButton` ignore une valeur nulle et
            // n'appellerait jamais `onSelected` sur l'entree « tous ».
            value: _Choix<T>(entree.valeur),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(entree.libelle)),
                if (entree.compteur != null) ...<Widget>[
                  Ecart.hMd,
                  Text(
                    '${entree.compteur}',
                    style: palette.inkMuted.applyTo(
                      // Chiffres tabulaires : une colonne de comptes ne doit
                      // pas danser d'une ligne a l'autre.
                      (textes.bodySmall ?? const TextStyle()).copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: actif ? '$libelle : $texte' : libelle,
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppMetriques.of(context).cibleTactile,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: actif
                ? palette.washAccent.background
                : palette.surfaceRaised.background,
            // Le meme arrondi que `FilterPill` : les deux affordances de
            // filtre se lisent comme une seule famille.
            borderRadius: AppRadius.arrondiFull,
            border: Border.fromBorderSide(
              actif
                  ? palette.borderStrong.asBorderSide()
                  : palette.borderHairline.asBorderSide(),
            ),
          ),
          // K-54 : libelle et chevron centres dans le bouton, y compris quand
          // le parent l'etire.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    texte,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: (actif ? palette.inkAccent : palette.inkStrong)
                        .applyTo(textes.labelLarge ?? const TextStyle()),
                  ),
                ),
                Ecart.hXs,
                Icon(
                  // Vers le bas, la ou le menu s'ouvre. Un chevron vers la
                  // droite promettrait de mener ailleurs.
                  AppIcons.menuDeroulant.repos,
                  size: AppSpacing.lg,
                  color: (actif ? palette.inkAccent : palette.inkMuted)
                      .asIconTheme()
                      .color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'enveloppe d'une valeur de menu.
///
/// `PopupMenuButton` traite une valeur nulle comme « aucune valeur » et
/// n'appelle alors jamais `onSelected` : l'entree « tous » ne relacherait
/// jamais le filtre. L'envelopper rend la valeur nulle selectionnable.
@immutable
class _Choix<T> {
  const _Choix(this.valeur);

  final T? valeur;
}
