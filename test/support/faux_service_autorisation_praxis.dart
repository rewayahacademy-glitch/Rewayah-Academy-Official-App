// Le double de `ServiceAutorisationPraxis` : aucune base, une demande
// fictive, le journal de ce que l'ecran a demande.

import 'dart:async';

import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';

/// Une adresse de retour valable : le code est un condense hexadecimal fictif.
final String retourAutorise =
    'https://claude.ai/api/mcp/auth_callback?code=${'a' * 64}&state=etat%201%26x';

/// Le refus, tel que la base le rend.
const String retourRefuse =
    'https://claude.ai/api/mcp/auth_callback?error=access_denied&state=etat%201%26x';

/// Le double.
class FauxServiceAutorisationPraxis implements ServiceAutorisationPraxis {
  /// Cree le double.
  FauxServiceAutorisationPraxis({
    this.demande = const DemandeAutorisationPraxis(
      etat: EtatDemandePraxis.enAttente,
      client: 'Claude',
      hote: 'claude.ai',
      peutAutoriser: true,
    ),
    this.decision,
    this.erreurLecture,
    this.erreurDecision,
    this.attenteLecture,
  });

  /// Ce que la lecture rend.
  DemandeAutorisationPraxis demande;

  /// Ce que la decision rend (sinon : l'adresse de retour d'un accord).
  DecisionAutorisationPraxis? decision;

  /// Une erreur a jeter a la lecture.
  Exception? erreurLecture;

  /// Une erreur a jeter a la decision.
  Exception? erreurDecision;

  /// Tant qu'elle n'est pas terminee, la lecture attend (etat « chargement »).
  Completer<void>? attenteLecture;

  /// Les lectures faites.
  final List<String> lectures = <String>[];

  /// Les decisions demandees : identifiant et sens.
  final List<({String demande, bool accepter})> decisions =
      <({String demande, bool accepter})>[];

  @override
  Future<DemandeAutorisationPraxis> lire(String demande) async {
    lectures.add(demande);
    if (attenteLecture != null) await attenteLecture!.future;
    if (erreurLecture != null) throw erreurLecture!;
    return this.demande;
  }

  @override
  Future<DecisionAutorisationPraxis> decider(
    String demande, {
    required bool accepter,
  }) async {
    decisions.add((demande: demande, accepter: accepter));
    if (erreurDecision != null) throw erreurDecision!;
    return decision ??
        DecisionAutorisationPraxis(
          redirection: accepter ? retourAutorise : retourRefuse,
        );
  }
}
