// Lot SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : la
// couverture d'un support, comme un livre pose sur une etagere.
//
// Directeur, 11/11/2026 (reprise) : « n'oublie pas de brander les couvertures
// aux styles et couleurs de l'academie ; le Coran, lui, doit avoir une
// couverture standard : si le complexe Roi Fahd n'en fournit pas, tu en
// choisis une qui est en arabe, compréhensible et familière à tous les
// musulmans du monde. »
//
// Deux maquettes, un seul composant :
// - **la collection de l'academie** : les violets de la marque
//   ([AppCouleursCouverture.academie]), le dos, un filet blanc, un repere
//   (« Etape 1 »), le titre dans la police des titres de l'application,
//   l'ornement de la marque en blanc. Ce qui distingue deux livres : le titre,
//   le repere et la nuance de violet, jamais une couleur etrangere ;
// - **le Coran** : violet profond de la marque, double filet lavande, medaillon, « القرآن الكريم »
//   en arabe dans la police KFGQPC Uthman Taha Naskh, l'edition dessous. Aucune
//   marque de l'academie (ce n'est pas un livre de l'academie), aucune image
//   d'un mushaf reel, aucun verset. Le KFGQPC ne publie aucune couverture
//   reutilisable (verifie le 11/11/2026 sur qurancomplex.gov.sa).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../tc_bibliotheque/couverture_ressource.dart';
import '../tc_bibliotheque/library_resource.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'brand_logo.dart' show FondLogo;
import 'ornement_marque.dart';

/// La couverture d'un support : un livre de la collection de l'academie, ou
/// la couverture standard du Coran.
///
/// **Aucune couleur n'est posee ici** : elles viennent de
/// [AppCouleursCouverture], identiques en clair et en sombre (une couverture
/// est un objet). Le titre ne se reduit que si la hauteur manque, jamais en
/// coupant un mot ; il est lu en entier, dans la langue de l'interface, par le
/// lecteur d'ecran.
class CouvertureSupport extends StatelessWidget {
  /// Cree une couverture.
  const CouvertureSupport({
    required this.titre,
    required this.couverture,
    this.mention,
    this.repere,
    super.key,
  });

  /// Le titre du support, dans la langue de l'interface : ecrit sur la
  /// couverture de l'academie, lu par le lecteur d'ecran (le Coran ecrit, lui,
  /// son titre arabe).
  final String titre;

  /// Le type (Coran ou non) et la nuance, calcules une fois pour toutes
  /// ([CouvertureRessource]) : la meme ressource a toujours la meme couverture.
  final CouvertureRessource couverture;

  /// Une mention courte sous le titre (« A valider »), ou `null`.
  final String? mention;

  /// Le repere du support dans le parcours (« Etape 1 »), ou `null`.
  final String? repere;

  /// Le rapport largeur sur hauteur : celui d'un livre, jamais un carre.
  static const double rapport = 3 / 4;

  /// La part du blanc reprise par le dos et le filet de l'academie.
  static const double opaciteFilet = 0.36;

  /// La paire d'une teinte de couverture du catalogue (`VignetteRessource`) :
  /// l'index 0 est celui du Coran (`surfaceQuran`), les autres viennent de
  /// `AppPalette.teintesIdentite` (decision D-18).
  static AppColorPair teinteDe(AppPalette palette, int index) =>
      index == 0 ? palette.surfaceQuran : palette.teinteCouverture(index - 1);

  /// La nuance de la collection de l'academie, stable pour un support.
  static AppColorPair nuanceAcademie(CouvertureRessource couverture) =>
      AppCouleursCouverture.academie[couverture.indexTeinte %
          AppCouleursCouverture.academie.length];

  /// Vrai pour la couverture du Coran.
  bool get coran => couverture.type == TypeRessource.quran;

  @override
  Widget build(BuildContext context) {
    final String? mention = this.mention;
    return Semantics(
      label: <String>[titre, ?repere, ?mention].join(', '),
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: rapport,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => coran
              ? _CouvertureCoran(largeur: c.maxWidth)
              : _CouvertureAcademie(
                  largeur: c.maxWidth,
                  titre: titre,
                  repere: repere,
                  mention: mention,
                  nuance: nuanceAcademie(couverture),
                ),
        ),
      ),
    );
  }
}

/// Un livre de l'academie : violet de la marque, dos, filet blanc, repere,
/// titre, ornement.
class _CouvertureAcademie extends StatelessWidget {
  const _CouvertureAcademie({
    required this.largeur,
    required this.titre,
    required this.repere,
    required this.mention,
    required this.nuance,
  });

  final double largeur;
  final String titre;
  final String? repere;
  final String? mention;
  final AppColorPair nuance;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Color filet = nuance.onBackground.withValues(
      alpha: CouvertureSupport.opaciteFilet,
    );
    final double dos = largeur / 12;
    final double marge = largeur / 16;
    final String? repere = this.repere;
    final String? mention = this.mention;
    return DecoratedBox(
      decoration: nuance.decoration(borderRadius: AppRadius.arrondiXs),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Le dos du livre, au debut de la ligne (a droite en arabe).
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: dos,
            child: ColoredBox(color: filet),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              dos + marge,
              marge,
              marge,
              marge,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(BorderSide(color: filet)),
                borderRadius: AppRadius.arrondiXs,
              ),
              child: Padding(
                padding: EdgeInsets.all(marge),
                child: _Ajuste(
                  mots: titre,
                  style: textes.titleMedium ?? const TextStyle(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (repere != null) ...<Widget>[
                        Text(
                          repere,
                          textAlign: TextAlign.center,
                          style: nuance.applyTo(
                            AppTypography.capitales(
                              textes.labelSmall ?? const TextStyle(),
                            ),
                          ),
                        ),
                        Ecart.vSm,
                      ],
                      Text(
                        titre,
                        textAlign: TextAlign.center,
                        style: nuance.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vMd,
                      // M-14 et M-28 : l'ornement officiel, blanc sur le
                      // violet de marque (README du logo : `blanc/` sur fond
                      // violet). Le logo, lui, ne se pose jamais dans une
                      // liste (README, « Placement »).
                      const OrnementMarque(fond: FondLogo.violet),
                      if (mention != null) ...<Widget>[
                        Ecart.vSm,
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(color: nuance.onBackground),
                            ),
                            borderRadius: AppRadius.arrondiFull,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              mention,
                              style: nuance.applyTo(
                                textes.labelSmall ?? const TextStyle(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La couverture standard du Coran : violet profond de la marque (directeur,
/// 11/11/2026 : la couleur de l'academie), double filet lavande, medaillon,
/// « القرآن الكريم » et l'edition, toujours en arabe.
class _CouvertureCoran extends StatelessWidget {
  const _CouvertureCoran({required this.largeur});

  final double largeur;

  @override
  Widget build(BuildContext context) {
    const AppColorPair fond = AppCouleursCouverture.coran;
    final Color filet = AppCouleursCouverture.filetCoran.asBorderSide().color;
    final double marge = largeur / 14;
    final String titre = t.salle.etagere.coranCouverture.titre;
    final String edition = t.salle.etagere.coranCouverture.edition;
    // Le titre arabe suit sa propre direction, quelle que soit la langue de
    // l'interface.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: fond.decoration(borderRadius: AppRadius.arrondiXs),
        child: Padding(
          padding: EdgeInsets.all(marge),
          // Le double filet, classique des couvertures de mushaf.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: filet, width: AppSpacing.xs / 2),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(marge / 2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: filet)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(marge / 2),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      // Le medaillon : un ovale a filet filet.
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: OvalBorder(side: BorderSide(color: filet)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(marge),
                          child: _Ajuste(
                            mots: titre,
                            style: _styleTitre,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  titre,
                                  key: const ValueKey<String>(
                                    'couverture-coran-titre',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: fond.applyTo(_styleTitre),
                                ),
                                Ecart.vXs,
                                Text(
                                  edition,
                                  textAlign: TextAlign.center,
                                  style: fond.applyTo(_styleEdition),
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
            ),
          ),
        ),
      ),
    );
  }

  /// Le titre arabe du Coran est un arabe de CONTENU : il s'ecrit dans la
  /// police du Coran, KFGQPC UthmanicHafs (`AppFontFamily.arabeMushaf`, decision
  /// du directeur du 13/11/2026), la police des documents arabes en repli
  /// (licence du Complexe : usage, copie et distribution gratuits, sans
  /// modification de la police). L'arabe d'interface ne change pas.
  static final TextStyle _styleTitre = AppTypography.mushaf15L(
    taille: AppSpacing.xxxl,
    interligne: 1.4,
  );

  static final TextStyle _styleEdition = AppTypography.mushaf15L(
    taille: AppSpacing.lg,
    interligne: 1.4,
  );
}

/// Pose [child] dans toute la largeur disponible, au moins celle du mot le
/// plus long de [mots] au [style] donne, puis le reduit si la place manque :
/// jamais un mot coupe, jamais un debordement.
class _Ajuste extends StatelessWidget {
  const _Ajuste({required this.mots, required this.style, required this.child});

  final String mots;
  final TextStyle style;
  final Widget child;

  double _motLePlusLong(BuildContext context) {
    double largeur = 0;
    for (final String mot in mots.split(RegExp(r'\s+'))) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      largeur = math.max(largeur, peintre.width.ceilToDouble());
      peintre.dispose();
    }
    return largeur;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) => FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: math.max(c.maxWidth, _motLePlusLong(context)),
        child: child,
      ),
    ),
  );
}
