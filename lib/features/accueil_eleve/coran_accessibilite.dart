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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/commandes_masquables.dart';
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
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../tc_mushaf/navigation_coran_feuille.dart';
import '../tc_mushaf/textes_lecteur_coran.dart';
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

/// L'etat de la lecture de la position de reprise (revue MA-7, MA-11).
enum EtatRepriseCoran {
  /// Lecture en cours : l'action principale attend (pas d'ouverture a la
  /// mauvaise page).
  recherche,

  /// Lecture terminee (position connue ou absente).
  connue,

  /// Lecture echouee : l'ecran le dit (K-59) et le Coran s'ouvre quand meme.
  echec,
}

class _CoranAccessibiliteEtat extends ConsumerState<CoranAccessibilite> {
  /// Au-dela, la reprise est tenue pour non retrouvee : l'action principale
  /// ne reste jamais bloquee (ce n'est pas une animation).
  static const Duration _delaiReprise = Duration(seconds: 5);

  PositionLecture? _reprise;
  EtatRepriseCoran _etatReprise = EtatRepriseCoran.recherche;
  bool _ouvert = false;

  @override
  void initState() {
    super.initState();
    unawaited(_lireReprise());
  }

  /// La reprise vient du port existant : aucune position inventee. Un echec
  /// n'est plus avale en silence (revue MA-7) : il est dit, avec ce qu'il
  /// reste a faire.
  Future<void> _lireReprise() async {
    final PositionLecture? position;
    try {
      position = await ref
          .read(portNavigationCoranProvider)
          .dernierePositionPersonnelle()
          .timeout(_delaiReprise);
    } on Object {
      if (mounted) setState(() => _etatReprise = EtatRepriseCoran.echec);
      return;
    }
    if (!mounted) return;
    setState(() {
      _reprise = position;
      _etatReprise = EtatRepriseCoran.connue;
    });
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
      // Comme `MushafPage` : le grossissement voyage avec la position, un
      // lecteur qui a grossi son texte le retrouve grossi (MA22, K-51).
      lecture.definirZoom(reprise.zoom);
    }
    if (widget.lectureGrande ??
        ref.read(preferencesLocalesProvider).lectureGrande) {
      lecture.changerMode(ModeRenduCoran.versetAgrandi);
    }
    setState(() => _ouvert = true);
  }

  /// Revient a l'entree.
  void _fermer() => setState(() => _ouvert = false);

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
        child: KeyedSubtree(
          key: const ValueKey<String>('coran-ma-lecteur'),
          child: widget.demonstration
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    EnteteLecteurCoranAccessibilite(
                      titre: t.eleve.coran.titre,
                      onRetour: _fermer,
                    ),
                    Expanded(child: _demonstrationSansTexte()),
                  ],
                )
              : LecteurCoranAccessibilite(
                  onRetour: _fermer,
                  tutoiement: widget.tutoiement,
                ),
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
    final bool recherche = _etatReprise == EtatRepriseCoran.recherche;

    // MA-DEC-1 (decision A8 = a du 27/09) : les libelles existants sont
    // reutilises, rien n'est ajoute. « Reprendre ta lecture » et « Tu en
    // etais page {page} » sont ceux du Coran standard (`MushafPage`) ;
    // « Lire le Coran » est le nom de la meme action a l'Accueil (MA9) ;
    // « Chargement » et « Retour » sont communs.
    return PageShell(
      key: const ValueKey<String>('coran-ma-entree'),
      titre: t.eleve.coran.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // L'etat de la reprise est annonce quand il change (region vive).
          if (reprise != null ||
              _etatReprise != EtatRepriseCoran.connue) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                switch (_etatReprise) {
                  EtatRepriseCoran.recherche => t.commun.chargement,
                  EtatRepriseCoran.echec =>
                    tu
                        ? t.accessibilite.coran.repriseErreur
                        : t.accessibilite.coran.repriseErreurVous,
                  EtatRepriseCoran.connue =>
                    tu
                        ? t.eleve.coran.reprendreDetail(
                            page: '${reprise?.page}',
                          )
                        : t.accessibilite.coran.reprendreDetailVous(
                            page: '${reprise?.page}',
                          ),
                },
                key: const ValueKey<String>('coran-ma-reprise'),
                style: palette.inkMuted.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Pas d'action avant l'arrivee de la reprise (revue MA-7), et jamais
          // de bouton grise (K-54) : pendant la lecture, seule la ligne
          // « Chargement » est montree, au plus le delai de reprise.
          if (!recherche)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: const ValueKey<String>('coran-ma-principale'),
                libelle: reprise == null
                    ? t.accessibilite.accueil.lireCoran
                    : tu
                    ? t.eleve.coran.reprendre
                    : t.accessibilite.coran.reprendreVous,
                pleineLargeur: false,
                onPress: _ouvrir,
              ),
            ),
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
/// MA-CMD-1 (directeur, 02/10/2026, capture a 200 % : « des fleches et sans
/// texte, compacte en bas, qui s'affiche a la touche de l'ecran pour laisser
/// le Coran et le support respirer ») : le Coran garde tout l'ecran. L'en-tete
/// tient sur une ligne (retour en icone, sourate et page en petit) ; les
/// commandes reprennent la disposition de `_Commandes` de `MushafPage`
/// (page precedente, navigation, page suivante, et la taille du texte en
/// verset agrandi), en icones seules posees par-dessus le bas du Mushaf dans
/// [CommandesMasquables] : masquees apres quelques secondes, rappelees d'une
/// touche ou au focus, toujours visibles avec lecteur d'ecran ou clavier.
/// Chaque icone garde son nom pour le lecteur d'ecran et une infobulle.
///
/// Repris de `MushafPage` sans rien y changer : l'enregistrement differe de
/// la position personnelle (seulement apres une navigation du lecteur) et
/// l'attribution Tanzil, toujours visible au pied de l'ecran (jamais masquee
/// avec les commandes : la licence demande qu'elle soit lisible).
class LecteurCoranAccessibilite extends ConsumerStatefulWidget {
  /// Cree le lecteur.
  const LecteurCoranAccessibilite({
    this.onRetour,
    this.tutoiement = false,
    super.key,
  });

  /// Le retour a l'entree ; nul : pas de bouton de retour.
  final VoidCallback? onRetour;

  /// Vrai pour l'eleve mineur (tutoiement) ; un adulte, ou un age inconnu,
  /// est vouvoye (MA-TUTOIEMENT-1, decision A4 = a). Les phrases des etats
  /// sans texte des vues de rendu suivent, par [TextesLecteurCoran].
  final bool tutoiement;

  /// La cle de l'en-tete (tests, captures).
  static const Key enteteKey = ValueKey<String>('coran-ma-entete');

  /// La cle de l'attribution (tests, captures).
  static const Key attributionKey = ValueKey<String>('coran-ma-attribution');

  /// La place reservee de la fleche « page precedente » a la premiere page
  /// (NAV-FLECHES-1 : la fleche disparait, sa place reste).
  static const Key placePrecedenteKey = ValueKey<String>(
    'coran-ma-place-precedente',
  );

  /// Idem pour « page suivante » a la derniere page.
  static const Key placeSuivanteKey = ValueKey<String>(
    'coran-ma-place-suivante',
  );

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
    final bool agrandi = etat.mode == ModeRenduCoran.versetAgrandi;
    // DUREE-INSECABLE-4 : « 150 % » insecable ; la valeur suit le nom de la
    // commande (« Agrandir, 150 % »), donc sans ancre de sens.
    final String taille = LibellesGroupe.insecable(
      t.tc.coran.zoom.valeur(pourcent: (etat.zoomLocal * 100).round()),
    );

    // La disposition de `_Commandes` (MushafPage), en icones seules : les
    // fleches aux deux bouts, la navigation au milieu, la taille du texte
    // entre les deux en verset agrandi. Ecarts serres : les cinq disques de
    // la cible du mode guide (72) tiennent sur une seule rangee a 390.
    // NAV-FLECHES-1 (K-54, K-56) : a la premiere ou a la derniere page, la
    // fleche DISPARAIT (jamais grisee) et sa place reste reservee, pour que
    // les autres commandes ne bougent pas.
    final double cible = AppMetriques.of(context).cibleTactile;
    final Widget commandes = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Center(
        child: Wrap(
          key: const ValueKey<String>('coran-ma-commandes'),
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            if (precedente == null)
              SizedBox.square(
                key: LecteurCoranAccessibilite.placePrecedenteKey,
                dimension: cible,
              )
            else
              BoutonIcone(
                key: const ValueKey<String>('coran-ma-page-precedente'),
                forme: FormeBoutonIcone.disque,
                icone: AppIcons.retour,
                libelle: t.eleve.coran.pagePrecedente,
                onPress: () => _allerA(precedente),
              ),
            BoutonIcone(
              key: const ValueKey<String>('coran-ma-navigation'),
              forme: FormeBoutonIcone.disque,
              icone: AppIcons.menu,
              libelle: t.tc.coran.navigation.ouvrir,
              onPress: () => unawaited(
                FeuilleNavigationCoran.ouvrir(context, onAller: _allerA),
              ),
            ),
            if (agrandi) ...<Widget>[
              BoutonIcone(
                key: const ValueKey<String>('coran-ma-reduire'),
                forme: FormeBoutonIcone.disque,
                icone: AppIcons.zoomMoins,
                libelle: '${t.eleve.coran.reduire}, $taille',
                infobulle: t.eleve.coran.reduire,
                onPress: () => _zoomer(-0.2),
              ),
              BoutonIcone(
                key: const ValueKey<String>('coran-ma-agrandir'),
                forme: FormeBoutonIcone.disque,
                icone: AppIcons.zoomPlus,
                libelle: '${t.eleve.coran.agrandir}, $taille',
                infobulle: t.eleve.coran.agrandir,
                onPress: () => _zoomer(0.2),
              ),
            ],
            if (suivante == null)
              SizedBox.square(
                key: LecteurCoranAccessibilite.placeSuivanteKey,
                dimension: cible,
              )
            else
              BoutonIcone(
                key: const ValueKey<String>('coran-ma-page-suivante'),
                forme: FormeBoutonIcone.disque,
                icone: AppIcons.flecheAction,
                libelle: t.eleve.coran.pageSuivante,
                onPress: () => _allerA(suivante),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnteteLecteurCoranAccessibilite(
          key: LecteurCoranAccessibilite.enteteKey,
          titre: <String>[
            sourate?.nomTranslittere ?? t.eleve.coran.titre,
            t.commun.formats.pageSur(
              page: '${vue?.numero ?? etat.page}',
              total: '${vue?.nombrePages ?? pagesMushafMedine}',
            ),
          ].join(' . '),
          onRetour: widget.onRetour,
        ),
        Expanded(
          child: CommandesMasquables(
            // MA-TUTOIEMENT-1 : les vues de rendu, inchangees, recoivent les
            // phrases de leurs etats sans texte au registre de l'eleve.
            contenu: TextesLecteurCoran(
              indisponibleDetail: widget.tutoiement
                  ? t.eleve.coran.indisponibleDetail
                  : t.accessibilite.coran.indisponibleDetailVous,
              absentDetail: widget.tutoiement
                  ? t.eleve.coran.absentDetail
                  : t.accessibilite.coran.absentDetailVous,
              child: switch (etat.mode) {
                ModeRenduCoran.versetAgrandi => const VueVersetAgrandi(),
                _ => const VuePageMushaf(),
              },
            ),
            commandes: commandes,
            // Finition MA-CMD-1 : la barre du bas s'efface avec les
            // commandes et revient a la meme touche.
            effacerBarreBasse: true,
            // MA-CORAN-X2-1 : une page sans texte (non chargee, vide) ne passe
            // plus sous les commandes : son titre, sa phrase et « Reessayer »
            // restent lisibles a texte x2. Une page lue garde tout l'ecran,
            // exactement comme avant (le rendu du Coran ne change pas).
            margeLecture: vue != null && !vue.aDuTexte,
            // SUPERPOS-1 : avec lecteur d'ecran ou clavier, les commandes ne
            // se ferment jamais ; elles passent alors sous le Mushaf au lieu
            // d'en recouvrir le bas.
            placeReservee: true,
          ),
        ),
        if (vue != null && vue.aDuTexte)
          Padding(
            key: LecteurCoranAccessibilite.attributionKey,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: gabarit.gouttiere,
              vertical: AppSpacing.xs,
            ),
            child: AttributionCoranCompacte(
              texte:
                  '${t.eleve.coran.edition} . ${t.eleve.coran.source} . '
                  '${t.eleve.coran.sourceLien}',
              style: palette.inkFaint.applyTo(
                textes.labelSmall ?? const TextStyle(),
              ),
            ),
          ),
      ],
    );
  }
}

/// L'attribution Tanzil du lecteur, **toujours affichee en entier** (la
/// licence demande que la source soit clairement indiquee) mais tenue sur
/// [lignesMax] lignes au plus : quand le texte agrandi par l'utilisateur la
/// ferait deborder, son echelle descend, par pas, jusqu'a la taille de base
/// au minimum (jamais en dessous). Si meme la taille de base ne tient pas,
/// le texte passe a la ligne autant qu'il le faut : il n'est jamais coupe
/// ni masque. Finition MA-CMD-1 (02/10/2026) : a 200 %, quatre lignes
/// prenaient au Coran une hauteur dont il a besoin.
class AttributionCoranCompacte extends StatelessWidget {
  /// Cree l'attribution.
  const AttributionCoranCompacte({
    required this.texte,
    required this.style,
    super.key,
  });

  /// Le texte complet de l'attribution.
  final String texte;

  /// Le style de base (avant l'echelle de texte de l'utilisateur).
  final TextStyle style;

  /// Le nombre de lignes vise.
  static const int lignesMax = 2;

  /// Le pas de reduction de l'echelle.
  static const double _pas = 0.05;

  @override
  Widget build(BuildContext context) {
    final TextScaler echelleUtilisateur = MediaQuery.textScalerOf(context);
    final TextDirection sens = Directionality.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double base = style.fontSize ?? 14;
        final double facteurUtilisateur = echelleUtilisateur.scale(base) / base;
        double facteur = facteurUtilisateur;
        while (facteur > 1) {
          final TextPainter mesure = TextPainter(
            text: TextSpan(text: texte, style: style),
            textAlign: TextAlign.center,
            textDirection: sens,
            textScaler: TextScaler.linear(facteur),
            maxLines: lignesMax,
          )..layout(maxWidth: contraintes.maxWidth);
          final bool tient = !mesure.didExceedMaxLines;
          mesure.dispose();
          if (tient) break;
          facteur = (facteur - _pas).clamp(1, facteurUtilisateur);
        }
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: facteur < 1 ? 1 : facteur,
          minScaleFactor: 0,
          child: Text(texte, textAlign: TextAlign.center, style: style),
        );
      },
    );
  }
}

/// L'en-tete minimal du lecteur, sur une ligne : le retour en icone seule
/// (nom lu « Retour », infobulle) et le titre en petit, reduit si besoin
/// pour tenir en entier sur cette ligne (MA-CORAN-TETE-1).
class EnteteLecteurCoranAccessibilite extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteLecteurCoranAccessibilite({
    required this.titre,
    required this.onRetour,
    super.key,
  });

  /// La sourate et la page (ou le titre du Coran).
  final String titre;

  /// Le retour a l'entree ; nul : pas de bouton.
  final VoidCallback? onRetour;

  /// La cle du titre (tests, captures).
  static const Key titreKey = ValueKey<String>('coran-ma-entete-titre');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Gabarit gabarit = AppGabarit.de(context);
    final VoidCallback? retour = onRetour;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        retour == null ? gabarit.gouttiere : AppSpacing.xs,
        AppSpacing.xs,
        gabarit.gouttiere,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          if (retour != null) ...<Widget>[
            BoutonIcone(
              key: const ValueKey<String>('coran-ma-retour'),
              icone: AppIcons.retour,
              libelle: t.commun.retour,
              onPress: retour,
              forme: FormeBoutonIcone.nue,
            ),
            Ecart.hXs,
          ],
          // MA-CORAN-TETE-1 (meme principe que MA-TITRE-1) : l'en-tete reste
          // sur une ligne (MA-CMD-1) a texte x2 ; jamais de points de
          // suspension, le titre se reduit juste assez pour tenir en entier.
          Expanded(
            child: FittedBox(
              key: titreKey,
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                titre,
                maxLines: 1,
                softWrap: false,
                style: palette.inkStrong.applyTo(
                  textes.labelMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
