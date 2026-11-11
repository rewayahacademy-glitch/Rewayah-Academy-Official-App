// La vignette video de l'enseignante (CLV-04, 05, 06).
//
// Ratio fixe, jamais etiree (AspectRatio + contenu en `cover`). En capture,
// un aplat aux jetons remplace la photo (plan de code section 3).

import 'package:flutter/material.dart';

import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/cadre_visage.dart';
import '../../core/widgets/pressable.dart';
import 'media_salle.dart';
import 'vue_seance.dart';

/// Les mesures de la vignette, par gabarit.
abstract final class MesuresVignette {
  /// Le ratio largeur / hauteur, identique a toutes les largeurs (≈ 1,1:1).
  static const double ratio = 1.1;

  /// Telephone et web etroit : ≈ 136 x 124.
  static const double largeurEtroite = 136;

  /// Desktop : ≈ 208 x 190.
  static const double largeurLarge = 208;

  /// Desktop, panneau Eleves ou Supports ouvert : ≈ 192 x 175 (images
  /// CLV-07 et CLV-08 : le titre du support garde ses deux lignes).
  static const double largeurLargePanneau = 192;

  /// Web etroit, eleve standard : ≈ 188 x 171 (image CLV-04-05-06 web
  /// etroit, ≈ 31 % de la largeur du support).
  static const double largeurTablette = 188;

  /// Web etroit, enseignant, outils en colonne a droite : ≈ 176 x 160
  /// (meme image, colonne CLV-06).
  static const double largeurTabletteEnseignant = 176;

  /// Interface guidee, telephone : ≈ 160 x 145 (S CLV-05).
  static const double largeurGuideeMobile = 160;

  /// Interface guidee, web etroit : ≈ 240 x 218 (image CLV-04-05-06 web
  /// etroit : ≈ 41 % de la largeur du support ; S CLV-05 : 160 a 300).
  static const double largeurGuideeTablette = 240;

  /// Interface guidee, desktop : ≈ 300 x 273, dans sa colonne (Q8).
  static const double largeurGuideeLarge = 300;

  /// Le retrait depuis le coin du support.
  static const double retrait = AppSpacing.md;

  /// La largeur pour un gabarit ; [guidee] : les mesures de l'Interface
  /// guidee ([VueSeance.vignetteAgrandie]) ; [enseignant] : la salle de
  /// l'enseignant ; [panneau] : un panneau Eleves ou Supports est ouvert
  /// (web etroit : le volet couvre le support, la vignette reste petite).
  static double largeur(
    Gabarit gabarit, {
    bool guidee = false,
    bool enseignant = false,
    bool panneau = false,
  }) {
    if (guidee) {
      return switch (gabarit) {
        Gabarit.mobile => largeurGuideeMobile,
        Gabarit.tablette => largeurGuideeTablette,
        Gabarit.desktop => largeurGuideeLarge,
      };
    }
    return switch (gabarit) {
      Gabarit.mobile => largeurEtroite,
      Gabarit.tablette =>
        panneau
            ? largeurEtroite
            : (enseignant ? largeurTabletteEnseignant : largeurTablette),
      Gabarit.desktop => panneau ? largeurLargePanneau : largeurLarge,
    };
  }

  /// S0.2 (pilote, 24/10/2026) : dans `/salle`, la vignette est petite et
  /// flottante, au coin de la scene : ≈ 110 au telephone, ≈ 200 ailleurs.
  static double largeurPleinCadre(Gabarit gabarit) => gabarit == Gabarit.mobile
      ? largeurPleinCadreEtroite
      : largeurPleinCadreLarge;

  /// Telephone, `/salle` : ≈ 110 x 100.
  static const double largeurPleinCadreEtroite = 112;

  /// Tablette et ordinateur, `/salle` : ≈ 200 x 180.
  static const double largeurPleinCadreLarge = 200;

  /// La hauteur qui suit du ratio.
  static double hauteur(Gabarit gabarit, {bool guidee = false}) =>
      largeur(gabarit, guidee: guidee) / ratio;
}

/// La video de l'enseignante en petite vignette.
///
/// RUBAN-TELEPHONE (directeur, 11/11/2026, MODES-AFFICHAGE §2, regle 2) :
/// une enveloppe mince autour de LE cadre de la salle ([CadreVisage]) : meme
/// forme, memes coins, meme pastille du nom, meme signe du micro, meme
/// anneau de parole, meme repli camera eteinte que la grille ; seule la
/// taille change. Ce qui reste a la vignette : sa largeur et son rapport
/// (jamais etiree), sa cle (`vignette-video`), le toucher qui met la classe
/// en grand, et les barres du reseau de l'enseignant posees DANS le cadre.
/// Dans `/salle`, le cadre vient de la portee ([PorteeMediaSalle.cadre]),
/// le meme que celui de la grille ; en demonstration, la vignette le compose
/// elle-meme.
class VignetteVideo extends StatelessWidget {
  const VignetteVideo({
    required this.vue,
    required this.largeur,
    this.touchable = true,
    this.avecSignal = true,
    this.avecNom = true,
    this.ratio = MesuresVignette.ratio,
    this.identite,
    this.nom,
    this.cleCadre = cleVignette,
    super.key,
  });

  final VueSeance vue;
  final double largeur;

  /// Le rapport largeur sur hauteur ; par defaut celui de la vignette
  /// ([MesuresVignette.ratio]). Panneau des Eleves de l'ordinateur
  /// (directeur, 11/11/2026) : 4:3, a la largeur du panneau.
  final double ratio;

  /// Faux dans la capsule du telephone (fiche 1, ligne 5) : toucher la
  /// capsule deplie le profil, l'oeil met la video en grand.
  final bool touchable;

  /// Faux quand la vignette ne montre pas l'enseignant lui-meme (le
  /// recitant dans sa capsule) : les barres sont celles de SON lien.
  final bool avecSignal;

  /// Faux dans la capsule et le profil du telephone : le nom ne s'ecrit pas
  /// (il reste lu par le lecteur d'ecran).
  final bool avecNom;

  /// RUBAN-TELEPHONE : la personne montree, a la place de celle de la portee
  /// ([PorteeMediaSalle.identiteVignette]) ; `null` : celle de la portee.
  final String? identite;

  /// RUBAN-TELEPHONE : le nom de la personne montree hors de `/salle` ;
  /// `null` : le nom de l'enseignant.
  final String? nom;

  /// La cle du cadre (tests) : [cleVignette] pour la vignette de la
  /// portee ; une autre pour un second cadre (le recitant de la bande).
  final Key cleCadre;

  /// La cle de la vignette (tests, captures).
  static const Key cleVignette = ValueKey<String>('vignette-video');

  @override
  Widget build(BuildContext context) {
    final PorteeMediaSalle? portee = PorteeMediaSalle.de(context);
    // S0 : toucher la vignette met la classe en grand (spec D16, point 4).
    final VoidCallback? enGrand = touchable ? portee?.onBasculerScene : null;
    final Widget vignette = _vignette(context, portee);
    if (enGrand == null) return vignette;
    return Pressable(
      key: const ValueKey<String>('vignette-en-grand'),
      libelleSemantique: t.salle.voirVideoEnGrand,
      onPress: enGrand,
      child: vignette,
    );
  }

  Widget _vignette(BuildContext context, PorteeMediaSalle? portee) {
    final String? qui = identite ?? portee?.identiteVignette;
    final String nomMontre = nom ?? vue.nomEnseignant;
    // Le reseau de l'enseignant, DANS le cadre (en haut a la fin).
    final Widget? coin = vue.voitSignalVideo && avecSignal
        ? SignalVideo(
            key: const ValueKey<String>('signal-video'),
            barres: vue.signalEnseignant ?? 0,
          )
        : null;
    // TB-RC (revue TB-R, m7) : un noeud propre, jamais fondu dans l'ecran ;
    // il commence par « Video de … », puis l'etat du cadre (micro, image).
    final String libelle = t.salle.seance.videoDe(deNom: deDevant(nomMontre));
    final Widget cadre =
        (qui == null
            ? null
            : portee?.cadre?.call(
                qui,
                libelleNom: libelle,
                coin: coin,
                detache: true,
              )) ??
        CadreVisage(
          nom: avecNom ? nomMontre : '',
          prenom: nomMontre,
          image: qui == null ? null : portee?.video?.call(qui),
          // PHOTOS-A : la photo par l'id de la personne montree.
          personneId: qui,
          libelleNom: libelle,
          coin: coin,
          detache: true,
        );
    return SizedBox(
      key: cleCadre,
      width: largeur,
      child: AspectRatio(aspectRatio: ratio, child: cadre),
    );
  }
}

/// Trois barres de signal (enseignant seulement) : la qualite reelle du
/// lien, mesuree par le serveur de visio (3 excellente, 2 bonne, 1 mediocre,
/// 0 perdue).
class SignalVideo extends StatelessWidget {
  const SignalVideo({required this.barres, super.key});

  final int barres;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _ecartBarres),
            child: SizedBox(
              width: AppSpacing.xs,
              height: AppSpacing.xs * (i + 2),
              child: DecoratedBox(
                decoration:
                    (i < barres
                            // Une seule barre : le lien est faible, la teinte
                            // le dit aussi (jamais par la couleur seule : le
                            // nombre de barres reste le signal).
                            ? (barres <= 1
                                  ? palette.pointsStatut.attention
                                  : palette.pointsStatut.succes)
                            : palette.pointsStatut.neutre)
                        .pastille()
                        .copyWith(
                          shape: BoxShape.rectangle,
                          borderRadius: AppRadius.arrondiXs,
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

/// L'ecart entre deux barres de signal : un demi-palier.
const double _ecartBarres = AppSpacing.xs / 2;
