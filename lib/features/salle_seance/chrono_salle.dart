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
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/chrono_seance.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
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
    this.pause,
    this.onPause,
    this.garderCouleur = false,
    super.key,
  });

  /// FN-023 : dans la pilule d'etat, le chrono garde l'encre de la pilule
  /// (couche sombre du telephone, pilule translucide) au lieu de l'encre
  /// discrete de l'en-tete, pour garder son contraste.
  final bool garderCouleur;

  /// LIVE-PAUSE-01 : la pause programmee de la seance, ou `null`.
  final PauseSeance? pause;

  /// Demarre ou termine la pause ; `null` sans capacite (rien n'est rendu).
  final VoidCallback? onPause;

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

  /// La cle du texte de pause.
  static const Key clePause = ValueKey<String>('chrono-salle-pause');

  /// La cle du noeud de pause lu par le lecteur d'ecran.
  static const Key cleAnnoncePause = ValueKey<String>(
    'chrono-salle-annonce-pause',
  );

  /// La cle de la commande « Demarrer la pause » / « Terminer la pause ».
  static const Key cleCommandePause = ValueKey<String>(
    'chrono-salle-commande-pause',
  );

  @override
  State<ChronoSalle> createState() => _ChronoSalleEtat();
}

class _ChronoSalleEtat extends State<ChronoSalle> with WidgetsBindingObserver {
  Timer? _minuteur;
  ChronoSeance? _chrono;
  DateTime _instant = DateTime.now().toUtc();

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
    if (ancien.bornes != widget.bornes ||
        ancien.pause != widget.pause ||
        retablie) {
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

  /// Les pauses du chrono, d'apres l'etat servi : en cours ou prise.
  List<PauseChrono> _pauses() {
    final PauseSeance? p = widget.pause;
    final DateTime? debut = p?.debutUtc;
    if (p == null || debut == null) {
      return const <PauseChrono>[];
    }
    return switch (p.statut) {
      StatutPause.enCours => <PauseChrono>[PauseChrono(debutUtc: debut)],
      StatutPause.prise when p.finUtc != null => <PauseChrono>[
        PauseChrono(debutUtc: debut, finUtc: p.finUtc),
      ],
      _ => const <PauseChrono>[],
    };
  }

  void _recalculer() {
    _instant = _maintenant();
    final ChronoSeance suivant = ChronoSeance.a(
      widget.bornes,
      _instant,
      pauses: _pauses(),
    );
    if (suivant != _chrono) {
      setState(() => _chrono = suivant);
    } else {
      // La pause se lit sur l'instant : elle peut changer sans que le chrono
      // change (« Pause dans 5 min » devient « dans 4 min »).
      setState(() {});
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

  /// L'heure locale de l'appareil, `HH:MM`, en chiffres de gauche a droite.
  static String _heure(DateTime utc) {
    final DateTime l = utc.toLocal();
    String deux(int n) => n.toString().padLeft(2, '0');
    return '\u2066${deux(l.hour)}:${deux(l.minute)}\u2069';
  }

  /// Ce que la pause dit a cet instant, ou `null` : le texte visible et sa
  /// version lue.
  ({String texte, String annonce})? _direPause(ChronoSeance chrono) {
    final PauseSeance? p = widget.pause;
    if (p == null || chrono.prevuEcoule) {
      return null;
    }
    final d = t.salle.seance.pause;
    switch (p.statut) {
      case StatutPause.nonPrevue:
      case StatutPause.nonPrise:
        return null;
      case StatutPause.programmee:
        final DateTime? prevue = p.debutPrevuUtc;
        if (prevue == null || !prevue.isAfter(_instant)) {
          return (texte: d.prevue, annonce: d.prevue);
        }
        final int minutes =
            (prevue.difference(_instant).inSeconds / Duration.secondsPerMinute)
                .ceil();
        return (
          texte: LibellesGroupe.insecable(d.dans(minutes: minutes)),
          annonce: LibellesGroupe.insecable(d.annonceDans(minutes: minutes)),
        );
      case StatutPause.enCours:
        final DateTime? reprise = p.repriseUtc;
        if (reprise == null) {
          return (texte: d.prevue, annonce: d.prevue);
        }
        return (
          texte: d.enCours(heure: _heure(reprise)),
          annonce: d.annonceEnCours(heure: _heure(reprise)),
        );
      case StatutPause.prise:
        return (texte: d.prise, annonce: d.prise);
    }
  }

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
        : LibellesGroupe.insecable(
            // Pluriel slang (« 1 min restante », « 2 min restantes ») :
            // l'annonce est lue a chaque seance depuis FN-023.
            d.chrono.annonce(
              ecoule: d.chrono.minutesEcoulees(minutes: chrono.minutesEcoulees),
              restant: d.chrono.minutesRestantes(
                minutes: chrono.minutesRestantes,
              ),
            ),
          );
    final TextStyle chiffres = widget.style.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final TextStyle style = widget.garderCouleur
        ? chiffres
        : AppPalette.of(context).inkMuted.applyTo(chiffres);
    final PauseSeance? p = widget.pause;
    final ({String texte, String annonce})? pause = _direPause(chrono);
    final VoidCallback? commande = widget.onPause;
    // Un widget lit une capacite, jamais un role : la commande n'existe que si
    // le serveur l'a donnee (`peutPiloter`) et que l'appelant la fournit.
    final bool commander =
        commande != null &&
        p != null &&
        p.peutPiloter &&
        !chrono.prevuEcoule &&
        (p.statut == StatutPause.programmee || p.statut == StatutPause.enCours);
    final Widget ligneChrono = Semantics(
      key: ChronoSalle.cleAnnonce,
      container: true,
      liveRegion: true,
      label: annonce,
      child: ExcludeSemantics(
        child: Text(texte, key: ChronoSalle.cleTexte, style: style),
      ),
    );
    if (pause == null && !commander) {
      return ligneChrono;
    }
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ligneChrono,
        if (pause != null)
          Semantics(
            key: ChronoSalle.cleAnnoncePause,
            container: true,
            liveRegion: true,
            label: pause.annonce,
            child: ExcludeSemantics(
              child: Text(pause.texte, key: ChronoSalle.clePause, style: style),
            ),
          ),
        if (commander)
          LienFleche(
            key: ChronoSalle.cleCommandePause,
            libelle: p.statut == StatutPause.enCours
                ? d.pause.terminer
                : d.pause.demarrer,
            onPress: commande,
            fleche: false,
          ),
      ],
    );
  }
}
