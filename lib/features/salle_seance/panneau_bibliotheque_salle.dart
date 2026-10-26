// Plan de composition du 26/10/2026 (docs/current/maquettes/salle/
// PLAN-SALLE-COMPOSITION-2026-10-26.md §2) : la Bibliotheque de la salle de
// l'enseignant, panneau de droite sur ordinateur.
//
// Recherche, trois filtres (Recents, Pour cette Classe, Tous), puis les
// supports avec leur couverture ([VignetteRessource]). Toucher un support
// deplie sa carte sur place : grande couverture, UN bouton plein
// « Presenter », et « Reprendre page N » quand la classe a une page retenue.
// Rien ne s'ouvre au milieu de la salle.
//
// Verite (plan §2) : la salle ne presente aujourd'hui que le Coran. Le
// panneau liste ce qui peut etre presente, rien d'autre, et ne promet aucun
// support a venir.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../tc_catalogue/vignette_ressource.dart';

/// Un support que la salle peut presenter maintenant.
@immutable
class SupportBibliotheque {
  const SupportBibliotheque({
    required this.id,
    required this.titre,
    required this.detail,
    required this.couverture,
    required this.onPresenter,
    this.pageReprise,
    this.onReprendre,
  });

  final String id;
  final String titre;

  /// La ligne sous le titre (« Page 24 · Dernière séance »).
  final String detail;
  final CouvertureRessource couverture;

  /// « Presenter » : le support s'ouvre pour toute la classe.
  final VoidCallback onPresenter;

  /// La page retenue pour cette Classe, ou `null`.
  final int? pageReprise;

  /// « Reprendre page N », ou `null`.
  final VoidCallback? onReprendre;

  /// Presente dans cette Classe (une page est retenue).
  bool get recent => pageReprise != null;
}

/// Les filtres de la Bibliotheque.
enum FiltreBibliotheque { recents, classe, tous }

/// La Bibliotheque de la salle, dans son panneau.
class PanneauBibliothequeSalle extends StatefulWidget {
  const PanneauBibliothequeSalle({
    required this.supports,
    required this.onFermer,
    super.key,
  });

  final List<SupportBibliotheque> supports;
  final VoidCallback onFermer;

  /// La cle du panneau (tests, captures).
  static const Key cle = ValueKey<String>('salle-panneau-bibliotheque');

  @override
  State<PanneauBibliothequeSalle> createState() => _EtatPanneauBibliotheque();
}

class _EtatPanneauBibliotheque extends State<PanneauBibliothequeSalle> {
  final TextEditingController _recherche = TextEditingController();
  FiltreBibliotheque _filtre = FiltreBibliotheque.tous;
  String? _deplie;

  /// La carte depliee : amenee entiere dans la liste, « Presenter » et
  /// « Reprendre » compris (comme la carte d'un eleve).
  final GlobalKey _carteDepliee = GlobalKey(debugLabel: 'support-deplie');

  void _basculer(String id) {
    setState(() => _deplie = _deplie == id ? null : id);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? carte = _carteDepliee.currentContext;
      if (!mounted || carte == null) return;
      unawaited(
        Scrollable.ensureVisible(
          carte,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  List<SupportBibliotheque> get _visibles {
    final String cherche = _recherche.text.trim().toLowerCase();
    return <SupportBibliotheque>[
      for (final SupportBibliotheque s in widget.supports)
        if ((_filtre == FiltreBibliotheque.tous || s.recent) &&
            (cherche.isEmpty || s.titre.toLowerCase().contains(cherche)))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<SupportBibliotheque> visibles = _visibles;
    Widget filtre(FiltreBibliotheque f, String libelle) => FilterPill(
      key: ValueKey<String>('bibliotheque-filtre-${f.name}'),
      libelle: libelle,
      retenue: _filtre == f,
      onPress: () => setState(() => _filtre = f),
    );
    // Le panneau defile d'un seul tenant : a 720 de haut et texte x2, la
    // tete (titre, recherche, filtres) ne prend jamais toute la place.
    return ListView(
      key: PanneauBibliothequeSalle.cle,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                t.tc.bibliotheque.titre,
                style: palette.inkStrong.applyTo(
                  textes.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            BoutonIcone(
              key: const ValueKey<String>('bibliotheque-fermer'),
              icone: AppIcons.fermer,
              libelle: t.commun.fermer,
              infobulle: t.commun.fermer,
              forme: FormeBoutonIcone.nue,
              onPress: widget.onFermer,
            ),
          ],
        ),
        Ecart.vSm,
        ChampRecherche(
          controleur: _recherche,
          libelle: t.tc.bibliotheque.rechercheLibelle,
          aide: t.tc.bibliotheque.rechercheIndication,
          cleChamp: const ValueKey<String>('bibliotheque-recherche'),
          onChange: (String _) => setState(() {}),
        ),
        Ecart.vSm,
        // Plan §2 : les trois filtres toujours visibles, jamais derriere
        // « Plus ».
        RangeeFiltres(
          replier: false,
          filtres: <Widget>[
            filtre(
              FiltreBibliotheque.recents,
              t.tc.bibliotheque.sections.recents,
            ),
            filtre(
              FiltreBibliotheque.classe,
              t.salle.seance.bibliotheque.cetteClasse,
            ),
            filtre(FiltreBibliotheque.tous, t.salle.seance.bibliotheque.tous),
          ],
        ),
        Ecart.vLg,
        if (visibles.isEmpty)
          Text(
            t.tc.bibliotheque.aucunResultat.message,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          // K-55 : des cartes independantes, 16 entre elles.
          PileCartes(
            children: <Widget>[
              for (final SupportBibliotheque s in visibles)
                _CarteSupport(
                  key: _deplie == s.id ? _carteDepliee : null,
                  support: s,
                  deplie: _deplie == s.id,
                  onBasculer: () => _basculer(s.id),
                ),
            ],
          ),
      ],
    );
  }
}

/// La carte d'un support : couverture, titre, detail ; depliee, la grande
/// couverture, « Presenter » et « Reprendre page N ».
class _CarteSupport extends StatelessWidget {
  const _CarteSupport({
    super.key,
    required this.support,
    required this.deplie,
    required this.onBasculer,
  });

  final SupportBibliotheque support;
  final bool deplie;
  final VoidCallback onBasculer;

  /// La largeur de la petite couverture d'une ligne.
  static const double _vignette = AppSpacing.xxxl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? reprendre = support.onReprendre;
    final int? page = support.pageReprise;
    return DecoratedBox(
      key: ValueKey<String>('bibliotheque-support-${support.id}'),
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              expanded: deplie,
              child: Pressable(
                key: ValueKey<String>('bibliotheque-deplier-${support.id}'),
                onPress: onBasculer,
                libelleSemantique: '${support.titre}, ${support.detail}',
                arrondiFocus: AppRadius.arrondiSm,
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: _vignette,
                          child: VignetteRessource(
                            couverture: support.couverture,
                            compacte: true,
                          ),
                        ),
                        Ecart.hMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                support.titre,
                                style: palette.inkStrong.applyTo(
                                  textes.titleSmall ?? const TextStyle(),
                                ),
                              ),
                              Text(
                                support.detail,
                                style: palette.inkMuted.applyTo(
                                  textes.bodySmall ?? const TextStyle(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconTheme(
                          data: palette.inkStrong.asIconTheme(
                            size: AppSpacing.xl,
                          ),
                          child: Icon(
                            deplie
                                ? AppIcons.replier.repos
                                : AppIcons.chevron.repos,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (deplie) ...<Widget>[
              Ecart.vMd,
              Center(
                child: SizedBox(
                  width: _vignette * 3,
                  child: VignetteRessource(couverture: support.couverture),
                ),
              ),
              Ecart.vLg,
              // K-56 : le seul bouton plein du panneau, en bas de la carte,
              // sur toute sa largeur.
              ActionPrincipale(
                key: ValueKey<String>('bibliotheque-presenter-${support.id}'),
                libelle: t.salle.seance.bibliotheque.presenter,
                onPress: support.onPresenter,
                pleineLargeur: true,
              ),
              if (reprendre != null && page != null) ...<Widget>[
                Ecart.vSm,
                LienFleche(
                  key: ValueKey<String>('bibliotheque-reprendre-${support.id}'),
                  libelle: t.salle.seance.bibliotheque.reprendrePage(
                    page: page,
                  ),
                  onPress: reprendre,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
