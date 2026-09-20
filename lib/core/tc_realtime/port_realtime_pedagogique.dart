import 'package:flutter/foundation.dart';

/// La fiabilite demandee au transport (CONTRACTS section 9).
///
/// **C'est la decision structurante du lot F.** Pendant un geste -- un doigt
/// qui suit une ligne, un trait qui se dessine -- ce qui compte est la
/// fraicheur : perdre un paquet ne coute qu'un sursaut, et exiger une garantie
/// de livraison pour trente paquets par seconde encombrerait le canal qui porte
/// les tours de page. A la fin du geste, plus rien ne peut se perdre.
///
/// Bloquer le canal fiable pour un pointeur est nomme comme une faute dans la
/// mission du lot : les deux canaux ne se melangent jamais.
enum CanalFiabilite {
  /// Ordonne et garanti.
  fiable,

  /// Perte acceptee, jamais persiste.
  ephemere,
}

/// Les capacites projetees pour l'appelant, derivees du jeton serveur.
///
/// **Jamais calculees ici.** Aucune de ces quatre valeurs ne se deduit d'un
/// role lu cote client : elles projettent les drapeaux que `autoriser_jeton_video()`
/// a calcules en base et que `create-room-token` a signes. Le contrat du socle
/// est explicite : « un client modifie ne gagne rien a les retourner, le
/// serveur LiveKit refusera la publication ».
@immutable
class CapacitesPedagogiques {
  /// Cree un jeu de capacites.
  const CapacitesPedagogiques({
    required this.peutPiloterSupport,
    required this.peutAnnoter,
    required this.peutEmettreNudge,
    required this.estObservateurSilencieux,
  });

  /// Peut changer le support actif, la page, le focus.
  final bool peutPiloterSupport;

  /// Peut poser une annotation visible des autres.
  final bool peutAnnoter;

  /// Peut envoyer un rappel discret.
  final bool peutEmettreNudge;

  /// Observe sans rien emettre : tuteur, controleur, admin incognito.
  final bool estObservateurSilencieux;

  @override
  bool operator ==(Object other) =>
      other is CapacitesPedagogiques &&
      other.peutPiloterSupport == peutPiloterSupport &&
      other.peutAnnoter == peutAnnoter &&
      other.peutEmettreNudge == peutEmettreNudge &&
      other.estObservateurSilencieux == estObservateurSilencieux;

  @override
  int get hashCode => Object.hash(
    peutPiloterSupport,
    peutAnnoter,
    peutEmettreNudge,
    estObservateurSilencieux,
  );
}

/// Un message pedagogique transporte par le canal de donnees.
///
/// **Une enveloppe plate : un type, une seance, un emetteur, une charge
/// serialisable, un instant.** La forme est celle qu'Agent D a declaree en
/// double local dans `TC_CONTRACT_REQUEST_D.md` et contre laquelle il a deja
/// ecrit `DiffusionOutils` ; Agent F, producteur du contrat, la reprend a
/// l'identique plutot que d'imposer une hierarchie scellee qui obligerait D a
/// tout reecrire pour un gain nul.
///
/// Elle a par ailleurs la bonne propriete pour un protocole : **le transport
/// n'a pas a connaitre les types de messages qu'il porte.** Agent D peut
/// ajouter `tc.outils.masquage` sans qu'une seule ligne du lot F change.
///
/// **Aucune donnee sensible n'y voyage.** Ni telephone, ni courriel, ni
/// identite de famille : [emetteurProfilId] est l'identifiant de participant
/// que le jeton signe porte deja, et les charges du protocole ne transportent
/// que des positions, des plages et des identifiants d'academie.
@immutable
class MessagePedagogique {
  /// Cree un message.
  const MessagePedagogique({
    required this.type,
    required this.sessionId,
    required this.emetteurProfilId,
    required this.charge,
    required this.emisLeUtc,
  });

  /// Le type d'evenement, qui decide de la lecture de [charge].
  final String type;

  /// La seance concernee.
  final String sessionId;

  /// Le profil qui emet.
  final String emetteurProfilId;

  /// La charge utile, serialisable.
  final Map<String, dynamic> charge;

  /// L'instant d'emission, en UTC.
  ///
  /// **Il date le message, il ne l'ordonne pas.** L'ordre de l'etat partage est
  /// porte par `SharedContentState.revision`, parce que deux appareils n'ont
  /// pas la meme horloge. Le socle tient deja ce raisonnement pour
  /// `ContenuPresente.emisLe`.
  final DateTime emisLeUtc;
}

/// Le transport des messages pedagogiques d'une seance.
///
/// **Contrat produit par Agent F** (CONTRACTS section 9), consomme par D pour
/// les traits et les marqueurs, par E pour le rappel discret et la coque, et
/// par Q.
///
/// Il ne cree **aucun** fournisseur WebRTC : il se pose au-dessus du seul
/// moteur du produit (`moteurSalleProvider`) par un adaptateur.
abstract class PortRealtimePedagogique {
  /// Messages fiables et ordonnes.
  ///
  /// Etat partage, mode, eleve actif, trait termine, rappel discret. Les
  /// doublons y sont ecartes : le meme message livre deux fois n'est rendu
  /// qu'une seule.
  Stream<MessagePedagogique> messagesFiables(String sessionId);

  /// Messages ephemeres, perte acceptee.
  ///
  /// Pointeur et apercu de trait. **Aucune deduplication, aucun ordonnancement,
  /// aucune persistance** : un paquet en double y coute moins cher qu'une
  /// memoire tenue pour rien.
  Stream<MessagePedagogique> messagesEphemeres(String sessionId);

  /// Emet un message a toute la seance.
  Future<void> emettre(
    MessagePedagogique message, {
    required CanalFiabilite canal,
  });

  /// Emet un message adresse a un seul participant.
  ///
  /// Le rappel discret l'emploie. **Reussite silencieuse** : un message
  /// n'apparait que si l'envoi echoue (CONTRACTS section 12,
  /// `PortRappelDiscret`), donc cette methode leve sur echec plutot que
  /// d'avaler.
  Future<void> emettreCible(
    MessagePedagogique message, {
    required String destinataireProfilId,
    required CanalFiabilite canal,
  });

  /// Les capacites projetees pour l'appelant.
  Future<CapacitesPedagogiques> capacites(String sessionId);
}
