import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_elevation.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une rubrique d'un [GroupeReglages] : icone (ou meneur), libelle, legende
/// ou valeur, chevron quand elle mene ailleurs.
@immutable
class LigneRubrique {
  /// Cree une rubrique. Il faut une [icone] ou un [meneur].
  const LigneRubrique({
    required this.libelle,
    this.icone,
    this.meneur,
    this.legende,
    this.valeur,
    this.onPress,
    this.controle,
    this.pastille,
    this.selectionnee,
    this.libelleSemantique,
    this.autofocus = false,
  });

  /// L'icone de la rubrique, en encre d'accent.
  final AppIcon? icone;

  /// Ce qui tient la tete de ligne a la place de l'icone : l'avatar ou
  /// l'initiale d'un membre du Foyer (demande B-1). Largeur libre ; le filet
  /// commence apres lui, au meme retrait qu'apres une icone. Il n'a pas de
  /// semantique propre a porter : la ligne est lue par son libelle.
  final Widget? meneur;

  /// Le nom de la rubrique : « Informations personnelles ».
  final String libelle;

  /// Une ligne de resume sous le libelle : « Nom, courriel, fuseau ».
  final String? legende;

  /// Une valeur courte en fin de ligne : « Systeme », « Francais ».
  final String? valeur;

  /// La destination. Avec elle, la ligne porte un chevron et se presse.
  final VoidCallback? onPress;

  /// Un controle natif en fin de ligne (interrupteur). Il garde son propre
  /// geste et sa propre semantique : la ligne ne se presse alors pas.
  final Widget? controle;

  /// Une pastille d'etat dans le flux du libelle : a cote du nom quand la
  /// place suffit, dessous sinon (AD-5).
  final Widget? pastille;

  /// Selection d'une file maitre-detail : annoncee (`Semantics.selected`) et
  /// marquee autrement que par la couleur (barre de debut, graisse). Nul :
  /// la ligne n'est pas selectionnable.
  final bool? selectionnee;

  /// Libelle lu a la place du libelle visible.
  final String? libelleSemantique;

  /// Prend le focus a l'apparition (retour d'un detail vers sa ligne).
  final bool autofocus;
}

/// Un groupe de rubriques a filets en retrait : le hub du Compte, la fiche
/// d'un eleve, les Preferences (maquettes V3, V4 ; manifeste visuel Tuteur V1
/// section 3.4).
///
/// **Une seule surface pour tout le groupe**, jamais une carte par ligne :
/// « Hub Reglages : un seul groupe a filets, pas quatre cartes » (V4). Les
/// filets separent les lignes et commencent apres l'icone, comme les listes
/// groupees des deux plateformes.
///
/// Chaque ligne fait au moins 48 de haut (cible tactile) et grandit avec le
/// texte ; a 200 %, la valeur passe sous le libelle au lieu de le couper.
class GroupeReglages extends StatelessWidget {
  /// Cree un groupe.
  const GroupeReglages({required this.lignes, super.key, this.titre});

  /// Le titre du groupe, au-dessus de la surface. Facultatif.
  final String? titre;

  /// Les rubriques, dans l'ordre d'affichage.
  final List<LigneRubrique> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (titre != null) ...<Widget>[
          Semantics(
            header: true,
            child: Text(
              titre!,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        DecoratedBox(
          decoration: AppElevation.avecFilet(
            surface: palette.surfaceRaised,
            filet: palette.contourCarte,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiMd,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.arrondiMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < lignes.length; i++)
                  _Ligne(ligne: lignes[i], filet: i < lignes.length - 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.ligne, required this.filet});

  final LigneRubrique ligne;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    // Une ligne a controle ne se presse pas : l'interrupteur garde son geste.
    if (ligne.controle != null || ligne.onPress == null) {
      return MergeSemantics(child: _contenu(context, const EtatPression()));
    }
    return Pressable.selon(
      onPress: ligne.onPress,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      libelleSemantique: ligne.libelleSemantique,
      selectionne: ligne.selectionnee,
      autofocus: ligne.autofocus,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool choisie = ligne.selectionnee ?? false;
    final Color fond = etat.survole || etat.presse || choisie
        ? Color.alphaBlend(
            palette.calqueInteraction(presse: etat.presse),
            palette.surfaceRaised.background,
          )
        : palette.surfaceRaised.background;
    final Widget? tete =
        ligne.meneur ??
        (ligne.icone == null
            ? null
            : IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                child: Icon(ligne.icone!.repos),
              ));

    return DecoratedBox(
      // La selection ne tient pas a la seule teinte : une barre de 4 au bord
      // de debut, en encre d'accent (jeton existant).
      decoration: BoxDecoration(
        color: fond,
        border: choisie
            ? BorderDirectional(
                start: palette.inkAccent.asBorderSide(width: AppSpacing.xs),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: choisie ? AppSpacing.lg - AppSpacing.xs : AppSpacing.lg,
        ),
        child: Row(
          children: <Widget>[
            if (tete != null) ...<Widget>[tete, Ecart.hMd],
            Expanded(
              // Le filet en retrait : il court sous le texte, pas sous
              // l'icone, et s'arrete a la derniere ligne du groupe.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: filet
                      ? Border(bottom: palette.contourCarte.asBorderSide())
                      : null,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppTouchTarget.standard,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                      end: AppSpacing.lg,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _textes(palette, textes)),
                        if (ligne.controle != null) ...<Widget>[
                          Ecart.hSm,
                          ligne.controle!,
                        ],
                        if (ligne.onPress != null &&
                            ligne.controle == null) ...<Widget>[
                          Ecart.hSm,
                          ExcludeSemantics(
                            child: IconTheme(
                              data: palette.inkMuted.asIconTheme(
                                size: AppSpacing.xl,
                              ),
                              child: Icon(AppIcons.chevron.repos),
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
      ),
    );
  }

  Widget _textes(AppPalette palette, TextTheme textes) {
    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Libelle et valeur partagent la ligne tant qu'ils tiennent ; sinon la
    // valeur passe dessous (Wrap), sans jamais couper un mot.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            Text(
              ligne.libelle,
              style: palette.inkStrong
                  .applyTo(textes.bodyLarge ?? const TextStyle())
                  .copyWith(
                    fontWeight: (ligne.selectionnee ?? false)
                        ? FontWeight.w600
                        : null,
                  ),
            ),
            if (ligne.pastille != null) ligne.pastille!,
            if (ligne.valeur != null)
              Text(ligne.valeur!, style: styleSecondaire),
          ],
        ),
        if (ligne.legende != null) ...<Widget>[
          Ecart.vXs,
          Text(ligne.legende!, style: styleSecondaire),
        ],
      ],
    );
  }
}
