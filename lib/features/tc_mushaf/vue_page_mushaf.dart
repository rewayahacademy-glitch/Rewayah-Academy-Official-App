import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/vue_lecteur.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_coran/etat_lecture_coran.dart';
import '../../core/tc_coran/metrique_texte_coran.dart';
import '../../core/tc_coran/moteur_mushaf.dart';
import '../../core/tc_coran/page_mushaf_vm.dart';
import '../../core/tc_coran/port_layout_mushaf.dart';
import '../../core/tc_coran/port_navigation_coran.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/rosace_verset.dart';
import 'page_madina_15.dart';
import 'textes_lecteur_coran.dart';

/// Le rendu « page du mushaf ».
///
/// **Ce que ce rendu corrige, precisement** : aujourd'hui le lecteur pose le
/// texte dans une `ListView` large comme l'ecran, donc les mots se
/// redistribuent a chaque appareil et a chaque rotation. La page 293 n'a pas la
/// meme tete sur un telephone et sur une tablette, et un eleve qui memorise
/// perd ses reperes spatiaux.
///
/// Ici, le texte est compose dans un **cadre de page** dont la largeur fixe la
/// mesure : la taille de caractere est derivee de la largeur du cadre, pas de
/// celle de l'ecran. La page est donc **homothetique a elle-meme** d'un
/// appareil a l'autre, et les coupures de ligne tombent aux memes mots.
///
/// **Ce que ce rendu ne fait pas, et le dit** : il ne reproduit pas les quinze
/// lignes de l'edition de Medine, parce que la donnee n'existe pas dans la base
/// (voir `LayoutLignesIndisponible`). Il l'ecrit a l'usager plutot que de
/// dessiner quinze lignes remplies au juge.
class VuePageMushaf extends ConsumerWidget {
  /// Cree le rendu page.
  const VuePageMushaf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int page = ref.watch(
      lectureCoranProvider.select((EtatLectureCoran e) => e.page),
    );
    final Gabarit gabarit = AppGabarit.de(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // [RESPONSIVE]
        final bool doublePage = PlancheMushafVM.tientEnDoublePage(
          largeurDisponible: contraintes.maxWidth - gabarit.gouttiere * 2,
          hauteurDisponible: contraintes.maxHeight,
          ecartEntrePages: AppSpacing.lg,
          gabaritLarge: gabarit.estLarge,
        );

        return _Feuilleteur(
          // Changer de forme d'ouverture change la numerotation des feuillets :
          // un controleur qui survivrait au changement afficherait la page 8
          // la ou l'on etait page 15.
          key: ValueKey<bool>(doublePage),
          doublePage: doublePage,
          pageCourante: page,
          gouttiere: gabarit.gouttiere,
        );
      },
    );
  }
}

/// Le feuilletage : un feuillet par ouverture, de la droite vers la gauche.
class _Feuilleteur extends ConsumerStatefulWidget {
  const _Feuilleteur({
    required this.doublePage,
    required this.pageCourante,
    required this.gouttiere,
    super.key,
  });

  final bool doublePage;
  final int pageCourante;
  final double gouttiere;

  @override
  ConsumerState<_Feuilleteur> createState() => _FeuilleteurEtat();
}

class _FeuilleteurEtat extends ConsumerState<_Feuilleteur> {
  late final PageController _controleur = PageController(
    initialPage: _feuilletDe(widget.pageCourante),
  );

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  int _feuilletDe(int page) => widget.doublePage ? (page - 1) ~/ 2 : page - 1;

  int _pageDe(int feuillet) =>
      widget.doublePage ? feuillet * 2 + 1 : feuillet + 1;

  int get _nombreFeuillets =>
      widget.doublePage ? (pagesMushafMedine / 2).ceil() : pagesMushafMedine;

  @override
  Widget build(BuildContext context) {
    // Une navigation venue d'ailleurs -- la feuille « Aller a », une reprise,
    // l'etat partage de la classe -- doit deplacer le feuilletage. Sans cela,
    // l'ecran afficherait la bonne page dans l'entete et une autre sous le
    // doigt.
    ref.listen<int>(
      lectureCoranProvider.select((EtatLectureCoran e) => e.page),
      (int? _, int page) {
        final int cible = _feuilletDe(page);
        if (!_controleur.hasClients || _controleur.page?.round() == cible) {
          return;
        }
        _controleur.jumpToPage(cible);
      },
    );

    return Directionality(
      // Le sens de lecture appartient au document, pas a l'application : on
      // tourne les pages d'un mushaf de la droite vers la gauche, meme quand
      // l'interface autour est en francais.
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _controleur,
        itemCount: _nombreFeuillets,
        onPageChanged: (int feuillet) => ref
            .read(lectureCoranProvider.notifier)
            .allerA(_pageDe(feuillet), origine: OrigineNavigation.personnelle),
        itemBuilder: (BuildContext context, int feuillet) => OuvertureMushaf(
          pageDeDroite: _pageDe(feuillet),
          doublePage: widget.doublePage,
          gouttiere: widget.gouttiere,
        ),
      ),
    );
  }
}

/// Une ouverture : une page seule, ou deux pages en vis-a-vis.
class OuvertureMushaf extends ConsumerWidget {
  /// Cree une ouverture.
  const OuvertureMushaf({
    required this.pageDeDroite,
    required this.doublePage,
    required this.gouttiere,
    super.key,
  });

  /// La page de droite, celle que l'on lit en premier.
  final int pageDeDroite;

  /// Vrai quand la place tient deux pages.
  final bool doublePage;

  /// La gouttiere laterale du gabarit courant.
  final double gouttiere;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? numeroGauche = doublePage
        ? GeometrieMushaf.pageDeGaucheDe(pageDeDroite)
        : null;

    final AsyncValue<PageMushafVM> droite = ref.watch(
      pageMushafProvider(pageDeDroite),
    );
    final AsyncValue<PageMushafVM>? gauche = numeroGauche == null
        ? null
        : ref.watch(pageMushafProvider(numeroGauche));

    // L'ouverture s'affiche d'un seul tenant : montrer une page puis l'autre
    // ferait changer la largeur des cadres sous les yeux du lecteur.
    final PageMushafVM? vueDroite = droite.hasValue ? droite.value : null;
    final PageMushafVM? vueGauche = gauche == null
        ? null
        : (gauche.hasValue ? gauche.value : null);
    final PlancheMushafVM? planche = _composer(
      droite: vueDroite,
      gauche: vueGauche,
      attendGauche: numeroGauche != null,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // MUSHAF-15L : la page de Medine n'est ni dans une carte ni dans une
        // zone defilante. Elle occupe toute la place entre l'en-tete et la
        // barre de navigation, avec une gouttiere fine, comme dans les
        // applications de mushaf : le corps du texte est calcule pour que les
        // quinze lignes remplissent la hauteur et la largeur.
        if (planche != null &&
            planche.pages.every((PageMushafVM p) => p.estMadina15) &&
            contraintes.hasBoundedHeight) {
          return _OuvertureMadina15(planche: planche, contraintes: contraintes);
        }
        final double utile = math.max(0, contraintes.maxWidth - gouttiere * 2);
        final bool deuxCadres = planche?.estDouble ?? numeroGauche != null;
        final double largeurCadre = deuxCadres
            ? math.max(0, (utile - AppSpacing.lg) / 2)
            : math.min(utile, AppPage.largeurLecture);

        return SingleChildScrollView(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: gouttiere,
            vertical: AppSpacing.sm,
          ),
          child: Semantics(
            label: planche != null && planche.estDouble
                ? t.tc.coran.mushaf.ouverture(
                    droite: planche.droite.numero,
                    gauche: planche.gauche!.numero,
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (planche == null)
                  SizedBox(
                    width: largeurCadre,
                    child: _CadreEnAttente(largeur: largeurCadre),
                  )
                else
                  for (final PageMushafVM page in planche.pages) ...<Widget>[
                    if (page != planche.droite)
                      const SizedBox(width: AppSpacing.lg),
                    SizedBox(
                      width: largeurCadre,
                      child: CadrePageMushaf(vue: page, largeur: largeurCadre),
                    ),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Compose l'ouverture, ou `null` tant qu'il manque une page.
  static PlancheMushafVM? _composer({
    required PageMushafVM? droite,
    required PageMushafVM? gauche,
    required bool attendGauche,
  }) {
    if (droite == null) {
      return null;
    }
    if (!attendGauche) {
      return PlancheMushafVM.simple(droite);
    }
    if (gauche == null) {
      return null;
    }
    return PlancheMushafVM.doublePage(droite: droite, gauche: gauche);
  }
}

/// Une ouverture du Mushaf de Medine : une page seule, ou deux pages en
/// vis-a-vis (grand ecran), chacune remplissant la hauteur disponible.
class _OuvertureMadina15 extends StatelessWidget {
  const _OuvertureMadina15({required this.planche, required this.contraintes});

  final PlancheMushafVM planche;
  final BoxConstraints contraintes;

  @override
  Widget build(BuildContext context) {
    // Une gouttiere fine : la page est la matiere de l'ecran.
    const double gouttiere = AppSpacing.xs;
    final int n = planche.pages.length;
    final double ecart = n > 1 ? AppSpacing.md : 0;
    final double largeurPage = math.max(
      0,
      (contraintes.maxWidth - 2 * gouttiere - ecart * (n - 1)) / n,
    );
    final double hauteur = math.max(0, contraintes.maxHeight - 2 * gouttiere);
    return Padding(
      padding: const EdgeInsets.all(gouttiere),
      child: Semantics(
        label: planche.estDouble
            ? t.tc.coran.mushaf.ouverture(
                droite: planche.droite.numero,
                gauche: planche.gauche!.numero,
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final PageMushafVM page in planche.pages) ...<Widget>[
              if (page != planche.droite) SizedBox(width: ecart),
              Semantics(
                label: page.cote == CoteDePage.droite
                    ? t.tc.coran.mushaf.coteDroite
                    : t.tc.coran.mushaf.coteGauche,
                child: PageMadina15(
                  vue: page,
                  largeur: largeurPage,
                  hauteur: hauteur,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un cadre de page, en attendant que la page arrive.
class _CadreEnAttente extends StatelessWidget {
  const _CadreEnAttente({required this.largeur});

  final double largeur;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: largeur / GeometrieMushaf.ratioCadreTexte,
        ),
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
  }
}

/// Le cadre d'une page : la feuille, et ce qu'elle porte.
///
/// La hauteur **minimale** du cadre respecte la proportion de l'edition. Elle
/// grandit quand le texte de la page demande plus de place a une taille
/// lisible : sans les donnees de ligne, rien ne garantit qu'une page tienne en
/// quinze lignes a l'ecran, et couper le texte pour tenir dans un cadre serait
/// exactement l'improvisation que la specification interdit.
class CadrePageMushaf extends StatelessWidget {
  /// Cree un cadre de page.
  const CadrePageMushaf({required this.vue, required this.largeur, super.key});

  /// La page a rendre.
  final PageMushafVM vue;

  /// La largeur du cadre, qui fixe la mesure du texte.
  final double largeur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Semantics(
      label: vue.cote == CoteDePage.droite
          ? t.tc.coran.mushaf.coteDroite
          : t.tc.coran.mushaf.coteGauche,
      child: AppCard(
        surface: palette.surfaceRaised,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: largeur / vue.ratioLargeurSurHauteur,
          ),
          // Ni `Expanded`, ni `mainAxisSize.max` : le cadre vit dans une zone
          // defilante, donc sa hauteur est non bornee. C'est le `minHeight`
          // ci-dessus qui donne au cadre la proportion de l'edition, et
          // `spaceBetween` qui colle le pied de page en bas quand la page
          // porte moins de texte que le cadre n'a de place.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ContenuDePage(vue: vue, largeur: largeur),
              const SizedBox(height: AppSpacing.md),
              _PiedDePage(vue: vue),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ce que la page porte, selon son etat.
class _ContenuDePage extends ConsumerWidget {
  const _ContenuDePage({required this.vue, required this.largeur});

  final PageMushafVM vue;
  final double largeur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MA-TUTOIEMENT-1 : l'enrobage peut fournir ses phrases (vouvoiement).
    final TextesLecteurCoran? enrobage = TextesLecteurCoran.de(context);
    return switch (vue.etat) {
      EtatLecteur.chargement => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      EtatLecteur.indisponible => EtatSansTexteLecteur(
        EmptyState(
          message: t.eleve.coran.indisponible,
          invitation:
              enrobage?.indisponibleDetail ?? t.eleve.coran.indisponibleDetail,
          icone: AppIcons.horsLigne,
          libelleAction: t.eleve.coran.reessayer,
          onAction: () => ref.invalidate(pageCorpusProvider(vue.numero)),
        ),
      ),
      EtatLecteur.corpusAbsent => EtatSansTexteLecteur(
        EmptyState(
          message: t.eleve.coran.absent,
          invitation: enrobage?.absentDetail ?? t.eleve.coran.absentDetail,
          icone: AppIcons.rienAAfficher,
        ),
      ),
      EtatLecteur.lecture => TexteDePage(vue: vue, largeur: largeur),
    };
  }
}

/// Le texte d'une page.
///
/// Deux chemins, et un seul est emprunte aujourd'hui :
///
/// - **lignes reelles** : quand une source de layout les fournit, chaque ligne
///   est posee telle que l'edition la compose. Ce chemin est ecrit, il n'a
///   aucune donnee a rendre ;
/// - **flux continu** : les versets exacts de la page, composes dans la largeur
///   du cadre. C'est le chemin courant, et [NoticeComposition] le dit.
class TexteDePage extends StatelessWidget {
  /// Cree le texte d'une page.
  const TexteDePage({required this.vue, required this.largeur, super.key});

  /// La page a rendre.
  final PageMushafVM vue;

  /// La largeur du cadre.
  final double largeur;

  @override
  Widget build(BuildContext context) {
    // MUSHAF-15L : une source de layout reelle (quinze lignes, cadres de
    // sourate, basmala, rosaces) se compose en page du Mushaf de Medine.
    if (vue.estMadina15) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) =>
            PageMadina15(
              vue: vue,
              largeur: contraintes.maxWidth.isFinite
                  ? contraintes.maxWidth
                  : largeur,
            ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    // La mesure vient du CADRE, pas de l'ecran : c'est toute la difference
    // avec le rendu actuel, et c'est ce qui rend la page reconnaissable.
    final MetriqueTexteCoran metrique = MetriqueTexteCoran.calculer(
      largeurDisponible: largeur,
      zoom: 1,
    );
    final TextStyle base = palette.inkStrong.applyTo(
      AppTypography.document(
        taille: metrique.tailleTexte,
        interligne: metrique.interligne,
      ),
    );

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (vue.lignes.isNotEmpty)
            for (final SectionLigne ligne in vue.lignes)
              LigneComposee(ligne: ligne, style: base, echelle: metrique)
          else
            for (final SectionSourate section in vue.sections) ...<Widget>[
              if (section.commenceLaSourate) EnteteSourate(section: section),
              ParagrapheVersets(
                versets: section.versets,
                style: base,
                echelleRosace: metrique.echelleRosace,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

/// Une ligne de l'edition, posee telle qu'elle est composee.
///
/// **Chemin non emprunte aujourd'hui** : aucune source de layout ne livre de
/// [SectionLigne]. Il est ecrit parce que c'est lui qui rend
/// `PortLayoutMushaf` utile : le jour ou les lignes arrivent, seul le port
/// change.
class LigneComposee extends StatelessWidget {
  /// Cree une ligne composee.
  const LigneComposee({
    required this.ligne,
    required this.style,
    required this.echelle,
    super.key,
  });

  /// La ligne a rendre.
  final SectionLigne ligne;

  /// Le style du texte du document.
  final TextStyle style;

  /// Les metriques courantes, pour la rosace.
  final MetriqueTexteCoran echelle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          for (final SegmentVersetLigne segment
              in ligne.segments) ...<InlineSpan>[
            TextSpan(text: segment.texte),
            if (segment.termineLAyah) ...<InlineSpan>[
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ExcludeSemantics(
                  child: RosaceVerset(
                    numero: segment.ayah,
                    echelle: echelle.echelleRosace,
                  ),
                ),
              ),
              const TextSpan(text: ' '),
            ],
          ],
        ],
      ),
      textAlign: ligne.centree ? TextAlign.center : TextAlign.justify,
      style: style,
    );
  }
}

/// Les versets d'une sourate presents sur la page, en un seul flux.
///
/// **Un flux continu, et non une liste de cartes** : c'est la forme d'un
/// mushaf. Les numeros de verset passent par la rosace **dessinee** de
/// `RosaceVerset`, qui resout deja le piege U+06DD.
class ParagrapheVersets extends StatelessWidget {
  /// Cree un paragraphe de versets.
  const ParagrapheVersets({
    required this.versets,
    required this.style,
    required this.echelleRosace,
    super.key,
  });

  /// Les versets a poser.
  final List<VersetCoran> versets;

  /// Le style du texte du document.
  final TextStyle style;

  /// Le grossissement de la rosace.
  final double echelleRosace;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          for (final VersetCoran verset in versets) ...<InlineSpan>[
            TextSpan(text: '${verset.texte} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              // La numerotation est un repere de mise en page, pas du texte
              // revele : un lecteur d'ecran doit lire le verset, pas epeler
              // son numero au milieu de la phrase.
              child: ExcludeSemantics(
                child: RosaceVerset(
                  numero: verset.numero,
                  echelle: echelleRosace,
                ),
              ),
            ),
            const TextSpan(text: ' '),
          ],
        ],
      ),
      textAlign: TextAlign.justify,
      style: style,
    );
  }
}

/// Le titre d'une sourate qui commence sur cette page.
class EnteteSourate extends StatelessWidget {
  /// Cree un en-tete de sourate.
  const EnteteSourate({required this.section, super.key});

  /// La section concernee.
  final SectionSourate section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Sourate? sourate = section.sourate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: <Widget>[
          Text(
            sourate?.nomArabe ?? '',
            textAlign: TextAlign.center,
            style: palette.inkStrong.applyTo(
              AppTypography.document(taille: 24, interligne: 1.6),
            ),
          ),
          if (sourate != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${sourate.nomTranslittere} - '
              '${sourate.mecquoise ? t.eleve.coran.mecquoise : t.eleve.coran.medinoise}',
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le pied de page : numero, juz, cote, et l'etat de la composition.
class _PiedDePage extends StatelessWidget {
  const _PiedDePage({required this.vue});

  final PageMushafVM vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NoticeComposition(fidelite: vue.fidelite),
        const SizedBox(height: AppSpacing.sm),
        Text(
          <String>[
            t.eleve.coran.page(
              page: '${vue.numero}',
              total: '${vue.nombrePages}',
            ),
            if (vue.juzNumero != null)
              t.eleve.coran.juz(juz: '${vue.juzNumero}'),
            vue.cote == CoteDePage.droite
                ? t.tc.coran.mushaf.coteDroite
                : t.tc.coran.mushaf.coteGauche,
          ].join(' . '),
          textAlign: TextAlign.center,
          style: palette.inkFaint.applyTo(
            AppTypography.tabulaire(textes.labelSmall ?? const TextStyle()),
          ),
        ),
      ],
    );
  }
}

/// Ce que la composition de la page vaut reellement.
///
/// **Elle n'est pas masquable et ne vit pas dans un reglage.** Une page
/// approximee qui ne le dirait pas tromperait exactement les lecteurs qui ont
/// le plus besoin de la verite : ceux qui memorisent par la position des mots.
class NoticeComposition extends StatelessWidget {
  /// Cree la notice.
  const NoticeComposition({required this.fidelite, super.key});

  /// L'etat de la composition.
  final DisponibiliteLayout fidelite;

  @override
  Widget build(BuildContext context) => Directionality(
    // MUSHAF-DIR-1 : une phrase francaise, au sens de la langue de
    // l'interface (le point final reste a la fin), meme posee dans une page
    // feuilletee de droite a gauche.
    textDirection: sensInterface(context),
    child: _notice(context),
  );

  Widget _notice(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    if (fidelite == DisponibiliteLayout.fidele) {
      return Text(
        t.tc.coran.fidelite.fidele,
        textAlign: TextAlign.center,
        style: palette.inkFaint.applyTo(textes.labelSmall ?? const TextStyle()),
      );
    }

    final AppColorPair fond = palette.washWarning;
    return DecoratedBox(
      // Une notice posee DANS une carte prend le cran de rayon inferieur.
      decoration: fond.decoration(
        borderRadius: AppRadius.arrondiEnfantDe(AppRadius.md),
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t.tc.coran.fidelite.approchee,
              textAlign: TextAlign.center,
              style: fond.applyTo(textes.labelMedium ?? const TextStyle()),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.tc.coran.fidelite.approcheeDetail,
              textAlign: TextAlign.center,
              style: fond.applyTo(textes.labelSmall ?? const TextStyle()),
            ),
          ],
        ),
      ),
    );
  }
}
