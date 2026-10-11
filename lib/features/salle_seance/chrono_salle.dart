// LIVE-CHRONO-01 : le chrono discret de la salle de classe.
//
// Une ligne compacte dans l'en-tete : « 00:12:34 ecoule · 00:32:26 restant ».
// Il sert seulement a connaitre la duree de la seance. Il n'est jamais
// presente comme une preuve de presence, ne court pas apres un record et ne
// donne jamais un temps negatif : apres la fin prevue, il dit « Temps prevu
// ecoule ».
//
// Aucun compteur qui derive : a chaque tic, au retour d'arriere-plan et au
// retablissement de la connexion, le temps est RECALCULE depuis les deux
// horodatages UTC de la seance et l'horloge courante. Le minuteur ne sert qu'a
// redessiner, jamais a compter.
//
// Lecteur d'ecran : le texte visible est exclu de la semantique ; un seul noeud
// annonce la duree EN MINUTES, donc une annonce par minute et non par seconde.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/chrono_seance.dart';
import '../../core/theme/app_palette.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import 'vue_seance.dart' show ConnexionSeance;

/// L'instant courant UTC du chrono : l'horloge serveur lue une fois a
/// l'ouverture, avancee du temps ecoule sur l'appareil, ou l'horloge de
/// l'appareil quand aucune horloge serveur ne repond. Les tests la
/// remplacent par une horloge factice.
final Provider<DateTime Function()> horlogeChronoProvider =
    Provider<DateTime Function()>((Ref ref) {
      final DateTime? ancre = ref.watch(ancreServeurProvider).value;
      if (ancre == null) {
        return () => DateTime.now().toUtc();
      }
      final DateTime appareilALAncre = DateTime.now();
      return () => ancre.add(DateTime.now().difference(appareilALAncre));
    });

/// Le chrono de la salle, pour les [bornes] d'une seance.
class ChronoSalle extends StatefulWidget {
  /// Cree le chrono.
  const ChronoSalle({
    required this.bornes,
    required this.style,
    this.connexion = ConnexionSeance.enLigne,
    super.key,
  });

  /// Le style du texte (celui de la ligne d'etat voisine).
  final TextStyle style;

  /// T0 et la fin prevue, en UTC.
  final BornesChrono bornes;

  /// La connexion de la salle : un retablissement force un recalcul.
  final ConnexionSeance connexion;

  /// La cle du texte visible.
  static const Key cleTexte = ValueKey<String>('chrono-salle-texte');

  /// La cle du noeud lu par le lecteur d'ecran.
  static const Key cleAnnonce = ValueKey<String>('chrono-salle-annonce');

  @override
  State<ChronoSalle> createState() => _ChronoSalleEtat();
}

class _ChronoSalleEtat extends State<ChronoSalle> with WidgetsBindingObserver {
  Timer? _minuteur;
  ChronoSeance? _chrono;

  /// L'horloge du chrono : celle du conteneur de providers s'il y en a un,
  /// l'horloge de l'appareil sinon.
  DateTime Function() _horloge() {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(horlogeChronoProvider);
    } on Object {
      // Hors ProviderScope (planche, test d'en-tete seul) : l'appareil.
      return () => DateTime.now().toUtc();
    }
  }

  DateTime _maintenant() => _horloge()().toUtc();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chrono = ChronoSeance.a(widget.bornes, DateTime.now().toUtc());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recalculer();
  }

  @override
  void didUpdateWidget(ChronoSalle ancien) {
    super.didUpdateWidget(ancien);
    final bool retablie = !ancien.connexion.etablie && widget.connexion.etablie;
    if (ancien.bornes != widget.bornes || retablie) {
      _recalculer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Retour d'arriere-plan : le minuteur a pu dormir longtemps, le temps se
    // relit depuis les horodatages.
    if (etat == AppLifecycleState.resumed) {
      _recalculer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minuteur?.cancel();
    super.dispose();
  }

  void _recalculer() {
    final ChronoSeance suivant = ChronoSeance.a(widget.bornes, _maintenant());
    if (suivant != _chrono) {
      setState(() => _chrono = suivant);
    }
    _planifier();
  }

  /// Prochain tic au passage de la seconde suivante de l'horloge : le minuteur
  /// ne cumule rien, il se recale a chaque tour.
  void _planifier() {
    _minuteur?.cancel();
    if (_chrono?.prevuEcoule ?? false) {
      return;
    }
    final int micro = _maintenant().microsecondsSinceEpoch;
    final int reste =
        Duration.microsecondsPerSecond - micro % Duration.microsecondsPerSecond;
    _minuteur = Timer(Duration(microseconds: reste), () {
      if (mounted) {
        _recalculer();
      }
    });
  }

  /// Les chiffres restent de gauche a droite, aussi en arabe.
  static String _chiffres(Duration duree) =>
      '\u2066${formaterChrono(duree)}\u2069';

  @override
  Widget build(BuildContext context) {
    final ChronoSeance chrono = _chrono!;
    if (!chrono.visible) {
      return const SizedBox.shrink();
    }
    final d = t.salle.seance;
    final String texte = chrono.prevuEcoule
        ? d.chrono.tempsPrevuEcoule
        : d.ligne(
            debut: d.chrono.ecoule(temps: _chiffres(chrono.ecoule)),
            fin: d.chrono.restant(temps: _chiffres(chrono.restant)),
          );
    final String annonce = chrono.prevuEcoule
        ? d.chrono.annoncePrevuEcoule
        : d.chrono.annonce(
            ecoule: chrono.minutesEcoulees,
            restant: chrono.minutesRestantes,
          );
    return Semantics(
      key: ChronoSalle.cleAnnonce,
      container: true,
      liveRegion: true,
      label: annonce,
      child: ExcludeSemantics(
        child: Text(
          texte,
          key: ChronoSalle.cleTexte,
          style: AppPalette.of(context).inkMuted.applyTo(
            widget.style.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
