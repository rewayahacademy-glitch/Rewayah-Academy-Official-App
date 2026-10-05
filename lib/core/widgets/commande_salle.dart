// La commande ronde de la salle de cours : un disque, une icone, un mot dessous.
//
// ETATS-BTN-1 (revue du directeur, 01/10/2026, K-54 et K-56). Micro, camera,
// son recu, agrandir : ce sont des bascules, et leur etat se lit sans
// ambiguite par TROIS signaux cumules, jamais par la couleur seule :
//
// 1. la forme du disque : plein et contraste quand la bascule est active,
//    contour seul (fond transparent) quand elle est inactive ;
// 2. l'icone : une icone differente (micro / micro barre, camera / camera
//    barree), choisie par l'appelant ;
// 3. le mot d'etat sous l'icone (« Micro ouvert » / « Micro coupe »), jamais
//    masque, meme quand la rangee est trop etroite pour les autres libelles.
//
// Un seul composant pour le dock de la seance et pour la salle : on
// l'ameliore, on n'en recree pas un (lib/CLAUDE.md).

import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_contour.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Le fond d'une [CommandeSalle] qui n'est pas une bascule, ou le fond de sa
/// bascule quand elle est active.
enum FondCommande {
  /// Surface surelevee : Camera, Agrandir, Reseau.
  surface,

  /// Disque plein d'alerte : Quitter.
  alerte,

  /// Disque plein de la paire succes : Parler, en guidee (Q1).
  succes,

  /// Disque plein de la paire primaire : Camera, en guidee (Q1).
  primaire,

  /// Surface surelevee, icone a l'encre de succes : Reseau (image CLV-06).
  reseau,
}

/// Le diametre commun des commandes d'une rangee : la cible tactile du mode
/// d'interface, plus un palier, pour tenir la taille des images (≈ 56 en
/// standard). En Interface guidee, la cible tactile du mode enfant elle-meme
/// (Q1, S CLV-05 : 72).
double diametreCommandeSalle(BuildContext context) {
  final AppMetriques metriques = AppMetriques.of(context);
  return metriques.mode == InterfaceMode.enfant
      ? metriques.cibleTactile
      : metriques.cibleTactile + AppSpacing.sm;
}

/// Vrai tant que le texte n'est pas tres agrandi : le mot d'etat d'une bascule
/// se montre. Au-dela, il passe en infobulle (voir [CommandeSalleCompacte]).
bool motEtatVisible(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) <= AppContour.seuilTexteAgrandi;

/// ETATS-MA-1 (decision du 05/10/2026, WCAG 1.4.1) : en Mode Accessibilite,
/// texte au-dela de 130 %, les commandes de la salle passent sur deux rangees
/// ([CommandesSurDeuxRangees]) pour que le mot d'etat des bascules reste
/// visible. Hors Mode Accessibilite, rien ne change.
bool commandesSurDeuxRangees(BuildContext context) =>
    AppMetriques.of(context).mode == InterfaceMode.enfant &&
    !motEtatVisible(context);

/// La largeur d'une case de rangee pour une commande : une bascule porte un
/// mot d'etat de deux mots, donc deux cibles ; les autres, une cible et un
/// ecart. Jamais sous 48 de cible, jamais collees (revue 01/10, ETATS-BTN-1).
double largeurCaseCommande(BuildContext context, {required bool bascule}) {
  final double cible = AppMetriques.of(context).cibleTactile;
  return bascule && motEtatVisible(context) ? cible * 2 : cible + AppSpacing.sm;
}

/// EN-12 (UX_REVIEW_04 n° 17 d, K-42) : la rangee est trop serree ou le texte
/// agrandi. Les commandes ordinaires y passent en icone seule (le libelle reste
/// lu par le lecteur d'ecran et montre en infobulle) et le disque tient sa case
/// moins un ecart, sans descendre sous la cible tactile. Une bascule garde son
/// mot d'etat : c'est un de ses trois signaux.
class CommandeSalleCompacte extends InheritedWidget {
  const CommandeSalleCompacte({
    required this.diametre,
    required super.child,
    this.garderMotEtat = false,
    super.key,
  });

  /// Le diametre des disques de la rangee compacte.
  final double diametre;

  /// Vrai : une bascule garde son mot d'etat a toute taille de texte, et
  /// remplit la case que lui donne sa rangee (ETATS-MA-1, deux rangees).
  final bool garderMotEtat;

  @override
  bool updateShouldNotify(CommandeSalleCompacte ancien) =>
      ancien.diametre != diametre || ancien.garderMotEtat != garderMotEtat;
}

/// ETATS-MA-1 (decision du 05/10/2026, par delegation du directeur ; regle du
/// 02/10, DECISIONS_DELEGUEES_2026-10-02.md : « le mot d'etat reste ») : en
/// Mode Accessibilite, texte au-dela de 130 %, une seule rangee de disques ne
/// laisse plus la place au mot d'etat des bascules. Les commandes passent
/// donc sur deux rangees, deux par deux et dans leur ordre (micro et camera,
/// puis la suivante et Quitter) : chaque commande prend la moitie de la
/// largeur, la bascule y garde son mot sous le disque (« Micro ouvert »,
/// sur deux lignes au besoin, jamais coupe), la commande ordinaire reste en
/// icone seule (MA-CMD-1, nom lu et en infobulle). Le support cede la hauteur
/// d'une rangee.
class CommandesSurDeuxRangees extends StatelessWidget {
  const CommandesSurDeuxRangees({
    required this.commandes,
    required this.diametre,
    super.key,
  });

  /// Les commandes, dans l'ordre de la rangee unique.
  final List<Widget> commandes;

  /// Le diametre des disques.
  final double diametre;

  /// La cle de la grille (tests, captures).
  static const Key grilleKey = ValueKey<String>('commandes-deux-rangees');

  @override
  Widget build(BuildContext context) => CommandeSalleCompacte(
    diametre: diametre,
    garderMotEtat: true,
    child: Column(
      key: grilleKey,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: <Widget>[
        for (int i = 0; i < commandes.length; i += 2)
          Row(
            // Les disques d'une rangee s'alignent en haut, meme quand un mot
            // passe sur deux lignes et l'autre non.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Center(child: commandes[i])),
              if (i + 1 < commandes.length)
                Expanded(child: Center(child: commandes[i + 1])),
            ],
          ),
      ],
    ),
  );
}

/// Une commande ronde de la salle. Si [bascule] est renseigne, c'est une
/// bascule : `true` = active (disque plein), `false` = inactive (contour
/// seul). [libelle] est alors le mot d'etat (« Micro ouvert »).
class CommandeSalle extends StatelessWidget {
  const CommandeSalle({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.libelleSemantique,
    this.fond = FondCommande.surface,
    this.actif = true,
    this.bascule,
    this.focusNode,
    this.selectionne,
    this.encreLibelle,
    super.key,
  });

  /// L'icone : pour une bascule, celle de l'etat courant (micro / micro
  /// barre).
  final IconData icone;

  /// Le mot sous l'icone : l'etat pour une bascule, le nom sinon.
  final String libelle;

  /// Ce que le lecteur d'ecran annonce : l'acte (« Fermer le micro »).
  final String? libelleSemantique;

  /// `null` : la commande reste rendue mais ne repond pas.
  final VoidCallback? onPress;

  /// Le fond d'une commande ordinaire ; pour une bascule, le fond de l'etat
  /// actif (`surface` : le disque de contraste du theme).
  final FondCommande fond;

  /// Faux : la commande reste rendue mais ne repond pas (reconnexion, lot
  /// CL-7). Aucune transparence : disque neutre et encre `inkMuted`.
  final bool actif;

  /// `null` : commande ordinaire. Sinon l'etat de la bascule.
  final bool? bascule;

  /// Le noeud de focus, rendu a la commande a la fermeture d'une feuille
  /// ouverte par elle (W2 2.4.3).
  final FocusNode? focusNode;

  /// Annonce « selectionne » quand son panneau est ouvert (EN-10).
  final bool? selectionne;

  /// L'encre du mot, quand la commande se pose sur le fond du registre `salle`
  /// (controleur, mode accessibilite) : sinon l'encre du theme.
  final AppColorPair? encreLibelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final CommandeSalleCompacte? compacte = context
        .dependOnInheritedWidgetOfExactType<CommandeSalleCompacte>();
    final bool estBascule = bascule != null;
    // Une bascule garde son mot : sans lui il ne reste que deux signaux. Il ne
    // cede que devant un texte tres agrandi (plus de 130 %), ou deux lignes de
    // mot par commande ne tiennent plus dans la hauteur d'un telephone : le mot
    // passe alors en infobulle et dans la voix du lecteur d'ecran, comme les
    // libelles du Teaching Dock (`BoutonOutil`).
    // ETATS-MA-1 : sur deux rangees, le mot d'une bascule reste a toute taille.
    final bool garderMot = compacte?.garderMotEtat ?? false;
    final bool iconeSeule =
        compacte != null &&
        (!estBascule || (!garderMot && !motEtatVisible(context)));
    final double diametre =
        compacte?.diametre ?? diametreCommandeSalle(context);
    final double tailleIcone =
        AppMetriques.of(context).mode == InterfaceMode.enfant
        ? AppSpacing.xxxl
        : AppSpacing.xxl;
    final bool allumee = bascule ?? false;
    final bool repondre = actif && onPress != null;

    // Le plein de l'etat actif d'une bascule : le disque de contraste du
    // theme (surfaceInverse), ou la couleur de son fond en guidee.
    final AppColorPair pleinBascule = switch (fond) {
      FondCommande.succes => palette.surfaceSuccess,
      FondCommande.primaire => palette.surfacePrimary,
      FondCommande.alerte => palette.surfaceAlert,
      FondCommande.surface || FondCommande.reseau => palette.surfaceInverse,
    };

    // Un disque a contour seul laisse voir le fond sous l'icone : posee sur le
    // fond du registre `salle`, elle prend l'encre de [encreLibelle]
    // (SALLE-CORR-3), sinon celle du theme.
    final AppColorPair? fondPose = encreLibelle;
    final BoxDecoration disque;
    final IconThemeData encre;
    if (!repondre && estBascule && !allumee) {
      // Bascule inactive et inerte : le contour seul reste, l'encre s'attenue.
      disque = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          palette.borderResting.asBorderSide(width: AppContour.fort),
        ),
      );
      encre = fondPose != null
          ? IconThemeData(color: fondPose.onBackground, size: tailleIcone)
          : palette.inkMuted.asIconTheme(size: tailleIcone);
    } else if (!repondre) {
      // Commande inerte, ou bascule active et inerte : le disque plein reste
      // (surface neutre), seule l'encre s'attenue. L'etat se lit donc encore.
      disque = palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiFull,
        side: palette.borderResting.asBorderSide(),
      );
      encre = palette.inkMuted.asIconTheme(size: tailleIcone);
    } else if (estBascule && !allumee) {
      // Inactive : contour seul, fond transparent, encre forte.
      disque = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          palette.borderStrong.asBorderSide(width: AppContour.fort),
        ),
      );
      encre = fondPose != null
          ? IconThemeData(color: fondPose.onBackground, size: tailleIcone)
          : palette.inkStrong.asIconTheme(size: tailleIcone);
    } else if (estBascule) {
      disque = pleinBascule.decoration(borderRadius: AppRadius.arrondiFull);
      encre = IconThemeData(
        color: pleinBascule.onBackground,
        size: tailleIcone,
      );
    } else {
      switch (fond) {
        case FondCommande.surface || FondCommande.reseau:
          disque = palette.surfaceOverlay.decoration(
            borderRadius: AppRadius.arrondiFull,
            side: palette.borderHairline.asBorderSide(),
          );
          encre =
              (fond == FondCommande.reseau
                      ? palette.inkSuccess
                      : palette.inkStrong)
                  .asIconTheme(size: tailleIcone);
        case FondCommande.alerte:
          disque = palette.pointsStatut.alerte.pastille();
          // Encre claire fixe, dans les deux themes : le disque est un point
          // d'alerte, pas la paire `surfaceAlert`. Le blanc tient 4,1:1
          // (clair) et 3,3:1 (sombre), au-dessus de 3:1 (WCAG 1.4.11).
          encre = IconThemeData(
            color: AppPalette.claire().surfaceAlert.onBackground,
            size: tailleIcone,
          );
        case FondCommande.succes:
          disque = palette.surfaceSuccess.decoration(
            borderRadius: AppRadius.arrondiFull,
          );
          encre = IconThemeData(
            color: palette.surfaceSuccess.onBackground,
            size: tailleIcone,
          );
        case FondCommande.primaire:
          disque = palette.surfacePrimary.decoration(
            borderRadius: AppRadius.arrondiFull,
          );
          encre = IconThemeData(
            color: palette.surfacePrimary.onBackground,
            size: tailleIcone,
          );
      }
    }

    final TextStyle base = theme.textTheme.labelMedium ?? const TextStyle();
    final TextStyle styleLibelle = encreLibelle != null
        ? encreLibelle!.applyTo(base)
        : (repondre ? palette.inkStrong : palette.inkMuted).applyTo(base);

    final Widget pressable = Pressable(
      onPress: onPress,
      actif: actif,
      focusNode: focusNode,
      libelleSemantique: libelleSemantique ?? libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            key: const ValueKey<String>('disque-appel'),
            dimension: diametre,
            child: DecoratedBox(
              decoration: disque,
              child: Center(
                child: IconTheme(data: encre, child: Icon(icone)),
              ),
            ),
          ),
          if (!iconeSeule) ...<Widget>[
            Ecart.vXs,
            Text(
              libelle,
              key: const ValueKey<String>('mot-commande'),
              // Un mot d'etat de deux mots passe a la ligne, centre ligne a
              // ligne (K-54), plutot que de se tronquer.
              maxLines: estBascule ? 2 : 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: styleLibelle,
            ),
          ],
        ],
      ),
    );
    // Une bascule tient une case de largeur fixe : son mot d'etat change de
    // longueur (« Micro ouvert », « Micro coupe ») sans deplacer ses voisines.
    // Sur deux rangees (ETATS-MA-1), elle remplit la moitie de rangee que sa
    // case lui donne : son mot y passe a la ligne sans se couper.
    final Widget case_ = estBascule && !garderMot
        ? SizedBox(
            width: largeurCaseCommande(context, bascule: true),
            child: pressable,
          )
        : pressable;
    // Doc 04 §28 et §33 n. 13 : en icone seule, le libelle reste visible en
    // infobulle (comme `nav_shell`), deja lu par `Pressable`.
    final Widget bouton = iconeSeule
        ? Tooltip(
            // Une bascule dit son etat (« Micro coupe »), pas seulement son acte.
            message: estBascule ? libelle : libelleSemantique ?? libelle,
            excludeFromSemantics: true,
            child: case_,
          )
        : case_;
    final Widget annonce = estBascule
        ? Semantics(toggled: allumee, child: bouton)
        : bouton;
    final bool? choisi = selectionne;
    return choisi == null
        ? annonce
        : Semantics(selected: choisi, child: annonce);
  }
}
