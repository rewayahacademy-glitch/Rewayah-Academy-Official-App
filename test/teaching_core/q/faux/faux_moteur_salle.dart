// Faux moteur de salle, et faux porteur de session persistante.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// Le patron reproduit est celui de `test/features/salle_test.dart` : un faux
// moteur injecte par override, sans SDK LiveKit. La difference tient en un
// point -- celui-ci **compte** les deconnexions, parce que c'est precisement
// ce que les tests Q-07 et Q-12 doivent prouver egal a zero.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Un moteur de salle qui n'ouvre aucune connexion et compte ce qu'on lui
/// demande.
class FauxMoteurSalle implements VideoSessionProvider {
  /// Cree un faux moteur, deja connecte si [connecte] vaut vrai.
  FauxMoteurSalle({bool connecte = true})
    : _etat = connecte ? EtatSalle.connecte : EtatSalle.absent;

  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<List<ParticipantSalle>> _participants =
      StreamController<List<ParticipantSalle>>.broadcast();
  final StreamController<QualiteLien> _qualite =
      StreamController<QualiteLien>.broadcast();
  final StreamController<ContenuPresente> _contenus =
      StreamController<ContenuPresente>.broadcast();

  EtatSalle _etat;

  /// Le nombre d'appels a [quitter]. **C'est la mesure des tests Q-07/Q-12.**
  int deconnexions = 0;

  /// Le nombre d'appels a [rejoindre].
  int connexions = 0;

  /// Le nombre d'appels a [liberer].
  int liberations = 0;

  /// Les contenus effectivement presentes a la classe.
  final List<ContenuPresente> contenusEmis = <ContenuPresente>[];

  @override
  Future<void> rejoindre(AccesSalle acces) async {
    connexions++;
    _etat = EtatSalle.connecte;
    _etats.add(_etat);
  }

  @override
  Future<void> quitter() async {
    deconnexions++;
    _etat = EtatSalle.absent;
    _etats.add(_etat);
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {}

  @override
  String? get erreurCameraEntree => null;

  @override
  Future<void> reglerCamera({required bool actif}) async {}

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {}

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  @override
  Stream<List<ParticipantSalle>> get participants => _participants.stream;

  @override
  Stream<QualiteLien> get qualite => _qualite.stream;

  @override
  Stream<ContenuPresente> get contenusPresentes => _contenus.stream;

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {
    contenusEmis.add(contenu);
    _contenus.add(contenu);
  }

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Widget? renduVideo(String identite) => null;

  @override
  Future<void> liberer() async {
    liberations++;
    await _etats.close();
    await _participants.close();
    await _qualite.close();
    await _contenus.close();
    await _donnees.close();
  }

  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  @override
  Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

  @override
  AccesSalle? get accesCourant => null;

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {}
}

/// Le double du transport qui annonce une sortie au serveur.
///
/// Il enregistre l'ORDRE des gestes : la sortie volontaire annonce au serveur
/// **avant** de couper le moteur (decision D-24, detail a reproduire a
/// l'identique). L'ordre porte de l'information -- le webhook deduplique dans
/// une fenetre de 30 s -- donc un test qui ne verifierait que le resultat
/// laisserait passer l'inversion.
class FauxAnnonceSortie {
  /// La trace des gestes, dans l'ordre.
  final List<String> gestes = <String>[];

  /// Fait echouer l'annonce, pour verifier qu'on n'en depend pas pour une
  /// simple trace.
  bool echoue = false;

  /// Annonce la sortie au serveur.
  Future<void> annoncerSortie(String sessionId) async {
    gestes.add('annonce');
    if (echoue) throw StateError('annonce refusee');
  }
}

/// La session live en cours, independamment de l'ecran affiche.
///
/// Double de `SessionEnCours` d'Agent E, reduit a ce dont les tests de
/// navigation ont besoin.
class SessionEnCoursDouble {
  /// Cree une session en cours.
  const SessionEnCoursDouble({
    required this.sessionId,
    required this.groupeId,
    required this.libelleGroupe,
  });

  /// La seance.
  final String sessionId;

  /// Le groupe.
  final String groupeId;

  /// Le libelle affiche dans la barre compacte « Seance toujours en direct ».
  final String libelleGroupe;
}

/// Le porteur applicatif de la session : **il possede la room, pas l'ecran.**
///
/// Double de `PortSessionPersistante` (CONTRACTS section 12). Sa raison d'etre
/// tient en une phrase de la decision D-24 : retourner au Groupe, a l'Accueil
/// ou ouvrir la Bibliotheque ne coupe jamais LiveKit. Seul [quitter] le fait.
class FauxSessionPersistante {
  /// Cree un porteur au-dessus d'un moteur et d'un transport d'annonce.
  FauxSessionPersistante({
    required this.moteur,
    required this.annonce,
    this.courante,
  });

  /// Le moteur possede.
  final FauxMoteurSalle moteur;

  /// Le transport d'annonce de sortie.
  final FauxAnnonceSortie annonce;

  /// La session en cours, ou `null`.
  SessionEnCoursDouble? courante;

  final StreamController<SessionEnCoursDouble?> _flux =
      StreamController<SessionEnCoursDouble?>.broadcast();

  /// Le flux de la session en cours.
  Stream<SessionEnCoursDouble?> suivre() => _flux.stream;

  /// Sortie **volontaire** : on annonce au serveur, puis on coupe.
  Future<void> quitter() async {
    try {
      await annonce.annoncerSortie(courante?.sessionId ?? '');
    } on StateError {
      // Une annonce perdue reste une trace perdue, pas une sortie empechee :
      // c'est le comportement de `ServiceVideo.annoncerSortie` du depot. Il
      // serait INACCEPTABLE si ce geste devait fermer un quota d'observation
      // (decision D-14) -- d'ou le test Q-03, qui ferme cote serveur.
    }
    annonce.gestes.add('quitter');
    await moteur.quitter();
    courante = null;
    _flux.add(null);
  }

  /// Ferme le flux. A appeler en fin de test.
  Future<void> liberer() async {
    await _flux.close();
  }
}
