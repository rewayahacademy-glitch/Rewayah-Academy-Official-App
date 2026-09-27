// MA-7 : la destination Coran du Mode Accessibilite, AUTOUR du rendu.
//
// Une entree simple (une seule action dominante : reprendre la ou l'eleve
// s'etait arrete(e), sinon ouvrir le Coran), puis la VRAIE page du moteur
// Coran (`MushafPage`), reprise telle quelle. Le rendu du Coran (polices,
// mise en page des versets, Mushaf) n'est jamais touche : cet ecran ne fait
// que choisir la page et le mode AVANT d'ouvrir le lecteur existant.
//
// « Lecture en grand texte » (preference locale `lectureGrande`) : le Coran
// s'ouvre dans le mode verset agrandi EXISTANT (`ModeRenduCoran.versetAgrandi`),
// ou vivent deja les commandes « Reduire le texte » / « Agrandir le texte ».
// Aucune traduction sous les versets (Q7).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart' show PositionLecture;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/page_mushaf_vm.dart' show ModeRenduCoran;
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../tc_mushaf/mushaf_page.dart';

/// La destination Coran de l'eleve en Mode Accessibilite.
class CoranAccessibilite extends ConsumerStatefulWidget {
  /// Cree la destination.
  const CoranAccessibilite({
    required this.tutoiement,
    required this.onAide,
    this.lectureGrande,
    super.key,
  });

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
  /// La hauteur sous laquelle le lecteur defile plutot que de deborder.
  static const double _hauteurPlancher = 1100;

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
      // Le fond du theme existant (clair ou sombre) sous la ligne de retour.
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _lecteur(context),
      );
    }
    return _entree(context);
  }

  Widget _lecteur(BuildContext context) {
    return Column(
      key: const ValueKey<String>('coran-ma-lecteur'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: Padding(
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
                onPress: () => setState(() => _ouvert = false),
              ),
            ),
          ),
        ),
        // Le lecteur existant est pose tel quel. En Mode Accessibilite
        // (cibles et texte plus grands), sa hauteur ne descend jamais sous
        // un plancher : au-dessous, la page defile au lieu de deborder.
        // Rien n'est change DANS le lecteur ni dans le rendu.
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints contraintes) {
              final double plancher = MediaQuery.textScalerOf(context)
                  .scale(_hauteurPlancher);
              if (contraintes.maxHeight >= plancher) {
                return const MushafPage();
              }
              return SingleChildScrollView(
                child: SizedBox(height: plancher, child: const MushafPage()),
              );
            },
          ),
        ),
      ],
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
