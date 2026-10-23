// La carte a partager (CAND-06) : une image au format story (9:16), lue par la
// personne qui voudrait apprendre le Coran, pas par celle qui la partage.
//
// **Redessinee le 22/10/2026** sur la direction du directeur (la carte d'avant
// etait « trop nulle et moche ») : un fond violet profond ; le symbole contour
// officiel tres agrandi, coupe par les bords, en filigrane tamise ; et,
// subtilement, le portail, pour dire l'eleve qui entre dans la lumiere du Coran
// et du savoir. Typographie suisse : peu d'elements, beaucoup de vide, tout
// aligne au debut de la ligne. **Le 23/10/2026**, la lumiere et les tenebres : le
// faisceau de la porte part du seuil en droites et s'eteint dans l'obscurite des
// bords (`decor_carte.dart`).
//
// Dans l'ordre de lecture : le logo blanc ; un titre court sur ce que l'eleve y
// gagne et sa ligne ; la scene du portail avec la signature arabe de la marque
// (M-26) ; l'appel « Decouvrir l'offre » avec son QR et le lien ; enfin, tout en
// bas et discret, le hadith, sa traduction et sa source. **Aucun prix**, aucune
// promesse, jamais l'academie comme motif.
//
// **Deux variantes** (`VarianteCarte`, lue sur le profil de la personne qui
// partage, jamais devinee) : les hommes (et le genre inconnu), sans personnage ;
// les femmes, une teinte plus douce et, tres discrete, une fine branche fleurie
// dans la penombre au bord du faisceau, sans aucun personnage (directeur,
// 23/10/2026). Les deux variantes ont la meme scene : seule la teinte change.
// **Quatre langues** (`LangueCarte`) : francais, anglais, portugais, arabe ; en
// arabe le texte se met en miroir, jamais le logo ni le symbole.
//
// Rendue par Flutter, puis exportee en PNG (`rendu_carte.dart`) : elle ne suit
// donc ni le theme de l'ecran, ni la taille de texte de l'appareil, ni
// l'interface guidee, ni la langue de l'application. Elle porte ses propres
// couleurs (`AppPaletteCarte`) et ses textes (`textes_carte.dart`).
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/partage_offre/lien_offre.dart';
import '../../core/partage_offre/personnalisation_carte.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_logo.dart';
import 'decor_carte.dart';
import 'textes_carte.dart';

/// La carte, a sa taille d'export : 360 x 640 points logiques, soit
/// 1080 x 1920 pixels a [echelleExport].
class CartePartage extends StatelessWidget {
  /// Cree la carte pour [lien], dans [langue], pour la [variante] de la
  /// personne qui partage.
  const CartePartage({
    required this.lien,
    required this.langue,
    this.variante = VarianteCarte.hommes,
    super.key,
  });

  /// Le lien de l'offre : imprime sous le QR et encode dedans.
  final Uri lien;

  /// La langue de la carte.
  final LangueCarte langue;

  /// La variante : hommes (et genre inconnu) ou femmes.
  final VarianteCarte variante;

  /// La largeur de la carte, en points logiques.
  static const double largeur = 360;

  /// La hauteur de la carte : le format story, 9:16.
  static const double hauteur = 640;

  /// Les pixels par point de l'export : 360 x 3 = 1080, 640 x 3 = 1920.
  static const double echelleExport = 3;

  /// Le cote du QR, sans sa plaque blanche.
  static const double coteQr = 68;

  /// La hauteur de la zone du titre et de sa ligne.
  static const double hauteurTitre = 112;

  /// La hauteur de la bande du portail : de la fin du titre au QR.
  static const double hauteurScene = 228;

  /// La hauteur de la ligne de la signature arabe (24 points d'interligne).
  static const double hauteurLigneSignature = 24;

  /// Le milieu de la porte, sur la carte : la signature s'y aligne.
  static final double yPorte = GeometrieScene(const Size(largeur, hauteur))
      .porte
      .center
      .dy;

  /// La largeur utile : la carte moins ses deux marges.
  static const double largeurUtile = largeur - 2 * AppSpacing.xxl;

  /// La taille du hadith, en points : un rappel, pas le message (60 pixels a
  /// l'export).
  static const double tailleHadith = 20;

  /// La marge du logo : sa zone de protection (25 pour cent de sa hauteur) est
  /// comprise dans son composant, donc le dessin tombe sur la marge du texte.
  static const double margeLogo =
      AppSpacing.xxl - BrandLogo.minimumHorizontal * BrandLogo.zoneProtection;

  /// Le haut du titre : la marge, le logo, sa zone de protection du bas, puis
  /// une respiration.
  static const double hautTitre =
      AppSpacing.xxl +
      BrandLogo.minimumHorizontal * (1 + BrandLogo.zoneProtection) +
      AppSpacing.xl;

  /// Le haut de la bande du portail : juste sous le titre.
  static const double hautScene = hautTitre + hauteurTitre;

  /// La cle du titre (ce que l'eleve y gagne).
  static const Key titreKey = ValueKey<String>('carte-titre');

  /// La cle de la ligne sous le titre.
  static const Key sousTitreKey = ValueKey<String>('carte-sous-titre');

  /// La cle de la signature arabe de la marque.
  static const Key signatureKey = ValueKey<String>('carte-signature');

  /// La cle de l'appel « Decouvrir l'offre ».
  static const Key decouvrirKey = ValueKey<String>('carte-decouvrir');

  /// La cle du hadith.
  static const Key hadithKey = ValueKey<String>('carte-hadith');

  /// La cle de la traduction du hadith (absente en arabe).
  static const Key traductionKey = ValueKey<String>('carte-traduction');

  /// La cle de la reference du hadith.
  static const Key referenceKey = ValueKey<String>('carte-reference');

  /// La cle du code QR.
  static const Key qrKey = ValueKey<String>('carte-qr');

  /// La cle du lien imprime.
  static const Key lienKey = ValueKey<String>('carte-lien');

  /// La cle du filigrane.
  static const Key filigraneKey = ValueKey<String>('carte-filigrane');

  /// La cle de la scene du portail.
  static const Key sceneKey = ValueKey<String>('carte-scene');

  /// La cle du logo.
  static const Key logoKey = ValueKey<String>('carte-logo');

  /// La cle de la zone de protection du logo : une zone libre, dans les
  /// tenebres.
  static const Key zoneLogoKey = ValueKey<String>('carte-zone-logo');

  @override
  Widget build(BuildContext context) {
    final AppPaletteCarte couleurs = variante == VarianteCarte.femmes
        ? AppPaletteCarte.femmes
        : AppPaletteCarte.hommes;
    final TextesCarte c = textesCarte[langue]!;
    final TextTheme textes = AppTypography.standard;
    final bool rtl = langue.droiteAGauche;
    final String? traduction = c.traduction;

    final TextStyle styleTitre = couleurs.fond.applyTo(textes.headlineSmall!);
    final TextStyle styleSousTitre = couleurs.encreDouce.applyTo(
      textes.bodyLarge!,
    );
    final TextStyle styleSignature = couleurs.fond.applyTo(textes.titleMedium!);
    final TextStyle styleDecouvrir = couleurs.fond.applyTo(textes.titleMedium!);
    final TextStyle styleLien = couleurs.encreDouce.applyTo(textes.bodyMedium!);
    final TextStyle styleHadith = couleurs.encreDouce.applyTo(
      AppTypography.document(taille: tailleHadith, interligne: 1.4),
    );
    final TextStyle styleSource = couleurs.encreDouce.applyTo(
      textes.bodySmall!,
    );
    // Tout s'aligne au debut de la ligne (a gauche en francais et en anglais, a
    // droite en arabe). Le hadith s'ecrit de droite a gauche dans toutes les
    // langues, mais se place au debut de la ligne comme le reste.
    final TextAlign debut = rtl ? TextAlign.right : TextAlign.left;

    final String libelle = <String>[
      t.recrutement.partage.apercu,
      c.titre,
      c.sousTitre,
      signatureArabe,
      c.decouvrir,
      lienLisible(lien),
      hadithArabe,
      ?traduction,
      c.reference,
    ].join('. ');

    final Widget titre = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(c.titre, key: titreKey, textAlign: debut, style: styleTitre),
        Ecart.vSm,
        Text(
          c.sousTitre,
          key: sousTitreKey,
          textAlign: debut,
          style: styleSousTitre,
        ),
      ],
    );

    final Widget hadith = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          hadithArabe,
          key: hadithKey,
          textAlign: debut,
          textDirection: TextDirection.rtl,
          style: styleHadith,
        ),
        if (traduction != null)
          Text(
            traduction,
            key: traductionKey,
            textAlign: debut,
            style: styleSource,
          ),
        Text(
          c.reference,
          key: referenceKey,
          textAlign: debut,
          style: styleSource,
        ),
      ],
    );

    return MediaQuery(
      // Une image ne grossit pas avec le texte de l'appareil.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      // La carte a son propre sens de lecture, celui de sa langue : une carte
      // arabe se met en miroir meme dans une application en francais.
      child: Directionality(
        textDirection: langue.sens,
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
                child: ClipRect(
                  child: DecoratedBox(
                    decoration: couleurs.fond.decoration(),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: FiligraneCarte(
                            key: filigraneKey,
                            couleurs: couleurs,
                          ),
                        ),
                        // La scene du portail : les tenebres, la porte, son halo et
                        // son faisceau, sur toute la carte, sous le texte. Les
                        // textes ne sont jamais retournes : seule la scene se met
                        // en miroir en arabe.
                        Positioned.fill(
                          child: ScenePortail(
                            key: sceneKey,
                            couleurs: couleurs,
                            variante: variante,
                          ),
                        ),
                        // La signature arabe de la marque, pres de la porte : a la
                        // hauteur de son milieu, au debut de la ligne.
                        PositionedDirectional(
                          top: yPorte - hauteurLigneSignature / 2,
                          start: AppSpacing.xxl,
                          child: Text(
                            signatureArabe,
                            key: signatureKey,
                            textDirection: TextDirection.rtl,
                            style: styleSignature,
                          ),
                        ),
                        // Le logo blanc dans les tenebres, au debut de la ligne
                        // (a droite en arabe, sans se retourner). Sa zone de
                        // protection (25 pour cent de sa hauteur, comprise dans le
                        // composant) est libre : le filigrane ne la traverse
                        // jamais, et c'est le coin le plus sombre de la carte.
                        const PositionedDirectional(
                          top: margeLogo,
                          start: margeLogo,
                          child: SizedBox(
                            key: zoneLogoKey,
                            child: BrandLogo(
                              key: logoKey,
                              variante: VarianteLogo.horizontal,
                              hauteur: BrandLogo.minimumHorizontal,
                              fond: FondLogo.violet,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.xxl,
                            hautTitre,
                            AppSpacing.xxl,
                            AppSpacing.xxl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                height: hauteurTitre,
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.topStart,
                                  child: SizedBox(
                                    width: largeurUtile,
                                    child: titre,
                                  ),
                                ),
                              ),
                              // La bande du portail : vide, entre le titre et l'appel ;
                              // la scene, sur toute la carte, y pose la porte.
                              const SizedBox(
                                height: hauteurScene,
                                width: double.infinity,
                              ),
                              Ecart.vSm,
                              _Appel(
                                lien: lien,
                                texte: c.decouvrir,
                                styleDecouvrir: styleDecouvrir,
                                styleLien: styleLien,
                              ),
                              // Le hadith, tout en bas ; si un texte plus long ne
                              // tenait pas, il se reduit au lieu de deborder.
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.bottomStart,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.bottomStart,
                                    child: SizedBox(
                                      width: largeurUtile,
                                      child: hadith,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

/// L'appel : le QR sur sa plaque blanche, « Decouvrir l'offre » et le lien.
class _Appel extends StatelessWidget {
  const _Appel({
    required this.lien,
    required this.texte,
    required this.styleDecouvrir,
    required this.styleLien,
  });

  final Uri lien;
  final String texte;
  final TextStyle styleDecouvrir;
  final TextStyle styleLien;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _Qr(lien: lien),
      Ecart.hLg,
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(texte, key: CartePartage.decouvrirKey, style: styleDecouvrir),
            Ecart.vXs,
            // L'adresse se lit de gauche a droite, et se reduit plutot que de
            // se couper.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  lienLisible(lien),
                  key: CartePartage.lienKey,
                  maxLines: 1,
                  style: styleLien,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Le QR : noir sur blanc dans tous les cas (`AppPalette.contenuQr`), avec sa
/// marge blanche, sur le fond violet.
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
        // Sa marge blanche : 12 points, quatre modules et plus (la zone de
        // silence que demande un lecteur de QR).
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
