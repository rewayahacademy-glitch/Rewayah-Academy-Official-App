import 'dart:async';

import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';

/// Le transport de l'etat « aucune salle ouverte ».
///
/// **Ce n'est pas un bouchon de test, c'est l'etat normal du produit hors
/// classe.** L'application passe l'essentiel de son temps sans salle : le
/// Groupe, la Bibliotheque et l'Accueil n'ont aucun canal de donnees, et le
/// protocole pedagogique doit pouvoir y etre demande sans que rien n'explose.
///
/// Il dit **non** a tout, et il le dit de facon nommee :
/// [DisponibiliteTransport.indisponible] plutot qu'un flux muet, et
/// [MotifEchecTransport.horsSalle] plutot qu'un silence. Un ecran qui
/// proposerait de presenter un support hors classe est un defaut ; un ecran qui
/// croirait avoir presente quelque chose en est un plus grave.
///
/// C'est le defaut de `portTransportDonneesProvider`. Agent E le remplace par
/// `AdaptateurTransportLiveKit` a l'entree en salle.
class TransportIndisponible implements PortTransportDonnees {
  /// Cree le transport nul.
  const TransportIndisponible();

  @override
  DisponibiliteTransport get disponibilite =>
      DisponibiliteTransport.indisponible;

  /// Aucun droit connu, et non « tous les droits » : hors salle, le jeton
  /// signe n'existe pas.
  @override
  CapacitesTransport? get capacites => null;

  @override
  Stream<PaquetRealtime> paquets() => const Stream<PaquetRealtime>.empty();

  /// Aucune transition a annoncer : hors salle, il ne se passe rien.
  ///
  /// `Stream.empty()` et non `Stream.value(absent)` pour deux raisons. Emettre
  /// `absent` ressemblerait a une **transition** -- donc a une coupure -- alors
  /// qu'il ne s'est rien passe ; et `Stream.value` ne se laisse ecouter qu'une
  /// fois, la ou `Stream.empty` accepte plusieurs abonnes. Un service qui suit
  /// deux seances tomberait sur « Stream has already been listened to ».
  @override
  Stream<EtatTransport> etats() => const Stream<EtatTransport>.empty();

  @override
  Future<void> envoyer({
    required String sujet,
    required List<int> charge,
    required CanalFiabilite canal,
    List<String> destinataires = const <String>[],
  }) async => throw const EchecTransport(MotifEchecTransport.horsSalle);

  @override
  Future<void> liberer() async {}
}
