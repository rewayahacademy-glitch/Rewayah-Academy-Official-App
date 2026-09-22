import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// Un moteur de salle en memoire, reduit a ce que l'adaptateur du lot F lit.
///
/// **Il ne simule pas WebRTC** : il rejoue ce que le vrai moteur publie -- un
/// etat, des paquets -- et enregistre ce qu'on lui demande de publier.
/// Depuis le lot 2, il porte la primitive generale de donnees du socle
/// (`publierDonnees`, `donneesRecues`), que l'adaptateur emploie.
class FauxMoteurSalle implements VideoSessionProvider {
  final StreamController<EtatSalle> _etats =
      StreamController<EtatSalle>.broadcast();
  final StreamController<PaquetDonnees> _donnees =
      StreamController<PaquetDonnees>.broadcast();

  EtatSalle _etat = EtatSalle.absent;

  /// Les contenus presentes par le protocole coranique du socle.
  ///
  /// Le lot F ne s'en sert pas : il a son propre sujet. La liste est la pour
  /// **prouver** qu'il ne passe jamais par cette primitive.
  final List<ContenuPresente> presentes = <ContenuPresente>[];

  /// Les paquets publies par la primitive generale, dans l'ordre.
  final List<PublicationEnregistree> publies = <PublicationEnregistree>[];

  /// Ce que `publierDonnees` doit lever, quand on teste un refus du moteur.
  EchecPublicationDonnees? refuserPublication;

  /// Pose un etat de salle et le publie.
  void poser(EtatSalle etat) {
    _etat = etat;
    if (!_etats.isClosed) {
      _etats.add(etat);
    }
  }

  /// Fait arriver un paquet du canal de donnees, comme le ferait le reseau.
  void recevoir(PaquetDonnees paquet) {
    if (!_donnees.isClosed) {
      _donnees.add(paquet);
    }
  }

  /// Ferme les flux.
  Future<void> fermer() async {
    await _etats.close();
    await _donnees.close();
  }

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
  Future<void> reglerCamera({required bool actif}) async {}

  @override
  Future<void> reglerAudioSeul({required bool actif}) async {}

  @override
  Widget? renduVideo(String identite) => null;

  @override
  Future<void> liberer() => fermer();

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
  }) async {
    final EchecPublicationDonnees? refus = refuserPublication;
    if (refus != null) {
      throw refus;
    }
    publies.add(
      PublicationEnregistree(
        sujet: sujet,
        charge: charge,
        fiable: fiable,
        destinataires: destinataires,
      ),
    );
  }
}

/// Une publication telle que le faux moteur l'a recue.
class PublicationEnregistree {
  /// Cree l'enregistrement.
  const PublicationEnregistree({
    required this.sujet,
    required this.charge,
    required this.fiable,
    required this.destinataires,
  });

  /// Le sujet demande.
  final String sujet;

  /// Les octets.
  final List<int> charge;

  /// Le mode demande.
  final bool fiable;

  /// Les destinataires cibles, vide pour une diffusion.
  final List<String> destinataires;
}
