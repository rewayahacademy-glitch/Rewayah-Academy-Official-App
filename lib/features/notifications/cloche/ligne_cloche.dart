// Une ligne de la cloche (CLOCHE-C, decision du 21/11/2026, regle 3 ; style
// C du canevas) : icone de la categorie, titre en gras quand non lu, une
// ligne de texte, l'heure ; l'action sur la ligne quand il y en a une ; la
// croix des annonces qu'on peut fermer. Deux lignes de texte au plus.

import 'package:flutter/material.dart';

import '../../../core/accessibilite/texte_agrandi.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bouton_icone.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/status_pill.dart';

/// La famille d'une ligne, qui choisit son icone et sa teinte.
enum CategorieLigneCloche {
  /// Une annonce de l'academie.
  annonce,

  /// Un geste attendu (remplacement, paiement, cahier).
  aFaire,

  /// Une seance (rappel, report, fin).
  seance,

  /// Le reste.
  autre,
}

/// Une ligne de la cloche, notification ou annonce.
class LigneCloche extends StatelessWidget {
  /// Cree la ligne.
  const LigneCloche({
    required this.categorie,
    required this.titre,
    required this.quand,
    required this.nonLu,
    required this.onOuvrir,
    required this.libelleSemantique,
    super.key,
    this.prefixe,
    this.texte,
    this.libelleAction,
    this.onAction,
    this.onFermer,
    this.libelleFermer,
    this.fermee = false,
    this.compacte = false,
    this.margeLaterale = AppSpacing.lg,
  });

  /// La famille de la ligne.
  final CategorieLigneCloche categorie;

  /// Le mot de la categorie, en gras devant le titre (« Annonce : »), ou nul.
  final String? prefixe;

  /// Le titre.
  final String titre;

  /// La ligne de texte, ou nul.
  final String? texte;

  /// L'heure ou le jour (« 19:03 », « Hier », « 19 nov. »).
  final String quand;

  /// Vrai si l'element n'est pas lu : fond doux et titre en gras.
  final bool nonLu;

  /// Vrai pour une annonce fermee, montree dans « Annonces ».
  final bool fermee;

  /// Ouvre le detail.
  final VoidCallback onOuvrir;

  /// La phrase lue par le lecteur d'ecran pour la ligne.
  final String libelleSemantique;

  /// L'action de la ligne (« Prendre la seance », « Ouvrir le lien »).
  final String? libelleAction;

  /// Rappele par l'action de la ligne.
  final VoidCallback? onAction;

  /// La croix d'une annonce qu'on peut fermer ; nulle : pas de croix.
  final VoidCallback? onFermer;

  /// Le nom lu de la croix (« Fermer l'annonce ... »).
  final String? libelleFermer;

  /// Vrai dans le panneau d'ordinateur : tuile de 36.
  final bool compacte;

  /// La marge de debut et de fin de la ligne : 20 dans le panneau, 12 dans la
  /// feuille (qui a deja sa marge), 16 dans la page.
  final double margeLaterale;

  /// La cle de la croix d'une ligne, pour les tests.
  static ValueKey<String> cleFermer(String cle) =>
      ValueKey<String>('cloche-fermer-$cle');

  /// La cle de l'action d'une ligne, pour les tests.
  static ValueKey<String> cleAction(String cle) =>
      ValueKey<String>('cloche-action-$cle');

  @override
  Widget build(BuildContext context) {
    return Pressable.selon(
      onPress: onOuvrir,
      libelleSemantique: libelleSemantique,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiXs,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Color fondRepos = nonLu
        ? palette.washAccent.background
        : palette.surfaceRaised.background;
    final Color fond = etat.survole || etat.presse
        ? Color.alphaBlend(
            palette.calqueInteraction(presse: etat.presse),
            fondRepos,
          )
        : fondRepos;
    final TextStyle base = textes.bodyMedium ?? const TextStyle();
    final TextStyle encreTitre = (fermee ? palette.inkMuted : palette.inkStrong)
        .applyTo(base);
    // Le gras du titre non lu et du mot de la categorie : celui du nom de
    // carte (`titleSmall`), jamais une graisse posee ici.
    final TextStyle gras = (fermee ? palette.inkMuted : palette.inkStrong)
        .applyTo(textes.titleSmall ?? base);
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool agrandi = SeuilsTexteAgrandi.texteAgrandi(context);
    final String? action = libelleAction;
    final VoidCallback? surAction = onAction;
    final VoidCallback? fermer = onFermer;
    return ColoredBox(
      color: fond,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: margeLaterale,
          end: fermer == null ? margeLaterale : AppSpacing.xs,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: _TuileCategorie(
                categorie: categorie,
                nonLu: nonLu,
                compacte: compacte,
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExcludeSemantics(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          if (prefixe != null)
                            TextSpan(
                              text: t.notifications.cloche.prefixe(
                                libelle: prefixe!,
                              ),
                              style: gras,
                            ),
                          TextSpan(text: titre, style: nonLu ? gras : null),
                        ],
                      ),
                      style: encreTitre,
                      // Deux lignes de texte au plus (regle 3) : le titre et
                      // sa ligne ; a texte agrandi, le titre peut prendre les
                      // deux, sans ligne de texte.
                      maxLines: agrandi ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (texte != null && texte!.trim().isNotEmpty && !agrandi)
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          texte!.replaceAll('\n', ' '),
                          style: doux,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        if (action != null && surAction != null)
                          ActionPrincipale(
                            key: key is ValueKey<String>
                                ? cleAction((key! as ValueKey<String>).value)
                                : null,
                            libelle: action,
                            niveau: NiveauAction.secondaire,
                            compacte: true,
                            pleineLargeur: false,
                            onPress: surAction,
                          ),
                        if (fermee)
                          StatusPill(
                            libelle: t.notifications.cloche.fermee,
                            ton: TonEtat.neutre,
                          ),
                        ExcludeSemantics(child: Text(quand, style: doux)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (fermer != null) ...<Widget>[
              Ecart.hXs,
              BoutonIcone(
                key: key is ValueKey<String>
                    ? cleFermer((key! as ValueKey<String>).value)
                    : null,
                icone: AppIcons.fermer,
                libelle: libelleFermer ?? t.notifications.cloche.fermerAnnonce,
                infobulle: t.notifications.cloche.fermerAnnonce,
                forme: FormeBoutonIcone.nue,
                onPress: fermer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La tuile de la categorie : annonce non lue en violet de marque, geste
/// attendu en ambre doux, le reste en gris doux.
class _TuileCategorie extends StatelessWidget {
  const _TuileCategorie({
    required this.categorie,
    required this.nonLu,
    required this.compacte,
  });

  final CategorieLigneCloche categorie;
  final bool nonLu;
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = switch (categorie) {
      CategorieLigneCloche.annonce =>
        nonLu ? palette.surfacePrimary : palette.washAccent,
      CategorieLigneCloche.aFaire => palette.washWarning,
      CategorieLigneCloche.seance ||
      CategorieLigneCloche.autre => palette.surfaceSunken,
    };
    final AppIcon icone = switch (categorie) {
      CategorieLigneCloche.annonce => AppIcons.annonce,
      CategorieLigneCloche.aFaire => AppIcons.reaffectation,
      CategorieLigneCloche.seance => AppIcons.calendrier,
      CategorieLigneCloche.autre => AppIcons.notifications,
    };
    final double cote = compacte
        ? AppSpacing.section - AppSpacing.xs
        : AppSpacing.section;
    return SizedBox.square(
      dimension: cote,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          borderRadius: AppRadius.arrondiSm,
        ),
        child: Center(
          child: Icon(
            icone.repos,
            size: compacte ? AppSpacing.lg : AppSpacing.xl,
            color: paire.onBackground,
          ),
        ),
      ),
    );
  }
}
