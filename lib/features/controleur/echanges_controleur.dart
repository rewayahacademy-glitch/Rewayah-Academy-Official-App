// Echanges avec l'administration (CTR-04, CT-6) : le modele des fils et le
// port de lecture et d'envoi.
//
// Un fil par mission seulement en V1 (UX_REVIEW_08 question 8) : il nait de
// « Ecrire a l'administration » ou de l'administration. Son titre est la
// Classe et la date de la mission, jamais un nom de personne (question 7).
// Le contexte de la visite est joint par le serveur (P-CTR-06) : le
// controleur ne le recopie pas.
//
// Aucun serveur n'est branche (K-28) : le port par defaut echoue, honnete,
// et la demonstration le remplace. Besoin serveur : `14_controleur/CT-BR.md`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'etat d'un fil (doc 08 CTR-04).
enum EtatFilEchange {
  /// L'administration a repondu au dernier message.
  reponseRecue,

  /// Le dernier message attend la reponse de l'administration.
  enAttente,
}

/// Qui a ecrit un message.
enum AuteurEchange {
  /// Le controleur qui lit le fil.
  controleur,

  /// L'administration.
  administration,
}

/// Un message d'un fil.
@immutable
class MessageEchange {
  /// Cree le message.
  const MessageEchange({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.date,
  });

  /// Identifiant stable.
  final String id;

  /// L'auteur.
  final AuteurEchange auteur;

  /// Le texte, sans prenom d'eleve (C8).
  final String texte;

  /// Date d'envoi, heure de l'appareil.
  final DateTime date;
}

/// Un fil avec l'administration, rattache a une mission.
@immutable
class FilEchange {
  /// Cree le fil.
  const FilEchange({
    required this.id,
    required this.missionId,
    required this.classe,
    required this.debutMission,
    required this.etat,
    required this.messages,
  });

  /// Identifiant du fil.
  final String id;

  /// La mission du fil (un seul fil par mission, P-CTR-06).
  final String missionId;

  /// La Classe observee.
  final String classe;

  /// Debut de la seance observee : date et heure du contexte epingle.
  final DateTime debutMission;

  /// Etat du fil.
  final EtatFilEchange etat;

  /// Les messages, du plus ancien au plus recent.
  final List<MessageEchange> messages;

  /// La derniere activite : le dernier message, ou la mission.
  DateTime get derniereActivite =>
      messages.isEmpty ? debutMission : messages.last.date;
}

/// Le port des echanges.
abstract interface class PortEchanges {
  /// Les fils du controleur, du plus recent au plus ancien.
  Future<List<FilEchange>> fils();

  /// Le fil canonique d'une mission, cree par le serveur s'il n'existe pas
  /// encore (P-CTR-06, point 2).
  Future<FilEchange> filDeMission(String missionId);

  /// Envoie un message dans un fil ; se termine sur la reponse, echoue si le
  /// message n'est pas parti.
  Future<void> envoyer(String filId, String texte);
}

/// Le port par defaut, sans serveur : tout echoue, rien n'est simule.
class EchangesIndisponibles implements PortEchanges {
  /// Cree le port.
  const EchangesIndisponibles();

  @override
  Future<List<FilEchange>> fils() async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<FilEchange> filDeMission(String missionId) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyer(String filId, String texte) async =>
      throw StateError('Aucun serveur branche (BR-1).');
}

/// Le port des echanges : neutre par defaut, remplace en demonstration.
final Provider<PortEchanges> portEchangesProvider = Provider<PortEchanges>(
  (Ref _) => const EchangesIndisponibles(),
);
