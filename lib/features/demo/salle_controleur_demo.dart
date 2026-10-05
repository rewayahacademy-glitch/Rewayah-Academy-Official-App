// La salle du controleur en demonstration (CT-3, CTR-02) : la VRAIE salle
// (`SallePage`, role `masked_controller`), ses ports video, pre-vol et
// presence remplaces par des doubles locaux. Aucun serveur, aucun WebRTC
// (K-28) : le moteur rejoue ce que le vrai publie, un etat et une liste.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/presence/service_presence.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import 'classe_demo.dart' show DonneesClasseDemo, EleveProjectionDemo;

/// L'identite fictive du controleur dans la salle.
const String identiteControleurDemo = 'demo-controleur';

/// L'acces tel que `create-room-token` le rendrait a un controleur : muet,
/// sans camera, sans donnees, invisible (ADR-011).
AccesSalle accesControleurDemo() => AccesSalle(
  urlServeur: 'wss://demo.invalid',
  jeton: 'demo',
  nomSalle: 'demo-controle',
  fournisseur: FournisseurVideo.cloud,
  role: 'masked_controller',
  capacites: const CapacitesSalle(
    peutPublier: false,
    peutPublierVideo: false,
    peutPublierDonnees: false,
    peutRecevoir: true,
    invisible: true,
  ),
  expireLe: DateTime.now().add(const Duration(hours: 1)),
);

/// Les personnes de la seance observee : l'enseignant, puis les eleves, tous
/// sans image (aucune piste en demonstration) : le cadre montre prenom et
/// initiales, jamais une photo (question 11 de UX_REVIEW_08).
List<ParticipantSalle> participantsControleurDemo() {
  final String titre = switch (DonneesClasseDemo.enseignant.titre) {
    TitreEnseignant.sayyid => LibellesGroupe.sayyid,
    TitreEnseignant.sayyida => LibellesGroupe.sayyida,
  };
  return <ParticipantSalle>[
    const ParticipantSalle(
      identite: identiteControleurDemo,
      nom: '',
      role: 'masked_controller',
      estLocal: true,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    ),
    ParticipantSalle(
      identite: 'demo-enseignant',
      nom: '$titre ${DonneesClasseDemo.enseignant.nomAffichage}',
      role: 'teacher',
      estLocal: false,
      micro: true,
      camera: false,
      parle: true,
      qualite: QualiteLien.bonne,
    ),
    for (final EleveProjectionDemo e in DonneesClasseDemo.eleves)
      ParticipantSalle(
        identite: 'demo-eleve-${e.prenom}',
        nom: e.prenom,
        role: 'student',
        estLocal: false,
        micro: false,
        camera: false,
        parle: false,
        qualite: QualiteLien.bonne,
      ),
  ];
}

/// Le moteur de demonstration : il entre, se dit connecte et publie la
/// liste. Il ne publie jamais rien au nom du controleur.
class MoteurSalleControleurDemo implements VideoSessionProvider {
  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<List<ParticipantSalle>> _participants =
      StreamController<List<ParticipantSalle>>.broadcast();
  final StreamController<QualiteLien> _qualite =
      StreamController<QualiteLien>.broadcast();

  EtatSalle _etat = EtatSalle.absent;
  AccesSalle? _acces;

  @override
  Future<void> rejoindre(AccesSalle acces) async {
    _acces = acces;
    _poser(EtatSalle.connexion);
    _poser(EtatSalle.connecte);
    _qualite.add(QualiteLien.bonne);
    _participants.add(participantsControleurDemo());
  }

  void _poser(EtatSalle etat) {
    _etat = etat;
    if (!_etats.isClosed) _etats.add(etat);
  }

  @override
  Future<void> quitter() async {
    _acces = null;
    _poser(EtatSalle.absent);
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {}

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
  Stream<ContenuPresente> get contenusPresentes =>
      const Stream<ContenuPresente>.empty();

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {}

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Widget? renduVideo(String identite) => null;

  @override
  Future<void> liberer() async {}

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {
    // Le controleur ne publie rien (P-CTR-03 point 7).
    throw const EchecPublicationDonnees(MotifEchecPublication.droitRefuse);
  }

  @override
  Stream<PaquetDonnees> get donneesRecues => const Stream<PaquetDonnees>.empty();

  @override
  AccesSalle? get accesCourant => _acces;
}

/// Le service video de demonstration : l'acces du controleur, rien d'autre.
class ServiceVideoControleurDemo implements ServiceVideo {
  /// Cree le service.
  const ServiceVideoControleurDemo();

  @override
  Future<AccesSalle> acces(String seanceId) async => accesControleurDemo();

  @override
  Future<void> observerEnControle(String seanceId) async {}

  @override
  Future<void> assisterEnTuteur(String seanceId) async {}

  @override
  Future<void> annoncerSortie(String seanceId) async {}
}

/// Le pre-vol de demonstration : rien a verifier, aucun materiel ouvert.
class PreVolControleurDemo implements ServicePreVol {
  /// Cree le pre-vol.
  const PreVolControleurDemo();

  @override
  Future<ResultatPreVol> verifier() async => const ResultatPreVol(
    microDisponible: true,
    cameraDisponible: true,
    sortieAudioDisponible: true,
    permissionRefusee: false,
  );
}

/// La presence de demonstration : inconnue (invariant J3), la liste retombe
/// sur les personnes que le moteur connait.
class PresenceControleurDemo implements ServicePresence {
  /// Cree le service.
  const PresenceControleurDemo();

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async => null;
}
