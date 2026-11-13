// SYNCHRO-SESSION (directeur, 12/11/2026, point 15 : la barre du chrono
// « marche bien aussi lorsque l'on reduit la salle, mais la aussi il faut
// qu'elle soit exploitee au max » ; plan : `docs/current/salle/HARMONIE-
// 2026-11-13.md`, section 7 et lignes 3.1 a 3.3 ; journal D-045).
//
// Ce qui vit le temps d'un appel, et non le temps d'un ecran : la
// synchronisation de la salle ([SynchroSalle] : traits, page et tableau
// rejoues a chaque arrivee, parole, rappels, pointeur) et LA Dynamique
// chrono de la seance ([PiloteDynamique] : une file d'alertes, des marques).
// La page de la salle et la salle reduite (`BarreSeanceEnDirect`) lisent le
// meme objet : une marque ou une alerte nee dans l'une se voit dans l'autre.
//
// Qui le tient :
// - en production, le controleur de session (`ControleurSessionPersistante`)
//   le cree quand il adopte l'appel et le libere quand l'appel finit
//   (« Quitter », fin subie, sortie de l'eleve hors de l'application) ;
// - une demonstration ou un test qui surcharge le moteur sous la racine (le
//   controleur ne tient pas son appel) : la page en cree un a elle, libere
//   avec elle (l'ancienne regle) ; la salle reduite de meme si le controleur
//   n'en a pas.
//
// Aucune regle ne change : chaque decision reste lue sur les capacites du
// jeton signe, la pause sur l'etat servi par le serveur, et rien n'est garde
// au-dela de l'appel.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:uuid/uuid.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/theme/app_delais.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/video/gestes_salle.dart';
import '../../core/video/publication_differee.dart' show roleQuiConduit;
import '../../core/video/signal_rappel.dart';
import '../../core/video/video_session_provider.dart';
import '../salle_seance/chrono_salle.dart' show horlogeChronoProvider;
import '../salle_seance/marque_chrono.dart';
import '../salle_seance/pilote_dynamique.dart';
import '../salle_seance/relais_salle.dart';
import 'synchro_salle.dart';

/// La synchronisation et la Dynamique chrono d'une seance, le temps de
/// l'appel.
class SeanceVivante extends ChangeNotifier implements CompagnonAppel {
  /// Raccorde la seance [sessionId] au moteur, avec l'acces [acces].
  ///
  /// [profilLocalId] : le profil de cet appareil ; `null` (session illisible)
  /// : aucune synchronisation, la Dynamique chrono seule. [signal] : le son
  /// et la vibration de l'appel recu et du tour de reciter. [maintenant] :
  /// l'heure du serveur (celle du chrono), pour la pause. [portPause] et
  /// [relirePause] : les commandes de la pause et la relecture de son etat ;
  /// sans port, rien n'est jamais envoye au serveur.
  SeanceVivante({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required this.sessionId,
    required String? profilLocalId,
    required this.tutoie,
    required this._signal,
    required DateTime Function() maintenant,
    PortPauseSeance Function()? portPause,
    this._relirePause,
    SignalErreurSynchro signalerErreur = signalerErreurSynchro,
  }) : _moteur = moteur,
       _acces = acces,
       _portPause = portPause,
       synchro = profilLocalId == null
           ? null
           : SynchroSalle(
               moteur: moteur,
               acces: acces,
               sessionId: sessionId,
               profilLocalId: profilLocalId,
               signalerErreur: signalerErreur,
             ) {
    _sonnerie = SonnerieAppel(_jouer);
    _pause = PilotePause(
      dynamique: dynamique,
      maintenant: maintenant,
      commandes: portPause == null ? null : _CommandesPauseSeance(this),
    );
    final SynchroSalle? s = synchro;
    if (s != null) {
      s.parole.addListener(_paroleChangee);
      s.tableauOuvert.addListener(_changer);
      s.rappelsRecus.addListener(_rappelRecu);
    }
    // DYNAMIQUE-CHRONO-2 : un toucher de la barre coupe la sonnerie et
    // efface la marque de l'appel recu ; chaque battement relit la pause.
    dynamique
      ..auToucher(() {
        _sonnerie.arreter();
        dynamique.oublier(cleAppelRecu);
      })
      ..aChaqueBattement(() {
        if (!_libere) _pause.evaluer();
      })
      ..demarrer();
    _sParticipants = moteur.participants.listen(_participantsRecus);
    _sPause = moteur.donneesRecues
        .where((PaquetDonnees p) => p.sujet == sujetPauseSalle)
        .listen(_pauseRecueDe);
    // Ligne 3.1 : le recitant que le moteur lit (metadonnees de la salle,
    // ecrites par le serveur), quand le moteur sait le dire.
    if (moteur case final RecitantDeLaSalle r) {
      _recitantMoteur = r.recitantCourant;
      _sRecitant = r.recitantChange.listen((String? recitant) {
        if (recitant == _recitantMoteur) return;
        _recitantMoteur = recitant;
        _changer();
      });
    }
  }

  @override
  final String sessionId;

  final VideoSessionProvider _moteur;
  final AccesSalle _acces;
  final SignalRappel _signal;
  final PortPauseSeance Function()? _portPause;
  final VoidCallback? _relirePause;

  /// La synchronisation de la salle, ou `null` (profil inconnu).
  final SynchroSalle? synchro;

  /// LA Dynamique chrono de la seance (ligne 3.2), lue par la page et par la
  /// salle reduite.
  final PiloteDynamique dynamique = PiloteDynamique();

  /// Le tutoiement de la salle (Interface guidee) : celui du cours, puis
  /// celui que la page lit a sa composition.
  bool tutoie;

  late final SonnerieAppel _sonnerie;
  late final PilotePause _pause;
  final SuiviArrivees _arrivees = SuiviArrivees();

  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<PaquetDonnees>? _sPause;
  StreamSubscription<String?>? _sRecitant;

  bool _libere = false;

  /// Vrai une fois l'appel fini (ou l'ecran qui tenait la seance parti).
  bool get libere => _libere;

  /// Les capacites du jeton courant (le moteur suit les droits que le
  /// serveur change), sinon celles de l'entree.
  CapacitesSalle get _capacites => (_moteur.accesCourant ?? _acces).capacites;

  /// Un widget lit une capacite, jamais un role : qui peut moderer la seance
  /// la conduit.
  bool get _conduit => _capacites.peutModerer;

  void _changer() {
    if (!_libere) notifyListeners();
  }

  void _jouer() {
    try {
      _signal();
    } on Object catch (e) {
      journalDev('signal de la salle impossible : $e');
    }
  }

  /// La sonnerie de l'appel recu sonne-t-elle encore ?
  bool get sonne => _sonnerie.sonne;

  /// Toucher l'ecran arrete la sonnerie (DYNAMIQUE-CHRONO-2, point 6).
  void arreterSonnerie() => _sonnerie.arreter();

  // ---------------------------------------------------------------------
  // La parole et l'appel
  // ---------------------------------------------------------------------

  /// L'eleve qui a la parole tel que l'enseignant l'a dit (prenom, alertes),
  /// ou `null`.
  ParoleSalle? get parole => synchro?.parole.value;

  String? _recitantMoteur;

  /// Ligne 3.1 : l'identite de l'eleve qui recite pour la VIDEO et le cadre
  /// mis en avant. Les metadonnees de la salle (ce que lit le moteur pour
  /// s'abonner) font foi quand le moteur sait les dire ; sinon
  /// (demonstration, doubles), le message de l'enseignant.
  String? get recitant => _moteur is RecitantDeLaSalle
      ? _recitantMoteur
      : synchro?.parole.value?.profilId;

  /// Le tableau ouvert par l'enseignant, tel que la classe le recoit.
  bool get tableauOuvert => synchro?.tableauOuvert.value ?? false;

  /// La derniere recitation vue par cet appareil (eleve).
  ParoleSalle? _paroleVue;

  /// GESTES-POINTEUR : chez un eleve, la recitation se dit en une phrase
  /// (dans la barre, DYNAMIQUE-CHRONO-2, point 5). Le recitant : « ouvrez
  /// votre micro » (son micro n'est jamais ouvert de force). Ses camarades :
  /// leur micro est ferme, et pourquoi. A la fin : ils peuvent le rouvrir.
  /// Ecrit une fois : que la salle soit ouverte ou reduite.
  void _paroleChangee() {
    if (_libere) return;
    final SynchroSalle? s = synchro;
    if (s == null) return;
    if (!_conduit) _annoncerParole(s);
    _changer();
  }

  void _annoncerParole(SynchroSalle s) {
    final ParoleSalle? avant = _paroleVue;
    final ParoleSalle? parole = s.parole.value;
    _paroleVue = parole;
    final bool tu = tutoie;
    if (parole == null) {
      if (avant == null) return;
      dynamique.annoncer(
        AlerteChrono(
          id: 'recitation-fin-${dynamique.numero}',
          groupe: groupeRecitation,
          titre: t.salle.gestes.finRecitationTitre,
          detail: tu
              ? t.salle.gestes.finRecitationTutoie
              : t.salle.gestes.finRecitation,
          duree: AppMouvement.alerteChronoBreve,
        ),
      );
    } else if (parole.profilId == s.profilLocalId) {
      _jouer();
      dynamique.annoncer(
        AlerteChrono(
          id: 'recitation-${dynamique.numero}',
          groupe: groupeRecitation,
          titre: tu
              ? t.salle.gestes.aVousTitreTutoie
              : t.salle.gestes.aVousTitre,
          detail: tu ? t.salle.gestes.aVousTutoie : t.salle.gestes.aVous,
        ),
      );
    } else {
      dynamique.annoncer(
        AlerteChrono(
          id: 'recitation-${dynamique.numero}',
          groupe: groupeRecitation,
          titre: titreRecitation(parole.prenom),
          detail: tu
              ? t.salle.gestes.autreReciteTutoie
              : t.salle.gestes.autreRecite,
        ),
      );
    }
  }

  /// « Appeler » : l'eleve appele l'entend (sonnerie repetee) et le lit dans
  /// la barre, qui laisse sa marque jusqu'a son toucher (DYNAMIQUE-CHRONO-2,
  /// points 5 et 6), salle ouverte ou reduite.
  void _rappelRecu() {
    if (_libere) return;
    _sonnerie.lancer();
    dynamique.annoncer(
      alerteAppelRecu(tutoie: tutoie, numero: dynamique.numero),
    );
  }

  // ---------------------------------------------------------------------
  // Les arrivees
  // ---------------------------------------------------------------------

  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  int _participantsVus = 0;

  void _participantsRecus(List<ParticipantSalle> liste) {
    if (_libere) return;
    _participants = liste;
    // DYNAMIQUE-CHRONO-2, point 5 : qui conduit la seance voit arriver ses
    // eleves (+1, +2), sans son, salle ouverte ou reduite.
    if (_conduit) {
      annoncerArrivees(dynamique, <String>[
        for (final ParticipantSalle p in _arrivees.observer(
          liste,
          ecoule: dynamique.ecoule,
        ))
          p.nom,
      ]);
    }
    // SITUATIONS-GRAVES : un arrivant recoit la pause en cours.
    final PauseSeance? diffusee = _pauseDiffusee;
    if (liste.length > _participantsVus && diffusee != null) {
      unawaited(diffuserPause(diffusee, forcer: true));
    }
    _participantsVus = liste.length;
  }

  // ---------------------------------------------------------------------
  // La pause
  // ---------------------------------------------------------------------

  PauseSeance? _pauseRecue;
  PauseSeance? _pauseDiffusee;
  PauseSeance? _pauseObservee;
  bool _pauseJamaisObservee = true;
  String? _echecPause;

  /// La pause relayee par qui conduit (eleve, tuteur), ou `null`.
  PauseSeance? get pauseRecue => _pauseRecue;

  /// N3, S2 : le dernier geste de la Dynamique chrono sur la pause n'est pas
  /// confirme (K-59), ou `null`.
  String? get echecPause => _echecPause;

  /// SITUATIONS-GRAVES, ligne 3.3 : la pause relayee n'est lue que si elle
  /// vient de qui conduit la seance (l'identite et le role du jeton signe),
  /// la meme verification dans la salle et dans la salle reduite.
  void _pauseRecueDe(PaquetDonnees paquet) {
    if (_libere || _conduit) return;
    final bool deQuiConduit = _participants.any(
      (ParticipantSalle p) =>
          p.identite == paquet.emetteurIdentite && p.role == roleQuiConduit,
    );
    if (!deQuiConduit) return;
    final PauseSeance? pause = pauseDepuisCharge(paquet.charge);
    if (pause == null) return;
    _pauseRecue = pause;
    _changer();
  }

  /// La pause lue par la barre (servie chez qui conduit, relayee chez les
  /// autres) : une fois par changement, apres l'image. [pilote] : la
  /// capacite `peutPiloter` du serveur.
  void observerPause(PauseSeance? pause, {required bool pilote}) {
    if (_libere) return;
    if (!_pauseJamaisObservee && pause == _pauseObservee) return;
    _pauseJamaisObservee = false;
    _pauseObservee = pause;
    scheduleMicrotask(() {
      if (!_libere) _pause.observer(pause, pilote: pilote);
    });
  }

  /// SITUATIONS-GRAVES (defaut n° 6) : relaie [pause] (l'etat servi) a la
  /// classe sur le canal fiable, a chaque changement et a chaque arrivant ;
  /// sans droit de publier, rien ne part. Aucun micro n'est touche.
  Future<void> diffuserPause(PauseSeance pause, {bool forcer = false}) async {
    if (_libere) return;
    if (!forcer && pause == _pauseDiffusee) return;
    _pauseDiffusee = pause;
    if (!_capacites.peutPublierDonnees) return;
    try {
      await _moteur.publierDonnees(
        sujet: sujetPauseSalle,
        charge: utf8.encode(jsonEncode(chargePause(pause))),
        fiable: true,
      );
    } on Object catch (erreur) {
      journalDev('pause non relayee : $erreur');
    }
  }

  /// Une commande de la pause, par le port ; l'etat rendu par le serveur est
  /// relaye a la classe (HARMONIE-SALLE, 3.4) ; un echec se dit en une
  /// phrase (K-59), puis l'etat est relu.
  Future<void> _commander(
    Future<PauseSeance> Function(PortPauseSeance port, String cle) commande,
  ) async {
    final PortPauseSeance Function()? port = _portPause;
    if (port == null || _libere) return;
    _poserEchec(null);
    try {
      final PauseSeance etat = await commande(
        port(),
        const Uuid().v4(),
      ).timeout(AppDelais.requeteMax);
      await diffuserPause(etat);
    } on Object {
      _poserEchec(t.salle.seance.pause.echec);
      rethrow;
    } finally {
      if (!_libere) _relirePause?.call();
    }
  }

  void _poserEchec(String? echec) {
    if (_libere || _echecPause == echec) return;
    _echecPause = echec;
    _changer();
  }

  // ---------------------------------------------------------------------
  // La fin
  // ---------------------------------------------------------------------

  /// Coupe tout, tout de suite : sonnerie, battement de la Dynamique chrono,
  /// abonnements au moteur, synchronisation. Rien de la seance ne passe a
  /// la suivante.
  @override
  Future<void> liberer() async {
    if (_libere) return;
    _libere = true;
    _sonnerie.arreter();
    dynamique.dispose();
    final SynchroSalle? s = synchro;
    if (s != null) {
      s.parole.removeListener(_paroleChangee);
      s.tableauOuvert.removeListener(_changer);
      s.rappelsRecus.removeListener(_rappelRecu);
    }
    final List<Future<void>> fins = <Future<void>>[
      ?_sParticipants?.cancel(),
      ?_sPause?.cancel(),
      ?_sRecitant?.cancel(),
    ];
    _sParticipants = null;
    _sPause = null;
    _sRecitant = null;
    // Ceux qui la lisent (page, salle reduite) l'apprennent et la quittent.
    notifyListeners();
    dispose();
    await Future.wait(<Future<void>>[...fins, ?s?.liberer()]);
  }
}

/// Les commandes de la pause, tenues par la seance : la meme chose que la
/// salle soit ouverte ou reduite.
class _CommandesPauseSeance implements CommandesPause {
  _CommandesPauseSeance(this._seance);

  final SeanceVivante _seance;

  String get _id => _seance.sessionId;

  @override
  Future<void> demarrer() => _seance._commander(
    (PortPauseSeance port, String cle) =>
        port.demarrer(seanceId: _id, cleIdempotence: cle),
  );

  @override
  Future<void> terminer() => _seance._commander(
    (PortPauseSeance port, String cle) =>
        port.terminer(seanceId: _id, cleIdempotence: cle),
  );

  @override
  Future<void> refuser() => _seance._commander(
    (PortPauseSeance port, String cle) =>
        port.refuser(seanceId: _id, cleIdempotence: cle),
  );
}

/// Lit un fournisseur (`ref.read` d'un `Ref` comme d'un `WidgetRef`).
typedef LireFournisseur = T Function<T>(ProviderListenable<T> fournisseur);

/// La seance d'un appel qu'on vient d'adopter (ou que la page tient
/// elle-meme), raccordee aux fournisseurs de l'application : profil, signal,
/// horloge du chrono, port de la pause, gestes. [relirePause] relit l'etat
/// de la pause (invalidation du fournisseur).
///
/// GESTES-POINTEUR : celui qui conduit entre (ou revient, page rechargee)
/// sans recitation connue de cet appareil ; si le serveur en tient encore
/// une, il la termine (jamais une classe muette que l'enseignant ne voit
/// pas). Une fois, a la naissance de la seance : une salle rouverte depuis la
/// barre ne coupe plus la recitation en cours. [terminerRecitationALEntree]
/// faux : la salle reduite qui tient sa propre seance (controleur sans
/// fabrique) ne le demande pas, comme avant. [profilLocalId] : le profil
/// deja connu de l'appelant ; sinon il est lu dans la session.
SeanceVivante creerSeanceVivante({
  required SessionEnCours cours,
  required AccesSalle acces,
  required VideoSessionProvider moteur,
  required LireFournisseur lire,
  required VoidCallback relirePause,
  bool terminerRecitationALEntree = true,
  String? profilLocalId,
}) {
  String? profil = profilLocalId;
  if (profil == null) {
    try {
      profil = lire(sessionProvider).profileId;
    } on Object catch (e) {
      journalDev('profil illisible pour la seance : $e');
    }
  }
  final SeanceVivante seance = SeanceVivante(
    moteur: moteur,
    acces: acces,
    sessionId: cours.sessionId,
    profilLocalId: profil,
    tutoie: cours.interfaceGuidee,
    signal: () => lire(signalRappelProvider)(),
    maintenant: () => lire(horlogeChronoProvider)().toUtc(),
    portPause: () => lire(portPauseSeanceProvider),
    relirePause: relirePause,
  );
  if (terminerRecitationALEntree && acces.capacites.peutModerer) {
    try {
      unawaited(
        lire(portGestesSalleProvider)
            .terminerRecitation(cours.sessionId)
            .catchError(
              (Object e) => journalDev('recitation non relue a l entree : $e'),
            ),
      );
    } on Object catch (e) {
      journalDev('recitation non relue a l entree : $e');
    }
  }
  return seance;
}

/// La seance que tient le controleur pour [sessionId], ou `null`.
SeanceVivante? seanceTenue(
  ControleurSessionPersistante controleur,
  String sessionId,
) => switch (controleur.compagnon) {
  final SeanceVivante s when s.sessionId == sessionId && !s.libere => s,
  _ => null,
};
