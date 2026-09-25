import 'package:flutter/material.dart';

import '../mouvement/mouvement.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// La surface elevee du produit : `surfaceRaised`, `borderHairline`,
/// `elevation1`, arrondi du mode courant.
///
/// **Seul point d'entree d'une surface de contenu.** Aucun ecran ne compose sa
/// propre [BoxDecoration] : `docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 6
/// dit que les surfaces viennent d'`AppCard` et de `PageShell`.
///
/// Deux regles portees par le composant et non par la vigilance :
///
/// - **une surface elevee porte un filet ET une ombre**, jamais l'un des deux
///   seul. C'est [AppElevation.avecFilet] qui compose les deux ;
/// - **une carte n'est jamais posee sur une carte.** Deux plans suffisent a
///   tout le produit ; un troisieme signifie que la hierarchie de l'ecran est
///   fausse. Cette regle-la se tient en revue, aucun composant ne peut la
///   verifier seul (`01-systeme-visuel.md` section 2).
class AppCard extends StatelessWidget {
  /// Cree une carte.
  const AppCard({
    required this.child,
    super.key,
    this.surface,
    this.onPress,
    this.libelleSemantique,
    this.selectionnee = false,
    this.contourFort = false,
    this.marge,
    this.dominante = false,
    this.entete,
    this.actions,
  });

  /// Le contenu de la carte.
  final Widget child;

  /// La paire de la carte. Par defaut, la surface elevee.
  ///
  /// C'est une paire : impossible de poser un fond sans son texte. Une carte
  /// qui porte un etat prend la paire douce de sa famille, `washWarning` ou
  /// `washAlert`, jamais un aplat sature (`01-systeme-visuel.md` section 3).
  final AppColorPair? surface;

  /// Action au tap. Passe par [Pressable], jamais par un `onTap` nu.
  final VoidCallback? onPress;

  /// Libelle lu par les technologies d'assistance.
  final String? libelleSemantique;

  /// Vrai quand la carte est retenue. Le contour passe alors en
  /// `borderStrong`, **la seule bordure porteuse de sens**.
  final bool selectionnee;

  /// Vrai quand la carte porte un etat qui demande un contour porteur de sens
  /// au repos, sans etre une selection : c'est le cas de la carte enfant « sans
  /// planning », dont `07-catalogue-composants.md` section 3 fixe le registre a
  /// « fond `washWarning`, encre `inkWarning`, contour `borderStrong` ».
  final bool contourFort;

  /// Marge interne. Par defaut, celle du mode courant.
  final double? marge;

  /// The single visually dominant card allowed on a page.
  final bool dominante;

  /// Optional structural zones. They avoid screens rebuilding their own card.
  final Widget? entete;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final AppColorPair paire = selectionnee
        ? palette.washAccent
        : surface ?? palette.surfaceRaised;

    if (onPress == null) {
      return _corps(
        context,
        palette,
        metriques,
        paire,
        const EtatPression(actif: false),
      );
    }

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: libelleSemantique,
      respecterCibleTactile: false,
      arrondiFocus: dominante ? AppRadius.arrondiLg : AppRadius.arrondiMd,
      constructeur: (BuildContext contexte, EtatPression etat) =>
          _corps(contexte, palette, metriques, paire, etat),
    );
  }

  Widget _corps(
    BuildContext context,
    AppPalette palette,
    AppMetriques metriques,
    AppColorPair paire,
    EtatPression etat,
  ) {
    // Selection, survol et pression changent fond et contour en fondu court
    // (P2-16) ; l'enfoncement 0.98 reste celui de [Pressable], sans doublon.
    return AnimatedContainer(
      duration: Mouvement.duree(context, Mouvement.court),
      curve: Mouvement.entree,
      constraints: BoxConstraints(minHeight: metriques.cibleTactile),
      padding: EdgeInsets.all(
        marge ??
            (MediaQuery.sizeOf(context).width < AppGabarit.seuilTablette
                ? AppSpacing.xl
                : AppSpacing.xxl),
      ),
      decoration: BoxDecoration(
        color: etat.survole || etat.presse
            ? Color.alphaBlend(
                palette.calqueInteraction(presse: etat.presse),
                paire.background,
              )
            : paire.background,
        borderRadius: dominante ? AppRadius.arrondiLg : AppRadius.arrondiMd,
        // The decorative border only becomes semantic for an explicit state.
        border: Border.fromBorderSide(
          (selectionnee
                  ? palette.inkAccent.asBorderSide(width: 2)
                  : (contourFort || etat.survole || etat.presse
                            ? palette.borderStrong
                            : palette.contourCarte)
                        .asBorderSide())
              .copyWith(),
        ),
        boxShadow: dominante && !palette.estSombre
            ? AppElevation.niveau1(palette.ombre)
            : AppElevation.niveau0,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: paire.onBackground),
        child: IconTheme.merge(
          data: IconThemeData(color: paire.onBackground),
          child: entete == null && actions == null
              ? child
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (entete != null) ...<Widget>[entete!, Ecart.vLg],
                    child,
                    if (actions != null) ...<Widget>[Ecart.vLg, actions!],
                  ],
                ),
        ),
      ),
    );
  }
}
