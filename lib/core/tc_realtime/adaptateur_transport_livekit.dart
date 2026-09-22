import 'dart:async';

import '../video/video_session_provider.dart';
import 'port_realtime_pedagogique.dart';
import 'port_transport_donnees.dart';

/// L'adaptateur du protocole pedagogique au-dessus du moteur temps reel
/// existant.
///
/// **Aucune seconde `Room`, aucun second fournisseur WebRTC.** Il ne fait que
/// lire et ecrire `VideoSessionProvider`, qui reste le seul moteur du produit
/// (`moteurSalleProvider`, Provider racine). Il n'importe pas `livekit_client`
/// et ne recopie aucune ligne du SDK.
///
/// ## Ce qu'il reutilise
///
/// - les **capacites signees** du jeton (`AccesSalle.capacites`), calculees par
///   `autoriser_jeton_video()` et posees par `create-room-token` ;
/// - l'**etat de connexion** (`VideoSessionProvider.etats`), dont
///   `EtatSalle.retabli` est le signal qui declenche une restauration d'etat ;
/// - la **primitive generale de donnees** du socle,
///   `VideoSessionProvider.publierDonnees` / `donneesRecues`, ajoutee par le
///   lot PROTECTED (`TC_CONTRACT_REQUEST_F.md` section 1). C'est elle qui a
///   fait passer ce transport de `partiel` a `complet` : seul ce fichier a
///   change, exactement comme sa premiere version le promettait.
///
/// ## Le piege du canal, et comment il est absorbe
///
/// LiveKit ne dit pas, a la reception, par quel canal un paquet est arrive
/// (`DataReceivedEvent` porte `participant`, `data`, `topic`, rien d'autre).
/// Le socle a donc pose la convention : **un sujet qui finit par
/// [suffixeSujetEphemere] a voyage en mode non fiable**, et il renseigne
/// `PaquetDonnees.fiable` a partir de cela. L'adaptateur fait la correspondance
/// dans les deux sens ; le protocole, lui, continue de ne connaitre qu'un sujet
/// et un canal.
class AdaptateurTransportLiveKit implements PortTransportDonnees {
  /// Cree l'adaptateur pour une salle deja ouverte.
  ///
  /// [profilLocalId] est le `profile_id` de l'appelant. Il est passe plutot que
  /// lu du moteur parce que `AccesSalle` ne porte pas d'identite et que
  /// l'appelant la connait deja : c'est celle de sa propre session Supabase.
  factory AdaptateurTransportLiveKit({
    required VideoSessionProvider moteur,
    required AccesSalle acces,
    required String profilLocalId,
  }) => AdaptateurTransportLiveKit._(
    moteur: moteur,
    capacites: _capacitesDe(acces, profilLocalId),
  );

  AdaptateurTransportLiveKit._({
    required VideoSessionProvider moteur,
    required CapacitesTransport capacites,
  }) : _moteur = moteur, // ignore: prefer_initializing_formals
       _capacites = capacites; // ignore: prefer_initializing_formals

  /// Recopie les capacites signees du jeton, sans en deduire aucune.
  static CapacitesTransport _capacitesDe(AccesSalle acces, String profilId) =>
      CapacitesTransport(
        identiteLocale: profilId,
        peutPublier: acces.capacites.peutPublier,
        peutPublierDonnees: acces.capacites.peutPublierDonnees,
        invisible: acces.capacites.invisible,
      );

  final VideoSessionProvider _moteur;
  final CapacitesTransport _capacites;

  bool _libere = false;

  @override
  DisponibiliteTransport get disponibilite => DisponibiliteTransport.complet;

  @override
  CapacitesTransport get capacites => _capacites;

  /// Les paquets recus, tous sujets confondus, dans le vocabulaire du protocole.
  ///
  /// Le socle relaie **tout** paquet du canal de donnees, y compris le sien
  /// (`contenu-presente`) : le filtrage par sujet appartient a l'appelant, et
  /// `ServiceRealtimePedagogique` le fait deja.
  @override
  Stream<PaquetRealtime> paquets() => _moteur.donneesRecues.map(
    (PaquetDonnees p) => PaquetRealtime(
      sujet: _sansSuffixe(p.sujet),
      charge: p.charge,
      canal: p.fiable ? CanalFiabilite.fiable : CanalFiabilite.ephemere,
      emetteurIdentite: p.emetteurIdentite,
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
    EtatSalle.echec => EtatTransport.absent,
  };

  @override
  Future<void> envoyer({
    required String sujet,
    required List<int> charge,
    required CanalFiabilite canal,
    List<String> destinataires = const <String>[],
  }) async {
    // Le droit d'abord : il est signe, et le refuser ici evite un aller-retour
    // vers un moteur qui refuserait de toute facon.
    if (!_capacites.peutPublierDonnees) {
      throw const EchecTransport(MotifEchecTransport.droitRefuse);
    }
    if (_libere ||
        _moteur.etatCourant == EtatSalle.absent ||
        _moteur.etatCourant == EtatSalle.echec) {
      throw const EchecTransport(MotifEchecTransport.horsSalle);
    }
    try {
      await _moteur.publierDonnees(
        sujet: canal == CanalFiabilite.ephemere
            ? '$sujet$suffixeSujetEphemere'
            : sujet,
        charge: charge,
        fiable: canal == CanalFiabilite.fiable,
        destinataires: destinataires,
      );
    } on EchecPublicationDonnees catch (e) {
      throw EchecTransport(switch (e.motif) {
        MotifEchecPublication.droitRefuse => MotifEchecTransport.droitRefuse,
        MotifEchecPublication.horsSalle => MotifEchecTransport.horsSalle,
        MotifEchecPublication.transport => MotifEchecTransport.reseau,
      }, e.detail);
    }
  }

  @override
  Future<void> liberer() async {
    // Le flux de paquets est celui du moteur : on ne le ferme pas, il ne nous
    // appartient pas. Ce drapeau suffit a refuser tout envoi ulterieur.
    _libere = true;
  }

  static String _sansSuffixe(String sujet) =>
      sujet.endsWith(suffixeSujetEphemere)
      ? sujet.substring(0, sujet.length - suffixeSujetEphemere.length)
      : sujet;
}
