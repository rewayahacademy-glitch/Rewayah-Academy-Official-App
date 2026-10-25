import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Un moteur de salle sans SDK, pilote a la main.
///
/// **Le patron est celui de `test/features/salle_test.dart` (lignes 72-74)** :
/// la salle se prouve avec un faux moteur injecte, jamais avec LiveKit. Ce faux
/// vit sous `test/teaching_core/f/faux/` parce que `test/support/harnais.dart`
/// est interdit aux agents Teaching Core (decision D-06).
///
/// Il n'implemente que ce que le lot F lit reellement du contrat : l'etat de
/// connexion. Le reste rend des flux vides ou ne fait rien -- un faux qui
/// simulerait ce que le test n'observe pas invite a croire qu'on l'a eprouve.
class FauxMoteurSalle implements VideoSessionProvider {
  /// Cree un faux moteur, hors salle par defaut.
  FauxMoteurSalle();

  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();

  EtatSalle _etat = EtatSalle.absent;

  /// Les contenus presentes par le protocole coranique du socle.
  ///
  /// Le lot F ne s'en sert pas : il a son propre sujet. La liste est la pour
  /// **prouver** qu'il ne passe jamais par cette primitive.
  final List<ContenuPresente> presentes = <ContenuPresente>[];

  /// Pose un etat de salle et le publie.
  void poser(EtatSalle etat) {
    _etat = etat;
    if (!_etats.isClosed) {
      _etats.add(etat);
    }
  }

  /// Ferme les flux.
  Future<void> fermer() => _etats.close();

  @override
  EtatSalle get etatCourant => _etat;

  @override
  Stream<EtatSalle> get etats => _etats.stream;

  @override
  Stream<List<ParticipantSalle>> get participants =>
      const Stream<List<ParticipantSalle>>.empty();

  @override
  Stream<QualiteLien> get qualite => const Stream<QualiteLien>.empty();

  @override
  Stream<ContenuPresente> get contenusPresentes =>
      const Stream<ContenuPresente>.empty();

  @override
  Future<void> presenterContenu(ContenuPresente contenu) async {
    presentes.add(contenu);
  }

  @override
  Future<void> rejoindre(AccesSalle acces) async => poser(EtatSalle.connecte);

  @override
  Future<void> quitter() async => poser(EtatSalle.absent);

  @override
  Future<void> reglerMicro({required bool actif}) async {}

  @override
  String? get erreurCameraEntree => null;

  @override
  Future<void> reglerCamera({required bool actif}) async {}

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {}

  @override
  Widget? renduVideo(String identite) => null;

  @override
  Future<void> liberer() => fermer();

  @override
  Stream<PaquetDonnees> get donneesRecues => _donnees.stream;

  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  /// S1 : les paquets passes a [publierDonnees], dans l'ordre.
  final List<PaquetDonnees> publies = <PaquetDonnees>[];

  /// S1 : simule la reception d'un paquet de la salle.
  void recevoir(PaquetDonnees paquet) => _donnees.add(paquet);

  @override
  AccesSalle? get accesCourant => null;

  @override
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  }) async {
    publies.add(PaquetDonnees(sujet: sujet, charge: charge, fiable: fiable));
  }
}
