import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La case a cocher du produit : une ligne de table, la page entiere.
///
/// **Le seul point d'entree d'une case.** Elle sort de `Checkbox` de Material,
/// qui n'avait ni la cible tactile du mode, ni l'anneau de focus du produit, ni
/// l'etat partiel ; quatre fonctionnalites en recomposaient chacune une (lignes
/// de candidature, d'obligation, de consentement, recharge) sans geste ni
/// focus. Ici : un [Pressable] (survol, pression, anneau de focus de 2 points,
/// Entree et Espace), la cible tactile du mode d'interface (48, 72 en
/// Interface guidee), et **trois etats** :
///
///   * [valeur] vrai : cochee, **coche** dans la case ;
///   * [valeur] faux : vide ;
///   * [valeur] nul : **partielle** (une partie de la page est cochee), un
///     **trait** dans la case. Jamais l'etat d'une ligne seule.
///
/// **L'etat ne se lit jamais a la seule couleur** : la case cochee porte une
/// coche, la partielle un trait, la vide rien, et le lecteur d'ecran entend
/// `checked` ou `mixed`. La case vide a un contour fort (`borderStrong`, plus de
/// 3:1 contre la surface, dans les deux themes).
///
/// Le toucher donne la valeur **suivante** : vide ou partielle vers cochee,
/// cochee vers vide. **Une case qui ne peut pas aboutir n'est pas rendue** :
/// elle n'est jamais grisee, l'ecran decide de ne pas la poser (une ligne qu'on
/// ne peut pas retenir n'a pas de case, voir `SelectionCollection.estCochable`).
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class CaseACocher extends StatelessWidget {
  /// Cree une case.
  const CaseACocher({
    required this.valeur,
    required this.libelle,
    required this.onChange,
    super.key,
    this.focusNode,
  });

  /// Cochee (`true`), vide (`false`) ou partielle (`null`).
  final bool? valeur;

  /// Ce que dit le lecteur d'ecran (« Cocher Amina Diallo », « Cocher la
  /// page »). Jamais affiche.
  final String libelle;

  /// Recoit la valeur voulue : `true` pour cocher, `false` pour vider.
  final ValueChanged<bool> onChange;

  /// Le noeud de focus de la case, facultatif.
  final FocusNode? focusNode;

  /// Le cote de la case dessinee (la cible tactile l'entoure).
  static const double cote = AppSpacing.xxl;

  /// L'epaisseur du contour de la case vide.
  static const double epaisseurContour = 2;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    void basculer() => onChange(valeur != true);
    // `mixed` : l'etat partiel est annonce comme tel, pas comme « non cochee ».
    return Semantics(
      mixed: valeur == null,
      child: Pressable.selon(
        onPress: basculer,
        focusNode: focusNode,
        libelleSemantique: libelle,
        // Nul = partielle : l'etat `mixed` (ci-dessus) le dit, `checked` se tait.
        coche: valeur,
        arrondiFocus: AppRadius.arrondiFull,
        constructeur: (BuildContext contexte, EtatPression etat) {
          final bool plein = valeur != false;
          final double cible = AppMetriques.of(contexte).cibleTactile;
          return ExcludeSemantics(
            child: SizedBox(
              width: cible,
              height: cible,
              child: DecoratedBox(
                // Un disque doux au survol et a la pression : la cible se voit
                // avant le clic (meme geste que le declencheur d'un menu).
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: etat.survole || etat.presse
                      ? palette.washAccent.background
                      : null,
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: cote,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.arrondiXs,
                        color: plein
                            ? palette.surfacePrimary.background
                            : palette.surfaceRaised.background,
                        border: plein
                            ? null
                            : Border.fromBorderSide(
                                palette.borderStrong.asBorderSide(
                                  width: epaisseurContour,
                                ),
                              ),
                      ),
                      child: plein
                          ? Icon(
                              valeur == null
                                  ? AppIcons.moins.actif
                                  : AppIcons.succes.actif,
                              size: AppSpacing.lg,
                              color: palette.surfacePrimary.onBackground,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
