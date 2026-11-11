// GESTES-POINTEUR (directeur, 11/11/2026, cahier de la salle §8) : « le
// pointeur est trop discret, et il arrive en retard chez l'eleve. Attendu :
// quasi instantane, tres visible, avec un sillage qui s'efface presque
// aussitot. »
//
// Deux pieces, employees par `SurfacePageFixe` :
//
//   * [CadencePointeur] : ce qui part a la classe. Une position par image au
//     plus (30 par seconde), **la derniere position d'un geste part
//     toujours**, un battement redit la position tant que le doigt reste
//     pose, et le lever part aussitot ;
//   * [PointeurSalle] : ce qui se voit. Un point a fort contraste (anneau
//     clair, coeur de la couleur de marque), un sillage qui s'efface en
//     [AppMouvement.pointeurSillage], et chez qui recoit un rattrapage court
//     entre deux positions. « Reduire les animations » : le point seul.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// La cadence d'envoi du pointeur de l'enseignant.
///
/// **Pourquoi il arrivait en retard** (lu dans le code, defaut P-1) : une
/// position toutes les 50 ms au plus, et toute position tombee dans cet
/// intervalle etait jetee, **y compris la derniere** : le point de l'eleve
/// s'arretait avant celui de l'enseignant et n'y arrivait jamais. Rien ne
/// lissait le mouvement, donc vingt sauts par seconde.
///
/// Ici, la fenetre ne jette rien : elle garde la position la plus recente et
/// l'envoie a sa fermeture. Aucune file : une seule position attend, la
/// derniere.
class CadencePointeur {
  /// Cree la cadence au-dessus de [envoyer] (`null` : le pointeur se leve).
  CadencePointeur({
    required this._envoyer,
    this.intervalle = AppMouvement.pointeurCadence,
    this.battement = AppMouvement.pointeurBattement,
  });

  final void Function(Offset? point) _envoyer;

  /// L'intervalle minimal entre deux positions.
  final Duration intervalle;

  /// Le rythme auquel une position immobile est redite.
  final Duration battement;

  Timer? _fenetre;
  Timer? _battement;
  Offset? _enAttente;
  Offset? _dernier;

  /// Vrai tant qu'un point est montre a la classe.
  bool get montre => _dernier != null;

  /// L'enseignant montre [point] (repere de la page, de 0 a 1).
  void montrer(Offset point) {
    _dernier = point;
    if (_fenetre != null) {
      // La fenetre est ouverte : seule la position la plus recente attend.
      _enAttente = point;
      return;
    }
    _partir(point);
  }

  void _partir(Offset point) {
    _enAttente = null;
    _envoyer(point);
    _fenetre = Timer(intervalle, _fermerFenetre);
    _battement?.cancel();
    _battement = Timer.periodic(battement, (Timer _) {
      final Offset? pose = _dernier;
      if (pose != null && _fenetre == null) _partir(pose);
    });
  }

  void _fermerFenetre() {
    _fenetre = null;
    final Offset? attendu = _enAttente;
    if (attendu != null) _partir(attendu);
  }

  /// L'enseignant cesse de pointer : le lever part aussitot.
  void lever() {
    if (_dernier == null) return;
    _arreter();
    _envoyer(null);
  }

  void _arreter() {
    _fenetre?.cancel();
    _battement?.cancel();
    _fenetre = null;
    _battement = null;
    _enAttente = null;
    _dernier = null;
  }

  /// Libere les minuteries ; un pointeur encore montre est leve.
  void liberer() => lever();
}

/// Le pointeur tel qu'il se voit sur la page : un point tres visible et son
/// sillage. [source] porte le point dans le repere de la boite (de 0 a 1),
/// ou `null` quand rien n'est montre.
class PointeurSalle extends StatefulWidget {
  /// Cree le pointeur.
  const PointeurSalle({
    super.key,
    required this.source,
    this.clePoint,
    this.rattrapage = true,
  });

  /// Le point montre, en proportion de la boite, ou `null`.
  final ValueListenable<Offset?> source;

  /// La cle posee sur le point (tests et semantique des ecrans).
  final Key? clePoint;

  /// Vrai chez qui recoit : le point affiche rejoint la position recue en
  /// [AppMouvement.pointeurLissage] au lieu de sauter. Faux chez
  /// l'enseignant : son point reste sous son doigt.
  final bool rattrapage;

  /// La cle du sillage, present seulement tant qu'il y a une trace a peindre.
  static const Key cleSillage = ValueKey<String>('pointeur-sillage');

  /// Le diametre du point (anneau compris).
  static const double diametre = AppSpacing.xxxl;

  /// Le diametre du coeur de couleur.
  static const double diametreCoeur = AppSpacing.lg;

  @override
  State<PointeurSalle> createState() => _PointeurSalleState();
}

/// Un point du sillage : ou, et quand (temps du `Ticker`).
@immutable
class _Trace {
  const _Trace(this.point, this.instant);
  final Offset point;
  final Duration instant;
}

class _PointeurSalleState extends State<PointeurSalle>
    with SingleTickerProviderStateMixin {
  late final Ticker _horloge = createTicker(_battre);

  /// Le point affiche (repere de 0 a 1), ou `null`.
  Offset? _affiche;

  /// Le sillage, du plus ancien au plus recent.
  final List<_Trace> _sillage = <_Trace>[];

  /// La derniere position entree dans le sillage.
  Offset? _derniereTrace;

  Duration _maintenant = Duration.zero;
  Duration _precedent = Duration.zero;

  bool get _reduit => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    widget.source.addListener(_recevoir);
    _affiche = widget.source.value;
  }

  @override
  void didUpdateWidget(PointeurSalle ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.source != widget.source) {
      ancien.source.removeListener(_recevoir);
      widget.source.addListener(_recevoir);
      _recevoir();
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_recevoir);
    _horloge.dispose();
    super.dispose();
  }

  void _recevoir() {
    if (!mounted) return;
    final Offset? cible = widget.source.value;
    if (_reduit) {
      // Mouvement reduit : le point seul, a sa place, sans sillage.
      if (_horloge.isActive) _horloge.stop();
      _sillage.clear();
      _derniereTrace = null;
      setState(() => _affiche = cible);
      return;
    }
    if (cible == null) {
      // Le point disparait aussitot ; le sillage finit de s'effacer.
      setState(() => _affiche = null);
    } else if (_affiche == null || !widget.rattrapage) {
      // Il apparait ou on le pose : jamais de glissade depuis ailleurs.
      setState(() => _affiche = cible);
    }
    if (!_horloge.isActive) {
      _precedent = _maintenant = Duration.zero;
      _sillage.clear();
      _derniereTrace = null;
      unawaited(_horloge.start());
    }
  }

  void _battre(Duration ecoule) {
    final Duration pas = ecoule - _precedent;
    _precedent = _maintenant = ecoule;
    final Offset? cible = widget.source.value;
    Offset? affiche = _affiche;
    if (cible != null && affiche != null && widget.rattrapage) {
      // Rattrapage exponentiel : a chaque image, le point franchit une part
      // de l'ecart qui ne depend que du temps ecoule.
      final double part =
          1 -
          math.exp(
            -pas.inMicroseconds /
                AppMouvement.pointeurLissage.inMicroseconds.toDouble(),
          );
      affiche = Offset.lerp(affiche, cible, part.clamp(0, 1));
      if (affiche != null && (affiche - cible).distanceSquared < _seuil) {
        affiche = cible;
      }
    } else if (cible != null) {
      affiche = cible;
    }
    final Duration limite = ecoule - AppMouvement.pointeurSillage;
    _sillage.removeWhere((_Trace t) => t.instant < limite);
    if (affiche == null) {
      _derniereTrace = null;
    } else if (affiche != _derniereTrace) {
      _sillage.add(_Trace(affiche, ecoule));
      _derniereTrace = affiche;
    }
    // Plus rien ne bouge et le sillage est efface : l'horloge s'arrete, le
    // point reste (ou a deja disparu).
    if ((cible == null || affiche == cible) && _sillage.isEmpty) {
      _horloge.stop();
    }
    setState(() => _affiche = affiche);
  }

  /// En dessous de cet ecart (repere de 0 a 1, au carre), le point est
  /// arrive : il ne tremble pas autour de sa cible.
  static const double _seuil = 1e-8;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Offset? point = _affiche;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_sillage.length > 1 && !_reduit)
              CustomPaint(
                key: PointeurSalle.cleSillage,
                painter: _PeintreSillage(
                  traces: List<_Trace>.of(_sillage),
                  maintenant: _maintenant,
                  encre: palette.surfacePrimary,
                ),
              ),
            if (point != null)
              // Le CENTRE du point est sur la position montree, chez
              // l'enseignant comme chez l'eleve (l'ancien pointeur recu etait
              // aligne en fraction : il derivait d'un demi-diametre vers les
              // bords). Un point de la page, geometrique comme les traits,
              // pas un cote de lecture : le meme en arabe.
              Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: Offset(point.dx * c.maxWidth, point.dy * c.maxHeight),
                  width: PointeurSalle.diametre,
                  height: PointeurSalle.diametre,
                ),
                child: _Point(key: widget.clePoint, palette: palette),
              ),
          ],
        ),
      ),
    );
  }
}

/// Le point : un anneau clair cerne de la couleur de marque, et un coeur de
/// la couleur de marque. Clair sur une page sombre, colore sur une page
/// claire : il se lit dans les deux themes.
class _Point extends StatelessWidget {
  const _Point({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: PointeurSalle.diametre,
    child: CustomPaint(painter: _PeintrePoint(palette.surfacePrimary)),
  );
}

class _PeintrePoint extends CustomPainter {
  const _PeintrePoint(this.paire);

  final AppColorPair paire;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double rayon = size.shortestSide / 2;
    // Le cerne de couleur : il detache l'anneau clair d'une page claire.
    canvas
      ..drawCircle(centre, rayon, Paint()..color = paire.background)
      // L'anneau clair : il detache le coeur d'une page sombre.
      ..drawCircle(centre, rayon - _cerne, Paint()..color = paire.onBackground)
      ..drawCircle(
        centre,
        PointeurSalle.diametreCoeur / 2,
        Paint()..color = paire.background,
      );
  }

  /// L'epaisseur du cerne exterieur.
  static const double _cerne = 2;

  @override
  bool shouldRepaint(_PeintrePoint ancien) => ancien.paire != paire;
}

class _PeintreSillage extends CustomPainter {
  const _PeintreSillage({
    required this.traces,
    required this.maintenant,
    required this.encre,
  });

  final List<_Trace> traces;
  final Duration maintenant;
  final AppColorPair encre;

  @override
  void paint(Canvas canvas, Size size) {
    final double duree = AppMouvement.pointeurSillage.inMicroseconds.toDouble();
    for (int i = 1; i < traces.length; i++) {
      final _Trace a = traces[i - 1];
      final _Trace b = traces[i];
      final double age = (maintenant - b.instant).inMicroseconds / duree;
      final double vie = (1 - age).clamp(0.0, 1.0);
      if (vie <= 0) continue;
      canvas.drawLine(
        Offset(a.point.dx * size.width, a.point.dy * size.height),
        Offset(b.point.dx * size.width, b.point.dy * size.height),
        Paint()
          ..color = encre.background.withValues(alpha: vie * _opaciteSillage)
          ..strokeWidth = PointeurSalle.diametreCoeur * (0.4 + 0.6 * vie)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// L'opacite du sillage a sa naissance.
  static const double _opaciteSillage = 0.55;

  @override
  bool shouldRepaint(_PeintreSillage ancien) =>
      ancien.maintenant != maintenant || ancien.traces.length != traces.length;
}
