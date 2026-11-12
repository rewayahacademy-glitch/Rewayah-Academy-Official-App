// Le chrono de la salle de classe.
//
// CHRONO-ETAT (directeur, 10 et 11/11/2026, `docs/current/CAHIER-SALLE.md` §8),
// qui remplace la ligne de LIVE-CHRONO-01 (« 00:12:34 ecoule · 00:32:26
// restant », trop bavarde) : une capsule qui ne montre que ce qui reste
// (`ChronoVivant`, lib/core/widgets), qui change de teinte a cinq minutes de
// la fin, puis compte le depassement en croissant tant que le depassement
// regle par la direction n'est pas epuise. Il sert a conduire la seance. Il
// n'est jamais presente comme une preuve de presence.
//
// Aucun compteur qui derive : a chaque tic, au retour d'arriere-plan et au
// retablissement de la connexion, le temps est RECALCULE depuis les deux
// horodatages UTC de la seance et l'horloge courante. Le minuteur ne sert qu'a
// redessiner, jamais a compter.
//
// Lecteur d'ecran : les chiffres sont exclus de la semantique ; un seul noeud
// annonce la duree EN MINUTES, donc une annonce par minute et non par seconde.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/chrono_seance.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/signal_rappel.dart';
import '../../core/widgets/chrono_vivant.dart';
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
    this.echecPause,
    this.garderCouleur = false,
    this.surfaceCapsule,
    this.sobre = false,
    this.dansUnePilule = false,
    this.sonne = false,
    this.onEtat,
    super.key,
  });

  /// Le chrono loge dans la pilule d'etat : voir [ChronoVivant.dansUnePilule].
  final bool dansUnePilule;

  /// Le chrono sonne (deux notes douces) cinq minutes avant la fin et a la
  /// fin prevue : chez qui conduit la seance seulement.
  final bool sonne;

  /// Sans teinte d'urgence (qui ne conduit pas la seance) : voir
  /// [ChronoVivant.sobre].
  final bool sobre;

  /// La paire de la capsule au calme ; `null` : la surface relevee du theme.
  final AppColorPair? surfaceCapsule;

  /// Appele quand le chrono change d'etat (cinq minutes avant la fin, fin
  /// prevue, depassement epuise) : la salle y branche le signal sonore de qui
  /// dirige la seance. Jamais appele a l'ouverture.
  final ValueChanged<EtatChronoVivant>? onEtat;

  /// FN-023 : dans la pilule d'etat, le chrono garde l'encre de la pilule
  /// (couche sombre du telephone, pilule translucide) au lieu de l'encre
  /// discrete de l'en-tete, pour garder son contraste.
  final bool garderCouleur;

  /// LIVE-PAUSE-01 : la pause programmee de la seance, ou `null`.
  final PauseSeance? pause;

  /// Demarre ou termine la pause ; `null` sans capacite (rien n'est rendu).
  final VoidCallback? onPause;

  /// N3, S2 : le dernier « Demarrer / Terminer la pause » n'est pas confirme
  /// par le serveur (K-59) ; la phrase dit quoi faire. `null` : rien a dire.
  final String? echecPause;

  /// Le style du texte (celui de la ligne d'etat voisine).
  final TextStyle style;

  /// T0 et la fin prevue, en UTC.
  final BornesChrono bornes;

  /// La connexion de la salle : un retablissement force un recalcul.
  final ConnexionSeance connexion;

  /// La cle des chiffres visibles (ceux de la capsule).
  static const Key cleTexte = ChronoVivant.cleChiffres;

  /// La cle du noeud lu par le lecteur d'ecran.
  static const Key cleAnnonce = ValueKey<String>('chrono-salle-annonce');

  /// La cle du texte de pause.
  static const Key clePause = ValueKey<String>('chrono-salle-pause');

  /// La cle de la phrase « pause non confirmee » (N3).
  static const Key cleEchecPause = ValueKey<String>('chrono-salle-echec-pause');

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

  bool _finSonnee = false;

  /// Le chrono vient de changer d'etat : le signal sonore de qui conduit la
  /// seance (la fin approche, la fin prevue est atteinte), puis l'appelant.
  void _changerEtat(EtatChronoVivant etat) {
    // La fin prevue ne sonne qu'une fois : avec un depassement autorise,
    // l'etat passe par « depassement » puis « fini » ; sans, il va droit a
    // « fini ».
    final bool fin =
        etat == EtatChronoVivant.depassement || etat == EtatChronoVivant.fini;
    final bool aSignaler =
        etat == EtatChronoVivant.bientot || (fin && !_finSonnee);
    if (fin) _finSonnee = true;
    if (widget.sonne && aSignaler) {
      try {
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(signalChronoProvider)();
      } on Object {
        // Hors ProviderScope (planche, test d'en-tete seul) : aucun son.
      }
    }
    widget.onEtat?.call(etat);
  }

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

  /// L'heure du profil ([chezMoi], sinon celle de l'appareil), `HH:MM`, en
  /// chiffres de gauche a droite.
  static String _heure(DateTime utc) => '\u2066${heureChezMoi(utc)}\u2069';

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
    final String annonce = chrono.prevuEcoule
        ? d.chrono.annoncePrevuEcoule
        : chrono.enDepassement
        ? LibellesGroupe.insecable(
            d.chrono.annonceDepassement(minutes: chrono.depasse.inMinutes),
          )
        : LibellesGroupe.insecable(
            // Pluriel slang (« 1 min restante », « 2 min restantes ») : une
            // annonce par minute.
            d.chrono.minutesRestantes(minutes: chrono.minutesRestantes),
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
    final Widget ligneChrono = ChronoVivant(
      key: ChronoSalle.cleAnnonce,
      chrono: chrono,
      annonce: annonce,
      libelleFini: d.chrono.tempsPrevuEcoule,
      surface: widget.surfaceCapsule,
      sobre: widget.sobre,
      dansUnePilule: widget.dansUnePilule,
      onEtat: _changerEtat,
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
        if (widget.echecPause != null)
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              widget.echecPause!,
              key: ChronoSalle.cleEchecPause,
              style: style,
            ),
          ),
      ],
    );
  }
}
