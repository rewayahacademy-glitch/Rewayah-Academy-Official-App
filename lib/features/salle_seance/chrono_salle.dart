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
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import 'marque_chrono.dart';
import 'pilote_dynamique.dart' show heureDeLaBarre, pauseALInstant;
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
    this.marques = const <MarqueChrono>[],
    this.deplie = true,
    this.onBasculer,
    this.libelleBasculer,
    this.signes = const <Widget>[],
    super.key,
  });

  /// DYNAMIQUE-CHRONO-1 : les marques posees par la salle (presence,
  /// recitation) ; la pause y est ajoutee ici, d'apres l'instant.
  final List<MarqueChrono> marques;

  /// DYNAMIQUE-CHRONO-1 (directeur, 12/11/2026) : faux, la ligne repliee
  /// (l'anneau, « Reste 37:51 », les marques en points de couleur, lues) ;
  /// vrai, chaque marque en clair, puis la commande de la pause et son echec.
  /// Hors de la Dynamique chrono (anciens en-tetes), tout reste visible.
  final bool deplie;

  /// Un toucher de la ligne du chrono deplie ou replie la Dynamique chrono ;
  /// `null` : la ligne ne se touche pas (salle reduite : l'appelant porte
  /// son propre geste).
  final VoidCallback? onBasculer;

  /// Ce que lit le lecteur d'ecran du toucher [onBasculer].
  final String? libelleBasculer;

  /// Des signes courts poses au bout de la ligne (le micro ouvert), une
  /// icone et son libelle lu : jamais la couleur seule.
  final List<Widget> signes;

  /// La cle de la ligne du chrono (tests de geometrie).
  static const Key cleLigne = ValueKey<String>('chrono-salle-ligne');

  /// La cle du toucher qui deplie ou replie (tests).
  static const Key cleBasculer = ValueKey<String>('chrono-salle-basculer');

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
    // DYNAMIQUE-CHRONO-2 : passee l'heure de reprise, la pause ne fige plus
    // le chrono, meme si le message de fin n'est pas encore arrive.
    final PauseSeance? p = pauseALInstant(widget.pause, _instant);
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
  static String _heure(DateTime utc) => heureDeLaBarre(utc);

  /// La marque de la pause a cet instant, ou `null` (DYNAMIQUE-CHRONO-1 : la
  /// pause est une marque de la barre, son texte n'est plus pose a cote).
  MarqueChrono? _marquePause(ChronoSeance chrono) {
    final PauseSeance? p = pauseALInstant(widget.pause, _instant);
    // DYNAMIQUE-CHRONO-2 : une marque de pause posee par la barre (« Pause
    // proposee ») tient lieu de celle-ci.
    if (p == null ||
        chrono.prevuEcoule ||
        widget.marques.any((MarqueChrono m) => m.estPause)) {
      return null;
    }
    final d = t.salle.seance.pause;
    MarqueChrono marque(
      GenreMarqueChrono genre,
      String texte,
      String annonce,
    ) => MarqueChrono.pause(genre: genre, libelle: texte, annonce: annonce);
    switch (p.statut) {
      case StatutPause.nonPrevue:
      case StatutPause.nonPrise:
        return null;
      case StatutPause.programmee when p.motif == MotifPause.priere:
        // DYNAMIQUE-CHRONO-2 : la pause de priere s'annonce d'avance, a son
        // heure (celle que le serveur propose, sinon l'heure prevue).
        final DateTime? heure = p.proposerAUtc ?? p.debutPrevuUtc;
        final String texte = heure == null
            ? t.salle.dynamique.priereNom
            : t.salle.dynamique.priereA(heure: _heure(heure));
        return marque(GenreMarqueChrono.pauseProgrammee, texte, texte);
      case StatutPause.programmee:
        final DateTime? prevue = p.debutPrevuUtc;
        if (prevue == null || !prevue.isAfter(_instant)) {
          return marque(GenreMarqueChrono.pauseProgrammee, d.prevue, d.prevue);
        }
        final int minutes =
            (prevue.difference(_instant).inSeconds / Duration.secondsPerMinute)
                .ceil();
        return marque(
          GenreMarqueChrono.pauseProgrammee,
          LibellesGroupe.insecable(d.dans(minutes: minutes)),
          LibellesGroupe.insecable(d.annonceDans(minutes: minutes)),
        );
      case StatutPause.enCours:
        final DateTime? reprise = p.repriseUtc;
        if (reprise == null) {
          return marque(GenreMarqueChrono.pauseEnCours, d.prevue, d.prevue);
        }
        // DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026) : « Pause, reprise
        // dans 7 min » ; l'heure exacte est dite a l'alerte et lue ici.
        final int reste =
            (reprise.difference(_instant).inSeconds / Duration.secondsPerMinute)
                .ceil()
                .clamp(1, p.dureePrevueMinutes);
        return marque(
          GenreMarqueChrono.pauseEnCours,
          LibellesGroupe.insecable(d.enCoursDans(minutes: reste)),
          d.annonceEnCours(heure: _heure(reprise)),
        );
      case StatutPause.prise:
        return marque(GenreMarqueChrono.pausePrise, d.prise, d.prise);
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
    final MarqueChrono? pause = _marquePause(chrono);
    final VoidCallback? commande = widget.onPause;
    // Un widget lit une capacite, jamais un role : la commande n'existe que si
    // le serveur l'a donnee (`peutPiloter`) et que l'appelant la fournit.
    final bool commander =
        commande != null &&
        p != null &&
        p.peutPiloter &&
        !chrono.prevuEcoule &&
        (p.statut == StatutPause.programmee || p.statut == StatutPause.enCours);
    final Widget vivant = ChronoVivant(
      key: ChronoSalle.cleAnnonce,
      chrono: chrono,
      annonce: annonce,
      libelleFini: d.chrono.tempsPrevuEcoule,
      libelleReste: d.chrono.reste,
      libelleApresFin: d.chrono.apresFin,
      libellePause: d.chrono.pause,
      uneLigne: true,
      surface: widget.surfaceCapsule,
      sobre: widget.sobre,
      dansUnePilule: widget.dansUnePilule,
      onEtat: _changerEtat,
    );
    final List<MarqueChrono> marques = <MarqueChrono>[
      ...widget.marques,
      ?pause,
    ];
    final AppPalette palette = AppPalette.of(context);
    // Le point d'une marque : 8 points, la couleur de son ton ; le mot est lu
    // (repliee) ou ecrit a cote (depliee).
    Widget point(MarqueChrono m) => SizedBox.square(
      dimension: StatusPill.diametrePastille,
      child: DecoratedBox(decoration: palette.pastilleDe(m.ton)),
    );
    Widget lue(MarqueChrono m, Widget enfant) => Semantics(
      key: m.estPause ? ChronoSalle.cleAnnoncePause : null,
      container: true,
      liveRegion: m.estPause,
      label: m.annonce,
      child: ExcludeSemantics(child: enfant),
    );
    final bool deplie = widget.deplie;
    // La ligne : l'anneau, « Reste 37:51 », puis (repliee) les marques en
    // points et les signes. Toujours UNE ligne : sans place, elle se reduit
    // d'un bloc au lieu de passer a la ligne ou de deborder.
    Widget ligne = FittedBox(
      key: ChronoSalle.cleLigne,
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          vivant,
          if (!deplie)
            for (final MarqueChrono m in marques) ...<Widget>[
              Ecart.hSm,
              lue(m, point(m)),
            ],
          for (final Widget signe in widget.signes) ...<Widget>[
            Ecart.hSm,
            signe,
          ],
        ],
      ),
    );
    final VoidCallback? basculer = widget.onBasculer;
    if (basculer != null) {
      // La cible fait 48 de haut au moins ; le toucher couvre toute la ligne.
      ligne = Stack(
        alignment: AlignmentDirectional.centerStart,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.titreEcran),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: ligne,
            ),
          ),
          Positioned.fill(
            child: Pressable(
              key: ChronoSalle.cleBasculer,
              onPress: basculer,
              libelleSemantique: widget.libelleBasculer,
              respecterCibleTactile: false,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
    }
    if (!deplie) {
      return ligne;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: <Widget>[
        ligne,
        // Chaque marque en clair : son point ET son mot.
        for (final MarqueChrono m in marques)
          lue(
            m,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                point(m),
                Ecart.hSm,
                Flexible(
                  child: Text(
                    m.libelle,
                    key: m.estPause ? ChronoSalle.clePause : null,
                    style: style,
                  ),
                ),
              ],
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
