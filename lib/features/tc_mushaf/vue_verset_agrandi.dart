import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/vue_lecteur.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/content_range.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/metrique_texte_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/rosace_verset.dart';
import 'textes_lecteur_coran.dart';

/// Le rendu « lecture agrandie » : un verset a la fois, reflowable.
///
/// **Le zoom n'est pas un `Transform.scale`.** La largeur de colonne, la taille
/// de caractere, l'interligne et le nombre de lignes sont recalcules par
/// [MetriqueTexteCoran] a chaque largeur et a chaque zoom, et la taille est
/// bornee pour qu'aucun mot du corpus ne se coupe. C'est pourquoi ce rendu ne
/// deborde a aucune largeur, y compris au grossissement maximal que la base
/// accepte (4,0).
///
/// **Le zoom est local.** Il ne part pas dans l'etat partage de la classe, et
/// une page tournee par l'enseignant ne le remet pas a un. C'est l'invariant 5
/// du contrat `SharedContentState` et la decision D-21.
class VueVersetAgrandi extends ConsumerWidget {
  /// Cree le rendu verset.
  const VueVersetAgrandi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatLectureCoran etat = ref.watch(lectureCoranProvider);
    final AsyncValue<PageMushafVM> page = ref.watch(
      pageMushafProvider(etat.page),
    );

    if (!page.hasValue || page.value == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final PageMushafVM vue = page.value!;
    if (vue.etat != EtatLecteur.lecture) {
      return _EtatNonLisible(vue: vue);
    }

    return ColonneVersetsReflow(
      versets: vue.versets,
      zoom: etat.zoomLocal,
      sections: vue.sections,
    );
  }
}

/// Un etat du lecteur qui n'a pas de texte a montrer.
class _EtatNonLisible extends ConsumerWidget {
  const _EtatNonLisible({required this.vue});

  final PageMushafVM vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MA-TUTOIEMENT-1 : l'enrobage peut fournir ses phrases (vouvoiement).
    final TextesLecteurCoran? enrobage = TextesLecteurCoran.de(context);
    return switch (vue.etat) {
      EtatLecteur.chargement => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      EtatLecteur.corpusAbsent => EtatSansTexteLecteur(
        EmptyState(
          message: t.eleve.coran.absent,
          invitation: enrobage?.absentDetail ?? t.eleve.coran.absentDetail,
          icone: AppIcons.rienAAfficher,
        ),
      ),
      EtatLecteur.indisponible || EtatLecteur.lecture => EtatSansTexteLecteur(
        EmptyState(
          message: t.eleve.coran.indisponible,
          invitation:
              enrobage?.indisponibleDetail ?? t.eleve.coran.indisponibleDetail,
          icone: AppIcons.horsLigne,
          libelleAction: t.eleve.coran.reessayer,
          onAction: () => ref.invalidate(pageCorpusProvider(vue.numero)),
        ),
      ),
    };
  }
}

/// Une colonne de versets, recomposee a chaque largeur et a chaque zoom.
class ColonneVersetsReflow extends StatelessWidget {
  /// Cree la colonne.
  const ColonneVersetsReflow({
    required this.versets,
    required this.zoom,
    this.sections = const <SectionSourate>[],
    super.key,
  });

  /// Les versets a rendre, dans l'ordre du texte.
  final List<VersetCoran> versets;

  /// Le grossissement local du lecteur.
  final double zoom;

  /// Les sections, pour savoir ou une sourate commence.
  final List<SectionSourate> sections;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // [RESPONSIVE]
        final MetriqueTexteCoran metrique = MetriqueTexteCoran.calculer(
          largeurDisponible: contraintes.maxWidth,
          zoom: zoom,
          marge: gabarit.gouttiere,
          largeurMaximaleColonne: AppPage.largeurLecture,
        );

        return SingleChildScrollView(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: gabarit.gouttiere,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: SizedBox(
              width: metrique.largeurColonne,
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (metrique.zoomBride) ...<Widget>[
                      _NoticeZoomBride(metrique: metrique),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    for (final VersetCoran verset in versets) ...<Widget>[
                      BlocVerset(
                        verset: verset,
                        metrique: metrique,
                        debutDeSourate: _commenceUneSourate(verset),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _commenceUneSourate(VersetCoran verset) {
    for (final SectionSourate section in sections) {
      if (section.sourateNumero == verset.sourateNumero &&
          section.commenceLaSourate &&
          section.versets.isNotEmpty &&
          section.versets.first.numero == verset.numero) {
        return true;
      }
    }
    return false;
  }
}

/// Un verset, avec sa reference et sa rosace.
class BlocVerset extends StatelessWidget {
  /// Cree un bloc de verset.
  const BlocVerset({
    required this.verset,
    required this.metrique,
    this.debutDeSourate = false,
    super.key,
  });

  /// Le verset a rendre.
  final VersetCoran verset;

  /// Les metriques recalculees pour la largeur et le zoom courants.
  final MetriqueTexteCoran metrique;

  /// Vrai quand ce verset ouvre une sourate.
  final bool debutDeSourate;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          verset.reference,
          // La reference est de l'interface, pas du document : elle se lit de
          // gauche a droite meme au milieu d'un texte arabe.
          textAlign: TextAlign.center,
          style: palette.inkFaint.applyTo(
            AppTypography.tabulaire(textes.labelSmall ?? const TextStyle()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '${verset.texte} '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: ExcludeSemantics(
                    child: RosaceVerset(
                      numero: verset.numero,
                      echelle: metrique.echelleRosace,
                    ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.justify,
            style: palette.inkStrong.applyTo(
              AppTypography.document(
                taille: metrique.tailleTexte,
                interligne: metrique.interligne,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La notice du zoom borne.
class _NoticeZoomBride extends StatelessWidget {
  const _NoticeZoomBride({required this.metrique});

  final MetriqueTexteCoran metrique;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Text(
      '${t.tc.coran.zoom.bride} '
      '${t.tc.coran.zoom.valeur(pourcent: (metrique.zoomApplique * 100).round())}',
      textAlign: TextAlign.center,
      style: palette.inkMuted.applyTo(textes.labelSmall ?? const TextStyle()),
    );
  }
}

/// Le passage qu'une plage de travail designe, dans une page.
///
/// Pose ici parce que le mode focus et le mode verset le partagent : c'est la
/// meme question, « quels versets de cette page sont dans la plage ».
List<VersetCoran> versetsDansPlage(
  List<VersetCoran> versets,
  ContentRange? plage,
) {
  if (plage == null) {
    return versets;
  }
  final List<VersetCoran> retenus = <VersetCoran>[
    for (final VersetCoran v in versets)
      if (plage.contient(
        ContentPosition.ayah(
          resourceId: plage.resourceId,
          sourate: v.sourateNumero,
          ayah: v.numero,
        ),
      ))
        v,
  ];
  // Une plage qui ne recoupe pas la page ouverte ne doit pas vider l'ecran :
  // mieux vaut la page entiere qu'une page blanche.
  return retenus.isEmpty ? versets : retenus;
}

/// La position par defaut d'un ecran de lecture agrandie.
PositionLecture positionDe(PageMushafVM vue) {
  final List<VersetCoran> versets = vue.versets;
  if (versets.isEmpty) {
    return PositionLecture(page: vue.numero, sourate: 1, verset: 1);
  }
  final VersetCoran premier = versets.first;
  return PositionLecture(
    page: vue.numero,
    sourate: premier.sourateNumero,
    verset: premier.numero,
  );
}
