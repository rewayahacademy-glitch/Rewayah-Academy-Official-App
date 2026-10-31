import 'dart:async';

import '../video/video_session_provider.dart';
import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';

/// L'adaptateur du protocole pedagogique au-dessus du moteur temps reel
/// existant.
///
/// **Aucune seconde `Room`, aucun second fournisseur WebRTC.** Il ne fait que
/// lire `VideoSessionProvider`, qui reste le seul moteur du produit
/// (`moteurSalleProvider`, Provider racine). Il n'importe pas `livekit_client`
/// et ne recopie aucune ligne du SDK.
///
/// ## Ce qu'il reutilise reellement
///
/// - les **capacites signees** du jeton (`AccesSalle.capacites`), calculees par
///   `autoriser_jeton_video()` et posees par `create-room-token` ;
/// - l'**etat de connexion** (`VideoSessionProvider.etats`), dont
///   `EtatSalle.retabli` est le signal qui declenche une restauration d'etat ;
/// - S1 (24/10/2026) : la primitive de donnees du moteur,
///   `publierDonnees` a l'emission et `donneesRecues` a la reception. Le
///   canal (fiable ou ephemere) voyage dans le sujet : c'est le moteur qui
///   pose et relit le suffixe ([suffixeSujetEphemere]), l'adaptateur ne fait
///   que traduire un booleen en [CanalFiabilite], dans les deux sens.
///
/// Le transport est donc [DisponibiliteTransport.complet] : plan de controle
/// et plan de donnees. Le droit d'emettre reste celui du jeton signe ; un
/// refus du moteur remonte en [EchecTransport], jamais avale.
class AdaptateurTransportLiveKit implements PortTransportDonnees {
  /// Cree l'adaptateur pour une salle deja ouverte.
  ///
  /// [profilLocalId] est le `profile_id` de l'appelant. Il est passe plutot que
  /// lu du moteur parce que `AccesSalle` ne porte pas d'identite et que
  /// l'appelant la connait deja : c'est celle de sa propre session Supabase.
  /// Le deduire d'un participant marque `estLocal` obligerait a attendre un
  /// premier evenement, donc a rendre [capacites] asynchrone pour rien.
  factory AdaptateurTransportLiveKit({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required String profilLocalId,
  }) => AdaptateurTransportLiveKit._(
    moteur: moteur,
    capacites: _capacitesDe(acces, profilLocalId),
  );

  AdaptateurTransportLiveKit._({
    required this._moteur,
    required this._capacites,
  });

  /// Recopie les capacites signees du jeton, sans en deduire aucune.
  ///
  /// **Recopie, jamais deduction.** Aucun des quatre drapeaux ne se calcule
  /// ici : ils viennent de `autoriser_jeton_video()` et sont signes par
  /// `create-room-token`.
  static CapacitesTransport _capacitesDe(AccesSalle acces, String profilId) =>
      CapacitesTransport(
        identiteLocale: profilId,
        peutPublier: acces.capacites.peutPublier,
        peutPublierDonnees: acces.capacites.peutPublierDonnees,
        invisible: acces.capacites.invisible,
      );

  final VideoSessionProvider _moteur;
  final CapacitesTransport _capacites;

  @override
  DisponibiliteTransport get disponibilite => DisponibiliteTransport.complet;

  @override
  CapacitesTransport get capacites => _capacites;

  /// Le flux des paquets recus, tous sujets confondus : le protocole filtre
  /// le sien (`ServiceRealtimePedagogique`).
  @override
  Stream<PaquetRealtime> paquets() => _moteur.donneesRecues.map(
    (PaquetDonnees paquet) => PaquetRealtime(
      sujet: paquet.sujet,
      charge: paquet.charge,
      canal: paquet.fiable ? CanalFiabilite.fiable : CanalFiabilite.ephemere,
      emetteurIdentite: paquet.emetteurIdentite,
    ),
  );

  @override
  Stream<EtatTransport> etats() => _moteur.etats.map(_traduire);

  /// Traduit l'etat de salle en etat de transport.
  ///
  /// `instable` devient [EtatTransport.ouvert] et non [EtatTransport.interrompu] :
  /// le commentaire du socle est explicite, un lien instable est un
  /// avertissement, « la seance continue, rien ne se demonte ». Le traiter
  /// comme une coupure declencherait une restauration d'etat a chaque
  /// degradation de reseau.
  EtatTransport _traduire(EtatSalle etat) => switch (etat) {
    EtatSalle.absent => EtatTransport.absent,
    EtatSalle.connexion => EtatTransport.absent,
    EtatSalle.connecte => EtatTransport.ouvert,
    EtatSalle.instable => EtatTransport.ouvert,
    EtatSalle.reconnexion => EtatTransport.interrompu,
    EtatSalle.retabli => EtatTransport.retabli,
    EtatSalle.echec || EtatSalle.retire => EtatTransport.absent,
  };

  @override
  Future<void> envoyer({
    required String sujet,
    required List<int> charge,
    required CanalFiabilite canal,
    List<String> destinataires = const <String>[],
  }) async {
    // Le droit d'abord : il est signe, et le refuser ici evite un aller
    // inutile vers le moteur.
    if (!_capacites.peutPublierDonnees) {
      throw const EchecTransport(MotifEchecTransport.droitRefuse);
    }
    if (_moteur.etatCourant == EtatSalle.absent ||
        _moteur.etatCourant == EtatSalle.echec ||
        _moteur.etatCourant == EtatSalle.retire) {
      throw const EchecTransport(MotifEchecTransport.horsSalle);
    }
    try {
      await _moteur.publierDonnees(
        sujet: sujet,
        charge: charge,
        fiable: canal == CanalFiabilite.fiable,
        destinataires: destinataires,
      );
    } on EchecPublicationDonnees catch (echec) {
      throw EchecTransport(switch (echec.motif) {
        MotifEchecPublication.droitRefuse => MotifEchecTransport.droitRefuse,
        MotifEchecPublication.horsSalle => MotifEchecTransport.horsSalle,
        MotifEchecPublication.transport => MotifEchecTransport.reseau,
      }, echec.detail);
    }
  }

  @override
  Future<void> liberer() async {}
}
