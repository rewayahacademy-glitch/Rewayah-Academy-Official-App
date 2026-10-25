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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../salle_seance/telephone_plein_ecran.dart' show pleinEcranSalle;
import '../tc_mushaf/page_madina_15.dart';
import '../tc_mushaf/police_mushaf.dart';

/// Vrai quand la page [numero] se compose vraiment (mise en page Madina et
/// police UthmanicHafs lues) : la salle ne lui donne toute la largeur ou
/// toute la hauteur qu'alors ; un etat d'attente ou d'erreur garde la
/// composition qui tient son action a l'ecran (SALLE-ERR-320-1).
bool pageCoranLisible(WidgetRef ref, int numero) =>
    ref.watch(pageMushafProvider(numero)).value?.estMadina15 == true &&
    ref.watch(policeMushafDisponibleProvider).value == true;

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
class PageCoranSalle extends ConsumerWidget {
  /// Cree la page.
  const PageCoranSalle({
    required this.numero,
    this.surCarte = false,
    super.key,
  });

  /// S0 : posee dans la surface a page fixe de la salle de seance.
  final bool surCarte;

  /// Le numero de la page du mushaf, de 1 a 604.
  final int numero;

  /// La page composee (tests et captures).
  static const Key cle = ValueKey<String>('page-coran-salle');

  /// L'etat qui dit que la page ne peut pas s'afficher.
  static const Key cleIndisponible = ValueKey<String>(
    'page-coran-salle-indisponible',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      surCarte ? SurCarteSalle(child: _page(ref)) : _page(ref);

  Widget _page(WidgetRef ref) =>
      Builder(builder: (BuildContext context) => _rendu(context, ref));

  Widget _rendu(BuildContext context, WidgetRef ref) {
    final AsyncValue<PageMushafVM> page = ref.watch(pageMushafProvider(numero));
    final AsyncValue<bool> police = ref.watch(policeMushafDisponibleProvider);
    final AppPalette palette = AppPalette.of(context);
    // Les etats sans page se posent sur le fond de la salle (SALLE-ENCRE-1).
    final AppColorPair salle = encreSalle(context);

    // `hasValue` et non le type d'execution (piege deja paye, lib/CLAUDE.md).
    if (!page.hasValue && !page.hasError ||
        !police.hasValue && !police.hasError) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Skeleton.texte(lignes: 6),
      );
    }
    final PageMushafVM? vue = page.value;
    if (vue == null || !vue.estMadina15 || police.value != true) {
      return EmptyState(
        key: cleIndisponible,
        message: t.salle.coran.indisponible,
        invitation: t.salle.coran.indisponibleDetail,
        icone: AppIcons.rienAAfficher,
        libelleAction: t.commun.reessayer,
        onAction: () {
          ref
            ..invalidate(policeMushafDisponibleProvider)
            ..invalidate(pageMushafProvider(numero));
        },
        encre: salle,
      );
    }

    final AppMetriques metriques = AppMetriques.of(context);
    // En registre de lecture, sur le parchemin du lecteur (`surfaceQuran`) :
    // un texte coranique ne se lit pas sur un fond de scene video.
    return DecoratedBox(
      key: cle,
      // S0.2c, K4 : dans `/salle`, la page est l'ecran, bord a bord, sans arrondi.
      decoration: palette.surfaceQuran.decoration(
        borderRadius: pleinEcranSalle(context)
            ? BorderRadius.zero
            : metriques.arrondi,
      ),
      // S0.2d, K4 : zero marge ; la page remplit sa boite.
      child: Padding(
        padding: pleinEcranSalle(context)
            ? EdgeInsets.zero
            : const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) => Center(
            child: PageMadina15(
              vue: vue,
              largeur: contraintes.maxWidth,
              hauteur: contraintes.maxHeight.isFinite
                  ? contraintes.maxHeight
                  : null,
              pleineHauteur: pleinEcranSalle(context),
            ),
          ),
        ),
      ),
    );
  }
}
