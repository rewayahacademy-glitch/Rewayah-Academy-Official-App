import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/page_immersive.dart';
import 'navigation_coran_feuille.dart';
import 'vue_focus_classe.dart';
import 'vue_page_mushaf.dart';
import 'vue_verset_agrandi.dart';

/// Le moteur Coran : les trois rendus sur la meme source canonique.
///
/// **Il ne remplace pas `lib/features/coran/coran_page.dart`.** L'ecran
/// `ELV-04` actuel reste en place, sur sa route, avec ses consommateurs : c'est
/// Agent Z qui arbitrera le remplacement, apres l'integration. Les deux lisent
/// le meme corpus par le meme service.
///
/// Ce que cet ecran reprend de l'existant, sans le reecrire : la coquille
/// immersive [PageImmersive] en registre lecture, l'enregistrement differe de
/// la position, la regle « ne rien ecrire tant que le lecteur n'a pas navigue »,
/// et l'attribution Tanzil rendue dans le flux.
class MushafPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const MushafPage({super.key, this.sessionId});

  /// La seance en cours, quand l'ecran est ouvert depuis une classe.
  ///
  /// `null` hors classe, et c'est le cas nominal : il n'y a alors ni etat
  /// partage a suivre, ni position de groupe a proposer.
  final String? sessionId;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageEtat();
}

class _MushafPageEtat extends ConsumerState<MushafPage> {
  /// Le delai avant d'ecrire la position, une fois la page posee.
  ///
  /// Repris de l'ecran actuel : assez long pour qu'un feuilletage rapide
  /// n'ecrive pas quinze fois, assez court pour qu'une lecture interrompue
  /// garde sa place.
  static const Duration _delaiEnregistrement = Duration(seconds: 3);

  Timer? _enregistrement;
  PositionLecture? _positionPersonnelle;
  PositionLecture? _positionDeGroupe;

  @override
  void initState() {
    super.initState();
    unawaited(_lirePositions());
  }

  @override
  void dispose() {
    // Une minuterie annulable, et annulee : un `Future.delayed` qui ecrirait
    // apres la sortie de l'ecran enregistrerait une page que plus personne ne
    // lit.
    _enregistrement?.cancel();
    super.dispose();
  }

  Future<void> _lirePositions() async {
    final PortNavigationCoran navigation = ref.read(
      portNavigationCoranProvider,
    );
    final PositionLecture? personnelle = await navigation
        .dernierePositionPersonnelle();
    final String? session = widget.sessionId;
    final PositionLecture? groupe = session == null
        ? null
        : await navigation.positionDeGroupe(session);
    if (!mounted) {
      return;
    }
    setState(() {
      _positionPersonnelle = personnelle;
      _positionDeGroupe = groupe;
    });
    if (personnelle != null) {
      // Le grossissement voyage avec la position depuis les `0007` : un
      // lecteur qui a grossi son texte le retrouve grossi.
      ref.read(lectureCoranProvider.notifier).definirZoom(personnelle.zoom);
    }
  }

  void _allerA(int page, {required OrigineNavigation origine}) {
    ref.read(lectureCoranProvider.notifier).allerA(page, origine: origine);
    _planifierEnregistrement();
  }

  void _planifierEnregistrement() {
    _enregistrement?.cancel();
    _enregistrement = Timer(_delaiEnregistrement, () {
      unawaited(_enregistrer());
    });
  }

  Future<void> _enregistrer() async {
    final EtatLectureCoran etat = ref.read(lectureCoranProvider);
    // Deux barrieres, et les deux comptent. Ouvrir le Coran ne doit pas ecraser
    // le marque-page par la page d'accueil ; et une page tournee par la classe
    // ne doit jamais ecrire la position personnelle (invariant J2). La seconde
    // est aussi tenue par le port, qui refuse d'ecrire : celle-ci evite l'appel
    // inutile, elle ne le remplace pas.
    if (etat.origine != OrigineNavigation.personnelle) {
      return;
    }
    final PageMushafVM? vue = ref.read(pageMushafProvider(etat.page)).value;
    if (vue == null || !vue.aDuTexte) {
      return;
    }
    final PositionLecture position = positionDe(vue).avecZoom(etat.zoomLocal);
    await ref
        .read(portNavigationCoranProvider)
        .memoriserPositionPersonnelle(
          position,
          origine: OrigineNavigation.personnelle,
        );
    if (mounted) {
      setState(() => _positionPersonnelle = position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final EtatLectureCoran etat = ref.watch(lectureCoranProvider);
    final AsyncValue<PageMushafVM> page = ref.watch(
      pageMushafProvider(etat.page),
    );
    final PageMushafVM? vue = page.hasValue ? page.value : null;

    return PageImmersive(
      registre: RegistreImmersif.lecture,
      entete: _Entete(vue: vue, mode: etat.mode),
      commandes: _Commandes(
        vue: vue,
        mode: etat.mode,
        zoom: etat.zoomLocal,
        onPage: (int p) =>
            _allerA(p, origine: OrigineNavigation.personnelle),
        onZoom: (double delta) {
          ref.read(lectureCoranProvider.notifier).zoomer(delta);
          _planifierEnregistrement();
        },
        onNavigation: () => unawaited(
          FeuilleNavigationCoran.ouvrir(
            context,
            onAller: (int p) =>
                _allerA(p, origine: OrigineNavigation.personnelle),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Reprises(
            personnelle: _positionPersonnelle,
            groupe: _positionDeGroupe,
            pageAffichee: etat.page,
            onReprendre: (int p) =>
                _allerA(p, origine: OrigineNavigation.personnelle),
          ),
          Expanded(
            child: switch (etat.mode) {
              ModeRenduCoran.mushaf => const VuePageMushaf(),
              ModeRenduCoran.versetAgrandi => const VueVersetAgrandi(),
              ModeRenduCoran.focus => const VueFocusClasse(),
            },
          ),
          if (vue != null && vue.aDuTexte) const _Attribution(),
        ],
      ),
    );
  }
}

/// La ligne de contexte : ou l'on est, et dans quel rendu.
///
/// Elle reste visible, et ce n'est pas une entorse au mode immersif : ce sont
/// les **controles** que la Bible demande de masquer, pas le reperage. Un
/// lecteur qui ne sait plus quelle sourate il lit a perdu davantage qu'un peu
/// de place a l'ecran.
class _Entete extends ConsumerWidget {
  const _Entete({required this.vue, required this.mode});

  final PageMushafVM? vue;
  final ModeRenduCoran mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Sourate? sourate = vue == null || vue!.sections.isEmpty
        ? null
        : vue!.sections.first.sourate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          sourate?.nomTranslittere ?? t.eleve.coran.titre,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          <String>[
            t.eleve.coran.page(
              page: '${vue?.numero ?? 1}',
              total: '${vue?.nombrePages ?? pagesMushafMedine}',
            ),
            if (vue?.juzNumero != null) t.eleve.coran.juz(juz: '${vue!.juzNumero}'),
          ].join(' . '),
          style: palette.inkMuted.applyTo(
            AppTypography.tabulaire(textes.bodySmall ?? const TextStyle()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChoixMode(mode: mode),
      ],
    );
  }
}

/// Le choix du rendu.
class _ChoixMode extends ConsumerWidget {
  const _ChoixMode({required this.mode});

  final ModeRenduCoran mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: t.tc.coran.modes.choisir,
      // Trois pastilles qui passeraient a la ligne sur un ecran de 320 points
      // mangeraient la hauteur du texte. Le choix de rendu est un chrome : il
      // defile, il ne repousse pas le contenu.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final ModeRenduCoran candidat in ModeRenduCoran.values) ...[
              FilterPill(
                libelle: _libelle(candidat),
                retenue: candidat == mode,
                onPress: () => ref
                    .read(lectureCoranProvider.notifier)
                    .changerMode(candidat),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  static String _libelle(ModeRenduCoran mode) => switch (mode) {
    ModeRenduCoran.mushaf => t.tc.coran.modes.mushaf,
    ModeRenduCoran.versetAgrandi => t.tc.coran.modes.verset,
    ModeRenduCoran.focus => t.tc.coran.modes.focus,
  };
}

/// Les deux reprises : la sienne, et celle du groupe.
///
/// **Elles ne se confondent jamais.** La position personnelle appartient au
/// lecteur ; la position de groupe appartient a la seance. Les melanger
/// reviendrait a ecraser le marque-page d'un eleve avec la page du professeur,
/// ce que la migration `0007` interdit en toutes lettres.
class _Reprises extends StatelessWidget {
  const _Reprises({
    required this.personnelle,
    required this.groupe,
    required this.pageAffichee,
    required this.onReprendre,
  });

  final PositionLecture? personnelle;
  final PositionLecture? groupe;
  final int pageAffichee;
  final void Function(int page) onReprendre;

  @override
  Widget build(BuildContext context) {
    final List<Widget> bandes = <Widget>[
      // La reprise ne se propose que si elle mene ailleurs : un bouton qui
      // ramene a la page deja ouverte est une promesse vide.
      if (personnelle != null && personnelle!.page != pageAffichee)
        _BandeReprise(
          titre: t.eleve.coran.reprendre,
          detail: t.eleve.coran.reprendreDetail(page: '${personnelle!.page}'),
          onPress: () => onReprendre(personnelle!.page),
        ),
      if (groupe != null && groupe!.page != pageAffichee)
        _BandeReprise(
          titre: t.tc.coran.reprise.groupe,
          detail: t.tc.coran.reprise.groupeDetail(page: groupe!.page),
          onPress: () => onReprendre(groupe!.page),
        ),
    ];
    if (bandes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget bande in bandes) ...<Widget>[
            bande,
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Une bande de reprise : elle propose, elle ne teleporte pas.
class _BandeReprise extends StatelessWidget {
  const _BandeReprise({
    required this.titre,
    required this.detail,
    required this.onPress,
  });

  final String titre;
  final String detail;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      onPress: onPress,
      libelleSemantique: titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            titre,
            style: palette.inkAccent.applyTo(
              textes.labelLarge ?? const TextStyle(),
            ),
          ),
          Text(
            detail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// La provenance du texte, au pied de l'ecran.
///
/// **Elle n'est pas negociable et elle n'est pas dans un reglage** : la licence
/// Tanzil demande que la source soit clairement indiquee et que tanzil.net
/// soit joignable. Un credit relegue dans un ecran « a propos » ne serait lu
/// par personne.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        '${t.eleve.coran.edition} . ${t.eleve.coran.source} . '
        '${t.eleve.coran.sourceLien}',
        textAlign: TextAlign.center,
        style: palette.inkFaint.applyTo(
          textes.labelSmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Les commandes du lecteur.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.vue,
    required this.mode,
    required this.zoom,
    required this.onPage,
    required this.onZoom,
    required this.onNavigation,
  });

  final PageMushafVM? vue;
  final ModeRenduCoran mode;
  final double zoom;
  final void Function(int page) onPage;
  final void Function(double delta) onZoom;
  final VoidCallback onNavigation;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final int? precedente = vue?.pagePrecedente;
    final int? suivante = vue?.pageSuivante;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (mode == ModeRenduCoran.mushaf)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              t.tc.coran.zoom.renvoiLectureAgrandie,
              textAlign: TextAlign.center,
              style: palette.inkFaint.applyTo(
                textes.labelSmall ?? const TextStyle(),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            // `Wrap` et non `Row` : les trois libelles de la commande de
            // taille ne tiennent pas sur une ligne de 320 points, et un
            // `Row` y deborderait au lieu de passer a la ligne.
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                // Deux libelles plutot que deux icones : le catalogue n'a ni
                // « plus » ni « moins », et inventer un point de code Phosphor
                // au juge poserait un carre vide sur l'ecran de lecture.
                ActionPrincipale(
                  libelle: t.eleve.coran.reduire,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => onZoom(-0.2),
                ),
                Text(
                  t.tc.coran.zoom.valeur(pourcent: (zoom * 100).round()),
                  style: palette.inkMuted.applyTo(
                    AppTypography.tabulaire(
                      textes.labelMedium ?? const TextStyle(),
                    ),
                  ),
                ),
                ActionPrincipale(
                  libelle: t.eleve.coran.agrandir,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => onZoom(0.2),
                ),
              ],
            ),
          ),
        // NAV-FLECHES-1 : fleche, position, fleche ; aux bornes la fleche
        // disparait. Le choix d'une page ou d'une sourate reste dessous, un
        // lien discret.
        BarrePrecedentSuivant(
          position: t.salle.seance.page(
            page: vue?.numero ?? 1,
            pages: vue?.nombrePages ?? pagesMushafMedine,
          ),
          positionSemantique: t.salle.seance.pageSemantique(
            page: vue?.numero ?? 1,
            pages: vue?.nombrePages ?? pagesMushafMedine,
          ),
          libellePrecedent: t.eleve.coran.pagePrecedente,
          libelleSuivant: t.eleve.coran.pageSuivante,
          onPrecedent: precedente == null ? null : () => onPage(precedente),
          onSuivant: suivante == null ? null : () => onPage(suivante),
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionPrincipale(
          libelle: t.tc.coran.navigation.ouvrir,
          niveau: NiveauAction.tertiaire,
          onPress: onNavigation,
        ),
      ],
    );
  }
}
