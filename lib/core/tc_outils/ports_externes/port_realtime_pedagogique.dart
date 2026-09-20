// TC-STUB-PORT: canonique = lib/core/tc_realtime/port_realtime_pedagogique.dart (Agent F)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 9.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// DOUBLE LOCAL DECLARE, voir TC_CONTRACT_REQUEST_D.md section 2 :
// `MessagePedagogique` est annonce comme contrat d'Agent F (CONTRACTS section 9,
// puis section 17) mais **aucune signature n'en est donnee nulle part**. Le port
// ci-dessous ne peut donc pas compiler sans une forme de message. Celle qui suit
// est un double local, ecrit au plus proche de l'usage reel (un type, une
// session, un emetteur, une charge serialisable, un instant UTC). Agent D ne
// s'en sert QUE dans `evenements_outils.dart`, dans une seule fonction de
// conversion : quand la forme canonique arrivera, un seul endroit changera.
//
// `ModeAffichagePartage` est en revanche copie a l'identique du contrat.

import 'package:flutter/foundation.dart';

/// La fiabilite demandee au transport.
///
/// Pendant le geste, on accepte de perdre un paquet : ce qui compte est la
/// fraicheur. A la fin du trait, on ne peut plus rien perdre.
enum CanalFiabilite {
  /// Ordonne et garanti.
  fiable,

  /// Perte acceptee, jamais persiste.
  ephemere,
}

/// Le mode d'affichage du support partage.
enum ModeAffichagePartage {
  /// Page fidele de l'edition : la mise en page est figee.
  page,

  /// Verset reflowable : le texte se recompose avec la largeur.
  verse,

  /// Support dirige, chrome reduit.
  focus,
}

/// Les capacites projetees pour l'appelant, derivees du jeton serveur.
///
/// **Jamais calculees ici.** Le Teaching Dock les lit, il ne les deduit pas
/// d'un role.
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
}

/// Un message pedagogique transporte par le canal de donnees.
///
/// **DOUBLE LOCAL** : voir l'en-tete de ce fichier.
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
  final DateTime emisLeUtc;
}

/// Le transport des messages pedagogiques d'une seance.
///
/// **Agent D ne transporte pas lui-meme les strokes** : il convertit ses
/// evenements en messages et les confie a ce port.
abstract class PortRealtimePedagogique {
  /// Messages fiables et ordonnes.
  Stream<MessagePedagogique> messagesFiables(String sessionId);

  /// Messages ephemeres, perte acceptee.
  Stream<MessagePedagogique> messagesEphemeres(String sessionId);

  /// Emet un message a toute la seance.
  Future<void> emettre(
    MessagePedagogique message, {
    required CanalFiabilite canal,
  });

  /// Emet un message adresse a un seul participant.
  Future<void> emettreCible(
    MessagePedagogique message, {
    required String destinataireProfilId,
    required CanalFiabilite canal,
  });

  /// Les capacites projetees pour l'appelant.
  Future<CapacitesPedagogiques> capacites(String sessionId);
}
