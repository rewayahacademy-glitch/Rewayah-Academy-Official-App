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
///   `EtatSalle.retabli` est le signal qui declenche une restauration d'etat.
///   Cet etat existe deja dans le socle precisement pour cela : son
///   commentaire dit qu'il doit se distinguer d'une premiere connexion pour que
///   l'ecran puisse « republier l'etat pedagogique en cours ».
///
/// ## Ce qu'il ne fait PAS, et pourquoi
///
/// Le socle expose **une** primitive de donnees : `presenterContenu`, qui porte
/// un `ContenuPresente` -- page, sourate, verset -- sur **un** sujet
/// (`contenu-presente`), en **diffusion**, en mode **fiable**, sans
/// destinataire.
///
/// Faire passer le protocole pedagogique par elle aurait ete possible et aurait
/// ete une faute : le mode d'affichage, la plage de travail, les plages
/// masquees et les marqueurs semantiques n'y tiennent pas. La classe suivrait
/// les tours de page en perdant silencieusement tout le reste -- une classe qui
/// suit la moitie de la lecon sans que rien ne le dise est pire qu'une
/// fonctionnalite annoncee comme non branchee.
///
/// Ce transport declare donc [DisponibiliteTransport.partiel] : le plan de
/// controle fonctionne, le plan de donnees leve
/// [MotifEchecTransport.primitiveEnvoiAbsente] tant qu'Agent Z n'a pas ajoute
/// la primitive demandee dans `TC_CONTRACT_REQUEST_F.md`. Le jour ou elle
/// existera, **seul ce fichier changera** : aucun autre fichier du lot F ne
/// connait LiveKit.
///
/// ## Le piege a connaitre avant d'ecrire cette implementation
///
/// **LiveKit ne dit pas, a la reception, par quel canal un paquet est
/// arrive.** Verifie dans `livekit_client 2.12.0` : `DataReceivedEvent` porte
/// exactement trois champs -- `participant`, `data`, `topic` -- et aucun mode
/// de livraison. A l'emission, `publishData(..., reliable: bool)` choisit bien
/// entre `RELIABLE` et `LOSSY`, mais l'information ne voyage pas jusqu'au
/// recepteur.
///
/// La seule facon de reconstituer [PaquetRealtime.canal] est donc de la porter
/// **dans le sujet** : deux sujets nommes, l'un pour le fiable, l'autre pour
/// l'ephemere, et l'adaptateur fait la correspondance dans les deux sens.
/// Le protocole, lui, continue de ne connaitre qu'un sujet et un canal : c'est
/// exactement ce qu'un adaptateur doit absorber. La mettre dans l'enveloppe du
/// message obligerait a decoder chaque paquet de pointeur avant de savoir
/// s'il nous concerne -- trente fois par seconde, pour rien.
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

  final StreamController<PaquetRealtime> _paquets =
      StreamController<PaquetRealtime>.broadcast();

  @override
  DisponibiliteTransport get disponibilite => DisponibiliteTransport.partiel;

  @override
  CapacitesTransport get capacites => _capacites;

  /// Le flux des paquets recus.
  ///
  /// **Vide tant que le core n'expose pas la reception de donnees brutes.**
  /// Un flux vide, et non une erreur : un abonne doit pouvoir s'abonner sans
  /// se proteger, et c'est [disponibilite] qui dit l'etat des lieux.
  @override
  Stream<PaquetRealtime> paquets() => _paquets.stream;

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
    // Le droit d'abord : il est signe, et le refuser ici evite d'annoncer une
    // primitive manquante a qui n'aurait de toute facon pas le droit d'emettre.
    if (!_capacites.peutPublierDonnees) {
      throw const EchecTransport(MotifEchecTransport.droitRefuse);
    }
    if (_moteur.etatCourant == EtatSalle.absent ||
        _moteur.etatCourant == EtatSalle.echec) {
      throw const EchecTransport(MotifEchecTransport.horsSalle);
    }
    throw EchecTransport(
      MotifEchecTransport.primitiveEnvoiAbsente,
      'sujet $sujet, canal ${canal.name}'
      '${destinataires.isEmpty ? '' : ', ${destinataires.length} destinataire(s)'}',
    );
  }

  @override
  Future<void> liberer() async {
    await _paquets.close();
  }
}
