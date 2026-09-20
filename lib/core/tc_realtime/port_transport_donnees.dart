import 'package:flutter/foundation.dart';

import 'port_realtime_pedagogique.dart';

/// Ce que le transport disponible sait reellement faire.
///
/// Le motif est celui d'Agent C pour `DisponibiliteLayout` : **on declare le
/// manque, on ne fabrique pas une capacite qu'on n'a pas.** Un transport
/// partiel qui se presenterait comme complet produirait une classe ou la moitie
/// des gestes du professeur n'arrivent nulle part, sans qu'aucun message ne le
/// dise.
enum DisponibiliteTransport {
  /// Les deux canaux et le ciblage sont disponibles.
  complet,

  /// Une partie seulement : voir `AdaptateurTransportLiveKit`.
  partiel,

  /// Aucun transport : hors salle, ou moteur non connecte.
  indisponible,
}

/// Pourquoi un envoi n'a pas pu avoir lieu.
enum MotifEchecTransport {
  /// Le jeton signe n'accorde pas `can_publish_data` a l'appelant.
  ///
  /// **Ce n'est pas cette ligne qui l'empeche** : la barriere reelle est le
  /// jeton, que le serveur LiveKit fait respecter. Le refus cote client evite
  /// seulement qu'un ecran croie avoir emis quelque chose.
  droitRefuse,

  /// Aucune salle ouverte.
  horsSalle,

  /// Le transport n'expose aucune primitive d'envoi de donnees.
  ///
  /// C'est l'etat du socle a la baseline `0071557` : `VideoSessionProvider`
  /// sait presenter un pointeur de contenu coranique et rien d'autre. La
  /// signature Dart attendue est ecrite dans `TC_CONTRACT_REQUEST_F.md`.
  primitiveEnvoiAbsente,

  /// Le canal ephemere n'existe pas sur ce transport.
  canalEphemereAbsent,

  /// L'envoi adresse a un participant precis n'existe pas sur ce transport.
  ciblageAbsent,

  /// Ce sujet n'est pas transportable par ce transport.
  sujetNonTransportable,

  /// Le transport a refuse le paquet.
  reseau,
}

/// L'echec d'un envoi.
class EchecTransport implements Exception {
  /// Cree un echec.
  const EchecTransport(this.motif, [this.detail]);

  /// Ce qui a empeche l'envoi.
  final MotifEchecTransport motif;

  /// Une precision facultative, pour le journal de developpement seulement.
  final String? detail;

  @override
  String toString() =>
      'EchecTransport($motif${detail == null ? '' : ', $detail'})';
}

/// L'etat du transport, vu du protocole.
///
/// Volontairement plus court que `EtatSalle` : le protocole n'a besoin de
/// distinguer que trois situations, et **[retabli] est celle qui compte** --
/// c'est la seule qui declenche une restauration d'etat depuis le backend.
enum EtatTransport {
  /// Pas de salle, ou salle quittee.
  absent,

  /// Connecte, les paquets passent.
  ouvert,

  /// Le lien est perdu, le transport tente de le retablir.
  interrompu,

  /// Le lien vient d'etre retabli apres une coupure.
  retabli,
}

/// Ce que le jeton signe accorde a l'appelant, reduit a ce que le protocole
/// en a besoin.
///
/// **Aucune de ces valeurs n'est decidee ici.** Elles sont recopiees depuis
/// `CapacitesSalle`, que `create-room-token` a signee d'apres
/// `autoriser_jeton_video()`.
@immutable
class CapacitesTransport {
  /// Cree un jeu de capacites de transport.
  const CapacitesTransport({
    required this.identiteLocale,
    required this.peutPublier,
    required this.peutPublierDonnees,
    required this.invisible,
  });

  /// L'identite du participant local, telle que le jeton l'a inscrite.
  ///
  /// C'est le `profile_id`. Il n'y a **aucune autre donnee d'identite** dans
  /// le transport : ni nom, ni courriel, ni telephone, ni rien de la famille.
  final String identiteLocale;

  /// Le participant peut publier au moins sa voix.
  final bool peutPublier;

  /// Le participant peut publier sur le canal de donnees.
  final bool peutPublierDonnees;

  /// Le participant n'apparait dans la liste de personne.
  final bool invisible;
}

/// Un paquet recu du canal de donnees.
@immutable
class PaquetRealtime {
  /// Cree un paquet.
  const PaquetRealtime({
    required this.sujet,
    required this.charge,
    required this.canal,
    this.emetteurIdentite,
  });

  /// Le sujet nomme du paquet.
  final String sujet;

  /// Les octets recus, tels quels.
  final List<int> charge;

  /// Le canal par lequel il est arrive.
  final CanalFiabilite canal;

  /// L'identite de l'emetteur, quand le transport la donne.
  ///
  /// **Elle ne decide d'aucun droit** : le message porte deja son emetteur, et
  /// le droit d'emettre est tenu par le jeton signe cote serveur.
  final String? emetteurIdentite;
}

/// La primitive d'envoi et de reception de donnees d'une seance.
///
/// **Port produit par Agent F, et raison d'etre du lot.** Le socle
/// (`VideoSessionProvider`) sait transporter **un** message pedagogique -- le
/// pointeur de contenu coranique -- sur **un** canal, en diffusion, en mode
/// fiable. Il n'expose ni le canal ephemere, ni l'envoi adresse, ni un sujet
/// libre. La separation fiable / ephemere exigee par la mission demande donc
/// une extension du contrat core, dont la signature exacte est ecrite dans
/// `TC_CONTRACT_REQUEST_F.md`.
///
/// En attendant, tout le lot F est construit **contre ce port**, jamais contre
/// LiveKit : `TransportMemoire` le sert pour les tests,
/// `AdaptateurTransportLiveKit` le sert partiellement au-dessus du moteur
/// existant, et l'implementation complete sera un troisieme adaptateur le jour
/// ou le core aura la primitive. Aucun autre fichier du lot ne change alors.
///
/// **Aucun nouveau fournisseur WebRTC, aucune seconde `Room`** : l'adaptateur
/// se pose au-dessus de `moteurSalleProvider`, qui reste le seul moteur du
/// produit.
abstract class PortTransportDonnees {
  /// Ce que ce transport sait reellement faire.
  DisponibiliteTransport get disponibilite;

  /// Les paquets recus, tous sujets confondus.
  ///
  /// Le filtrage par sujet appartient a l'appelant : un transport qui filtrerait
  /// lui-meme empecherait un second protocole de cohabiter sur le meme canal.
  Stream<PaquetRealtime> paquets();

  /// L'etat du transport.
  Stream<EtatTransport> etats();

  /// Les capacites signees de l'appelant, ou `null` si elles sont inconnues.
  ///
  /// `null` **n'est pas « tout est permis »** : l'appelant doit le traiter
  /// comme « aucun droit connu », c'est-a-dire le repli sur : ne rien proposer.
  CapacitesTransport? get capacites;

  /// Pose un paquet sur le canal demande.
  ///
  /// [destinataires] vide vaut diffusion a toute la salle. Leve
  /// [EchecTransport] quand l'envoi ne peut pas avoir lieu -- **jamais un
  /// silence** : un appelant qui croit avoir emis un rappel discret alors que
  /// rien n'est parti est precisement ce que CONTRACTS section 12 interdit.
  Future<void> envoyer({
    required String sujet,
    required List<int> charge,
    required CanalFiabilite canal,
    List<String> destinataires,
  });

  /// Libere abonnements et controleurs.
  Future<void> liberer();
}
