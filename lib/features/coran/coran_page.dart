import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/vue_lecteur.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rosace_verset.dart';

/// `ELV-04` : le lecteur de Coran.
///
/// **Le premier ecran du produit dont le contenu n'est pas de l'interface.**
/// Il porte quatre contraintes qui ne se negocient pas :
///
/// 1. **J6** : la couche d'affichage ne depend d'aucun identifiant de fichier.
///    Rien ici ne connait de PDF, de page-image ni de chemin ; l'ecran lit des
///    versets et les compose lui-meme. C'est ce qui permettra de changer de
///    rendu -- glyphes d'une edition, mot a mot -- sans rien reecrire de cet
///    ecran.
/// 2. **Bible section 22, `CONTENT > CHROME`** : le Coran ne se traite jamais
///    comme une carte entouree de controles. D'ou [PageImmersive], le registre
///    `lecture`, et l'inversion assumee du motif « carte sur fond » pris a tous
///    les ecrans des lots R.
/// 3. **Section 4.3** : la reprise de lecture est **en evidence**, jamais
///    cachee dans un reglage.
/// 4. **La licence du corpus** : la source se dit dans l'application, pas
///    seulement dans un commentaire de migration. Elle est au pied de chaque
///    page, dans le flux, ou elle se voit sans encombrer.
///
/// **Ce que cet ecran n'ecrit pas, et c'est delibere** : il n'enregistre la
/// position de lecture qu'apres un geste de navigation de l'eleve. Ouvrir le
/// Coran ne doit pas ecraser le marque-page par la page d'ouverture -- ce
/// serait exactement le defaut que l'invariant **J2** interdit a l'enseignant,
/// commis par l'ecran lui-meme.
class CoranPage extends ConsumerStatefulWidget {
  /// Cree le lecteur.
  const CoranPage({super.key});

  @override
  ConsumerState<CoranPage> createState() => _CoranPageState();
}

class _CoranPageState extends ConsumerState<CoranPage> {
  /// Le delai avant d'ecrire la position, une fois la page posee.
  ///
  /// Assez long pour qu'un feuilletage rapide n'ecrive pas quinze fois, assez
  /// court pour qu'une lecture interrompue garde sa place.
  static const Duration _delaiEnregistrement = Duration(seconds: 3);

  late final PageController _controleur = PageController();

  int _page = 1;
  bool _reglagesOuverts = false;
  bool _aNavigue = false;
  PositionLecture? _position;
  double _zoom = 1;
  Timer? _enregistrement;

  @override
  void initState() {
    super.initState();
    unawaited(_lirePosition());
  }

  @override
  void dispose() {
    // Une minuterie annulable, et annulee : le piege ferme par N4 vaut ici
    // aussi, et un `Future.delayed` qui ecrirait apres la sortie de l'ecran
    // enregistrerait une page que l'eleve ne lit plus.
    _enregistrement?.cancel();
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _lirePosition() async {
    final String? profil = ref.read(sessionProvider).profileId;
    if (profil == null) {
      return;
    }
    final PositionLecture? position = await ref
        .read(serviceCoranProvider)
        .position(profil);
    if (!mounted || position == null) {
      return;
    }
    setState(() {
      _position = position;
      _zoom = position.zoom;
    });
  }

  void _allerA(int page) {
    _aNavigue = true;
    _controleur.jumpToPage(page - 1);
    setState(() => _page = page);
    _planifierEnregistrement();
  }

  void _planifierEnregistrement() {
    _enregistrement?.cancel();
    _enregistrement = Timer(_delaiEnregistrement, () {
      unawaited(_enregistrer());
    });
  }

  Future<void> _enregistrer() async {
    // Sans geste de l'eleve, rien ne s'ecrit : voir l'en-tete de la classe.
    if (!_aNavigue) {
      return;
    }
    final String? profil = ref.read(sessionProvider).profileId;
    if (profil == null) {
      return;
    }
    final PageCoran? page = await ref.read(pageCoranProvider(_page).future);
    if (!mounted) {
      return;
    }
    final VersetCoran? premier = page == null || page.versets.isEmpty
        ? null
        : page.versets.first;
    final PositionLecture position = PositionLecture(
      page: _page,
      sourate: premier?.sourateNumero ?? _position?.sourate ?? 1,
      verset: premier?.numero ?? 1,
      zoom: _zoom,
    );
    await ref.read(serviceCoranProvider).enregistrerPosition(profil, position);
    if (mounted) {
      setState(() => _position = position);
    }
  }

  void _changerZoom(double delta) {
    setState(() => _zoom = (_zoom + delta).clamp(0.8, 2.4));
    _aNavigue = true;
    _planifierEnregistrement();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Sourate>?> sourates = ref.watch(souratesProvider);
    final AsyncValue<PageCoran?> page = ref.watch(pageCoranProvider(_page));

    final VueLecteur vue = VueLecteur.depuis(
      pageDemandee: _page,
      page: page.value,
      chargementEnCours: page.isLoading,
      sourates: sourates.value,
      position: _position,
    );

    return PageImmersive(
      registre: RegistreImmersif.lecture,
      entete: _Entete(
        vue: vue,
        reglagesOuverts: _reglagesOuverts,
        onReglages: () =>
            setState(() => _reglagesOuverts = !_reglagesOuverts),
      ),
      commandes: _Commandes(
        vue: vue,
        zoom: _zoom,
        reglagesOuverts: _reglagesOuverts,
        onPage: _allerA,
        onZoom: _changerZoom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (vue.repriseProposee && vue.position != null)
            _BandeReprise(
              position: vue.position!,
              onReprendre: () => _allerA(vue.position!.page),
            ),
          Expanded(
            // Le sens de lecture appartient au document, pas a l'application :
            // on tourne les pages d'un mushaf de la droite vers la gauche,
            // meme quand l'interface autour est en francais.
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _controleur,
                itemCount: pagesMushafMedine,
                onPageChanged: (int index) {
                  _aNavigue = true;
                  setState(() => _page = index + 1);
                  _planifierEnregistrement();
                },
                itemBuilder: (BuildContext _, int index) =>
                    _PageTexte(numero: index + 1, zoom: _zoom),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La ligne de contexte : ou l'on est dans le mushaf.
///
/// Elle reste visible en permanence, et ce n'est pas une entorse au mode
/// immersif : ce sont les **controles** que la section 5.3 demande de masquer,
/// pas le reperage. Un lecteur qui ne sait plus quelle sourate il lit a perdu
/// davantage qu'un peu de place a l'ecran.
class _Entete extends StatelessWidget {
  const _Entete({
    required this.vue,
    required this.reglagesOuverts,
    required this.onReglages,
  });

  final VueLecteur vue;
  final bool reglagesOuverts;
  final VoidCallback onReglages;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Sourate? sourate = vue.sections.isEmpty
        ? null
        : vue.sections.first.sourate;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    page: '${vue.pageAffichee}',
                    total: '${vue.nombrePages}',
                  ),
                  if (vue.juzNumero != null)
                    t.eleve.coran.juz(juz: '${vue.juzNumero}'),
                ].join(' · '),
                style: palette.inkMuted.applyTo(
                  AppTypography.tabulaire(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Pressable(
          onPress: onReglages,
          libelleSemantique: reglagesOuverts
              ? t.eleve.coran.fermerReglages
              : t.eleve.coran.reglages,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              AppIcons.reglages.resoudre(selectionne: reglagesOuverts),
              size: AppSpacing.xl,
            ),
          ),
        ),
      ],
    );
  }
}

/// L'acces « Reprendre », en evidence et jamais dans un reglage (section 4.3).
///
/// **Il propose, il ne teleporte pas.** Ouvrir le Coran directement a la page
/// enregistree serait plus rapide d'un geste, et ferait perdre a l'eleve le
/// seul endroit ou il choisit lui-meme : la Bible section 28 demande un acces
/// visible, pas un saut automatique.
class _BandeReprise extends StatelessWidget {
  const _BandeReprise({required this.position, required this.onReprendre});

  final PositionLecture position;
  final VoidCallback onReprendre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: AppCard(
        onPress: onReprendre,
        libelleSemantique: t.eleve.coran.reprendre,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.eleve.coran.reprendre,
                    style: palette.inkAccent.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                  Text(
                    t.eleve.coran.reprendreDetail(page: '${position.page}'),
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevron.repos, size: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Une page du mushaf, telle qu'elle se lit.
class _PageTexte extends ConsumerWidget {
  const _PageTexte({required this.numero, required this.zoom});

  final int numero;
  final double zoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Sourate>?> sourates = ref.watch(souratesProvider);
    final AsyncValue<PageCoran?> page = ref.watch(pageCoranProvider(numero));

    final VueLecteur vue = VueLecteur.depuis(
      pageDemandee: numero,
      page: page.value,
      chargementEnCours: page.isLoading,
      sourates: sourates.value,
      position: null,
    );

    return switch (vue.etat) {
      EtatLecteur.chargement => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      EtatLecteur.indisponible => Center(
        child: EmptyState(
          message: t.eleve.coran.indisponible,
          invitation: t.eleve.coran.indisponibleDetail,
          icone: AppIcons.horsLigne,
          libelleAction: t.eleve.coran.reessayer,
          onAction: () => ref.invalidate(pageCoranProvider(numero)),
        ),
      ),
      EtatLecteur.corpusAbsent => Center(
        child: EmptyState(
          message: t.eleve.coran.absent,
          invitation: t.eleve.coran.absentDetail,
          icone: AppIcons.rienAAfficher,
        ),
      ),
      EtatLecteur.lecture => _Texte(vue: vue, zoom: zoom),
    };
  }
}

/// Le texte lui-meme, decoupe par sourate.
class _Texte extends StatelessWidget {
  const _Texte({required this.vue, required this.zoom});

  final VueLecteur vue;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: <Widget>[
          for (final SectionSourate section in vue.sections) ...<Widget>[
            if (section.commenceLaSourate) _EnteteSourate(section: section),
            _Paragraphe(section: section, zoom: zoom),
            const SizedBox(height: AppSpacing.lg),
          ],
          _Attribution(page: vue.pageAffichee),
        ],
      ),
    );
  }
}

/// Le titre d'une sourate qui commence sur cette page.
class _EnteteSourate extends StatelessWidget {
  const _EnteteSourate({required this.section});

  final SectionSourate section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Sourate? sourate = section.sourate;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: AppCard(
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
                '${sourate.nomTranslittere} · '
                '${sourate.mecquoise ? t.eleve.coran.mecquoise : t.eleve.coran.medinoise}',
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Les versets d'une sourate presents sur la page, en un seul flux.
///
/// **Un flux continu, et non une liste de cartes** : c'est la forme d'un
/// mushaf, et c'est ce que la Bible section 22 demande en interdisant de
/// traiter le Coran comme un composant d'interface. Les numeros de verset sont
/// poses dans une rosace **dessinee**, pas tiree d'un glyphe de la police :
/// U+06DD existe pour cela mais toutes les polices ne le portent pas, et un
/// carre vide au milieu du texte coranique serait pire que tout.
class _Paragraphe extends StatelessWidget {
  const _Paragraphe({required this.section, required this.zoom});

  final SectionSourate section;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base = palette.inkStrong.applyTo(
      AppTypography.document(taille: 26 * zoom, interligne: 2.1),
    );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          for (final VersetCoran verset in section.versets) ...<InlineSpan>[
            TextSpan(text: '${verset.texte} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              // La numerotation est un repere de mise en page, pas du texte
              // revele : un lecteur d'ecran doit lire le verset, pas epeler
              // son numero au milieu de la phrase.
              child: ExcludeSemantics(
                child: RosaceVerset(numero: verset.numero, echelle: zoom),
              ),
            ),
            const TextSpan(text: ' '),
          ],
        ],
      ),
      textAlign: TextAlign.justify,
      style: base,
    );
  }
}


/// La provenance du texte, au pied de chaque page.
///
/// **Elle n'est pas negociable et elle n'est pas dans un reglage** : la licence
/// du corpus demande que la source soit clairement indiquee et que tanzil.net
/// soit joignable. Un credit relegue dans un ecran « a propos » ne serait lu
/// par personne, et l'exigence porte sur l'endroit ou le texte s'affiche.
class _Attribution extends StatelessWidget {
  const _Attribution({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          Text(
            t.eleve.coran.edition,
            textAlign: TextAlign.center,
            style: palette.inkFaint.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${t.eleve.coran.source} · ${t.eleve.coran.sourceLien}',
            textAlign: TextAlign.center,
            style: palette.inkFaint.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les commandes du lecteur.
///
/// La navigation de page est **primaire** et reste donc visible : c'est le
/// geste du lecteur, et le masquer laisserait le clavier et les technologies
/// d'assistance sans aucun moyen de tourner la page. Ce que la section 5.3
/// demande de masquer, ce sont les controles **secondaires** : ils sont dans
/// le tiroir ci-dessous, ferme par defaut.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.vue,
    required this.zoom,
    required this.reglagesOuverts,
    required this.onPage,
    required this.onZoom,
  });

  final VueLecteur vue;
  final double zoom;
  final bool reglagesOuverts;
  final void Function(int page) onPage;
  final void Function(double delta) onZoom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (reglagesOuverts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  t.eleve.coran.taille,
                  style: palette.inkMuted.applyTo(
                    textes.labelMedium ?? const TextStyle(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Deux libelles plutot que deux icones : le catalogue n'a ni
                // « plus » ni « moins », et inventer un point de code Phosphor
                // au juge poserait un carre vide sur l'ecran de lecture. Un
                // verbe se lit, se traduit et s'annonce, ce qu'une icone
                // devinee ne fait dans aucun des trois cas.
                ActionPrincipale(
                  libelle: t.eleve.coran.reduire,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => onZoom(-0.2),
                ),
                Text(
                  '${(zoom * 100).round()}%',
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
        Row(
          children: <Widget>[
            Expanded(
              child: ActionPrincipale(
                libelle: t.eleve.coran.pagePrecedente,
                niveau: NiveauAction.secondaire,
                onPress: vue.pagePrecedente == null
                    ? null
                    : () => onPage(vue.pagePrecedente!),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ActionPrincipale(
                libelle: t.eleve.coran.pageSuivante,
                niveau: NiveauAction.secondaire,
                onPress: vue.pageSuivante == null
                    ? null
                    : () => onPage(vue.pageSuivante!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
