// TB-6 (PED-01 a PED-04 ; plan V2 §2, §3, §9, §12) : la surface
// pedagogique a page fixe.
//
// Une page (ou la feuille du tableau) a ratio fixe, posee en
// `BoxFit.contain` dans la place laissee : jamais etiree, jamais inversee en
// sombre (document lu comme sur papier). Trois affichages partages :
// Support (notes cachees, jamais effacees), Avec notes, Tableau (le fond du
// support masque, feuille claire au meme ratio, notes visibles). Sans
// support presente : le tableau libre. Le calque des notes reste monte
// d'un affichage a l'autre : masquer puis reafficher ne perd rien.
//
// TB-7a (plan V2 §9) : le calque porte `CoucheAnnotation`, au repere de la
// page ([ReperePage]) ; la page et ses notes sont lues dans la meme
// transformation locale (zoom), qui remplace le `Transform.scale` de TB-6.
//
// TB-7b (plan V2 §7) : gestes. En lecture, un doigt (ou la souris, ou le
// stylet) deplace la page agrandie ; avec Ecrire, un doigt ecrit et deux
// doigts deplacent (un doigt deplace des qu'un stylet s'est montre) ; avec
// le Pointeur, un doigt montre un passage, sans trace, et deux doigts
// deplacent. Le deplacement est local, borne a la page, jamais diffuse.
//
// TB-RC (revue TB-R) :
// - M5 : un seul « stylet detecte », appris ici (Listener passif, toujours
//   atteint, meme en lecture) et passe a la couche : apres un stylet vu en
//   lecture, le doigt ne pose plus d'encre en Ecrire.
// - m14 : le deplacement est garde, rapporte a la page agrandie, dans le
//   stockage de la route (`PageStorage`) : ouvrir les Commandes ou armer
//   Ecrire remonte la surface sans perdre la part de page regardee.
// - m17, ecart ecrit : deux doigts deplacent la page, ils ne la zooment
//   pas (pas de pincement). Le zoom passe par les Commandes (Lecture,
//   plus / moins, Ajuster) ; le pincement du plan §7 est reporte (TB-7b,
//   TB21 ne demandaient que le deplacement).

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart'
    show CapaciteRessource;
import '../../core/tc_etat_partage/shared_content_state.dart'
    show ModeAffichagePartage;
import '../../core/tc_outils/ancrage_annotation.dart' show CarteDesBlocs;
import '../../core/tc_outils/annotation_layer.dart' show TraitVectoriel;
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/theme/app_contour.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../tc_dock/couche_annotation.dart';
import 'ecriture_seance.dart' show emettreEcriture, traitsDeLaSurface;
import 'notes_deposees.dart';
import 'rangement_support.dart';
import 'repere_page.dart';
import 'vue_seance.dart';

/// Le rectangle de la page dans sa boite : `BoxFit.contain`, centre (plan
/// V2 §9.1). Le repere des notes (TB-7a) est ce rectangle, jamais la boite.
Rect rectanglePage({required double ratio, required Size boite}) {
  final FittedSizes tailles = applyBoxFit(
    BoxFit.contain,
    Size(ratio, 1),
    boite,
  );
  return Alignment.center.inscribe(tailles.destination, Offset.zero & boite);
}

/// Le deplacement [voulu] de la page, borne pour qu'elle ne quitte jamais sa
/// [boite] : une page plus petite que la boite (zoom 100 %) ne bouge pas ;
/// agrandie, elle se deplace jusqu'a son bord, pas au-dela.
Offset borneDeplacement({
  required Offset voulu,
  required Rect page,
  required Size boite,
  required double zoom,
}) {
  final double x = math.max(0, (page.width * zoom - boite.width) / 2);
  final double y = math.max(0, (page.height * zoom - boite.height) / 2);
  return Offset(voulu.dx.clamp(-x, x), voulu.dy.clamp(-y, y));
}

/// La surface a page fixe : [VueSeance.vueSurface] dit quoi montrer.
class SurfacePageFixe extends ConsumerStatefulWidget {
  const SurfacePageFixe({
    required this.vue,
    required this.surface,
    this.zoom = 1,
    super.key,
  });

  final VueSeance vue;

  /// Ce que montre la surface (derive de la vue, jamais calcule ici).
  final VueSurface surface;

  /// Le zoom local (1 = 100 %), autour du centre de la page, applique a la
  /// page et a ses notes ensemble ; rien n'est diffuse.
  final double zoom;

  /// La cle de la page du support (Support, Avec notes).
  static const Key clePage = ValueKey<String>('surface-page');

  /// La cle de la feuille claire (Tableau, tableau libre).
  static const Key cleFeuille = ValueKey<String>('surface-feuille');

  /// La cle du calque des notes, monte dans les trois affichages.
  static const Key cleCalque = ValueKey<String>('surface-calque');

  /// La cle de la couche d'annotation, posee dans le calque (TB-7a).
  static const Key cleCouche = ValueKey<String>('surface-couche');

  /// La cle de la transformation commune a l'image et aux notes (TB-7a).
  static const Key cleLecture = ValueKey<String>('surface-lecture');

  /// La cle de la phrase du tableau libre (enseignant).
  static const Key cleConsigne = ValueKey<String>('surface-consigne');

  /// TB-7b : la cle du calque du Pointeur (monte quand il est retenu).
  static const Key clePointage = ValueKey<String>('surface-pointage');

  /// TB-7b : la cle de l'indication du Pointeur, tant que le doigt est pose.
  static const Key clePointeur = ValueKey<String>('surface-pointeur');

  /// La hauteur de la phrase du §12 et de sa marge dans une surface de
  /// largeur [largeur], a l'echelle du texte de l'appareil : en dessous, la
  /// phrase serait rognee (revue du 09/10, 320 x2). Le style est celui de la
  /// carte, toujours claire (meme theme que [ZoneSupport]).
  static double hauteurConsigne(BuildContext context, double largeur) {
    final ThemeData clair = AppTheme.pour(
      InterfaceMode.standard,
      Brightness.light,
    );
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: t.salle.seance.surface.aucunSupport,
        style: DefaultTextStyle.of(context).style
            .merge(clair.textTheme.bodyLarge),
      ),
      textAlign: TextAlign.center,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(0, largeur - 2 * _margeConsigne));
    final double hauteur = peintre.height;
    peintre.dispose();
    return hauteur + 2 * _margeConsigne;
  }

  @override
  ConsumerState<SurfacePageFixe> createState() => _SurfacePageFixeState();
}

class _SurfacePageFixeState extends ConsumerState<SurfacePageFixe> {
  /// TB-RC (m14) : l'identifiant du deplacement dans le stockage de la
  /// route.
  static const String _cleStockage = 'surface-page-fixe-deplacement';

  /// TB-RC (M5) : l'identifiant du stylet vu, dans le meme stockage (la
  /// surface se remonte quand on arme Ecrire ; le stylet vu reste su).
  static const String _cleStylet = 'surface-page-fixe-stylet';

  /// Le deplacement local de la page, voulu, rapporte a la taille de la
  /// page agrandie (TB-RC, m14 : il survit a une boite qui change, quand
  /// les Commandes s'ouvrent) ; il est borne a chaque rendu.
  Offset _relatif = Offset.zero;

  /// Le stockage a deja ete relu.
  bool _relu = false;

  /// Les pointeurs poses sur la surface, et leur appareil.
  final Map<int, PointerDeviceKind> _poses = <int, PointerDeviceKind>{};

  /// Un stylet s'est montre : avec Ecrire, le doigt deplace (plan V2 §7).
  /// TB-RC (M5) : le seul « stylet detecte » de la salle, passe a la
  /// couche et garde pour toute la route.
  bool _styletVu = false;

  /// Le dernier repere rendu (bornes du deplacement).
  Rect _page = Rect.zero;
  Size _boite = Size.zero;

  @override
  void initState() {
    super.initState();
    _reconcilier();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_relu) return;
    _relu = true;
    final Object? garde = PageStorage.maybeOf(context)
        ?.readState(context, identifier: _cleStockage);
    if (garde is Offset) _relatif = garde;
    _styletVu =
        PageStorage.maybeOf(
          context,
        )?.readState(context, identifier: _cleStylet) ==
        true;
  }

  /// TB-RC (m14) : garde le deplacement pour la prochaine surface montee.
  void _garder(Offset relatif) {
    _relatif = relatif;
    PageStorage.maybeOf(context)
        ?.writeState(context, relatif, identifier: _cleStockage);
  }

  /// La taille de la page agrandie, ou `null` (pas encore rendue).
  Size? get _agrandie {
    final Size taille = _page.size * widget.zoom;
    return taille.isEmpty ? null : taille;
  }

  /// Le deplacement voulu, en points de la surface.
  Offset get _deplacement {
    final Size? taille = _agrandie;
    if (taille == null) return Offset.zero;
    return Offset(_relatif.dx * taille.width, _relatif.dy * taille.height);
  }

  /// TB-11b (tour 2) : le tableau partage (revenu, ou jamais interrompu),
  /// les traits notes « non partages » ne le sont plus : la marque est
  /// effacee, une interruption suivante ne les remarque pas.
  ///
  /// TB-RC (m19), ecart ecrit : la marque est levee au retour a
  /// « partage » sans renvoi ni accuse de reception par trait ; un trait
  /// pose pendant l'interruption n'est donc pas prouve recu. La levee sur
  /// accuse par trait (TB-BR-42) arrive avec le transport (BR-1).
  void _reconcilier() {
    if (widget.vue.synchroTableau != SynchroTableau.partage) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      ref.read(traitsNonPartagesProvider.notifier).reconcilier();
    });
  }

  @override
  void didUpdateWidget(SurfacePageFixe ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.vue.synchroTableau != widget.vue.synchroTableau) _reconcilier();
    // « Ajuster a l'ecran » (zoom 100 %) recentre aussi la page.
    if (widget.zoom != ancien.zoom && widget.zoom <= 1) {
      _garder(Offset.zero);
    }
  }

  void _poser(PointerDownEvent e) {
    _poses[e.pointer] = e.kind;
    if (!_styletVu &&
        (e.kind == PointerDeviceKind.stylus ||
            e.kind == PointerDeviceKind.invertedStylus)) {
      // M5 : la couche l'apprend d'ici, ou qu'en soit l'outil.
      setState(() => _styletVu = true);
      PageStorage.maybeOf(
        context,
      )?.writeState(context, true, identifier: _cleStylet);
    }
  }

  void _lever(PointerEvent e) => _poses.remove(e.pointer);

  /// Les pointeurs qui deplacent la page, selon l'outil retenu.
  List<int> _quiDeplacent(EtatOutils etat) {
    final VueSeance vue = widget.vue;
    final bool ecrit = vue.ecritPossible && etat.styletArme;
    final bool pointe = vue.peutPointer && etat.pointeurArme;
    final List<int> doigts = <int>[
      for (final MapEntry<int, PointerDeviceKind> p in _poses.entries)
        if (p.value == PointerDeviceKind.touch) p.key,
    ];
    if (!ecrit && !pointe) return _poses.keys.toList();
    if (doigts.length >= 2) return doigts;
    if (ecrit && _styletVu) return doigts;
    return const <int>[];
  }

  void _bouger(PointerMoveEvent e) {
    final List<int> deplacent = _quiDeplacent(ref.read(etatOutilsProvider));
    if (!deplacent.contains(e.pointer)) return;
    // Deux doigts qui glissent ensemble deplacent la page de leur pas
    // commun, pas du double.
    final Size? taille = _agrandie;
    if (taille == null) return;
    final Offset voulu = borneDeplacement(
      voulu: _deplacement + e.delta / deplacent.length.toDouble(),
      page: _page,
      boite: _boite,
      zoom: widget.zoom,
    );
    if (voulu == _deplacement) return;
    setState(
      () => _garder(Offset(voulu.dx / taille.width, voulu.dy / taille.height)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final VueSurface surface = widget.surface;
    final double zoom = widget.zoom;
    final bool pointe =
        vue.peutPointer &&
        ref.watch(etatOutilsProvider.select((EtatOutils e) => e.pointeurArme));
    final SupportPageFixe? page = vue.supportPresente;
    final TableauLibre? tableau = vue.tableauLibre;
    final bool libre = surface == VueSurface.tableauLibre;
    final double ratio = libre || page == null
        ? (tableau?.ratio ?? _ratioParDefaut)
        : page.ratio;
    final bool fondSupport =
        surface == VueSurface.supportSeul ||
        surface == VueSurface.supportAvecNotes;
    final bool notesVisibles = surface != VueSurface.supportSeul;
    final bool consigne = libre && vue.voitConsigneTableauLibre;
    // TB-9 : le depart de la copie du rangement (salle de l'enseignant).
    final GlobalKey? repereRangement = PorteeRangement.maybeOf(context)
        ?.feuille;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        // TB-7a (plan V2 §9) : une seule geometrie pour l'image et l'encre,
        // la page en `BoxFit.contain` et la lecture locale (zoom, TB-7b :
        // deplacement).
        _boite = c.biggest;
        _page = rectanglePage(ratio: ratio, boite: c.biggest);
        final ReperePage repere = ReperePage.de(
          ratio: ratio,
          boite: c.biggest,
          zoom: zoom,
          deplacement: borneDeplacement(
            voulu: _deplacement,
            page: _page,
            boite: c.biggest,
            zoom: zoom,
          ),
        );
        final Rect rect = repere.page;
        // La part de la page qui se voit (la surface rogne la page zoomee),
        // dans le repere du calque : on n'ecrit pas la ou l'on ne voit pas.
        final Rect visible = repere.partVisible(c.biggest);
        final Widget feuille = SizedBox.fromSize(
          size: rect.size,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Le fond : la page du support, ou la feuille claire.
              if (fondSupport && page != null)
                _Page(key: SurfacePageFixe.clePage, page: page)
              else
                _Feuille(
                  key: SurfacePageFixe.cleFeuille,
                  libelle: libre
                      ? t.salle.seance.commandes.affichageTableau
                      : t.salle.seance.surface.supportMasque,
                ),
              // Le calque des notes : cache en Support, jamais demonte. Il
              // couvre la page exactement : son repere est la page (TB-7a).
              Visibility(
                key: SurfacePageFixe.cleCalque,
                visible: notesVisibles,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: _CalqueNotes(
                  vue: vue,
                  taille: rect.size,
                  visible: visible,
                  styletDetecte: _styletVu,
                ),
              ),
              // TB-7b : le Pointeur, dans tous les affichages (il ne pose
              // rien sur le calque des notes).
              if (pointe) const _Pointage(key: SurfacePageFixe.clePointage),
            ],
          ),
        );
        return Listener(
          // Passif : il ne prend aucun geste a la couche, il deplace la
          // page selon l'outil retenu.
          behavior: HitTestBehavior.translucent,
          onPointerDown: _poser,
          onPointerMove: _bouger,
          onPointerUp: _lever,
          onPointerCancel: _lever,
          child: ClipRect(
            child: Stack(
              children: <Widget>[
                // Image et encre dans la MEME transformation (§9.5) : un
                // point touche revient a la page par son inverse (toScene).
                Positioned.fill(
                  child: Transform(
                    key: SurfacePageFixe.cleLecture,
                    transform: repere.lecture,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fromRect(
                          rect: rect,
                          child: KeyedSubtree(
                            key: repereRangement,
                            child: feuille,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // La phrase du §12 se pose sur toute la surface, pas dans la
                // seule feuille : vide, celle-ci ne cache rien, et la phrase
                // garde la largeur de l'ecran a texte agrandi (elle defile si
                // la hauteur manque).
                if (consigne)
                  Positioned.fill(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(_margeConsigne),
                        child: Text(
                          t.salle.seance.surface.aucunSupport,
                          key: SurfacePageFixe.cleConsigne,
                          textAlign: TextAlign.center,
                          style: _styleConsigne(context),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// TB-7b (plan V2 §4.2) : le Pointeur. Tant qu'un seul doigt (ou la
/// souris, ou le stylet) est pose sur la page, une indication le suit ;
/// levee, elle disparait. Rien n'est ecrit, rien n'est garde.
class _Pointage extends StatefulWidget {
  const _Pointage({super.key});

  @override
  State<_Pointage> createState() => _PointageState();
}

class _PointageState extends State<_Pointage> {
  final Map<int, Offset> _poses = <int, Offset>{};

  /// Le point montre : un seul pointeur pose. Deux doigts deplacent.
  Offset? get _montre => _poses.length == 1 ? _poses.values.single : null;

  void _suivre(PointerEvent e) =>
      setState(() => _poses[e.pointer] = e.localPosition);

  void _lever(PointerEvent e) => setState(() => _poses.remove(e.pointer));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Offset? montre = _montre;
    const double taille = AppSpacing.xl;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _suivre,
      onPointerMove: _suivre,
      onPointerUp: _lever,
      onPointerCancel: _lever,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (montre != null)
            // Un point de la page (geometrique, comme les traits), pas un
            // cote de lecture : le meme en arabe.
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center: montre,
                width: taille,
                height: taille,
              ),
              child: IgnorePointer(
                child: DecoratedBox(
                  key: SurfacePageFixe.clePointeur,
                  decoration: palette.washAccent.decoration(
                    borderRadius: AppRadius.arrondiFull,
                    side: palette.inkAccent.asBorderSide(
                      width: AppContour.fort,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// TB-7a : le calque des notes, au repere de la page. `CoucheAnnotation`
/// (tc_dock) y est montee sur un seul bloc qui couvre la page : son cadre
/// est la page elle-meme, l'ancrage celui de la page montree
/// ([VueSeance.ancrageSurface]). Elle peint les notes de cette page
/// seulement, celles de la vue et celles que le depot a prises
/// ([notesDeposeesProvider]) ; elle ne recoit un geste que si la personne peut ecrire
/// ([VueSeance.peutEcrire]) ET que l'outil d'ecriture est arme : sinon le
/// calque se lit, sans focus ni geste.
class _CalqueNotes extends ConsumerWidget {
  const _CalqueNotes({
    required this.vue,
    required this.taille,
    required this.visible,
    required this.styletDetecte,
  });

  final VueSeance vue;

  /// TB-RC (M5) : la surface a deja vu un stylet.
  final bool styletDetecte;

  /// La taille de la page avant la lecture locale.
  final Size taille;

  /// La part visible de la page, dans le repere de la page.
  final Rect visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentPosition? ancrage = vue.ancrageSurface;
    if (ancrage == null) return const SizedBox.expand();
    final bool arme = ref.watch(
      etatOutilsProvider.select((EtatOutils e) => e.styletArme),
    );
    // TB-11b : la reprise du tableau suspend l'ecriture (plan V2 §19.5).
    final bool saisie = vue.ecritPossible && arme;
    // TB-11b (plan V2 §10) : les traits que la classe n'a pas recus, tant
    // que le tableau n'est pas revenu : ceux que dit la vue, et ceux que la
    // personne vient de poser pendant l'interruption.
    final Set<String> locaux = ref.watch(traitsNonPartagesProvider);
    final Set<String> nonPartages = vue.synchroTableau == SynchroTableau.partage
        ? vue.traitsNonPartages
        : <String>{...vue.traitsNonPartages, ...locaux};
    // Les notes de la vue, puis celles que le depot a prises pour cette
    // page (l'encre posee reste peinte, meme quand la surface se remonte).
    final List<TraitVectoriel> traits = traitsDeLaSurface(ref, vue);
    return ExcludeFocus(
      excluding: !saisie,
      child: ExcludeSemantics(
        excluding: !saisie,
        child: IgnorePointer(
          ignoring: !saisie,
          child: CoucheAnnotation(
            key: SurfacePageFixe.cleCouche,
            support: SupportPresente(
              resourceId: ancrage.resourceId,
              resourceVersionId: ancrage.resourceVersionId,
              capacites: const <CapaciteRessource>{
                CapaciteRessource.annotatable,
              },
              modeAffichage: ModeAffichagePartage.page,
              blocs: CarteDesBlocs(cadre: Offset.zero & taille),
              ancrageCadre: ancrage,
            ),
            contexte: ContexteDock(groupeId: vue.groupeId),
            traits: traits,
            repereDePage: true,
            gommeSurTous: vue.gereToutesLesNotes,
            zoneVisible: visible,
            // TB-10 : le droit retire pendant un trait le resout ici.
            saisie: saisie,
            traitsNonPartages: nonPartages,
            encreNonPartagee: vue.encreNonPartagee,
            styletDetecte: styletDetecte,
            // TB-RC (M6) : le rappel unique, celui des boutons Annuler.
            onEvenement: (EvenementOutil evenement) =>
                emettreEcriture(ref, vue, evenement),
          ),
        ),
      ),
    );
  }
}

/// La marge autour de la phrase du §12.
const double _margeConsigne = AppSpacing.lg;

TextStyle _styleConsigne(BuildContext context) =>
    AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyLarge ?? const TextStyle());

/// Sans donnee de ratio : celui d'une page A4 en portrait.
const double _ratioParDefaut = 1240 / 1754;

/// La page du support. Aucune image n'est livree en demonstration
/// (`cleImage` nulle, fournisseur des pages a BR-1) : une page neutre qui
/// porte son titre et sa mention, jamais un faux contenu. Sa position est
/// dite au lecteur d'ecran ; ecrite, elle doublerait la pagination des
/// Commandes de l'enseignant (TB14).
class _Page extends StatelessWidget {
  const _Page({required this.page, super.key});

  final SupportPageFixe page;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? mention = page.mention;
    return Semantics(
      image: true,
      label: t.salle.seance.surface.page(
        titre: page.titre,
        page: page.page,
        pages: page.total,
      ),
      child: ExcludeSemantics(
        child: _Cadre(
          // Une page fixe est un document : son contenu suit le sens de sa
          // langue, jamais celui de l'interface (revue TB-6 : en arabe, la
          // page francaise de demonstration se calait a droite). Le titre
          // dit la langue du document, avant la mention (TB-12, R-18 : la
          // mention francaise de demonstration calait a gauche un support
          // arabe).
          child: Directionality(
            textDirection: sensDuDocument(<String?>[page.titre, mention]),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              // Le texte de la page est celui du document : il suit la taille
              // de la page, jamais le texte de l'interface.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.topStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (mention != null) ...<Widget>[
                      Text(
                        mention,
                        style: palette.inkMuted.applyTo(
                          textes.labelMedium ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vSm,
                    ],
                    Text(
                      page.titre,
                      style: palette.inkStrong.applyTo(
                        textes.titleLarge ?? const TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le sens d'ecriture d'un document, d'apres le premier caractere fort de
/// ses [textes] (dans l'ordre) : arabe ou hebreu, droite a gauche ; sinon,
/// et sans caractere fort, gauche a droite. La ressource ne porte pas
/// encore sa langue (BR-1) : son texte la dit.
@visibleForTesting
TextDirection sensDuDocument(Iterable<String?> textes) {
  for (final String? texte in textes) {
    if (texte == null) continue;
    for (final int c in texte.runes) {
      if (_droiteAGauche(c)) return TextDirection.rtl;
      if (_gaucheADroite(c)) return TextDirection.ltr;
    }
  }
  return TextDirection.ltr;
}

bool _droiteAGauche(int c) =>
    (c >= 0x0590 && c <= 0x08FF) ||
    (c >= 0xFB1D && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF);

bool _gaucheADroite(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0xC0 && c <= 0x024F && c != 0xD7 && c != 0xF7);

/// La feuille claire du tableau : meme ratio que la page, notes au-dessus.
class _Feuille extends StatelessWidget {
  const _Feuille({required this.libelle, super.key});

  final String libelle;

  @override
  Widget build(BuildContext context) => Semantics(
    label: libelle,
    container: true,
    child: const _Cadre(child: SizedBox.expand()),
  );
}

/// Le bord d'une page ou d'une feuille : surface claire, filet, ombre de
/// niveau 1. Toujours en theme clair (pose par [ZoneSupport]).
class _Cadre extends StatelessWidget {
  const _Cadre({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.surfaceRaised
          .decoration(
            borderRadius: AppRadius.arrondiSm,
            side: palette.borderHairline.asBorderSide(),
          )
          .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
      child: child,
    );
  }
}
