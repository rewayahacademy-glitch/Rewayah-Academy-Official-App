// Le panneau Supports (CLV-08), enseignant seulement.
//
// Repris de la Bibliotheque en classe (`ClassLibraryPicker`, ordre de
// `VueCatalogue` : continuer, recents, groupe) et de sa couverture
// (`VignetteRessource`), sans cablage serveur (K-28, BR-1). Le panneau ne
// decide rien : « Ouvrir » et les lignes des Recents appellent
// `ActionsSeance.onOuvrirSupport`, la Bibliotheque `onBibliotheque`. Un
// rappel nul = rien de rendu. Une seule zone pleine : « Voir toute la
// bibliotheque ».

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pressable.dart';
import '../tc_catalogue/vignette_ressource.dart';
import 'actions_seance.dart';
import 'panneau_seance.dart';
import 'vue_seance.dart';

/// La largeur des vignettes du panneau (image CLV-08 : ≈ 48 px).
const double _largeurVignette = AppSpacing.titreEcran - AppSpacing.xs;

/// Le contenu du panneau Supports.
class PanneauSupports extends StatelessWidget {
  const PanneauSupports({
    required this.supports,
    required this.actions,
    this.forme = FormePanneau.colonne,
    super.key,
  });

  final List<SupportDisponible> supports;
  final ActionsSeance actions;
  final FormePanneau forme;

  List<SupportDisponible> _de(RubriqueSupport rubrique) => <SupportDisponible>[
    for (final SupportDisponible s in supports)
      if (s.rubrique == rubrique) s,
  ];

  @override
  Widget build(BuildContext context) {
    final List<SupportDisponible> reprendre = _de(RubriqueSupport.reprendre);
    final List<SupportDisponible> recents = _de(RubriqueSupport.recent);
    final List<SupportDisponible> classe = _de(RubriqueSupport.classe);
    final VoidCallback? bibliotheque = actions.onBibliotheque;
    final ValueChanged<SupportDisponible>? ouvrir = actions.onOuvrirSupport;
    // Desktop : « Voir tout » n'accompagne que les Recents (image CLV-08).
    final bool voirToutClasse = forme != FormePanneau.colonne;
    // Volet et feuille : plus denses (images web etroit et telephone).
    final bool compact = forme != FormePanneau.colonne;
    return ListView(
      key: const ValueKey<String>('panneau-supports'),
      padding: EdgeInsets.only(
        bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        if (reprendre.isNotEmpty) ...<Widget>[
          _TitreRubrique(
            compact: compact,
            titre: t.salle.seance.panneauSupports.reprendre,
          ),
          _Groupe(
            lignes: <Widget>[
              for (final SupportDisponible s in reprendre)
                _LigneSupport(
                  compact: compact,
                  support: s,
                  onOuvrir: ouvrir == null || s.contenu == null
                      ? null
                      : () => ouvrir(s),
                  boutonOuvrir: true,
                ),
            ],
          ),
          if (compact) Ecart.vSm else Ecart.vMd,
        ],
        if (recents.isNotEmpty) ...<Widget>[
          _TitreRubrique(
            compact: compact,
            titre: t.salle.seance.panneauSupports.recents,
            onVoirTout: bibliotheque,
          ),
          _Groupe(
            lignes: <Widget>[
              for (final SupportDisponible s in recents)
                _LigneSupport(
                  compact: compact,
                  support: s,
                  onOuvrir: ouvrir == null || s.contenu == null
                      ? null
                      : () => ouvrir(s),
                ),
            ],
          ),
          if (compact) Ecart.vSm else Ecart.vMd,
        ],
        if (classe.isNotEmpty) ...<Widget>[
          _TitreRubrique(
            compact: compact,
            titre: t.salle.seance.panneauSupports.ressourcesClasse,
            onVoirTout: voirToutClasse ? bibliotheque : null,
          ),
          _Groupe(
            lignes: <Widget>[
              for (final SupportDisponible s in classe)
                _LigneSupport(
                  compact: compact,
                  support: s,
                  onOuvrir: bibliotheque,
                  fonds: true,
                ),
            ],
          ),
        ],
        if (bibliotheque != null) ...<Widget>[
          if (compact) Ecart.vSm else Ecart.vMd,
          // La seule zone pleine du panneau.
          ActionPrincipale(
            key: const ValueKey<String>('voir-bibliotheque'),
            libelle: t.salle.seance.panneauSupports.voirBibliotheque,
            onPress: bibliotheque,
            fleche: true,
          ),
        ],
      ],
    );
  }
}

/// « Recents » et, a droite, « Voir tout → ».
class _TitreRubrique extends StatelessWidget {
  const _TitreRubrique({
    required this.titre,
    this.onVoirTout,
    this.compact = false,
  });

  final bool compact;

  final String titre;
  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final VoidCallback? voirTout = onVoirTout;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.xs,
        0,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette.inkStrong.applyTo(
                  (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium) ??
                      const TextStyle(),
                ),
              ),
            ),
          ),
          if (voirTout != null)
            LienFleche(
              libelle: t.salle.seance.panneauSupports.voirTout,
              onPress: voirTout,
            ),
        ],
      ),
    );
  }
}

/// Une carte qui groupe des lignes, separees par un filet.
class _Groupe extends StatelessWidget {
  const _Groupe({required this.lignes});

  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderSide filet = palette.borderHairline.asBorderSide();
    return DecoratedBox(
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: filet,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < lignes.length; i++)
            if (i == 0)
              lignes[i]
            else
              DecoratedBox(
                decoration: BoxDecoration(border: Border(top: filet)),
                child: lignes[i],
              ),
        ],
      ),
    );
  }
}

/// Une ligne : vignette, textes, puis « Ouvrir » (Reprendre) ou chevron.
class _LigneSupport extends StatelessWidget {
  const _LigneSupport({
    required this.support,
    required this.onOuvrir,
    this.boutonOuvrir = false,
    this.fonds = false,
    this.compact = false,
  });

  /// Volet et feuille : titres au registre inferieur, detail sur deux lignes.
  final bool compact;

  final SupportDisponible support;

  /// `null` : ni bouton ni chevron, la ligne n'est pas pressable.
  final VoidCallback? onOuvrir;

  /// Reprendre : un bouton « Ouvrir » (contour) au lieu du chevron.
  final bool boutonOuvrir;

  /// La Bibliotheque de la Classe : un dossier au lieu d'une couverture.
  final bool fonds;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? ouvrir = onOuvrir;
    final String? surTitre = support.surTitre;
    final TextStyle titre = palette.inkStrong.applyTo(
      (compact ? textes.labelLarge : textes.titleSmall) ?? const TextStyle(),
    );
    final Widget vignette = SizedBox(
      width: _largeurVignette,
      child: fonds
          ? AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: palette.washAccent.decoration(
                  borderRadius: AppRadius.arrondiMd,
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                    child: Icon(AppIcons.bibliotheque.actif),
                  ),
                ),
              ),
            )
          : VignetteRessource(
              compacte: true,
              couverture: CouvertureRessource(
                indexTeinte: support.teinte,
                motif: MotifCouverture
                    .values[support.teinte % MotifCouverture.values.length],
                monogramme: support.monogramme,
                type: support.type,
              ),
            ),
    );
    final Widget corps = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(child: vignette),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (surTitre != null)
                  Text(
                    surTitre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titre,
                  ),
                Text(
                  support.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titre,
                ),
                Ecart.vXs,
                Text(
                  support.detail,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
          if (ouvrir != null) ...<Widget>[
            Ecart.hSm,
            if (boutonOuvrir)
              ActionPrincipale(
                key: ValueKey<String>('ouvrir-${support.id}'),
                libelle: t.salle.seance.panneauSupports.ouvrir,
                onPress: ouvrir,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
              )
            else
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.chevron.repos),
              ),
          ],
        ],
      ),
    );
    if (ouvrir == null || boutonOuvrir) {
      return KeyedSubtree(
        key: ValueKey<String>('support-${support.id}'),
        child: corps,
      );
    }
    return Pressable(
      key: ValueKey<String>('support-${support.id}'),
      onPress: ouvrir,
      libelleSemantique: fonds
          ? support.titre
          : t.salle.seance.panneauSupports.ouvrirSupport(titre: support.titre),
      arrondiFocus: AppRadius.arrondiMd,
      child: corps,
    );
  }
}
