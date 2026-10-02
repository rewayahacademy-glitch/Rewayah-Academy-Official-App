// MA-7 : la destination Coran du Mode Accessibilite, AUTOUR du rendu.
//
// Une entree simple (une seule action dominante : reprendre la ou l'eleve
// s'etait arrete(e), sinon ouvrir le Coran), puis les VRAIES vues de rendu
// du moteur Coran (`VuePageMushaf`, `VueVersetAgrandi`), reprises telles
// quelles dans un enrobage propre au mode (revue MA-7 : commandes de page
// flechees, jamais coupees en plein mot, toujours atteignables). Le rendu du
// Coran (polices, mise en page des versets, Mushaf) n'est jamais touche.
// En demonstration sans serveur, l'ecran dit la vraie cause (texte non
// charge dans la demonstration) au lieu d'invoquer le reseau.
//
// « Lecture en grand texte » (preference locale `lectureGrande`) : le Coran
// s'ouvre dans le mode verset agrandi EXISTANT (`ModeRenduCoran.versetAgrandi`),
// ou vivent deja les commandes « Reduire le texte » / « Agrandir le texte ».
// Aucune traduction sous les versets (Q7).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart'
    show PositionLecture, Sourate, pagesMushafMedine;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart' show pageMushafProvider;
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../tc_mushaf/navigation_coran_feuille.dart';
import '../tc_mushaf/vue_page_mushaf.dart';
import '../tc_mushaf/vue_verset_agrandi.dart';

/// La destination Coran de l'eleve en Mode Accessibilite.
class CoranAccessibilite extends ConsumerStatefulWidget {
  /// Cree la destination.
  const CoranAccessibilite({
    required this.tutoiement,
    required this.onAide,
    this.lectureGrande,
    this.demonstration = false,
    super.key,
  });

  /// Vrai dans la demonstration sans serveur : le texte du Coran n'y est
  /// pas charge, et l'ecran le dit au lieu d'invoquer le reseau (K-59).
  final bool demonstration;

  /// « Lecture en grand texte » ; nul : la preference locale de l'appareil.
  final bool? lectureGrande;

  /// Vrai pour l'eleve mineur (tutoiement) ; un adulte est vouvoye (MA1).
  final bool tutoiement;

  /// L'aide, en dernier (MA14).
  final VoidCallback onAide;

  @override
  ConsumerState<CoranAccessibilite> createState() => _CoranAccessibiliteEtat();
}

class _CoranAccessibiliteEtat extends ConsumerState<CoranAccessibilite> {
  PositionLecture? _reprise;
  bool _ouvert = false;

  @override
  void initState() {
    super.initState();
    unawaited(_lireReprise());
  }

  /// La reprise vient du port existant : aucune position inventee.
  Future<void> _lireReprise() async {
    final PositionLecture? position;
    try {
      position = await ref
          .read(portNavigationCoranProvider)
          .dernierePositionPersonnelle();
    } on Object {
      return;
    }
    if (!mounted || position == null) return;
    setState(() => _reprise = position);
  }

  /// Ouvre le lecteur existant, sur la page de reprise s'il y en a une, et
  /// dans le mode verset agrandi si la preference le demande.
  void _ouvrir() {
    final ControleurLectureCoran lecture = ref.read(
      lectureCoranProvider.notifier,
    );
    final PositionLecture? reprise = _reprise;
    if (reprise != null) {
      lecture.allerA(reprise.page, origine: OrigineNavigation.personnelle);
    }
    if (widget.lectureGrande ??
        ref.read(preferencesLocalesProvider).lectureGrande) {
      lecture.changerMode(ModeRenduCoran.versetAgrandi);
    }
    setState(() => _ouvert = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ouvert) {
      // Le fond de lecture du theme existant (clair ou sombre), celui de la
      // coquille immersive du lecteur.
      return ColoredBox(
        color: AppPalette.of(context).surfaceQuran.background,
        child: _lecteur(context),
      );
    }
    return _entree(context);
  }

  Widget _lecteur(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return SafeArea(
      child: DefaultTextStyle(
        style: palette.surfaceQuran.applyTo(
          textes.bodyMedium ?? const TextStyle(),
        ),
        child: Column(
          key: const ValueKey<String>('coran-ma-lecteur'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionPrincipale(
                  key: const ValueKey<String>('coran-ma-retour'),
                  libelle: t.accessibilite.coran.retour,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  prefixe: _IconeAction(
                    icone: AppIcons.retour,
                    couleur: palette.inkAccent.applyTo(const TextStyle()).color,
                  ),
                  onPress: () => setState(() => _ouvert = false),
                ),
              ),
            ),
            Expanded(
              child: widget.demonstration
                  ? _demonstrationSansTexte()
                  : const LecteurCoranAccessibilite(),
            ),
          ],
        ),
      ),
    );
  }

  /// En demonstration, le texte du Coran n'est pas charge : l'ecran dit la
  /// vraie cause, ce qu'il y a a faire et ce qui reste fiable, sans aucun
  /// bouton qui ne pourrait pas aboutir (K-59).
  Widget _demonstrationSansTexte() {
    return SingleChildScrollView(
      key: const ValueKey<String>('coran-ma-demo-sans-texte'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: EmptyState(
        message: t.accessibilite.coran.demoSansTexte,
        invitation: widget.tutoiement
            ? t.accessibilite.coran.demoSansTexteDetail
            : t.accessibilite.coran.demoSansTexteDetailVous,
        icone: AppIcons.info,
        registre: RegistreVide.subi,
      ),
    );
  }

  Widget _entree(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool tu = widget.tutoiement;
    final PositionLecture? reprise = _reprise;
    final bool grande =
        widget.lectureGrande ??
        ref.watch(
          preferencesLocalesProvider.select(
            (PreferencesLocales p) => p.lectureGrande,
          ),
        );

    return PageShell(
      key: const ValueKey<String>('coran-ma-entree'),
      titre: t.eleve.coran.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (reprise != null) ...<Widget>[
            Text(
              tu
                  ? t.accessibilite.coran.reprendreDetail(
                      page: '${reprise.page}',
                    )
                  : t.accessibilite.coran.reprendreDetailVous(
                      page: '${reprise.page}',
                    ),
              style: palette.inkMuted.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              key: const ValueKey<String>('coran-ma-principale'),
              libelle: reprise == null
                  ? t.accessibilite.coran.ouvrir
                  : tu
                  ? t.accessibilite.coran.reprendre
                  : t.accessibilite.coran.reprendreVous,
              pleineLargeur: false,
              onPress: _ouvrir,
            ),
          ),
          if (grande) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              t.accessibilite.coran.lectureGrande,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.accueil.aide,
                icone: AppIcons.info,
                onPress: widget.onAide,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Le lecteur du Mode Accessibilite : les VRAIES vues de rendu du moteur
/// (`VuePageMushaf`, `VueVersetAgrandi`), reprises telles quelles, dans un
/// enrobage propre au mode.
///
/// Seul l'enrobage change par rapport a `MushafPage` (revue MA-7) : les
/// commandes de page portent une fleche directionnelle (miroitee en arabe),
/// ne coupent jamais un libelle en plein mot (cote a cote quand chaque mot
/// tient, l'une sous l'autre sinon, K-54) et restent en bas de l'ecran,
/// visibles sans defilement ; a texte tres agrandi, le bloc des commandes
/// defile dans sa moitie d'ecran au lieu de passer sous la ligne de
/// flottaison. Aucune hauteur litterale.
///
/// Repris de `MushafPage` sans rien y changer : l'enregistrement differe de
/// la position personnelle (seulement apres une navigation du lecteur) et
/// l'attribution Tanzil dans le flux.
class LecteurCoranAccessibilite extends ConsumerStatefulWidget {
  /// Cree le lecteur.
  const LecteurCoranAccessibilite({super.key});

  @override
  ConsumerState<LecteurCoranAccessibilite> createState() =>
      _LecteurCoranAccessibiliteEtat();
}

class _LecteurCoranAccessibiliteEtat
    extends ConsumerState<LecteurCoranAccessibilite> {
  /// Le delai avant d'ecrire la position, repris de `MushafPage`.
  static const Duration _delaiEnregistrement = Duration(seconds: 3);

  Timer? _enregistrement;

  @override
  void dispose() {
    _enregistrement?.cancel();
    super.dispose();
  }

  void _allerA(int page) {
    ref
        .read(lectureCoranProvider.notifier)
        .allerA(page, origine: OrigineNavigation.personnelle);
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
    if (etat.origine != OrigineNavigation.personnelle) return;
    final PageMushafVM? vue = ref.read(pageMushafProvider(etat.page)).value;
    if (vue == null || !vue.aDuTexte) return;
    await ref
        .read(portNavigationCoranProvider)
        .memoriserPositionPersonnelle(
          positionDe(vue).avecZoom(etat.zoomLocal),
          origine: OrigineNavigation.personnelle,
        );
  }

  void _zoomer(double delta) {
    ref.read(lectureCoranProvider.notifier).zoomer(delta);
    _planifierEnregistrement();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Gabarit gabarit = AppGabarit.de(context);
    final EtatLectureCoran etat = ref.watch(lectureCoranProvider);
    final AsyncValue<PageMushafVM> page = ref.watch(
      pageMushafProvider(etat.page),
    );
    final PageMushafVM? vue = page.hasValue ? page.value : null;
    final Sourate? sourate = vue == null || vue.sections.isEmpty
        ? null
        : vue.sections.first.sourate;
    final int? precedente = vue?.pagePrecedente;
    final int? suivante = vue?.pageSuivante;
    final EdgeInsetsDirectional marges = EdgeInsetsDirectional.symmetric(
      horizontal: gabarit.gouttiere,
    );

    final Widget commandes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Les commandes de page en tete du bloc : toujours les premieres
        // visibles, meme quand le bloc defile.
        _NavigationPages(
          onPrecedente: precedente == null ? null : () => _allerA(precedente),
          onSuivante: suivante == null ? null : () => _allerA(suivante),
        ),
        Ecart.vSm,
        Center(
          child: ActionPrincipale(
            libelle: t.tc.coran.navigation.ouvrir,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () => unawaited(
              FeuilleNavigationCoran.ouvrir(context, onAller: _allerA),
            ),
          ),
        ),
        if (etat.mode == ModeRenduCoran.versetAgrandi) ...<Widget>[
          Ecart.vSm,
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ActionPrincipale(
                libelle: t.eleve.coran.reduire,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => _zoomer(-0.2),
              ),
              Text(
                t.tc.coran.zoom.valeur(
                  pourcent: (etat.zoomLocal * 100).round(),
                ),
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
                onPress: () => _zoomer(0.2),
              ),
            ],
          ),
        ],
        if (vue != null && vue.aDuTexte) ...<Widget>[
          Ecart.vSm,
          Text(
            '${t.eleve.coran.edition} . ${t.eleve.coran.source} . '
            '${t.eleve.coran.sourceLien}',
            textAlign: TextAlign.center,
            style: palette.inkFaint.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: marges.add(
                const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
              ),
              child: Text(
                <String>[
                  sourate?.nomTranslittere ?? t.eleve.coran.titre,
                  t.eleve.coran.page(
                    page: '${vue?.numero ?? etat.page}',
                    total: '${vue?.nombrePages ?? pagesMushafMedine}',
                  ),
                ].join(' . '),
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
            ),
            Expanded(
              child: switch (etat.mode) {
                ModeRenduCoran.versetAgrandi => const VueVersetAgrandi(),
                _ => const VuePageMushaf(),
              },
            ),
            // Les commandes, collees en bas : jamais plus de la moitie de
            // l'ecran ; au-dela (texte tres agrandi), elles defilent.
            ConstrainedBox(
              key: const ValueKey<String>('coran-ma-commandes'),
              constraints: BoxConstraints(maxHeight: contraintes.maxHeight / 2),
              child: SingleChildScrollView(
                padding: marges.add(
                  const EdgeInsetsDirectional.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                child: commandes,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// « Page precedente » et « Page suivante », chacune avec sa fleche.
///
/// Cote a cote quand le mot le plus long de chaque libelle tient dans une
/// demi-largeur ; sinon l'une sous l'autre. Un libelle ne se coupe donc
/// jamais en plein mot (K-54). Les fleches portent `matchTextDirection` :
/// en arabe, « precedente » pointe a droite et « suivante » a gauche.
class _NavigationPages extends StatelessWidget {
  const _NavigationPages({
    required this.onPrecedente,
    required this.onSuivante,
  });

  final VoidCallback? onPrecedente;
  final VoidCallback? onSuivante;

  /// Ce que le bouton prend autour de son libelle : ses marges, la fleche
  /// et son ecart, le filet.
  static const double _habillage =
      AppSpacing.xl * 2 + AppSpacing.xl + AppSpacing.sm + AppSpacing.xs;

  /// La largeur du mot le plus long d'un libelle, au style et a l'echelle
  /// de texte courants, en graisse forte.
  static double _motLePlusLong(BuildContext context, String libelle) {
    final TextStyle style = AppTypography.graisse(
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
      FontWeight.w700,
    );
    double plusLong = 0;
    for (final String mot in libelle.split(' ')) {
      final TextPainter peintre = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      plusLong = math.max(plusLong, peintre.width);
      peintre.dispose();
    }
    return plusLong;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color? encre = onPrecedente == null
        ? palette.inkMuted.applyTo(const TextStyle()).color
        : palette.surfaceRaised.applyTo(const TextStyle()).color;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double demi = (contraintes.maxWidth - AppSpacing.sm) / 2;
        final double mot = math.max(
          _motLePlusLong(context, t.eleve.coran.pagePrecedente),
          _motLePlusLong(context, t.eleve.coran.pageSuivante),
        );
        // Ecran tres etroit a texte tres agrandi : la fleche cede sa place
        // plutot que de couper un mot ; le libelle porte seul le sens.
        final bool fleches = mot + _habillage <= contraintes.maxWidth;
        final Widget precedenteBouton = ActionPrincipale(
          key: const ValueKey<String>('coran-ma-page-precedente'),
          libelle: t.eleve.coran.pagePrecedente,
          niveau: NiveauAction.secondaire,
          prefixe: fleches
              ? _IconeAction(icone: AppIcons.retour, couleur: encre)
              : null,
          onPress: onPrecedente,
        );
        final Widget suivanteBouton = ActionPrincipale(
          key: const ValueKey<String>('coran-ma-page-suivante'),
          libelle: t.eleve.coran.pageSuivante,
          niveau: NiveauAction.secondaire,
          fleche: fleches,
          onPress: onSuivante,
        );
        if (mot + _habillage <= demi) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: precedenteBouton),
              Ecart.hSm,
              Expanded(child: suivanteBouton),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[precedenteBouton, Ecart.vSm, suivanteBouton],
        );
      },
    );
  }
}

/// L'icone posee devant le libelle d'une action, dans l'encre du bouton.
class _IconeAction extends StatelessWidget {
  const _IconeAction({required this.icone, required this.couleur});

  final AppIcon icone;
  final Color? couleur;

  @override
  Widget build(BuildContext context) =>
      Icon(icone.repos, color: couleur, size: AppSpacing.xl);
}
