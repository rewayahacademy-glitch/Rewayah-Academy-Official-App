import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_outils/ancrage_annotation.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/compaction_trait.dart';
import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Qui a le droit d'ecrire, et qui garde la navigation.
///
/// **Rien n'ecrit tant que l'outil d'ecriture n'est pas arme** (plan V2 §7,
/// lignes 164-165 ; TB21 ; TB-STYLET-1) : lire au doigt ou poser le stylet
/// sur la page ne laisse aucune trace. Une fois l'outil arme : **stylet =
/// encre, doigt = pan et zoom** des qu'un stylet s'est manifeste ; sur un
/// appareil qui n'en a pas, le doigt et la souris ecrivent, sans quoi
/// l'annotation serait impossible sur un telephone.
///
/// Consequence voulue : sur une tablette avec stylet, poser la main ou faire
/// glisser le texte ne dessine jamais.
abstract final class PolitiqueSaisie {
  /// Les appareils qui posent de l'encre, dans ce contexte. Vide tant que
  /// l'outil n'est pas arme.
  static Set<PointerDeviceKind> appareilsDeDessin({
    required bool styletDetecte,
    required bool styletArme,
  }) {
    if (!styletArme) {
      return const <PointerDeviceKind>{};
    }
    if (!styletDetecte) {
      return const <PointerDeviceKind>{
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
    }
    return const <PointerDeviceKind>{
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
    };
  }
}

/// La couche d'annotation posee **au dessus** du support.
///
/// ```
/// RESSOURCE ORIGINALE IMMUABLE + COUCHE D'ANNOTATION + MARQUEURS = RENDU
/// ```
///
/// Elle ne touche pas au support : elle le recouvre, lit la geometrie que
/// l'hote publie et peint des traits ancres. **Aucune copie de la ressource
/// n'est creee, jamais**, ni a l'ecran ni en memoire.
///
/// Elle ne transporte rien non plus : elle rend des [EvenementOutil] a l'hote,
/// qui les confie au port d'Agent F.
class CoucheAnnotation extends ConsumerStatefulWidget {
  /// Cree une couche d'annotation.
  const CoucheAnnotation({
    required this.support,
    required this.contexte,
    required this.traits,
    super.key,
    this.marqueurs = const <MarqueurSemantique>[],
    this.onEvenement,
    this.onAncrageDegrade,
    this.generateur = const Uuid(),
    this.repereDePage = false,
    this.zoneVisible,
    this.gommeSurTous = true,
  });

  /// TB-7b (UX_REVIEW_TB n. 21, plan V2 §19.3.6) : la gomme retire tout
  /// trait (l'enseignant gere la surface), ou seulement ceux de la personne
  /// (un eleve autorise a ecrire). L'hote le lit d'une capacite de sa vue.
  final bool gommeSurTous;

  /// Le support annote, avec la geometrie courante de ses blocs.
  final SupportPresente support;

  /// Le groupe, la seance et le profil courants.
  final ContexteDock contexte;

  /// Les traits deja poses, tels que l'hote les lit de [PortAnnotations].
  final List<TraitVectoriel> traits;

  /// Les marqueurs de plage de la meme couche.
  ///
  /// Ils ne sont **pas** des dessins : la couche leur prete la geometrie des
  /// blocs qu'ils designent, et rien n'est stocke en pixels.
  final List<MarqueurSemantique> marqueurs;

  /// Ce que la couche a a dire au reste de la classe.
  final void Function(EvenementOutil evenement)? onEvenement;

  /// Appele quand un trait vient d'etre ancre spatialement sur un rendu
  /// reflowable : il se decalera a la prochaine recomposition, et l'hote peut
  /// le dire discretement.
  final VoidCallback? onAncrageDegrade;

  /// Le generateur d'identifiants, injecte pour les tests.
  final Uuid generateur;

  /// TB-7a (plan V2 §9 ; TB19) : la couche couvre une page fixe, dont
  /// [SupportPresente.blocs] porte le cadre. Un geste qui commence hors du
  /// cadre est rejete ; un geste qui en sort termine le trait sur son
  /// dernier point dans la page (jamais rabattu sur le bord, §9.4), et un
  /// retour dans la page sans lever le doigt n'ecrit rien. L'epaisseur du
  /// trait suit la largeur de la page (§9 : « l'epaisseur de l'annotation
  /// suit la page »).
  final bool repereDePage;

  /// TB-7a : la part de la page qui se voit, dans le repere de la couche
  /// (page zoomee rognee par sa surface), ou `null` (toute la page). Un
  /// point hors de cette part est traite comme hors de la page : on
  /// n'ecrit pas la ou l'on ne voit pas.
  final Rect? zoneVisible;

  /// TB-7b (plan V2 §13) : le nombre de fois ou les traits termines ont
  /// ete peints. Un test mesure qu'un trait en cours ne les repeint pas.
  @visibleForTesting
  static int debugPeinturesTraits = 0;

  @override
  ConsumerState<CoucheAnnotation> createState() => _CoucheAnnotationState();
}

class _CoucheAnnotationState extends ConsumerState<CoucheAnnotation> {
  /// Rayon de la gomme, en points d'ecran.
  static const double rayonGomme = AppSpacing.md;

  bool _styletDetecte = false;
  TraitEnCours? _enCours;
  Rect? _blocEnCours;
  String? _idEnCours;

  /// TB-7b (plan V2 §13 « repaint cible ») : le trait en cours se peint par
  /// cette valeur, sans reconstruire la couche ni repeindre les traits
  /// termines a chaque point.
  final ValueNotifier<List<PointNormalise>> _apercu =
      ValueNotifier<List<PointNormalise>>(const <PointNormalise>[]);

  /// Les traits que cette couche vient de terminer, tant que [widget.traits]
  /// ne les rend pas encore : l'encre posee reste peinte des que le doigt
  /// se leve (TB-7a, revue du tour 2). Un trait que le depot refuse en est
  /// retire ; un trait que l'hote rend dans [CoucheAnnotation.traits] n'y
  /// est plus garde, l'hote fait foi des lors (une annulation du dock le
  /// retire donc bien de l'ecran).
  final List<TraitVectoriel> _poses = <TraitVectoriel>[];

  /// TB-7b (plan V2 §7) : les doigts poses. Deux doigts deplacent la page,
  /// ils n'ecrivent jamais : le trait commence par le premier est abandonne.
  final Set<int> _doigts = <int>{};

  /// Un deuxieme doigt s'est pose : plus rien n'ecrit avant que tous les
  /// doigts ne se levent.
  bool _plusieursDoigts = false;

  /// Les appareils qui ecrivent, au dernier rendu.
  Set<PointerDeviceKind> _appareils = const <PointerDeviceKind>{};

  /// Les traits retires par le geste de gomme en cours (une operation).
  final List<TraitVectoriel> _gommesDuGeste = <TraitVectoriel>[];

  @override
  void didUpdateWidget(CoucheAnnotation ancien) {
    super.didUpdateWidget(ancien);
    // TB-7b (plan V2 §13 « ancien trait recu sur une nouvelle page ») : la
    // page change pendant un trait. Le trait est resolu dans son contexte :
    // il se termine sur la page ou il a commence (son ancrage), et la suite
    // du geste n'ecrit rien sur la nouvelle page.
    if (_enCours != null &&
        ancien.support.ancrageCadre != widget.support.ancrageCadre) {
      _terminer(ref.read(etatOutilsProvider));
    }
    if (_poses.isEmpty) return;
    final Set<String> rendus = <String>{
      for (final TraitVectoriel trait in widget.traits) trait.id,
    };
    _poses.removeWhere((TraitVectoriel trait) => rendus.contains(trait.id));
  }

  @override
  void dispose() {
    _apercu.dispose();
    super.dispose();
  }

  /// La surface de cette couche, pour l'historique personnel : la page
  /// montree, sinon le support (rendu reflowable : tous ses blocs).
  bool _surCetteSurface(ContentPosition position) {
    final ContentPosition? page = widget.support.ancrageCadre;
    if (widget.repereDePage) return page != null && position == page;
    return position.resourceId == widget.support.resourceId;
  }

  /// Les traits a peindre et a gommer : ceux de l'hote, puis ceux que la
  /// couche vient de poser, moins ceux que la personne a retires. Sur une
  /// page fixe, seuls ceux de la page montree (un trait d'une autre page se
  /// resoudrait sur ce cadre, a tort).
  List<TraitVectoriel> _visibles(Set<String> retires) {
    final Set<String> rendus = <String>{
      for (final TraitVectoriel trait in widget.traits) trait.id,
    };
    final ContentPosition? page = widget.repereDePage
        ? widget.support.ancrageCadre
        : null;
    return <TraitVectoriel>[
      for (final TraitVectoriel trait in widget.traits)
        if (!retires.contains(trait.id)) trait,
      for (final TraitVectoriel trait in _poses)
        if (!rendus.contains(trait.id) &&
            !retires.contains(trait.id) &&
            (page == null || trait.ancrage == page))
          trait,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final HistoriquePersonnel historique = ref.watch(
      historiquePersonnelProvider,
    );
    final Set<PointerDeviceKind> appareils = PolitiqueSaisie.appareilsDeDessin(
      styletDetecte: _styletDetecte,
      styletArme: etat.styletArme,
    );
    _appareils = appareils;
    final List<TraitVectoriel> visibles = _visibles(historique.retires);
    final bool effacable = _annulable(historique, visibles);

    // Alternative au geste (revue P2-10, mineur 4) : l'ardoise se nomme au
    // lecteur d'ecran, dit qu'elle est facultative, et offre « Effacer mon
    // dernier trait » en action semantique et au clavier (Suppr, Retour
    // arriere) quand la surface a le focus. TB-7b : « mon » dernier trait,
    // jamais celui d'un autre (UX_REVIEW_TB n. 21).
    return Semantics(
      container: true,
      label: t.tc.outils.trait.ardoise,
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        if (effacable)
          CustomSemanticsAction(label: t.tc.outils.trait.effacerDernier):
              effacerDernierTrait,
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.delete): effacerDernierTrait,
          const SingleActivator(LogicalKeyboardKey.backspace):
              effacerDernierTrait,
        },
        child: Focus(child: _surface(palette, etat, appareils, visibles)),
      ),
    );
  }

  /// La derniere operation personnelle de cette surface peut-elle etre
  /// defaite ? Un trait pose que l'hote ne rend plus (annule ailleurs) n'a
  /// plus rien a retirer : l'hote fait foi.
  bool _annulable(
    HistoriquePersonnel historique,
    List<TraitVectoriel> visibles,
  ) {
    final OperationPersonnelle? derniere = historique.derniere(
      _surCetteSurface,
    );
    return switch (derniere) {
      null => false,
      TraitPosePersonnel(:final TraitVectoriel trait) => visibles.any(
        (TraitVectoriel v) => v.id == trait.id,
      ),
      TraitsGommesPersonnels() => true,
    };
  }

  /// Defait la derniere operation personnelle de cette surface (un trait
  /// pose, ou un geste de gomme), sans geste : la voie du clavier et du
  /// lecteur d'ecran. Le meme « Annuler » que la barre d'ecriture.
  void effacerDernierTrait() => unawaited(_annuler());

  Future<void> _annuler() async {
    final PortAnnotations depot;
    try {
      depot = ref.read(portAnnotationsProvider);
    } on Object {
      return;
    }
    final OperationDefaite? defaite = await ref
        .read(historiquePersonnelProvider.notifier)
        .annuler(_surCetteSurface, depot);
    if (defaite == null || !mounted) return;
    switch (defaite.operation) {
      case TraitPosePersonnel(:final TraitVectoriel trait):
        setState(
          () => _poses.removeWhere((TraitVectoriel p) => p.id == trait.id),
        );
        widget.onEvenement?.call(
          EvenementTraitRetire(coucheId: defaite.coucheId, traitId: trait.id),
        );
      case final TraitsGommesPersonnels gommes:
        for (final TraitVectoriel trait in gommes.traits) {
          widget.onEvenement?.call(
            EvenementTraitTermine(
              coucheId: defaite.coucheId,
              trait: trait,
              portee: gommes.portee,
            ),
          );
        }
    }
  }

  Widget _surface(
    AppPalette palette,
    EtatOutils etat,
    Set<PointerDeviceKind> appareils,
    List<TraitVectoriel> visibles,
  ) {
    final double? largeurPage = widget.repereDePage
        ? widget.support.blocs.cadre?.width
        : null;
    return Listener(
      // Le guetteur est passif : il ne consomme rien, il apprend seulement
      // qu'un stylet existe sur cet appareil (des lors, le doigt redevient la
      // navigation, definitivement), et compte les doigts poses.
      onPointerDown: _guetter,
      onPointerUp: _lever,
      onPointerCancel: _lever,
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        // Le doigt n'est pas dans cette liste sur un appareil a stylet : ses
        // evenements traversent la couche et vont au support, qui garde son
        // pan et son zoom.
        supportedDevices: appareils,
        behavior: HitTestBehavior.translucent,
        onPanStart: (DragStartDetails details) =>
            _commencer(details.localPosition, etat),
        onPanUpdate: (DragUpdateDetails details) =>
            _prolonger(details.localPosition, etat),
        onPanEnd: (DragEndDetails details) => _terminer(etat),
        onPanCancel: () => _terminer(etat),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Les traits termines : leur propre calque, repeint seulement
            // quand la liste change (plan V2 §13 « chemins termines mis en
            // cache »).
            RepaintBoundary(
              child: CustomPaint(
                painter: _PeintreAnnotations(
                  palette: palette,
                  support: widget.support,
                  traits: visibles,
                  marqueurs: widget.marqueurs,
                  intentionParDefaut: etat.intention,
                  largeurPage: largeurPage,
                ),
              ),
            ),
            // Le trait en cours, seul repeint a chaque point.
            CustomPaint(
              painter: _PeintreApercu(
                palette: palette,
                apercu: _apercu,
                bloc: () => _blocEnCours,
                outil: etat.outilTrait,
                intention: etat.intention,
                epaisseur: etat.epaisseur,
                largeurPage: largeurPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vrai quand [point] tombe dans la page, bords compris.
  bool _dansLaPage(Offset point) {
    final Rect? page = widget.support.blocs.cadre;
    if (page == null) {
      return false;
    }
    final Rect? visible = widget.zoneVisible;
    if (visible != null &&
        (point.dx < visible.left ||
            point.dy < visible.top ||
            point.dx > visible.right ||
            point.dy > visible.bottom)) {
      return false;
    }
    return point.dx >= page.left &&
        point.dy >= page.top &&
        point.dx <= page.right &&
        point.dy <= page.bottom;
  }

  void _guetter(PointerDownEvent evenement) {
    if (evenement.kind == PointerDeviceKind.touch) {
      _doigts.add(evenement.pointer);
      // Deux doigts deplacent, ils n'ecrivent pas (plan V2 §7) : le trait
      // que le premier doigt avait commence est abandonne, sans trace.
      if (_doigts.length >= 2 && _appareils.contains(PointerDeviceKind.touch)) {
        _abandonner();
      }
    }
    if (_styletDetecte) {
      return;
    }
    if (evenement.kind == PointerDeviceKind.stylus ||
        evenement.kind == PointerDeviceKind.invertedStylus) {
      setState(() => _styletDetecte = true);
    }
  }

  void _lever(PointerEvent evenement) {
    _doigts.remove(evenement.pointer);
    if (_doigts.isEmpty) _plusieursDoigts = false;
  }

  /// Oublie le trait en cours, sans le poser : le geste n'etait pas une
  /// ecriture.
  void _abandonner() {
    _plusieursDoigts = true;
    _enCours = null;
    _blocEnCours = null;
    _idEnCours = null;
    _apercu.value = const <PointNormalise>[];
  }

  void _commencer(Offset point, EtatOutils etat) {
    if (_plusieursDoigts) return;
    if (etat.outilTrait == OutilTrait.gomme) {
      _gommesDuGeste.clear();
      _gommer(point);
      return;
    }

    if (widget.repereDePage && !_dansLaPage(point)) {
      // Hors de la page : rejete, jamais rabattu sur le bord (§9.4).
      return;
    }

    final BlocAncre? bloc = widget.support.blocs.blocA(point);
    final ResultatAncrage ancrage = choisirAncrage(
      mode: widget.support.modeAffichage,
      semantique: bloc != null && estSemantique(bloc.position)
          ? bloc.position
          : null,
      spatial: widget.support.ancrageCadre,
    );
    final ContentPosition? position = ancrage.position;
    if (position == null) {
      // Rien a quoi s'ancrer : on ne pose pas un trait qui se retrouverait
      // n'importe ou au prochain rendu.
      return;
    }
    if (ancrage.degrade) {
      widget.onAncrageDegrade?.call();
    }

    final Rect? cadre = widget.support.blocs.rectDe(position);
    if (cadre == null) {
      return;
    }

    _blocEnCours = cadre;
    _idEnCours = widget.generateur.v4();
    _enCours = TraitEnCours(
      ancrage: position,
      outil: etat.outilTrait,
      intention: etat.intention,
      epaisseur: etat.epaisseur,
    )..ajouter(normaliserDans(cadre, point));
    _apercu.value = <PointNormalise>[normaliserDans(cadre, point)];
  }

  void _prolonger(Offset point, EtatOutils etat) {
    if (_plusieursDoigts) return;
    if (etat.outilTrait == OutilTrait.gomme) {
      _gommer(point);
      return;
    }
    final TraitEnCours? trait = _enCours;
    final Rect? bloc = _blocEnCours;
    if (trait == null || bloc == null) {
      return;
    }
    if (widget.repereDePage && !_dansLaPage(point)) {
      // Le geste sort de la page : le trait s'arrete au dernier point pose
      // dans la page (UX_REVIEW_TB n. 20, « l'hote finit le trait quand le
      // doigt sort de la page »). Le point dehors n'est pas garde ni rabattu
      // sur le bord (§9.4), et le reste du geste n'ecrit plus : un retour
      // dans la page ne relie rien a l'ancien trait et n'en ouvre pas un
      // autre, il faut lever le doigt (pas de trait inattendu).
      _terminer(etat);
      return;
    }
    final PointNormalise normalise = normaliserDans(bloc, point);
    trait.ajouter(normalise);
    _apercu.value = <PointNormalise>[..._apercu.value, normalise];

    if (trait.paquetPret) {
      final List<PointNormalise> paquet = trait.prendrePaquet();
      if (paquet.isNotEmpty) {
        // Pendant le geste : paquet leger, canal ephemere. Perdre celui-la ne
        // coute qu'un sursaut chez les autres, et le trait final corrigera.
        widget.onEvenement?.call(
          EvenementTraitEnCours(
            traitId: _idEnCours!,
            ancrage: trait.ancrage,
            pointsNouveaux: paquet,
            outil: trait.outil,
            intention: trait.intention,
          ),
        );
      }
    }
  }

  void _terminer(EtatOutils etat) {
    if (_gommesDuGeste.isNotEmpty) {
      ref
          .read(historiquePersonnelProvider.notifier)
          .traitsGommes(
            List<TraitVectoriel>.of(_gommesDuGeste),
            surface:
                widget.support.ancrageCadre ?? _gommesDuGeste.first.ancrage,
            portee: etat.portee,
            sessionId: widget.contexte.sessionId,
          );
      _gommesDuGeste.clear();
    }
    final TraitEnCours? enCours = _enCours;
    final String? id = _idEnCours;
    _enCours = null;
    _blocEnCours = null;
    _idEnCours = null;
    _apercu.value = const <PointNormalise>[];
    if (enCours == null || id == null || enCours.nombreDePoints < 2) {
      return;
    }

    // A la fin du trait : version compacte et stable, canal fiable. L'encre
    // reste peinte pendant l'ecriture au depot.
    final TraitVectoriel trait = enCours.terminer(id: id);
    setState(() => _poses.add(trait));
    unawaited(_enregistrer(trait, etat));
  }

  Future<void> _enregistrer(TraitVectoriel trait, EtatOutils etat) async {
    final AnnotationLayer? couche;
    try {
      final PortAnnotations annotations = ref.read(portAnnotationsProvider);
      // TB-7b : la couche du support du trait (son ancrage), meme si la
      // surface a change depuis le debut du geste.
      couche = await annotations.couche(
        resourceId: trait.ancrage.resourceId,
        sessionId: widget.contexte.sessionId,
        portee: etat.portee,
      );
      if (couche != null) {
        await annotations.ajouterTrait(couche.id, trait);
      }
    } on Object {
      _oublier(trait);
      return;
    }
    if (couche == null) {
      // Aucun faux succes : un trait que le depot n'a pas pris ne reste pas
      // peint comme s'il l'avait ete.
      _oublier(trait);
      return;
    }
    // Le depot l'a pris : c'est une operation personnelle validee, que
    // « Annuler » pourra defaire (plan V2 §7).
    if (mounted) {
      ref
          .read(historiquePersonnelProvider.notifier)
          .traitPose(
            trait,
            portee: etat.portee,
            sessionId: widget.contexte.sessionId,
          );
    }
    widget.onEvenement?.call(
      EvenementTraitTermine(
        coucheId: couche.id,
        trait: trait,
        portee: etat.portee,
      ),
    );
  }

  /// Retire de l'ecran un trait que le depot n'a pas pris.
  void _oublier(TraitVectoriel trait) {
    if (!mounted) return;
    setState(() => _poses.remove(trait));
  }

  /// Retire les traits que la gomme traverse.
  ///
  /// La gomme ne laisse aucune trace propre : elle n'est pas un trait blanc,
  /// elle retire des traits. Un trait blanc serait une modification du support
  /// vue de loin. TB-7b : sans [CoucheAnnotation.gommeSurTous], elle ne
  /// retire que les traits de la personne.
  void _gommer(Offset point) {
    final HistoriquePersonnel historique = ref.read(
      historiquePersonnelProvider,
    );
    final ControleurHistorique controleur = ref.read(
      historiquePersonnelProvider.notifier,
    );
    for (final TraitVectoriel trait in _visibles(historique.retires)) {
      if (!widget.gommeSurTous && !historique.mesTraits.contains(trait.id)) {
        continue;
      }
      final List<Offset>? points = resoudreTrait(trait, widget.support.blocs);
      if (points == null) {
        continue;
      }
      if (!passePres(points, point, rayonGomme)) {
        continue;
      }
      controleur.masquer(trait.id);
      _gommesDuGeste.add(trait);
      unawaited(_retirer(trait));
    }
  }

  Future<void> _retirer(TraitVectoriel trait) async {
    final EtatOutils etat = ref.read(etatOutilsProvider);
    final AnnotationLayer? couche;
    try {
      final PortAnnotations annotations = ref.read(portAnnotationsProvider);
      couche = await annotations.couche(
        resourceId: trait.ancrage.resourceId,
        sessionId: widget.contexte.sessionId,
        portee: etat.portee,
      );
      if (couche == null) {
        return;
      }
      await annotations.retirerTrait(couche.id, trait.id);
    } on Object {
      // Le depot n'a pas retire le trait : il revient a l'ecran (aucun faux
      // succes).
      if (mounted) {
        ref.read(historiquePersonnelProvider.notifier).restaurer(trait.id);
      }
      return;
    }
    widget.onEvenement?.call(
      EvenementTraitRetire(coucheId: couche.id, traitId: trait.id),
    );
  }
}

/// L'epaisseur de base d'un trait, et son trace.
abstract final class _Trace {
  /// Epaisseur de base d'un trait de stylet.
  static const double epaisseurStylet = AppSpacing.xs / 2;

  /// TB-7a : sur une page fixe, l'epaisseur de base rapportee a la largeur
  /// de la page (§9) : [epaisseurStylet] sur une page de 400 points de
  /// large, la largeur de lecture d'un telephone. Le meme trait couvre la
  /// meme part de la page a 390, 768 et 1440, et grossit avec le zoom.
  static const double epaisseurRelativePage = epaisseurStylet / 400;

  /// Multiplicateur d'epaisseur du surligneur.
  static const double facteurSurligneur = 4;

  /// Opacite du surligneur : il passe **sous** le texte, il ne le masque pas.
  static const double opaciteSurligneur = 0.32;

  static void tracer(
    Canvas canvas,
    List<Offset> points, {
    required AppPalette palette,
    required OutilTrait outil,
    required IntentionPedagogique intention,
    required double? pression,
    required EpaisseurTrait? epaisseur,
    required double? largeurPage,
  }) {
    if (outil == OutilTrait.gomme || points.length < 2) {
      return;
    }
    final bool surligne = outil == OutilTrait.surligneur;
    final EncreIntention encre = CouleurIntention.encre(palette, intention);
    // La pression, quand le materiel la fournit, epaissit le trait sans jamais
    // le faire disparaitre : un trait a pression nulle reste visible.
    final double facteurPression = pression == null
        ? 1
        : 0.6 + 0.8 * pression.clamp(0, 1);
    final double base = largeurPage == null
        ? epaisseurStylet
        : epaisseurRelativePage * largeurPage;
    final Paint pinceau = Paint()
      ..color = encre.couleur(opacite: surligne ? opaciteSurligneur : 1)
      ..strokeWidth =
          base *
          facteurPression *
          (epaisseur ?? EpaisseurTrait.moyenne).facteur *
          (surligne ? facteurSurligneur : 1)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path chemin = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset point in points.skip(1)) {
      chemin.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(chemin, pinceau);
  }
}

/// Le peintre des traits termines et des marqueurs.
///
/// Il ne peint que ce qui est **ancre dans le rendu courant** : un trait dont
/// le verset n'est pas a l'ecran n'est pas peint ailleurs, il n'est pas peint
/// du tout. TB-7b : il ne repeint pas pendant un trait (le trait en cours a
/// son propre peintre), seulement quand la liste des traits change.
class _PeintreAnnotations extends CustomPainter {
  const _PeintreAnnotations({
    required this.palette,
    required this.support,
    required this.traits,
    required this.marqueurs,
    required this.intentionParDefaut,
    this.largeurPage,
  });

  /// Opacite de la bande d'un marqueur de plage. Plus discrete encore qu'un
  /// surligneur : un marqueur est une note de travail, pas une insistance.
  static const double opaciteMarqueur = 0.18;

  final AppPalette palette;
  final SupportPresente support;
  final List<TraitVectoriel> traits;
  final List<MarqueurSemantique> marqueurs;
  final IntentionPedagogique intentionParDefaut;

  /// La largeur de la page fixe, ou `null` (rendu reflowable : epaisseur
  /// en points d'ecran).
  final double? largeurPage;

  @override
  void paint(Canvas canvas, Size size) {
    CoucheAnnotation.debugPeinturesTraits++;
    // Les marqueurs d'abord : ils passent sous les traits, comme ils passent
    // sous le texte.
    for (final MarqueurSemantique marqueur in marqueurs) {
      final Paint fond = Paint()
        ..color = CouleurIntention.encre(
          palette,
          marqueur.intention,
        ).couleur(opacite: opaciteMarqueur);
      for (final BlocAncre bloc in blocsDansPlage(
        support.blocs,
        marqueur.plage,
      )) {
        canvas.drawRect(bloc.rect, fond);
      }
    }

    for (final TraitVectoriel trait in traits) {
      final List<Offset>? points = resoudreTrait(trait, support.blocs);
      if (points == null) {
        continue;
      }
      _Trace.tracer(
        canvas,
        points,
        palette: palette,
        outil: trait.outil,
        intention: trait.intention ?? intentionParDefaut,
        pression: trait.pression,
        epaisseur: trait.epaisseur,
        largeurPage: largeurPage,
      );
    }
  }

  /// La geometrie a change : sur une page fixe, son cadre et sa page ;
  /// ailleurs, toute nouvelle carte des blocs.
  bool _geometrieChangee(_PeintreAnnotations ancien) => largeurPage == null
      ? !identical(ancien.support, support)
      : ancien.support.blocs.cadre != support.blocs.cadre ||
            ancien.support.ancrageCadre != support.ancrageCadre;

  @override
  bool shouldRepaint(_PeintreAnnotations ancien) =>
      !listEquals(ancien.traits, traits) ||
      !listEquals(ancien.marqueurs, marqueurs) ||
      _geometrieChangee(ancien) ||
      ancien.intentionParDefaut != intentionParDefaut ||
      ancien.largeurPage != largeurPage ||
      ancien.palette != palette;
}

/// Le peintre du trait en cours : repeint a chaque point par [apercu],
/// seul.
class _PeintreApercu extends CustomPainter {
  _PeintreApercu({
    required this.palette,
    required this.apercu,
    required this.bloc,
    required this.outil,
    required this.intention,
    required this.epaisseur,
    required this.largeurPage,
  }) : super(repaint: apercu);

  final AppPalette palette;
  final ValueListenable<List<PointNormalise>> apercu;

  /// Le cadre du bloc du trait en cours, lu au moment de peindre.
  final Rect? Function() bloc;
  final OutilTrait outil;
  final IntentionPedagogique intention;
  final EpaisseurTrait epaisseur;
  final double? largeurPage;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? cadre = bloc();
    final List<PointNormalise> points = apercu.value;
    if (cadre == null || points.length < 2) {
      return;
    }
    _Trace.tracer(
      canvas,
      <Offset>[
        for (final PointNormalise point in points)
          Offset(
            cadre.left + point.x * cadre.width,
            cadre.top + point.y * cadre.height,
          ),
      ],
      palette: palette,
      outil: outil,
      intention: intention,
      pression: null,
      epaisseur: epaisseur,
      largeurPage: largeurPage,
    );
  }

  @override
  bool shouldRepaint(_PeintreApercu ancien) =>
      ancien.apercu != apercu ||
      ancien.outil != outil ||
      ancien.intention != intention ||
      ancien.epaisseur != epaisseur ||
      ancien.largeurPage != largeurPage ||
      ancien.palette != palette;
}
