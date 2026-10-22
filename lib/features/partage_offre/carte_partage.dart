// La carte a partager (CAND-06) : une image au format story (9:16), lue par la
// personne qui voudrait apprendre le Coran, pas par celle qui la partage.
//
// **Elle parle de l'interet de l'eleve d'abord** (consigne du directeur du
// 22/10/2026, apres coup : « il faut leur parler de l'interet que l'eleve va
// avoir. Pas Rewayah Academy »). Dans l'ordre de lecture : le logo ; un titre
// sur ce que l'eleve y gagne (apprendre le Coran en ligne, en petite classe) ;
// trois lignes vraies tirees des encarts decides (le meme enseignant, trois
// seances par semaine a heure fixe ; les enfants des 6 ans et les adultes ; les
// langues) ; l'appel « Decouvrir l'offre » avec son QR et le lien ; enfin, en
// petit, le hadith. **Aucun prix** (ils restent sur le site public), aucune
// promesse en plus.
//
// Rendue par Flutter, puis exportee en PNG (`rendu_carte.dart`) : elle ne suit
// donc ni le theme de l'ecran, ni la taille de texte de l'appareil, ni
// l'interface guidee. Elle porte ses propres jetons (palette claire, echelle
// standard) pour qu'elle soit la meme pour tous, en clair comme en sombre.
// Seule la langue de l'interface change son texte.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/partage_offre/lien_offre.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_logo.dart';

/// La carte, a sa taille d'export : 360 x 640 points logiques, soit
/// 1080 x 1920 pixels a [echelleExport].
class CartePartage extends StatelessWidget {
  /// Cree la carte pour [lien].
  const CartePartage({required this.lien, super.key});

  /// Le lien de l'offre : imprime sous le QR et encode dedans.
  final Uri lien;

  /// La largeur de la carte, en points logiques.
  static const double largeur = 360;

  /// La hauteur de la carte : le format story, 9:16.
  static const double hauteur = 640;

  /// Les pixels par point de l'export : 360 x 3 = 1080, 640 x 3 = 1920.
  static const double echelleExport = 3;

  /// Le cote du QR, sans sa marge blanche.
  static const double coteQr = 76;

  /// La largeur utile de l'arche : la carte moins ses marges et celles de
  /// l'arche.
  static const double largeurArche =
      largeur - 2 * AppSpacing.xxl - 2 * AppSpacing.xl;

  /// Le retrait du haut de l'arche : sous la courbe, la corde est assez large
  /// pour la premiere ligne du titre (une ligne plus large que la corde
  /// passerait de l'encre foncee sur le violet de la carte).
  static const double retraitArche = 68;

  /// La taille du hadith, en points : un rappel, pas le message.
  static const double tailleHadith = 24;

  /// La cle du titre (ce que l'eleve y gagne).
  static const Key titreKey = ValueKey<String>('carte-titre');

  /// La cle de la ligne du meme enseignant et des trois seances.
  static const Key enseignantKey = ValueKey<String>('carte-enseignant');

  /// La cle de la ligne des enfants et des adultes.
  static const Key publicsKey = ValueKey<String>('carte-publics');

  /// La cle de la ligne des langues.
  static const Key languesKey = ValueKey<String>('carte-langues');

  /// La cle de l'appel « Decouvrir l'offre ».
  static const Key decouvrirKey = ValueKey<String>('carte-decouvrir');

  /// La cle du hadith.
  static const Key hadithKey = ValueKey<String>('carte-hadith');

  /// La cle de la traduction du hadith (absente quand la langue n'en a pas).
  static const Key traductionKey = ValueKey<String>('carte-traduction');

  /// La cle de la reference du hadith.
  static const Key referenceKey = ValueKey<String>('carte-reference');

  /// La cle du code QR.
  static const Key qrKey = ValueKey<String>('carte-qr');

  /// La cle du lien imprime.
  static const Key lienKey = ValueKey<String>('carte-lien');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.claire();
    final TextTheme textes = AppTypography.standard;
    final AppColorPair marque = palette.surfacePrimary;
    final AppColorPair arche = palette.washAccent;
    final c = t.recrutement.partage.carte;
    final String traduction = c.traduction;

    final TextStyle styleTitre = arche.applyTo(textes.headlineSmall!);
    final TextStyle styleLigne = arche.applyTo(textes.bodyLarge!);
    final TextStyle styleDecouvrir = marque.applyTo(textes.titleMedium!);
    final TextStyle styleLien = marque.applyTo(textes.bodyMedium!);
    // Le hadith est en blanc sur le violet : la lavande (3,97:1) ne tient pas
    // pour un texte de cette taille.
    final TextStyle styleHadith = marque.applyTo(
      AppTypography.document(taille: tailleHadith, interligne: 1.5),
    );
    final TextStyle styleSource = marque.applyTo(textes.bodySmall!);

    Widget ligne(Key cle, String texte) =>
        Text(texte, key: cle, textAlign: TextAlign.center, style: styleLigne);

    // Ce que l'eleve y gagne, dans l'arche : un titre, puis trois lignes.
    final Widget gain = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          c.titre,
          key: titreKey,
          textAlign: TextAlign.center,
          style: styleTitre,
        ),
        Ecart.vMd,
        ligne(enseignantKey, c.enseignant),
        Ecart.vMd,
        ligne(publicsKey, c.publics),
        Ecart.vMd,
        ligne(languesKey, c.langues),
      ],
    );

    // Le hadith, en bas et en petit. Il s'ecrit de droite a gauche, quelle que
    // soit la langue de l'interface.
    final Widget hadith = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          c.hadith,
          key: hadithKey,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: styleHadith,
        ),
        if (traduction.isNotEmpty)
          Text(
            traduction,
            key: traductionKey,
            textAlign: TextAlign.center,
            style: styleSource,
          ),
        Text(
          c.reference,
          key: referenceKey,
          textAlign: TextAlign.center,
          style: styleSource,
        ),
      ],
    );

    final String libelle = <String>[
      t.recrutement.partage.apercu,
      c.titre,
      c.enseignant,
      c.publics,
      c.langues,
      c.decouvrir,
      lienLisible(lien),
      c.hadith,
      if (traduction.isNotEmpty) traduction,
      c.reference,
    ].join('. ');

    return MediaQuery(
      // Une image ne grossit pas avec le texte de l'appareil.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      // Le style de texte par defaut est le sien : l'image ne herite de rien
      // de la page qui la porte (ni souligne, ni famille de repli).
      child: DefaultTextStyle(
        style: textes.bodyMedium!,
        child: Semantics(
          image: true,
          label: libelle,
          child: ExcludeSemantics(
            child: SizedBox(
              width: largeur,
              height: hauteur,
              child: DecoratedBox(
                decoration: marque.decoration(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Le logo blanc sur la bande violette, au debut de la
                      // ligne (a droite en arabe, sans se retourner).
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: BrandLogo(
                          variante: VarianteLogo.horizontal,
                          hauteur: BrandLogo.minimumHorizontal,
                          fond: FondLogo.violet,
                        ),
                      ),
                      Ecart.vXs,
                      // L'arche : un demi-cercle en haut, le seul motif du
                      // symbole et du site. Elle porte ce que l'eleve y gagne.
                      Expanded(
                        child: DecoratedBox(
                          decoration: arche.decoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.full),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpacing.xl,
                              retraitArche,
                              AppSpacing.xl,
                              AppSpacing.lg,
                            ),
                            // Si un texte plus long ne tenait pas, l'arche le
                            // reduit au lieu de le couper : une image ne
                            // deborde jamais.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(width: largeurArche, child: gain),
                            ),
                          ),
                        ),
                      ),
                      Ecart.vMd,
                      Row(
                        children: <Widget>[
                          _Qr(lien: lien),
                          Ecart.hLg,
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  c.decouvrir,
                                  key: decouvrirKey,
                                  style: styleDecouvrir,
                                ),
                                Ecart.vXs,
                                // L'adresse se lit de gauche a droite, et se
                                // reduit plutot que de se couper.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      lienLisible(lien),
                                      key: lienKey,
                                      maxLines: 1,
                                      style: styleLien,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Ecart.vMd,
                      FittedBox(fit: BoxFit.scaleDown, child: hadith),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le QR : noir sur blanc dans tous les cas (`AppPalette.contenuQr`), avec sa
/// marge blanche, sur la bande violette.
class _Qr extends StatelessWidget {
  const _Qr({required this.lien});

  final Uri lien;

  @override
  Widget build(BuildContext context) {
    final AppColorPair qr = AppPalette.claire().contenuQr;
    return DecoratedBox(
      key: CartePartage.qrKey,
      decoration: qr.decoration(borderRadius: AppRadius.arrondiSm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: QrImageView(
          data: lien.toString(),
          padding: EdgeInsets.zero,
          size: CartePartage.coteQr,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          backgroundColor: qr.background,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: qr.onBackground,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: qr.onBackground,
          ),
        ),
      ),
    );
  }
}
