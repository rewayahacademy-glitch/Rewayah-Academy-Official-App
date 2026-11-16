import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/port_roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Les faux d'Agent E.
///
/// **Ecrits ici et non dans `test/support/harnais.dart`** (decision D-06) : ce
/// fichier est PROTECTED, partage par neuf agents, et deja modifie par le
/// chantier enseignant. Le patron reproduit est celui de
/// `test/features/salle_test.dart` : le faux moteur ne simule pas WebRTC, il
/// rejoue ce que le vrai moteur **publie** -- trois flux et une liste. C'est
/// tout ce dont la Classe Live depend, et c'est pourquoi elle se verifie sans
/// SDK, sans reseau et sans compte LiveKit.

/// L'acces tel que `create-room-token` le rend pour chacun des quatre roles.
///
/// Les capacites ne sont pas inventees ici : elles reproduisent ce que
/// `autoriser_jeton_video()` calcule -- `can_publish_data` reserve a
/// l'enseignant, camera d'eleve fermee par defaut, controleur invisible.
AccesSalle accesDe(String role, {bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher' || (role == 'student' && camera),
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// Un participant publie par le moteur.
ParticipantSalle participantDe({
  required String identite,
  required String role,
  String? nom,
  bool local = false,
  bool micro = false,
  bool camera = false,
}) => ParticipantSalle(
  identite: identite,
  nom: nom ?? identite,
  role: role,
  estLocal: local,
  micro: micro,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

/// Une ligne de `presence_seance_v`.
PresenceParticipant presenceDe({
  required String profilId,
  required String prenom,
  EtatPresence etat = EtatPresence.presente,
  String role = 'student',
  String? identifiant,
}) => PresenceParticipant(
  profilId: profilId,
  role: role,
  prenom: prenom,
  identifiantImmuable: identifiant ?? 'RA-$profilId',
  etat: etat,
  consolide: false,
);

/// Un moteur de salle en memoire.
class FauxMoteurClasse implements VideoSessionProvider {
  /// Cree le faux.
  ///
  /// [journal] est partage avec [FauxServiceVideoClasse] quand un test mesure
  /// l'**ordre** des gestes : l'annonce de sortie doit preceder la deconnexion,
  /// et c'est le seul moyen de le constater.
  FauxMoteurClasse({List<String>? journal})
    : journal = journal ?? <String>[];

  /// Les gestes, dans l'ordre ou ils ont eu lieu.
  final List<String> journal;

  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<List<ParticipantSalle>> _participants =
      StreamController<List<ParticipantSalle>>.broadcast();
  final StreamController<QualiteLien> _qualite =
      StreamController<QualiteLien>.broadcast();
  final StreamController<ContenuPresente> _contenus =
      StreamController<ContenuPresente>.broadcast();

  EtatSalle _etat = EtatSalle.absent;

  /// Les acces avec lesquels on a rejoint, dans l'ordre.
  final List<AccesSalle> entrees = <AccesSalle>[];

  /// Le nombre de sorties du moteur. **La mesure centrale du lot** : elle doit
  /// rester a zero quand on navigue, et passer a un sur « Quitter ».
  int departs = 0;

  /// Les reglages de micro demandes, dans l'ordre.
  final List<bool> microDemande = <bool>[];

  /// Les reglages de camera demandes, dans l'ordre.
  final List<bool> cameraDemandee = <bool>[];

  /// Ce que `rejoindre` doit lever, quand on teste un echec de connexion.
  Object? erreurEntree;

  /// Suspend `rejoindre` jusqu'a ce que le test la relache.
  ///
  /// Une connexion a une salle n'est pas instantanee, et c'est PENDANT cette
  /// attente que le budget d'observation peut tomber a zero. Sans prise sur ce
  /// moment, cet enchainement ne se joue pas : `rejoindre` aboutirait toujours
  /// avant que le serveur n'ait pu annoncer quoi que ce soit.
  Completer<void>? entreeSuspendue;

  /// Pose un etat et le publie, comme le vrai moteur.
  void poser(EtatSalle etat) {
    _etat = etat;
    _etats.add(etat);
  }

  /// Publie une liste de participants.
  void publier(List<ParticipantSalle> liste) => _participants.add(liste);

  /// Publie une qualite de lien.
  void publierQualite(QualiteLien lien) => _qualite.add(lien);

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  @override
  Stream<List<ParticipantSalle>> get participants => _participants.stream;

  @override
  Stream<QualiteLien> get qualite => _qualite.stream;

  @override
  Stream<ContenuPresente> get contenusPresentes => _contenus.stream;

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {}

  @override
  Future<void> rejoindre(AccesSalle acces) async {
    final Completer<void>? attente = entreeSuspendue;
    if (attente != null) {
      await attente.future;
    }
    final Object? erreur = erreurEntree;
    if (erreur != null) {
      poser(EtatSalle.echec);
      // ignore: only_throw_errors
      throw erreur;
    }
    entrees.add(acces);
    poser(EtatSalle.connecte);
  }

  @override
  Future<void> quitter() async {
    departs++;
    journal.add('deconnexion');
    poser(EtatSalle.absent);
  }

  @override
  Future<void> reglerMicro({required bool actif}) async {
    microDemande.add(actif);
  }

  @override
  String? get erreurCameraEntree => null;

  @override
  Future<void> reglerCamera({required bool actif}) async {
    cameraDemandee.add(actif);
  }

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {}

  /// Les images publiees, par identite.
  ///
  /// Le vrai moteur rend un widget deja monte, jamais une piste : un test n'a
  /// donc rien a simuler de WebRTC pour verifier qu'une image atteint l'ecran.
  final Map<String, Widget> videos = <String, Widget>{};

  @override
  Widget? renduVideo(String identite) => videos[identite];

  @override
  Future<void> liberer() async {
    await _etats.close();
    await _participants.close();
    await _qualite.close();
    await _contenus.close();
    await _donnees.close();
  }

  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  /// Les paquets publies, dans l'ordre. La Classe Live ne s'en sert pas
  /// directement : c'est l'adaptateur du lot F qui s'y branche, teste
  /// separement.
  final List<PaquetDonnees> donneesPubliees = <PaquetDonnees>[];

  @override
  Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

  @override
  AccesSalle? get accesCourant => entrees.isEmpty ? null : entrees.last;

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {
    donneesPubliees.add(
      PaquetDonnees(sujet: sujet, charge: charge, fiable: fiable),
    );
  }
}

/// Le service d'acces a la salle, en memoire.
class FauxServiceVideoClasse implements ServiceVideo {
  /// Cree le faux.
  FauxServiceVideoClasse({
    this.acces0,
    this.motifARefuser,
    List<String>? journal,
  }) : journal = journal ?? <String>[];

  /// Les gestes, dans l'ordre. Partage avec [FauxMoteurClasse] au besoin.
  final List<String> journal;

  /// L'acces rendu.
  AccesSalle? acces0;

  /// Le refus a lever, s'il y en a un.
  MotifRefusSalle? motifARefuser;

  /// Les seances pour lesquelles un acces a ete demande.
  final List<String> demandes = <String>[];

  /// Les sorties volontaires annoncees, dans l'ordre.
  ///
  /// **C'est l'ordre qui compte** : l'annonce precede la deconnexion, et seule
  /// cette ecriture distingue une sortie voulue d'une perte de reseau.
  final List<String> sorties = <String>[];

  @override
  Future<AccesSalle> acces(String seanceId, {String? eleveId}) async {
    demandes.add(seanceId);
    final MotifRefusSalle? motif = motifARefuser;
    if (motif != null) {
      throw EchecSalle(motif);
    }
    final AccesSalle? rendu = acces0;
    if (rendu == null) {
      throw const EchecSalle(MotifRefusSalle.reseau);
    }
    return rendu;
  }

  @override
  Future<void> observerEnControle(String seanceId) async {}

  @override
  Future<void> annoncerSortie(String seanceId) async {
    sorties.add(seanceId);
    journal.add('annonce');
  }
}

/// Le pre-vol, en memoire.
class FauxPreVolClasse implements ServicePreVol {
  /// Cree le faux, materiel complet par defaut.
  FauxPreVolClasse({
    this.microDisponible = true,
    this.cameraDisponible = true,
    this.permissionRefusee = false,
  });

  /// Une entree audio est utilisable.
  bool microDisponible;

  /// Une camera est utilisable.
  bool cameraDisponible;

  /// Le navigateur ou l'usager a refuse l'acces au materiel.
  bool permissionRefusee;

  /// Le nombre d'inspections demandees.
  int verifications = 0;

  @override
  Future<ResultatPreVol> verifier() async {
    verifications++;
    return ResultatPreVol(
      microDisponible: microDisponible,
      cameraDisponible: cameraDisponible,
      sortieAudioDisponible: true,
      permissionRefusee: permissionRefusee,
    );
  }
}

/// La presence d'une seance, en memoire.
///
/// **Le `null` est le cas le plus important a pouvoir jouer**, pas le cas
/// degrade : c'est lui qui exerce l'invariant J3 -- une presence indisponible
/// s'affiche « inconnu », jamais « absent ».
class FauxPresenceClasse implements ServicePresence {
  /// Cree le faux.
  FauxPresenceClasse({this.lignes});

  /// Ce que la lecture rend. `null` signifie « indisponible ».
  List<PresenceParticipant>? lignes;

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async => lignes;
}

/// Les annonces d'observation, en memoire.
///
/// **Il remplace le PORT, pas le provider de flux** : la Classe Live passe par
/// `annoncesObservationProvider`, et c'est ce chemin-la que le test doit
/// emprunter, sans quoi il verifierait un cablage qu'il aurait lui-meme pose.
///
/// Les seances qui ne sont pas les siennes rendent une liste vide, exactement
/// comme le serveur : `annonces_observation` leve pour qui n'est pas
/// l'enseignant de la seance, et `AnnonceObservationSupabase` traduit ce refus
/// en « personne n'observe ».
class FauxAnnonceObservation implements PortAnnonceObservation {
  /// Cree le faux.
  FauxAnnonceObservation({this.lignes = const <AnnonceObservation>[]});

  /// Ce que le flux porte.
  List<AnnonceObservation> lignes;

  /// Les seances pour lesquelles un flux a ete demande.
  final List<String> demandes = <String>[];

  @override
  Stream<List<AnnonceObservation>> annonces(String sessionId) {
    demandes.add(sessionId);
    return Stream<List<AnnonceObservation>>.value(lignes);
  }
}

/// L'annonce cote ENFANT, en memoire.
///
/// Le vrai port interroge `annonce_observation_pour_moi` (`0040`), qui ne rend
/// que la ligne de l'appelant. Ce faux rend un booleen unique pour la meme
/// raison : un enfant n'a jamais acces qu'a SON propre etat, et rendre une
/// liste ici laisserait croire le contraire.
class FauxAnnonceObservationEnfant implements PortAnnonceObservationEnfant {
  /// Cree le faux.
  FauxAnnonceObservationEnfant({this.observe = false});

  /// Ce que le flux porte : vrai quand le tuteur de cet enfant regarde.
  bool observe;

  /// Les seances pour lesquelles un flux a ete demande.
  final List<String> demandes = <String>[];

  @override
  Stream<bool> monTuteurObserve(String sessionId) {
    demandes.add(sessionId);
    return Stream<bool>.value(observe);
  }
}

/// Le roster pedagogique, en memoire.
class FauxRosterEnseignant implements PortRosterEnseignant {
  /// Cree le faux.
  FauxRosterEnseignant({this.fiches = const <TeacherStudentProjection>[]});

  /// Les fiches rendues pour une seance.
  List<TeacherStudentProjection> fiches;

  @override
  Future<TeacherStudentProjection?> fiche({
    required String academyId,
    String? sessionId,
  }) async {
    for (final TeacherStudentProjection e in fiches) {
      if (e.academyId == academyId) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<List<TeacherStudentProjection>> rosterDeGroupe(String groupeId) async =>
      throw const EchecRoster(MotifEchecRoster.projectionAbsente);

  @override
  Future<List<TeacherStudentProjection>> rosterDeSeance(
    String sessionId,
  ) async => fiches;

  @override
  Stream<List<TeacherStudentProjection>> suivreRoster(String sessionId) =>
      Stream<List<TeacherStudentProjection>>.value(fiches);
}

/// Le rappel discret, en memoire.
///
/// Il enregistre les appels reussis pour qu'un test puisse constater qu'une
/// reussite **ne dit rien** : il n'y a pas d'autre facon de verifier une action
/// silencieuse que d'en mesurer l'effet hors de l'ecran.
class FauxRappelDiscret implements PortRappelDiscret {
  /// Cree le faux.
  FauxRappelDiscret({this.echec, this.restant});

  /// L'echec a lever, s'il y en a un.
  EchecRappel? echec;

  /// Ce que [cooldownRestant] rend.
  Duration? restant;

  /// Les rappels partis, par `(sessionId, academyId)`.
  final List<(String, String)> appels = <(String, String)>[];

  @override
  Duration get cooldown => const Duration(seconds: 45);

  @override
  Duration? cooldownRestant({
    required String sessionId,
    required String academyId,
  }) => restant;

  @override
  Future<void> rappeler({
    required String sessionId,
    required String academyId,
  }) async {
    final EchecRappel? refus = echec;
    if (refus != null) {
      throw refus;
    }
    appels.add((sessionId, academyId));
  }
}
