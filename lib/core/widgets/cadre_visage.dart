// SCENE-CLASSE (directeur, 11/11/2026) : LE cadre d'une personne dans la
// salle (MODES-AFFICHAGE §2, regle 2) : la grille, et demain le ruban, la
// vignette, la capsule et les cartes du panneau. Meme forme, memes coins,
// meme etiquette du nom, meme signe du micro, meme anneau de parole, meme
// repli quand la camera est eteinte. Seule la taille change.
//
// Le composant ne connait ni LiveKit ni Riverpod : il recoit un widget
// d'image deja monte (ou `null`), et ce qu'il doit dire.

import 'package:flutter/material.dart';

import '../accessibilite/mode_accessibilite.dart';
import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'avatar_nom.dart';
import 'halo_lumiere.dart';
import 'status_pill.dart';

/// Le cadre d'une personne : son image, recadree au centre (jamais etiree),
/// ou sa photo et son initiale quand la camera est eteinte.
///
/// - **Forme** : celle que l'appelant lui donne (la grille la calcule, entre
///   le carre et 4/3) ; l'image **couvre** le cadre, centree.
/// - **Nom** : en bas au debut, sur une petite pastille sombre translucide
///   (lisible sur n'importe quelle image), jamais coupe dans un mot.
/// - **Micro ferme** : une icone, et le mot lu (jamais la couleur seule).
/// - **Fond** : un ecran sombre ([AppPalette.surfaceVisage]), qui se
///   detache du fond de la page dans les deux themes (VISAGES, 12/11/2026).
/// - **Sans image** : la photo de la personne quand le serveur la rend,
///   sinon un cercle de sa couleur et ses initiales, au centre exact du
///   cadre a toutes les tailles.
/// - **Parole** (VISAGES, point 9) : la lumiere du bouton Compte, DANS le
///   cadre ([HaloLumiere.voix]), en vagues tant que la personne parle ; elle
///   apparait et s'efface en fondu, sans rien deplacer ; rien quand elle se
///   tait. Mouvement ou effets reduits : une bordure `borderStrong` fixe. Le
///   lecteur d'ecran le dit aussi (« parle »).
/// - **Recite** : la marque « Recite » et un contour franc.
/// - **Gestes** : un emplacement au milieu du bord de fin ([menu]).
/// - **Petites tailles** (de 64 a 480 de cote) : sous [seuilNom], le nom
///   part (il reste lu et en infobulle), le signe du micro reste ; sous
///   [seuilMarque], la marque « Recite » part (le contour reste, et le mot
///   est lu) ; sous [seuilMenu], l'emplacement des gestes part.
class CadreVisage extends StatelessWidget {
  /// Cree le cadre.
  const CadreVisage({
    required this.nom,
    required this.prenom,
    super.key,
    this.image,
    this.personneId,
    this.microCoupe = false,
    this.parle = false,
    this.recite = false,
    this.menu,
    this.coin,
    this.libelleNom,
    this.detache = false,
  });

  /// RUBAN-TELEPHONE (11/11/2026) : un signe pose DANS le cadre, en haut a
  /// la fin (les barres du reseau de la capsule de l'enseignant), ou `null`.
  /// Le cadre ne le lit pas : l'appelant le rend lisible lui-meme.
  final Widget? coin;

  /// RUBAN-TELEPHONE : ce que le lecteur d'ecran dit a la place du nom
  /// (« Video de Khadija » dans la vignette), ou `null` : le nom.
  final String? libelleNom;

  /// RUBAN-TELEPHONE : vrai quand le cadre est pose seul sur une page ou un
  /// fond de la meme teinte que lui (la vignette sur le Coran) : un filet le
  /// detache, pour que son bord se voie (WCAG 1.4.11). La grille, sur sa
  /// propre scene, n'en a pas besoin.
  final bool detache;

  /// La cle du signe pose dans le coin (tests).
  static const Key cleCoin = ValueKey<String>('cadre-visage-coin');

  /// Le nom affiche (« Khadija », « Vous »).
  final String nom;

  /// Le prenom, source de l'initiale quand il n'y a pas de photo.
  final String prenom;

  /// L'image (la video deja montee), ou `null` : camera eteinte, ou pas
  /// encore recue.
  final Widget? image;

  /// L'id de la personne : sa photo quand la camera est eteinte (PHOTOS-A),
  /// et le suffixe des cles de test (`recite-<id>`, `gestes-<id>`).
  final String? personneId;

  /// Vrai : le micro est ferme.
  final bool microCoupe;

  /// Vrai : du son sort de ce micro en ce moment (ce n'est pas une preuve
  /// de recitation).
  final bool parle;

  /// Vrai : cet eleve a la parole pour reciter.
  final bool recite;

  /// Le menu des gestes de l'enseignant sur cette personne, ou `null`.
  final Widget? menu;

  /// La largeur sous laquelle le nom ne s'ecrit plus (il reste lu).
  static const double seuilNom = AppSpacing.respiration * 1.75;

  /// La largeur sous laquelle la marque « Recite » ne s'ecrit plus.
  static const double seuilMarque = AppSpacing.respiration * 2.5;

  /// La largeur sous laquelle l'emplacement des gestes n'est pas pose.
  static const double seuilMenu = AppSpacing.respiration * 1.5;

  /// L'epaisseur de l'anneau de parole et du contour de recitation.
  static const double epaisseurAnneau = AppSpacing.xs;

  /// L'opacite de la pastille du nom (sombre, translucide).
  static const double opacitePastille = 0.72;

  /// La cle de la lumiere de parole (son fondu ; tests).
  static const Key cleAnneau = ValueKey<String>('cadre-visage-anneau');

  /// La cle de la bordure fixe de parole, sous mouvement reduit (tests).
  static const Key cleBordureParole = ValueKey<String>(
    'cadre-visage-bordure-parole',
  );

  /// La cle de l'etiquette du nom (tests).
  static const Key cleNom = ValueKey<String>('cadre-visage-nom');

  /// La cle du signe du micro ferme (tests).
  static const Key cleMicro = ValueKey<String>('cadre-visage-micro');

  /// La phrase que le lecteur d'ecran lit pour ce cadre.
  String get libelle => <String>[
    if (libelleNom case final String l when l.trim().isNotEmpty)
      l
    else if (nom.trim().isNotEmpty)
      nom,
    if (microCoupe) t.salle.microCoupe,
    if (image == null) t.salle.sansImage,
    if (recite) t.tc.classe.recitation.pastille,
    if (parle) t.salle.scene.parle,
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = palette.surfaceVisage;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool fixe =
        AppMouvement.mouvementReduit(context) || EffetsReduits.de(context);
    final bool lumiere = parle && !recite;
    final Widget? image = this.image;
    final Widget? gestes = menu;
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) {
        final double largeur = c.hasBoundedWidth ? c.maxWidth : seuilMarque;
        final BorderRadius coins = largeur < seuilMenu
            ? AppRadius.arrondiSm
            : AppMetriques.of(contexte).arrondi;
        final bool avecNom = largeur >= seuilNom;
        // VISAGES : dans un grand cadre, le grand cercle (64), pour que la
        // photo ou la couleur de la personne se voie.
        final double cote = c.hasBoundedHeight
            ? (largeur < c.maxHeight ? largeur : c.maxHeight)
            : largeur;
        final double diametre = cote >= seuilMarque
            ? AppAvatar.grand
            : AppAvatar.moyen;
        final Widget contenu = ClipRRect(
          borderRadius: coins,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Camera allumee ou eteinte : un fondu dans le meme cadre.
              AnimatedSwitcher(
                duration: AppMouvement.fonduEntree,
                reverseDuration: AppMouvement.fonduSortie,
                switchInCurve: AppMouvement.courbeFondu,
                switchOutCurve: AppMouvement.courbeFondu,
                layoutBuilder: (Widget? courant, List<Widget> anciens) => Stack(
                  fit: StackFit.expand,
                  children: <Widget>[...anciens, ?courant],
                ),
                child: image != null
                    ? KeyedSubtree(
                        key: const ValueKey<String>('cadre-visage-image'),
                        // L'image remplit le cadre : le moteur la rend
                        // recadree au centre (`cover`), jamais etiree.
                        child: SizedBox.expand(child: image),
                      )
                    : KeyedSubtree(
                        key: const ValueKey<String>('cadre-visage-sans-image'),
                        child: TuileSansImage(
                          prenom: prenom,
                          nom: avecNom ? nom : '',
                          personneId: personneId == null || personneId!.isEmpty
                              ? null
                              : personneId,
                          libelleMicroCoupe: microCoupe
                              ? t.salle.microCoupe
                              : null,
                          couleurPersonne: true,
                          diametre: diametre,
                          couleurIcone: fond.onBackground,
                          styleNom: fond.applyTo(
                            textes.labelMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
              ),
              // La parole : la lumiere DANS le cadre (rognee a ses coins),
              // sous le nom et les marques ; elle apparait et s'efface en
              // fondu, rien ne bouge. Mouvement reduit : la bordure fixe,
              // posee plus bas.
              IgnorePointer(
                child: AnimatedOpacity(
                  key: cleAnneau,
                  opacity: lumiere ? 1 : 0,
                  duration: lumiere
                      ? AppMouvement.fonduEntree
                      : AppMouvement.fonduSortie,
                  curve: AppMouvement.courbeFondu,
                  child: fixe
                      ? const SizedBox.expand()
                      : HaloLumiere.voix(parle: lumiere, arrondi: coins),
                ),
              ),
              if (recite && largeur >= seuilMarque)
                PositionedDirectional(
                  top: AppSpacing.sm,
                  start: AppSpacing.sm,
                  child: StatusPill(
                    key: ValueKey<String>('recite-${personneId ?? nom}'),
                    libelle: t.tc.classe.recitation.pastille,
                    ton: TonEtat.accent,
                  ),
                ),
              if (image != null)
                PositionedDirectional(
                  start: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: _Etiquette(
                      // Un nom vide (un camarade dont le prenom n'est pas
                      // lisible) ne pose pas de pastille vide.
                      nom: avecNom && nom.trim().isNotEmpty ? nom : null,
                      microCoupe: microCoupe,
                      style: textes.labelMedium ?? const TextStyle(),
                    ),
                  ),
                ),
            ],
          ),
        );
        final Widget cadre = DecoratedBox(
          decoration: fond.decoration(
            borderRadius: coins,
            side: detache ? palette.borderStrong.asBorderSide() : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ExcludeSemantics(child: contenu),
              // Recite : un contour franc et fixe.
              if (recite)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: coins,
                      border: Border.fromBorderSide(
                        palette.borderStrong.asBorderSide(
                          width: epaisseurAnneau,
                        ),
                      ),
                    ),
                  ),
                ),
              // Mouvement ou effets reduits : la parole garde un signe, une
              // bordure fixe (l'information reste, sans vague).
              if (fixe && lumiere)
                IgnorePointer(
                  child: DecoratedBox(
                    key: cleBordureParole,
                    decoration: BoxDecoration(
                      borderRadius: coins,
                      border: Border.fromBorderSide(
                        palette.borderStrong.asBorderSide(
                          width: epaisseurAnneau,
                        ),
                      ),
                    ),
                  ),
                ),
              if (coin case final Widget signe)
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: KeyedSubtree(key: cleCoin, child: signe),
                ),
              if (gestes != null && largeur >= seuilMenu)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  child: Center(
                    child: KeyedSubtree(
                      key: ValueKey<String>('gestes-${personneId ?? nom}'),
                      child: gestes,
                    ),
                  ),
                ),
            ],
          ),
        );
        final Widget lu = Semantics(
          container: true,
          label: libelle,
          child: cadre,
        );
        // Le nom ne s'ecrit plus : il reste en infobulle.
        return avecNom
            ? lu
            : Tooltip(message: nom, excludeFromSemantics: true, child: lu);
      },
    );
  }
}

/// L'etiquette du bas : le signe du micro ferme et le nom, sur une petite
/// pastille sombre translucide, la meme dans les deux themes (lisible sur une
/// image claire comme sur une image sombre).
class _Etiquette extends StatelessWidget {
  const _Etiquette({
    required this.nom,
    required this.microCoupe,
    required this.style,
  });

  /// Le nom, ou `null` quand le cadre est trop petit pour l'ecrire.
  final String? nom;
  final bool microCoupe;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final String? nom = this.nom;
    if (nom == null && !microCoupe) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final Color encre = palette.coucheSalle.onBackground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.coucheSalle.background.withValues(
          alpha: CadreVisage.opacitePastille,
        ),
        borderRadius: AppRadius.arrondiXs,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: nom == null ? AppSpacing.xs : AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (microCoupe)
              Icon(
                AppIcons.microCoupe.repos,
                key: CadreVisage.cleMicro,
                size: AppSpacing.lg,
                color: encre,
              ),
            if (microCoupe && nom != null) Ecart.hXs,
            if (nom != null)
              Flexible(
                child: TexteSansCoupure(
                  nom,
                  key: CadreVisage.cleNom,
                  maxLignes: 2,
                  largeurAuPlusLong: true,
                  style: style.copyWith(color: encre),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
