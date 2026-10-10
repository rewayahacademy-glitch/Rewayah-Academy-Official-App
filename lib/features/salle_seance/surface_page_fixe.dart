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
  /// Le deplacement local de la page (points de la surface), voulu ; il est
  /// borne a chaque rendu (la boite et le zoom changent).
  Offset _deplacement = Offset.zero;

  /// Les pointeurs poses sur la surface, et leur appareil.
  final Map<int, PointerDeviceKind> _poses = <int, PointerDeviceKind>{};

  /// Un stylet s'est montre : avec Ecrire, le doigt deplace (plan V2 §7).
  bool _styletVu = false;

  /// Le dernier repere rendu (bornes du deplacement).
  Rect _page = Rect.zero;
  Size _boite = Size.zero;

  @override
  void initState() {
    super.initState();
    _reconcilier();
  }

  /// TB-11b (tour 2) : le tableau partage (revenu, ou jamais interrompu),
  /// les traits notes « non partages » ne le sont plus : la marque est
  /// effacee, une interruption suivante ne les remarque pas.
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
      _deplacement = Offset.zero;
    }
  }

  void _poser(PointerDownEvent e) {
    _poses[e.pointer] = e.kind;
    if (e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus) {
      _styletVu = true;
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
    final Offset voulu = borneDeplacement(
      voulu: _deplacement + e.delta / deplacent.length.toDouble(),
      page: _page,
      boite: _boite,
      zoom: widget.zoom,
    );
    if (voulu != _deplacement) setState(() => _deplacement = voulu);
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
  });

  final VueSeance vue;

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
    final List<TraitVectoriel> notes = vue.notesAffichees;
    final Set<String> connus = <String>{
      for (final TraitVectoriel trait in notes) trait.id,
    };
    final List<TraitVectoriel> traits = <TraitVectoriel>[
      ...notes,
      for (final TraitVectoriel trait in ref.watch(
        notesDeposeesProvider(ancrage.resourceId),
      ))
        if (trait.ancrage == ancrage && !connus.contains(trait.id)) trait,
    ];
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
            onEvenement: (EvenementOutil evenement) {
              final TraitsNonPartages suivi = ref.read(
                traitsNonPartagesProvider.notifier,
              );
              if (evenement is EvenementTraitTermine && vue.encreNonPartagee) {
                suivi.ajouter(evenement.trait.id);
              } else if (evenement is EvenementTraitRetire) {
                suivi.retirer(evenement.traitId);
              }
            },
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
    );
  }
}

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
