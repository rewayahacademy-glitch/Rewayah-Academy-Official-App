import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/tc_etat_partage/shared_content_state.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../tc_mushaf/navigation_coran_feuille.dart';
import '../tc_mushaf/vue_focus_classe.dart';
import '../tc_mushaf/vue_page_mushaf.dart';
import '../tc_mushaf/vue_verset_agrandi.dart';
import 'etat_partage_classe.dart';

/// Le Coran presente a la classe : le renderer d'Agent C, suivi par l'etat
/// partage, pilote par l'enseignant.
///
/// [QURAN-STAGE] **L'etat partage decide de la page et du mode ; le zoom
/// reste a chacun** (D-21). Une revision arrive → la page est resolue par
/// `PortNavigationCoran` (la pagination appartient a l'edition) → le lecteur
/// local l'applique par `fusionnerPartage`, qui refuse toute revision deja
/// suivie. L'eleve suit automatiquement ; s'il feuillette ailleurs, une bande
/// lui propose de revenir, **seulement dans ce cas** (Bible section 25).
///
/// **Le pilote publie par le meme chemin qu'il lit.** Tourner une page, aller
/// a un verset, changer de mode : chaque geste devient une revision de
/// `SharedContentState`, et c'est cette revision, recue, qui deplace l'ecran
/// de l'enseignant. Aucun champ « page que je presente » n'existe ici ; le
/// lot N5 avait pose la meme regle pour `contenuPresenteProvider`.
///
/// **Chrome sous le texte, jamais dessus** (Bible section 22) : une ligne de
/// repere en haut, une rangee de commandes en bas, et le dock, s'il y en a un,
/// se reserve sa place par `HoteDuDock`.
class SupportCoranClasse extends ConsumerStatefulWidget {
  /// Cree la surface.
  const SupportCoranClasse({
    required this.sessionId,
    required this.peutPiloter,
    super.key,
  });

  /// La seance suivie.
  final String sessionId;

  /// Le jeton autorise a piloter le support (`can_publish_data`).
  final bool peutPiloter;

  @override
  ConsumerState<SupportCoranClasse> createState() => _SupportCoranClasseEtat();
}

class _SupportCoranClasseEtat extends ConsumerState<SupportCoranClasse> {
  /// Un feuilletage rapide au doigt ne publie qu'a l'arret : le canal fiable
  /// porte des tours de page, pas des sursauts. Le plafond du systeme de
  /// mouvement est la bonne mesure d'« arret » : au-dela, l'oeil a fini.
  final Debounce _publication = Debounce(AppMouvement.plafond);

  /// La page que la classe presente, resolue. `null` tant qu'aucune revision
  /// n'a ete suivie.
  int? _pagePartagee;

  /// La derniere revision appliquee au lecteur local, pour n'appliquer chaque
  /// revision qu'une fois par construction. `fusionnerPartage` refuse de toute
  /// facon une revision deja suivie : ceci evite seulement l'appel.
  SharedContentState? _derniereAppliquee;

  /// Ce que le dernier geste de publication a dit. `null` = rien a dire.
  String? _message;

  @override
  void dispose() {
    _publication.annuler();
    super.dispose();
  }

  Future<void> _appliquer(SharedContentState? etat) async {
    if (etat == null || etat.resourceId != identifiantRessourceCoran) {
      return;
    }
    final PortNavigationCoran navigation = ref.read(
      portNavigationCoranProvider,
    );
    final ContentPosition p = etat.contentPosition;
    final int? page = switch (p.typeAncrage) {
      TypeAncrage.ayah when p.sourate != null && p.ayah != null =>
        await navigation.pageDe(CibleAyah(sourate: p.sourate!, ayah: p.ayah!)),
      TypeAncrage.page when p.page != null => p.page,
      _ => null,
    };
    if (!mounted) {
      return;
    }
    setState(() => _pagePartagee = page ?? _pagePartagee);
    ref.read(lectureCoranProvider.notifier).appliquerPartage(etat, page: page);
  }

  Future<void> _publierPage(int page) async {
    final PageMushafVM vue = await ref.read(pageMushafProvider(page).future);
    if (!vue.aDuTexte) {
      return;
    }
    await _publier(
      () => ref
          .read(presentateurClasseProvider)(widget.sessionId)
          .deplacer(positionDe(vue).versContentPosition()),
    );
  }

  Future<void> _publierMode(ModeRenduCoran mode) => _publier(
    () => ref.read(presentateurClasseProvider)(widget.sessionId).changerMode(
      switch (mode) {
        ModeRenduCoran.mushaf => ModeAffichagePartage.page,
        ModeRenduCoran.versetAgrandi => ModeAffichagePartage.verse,
        ModeRenduCoran.focus => ModeAffichagePartage.focus,
      },
    ),
  );

  /// Publie, et **dit** l'echec. Le lecteur local a deja bouge : le service
  /// diffuse aux abonnes locaux avant d'emettre au reseau, donc l'enseignant
  /// voit sa page, et lit seulement que le groupe pourrait ne pas suivre.
  Future<void> _publier(Future<void> Function() geste) async {
    try {
      await geste();
      if (mounted && _message != null) {
        setState(() => _message = null);
      }
    } on Object {
      if (mounted) {
        setState(() => _message = t.tc.classe.support.publicationEchec);
      }
    }
  }

  void _revenir() {
    final int? page = _pagePartagee;
    if (page != null) {
      ref
          .read(lectureCoranProvider.notifier)
          .allerA(page, origine: OrigineNavigation.groupe);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le pilote qui feuillette au doigt publie ; le suiveur, non. Une page
    // posee par la classe (`origine == groupe`) ne se republie pas : sinon la
    // revision recue en produirait une seconde, a l'infini.
    if (widget.peutPiloter) {
      ref.listen<(int, OrigineNavigation)>(
        lectureCoranProvider.select(
          (EtatLectureCoran e) => (e.page, e.origine),
        ),
        ((int, OrigineNavigation)? avant, (int, OrigineNavigation) apres) {
          if (apres.$2 == OrigineNavigation.personnelle &&
              avant?.$1 != apres.$1) {
            _publication.planifier(() => unawaited(_publierPage(apres.$1)));
          }
        },
      );
    }

    final AsyncValue<SharedContentState?> partage = ref.watch(
      etatPartageClasseProvider(widget.sessionId),
    );
    // La revision recue applique la page et le mode, pour tout le monde --
    // apres la construction, jamais pendant : un `setState` dans `build`
    // serait une faute, et la resolution de page est asynchrone.
    if (partage.value != null && partage.value != _derniereAppliquee) {
      _derniereAppliquee = partage.value;
      scheduleMicrotask(() => unawaited(_appliquer(_derniereAppliquee)));
    }
    final EtatLectureCoran etat = ref.watch(lectureCoranProvider);
    final AsyncValue<PageMushafVM> page = ref.watch(
      pageMushafProvider(etat.page),
    );
    final PageMushafVM? vue = page.hasValue ? page.value : null;

    // **Une restauration en echec se dit** : « rien n'est presente » et « je
    // n'ai pas pu lire » sont deux ecrans (lot F, TC-Z-SUIVI).
    if (partage.hasError && partage.value == null) {
      return Center(
        child: EmptyState(
          message: t.tc.realtime.etat.restauration_impossible,
          invitation: t.tc.classe.support.aucunDetailEleve,
          icone: AppIcons.horsLigne,
          libelleAction: t.tc.classe.prevol.reessayer,
          onAction: () =>
              ref.invalidate(etatPartageClasseProvider(widget.sessionId)),
        ),
      );
    }
    final SharedContentState? courant = partage.value;
    if (courant == null) {
      // Le suiveur seul arrive ici : pour le pilote, sans support la video
      // reprend la place et cette surface n'est pas montee.
      return Center(
        child: EmptyState(
          message: t.tc.classe.support.aucun,
          invitation: t.tc.classe.support.aucunDetailEleve,
          registre: RegistreVide.subi,
        ),
      );
    }
    if (courant.resourceId != identifiantRessourceCoran) {
      return Center(
        child: EmptyState(
          message: t.tc.classe.support.nonPrisEnCharge,
          invitation: t.tc.classe.support.nonPrisEnChargeDetail,
          registre: RegistreVide.subi,
        ),
      );
    }

    final bool decroche =
        !widget.peutPiloter &&
        _pagePartagee != null &&
        etat.origine == OrigineNavigation.personnelle &&
        etat.page != _pagePartagee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Repere(vue: vue, page: etat.page),
        if (decroche) _BandeRetour(page: _pagePartagee!, onRevenir: _revenir),
        if (_message case final String mot) _Mot(mot),
        Expanded(
          child: switch (etat.mode) {
            ModeRenduCoran.mushaf => const VuePageMushaf(),
            ModeRenduCoran.versetAgrandi => const VueVersetAgrandi(),
            ModeRenduCoran.focus => const VueFocusClasse(),
          },
        ),
        _Rangee(
          vue: vue,
          etat: etat,
          peutPiloter: widget.peutPiloter,
          onPage: (int p) => unawaited(_publierPage(p)),
          onAllerA: () => unawaited(
            FeuilleNavigationCoran.ouvrir(
              context,
              onAller: (int p) => unawaited(_publierPage(p)),
            ),
          ),
          onMode: (ModeRenduCoran m) => unawaited(_publierMode(m)),
          onZoom: (double delta) =>
              ref.read(lectureCoranProvider.notifier).zoomer(delta),
        ),
      ],
    );
  }
}

/// La ligne de repere : sourate, page, juz. Visible, discrete, jamais sur le
/// texte.
class _Repere extends StatelessWidget {
  const _Repere({required this.vue, required this.page});

  final PageMushafVM? vue;
  final int page;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Sourate? sourate = vue == null || vue!.sections.isEmpty
        ? null
        : vue!.sections.first.sourate;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppGabarit.de(context).gouttiere,
        vertical: AppSpacing.xs,
      ),
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                sourate?.nomTranslittere ?? t.eleve.coran.titre,
                overflow: TextOverflow.ellipsis,
                style: textes.labelLarge ?? const TextStyle(),
              ),
            ),
            Ecart.hSm,
            Text(
              <String>[
                t.eleve.coran.page(
                  page: '$page',
                  total: '${vue?.nombrePages ?? pagesMushafMedine}',
                ),
                if (vue?.juzNumero != null)
                  t.eleve.coran.juz(juz: '${vue!.juzNumero}'),
              ].join(' . '),
              style: palette.inkMuted.applyTo(
                AppTypography.tabulaire(
                  textes.labelMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La bande « Revenir a la page du professeur », **seulement** quand l'eleve
/// s'en est eloigne. Elle propose, elle ne teleporte pas (Bible section 25).
class _BandeRetour extends StatelessWidget {
  const _BandeRetour({required this.page, required this.onRevenir});

  final int page;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppGabarit.de(context).gouttiere,
        vertical: AppSpacing.xs,
      ),
      child: AppCard(
        onPress: onRevenir,
        libelleSemantique: t.tc.classe.support.revenirProfesseur,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                t.tc.classe.support.revenirProfesseur,
                style: palette.inkAccent.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
            ),
            Text(
              t.tc.classe.support.revenirProfesseurDetail(page: page),
              style: palette.inkMuted.applyTo(
                AppTypography.tabulaire(textes.bodySmall ?? const TextStyle()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un mot de l'enseignant a lui-meme : la derniere publication a echoue.
class _Mot extends StatelessWidget {
  const _Mot(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppGabarit.de(context).gouttiere,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        texte,
        style: palette.inkMuted.applyTo(
          textes.labelMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// La rangee basse du support.
///
/// **Pilote** : precedent, aller a, suivant -- les gestes qu'on repete toutes
/// les minutes, au premier niveau (Bible section 26) -- et l'affichage.
/// **Suiveur** : l'affichage seul, et seulement quand il a quelque chose a
/// regler (le zoom, en mode verset ou focus). Sur telephone, l'affichage
/// s'ouvre en feuille ; sur grand ecran, ses reglages tiennent dans la rangee.
class _Rangee extends StatelessWidget {
  const _Rangee({
    required this.vue,
    required this.etat,
    required this.peutPiloter,
    required this.onPage,
    required this.onAllerA,
    required this.onMode,
    required this.onZoom,
  });

  final PageMushafVM? vue;
  final EtatLectureCoran etat;
  final bool peutPiloter;
  final void Function(int page) onPage;
  final VoidCallback onAllerA;
  final void Function(ModeRenduCoran mode) onMode;
  final void Function(double delta) onZoom;

  bool get _zoomable => etat.mode != ModeRenduCoran.mushaf;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final int? precedente = vue?.pagePrecedente;
    final int? suivante = vue?.pageSuivante;
    final Widget reglages = _Reglages(
      etat: etat,
      peutPiloter: peutPiloter,
      onMode: onMode,
      onZoom: onZoom,
    );
    final bool reglagesUtiles = peutPiloter || _zoomable;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: gabarit.gouttiere,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          if (peutPiloter) ...<Widget>[
            ActionPrincipale(
              libelle: t.eleve.coran.pagePrecedente,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: precedente == null ? null : () => onPage(precedente),
            ),
            ActionPrincipale(
              libelle: t.tc.coran.navigation.ouvrir,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: onAllerA,
            ),
            ActionPrincipale(
              libelle: t.eleve.coran.pageSuivante,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: suivante == null ? null : () => onPage(suivante),
            ),
          ],
          if (reglagesUtiles)
            if (gabarit.estLarge)
              reglages
            else
              ActionPrincipale(
                libelle: t.tc.classe.support.affichage,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => unawaited(
                  AppBottomSheet.ouvrir<void>(
                    context,
                    titre: t.tc.classe.support.affichage,
                    constructeur: (BuildContext _) => reglages,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Le mode (pilote) et le zoom (chacun).
class _Reglages extends StatelessWidget {
  const _Reglages({
    required this.etat,
    required this.peutPiloter,
    required this.onMode,
    required this.onZoom,
  });

  final EtatLectureCoran etat;
  final bool peutPiloter;
  final void Function(ModeRenduCoran mode) onMode;
  final void Function(double delta) onZoom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (peutPiloter)
          Semantics(
            label: t.tc.coran.modes.choisir,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final ModeRenduCoran candidat in ModeRenduCoran.values)
                  FilterPill(
                    libelle: switch (candidat) {
                      ModeRenduCoran.mushaf => t.tc.coran.modes.mushaf,
                      ModeRenduCoran.versetAgrandi => t.tc.coran.modes.verset,
                      ModeRenduCoran.focus => t.tc.coran.modes.focus,
                    },
                    retenue: candidat == etat.mode,
                    onPress: () => onMode(candidat),
                  ),
              ],
            ),
          ),
        if (etat.mode == ModeRenduCoran.mushaf)
          Text(
            t.tc.coran.zoom.renvoiLectureAgrandie,
            style: palette.inkFaint.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          )
        else ...<Widget>[
          ActionPrincipale(
            libelle: t.eleve.coran.reduire,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () => onZoom(-0.2),
          ),
          Text(
            t.tc.coran.zoom.valeur(pourcent: (etat.zoomLocal * 100).round()),
            style: palette.inkMuted.applyTo(
              AppTypography.tabulaire(textes.labelMedium ?? const TextStyle()),
            ),
          ),
          ActionPrincipale(
            libelle: t.eleve.coran.agrandir,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () => onZoom(0.2),
          ),
        ],
      ],
    );
  }
}
