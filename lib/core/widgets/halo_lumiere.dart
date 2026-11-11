// HALO 2a-bis (pilote, 11/11/2026 ; conditions du garde-cap) : la lumiere du
// halo, extraite de `HaloCompte` pour servir aussi aux ecrans (lots E et H).
//
// Une seule composante du core : la lumiere d'une nature (urgent, salle
// ouverte, a preparer, nouveau), autour d'un cercle ou d'un rectangle arrondi.
// Elle tourne (ou respire, pour la salle) quelques fois, puis reste en lueur
// fixe (WCAG 2.2.2) ; sous mouvement reduit, la lueur fixe d'emblee.
//
// L'arbitre ([ArbitreLumieres]) est le seul mecanisme, de portee d'ecran :
// une seule lumiere tourne a la fois, la plus prioritaire de l'ecran et du
// cercle Compte reunis (rouge > vert > orange > bleu > dore) ; les autres
// restent en lueur fixe. Sans arbitre au-dessus, la lumiere tourne seule.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accessibilite/mode_accessibilite.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Ce qu'une lumiere signale, **par priorite decroissante** : l'ordre de
/// l'enum est celui de l'arbitre (rouge > vert > orange > bleu > dore ; le
/// dore n'a pas encore de nature, aucune couleur n'en est decidee).
enum NatureHalo {
  /// Une alerte urgente encore a faire (rouge).
  urgent,

  /// La salle est ouverte : la personne peut la rejoindre maintenant (vert).
  salle,

  /// Quelque chose est a preparer (orange, 2a-bis du 11/11/2026).
  aPreparer,

  /// Des nouveautes a lire (bleu).
  nouveau;

  /// La lumiere de cette nature (seule exception au branding, 09/11).
  AppHaloColor get couleurs => switch (this) {
    NatureHalo.urgent => CouleursHalo.urgent,
    NatureHalo.salle => CouleursHalo.salle,
    NatureHalo.aPreparer => CouleursHalo.aPreparer,
    NatureHalo.nouveau => CouleursHalo.nouveau,
  };

  /// La duree d'un tour de lumiere (d'une respiration pour la salle).
  Duration get dureeTour => switch (this) {
    NatureHalo.urgent => AppMouvement.tourHaloUrgent,
    NatureHalo.salle => AppMouvement.respirationHalo,
    NatureHalo.aPreparer => AppMouvement.tourHaloAPreparer,
    NatureHalo.nouveau => AppMouvement.tourHaloNouveau,
  };

  /// Le nombre de tours avant la lueur fixe.
  int get tours => switch (this) {
    NatureHalo.urgent => AppMouvement.toursHaloUrgent,
    NatureHalo.salle => AppMouvement.respirationsHalo,
    NatureHalo.aPreparer => AppMouvement.toursHaloAPreparer,
    NatureHalo.nouveau => 1,
  };
}

/// La forme qu'entoure la lumiere.
enum FormeHalo {
  /// Un cercle (le cercle Compte, un avatar).
  cercle,

  /// Un rectangle arrondi (une carte, une tuile).
  rectangle,
}

/// La lumiere d'une [nature] autour d'une forme de [taille] : elle tourne
/// (ou respire) [NatureHalo.tours] fois, puis reste en lueur fixe. Elle ne
/// prend aucune place : elle se pose derriere la forme, dans un `Stack`, et
/// deborde de [portee].
///
/// Purement visuelle : elle ne recoit aucun geste et ne retarde aucun toucher
/// (DECISION-FLUIDITE).
class HaloLumiere extends StatefulWidget {
  /// Cree la lumiere.
  const HaloLumiere({
    required this.nature,
    required this.taille,
    this.forme = FormeHalo.cercle,
    this.arrondi = AppRadius.arrondiMd,
    this.apparition,
    super.key,
  });

  /// La cle de la lumiere qui tourne (tests).
  static const Key lumiereKey = ValueKey<String>('halo-compte-lumiere');

  /// La cle de la lueur fixe (tests).
  static const Key lueurKey = ValueKey<String>('halo-compte-lueur');

  /// Portee de la lumiere au-dela du bord : bornee, elle ne deborde pas sur
  /// le voisin (8 d'ecart).
  static const double portee = 6;

  /// LUMIERE-DOUCE (directeur, 11/11/2026) : autour d'une carte, la forme de
  /// la lumiere ne depasse le bord que de 4...
  static const double porteeCarte = AppSpacing.xs;

  /// ... et son flou (ecart type) reste court : trois ecarts types
  /// depassent encore, a peine visibles.
  static const double flouCarte = 2.5;

  /// La portee totale d'une lumiere de carte, forme et flou ([porteeCarte]
  /// plus trois [flouCarte]) comme lueur fixe (`AppElevation.lueurHaloCarte`) :
  /// au plus 12, dans la gouttiere de 16 de la page. Aucun parent ne doit la
  /// couper ; les tests le mesurent sur les ecrans qui en posent.
  static const double debordementCarte = AppSpacing.md;

  /// Ce que la lumiere signale.
  final NatureHalo nature;

  /// La taille de la forme entouree ; un cercle prend le plus petit cote.
  final Size taille;

  /// La forme entouree.
  final FormeHalo forme;

  /// L'arrondi du rectangle ([FormeHalo.rectangle] seulement).
  final BorderRadius arrondi;

  /// Ce qui fait rejouer la lumiere quand il change (l'ecran affiche). Elle
  /// se rejoue aussi a chaque retour de l'application au premier plan, et a
  /// sa construction.
  final Object? apparition;

  @override
  State<HaloLumiere> createState() => _EtatHaloLumiere();
}

class _EtatHaloLumiere extends State<HaloLumiere>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _tour;
  bool _reduit = false;
  EtatArbitreLumieres? _arbitre;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Retour au premier plan : la personne regarde, la lumiere tourne.
    if (etat == AppLifecycleState.resumed) _rejouer();
  }

  void _rejouer() {
    if (!mounted) return;
    setState(() {
      _arreter();
      _demarrerSiElue();
    });
  }

  bool get _elue => _arbitre?.peutTourner(this) ?? true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EtatArbitreLumieres? arbitre = ArbitreLumieres.de(context);
    if (!identical(arbitre, _arbitre)) {
      _arbitre?._retirer(this);
      _arbitre = arbitre;
      arbitre?._inscrire(this, widget.nature);
    }
    final bool reduit = AppMouvement.mouvementReduit(context);
    if (reduit != _reduit) {
      _reduit = reduit;
      if (reduit) _arreter();
    }
    if (_tour == null) _demarrerSiElue();
  }

  @override
  void didUpdateWidget(HaloLumiere ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.nature != widget.nature) {
      _arbitre?._inscrire(this, widget.nature);
    }
    // Une autre nature, ou un autre ecran qui apparait, rejoue la lumiere
    // (jamais infinie) ; la meme, reconstruite, ne la relance pas.
    if (ancien.nature != widget.nature ||
        ancien.apparition != widget.apparition) {
      _arreter();
      _demarrerSiElue();
    }
  }

  void _demarrerSiElue() {
    if (_reduit || !_elue) return;
    _tour = AnimationController(vsync: this, duration: _dureeTour * _tours)
      ..forward();
  }

  void _arreter() {
    _tour?.dispose();
    _tour = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arbitre?._retirer(this);
    _arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // « Reduire les effets » : aucune lumiere, ni tournante ni fixe.
    if (EffetsReduits.de(context)) return const SizedBox.shrink();
    final bool forte = !AppPalette.of(context).estSombre;
    final AnimationController? tour = _tour;
    // Une lumiere que l'arbitre n'a pas elue reste en lueur fixe, meme si
    // sa rotation avait commence.
    if (tour == null || !_elue) return _lueur(forte);
    return AnimatedBuilder(
      animation: tour,
      builder: (BuildContext _, Widget? _) => tour.isCompleted
          ? _lueur(forte)
          : _Lumiere(
              couleurs: widget.nature.couleurs,
              taille: _taille,
              forme: widget.forme,
              arrondi: widget.arrondi,
              angle: _angle(widget.nature, _tours, tour.value),
              intensite: _intensite(widget.nature, _tours, tour.value),
              forte: forte,
            ),
    );
  }

  bool get _carte => widget.forme == FormeHalo.rectangle;

  /// La duree d'un tour : celle de la nature pour le cercle ; pour une carte,
  /// la meme douceur quelle que soit la nature (la salle garde sa
  /// respiration).
  Duration get _dureeTour => _carte && widget.nature != NatureHalo.salle
      ? AppMouvement.tourHaloCarte
      : widget.nature.dureeTour;

  /// Le nombre de tours, sur la meme regle que [_dureeTour].
  int get _tours => _carte && widget.nature != NatureHalo.salle
      ? AppMouvement.toursHaloCarte
      : widget.nature.tours;

  Size get _taille => widget.forme == FormeHalo.cercle
      ? Size.square(widget.taille.shortestSide)
      : widget.taille;

  Widget _lueur(bool forte) => _Lueur(
    couleurs: widget.nature.couleurs,
    taille: _taille,
    forme: widget.forme,
    arrondi: widget.arrondi,
    forte: forte,
  );

  /// L'angle de la lumiere : lineaire pour l'urgence, un seul tour qui
  /// ralentit pour une nouveaute ; la salle ouverte ne tourne pas.
  static double _angle(NatureHalo nature, int tours, double t) {
    if (nature == NatureHalo.salle) return 0;
    final double avance =
        nature == NatureHalo.nouveau || nature == NatureHalo.aPreparer
        ? AppMouvement.sortie.transform(t)
        : t;
    return avance * tours * 2 * math.pi;
  }

  /// L'intensite de la lumiere : pleine quand elle tourne ; pour la salle
  /// ouverte, une respiration lente (de 0,35 a 1) repetee
  /// [NatureHalo.tours] fois.
  static double _intensite(NatureHalo nature, int tours, double t) {
    if (nature != NatureHalo.salle) return 1;
    final double souffle = (1 - math.cos(2 * math.pi * tours * t)) / 2;
    return 0.35 + 0.65 * souffle;
  }
}

/// La lumiere qui tourne : un balayage circulaire flou autour de la forme.
class _Lumiere extends StatelessWidget {
  const _Lumiere({
    required this.couleurs,
    required this.taille,
    required this.forme,
    required this.arrondi,
    required this.angle,
    required this.intensite,
    required this.forte,
  });

  final AppHaloColor couleurs;
  final Size taille;
  final FormeHalo forme;
  final BorderRadius arrondi;
  final double angle;
  final double intensite;
  final bool forte;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      key: HaloLumiere.lumiereKey,
      size: taille,
      painter: _PeintreLumiere(
        couleurs: couleurs,
        forme: forme,
        arrondi: arrondi,
        angle: angle,
        intensite: intensite,
        forte: forte,
      ),
    ),
  );
}

class _PeintreLumiere extends CustomPainter {
  const _PeintreLumiere({
    required this.couleurs,
    required this.forme,
    required this.arrondi,
    required this.angle,
    required this.intensite,
    required this.forte,
  });

  final AppHaloColor couleurs;
  final FormeHalo forme;
  final BorderRadius arrondi;
  final double angle;
  final double intensite;
  final bool forte;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    switch (forme) {
      case FormeHalo.cercle:
        final double rayon = size.shortestSide / 2 + HaloLumiere.portee;
        final Rect zone = Rect.fromCircle(center: centre, radius: rayon);
        final Paint pinceau = _pinceau(zone);
        canvas.drawCircle(centre, rayon, pinceau);
        // En clair, la lumiere se voit moins : une seconde couche la renforce.
        if (forte) canvas.drawCircle(centre, rayon, pinceau);
      case FormeHalo.rectangle:
        // LUMIERE-DOUCE : une carte a sa propre portee, courte, et une
        // opacite basse, en une seule couche dans les deux themes.
        final RRect forme = arrondi
            .toRRect(Offset.zero & size)
            .inflate(HaloLumiere.porteeCarte);
        // Le balayage tourne autour du centre, sur le cercle qui contient
        // tout le rectangle.
        final Rect zone = Rect.fromCircle(
          center: centre,
          radius: size.longestSide / 2 + HaloLumiere.porteeCarte,
        );
        canvas.drawRRect(
          forme,
          couleurs.pinceau(
              zone,
              angle: angle,
              intensite: intensite * CouleursHalo.intensiteCarte,
            )
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              HaloLumiere.flouCarte,
            ),
        );
    }
  }

  Paint _pinceau(Rect zone) =>
      couleurs.pinceau(zone, angle: angle, intensite: intensite)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSpacing.xs);

  @override
  bool shouldRepaint(_PeintreLumiere ancien) =>
      ancien.angle != angle ||
      ancien.intensite != intensite ||
      ancien.couleurs != couleurs ||
      ancien.forme != forme ||
      ancien.arrondi != arrondi ||
      ancien.forte != forte;
}

/// La lueur fixe, apres la rotation, sous mouvement reduit, ou quand une
/// autre lumiere de l'ecran tourne.
class _Lueur extends StatelessWidget {
  const _Lueur({
    required this.couleurs,
    required this.taille,
    required this.forme,
    required this.arrondi,
    required this.forte,
  });

  final AppHaloColor couleurs;
  final Size taille;
  final FormeHalo forme;
  final BorderRadius arrondi;
  final bool forte;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      key: HaloLumiere.lueurKey,
      decoration: switch (forme) {
        FormeHalo.cercle => BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppElevation.lueurHalo(couleurs.lueur, forte: forte),
        ),
        FormeHalo.rectangle => BoxDecoration(
          borderRadius: arrondi,
          boxShadow: AppElevation.lueurHaloCarte(couleurs.lueur),
        ),
      },
      child: SizedBox.fromSize(size: taille),
    ),
  );
}

/// L'arbitre des lumieres d'un ecran : **un seul mecanisme**, pose une fois
/// par le core (la coquille `NavShell`), jamais recopie ecran par ecran.
///
/// Chaque [HaloLumiere] dessous s'y inscrit avec sa nature ; une seule tourne
/// (la plus prioritaire, la premiere inscrite a priorite egale), les autres
/// restent en lueur fixe. Quand l'elue s'en va, la suivante tourne a son tour.
class ArbitreLumieres extends StatefulWidget {
  /// Cree l'arbitre.
  const ArbitreLumieres({required this.child, super.key});

  /// L'ecran.
  final Widget child;

  /// L'arbitre de l'ecran, ou `null` : la lumiere tourne alors seule.
  static EtatArbitreLumieres? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PorteeArbitre>()?.notifier;

  @override
  State<ArbitreLumieres> createState() => _EtatArbitre();
}

class _EtatArbitre extends State<ArbitreLumieres> {
  final EtatArbitreLumieres _etat = EtatArbitreLumieres._();

  @override
  void dispose() {
    _etat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PorteeArbitre(notifier: _etat, child: widget.child);
}

/// Les lumieres inscrites aupres d'un [ArbitreLumieres].
class EtatArbitreLumieres extends ChangeNotifier {
  EtatArbitreLumieres._();

  // L'ordre d'inscription departage deux lumieres de meme nature.
  final Map<Object, NatureHalo> _inscrites = <Object, NatureHalo>{};
  bool _annonce = false;
  bool _fini = false;

  /// Vrai quand [jeton] est la lumiere qui tourne.
  bool peutTourner(Object jeton) => identical(_elue, jeton);

  Object? get _elue {
    Object? elue;
    NatureHalo? meilleure;
    for (final MapEntry<Object, NatureHalo> e in _inscrites.entries) {
      if (meilleure == null || e.value.index < meilleure.index) {
        elue = e.key;
        meilleure = e.value;
      }
    }
    return elue;
  }

  /// Le nombre de lumieres inscrites (tests).
  @visibleForTesting
  int get inscrites => _inscrites.length;

  void _inscrire(Object jeton, NatureHalo nature) {
    if (_inscrites[jeton] == nature) return;
    _inscrites.remove(jeton);
    _inscrites[jeton] = nature;
    _annoncer();
  }

  void _retirer(Object jeton) {
    if (_inscrites.remove(jeton) != null) _annoncer();
  }

  // Une inscription arrive pendant une construction : l'annonce attend la fin
  // de l'image.
  void _annoncer() {
    if (_annonce || _fini) return;
    _annonce = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _annonce = false;
      if (!_fini) notifyListeners();
    });
  }

  @override
  void dispose() {
    _fini = true;
    super.dispose();
  }
}

class _PorteeArbitre extends InheritedNotifier<EtatArbitreLumieres> {
  const _PorteeArbitre({required super.notifier, required super.child});
}
