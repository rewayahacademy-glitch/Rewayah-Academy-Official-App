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
    List<ConnexionPraxis>? connexions,
    this.erreurConnexions,
    this.erreurRevocation,
    this.revocationRendue = true,
  }) : _connexions = connexions ?? <ConnexionPraxis>[];

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

  List<ConnexionPraxis> _connexions;

  /// Une erreur a jeter a la lecture des connexions.
  Exception? erreurConnexions;

  /// Une erreur a jeter a la revocation.
  Exception? erreurRevocation;

  /// Ce que la revocation rend (faux : rien a couper).
  bool revocationRendue;

  /// Les lectures de la liste des connexions.
  int lecturesConnexions = 0;

  /// Les revocations demandees : identifiant et motif.
  final List<({String id, String motif})> revocations =
      <({String id, String motif})>[];

  /// Les lectures faites.
  final List<String> lectures = <String>[];

  /// Les decisions demandees : identifiant et sens.
  final List<({String demande, bool accepter})> decisions =
      <({String demande, bool accepter})>[];

  @override
  Future<List<ConnexionPraxis>> connexions() async {
    lecturesConnexions++;
    if (erreurConnexions != null) throw erreurConnexions!;
    return _connexions;
  }

  @override
  Future<bool> revoquerConnexion({
    required String id,
    required String motif,
  }) async {
    revocations.add((id: id, motif: motif));
    if (erreurRevocation != null) throw erreurRevocation!;
    // La liste relue montre la connexion coupee, comme la base.
    _connexions = <ConnexionPraxis>[
      for (final ConnexionPraxis c in _connexions)
        if (c.id == id && revocationRendue)
          ConnexionPraxis(
            id: c.id,
            client: c.client,
            creeLe: c.creeLe,
            expireLe: c.expireLe,
            etat: EtatConnexionPraxis.revoquee,
            derniereUtilisationLe: c.derniereUtilisationLe,
            revoqueeLe: DateTime(2026, 11, 19, 12),
            motifRevocation: motif,
          )
        else
          c,
    ];
    return revocationRendue;
  }

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

/// Une connexion fictive.
ConnexionPraxis connexionPraxisFictive({
  String id = 'cx1',
  String client = 'Claude',
  EtatConnexionPraxis etat = EtatConnexionPraxis.active,
  DateTime? derniereUtilisation,
}) => ConnexionPraxis(
  id: id,
  client: client,
  creeLe: DateTime(2026, 11, 10, 9),
  expireLe: DateTime(2027, 2, 8, 9),
  etat: etat,
  derniereUtilisationLe: derniereUtilisation,
);
