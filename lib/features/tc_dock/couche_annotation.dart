import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_outils/ancrage_annotation.dart';
import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/compaction_trait.dart';
import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/evenements_outils.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/tc_outils/port_dock_hote.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Qui a le droit d'ecrire, et qui garde la navigation.
///
/// **Stylet = encre, doigt = pan et zoom** (spec section 8.4). La regle n'est
/// tenable telle quelle que sur un appareil qui a un stylet : sur un telephone,
/// l'appliquer a la lettre rendrait l'annotation impossible. La politique
/// ci-dessous garde donc la regle **des qu'un stylet s'est manifeste**, et
/// n'ouvre le doigt a l'ecriture que sur un appareil qui n'en a pas, et
/// seulement quand l'outil Stylet a ete explicitement arme dans le dock.
///
/// Consequence voulue : sur une tablette avec stylet, poser la main ou faire
/// glisser le texte ne dessine jamais.
abstract final class PolitiqueSaisie {
  /// Les appareils qui posent de l'encre, dans ce contexte.
  ///
  /// **Le stylet ecrit toujours**, y compris avant que l'outil ne soit arme :
  /// c'est la regle de la spec, et c'est aussi ce que la main attend d'un
  /// stylet. Le doigt, lui, n'ecrit que sur un appareil ou aucun stylet ne
  /// s'est jamais manifeste, et seulement quand l'outil Stylet a ete arme dans
  /// le dock -- sans quoi l'annotation serait impossible sur un telephone.
  static Set<PointerDeviceKind> appareilsDeDessin({
    required bool styletDetecte,
    required bool styletArme,
  }) {
    if (!styletDetecte && styletArme) {
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
  });

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
  List<PointNormalise> _apercu = const <PointNormalise>[];
  final Set<String> _effaces = <String>{};

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final EtatOutils etat = ref.watch(etatOutilsProvider);
    final Set<PointerDeviceKind> appareils = PolitiqueSaisie.appareilsDeDessin(
      styletDetecte: _styletDetecte,
      styletArme: etat.styletArme,
    );

    return Listener(
      // Le guetteur est passif : il ne consomme rien, il apprend seulement
      // qu'un stylet existe sur cet appareil. Des lors, le doigt redevient la
      // navigation, definitivement.
      onPointerDown: _guetterStylet,
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
        child: CustomPaint(
          painter: _PeintreAnnotations(
            palette: palette,
            support: widget.support,
            traits: <TraitVectoriel>[
              for (final TraitVectoriel trait in widget.traits)
                if (!_effaces.contains(trait.id)) trait,
            ],
            marqueurs: widget.marqueurs,
            apercu: _apercu,
            blocApercu: _blocEnCours,
            outilApercu: etat.outilTrait,
            intentionApercu: etat.intention,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  void _guetterStylet(PointerDownEvent evenement) {
    if (_styletDetecte) {
      return;
    }
    if (evenement.kind == PointerDeviceKind.stylus ||
        evenement.kind == PointerDeviceKind.invertedStylus) {
      setState(() => _styletDetecte = true);
    }
  }

  void _commencer(Offset point, EtatOutils etat) {
    if (etat.outilTrait == OutilTrait.gomme) {
      _gommer(point);
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
    )..ajouter(normaliserDans(cadre, point));
    setState(() => _apercu = <PointNormalise>[normaliserDans(cadre, point)]);
  }

  void _prolonger(Offset point, EtatOutils etat) {
    if (etat.outilTrait == OutilTrait.gomme) {
      _gommer(point);
      return;
    }
    final TraitEnCours? trait = _enCours;
    final Rect? bloc = _blocEnCours;
    if (trait == null || bloc == null) {
      return;
    }
    final PointNormalise normalise = normaliserDans(bloc, point);
    trait.ajouter(normalise);
    setState(() => _apercu = <PointNormalise>[..._apercu, normalise]);

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
    final TraitEnCours? enCours = _enCours;
    final String? id = _idEnCours;
    _enCours = null;
    _blocEnCours = null;
    _idEnCours = null;
    setState(() => _apercu = const <PointNormalise>[]);
    if (enCours == null || id == null || enCours.nombreDePoints < 2) {
      return;
    }

    // A la fin du trait : version compacte et stable, canal fiable.
    final TraitVectoriel trait = enCours.terminer(id: id);
    unawaited(_enregistrer(trait, etat));
  }

  Future<void> _enregistrer(TraitVectoriel trait, EtatOutils etat) async {
    final PortAnnotations annotations = ref.read(portAnnotationsProvider);
    final AnnotationLayer? couche = await annotations.couche(
      resourceId: widget.support.resourceId,
      sessionId: widget.contexte.sessionId,
      portee: etat.portee,
    );
    if (couche == null) {
      return;
    }
    await annotations.ajouterTrait(couche.id, trait);
    widget.onEvenement?.call(
      EvenementTraitTermine(
        coucheId: couche.id,
        trait: trait,
        portee: etat.portee,
      ),
    );
  }

  /// Retire les traits que la gomme traverse.
  ///
  /// La gomme ne laisse aucune trace propre : elle n'est pas un trait blanc,
  /// elle retire des traits. Un trait blanc serait une modification du support
  /// vue de loin.
  void _gommer(Offset point) {
    for (final TraitVectoriel trait in widget.traits) {
      if (_effaces.contains(trait.id)) {
        continue;
      }
      final List<Offset>? points = resoudreTrait(trait, widget.support.blocs);
      if (points == null) {
        continue;
      }
      if (!passePres(points, point, rayonGomme)) {
        continue;
      }
      setState(() => _effaces.add(trait.id));
      unawaited(_retirer(trait.id));
    }
  }

  Future<void> _retirer(String traitId) async {
    final PortAnnotations annotations = ref.read(portAnnotationsProvider);
    final EtatOutils etat = ref.read(etatOutilsProvider);
    final AnnotationLayer? couche = await annotations.couche(
      resourceId: widget.support.resourceId,
      sessionId: widget.contexte.sessionId,
      portee: etat.portee,
    );
    if (couche == null) {
      return;
    }
    await annotations.retirerTrait(couche.id, traitId);
    widget.onEvenement?.call(
      EvenementTraitRetire(coucheId: couche.id, traitId: traitId),
    );
  }
}

/// Le peintre de la couche.
///
/// Il ne peint que ce qui est **ancre dans le rendu courant** : un trait dont
/// le verset n'est pas a l'ecran n'est pas peint ailleurs, il n'est pas peint
/// du tout.
class _PeintreAnnotations extends CustomPainter {
  const _PeintreAnnotations({
    required this.palette,
    required this.support,
    required this.traits,
    required this.marqueurs,
    required this.apercu,
    required this.outilApercu,
    required this.intentionApercu,
    this.blocApercu,
  });

  /// Epaisseur de base d'un trait de stylet.
  static const double epaisseurStylet = AppSpacing.xs / 2;

  /// Multiplicateur d'epaisseur du surligneur.
  static const double facteurSurligneur = 4;

  /// Opacite du surligneur : il passe **sous** le texte, il ne le masque pas.
  static const double opaciteSurligneur = 0.32;

  /// Opacite de la bande d'un marqueur de plage. Plus discrete encore qu'un
  /// surligneur : un marqueur est une note de travail, pas une insistance.
  static const double opaciteMarqueur = 0.18;

  final AppPalette palette;
  final SupportPresente support;
  final List<TraitVectoriel> traits;
  final List<MarqueurSemantique> marqueurs;
  final List<PointNormalise> apercu;
  final Rect? blocApercu;
  final OutilTrait outilApercu;
  final IntentionPedagogique intentionApercu;

  @override
  void paint(Canvas canvas, Size size) {
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
      if (points == null || points.length < 2) {
        continue;
      }
      _tracer(
        canvas,
        points,
        outil: trait.outil,
        intention: trait.intention ?? intentionApercu,
        pression: trait.pression,
      );
    }

    final Rect? bloc = blocApercu;
    if (bloc == null || apercu.length < 2) {
      return;
    }
    _tracer(
      canvas,
      <Offset>[
        for (final PointNormalise point in apercu)
          Offset(
            bloc.left + point.x * bloc.width,
            bloc.top + point.y * bloc.height,
          ),
      ],
      outil: outilApercu,
      intention: intentionApercu,
      pression: null,
    );
  }

  void _tracer(
    Canvas canvas,
    List<Offset> points, {
    required OutilTrait outil,
    required IntentionPedagogique intention,
    required double? pression,
  }) {
    if (outil == OutilTrait.gomme) {
      return;
    }
    final bool surligne = outil == OutilTrait.surligneur;
    final EncreIntention encre = CouleurIntention.encre(palette, intention);
    // La pression, quand le materiel la fournit, epaissit le trait sans jamais
    // le faire disparaitre : un trait a pression nulle reste visible.
    final double facteurPression = pression == null
        ? 1
        : 0.6 + 0.8 * pression.clamp(0, 1);
    final Paint pinceau = Paint()
      ..color = encre.couleur(opacite: surligne ? opaciteSurligneur : 1)
      ..strokeWidth =
          epaisseurStylet *
          facteurPression *
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

  @override
  bool shouldRepaint(_PeintreAnnotations ancien) =>
      ancien.traits != traits ||
      ancien.marqueurs != marqueurs ||
      ancien.apercu != apercu ||
      ancien.blocApercu != blocApercu ||
      ancien.support != support ||
      ancien.outilApercu != outilApercu ||
      ancien.intentionApercu != intentionApercu ||
      ancien.palette != palette;
}
