// D9 (24/10/2026, decision du pilote deleguee par le directeur) : en salle,
// la page du Coran presentee se lit comme dans un mushaf, quinze lignes de
// l'edition de Medine, et non plus en texte continu.
//
// Le composant partage de page que `panneau_enseignant.dart` attendait
// (« faute d'un widget partage de page de mushaf ») : `pageMushafProvider`
// assemble corpus, sourates et mise en page ; `PageMadina15` compose la page
// avec UthmanicHafs. Sans cette police ou sans mise en page Madina, un etat
// visible dit ce qui manque et quoi faire (K-59), jamais un texte continu
// illisible.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/passage_salle.dart' show FonduAuChangement;
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../salle_seance/telephone_plein_ecran.dart'
    show arrondiPageSalle, pleinEcranSalle;
import '../tc_mushaf/page_madina_15.dart';
import '../tc_mushaf/police_mushaf.dart';

/// Vrai quand la page [numero] se compose vraiment (mise en page Madina et
/// police UthmanicHafs lues) : la salle ne lui donne toute la largeur ou
/// toute la hauteur qu'alors ; un etat d'attente ou d'erreur garde la
/// composition qui tient son action a l'ecran (SALLE-ERR-320-1).
bool pageCoranLisible(WidgetRef ref, int numero) =>
    ref.watch(pageMushafProvider(numero)).value?.estMadina15 == true &&
    ref.watch(policeMushafDisponibleProvider).value == true;

/// Vrai quand la page [numero] montre son etat d'erreur (« Reessayer ») :
/// mise en page et police lues, mais la page ne se compose pas. Pendant
/// l'attente, faux.
bool pageCoranEnErreur(WidgetRef ref, int numero) {
  final AsyncValue<PageMushafVM> page = ref.watch(pageMushafProvider(numero));
  final AsyncValue<bool> police = ref.watch(policeMushafDisponibleProvider);
  final bool resolues =
      (page.hasValue || page.hasError) &&
      (police.hasValue || police.hasError) &&
      !_miseEnPageEnLecture(ref, numero);
  return resolues && !pageCoranLisible(ref, numero);
}

/// PAGES-FLUIDES : vrai tant que la mise en page de [numero] (ou ce que sa
/// source promet) n'est pas encore lue. La page calculee se resout alors
/// sans lignes : ce n'est pas une erreur, c'est une attente.
bool _miseEnPageEnLecture(WidgetRef ref, int numero) {
  bool attend(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;
  return attend(ref.watch(layoutPageProvider(numero))) ||
      attend(ref.watch(disponibiliteLayoutProvider));
}

/// S0 : les etats de la page et du panneau de l'enseignant se posent sur
/// la carte claire de la salle de seance, et non plus sur son fond
/// (`PageImmersive`) : leur encre est alors celle de la carte.
class SurCarteSalle extends InheritedWidget {
  /// Pose [child] sur la carte de la salle de seance.
  const SurCarteSalle({required super.child, super.key});

  @override
  bool updateShouldNotify(SurCarteSalle ancien) => false;
}

/// SALLE-ENCRE-1 : l'encre des etats sans page, celle du fond de la salle
/// (`surfaceInverse`), ou celle de la carte sous [SurCarteSalle].
AppColorPair encreSalle(BuildContext context) {
  final AppPalette palette = AppPalette.of(context);
  return context.dependOnInheritedWidgetOfExactType<SurCarteSalle>() == null
      ? palette.surfaceInverse
      : palette.surfaceRaised;
}

/// La page [numero] du mushaf, telle que la salle la montre.
///
/// PAGES-FLUIDES (directeur, 12/11/2026 : « tourner une page donne
/// l'impression que ca plante ») :
///
/// - **l'ancienne page reste** a l'ecran tant que la nouvelle n'est pas
///   composee, puis la nouvelle entre par un fondu court
///   ([FonduAuChangement], [AppMouvement.fonduEntree]) ; sous « reduire les
///   animations », le changement est immediat ;
/// - le squelette ne sert qu'au tout premier affichage, a la forme d'une page
///   entiere ;
/// - les pages voisines (precedente et suivante) sont lues en avance
///   ([pagesVoisines]) : le tour suivant n'attend aucune lecture.
class PageCoranSalle extends ConsumerStatefulWidget {
  /// Cree la page.
  const PageCoranSalle({
    required this.numero,
    this.surCarte = false,
    this.enPreparation = false,
    super.key,
  });

  /// S0 : posee dans la surface a page fixe de la salle de seance.
  final bool surCarte;

  /// Le numero de la page du mushaf, de 1 a 604.
  final int numero;

  /// PAGES-FLUIDES : vrai quand l'enseignant a demande une autre page, qui
  /// n'est pas encore lue : une barre fine le dit en tete de la page (le
  /// geste est compris), l'ancienne page reste lisible dessous.
  final bool enPreparation;

  /// La page composee (tests et captures).
  static const Key cle = ValueKey<String>('page-coran-salle');

  /// L'etat qui dit que la page ne peut pas s'afficher.
  static const Key cleIndisponible = ValueKey<String>(
    'page-coran-salle-indisponible',
  );

  /// PAGES-FLUIDES : le squelette du premier affichage, a la forme d'une page.
  static const Key cleSquelette = ValueKey<String>('page-coran-salle-attente');

  /// PAGES-FLUIDES : la barre « page demandee, en lecture ».
  static const Key clePreparation = ValueKey<String>(
    'page-coran-salle-preparation',
  );

  @override
  ConsumerState<PageCoranSalle> createState() => _EtatPageCoranSalle();
}

class _EtatPageCoranSalle extends ConsumerState<PageCoranSalle> {
  /// La derniere page composee : elle reste a l'ecran pendant que la
  /// suivante se lit.
  PageMushafVM? _montree;

  @override
  Widget build(BuildContext context) =>
      widget.surCarte ? SurCarteSalle(child: _page()) : _page();

  Widget _page() => Builder(builder: _rendu);

  /// Lit en avance les pages voisines de [numero]. Les familles de pages ne
  /// se jettent pas : une lecture faite reste en cache pour le tour suivant.
  void _prechargerVoisines(int numero) {
    for (final int voisine in pagesVoisines(numero)) {
      ref.read(pageMushafProvider(voisine));
    }
  }

  Widget _rendu(BuildContext context) {
    final int numero = widget.numero;
    final AsyncValue<PageMushafVM> page = ref.watch(pageMushafProvider(numero));
    final AsyncValue<bool> police = ref.watch(policeMushafDisponibleProvider);
    // Les etats sans page se posent sur le fond de la salle (SALLE-ENCRE-1).
    final AppColorPair salle = encreSalle(context);
    _prechargerVoisines(numero);

    // `hasValue` et non le type d'execution (piege deja paye, lib/CLAUDE.md).
    final bool resolue =
        (page.hasValue || page.hasError) && (police.hasValue || police.hasError);
    final PageMushafVM? vue = page.value;
    final bool lisible =
        resolue &&
        vue != null &&
        vue.numero == numero &&
        vue.estMadina15 &&
        police.value == true;
    if (lisible) {
      _montree = vue;
      return _composee(context, vue);
    }
    // En lecture (premiere lecture, ou relecture apres un changement de
    // source) : l'ancienne page reste ; sans ancienne page, la forme d'une
    // page.
    final bool enLecture =
        !resolue ||
        _miseEnPageEnLecture(ref, numero) ||
        (page.isLoading && !page.hasError);
    if (enLecture) {
      final PageMushafVM? ancienne = _montree;
      return ancienne != null
          ? _composee(context, ancienne)
          : _squelette(context);
    }
    _montree = null;
    return EmptyState(
      key: PageCoranSalle.cleIndisponible,
      message: t.salle.coran.indisponible,
      invitation: t.salle.coran.indisponibleDetail,
      icone: AppIcons.rienAAfficher,
      libelleAction: t.commun.reessayer,
      // RECHARGE-1 (03/11/2026) : la page se calcule a partir de quatre
      // lectures ; une source en echec restait en echec si on n'invalidait
      // que la page. On relit tout.
      onAction: () {
        ref
          ..invalidate(policeMushafDisponibleProvider)
          ..invalidate(pageCorpusProvider(numero))
          ..invalidate(layoutPageProvider(numero))
          ..invalidate(souratesCoranProvider)
          ..invalidate(disponibiliteLayoutProvider)
          ..invalidate(pageMushafProvider(numero));
      },
      encre: salle,
    );
  }

  /// PAGES-FLUIDES : le premier affichage, a la forme d'une page entiere
  /// (et non six lignes en haut d'un ecran vide).
  Widget _squelette(BuildContext context) {
    final bool plein = pleinEcranSalle(context);
    return Padding(
      key: PageCoranSalle.cleSquelette,
      padding: plein ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) {
          final double largeur = c.maxWidth.isFinite ? c.maxWidth : 0;
          final double naturelle = largeur * ratioHauteurPageMadina15;
          final double hauteur = c.maxHeight.isFinite
              ? (plein ? c.maxHeight : math.min(c.maxHeight, naturelle))
              : naturelle;
          return Center(
            child: Skeleton(hauteur: hauteur, largeur: largeur),
          );
        },
      ),
    );
  }

  Widget _composee(BuildContext context, PageMushafVM vue) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final bool plein = pleinEcranSalle(context);
    // En registre de lecture, sur le parchemin du lecteur (`surfaceQuran`) :
    // un texte coranique ne se lit pas sur un fond de scene video.
    return DecoratedBox(
      key: PageCoranSalle.cle,
      // S0.2c, K4 : dans `/salle`, la page remplit sa boite. Amende par la
      // demande du directeur du 12/11/2026 (cadre et marges, PAGES-FLUIDES) :
      // la boite de la page est entouree d'une marge et arrondie
      // (`margesPageSalle`, `pageSalle`) ; la page en suit l'arrondi.
      decoration: palette.surfaceQuran.decoration(
        borderRadius: plein ? arrondiPageSalle : metriques.arrondi,
      ),
      // S0.2d, K4 : aucune marge interieure en plein cadre ; la marge est
      // celle de la boite (demande du directeur du 12/11/2026).
      child: Padding(
        padding: plein ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints contraintes) =>
                    FonduAuChangement(
                      cle: vue.numero,
                      child: Center(
                        child: PageMadina15(
                          vue: vue,
                          largeur: contraintes.maxWidth,
                          hauteur: contraintes.maxHeight.isFinite
                              ? contraintes.maxHeight
                              : null,
                          pleineHauteur: plein,
                        ),
                      ),
                    ),
              ),
            ),
            if (widget.enPreparation)
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: _BarrePreparation(palette: palette),
              ),
          ],
        ),
      ),
    );
  }
}

/// PAGES-FLUIDES : la barre fine qui dit « la page demandee se lit ». Sous
/// « reduire les animations », une barre fixe : l'information reste, sans
/// mouvement.
class _BarrePreparation extends StatelessWidget {
  const _BarrePreparation({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LinearProgressIndicator(
      key: PageCoranSalle.clePreparation,
      value: AppMouvement.mouvementReduit(context) ? 1 : null,
      minHeight: AppSpacing.xs,
      color: palette.surfacePrimary.background,
      backgroundColor: palette.surfaceSunken.background,
    ),
  );
}
