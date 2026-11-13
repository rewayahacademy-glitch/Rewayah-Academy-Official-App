// DYNAMIQUE-CHRONO-2 (directeur, 12/11/2026, retours sur la salle, points 5,
// 6, 14 et 15 ; `docs/current/salle/PLAN-RETOURS-2026-11-12.md`) : ce que la
// Dynamique chrono dit, et quand.
//
// - [PiloteDynamique] tient la file des alertes passageres (une a la fois),
//   leur repli seul, et les marques qu'elles laissent. Il ne dessine rien :
//   la barre ([DynamiqueChrono]) l'ecoute. Le temps des alertes se compte en
//   battements ([avancer]), jamais a l'horloge murale : il reste juste dans
//   les tests comme sur l'appareil.
// - [SuiviArrivees] dit qui vient d'entrer, sans compter ceux qui etaient deja
//   la quand on est entre soi-meme.
// - [PilotePause] porte la pause proposee (Oui / Non, rappel, pause de priere,
//   fin a l'heure) et dit a tous quand elle commence et quand elle finit. Il
//   lit l'heure du serveur ([maintenant]) et n'agit que par les commandes du
//   port ([CommandesPause]) : aucun droit n'est decide ici.
//
// Partage par la salle (`salle_page.dart`) et par la salle reduite
// (`BarreSeanceEnDirect`) : la logique n'est ecrite qu'une fois.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/video/publication_differee.dart' show roleQuiConduit;
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import 'marque_chrono.dart';

/// L'heure du profil ([heureChezMoi]), `HH:MM`, en chiffres de gauche a
/// droite meme dans une phrase arabe.
String heureDeLaBarre(DateTime utc) => '\u2066${heureChezMoi(utc)}\u2069';

/// La pause telle qu'on la montre a [maintenant] : une pause en cours dont
/// l'heure de reprise est passee ne se dit plus « Pause », meme si le
/// message de fin n'est pas encore arrive (elle se lit prise, finie a la
/// reprise). Le serveur reste la verite ; seul l'affichage suit l'heure.
PauseSeance? pauseALInstant(PauseSeance? pause, DateTime maintenant) {
  final DateTime? reprise = pause?.repriseUtc;
  if (pause == null || reprise == null || maintenant.isBefore(reprise)) {
    return pause;
  }
  return PauseSeance(
    statut: StatutPause.prise,
    dureePrevueMinutes: pause.dureePrevueMinutes,
    debutPrevuUtc: pause.debutPrevuUtc,
    debutUtc: pause.debutUtc,
    finUtc: reprise,
    peutPiloter: pause.peutPiloter,
    refusNombre: pause.refusNombre,
    motif: pause.motif,
  );
}

/// Une marque laissee, et quand elle part.
class _Trace {
  _Trace(this.marque, this.fin, this.rouvrir);

  final MarqueChrono marque;

  /// Le battement ou elle part ; `null` : quand l'emetteur la retire.
  final Duration? fin;

  /// L'alerte qu'un toucher de la barre rouvre, ou `null`.
  final AlerteChrono? rouvrir;
}

/// La file des alertes et les marques de la Dynamique chrono.
class PiloteDynamique extends ChangeNotifier {
  /// Cree le pilote. Rien ne bat tant que [demarrer] n'est pas appele (les
  /// tests appellent [avancer]).
  PiloteDynamique();

  final List<AlerteChrono> _file = <AlerteChrono>[];
  AlerteChrono? _courante;
  Duration _ecoule = Duration.zero;
  Duration _finCourante = Duration.zero;
  final Map<String, _Trace> _traces = <String, _Trace>{};
  final List<VoidCallback> _auToucher = <VoidCallback>[];
  final List<VoidCallback> _aChaqueBattement = <VoidCallback>[];
  Timer? _battement;
  bool _libere = false;
  int _numero = 0;

  /// Un numero neuf : une alerte reposee porte un nouvel identifiant.
  int get numero => ++_numero;

  /// L'alerte montree, ou `null`.
  AlerteChrono? get alerte => _courante;

  /// Les marques laissees, dans l'ordre ou elles sont arrivees.
  List<MarqueChrono> get marques => <MarqueChrono>[
    for (final _Trace t in _traces.values) t.marque,
  ];

  /// Vrai si une marque de cle [cle] est posee.
  bool aMarque(String cle) => _traces.containsKey(cle);

  /// Vrai si l'alerte [id] est montree ou attend son tour.
  bool attend(String id) =>
      _courante?.id == id || _file.any((AlerteChrono a) => a.id == id);

  /// Vrai si une alerte dont l'identifiant commence par [prefixe] est
  /// montree ou attend son tour (une alerte rouverte d'un toucher garde le
  /// debut de son identifiant).
  bool attendFamille(String prefixe) =>
      (_courante?.id.startsWith(prefixe) ?? false) ||
      _file.any((AlerteChrono a) => a.id.startsWith(prefixe));

  /// Bat toutes les [AppMouvement.battementDynamique] : les alertes partent,
  /// les marques s'effacent, et les ecouteurs ([aChaqueBattement]) relisent
  /// l'heure.
  void demarrer() {
    _battement ??= Timer.periodic(
      AppMouvement.battementDynamique,
      (Timer _) => avancer(AppMouvement.battementDynamique),
    );
  }

  /// Appele a chaque battement, apres le repli des alertes (la pause relit
  /// l'heure du serveur).
  void aChaqueBattement(VoidCallback ecouteur) =>
      _aChaqueBattement.add(ecouteur);

  /// Appele a chaque toucher de la barre (couper la sonnerie, effacer la
  /// marque de l'appel recu).
  void auToucher(VoidCallback ecouteur) => _auToucher.add(ecouteur);

  /// Pose [alerte] : montree tout de suite si la barre est libre, sinon a la
  /// suite. Une alerte de la meme famille ([AlerteChrono.groupe]) remplace
  /// celle qui est montree et repart pour son temps entier. Une alerte deja
  /// montree ou en attente (meme [AlerteChrono.id]) ne se rejoue pas.
  void annoncer(AlerteChrono alerte) {
    if (_libere) return;
    final String? groupe = alerte.groupe;
    if (groupe != null && _courante?.groupe == groupe) {
      _montrer(alerte);
      notifyListeners();
      return;
    }
    if (attend(alerte.id)) return;
    if (groupe != null) {
      _file.removeWhere((AlerteChrono a) => a.groupe == groupe);
    }
    if (_courante == null) {
      _montrer(alerte);
    } else {
      _file.add(alerte);
    }
    notifyListeners();
  }

  void _montrer(AlerteChrono alerte) {
    _courante = alerte;
    _finCourante = _ecoule + (alerte.duree ?? AppMouvement.alerteChrono);
  }

  /// Repli de l'alerte montree ; [trace] : elle laisse sa marque.
  void _finir({required bool trace}) {
    final AlerteChrono? a = _courante;
    if (a == null) return;
    _courante = null;
    final MarqueChrono? marque = a.trace;
    if (trace && marque != null) {
      _poserTrace(
        a.cleTrace ?? a.id,
        marque,
        duree: a.dureeTrace,
        rouvrir: a.rouvrable ? a : null,
      );
    }
    if (_file.isNotEmpty) _montrer(_file.removeAt(0));
  }

  /// L'alerte [id] part maintenant et laisse sa marque (son temps est fini,
  /// ou la personne a touche la barre).
  void fermer(String id) {
    if (_courante?.id == id) {
      _finir(trace: true);
    } else {
      _file.removeWhere((AlerteChrono a) => a.id == id);
    }
    notifyListeners();
  }

  /// Une action de l'alerte [id] est choisie : elle part sans marque (la
  /// suite dit ce qui se passe).
  void choisir(String id) {
    if (_courante?.id == id) {
      _finir(trace: false);
    } else {
      _file.removeWhere((AlerteChrono a) => a.id == id);
    }
    notifyListeners();
  }

  /// Retire l'alerte [id] sans marque, montree ou en attente.
  void retirer(String id) => choisir(id);

  void _poserTrace(
    String cle,
    MarqueChrono marque, {
    Duration? duree,
    AlerteChrono? rouvrir,
  }) {
    _traces.remove(cle);
    _traces[cle] = _Trace(
      marque,
      duree == null ? null : _ecoule + duree,
      rouvrir,
    );
  }

  /// Pose (ou remplace) la marque [cle], pour [duree] ou jusqu'a [oublier].
  void marquer(String cle, MarqueChrono marque, {Duration? duree}) {
    if (_libere) return;
    final _Trace? avant = _traces[cle];
    if (avant != null && avant.marque == marque && duree == null) return;
    _poserTrace(cle, marque, duree: duree);
    notifyListeners();
  }

  /// Retire la marque [cle].
  void oublier(String cle) {
    if (_traces.remove(cle) != null && !_libere) notifyListeners();
  }

  /// Le temps passe de [duree] : l'alerte montree part a son heure (et
  /// laisse sa marque), les marques datees s'effacent.
  void avancer(Duration duree) {
    if (_libere) return;
    _ecoule += duree;
    bool change = false;
    if (_courante != null && _ecoule >= _finCourante) {
      _finir(trace: true);
      change = true;
    }
    final int avant = _traces.length;
    _traces.removeWhere(
      (String _, _Trace t) => t.fin != null && _ecoule >= t.fin!,
    );
    if (_traces.length != avant) change = true;
    if (change) notifyListeners();
    for (final VoidCallback ecouteur in List<VoidCallback>.of(
      _aChaqueBattement,
    )) {
      ecouteur();
    }
  }

  /// La personne touche la barre. Les ecouteurs ([auToucher]) d'abord ;
  /// puis une alerte montree part (elle laisse sa marque) ; sinon, une
  /// marque qui rouvre son alerte (la pause proposee) la rouvre. Vrai quand
  /// le toucher a servi : la barre ne se deplie pas en plus.
  bool toucher() {
    if (_libere) return false;
    for (final VoidCallback ecouteur in List<VoidCallback>.of(_auToucher)) {
      ecouteur();
    }
    final AlerteChrono? montree = _courante;
    if (montree != null) {
      fermer(montree.id);
      return true;
    }
    for (final MapEntry<String, _Trace> e
        in _traces.entries.toList().reversed) {
      final AlerteChrono? a = e.value.rouvrir;
      if (a == null) continue;
      _traces.remove(e.key);
      annoncer(
        AlerteChrono(
          id: '${a.id}-r$numero',
          titre: a.titre,
          detail: a.detail,
          compte: a.compte,
          actions: a.actions,
          duree: a.duree,
          trace: a.trace,
          cleTrace: a.cleTrace ?? a.id,
          dureeTrace: a.dureeTrace,
          rouvrable: true,
          groupe: a.groupe,
        ),
      );
      return true;
    }
    return false;
  }

  @override
  void notifyListeners() {
    if (!_libere) super.notifyListeners();
  }

  @override
  void dispose() {
    _libere = true;
    _battement?.cancel();
    _auToucher.clear();
    _aChaqueBattement.clear();
    super.dispose();
  }
}

/// Les arrivees dans la salle, pour qui conduit la seance.
///
/// La premiere liste ou l'on se voit soi-meme fixe ceux qui etaient deja la :
/// aucune alerte pour eux. Ensuite, chaque personne qui n'etait pas dans la
/// liste precedente (hors soi et hors qui conduit) est une arrivee ; une
/// personne qui part puis revient arrive de nouveau.
class SuiviArrivees {
  Set<String>? _vus;

  /// Les participants qui viennent d'entrer, dans l'ordre de la liste.
  List<ParticipantSalle> observer(List<ParticipantSalle> liste) {
    final bool moiDedans = liste.any((ParticipantSalle p) => p.estLocal);
    final Set<String> presents = <String>{
      for (final ParticipantSalle p in liste)
        if (!p.estLocal && p.role != roleQuiConduit) p.identite,
    };
    final Set<String>? avant = _vus;
    if (avant == null) {
      if (moiDedans) _vus = presents;
      return const <ParticipantSalle>[];
    }
    _vus = presents;
    return <ParticipantSalle>[
      for (final ParticipantSalle p in liste)
        if (!p.estLocal &&
            p.role != roleQuiConduit &&
            !avant.contains(p.identite))
          p,
    ];
  }
}

/// La famille des alertes d'arrivee : elles se regroupent (+1, +2).
const String groupeArrivees = 'arrivees';

/// DYNAMIQUE-CHRONO-2, point 5 : « les arrivees d'eleves (+1, +2... animees) ».
/// Le nombre roule tant que l'alerte est montree ; le prenom n'est dit que
/// pour une seule arrivee. Aucun son.
void annoncerArrivees(PiloteDynamique pilote, List<String> prenoms) {
  if (prenoms.isEmpty) return;
  final AlerteChrono? montree = pilote.alerte;
  final int deja = montree?.groupe == groupeArrivees
      ? (montree?.compte ?? 0)
      : 0;
  final int n = deja + prenoms.length;
  final String? prenom = n == 1 && prenoms.single.isNotEmpty
      ? prenoms.single
      : null;
  final d = t.salle.dynamique;
  pilote.annoncer(
    AlerteChrono(
      id: '$groupeArrivees-${pilote.numero}',
      groupe: groupeArrivees,
      compte: n,
      titre: prenom == null
          ? d.arrivees(n: n)
          : d.arriveePrenom(prenom: prenom),
      duree: AppMouvement.alerteArrivees,
      trace: MarqueChrono.evenement(
        libelle: prenom == null
            ? d.arriveesMarque(n: n)
            : d.arriveeMarquePrenom(prenom: prenom),
        ton: TonEtat.succes,
      ),
      cleTrace: groupeArrivees,
      dureeTrace: AppMouvement.marqueArrivee,
    ),
  );
}

/// Ce que la pause demande au serveur, par le port de la salle. Chaque
/// commande se termine en erreur si le serveur ne l'a pas confirmee ; la
/// salle dit alors l'echec en une phrase (`salle.seance.pause.echec`).
abstract interface class CommandesPause {
  /// « Oui », « Commencer maintenant », ou la pause de priere a son heure.
  Future<void> demarrer();

  /// La pause finit a l'heure de reprise.
  Future<void> terminer();

  /// « Non », ou « Decaler de 5 min » pour la pause de priere.
  Future<void> refuser();
}

/// DYNAMIQUE-CHRONO-2, point 14 (directeur, 12/11/2026) : « la barre du
/// chrono propose a l'enseignant de prendre une pause de 10 min ; il accepte
/// par un simple OUI ou refuse par NON ; s'il accepte, tous les participants
/// recoivent l'alerte sur leur barre, et l'heure exacte de reprise ; s'il
/// refuse, le systeme le lui rappelle apres quelques minutes, car la pause
/// est un droit. »
///
/// - Chez qui pilote la pause (capacite `peutPiloter`, lue du serveur) : a
///   `proposerA`, l'alerte « Pause de 10 min ? » (Oui / Non) reste depliee
///   [AppMouvement.propositionPause] ; sans reponse, elle laisse la marque
///   « Pause proposee » (un toucher la rouvre) et revient apres
///   [rappelSansReponse], sans rien envoyer au serveur (ne pas repondre
///   n'est pas refuser). Oui demarre, Non refuse (le serveur rend la
///   prochaine `proposerA`, nulle quand il n'y a plus de proposition).
/// - La pause de priere (motif fourni par le serveur) n'a pas de Oui / Non :
///   [avancePriere] avant son heure, « Commencer maintenant » ou « Decaler de
///   5 min » ; a l'heure, elle demarre seule.
/// - A l'heure de reprise, la pause se termine seule (une fois ; un echec se
///   reessaie au battement suivant).
/// - Chez tous : « Pause de 10 min. Reprise a 20:45 » quand elle commence,
///   « La pause est finie » quand elle finit (ou quand l'heure de reprise
///   est passee).
/// - Serveur d'avant PAUSE-SERVEUR : `proposerA` est nul, aucune proposition.
class PilotePause {
  /// Cree le pilote de la pause.
  PilotePause({
    required this.dynamique,
    required this.maintenant,
    this.commandes,
  });

  /// La barre qui montre les alertes.
  final PiloteDynamique dynamique;

  /// L'heure du serveur (celle du chrono), en UTC.
  final DateTime Function() maintenant;

  /// Les commandes du port ; `null` : rien n'est jamais envoye (eleve).
  final CommandesPause? commandes;

  /// Le delai avant de reposer une proposition restee sans reponse. Le port
  /// ne rend pas le reglage de la direction (`seance.pause_rappel_minutes`,
  /// 5 par defaut), qui ne vaut que pour le rappel apres un Non, pose par le
  /// serveur : on garde ici la meme valeur par defaut.
  static const Duration rappelSansReponse = Duration(minutes: 5);

  /// La pause de priere s'annonce a l'enseignant ce temps avant son heure.
  static const Duration avancePriere = Duration(minutes: 3);

  /// Le report demande par « Decaler » : le rappel de la direction
  /// (`seance.pause_rappel_minutes`, 5 par defaut), pose par le serveur.
  static const int minutesDecalage = 5;

  /// La cle de la marque « Pause proposee ».
  static const String cleProposee = 'pause-proposee';

  PauseSeance? _pause;
  bool _pilote = false;
  StatutPause? _statutVu;
  DateTime? _debutVu;
  bool _premiere = true;

  DateTime? _proposeePour;
  String? _idProposition;
  DateTime? _rappelA;
  DateTime? _refuseePour;
  bool _enVol = false;
  DateTime? _priereAnnonceePour;
  DateTime? _priereDemarreePour;
  DateTime? _termineePour;
  bool _terminerEnVol = false;

  /// Relit [pause] (servie au pilote, relayee aux autres). [pilote] : la
  /// capacite `peutPiloter` du serveur, jamais un role.
  void observer(PauseSeance? pause, {required bool pilote}) {
    _pause = pause;
    _pilote = pilote && commandes != null;
    evaluer();
  }

  /// Relit l'heure : a appeler a chaque battement.
  void evaluer() {
    final DateTime now = maintenant();
    _annoncerChangements(pauseALInstant(_pause, now));
    if (_pilote) _piloter(now);
  }

  void _annoncerChangements(PauseSeance? vue) {
    final StatutPause? statut = vue?.statut;
    final bool premiere = _premiere;
    _premiere = false;
    final StatutPause? avant = _statutVu;
    _statutVu = statut;
    final d = t.salle.dynamique;
    if (statut == StatutPause.enCours &&
        avant != StatutPause.enCours &&
        vue != null) {
      _debutVu = vue.debutUtc;
      dynamique
        ..oublier(cleProposee)
        ..retirer(_idProposition ?? '');
      final DateTime? reprise = vue.repriseUtc;
      if (reprise == null) return;
      final String heure = heureDeLaBarre(reprise);
      dynamique.annoncer(
        AlerteChrono(
          id: 'pause-debut-${vue.debutUtc?.millisecondsSinceEpoch}',
          titre: LibellesGroupe.insecable(
            vue.motif == MotifPause.priere
                ? d.pausePriereDebut(heure: heure)
                : d.pauseDebut(minutes: vue.dureePrevueMinutes, heure: heure),
          ),
        ),
      );
      return;
    }
    if (avant == StatutPause.enCours &&
        statut != StatutPause.enCours &&
        !premiere) {
      dynamique.annoncer(
        AlerteChrono(
          id: 'pause-fin-${_debutVu?.millisecondsSinceEpoch}',
          titre: d.pauseFinie,
          duree: AppMouvement.alerteChronoBreve,
        ),
      );
    }
  }

  void _piloter(DateTime now) {
    final PauseSeance? p = _pause;
    if (p == null) return;
    // La fin a l'heure de reprise : une fois, un echec se reessaie.
    final DateTime? reprise = p.repriseUtc;
    if (p.statut == StatutPause.enCours &&
        reprise != null &&
        !now.isBefore(reprise) &&
        !_terminerEnVol &&
        _termineePour != p.debutUtc) {
      _terminerEnVol = true;
      final DateTime? debut = p.debutUtc;
      unawaited(
        commandes!.terminer().then(
          (void _) {
            _terminerEnVol = false;
            _termineePour = debut;
          },
          onError: (Object _) {
            _terminerEnVol = false;
          },
        ),
      );
    }
    if (p.statut != StatutPause.programmee) {
      dynamique.oublier(cleProposee);
      return;
    }
    final DateTime? proposer = p.proposerAUtc;
    if (proposer == null) {
      dynamique
        ..oublier(cleProposee)
        ..retirer(_idProposition ?? '');
      return;
    }
    if (p.motif == MotifPause.priere) {
      _piloterPriere(p, proposer, now);
      return;
    }
    if (now.isBefore(proposer) || _enVol || _refuseePour == proposer) return;
    final String? id = _idProposition;
    final bool montree = id != null && dynamique.attendFamille(id);
    if (_proposeePour == proposer) {
      if (montree) return;
      // Repliee sans reponse (ou d'un toucher) : le rappel part de
      // maintenant, sans rien envoyer au serveur.
      final DateTime? rappel = _rappelA;
      if (rappel == null) {
        _rappelA = now.add(rappelSansReponse);
        return;
      }
      if (now.isBefore(rappel)) return;
    }
    _proposer(p, proposer);
  }

  void _proposer(PauseSeance p, DateTime proposer) {
    _proposeePour = proposer;
    _rappelA = null;
    final String id = 'pause-proposee-${dynamique.numero}';
    _idProposition = id;
    final d = t.salle.dynamique;
    dynamique.annoncer(
      AlerteChrono(
        id: id,
        titre: LibellesGroupe.insecable(
          d.pauseQuestion(minutes: p.dureePrevueMinutes),
        ),
        actions: <ActionAlerteChrono>[
          ActionAlerteChrono(
            libelle: d.oui,
            principale: true,
            onPress: () => _oui(proposer),
          ),
          ActionAlerteChrono(libelle: d.non, onPress: () => _non(proposer)),
        ],
        duree: AppMouvement.propositionPause,
        trace: MarqueChrono.pause(
          genre: GenreMarqueChrono.pauseProgrammee,
          libelle: d.pauseProposee,
          annonce: d.pauseProposee,
        ),
        cleTrace: cleProposee,
        rouvrable: true,
      ),
    );
  }

  void _oui(DateTime proposer) {
    _enVol = true;
    dynamique.oublier(cleProposee);
    unawaited(
      commandes!.demarrer().then(
        (void _) => _enVol = false,
        onError: (Object _) {
          // Non confirme : la proposition reste (la salle dit l'echec).
          _enVol = false;
          _proposeePour = null;
          evaluer();
        },
      ),
    );
  }

  void _non(DateTime proposer) {
    _enVol = true;
    _refuseePour = proposer;
    dynamique.oublier(cleProposee);
    unawaited(
      commandes!.refuser().then(
        (void _) => _enVol = false,
        onError: (Object _) {
          _enVol = false;
          _refuseePour = null;
          _proposeePour = null;
          evaluer();
        },
      ),
    );
  }

  void _piloterPriere(PauseSeance p, DateTime heurePriere, DateTime now) {
    if (_enVol) return;
    if (!now.isBefore(heurePriere)) {
      if (_priereDemarreePour == heurePriere) return;
      _priereDemarreePour = heurePriere;
      dynamique.retirer('priere-${heurePriere.millisecondsSinceEpoch}');
      _enVol = true;
      unawaited(
        commandes!.demarrer().then(
          (void _) => _enVol = false,
          onError: (Object _) {
            _enVol = false;
            _priereDemarreePour = null;
          },
        ),
      );
      return;
    }
    if (now.isBefore(heurePriere.subtract(avancePriere)) ||
        _priereAnnonceePour == heurePriere) {
      return;
    }
    _priereAnnonceePour = heurePriere;
    final d = t.salle.dynamique;
    final String id = 'priere-${heurePriere.millisecondsSinceEpoch}';
    dynamique.annoncer(
      AlerteChrono(
        id: id,
        titre: LibellesGroupe.insecable(
          d.priereDans(minutes: avancePriere.inMinutes),
        ),
        actions: <ActionAlerteChrono>[
          ActionAlerteChrono(
            libelle: d.commencerMaintenant,
            principale: true,
            onPress: () {
              _priereDemarreePour = heurePriere;
              _enVol = true;
              unawaited(
                commandes!.demarrer().then(
                  (void _) => _enVol = false,
                  onError: (Object _) {
                    _enVol = false;
                    _priereDemarreePour = null;
                  },
                ),
              );
            },
          ),
          ActionAlerteChrono(
            libelle: LibellesGroupe.insecable(
              d.decaler(minutes: minutesDecalage),
            ),
            onPress: () {
              _enVol = true;
              unawaited(
                commandes!.refuser().then(
                  (void _) => _enVol = false,
                  onError: (Object _) {
                    _enVol = false;
                    _priereAnnonceePour = null;
                  },
                ),
              );
            },
          ),
        ],
        duree: AppMouvement.propositionPause,
      ),
    );
  }
}

/// La famille des alertes de recitation : la fin remplace le debut, sans
/// attendre son tour.
const String groupeRecitation = 'recitation';

/// La cle de la marque de l'appel recu (jusqu'au toucher de la barre).
const String cleAppelRecu = 'appel-recu';

/// DYNAMIQUE-CHRONO-2, point 5 : « {Prenom} recite » ; un prenom que celui
/// qui regarde ne connait pas se dit « Un eleve recite ».
String titreRecitation(String prenom) => prenom.trim().isEmpty
    ? t.salle.dynamique.unEleveRecite
    : t.tc.classe.recitation.actif(prenom: prenom);

/// DYNAMIQUE-CHRONO-2, point 5 : l'appel recu par l'eleve, dans sa barre, en
/// plus du son et de la vibration ; sa marque reste jusqu'a ce qu'il touche
/// la barre.
AlerteChrono alerteAppelRecu({required bool tutoie, required int numero}) {
  final String titre = tutoie
      ? t.salle.gestes.appelRecuTitreTutoie
      : t.salle.gestes.appelRecuTitre;
  return AlerteChrono(
    id: '$cleAppelRecu-$numero',
    groupe: cleAppelRecu,
    titre: titre,
    detail: tutoie ? t.salle.gestes.appelRecuTutoie : t.salle.gestes.appelRecu,
    trace: MarqueChrono.evenement(
      libelle: titre,
      genre: GenreMarqueChrono.appel,
      ton: TonEtat.accent,
    ),
    cleTrace: cleAppelRecu,
  );
}
