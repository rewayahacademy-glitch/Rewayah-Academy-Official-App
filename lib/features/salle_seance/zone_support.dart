// Le support partage, dominant (CLV-04, 05, 06).
//
// Une carte claire, dans les deux themes : le support est un document, lu
// comme sur papier (images). La vignette video de l'enseignante est posee en
// coin haut droit, retrait de 12 ; c'est le seul chevauchement admis. Le
// contenu defile au pouce. Sans support : la video au centre et une phrase.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'vignette_video.dart';
import 'vue_seance.dart';

/// Le support et la vignette video.
class ZoneSupport extends StatelessWidget {
  const ZoneSupport({required this.vue, this.zoom = 1, super.key});

  final VueSeance vue;

  /// Le zoom local (1 = 100 %), qui n'agit que sur cet ecran.
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final SupportSeance? support = vue.support;
    if (support == null) return _RienPartage(vue: vue);
    final Gabarit gabarit = AppGabarit.de(context);
    // Le support est le document de l'enseignante, le meme pour tous : il
    // garde l'echelle standard, meme en guidee (images CLV-05 : texte de la
    // taille de CLV-04). Seules les commandes de la guidee grandissent.
    const InterfaceMode mode = InterfaceMode.standard;
    // Guidee desktop (Q8) : la video a cote du support, jamais par-dessus.
    final bool aCote = vue.videoACoteDuSupport(gabarit);
    final double largeurVignette = MesuresVignette.largeur(
      gabarit,
      guidee: vue.vignetteAgrandie,
    );
    // Guidee web etroit (image CLV-04-05-06 web etroit) : la grande vignette
    // descend jusqu'a l'encadre, qui se range a cote d'elle ; la carte
    // s'arrete apres son contenu, un espace la separe du dock.
    final bool colonneGuidee =
        vue.vignetteAgrandie && gabarit == Gabarit.tablette && !aCote;
    // La carte lit le theme clair, quel que soit le theme de l'ecran.
    final Widget carte = Theme(
      data: AppTheme.pour(mode, Brightness.light),
      child: Builder(
        builder: (BuildContext contexte) {
          final AppPalette palette = AppPalette.of(contexte);
          final Widget defilement = MediaQuery(
            data: MediaQuery.of(contexte).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.textScalerOf(contexte).scale(1) * zoom,
              ),
            ),
            child: _FonduBas(
              couleur: palette.surfaceRaised.background,
              child: SingleChildScrollView(
                key: const ValueKey<String>('support-defilement'),
                padding: EdgeInsets.all(_marge(gabarit)),
                child: _Contenu(
                  support: support,
                  gabarit: gabarit,
                  largeurVignette: aCote ? 0 : largeurVignette,
                  encadreACote: colonneGuidee,
                ),
              ),
            ),
          );
          return DecoratedBox(
            key: const ValueKey<String>('zone-support'),
            decoration: palette.surfaceRaised
                .decoration(borderRadius: AppRadius.arrondiLg)
                .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
            child: ClipRRect(
              borderRadius: AppRadius.arrondiLg,
              child: Stack(
                children: <Widget>[
                  // Ajustee : la carte prend la hauteur de son contenu,
                  // bornee par la place disponible (puis elle defile).
                  if (colonneGuidee)
                    defilement
                  else
                    Positioned.fill(child: defilement),
                  if (!aCote)
                    PositionedDirectional(
                      top: MesuresVignette.retrait,
                      end: MesuresVignette.retrait,
                      // La video garde le theme de l'ecran.
                      child: Theme(
                        data: Theme.of(context),
                        child: VignetteVideo(
                          vue: vue,
                          largeur: largeurVignette,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (colonneGuidee) {
      return Align(alignment: Alignment.topCenter, child: carte);
    }
    if (gabarit != Gabarit.desktop) return carte;
    // Desktop : la carte est sertie dans un cadre du theme de l'ecran (le
    // lisere sombre de CLV-04), qui la detache du fond en clair comme en
    // sombre.
    final Widget cadre = _Serti(
      key: const ValueKey<String>('cadre-support'),
      child: carte,
    );
    if (!aCote) return cadre;
    // La colonne de la video, a droite du support (image CLV-05) : sertie
    // comme lui, en haut, le reste de la colonne laisse vide.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: cadre),
        Ecart.hLg,
        _Serti(
          key: const ValueKey<String>('colonne-video'),
          child: VignetteVideo(vue: vue, largeur: largeurVignette),
        ),
      ],
    );
  }
}

/// Le cadre du theme de l'ecran qui sertit la carte en desktop (le lisere
/// sombre de CLV-04), et la video de la guidee a cote d'elle (CLV-05).
class _Serti extends StatelessWidget {
  const _Serti({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.lg + _serti),
        ),
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(padding: const EdgeInsets.all(_serti), child: child),
    );
  }
}

/// L'epaisseur du cadre qui sertit la carte en desktop.
const double _serti = AppSpacing.sm;

/// Un fondu en bas de la zone qui defile : une ligne coupee par l'arrondi de
/// la carte s'efface au lieu de s'arreter net. Sa hauteur egale la plus
/// petite marge interieure : en fin de defilement, il ne couvre que la marge.
class _FonduBas extends StatelessWidget {
  const _FonduBas({required this.couleur, required this.child});

  /// Une couleur opaque quelconque : seul son canal alpha compte.
  final Color couleur;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (Rect zone) {
      final double debut = zone.height <= 0
          ? 1
          : (1 - AppSpacing.xl / zone.height).clamp(0, 1);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[couleur, couleur, couleur.withValues(alpha: 0)],
        stops: <double>[0, debut, 1],
      ).createShader(zone);
    },
    child: child,
  );
}

double _marge(Gabarit gabarit) =>
    gabarit == Gabarit.desktop ? AppSpacing.section : AppSpacing.xl;

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.support,
    required this.gabarit,
    required this.largeurVignette,
    this.encadreACote = false,
  });

  final SupportSeance support;
  final Gabarit gabarit;

  /// La largeur de la vignette posee en coin ; 0 quand elle est a cote.
  final double largeurVignette;

  /// Guidee web etroit : les lignes et l'encadre restent dans la colonne a
  /// cote de la grande vignette (image CLV-04-05-06 web etroit).
  final bool encadreACote;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final bool large = gabarit == Gabarit.desktop;
    // La place laissee a la vignette sur les premieres lignes : aucun texte
    // ne passe dessous au repos.
    // Au telephone, l'ecart titre-vignette se resserre (images : ≈ 10).
    final double reserve = largeurVignette <= 0
        ? 0
        : math.max(
            0,
            MesuresVignette.retrait +
                largeurVignette +
                (gabarit == Gabarit.mobile ? AppSpacing.sm : AppSpacing.lg) -
                _marge(gabarit),
          );
    final Widget encadre = DecoratedBox(
      key: const ValueKey<String>('encadre-support'),
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiMd,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _largeurEncadre),
            child: Text(
              support.encadre,
              style: palette.inkAccent.applyTo(
                (large
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.bodyMedium) ??
                    const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    );
    final Widget entete = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Pastille(texte: support.chapitre),
        Ecart.vLg,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _largeurTitre),
          child: _TitreEquilibre(
            texte: support.titre,
            style: palette.inkStrong.applyTo(
              switch (gabarit) {
                    Gabarit.desktop => theme.textTheme.headlineLarge,
                    Gabarit.tablette => theme.textTheme.headlineSmall,
                    Gabarit.mobile => theme.textTheme.titleMedium,
                  } ??
                  const TextStyle(),
            ),
          ),
        ),
        Ecart.vXl,
        const _Ligne(fraction: 1),
        if (large) ...<Widget>[
          Ecart.vMd,
          const _Ligne(fraction: 0.86),
          Ecart.vMd,
          const _Ligne(fraction: 0.7),
        ],
        if (encadreACote) ...<Widget>[
          Ecart.vMd,
          const _Ligne(fraction: 1),
          Ecart.vMd,
          const _Ligne(fraction: 0.94),
          Ecart.vLg,
          encadre,
          Ecart.vLg,
          const _Ligne(fraction: 1),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: entete),
            if (large) ...<Widget>[Ecart.hXxl, const _Illustration()],
            SizedBox(
              width: reserve,
              height: large || largeurVignette <= 0
                  ? 0
                  : math.max(
                      0,
                      largeurVignette / MesuresVignette.ratio +
                          MesuresVignette.retrait -
                          _marge(gabarit),
                    ),
            ),
          ],
        ),
        if (!large && !encadreACote) ...<Widget>[
          Ecart.vMd,
          const _Ligne(fraction: 1),
          Ecart.vMd,
          const _Ligne(fraction: 0.7),
        ],
        if (!encadreACote) ...<Widget>[
          if (large) Ecart.vXxl else Ecart.vLg,
          encadre,
          if (large) Ecart.vXxl else Ecart.vLg,
          const _Ligne(fraction: 0.6),
        ],
        Ecart.vLg,
        for (int i = 0; i < support.points.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                SizedBox.square(
                  dimension: large
                      ? AppSpacing.xxxl + AppSpacing.sm
                      : AppSpacing.xxxl,
                  child: DecoratedBox(
                    decoration: palette.washAccent.decoration(
                      borderRadius: AppRadius.arrondiFull,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: palette.washAccent.applyTo(
                          theme.textTheme.titleSmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ),
                ),
                if (large) Ecart.hXl else Ecart.hLg,
                Expanded(
                  child: Text(
                    support.points[i],
                    style: palette.inkStrong.applyTo(
                      (large
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.bodyMedium) ??
                          const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (large) Ecart.vXxl else Ecart.vLg,
        const _Ligne(fraction: 1),
        Ecart.vMd,
        const _Ligne(fraction: 0.66),
      ],
    );
  }
}

/// La largeur maximale du titre du support : en desktop, il tient sur deux
/// lignes comme sur les images.
const double _largeurTitre = 400;

/// Un titre aux lignes equilibrees (comme `text-wrap: balance`) : meme
/// nombre de lignes qu'a pleine largeur, mais dans la plus petite largeur
/// qui le garde. « Les bonnes / manieres en classe » plutot que « Les bonnes
/// manieres en / classe », avec un mot seul sur la derniere ligne.
class _TitreEquilibre extends StatelessWidget {
  const _TitreEquilibre({required this.texte, required this.style});

  final String texte;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) {
      final Widget titre = Text(texte, style: style);
      final double pleine = contraintes.maxWidth;
      if (!pleine.isFinite) return titre;
      final TextStyle effectif = DefaultTextStyle.of(context).style
          .merge(style);
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: texte, style: effectif),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      int lignes(double largeur) {
        peintre.layout(maxWidth: largeur);
        return peintre.computeLineMetrics().length;
      }

      final int cible = lignes(pleine);
      if (cible <= 1) {
        peintre.dispose();
        return titre;
      }
      double bas = 0;
      double haut = pleine;
      for (int i = 0; i < 12; i++) {
        final double milieu = (bas + haut) / 2;
        if (lignes(milieu) > cible) {
          bas = milieu;
        } else {
          haut = milieu;
        }
      }
      peintre.dispose();
      return SizedBox(width: haut.ceilToDouble(), child: titre);
    },
  );
}

/// La largeur maximale du texte de l'encadre.
const double _largeurEncadre = 320;

/// Une ligne de texte figuree, en gris clair.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: fraction,
    child: SizedBox(
      height: AppSpacing.md,
      child: DecoratedBox(
        decoration: AppPalette.of(context).surfaceSunken
            .decoration(borderRadius: AppRadius.arrondiFull),
      ),
    ),
  );
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          texte,
          style: palette.washAccent.applyTo(
            Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
          ),
        ),
      ),
    );
  }
}

/// L'illustration du support : un aplat aux jetons, jamais une photo.
class _Illustration extends StatelessWidget {
  const _Illustration();

  static const double _largeur = 284;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      image: true,
      label: t.salle.seance.illustration,
      excludeSemantics: true,
      child: SizedBox(
        width: _largeur,
        child: AspectRatio(
          aspectRatio: 1.3,
          child: DecoratedBox(
            decoration: palette.washWarning.decoration(
              borderRadius: AppRadius.arrondiMd,
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: palette.washWarning.onBackground,
                  size: AppSpacing.respiration,
                ),
                child: Icon(AppIcons.lecon.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rien n'est partage : la video de l'enseignante au centre, et une phrase.
class _RienPartage extends StatelessWidget {
  const _RienPartage({required this.vue});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      key: const ValueKey<String>('zone-support'),
      decoration: palette.surfaceSunken.decoration(
        borderRadius: AppRadius.arrondiLg,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          final double largeur = math.min(
            _largeurVideoMax,
            math.min(
              contraintes.maxWidth - 2 * AppSpacing.xxl,
              (contraintes.maxHeight - _hauteurTexte) * MesuresVignette.ratio,
            ),
          );
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (largeur > 0) VignetteVideo(vue: vue, largeur: largeur),
                  Ecart.vXl,
                  Text(
                    t.salle.seance.rienPartage(nom: vue.nomEnseignant),
                    textAlign: TextAlign.center,
                    style: palette.inkMuted.applyTo(
                      Theme.of(context).textTheme.bodyLarge ??
                          const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// La plus grande video centree de l'etat « rien partage ».
const double _largeurVideoMax = 360;

/// La place gardee sous la video pour la phrase et les marges.
const double _hauteurTexte = 120;
