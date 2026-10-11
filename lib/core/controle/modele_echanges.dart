import 'package:flutter/foundation.dart';

/// État d'un fil d'échange avec l'administration.
enum EtatFilEchange { reponseRecue, enAttente }

/// Auteur d'un message d'échange.
enum AuteurEchange { controleur, administration }

/// Message d'un fil avec l'administration.
@immutable
class MessageEchange {
  const MessageEchange({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.date,
  });

  final String id;
  final AuteurEchange auteur;
  final String texte;
  final DateTime date;
}

/// Fil de discussion avec l'administration, rattaché à une mission.
@immutable
class FilEchange {
  const FilEchange({
    required this.id,
    required this.missionId,
    required this.classe,
    required this.debutMission,
    required this.etat,
    required this.messages,
  });

  final String id;
  final String missionId;
  final String classe;
  final DateTime debutMission;
  final EtatFilEchange etat;
  final List<MessageEchange> messages;

  DateTime get derniereActivite =>
      messages.isEmpty ? debutMission : messages.last.date;
}
