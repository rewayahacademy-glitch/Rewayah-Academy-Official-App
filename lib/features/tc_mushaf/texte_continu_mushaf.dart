import 'package:flutter/material.dart';

import '../../core/tc_coran/metrique_texte_coran.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rosace_verset.dart';
import 'police_mushaf.dart';

/// Le rapport interligne / corps des rendus « lecture agrandie » et « focus »
/// avec la mise en page de Medine (MUSHAF-MODES, regle g). **Fixe**, calibre
/// sur la hauteur des signes empiles de UthmanicHafs : le meme d'une ligne a
/// l'autre, d'un verset a l'autre, a tous les zooms.
const double ratioInterligneModes = 2.0;

/// Les versets d'une page en **texte continu**, comme dans un Mushaf : un seul
/// flux, aligne a droite, a espacement naturel entre les mots (jamais
/// justifie), la rosace du numero **en ligne** a la fin de chaque verset, sans
/// marge entre deux versets au-dela de l'interligne.
///
/// La reference « sourate:verset » est dans l'etiquette semantique de chaque
/// rosace, pour les lecteurs d'ecran. Les versets de [surlignes] (references)
/// portent un fond discret : la plage que l'enseignant designe en classe.
class ColonneContinueMushaf extends StatelessWidget {
  /// Cree la colonne.
  const ColonneContinueMushaf({
    required this.versets,
    required this.zoom,
    required this.policeKfgqpc,
    this.surlignes = const <String>{},
    this.selectionnable = true,
    super.key,
  });

  /// Les versets, dans l'ordre : KFGQPC avec [policeKfgqpc], Tanzil sinon.
  final List<VersetTexte> versets;

  /// Le grossissement local du lecteur.
  final double zoom;

  /// Vrai : le texte est celui du KFGQPC et se dessine en UthmanicHafs. Faux :
  /// texte Tanzil simple, police arabe de l'application.
  final bool policeKfgqpc;

  /// Les references (« 17:105 ») a surligner.
  final Set<String> surlignes;

  /// Faux dans un feuilletage tactile : la zone de selection garde le geste
  /// horizontal.
  final bool selectionnable;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final AppPalette palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // [RESPONSIVE]
        final MetriqueTexteCoran metrique = MetriqueTexteCoran.calculer(
          largeurDisponible: contraintes.maxWidth,
          zoom: zoom,
          marge: gabarit.gouttiere,
          largeurMaximaleColonne: AppPage.largeurLecture,
        );
        final TextStyle style = palette.inkStrong.applyTo(
          policeKfgqpc
              ? AppTypography.mushaf15L(
                  taille: metrique.tailleTexte,
                  interligne: ratioInterligneModes,
                )
              : AppTypography.document(
                  taille: metrique.tailleTexte,
                  interligne: ratioInterligneModes,
                ),
        );
        final Widget texte = Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                for (final VersetTexte verset in versets) ...<InlineSpan>[
                  TextSpan(
                    text: verset.texte,
                    style: surlignes.contains(verset.reference)
                        ? TextStyle(
                            backgroundColor: palette.washAccent.background,
                          )
                        : null,
                  ),
                  // Une espace insecable : la rosace ne passe jamais seule sur
                  // une ligne, elle reste collee au dernier mot du verset.
                  const TextSpan(text: '\u00A0'),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Semantics(
                      label: verset.reference,
                      excludeSemantics: true,
                      // `UnconstrainedBox` : la rosace centre son chiffre par un
                      // `Container` a `alignment`, qui prendrait toute la
                      // largeur de la ligne et passerait seul sur la sienne.
                      child: UnconstrainedBox(
                        child: RosaceVerset(
                          numero: verset.numero,
                          echelle: metrique.echelleRosace,
                          encre: palette.inkAccent,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            // A droite, espacement naturel : jamais de justification etiree.
            textAlign: TextAlign.start,
            style: style,
            // Une interligne forcee : identique d'une ligne a l'autre, meme
            // quand un glyphe de repli est plus haut.
            strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
          ),
        );

        return SingleChildScrollView(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: gabarit.gouttiere,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: SizedBox(
              width: metrique.largeurColonne,
              child: selectionnable ? SelectionArea(child: texte) : texte,
            ),
          ),
        );
      },
    );
  }
}
