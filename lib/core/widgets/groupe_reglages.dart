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
    this.action,
  }) : assert(
         icone != null || meneur != null,
         'une rubrique porte une icone ou un meneur',
       );

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

  /// Un bouton en fin de ligne (« Recharger » d'un solde). Il garde son geste
  /// et sa semantique, mais, a la difference de [controle], la ligne reste
  /// pressable ; il remplace le chevron. Toujours secondaire (K-36). A fort
  /// grossissement, il passe sous les textes.
  final Widget? action;
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
    // Avec une [LigneRubrique.action], elle se presse quand meme.
    if ((ligne.controle != null && ligne.action == null) ||
        ligne.onPress == null) {
      return MergeSemantics(child: _contenu(context, const EtatPression()));
    }
    return Pressable.selon(
      onPress: ligne.onPress,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget? action = ligne.action == null
        ? null
        : Semantics(container: true, child: ligne.action);
    // A 200 %, le bouton de fin de ligne passe sous les textes.
    final bool actionDessous =
        action != null && MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final Color fond = etat.survole || etat.presse
        ? Color.alphaBlend(
            palette.calqueInteraction(presse: etat.presse),
            palette.surfaceRaised.background,
          )
        : palette.surfaceRaised.background;

    return ColoredBox(
      color: fond,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            ligne.meneur ??
                IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(ligne.icone!.repos),
                ),
            Ecart.hMd,
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
                        Expanded(
                          child: actionDessous
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _textes(palette, textes),
                                    Ecart.vSm,
                                    action,
                                  ],
                                )
                              : _textes(palette, textes),
                        ),
                        if (ligne.controle != null) ...<Widget>[
                          Ecart.hSm,
                          ligne.controle!,
                        ],
                        if (action != null && !actionDessous) ...<Widget>[
                          Ecart.hSm,
                          action,
                        ],
                        if (ligne.onPress != null &&
                            ligne.controle == null &&
                            action == null) ...<Widget>[
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
              style: palette.inkStrong.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
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
