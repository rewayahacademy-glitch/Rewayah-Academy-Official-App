import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/navigation_coran.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/theme/app_contour.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/selecteur_section.dart';
// L'attribution Tanzil compacte (deux lignes au plus, jamais sous la taille
// de base) est celle du lecteur accessible : on la reprend, on ne la refait
// pas (CORAN-320-1).
import '../accueil_eleve/coran_accessibilite.dart'
    show AttributionCoranCompacte;
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

  /// La cle de l'en-tete (tests de geometrie, captures).
  static const Key enteteKey = ValueKey<String>('mushaf-entete');

  /// La cle des commandes du bas (tests de geometrie, captures).
  static const Key commandesKey = ValueKey<String>('mushaf-commandes');

  /// La cle de l'attribution Tanzil (tests de geometrie, captures).
  static const Key attributionKey = ValueKey<String>('mushaf-attribution');

  /// La cle du bouton qui deplie le choix du rendu, a texte agrandi.
  static const Key optionsKey = ValueKey<String>('mushaf-options');

  /// Vrai quand le texte est agrandi jusqu'au seuil des rangees compactes
  /// (CORAN-320-1) : en-tete, mentions et pagination se resserrent alors pour
  /// laisser la hauteur aux versets.
  ///
  /// CORAN-320-1b : le seuil est atteint **a 130 % exactement** (`>=`, et non
  /// plus `>`). A 130 %, le chrome n'est pas plafonne (il l'est a 130 %
  /// justement) : l'ancien saut laissait 9 % de la hauteur aux versets en page
  /// du mushaf et 0 % en lecture agrandie, contre 54 % un centieme plus haut.
  static bool texteAgrandi(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) >= AppContour.seuilTexteAgrandi;

  /// Plafonne l'echelle du texte de [enfant] au seuil du texte agrandi.
  ///
  /// CORAN-320-1 (decision deleguee du 05/10, choix a) : a texte x2, l'en-tete,
  /// les mentions et la pagination prenaient toute la page de 320 x 568. Ils
  /// restent agrandis (jusqu'a 130 %), dans l'ordre de la hierarchie HIER-1
  /// puisque tous leurs styles passent par le meme plafond ; **le texte des
  /// versets n'est jamais sous ce plafond** : il garde l'echelle de l'usager.
  static Widget plafonner(Widget enfant) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: AppContour.seuilTexteAgrandi,
    child: enfant,
  );

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
    final bool compact = MushafPage.texteAgrandi(context);
    final Widget commandes = _Commandes(
      key: MushafPage.commandesKey,
      compact: compact,
      vue: vue,
      mode: etat.mode,
      zoom: etat.zoomLocal,
      onPage: (int p) => _allerA(p, origine: OrigineNavigation.personnelle),
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
    );

    return PageImmersive(
      registre: RegistreImmersif.lecture,
      // CORAN-320-1 : a texte agrandi, l'en-tete passe dans le contenu, sous
      // une marge serree, au lieu de la marge de l'emplacement d'en-tete.
      entete: compact
          ? null
          : _Entete(key: MushafPage.enteteKey, vue: vue, mode: etat.mode),
      commandes: compact ? null : commandes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (compact)
            _EnteteCompact(
              key: MushafPage.enteteKey,
              vue: vue,
              mode: etat.mode,
              reglageTaille: _ReglageTaille(
                zoom: etat.zoomLocal,
                onZoom: (double delta) {
                  ref.read(lectureCoranProvider.notifier).zoomer(delta);
                  _planifierEnregistrement();
                },
              ),
            ),
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
          if (vue != null && vue.aDuTexte)
            _Attribution(key: MushafPage.attributionKey, compact: compact),
          // CORAN-320-1 : a texte agrandi, les commandes passent dans le
          // contenu, sous une marge serree, au lieu de la marge de
          // l'emplacement des commandes.
          if (compact)
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppGabarit.de(context).gouttiere,
                vertical: AppSpacing.xs,
              ),
              child: commandes,
            ),
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
  const _Entete({required this.vue, required this.mode, super.key});

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
            if (vue?.juzNumero != null)
              t.eleve.coran.juz(juz: '${vue!.juzNumero}'),
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

/// L'en-tete a texte agrandi (CORAN-320-1) : une ligne.
///
/// Le nom de la sourate, et un bouton qui deplie le choix du rendu (et, en
/// page du mushaf, la mention qui renvoie a la lecture agrandie ; en lecture
/// agrandie et en focus, le reglage de taille). La page n'est pas redite ici :
/// elle est au centre de la pagination. Le juz est au pied de chaque page du
/// mushaf ; en lecture agrandie et en focus, qui n'ont pas ce pied, il suit le
/// nom de la sourate (CORAN-320-1b). Taille plafonnee
/// ([MushafPage.plafonner]).
class _EnteteCompact extends StatefulWidget {
  const _EnteteCompact({
    required this.vue,
    required this.mode,
    required this.reglageTaille,
    super.key,
  });

  final PageMushafVM? vue;
  final ModeRenduCoran mode;

  /// Le reglage de taille du texte (lecture agrandie et focus), deplie avec
  /// le choix du rendu (CORAN-320-1b).
  final Widget reglageTaille;

  @override
  State<_EnteteCompact> createState() => _EnteteCompactEtat();
}

class _EnteteCompactEtat extends State<_EnteteCompact> {
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Gabarit gabarit = AppGabarit.de(context);
    final PageMushafVM? vue = widget.vue;
    final Sourate? sourate = vue == null || vue.sections.isEmpty
        ? null
        : vue.sections.first.sourate;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: gabarit.gouttiere,
        vertical: AppSpacing.xs,
      ),
      child: MushafPage.plafonner(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: sourate?.nomTranslittere ?? t.eleve.coran.titre,
                      children: <InlineSpan>[
                        // CORAN-320-1b : le juz, que ces deux rendus n'ont
                        // nulle part ailleurs, dans le style de la ligne de
                        // contexte de l'en-tete large.
                        if (widget.mode != ModeRenduCoran.mushaf &&
                            vue?.juzNumero != null)
                          TextSpan(
                            text:
                                ' . '
                                '${t.eleve.coran.juz(juz: '${vue!.juzNumero}')}',
                            style: palette.inkMuted.applyTo(
                              AppTypography.tabulaire(
                                textes.bodySmall ?? const TextStyle(),
                              ),
                            ),
                          ),
                      ],
                    ),
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Un bouton qui replie, pas un bouton grise : il est toujours
                // actif, et son etat (deplie ou non) est annonce.
                Semantics(
                  expanded: _deplie,
                  child: BoutonIcone(
                    key: MushafPage.optionsKey,
                    icone: AppIcons.reglages,
                    libelle: t.tc.coran.modes.choisir,
                    onPress: () => setState(() => _deplie = !_deplie),
                  ),
                ),
              ],
            ),
            if (_deplie) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              _ChoixMode(mode: widget.mode),
              const SizedBox(height: AppSpacing.xs),
              if (widget.mode == ModeRenduCoran.mushaf)
                Text(
                  t.tc.coran.zoom.renvoiLectureAgrandie,
                  textAlign: TextAlign.center,
                  style: palette.inkFaint.applyTo(
                    textes.labelSmall ?? const TextStyle(),
                  ),
                )
              else
                // CORAN-320-1b (decide par delegation le 09/10) : le reglage
                // de taille quitte la pagination, ou il prenait deux rangees
                // a 320 points, et rejoint le reglage du rendu.
                widget.reglageTaille,
            ],
          ],
        ),
      ),
    );
  }
}

/// Le choix du rendu.
class _ChoixMode extends ConsumerWidget {
  const _ChoixMode({required this.mode});

  final ModeRenduCoran mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trois rendus exclusifs : un controle segmente (ou un menu quand les
    // libelles ne tiennent pas), jamais une rangee qui defile (ONGLETS-1).
    return SelecteurSection<ModeRenduCoran>(
      libelle: t.tc.coran.modes.choisir,
      valeur: mode,
      sections: <Segment<ModeRenduCoran>>[
        for (final ModeRenduCoran candidat in ModeRenduCoran.values)
          Segment<ModeRenduCoran>(
            valeur: candidat,
            libelle: _libelle(candidat),
          ),
      ],
      onChange: (ModeRenduCoran candidat) =>
          ref.read(lectureCoranProvider.notifier).changerMode(candidat),
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
  const _Attribution({required this.compact, super.key});

  /// Vrai a texte agrandi (CORAN-320-1) : l'attribution reste entiere, mais
  /// tient sur deux lignes au plus, sans jamais passer sous la taille de base
  /// ([AttributionCoranCompacte]), sans marge verticale propre.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    if (compact) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppGabarit.de(context).gouttiere,
        ),
        child: AttributionCoranCompacte(
          texte:
              '${t.eleve.coran.edition} . ${t.eleve.coran.source} . '
              '${t.eleve.coran.sourceLien}',
          style: palette.inkFaint.applyTo(
            textes.labelSmall ?? const TextStyle(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        '${t.eleve.coran.edition} . ${t.eleve.coran.source} . '
        '${t.eleve.coran.sourceLien}',
        textAlign: TextAlign.center,
        style: palette.inkFaint.applyTo(textes.labelSmall ?? const TextStyle()),
      ),
    );
  }
}

/// Les commandes du lecteur.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.compact,
    required this.vue,
    required this.mode,
    required this.zoom,
    required this.onPage,
    required this.onZoom,
    required this.onNavigation,
    super.key,
  });

  /// Vrai a texte agrandi (CORAN-320-1) : une seule rangee, taille plafonnee.
  final bool compact;

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
    final Widget reglageTaille = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _ReglageTaille(zoom: zoom, onZoom: onZoom),
    );
    // NAV-FLECHES-1 : fleche, position, fleche ; aux bornes la fleche
    // disparait. Le choix d'une page ou d'une sourate reste dessous, un lien
    // discret (a cote, en icone, a texte agrandi).
    final Widget barre = BarrePrecedentSuivant(
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
    );

    if (compact) {
      // CORAN-320-1 : une seule rangee, la pagination et l'acces a « Aller a
      // une page » en icone (nom lu et en infobulle). La mention du mushaf
      // est repliee dans l'en-tete ; CORAN-320-1b : le reglage de taille de
      // la lecture agrandie et du focus aussi, dans tous les rendus la
      // pagination tient sur une rangee. Taille plafonnee
      // ([MushafPage.plafonner]).
      return MushafPage.plafonner(
        Row(
          children: <Widget>[
            Expanded(child: barre),
            const SizedBox(width: AppSpacing.sm),
            BoutonIcone(
              icone: AppIcons.menu,
              libelle: t.tc.coran.navigation.ouvrir,
              onPress: onNavigation,
            ),
          ],
        ),
      );
    }

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
          reglageTaille,
        barre,
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

/// Le reglage de taille du texte : Reduire, la valeur, Agrandir.
///
/// Un seul composant pour ses deux places (CORAN-320-1b) : sous les versets a
/// texte de base, dans le panneau « Mode de lecture » a texte agrandi.
class _ReglageTaille extends StatelessWidget {
  const _ReglageTaille({required this.zoom, required this.onZoom});

  final double zoom;
  final void Function(double delta) onZoom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // `Wrap` et non `Row` : les trois libelles de la commande de taille ne
    // tiennent pas sur une ligne de 320 points, et un `Row` y deborderait au
    // lieu de passer a la ligne.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        // Deux libelles plutot que deux icones : ils disent ce qui grossit
        // (le texte), la ou une loupe ne dit pas quoi.
        ActionPrincipale(
          libelle: t.eleve.coran.reduire,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: () => onZoom(-0.2),
        ),
        // Isolee : sans lettre, « 100 % » se lisait « % 100 » en arabe
        // (CORAN-320-1b).
        Text(
          isolerSens(t.tc.coran.zoom.valeur(pourcent: (zoom * 100).round())),
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
    );
  }
}
