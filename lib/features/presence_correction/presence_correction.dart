import 'package:flutter/foundation.dart';

import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';

/// Capacites exposees par l'autorisation serveur a la surface de correction.
///
/// Le widget ne lit jamais un role. Ces booléens sont un adaptateur temporaire
/// jusqu'au contrat d'autorisation definitif, qui pourra les alimenter sans
/// changer la presentation.
@immutable
class PresenceCorrectionCapacites {
  /// Cree les capacites de la surface.
  const PresenceCorrectionCapacites({
    this.peutCorriger = false,
    this.peutExcuser = false,
  });

  /// Autorise `corrigee_manuel`.
  final bool peutCorriger;

  /// Autorise `excusee`.
  final bool peutExcuser;
}

/// Cible de la decision, deja lue par la vue de presence bornee.
@immutable
class PresenceCorrectionCible {
  /// Cree une cible.
  const PresenceCorrectionCible({required this.ligne, required this.vue});

  /// Identite et etat exposes par `presence_seance_v`.
  final PresenceParticipant ligne;

  /// Representation prete a afficher.
  final VuePresence vue;
}

/// Etat que la presentation demande au contrat serveur.
enum PresenceCorrectionDecision {
  /// Remplace l'etat calcule par une decision manuelle.
  corrigeeManuel,

  /// Marque l'absence comme excusee.
  excusee,
}

/// Commande minimale transmise a l'adaptateur serveur.
@immutable
class PresenceCorrectionCommande {
  /// Cree une commande sans inventer de revision serveur.
  const PresenceCorrectionCommande({
    required this.sessionId,
    required this.profileId,
    required this.decision,
    required this.motif,
  });

  /// Seance concernee.
  final String sessionId;

  /// Participant concerne.
  final String profileId;

  /// Decision humaine demandee.
  final PresenceCorrectionDecision decision;

  /// Motif deja nettoye par la presentation.
  final String motif;

  /// Etat SQL attendu par le contrat d'integration.
  EtatPresence get etat => switch (decision) {
    PresenceCorrectionDecision.corrigeeManuel => EtatPresence.corrigeeManuel,
    PresenceCorrectionDecision.excusee => EtatPresence.excusee,
  };
}

/// Erreurs explicites que l'adaptateur peut remonter a l'interface.
enum PresenceCorrectionErreurType {
  /// Le reseau ne permet pas de confirmer la decision.
  horsLigne,

  /// La ligne a change depuis sa lecture.
  concurrence,

  /// L'autorisation serveur a refuse la commande.
  interdite,

  /// Le service n'a pas pu traiter la commande.
  indisponible,
}

/// Erreur de transport du contrat, sans fuite de detail backend dans l'UI.
class PresenceCorrectionException implements Exception {
  /// Cree une erreur d'adaptateur.
  const PresenceCorrectionException(this.type);

  /// Cause exploitable par l'etat de la surface.
  final PresenceCorrectionErreurType type;
}

/// Point d'integration du futur service serveur.
abstract interface class PresenceCorrectionAdaptateur {
  /// Attend la confirmation serveur avant de declarer le succes.
  Future<void> appliquer(PresenceCorrectionCommande commande);
}

/// Libelles fournis par l'integration, sans modifier les fichiers i18n dans ce
/// lot UI. La production pourra les construire depuis slang.
@immutable
class PresenceCorrectionLibelles {
  /// Cree les libelles de la surface.
  const PresenceCorrectionLibelles({
    required this.titre,
    required this.corriger,
    required this.excuser,
    required this.confirmation,
    required this.motif,
    required this.motifRequis,
    required this.confirmer,
    required this.annuler,
    required this.mutationEnCours,
    required this.succes,
    required this.erreur,
    required this.horsLigne,
    required this.journalisation,
  });

  final String titre;
  final String corriger;
  final String excuser;
  final String confirmation;
  final String motif;
  final String motifRequis;
  final String confirmer;
  final String annuler;
  final String mutationEnCours;
  final String succes;
  final String erreur;
  final String horsLigne;
  final String journalisation;
}
