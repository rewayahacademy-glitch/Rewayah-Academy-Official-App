// La machine d'etat des decisions (AD-8, ADM-02D et ADM-02E). Aucun widget :
// les surfaces et la revue lisent l'etat par dossier et envoient par le PORT
// (`portRevueDossiersProvider`), jamais par `ServiceValidation`.
//
// L'etat vit dans un notifier de session porte par la page, pas par la
// feuille : fermer une surface pendant l'envoi n'annule rien, le suivi reste
// attache au `commandeId` (P-ADM-10.6). Le motif n'existe que dans la
// commande ; tout est purge quand plus aucun ecran ne lit l'etat.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revue_dossiers.dart';

/// Une commande de decision, immuable : « Reessayer » la rejoue telle quelle.
@immutable
class CommandeDecision {
  /// Cree une commande ; le motif est trime.
  CommandeDecision({
    required this.dossierId,
    required this.revision,
    required this.decision,
    required this.verifications,
    String? motif,
    String? commandeId,
  }) : motif = motif?.trim(),
       commandeId = commandeId ?? const Uuid().v4();

  final String dossierId;
  final int revision;
  final DecisionDossier decision;
  final String commandeId;
  final String? motif;
  final Set<String> verifications;

  @override
  String toString() => 'CommandeDecision(${decision.name})';
}

/// L'etat d'une decision pour un dossier. L'absence d'etat est le repos.
sealed class EtatDecision {
  const EtatDecision(this.commande);

  final CommandeDecision commande;

  /// Vrai tant que le sort de la commande n'est pas connu : les deux
  /// decisions de la revue restent fermees (P-ADM-10.6).
  bool get nonResolue => false;
}

final class DecisionEnvoi extends EtatDecision {
  const DecisionEnvoi(super.commande);

  @override
  bool get nonResolue => true;
}

final class DecisionVerification extends EtatDecision {
  const DecisionVerification(super.commande);

  @override
  bool get nonResolue => true;
}

final class DecisionInconnue extends EtatDecision {
  const DecisionInconnue(super.commande);

  @override
  bool get nonResolue => true;
}

final class DecisionReussie extends EtatDecision {
  const DecisionReussie(super.commande, this.resultat);

  final ResultatDecision? resultat;
}

/// Echec certain : la reprise rejoue la MEME commande.
final class DecisionEchec extends EtatDecision {
  const DecisionEchec(super.commande, [this.code]);

  final CodeErreurRevue? code;
}

final class DecisionConflit extends EtatDecision {
  const DecisionConflit(super.commande);
}

/// Relecture : le dossier a quitte la file, decision non attribuable.
final class DecisionTraitee extends EtatDecision {
  const DecisionTraitee(super.commande);
}

final class DecisionPlusPrete extends EtatDecision {
  const DecisionPlusPrete(super.commande);
}

final class DecisionInterdite extends EtatDecision {
  const DecisionInterdite(super.commande);
}

final class DecisionIndisponible extends EtatDecision {
  const DecisionIndisponible(super.commande);
}

/// L'etat d'arrivee d'un code metier.
EtatDecision etatPourCode(CommandeDecision c, CodeErreurRevue code) =>
    switch (code) {
      CodeErreurRevue.perime ||
      CodeErreurRevue.dejaDecide => DecisionConflit(c),
      CodeErreurRevue.verificationManquante ||
      CodeErreurRevue.accordManquant ||
      CodeErreurRevue.activationImpossible =>
        c.decision == DecisionDossier.valider
            ? DecisionPlusPrete(c)
            : DecisionInterdite(c),
      CodeErreurRevue.pieceIndisponible =>
        c.decision == DecisionDossier.valider
            ? DecisionPlusPrete(c)
            : DecisionInterdite(c),
      CodeErreurRevue.interdit ||
      CodeErreurRevue.nonAutorise ||
      CodeErreurRevue.introuvable ||
      CodeErreurRevue.profilACompleter => DecisionInterdite(c),
      CodeErreurRevue.indisponibleTemporairement => DecisionIndisponible(c),
      CodeErreurRevue.reponsePerdue => DecisionInconnue(c),
      _ => DecisionEchec(c, code),
    };

/// Les decisions en cours, par dossier.
class DecisionsDossiersNotifier extends Notifier<Map<String, EtatDecision>> {
  /// Tenu tant qu'une commande n'est pas resolue : quitter la page ne doit
  /// jamais rouvrir les decisions sans relecture (P-ADM-10.6).
  KeepAliveLink? _garde;

  @override
  Map<String, EtatDecision> build() => <String, EtatDecision>{};

  void _poser(String dossierId, EtatDecision? e) {
    final Map<String, EtatDecision> m = <String, EtatDecision>{...state};
    if (e == null) {
      m.remove(dossierId);
    } else {
      m[dossierId] = e;
    }
    state = m;
    if (m.values.any((EtatDecision x) => x.nonResolue)) {
      _garde ??= ref.keepAlive();
    } else {
      _garde?.close();
      _garde = null;
    }
  }

  /// Envoie (ou rejoue) une commande. Aucune relance automatique. Une
  /// commande deja non resolue pour ce dossier n'est jamais doublee (double
  /// tap, Entree repetee) : l'etat courant est rendu tel quel.
  Future<EtatDecision> envoyer(CommandeDecision c) async {
    final EtatDecision? courant = state[c.dossierId];
    if (courant != null && courant.nonResolue) {
      return courant;
    }
    _poser(c.dossierId, DecisionEnvoi(c));
    EtatDecision fin;
    try {
      final ResultatDecision r = await ref
          .read(portRevueDossiersProvider)
          .decider(
            dossierId: c.dossierId,
            revisionAttendue: c.revision,
            decision: c.decision,
            commandeId: c.commandeId,
            verificationsFaites: c.verifications,
            motif: c.decision == DecisionDossier.refuser ? c.motif : null,
          );
      fin = DecisionReussie(c, r);
    } on CapaciteIndisponible {
      fin = DecisionIndisponible(c);
    } on ErreurRevueDossier catch (e) {
      fin = etatPourCode(c, e.code);
    } on TimeoutException {
      fin = DecisionInconnue(c);
    } on Object {
      fin = DecisionEchec(c);
    }
    if (ref.mounted) {
      _poser(c.dossierId, fin);
    }
    return fin;
  }

  /// « Verifier le resultat » : relit la MEME commande, sur geste seulement.
  Future<EtatDecision> verifier(String dossierId) async {
    final EtatDecision? avant = state[dossierId];
    if (avant == null) {
      throw StateError('aucune commande');
    }
    final CommandeDecision c = avant.commande;
    _poser(dossierId, DecisionVerification(c));
    EtatDecision fin;
    try {
      final EtatCommande e = await ref
          .read(portRevueDossiersProvider)
          .resultatDecision(dossierId: dossierId, commandeId: c.commandeId);
      fin = switch (e) {
        EtatCommandeReussie(:final ResultatDecision resultat) =>
          DecisionReussie(c, resultat),
        EtatCommandeEnAttente() => DecisionInconnue(c),
        EtatCommandeEchouee(code: CodeErreurRevue.dejaDecide) =>
          DecisionTraitee(c),
        EtatCommandeEchouee(:final CodeErreurRevue code) => etatPourCode(
          c,
          code,
        ),
        // Le port affirme que la commande n'est jamais arrivee (il suit les
        // commandId) : echec certain, reprise avec la meme charge. Un port
        // qui ne sait pas trancher rend EtatCommandeEnAttente (Q-AD8-9).
        EtatCommandeInconnue() => DecisionEchec(c),
      };
    } on Object {
      fin = DecisionInconnue(c);
    }
    if (ref.mounted) {
      _poser(dossierId, fin);
    }
    return fin;
  }

  /// Oublie la commande d'un dossier (annulation, actualisation, succes).
  void oublier(String dossierId) => _poser(dossierId, null);
}

/// Les decisions de la session, purgees quand plus rien ne les lit et
/// qu'aucune commande n'est en suspens.
final NotifierProvider<DecisionsDossiersNotifier, Map<String, EtatDecision>>
decisionsDossiersProvider =
    NotifierProvider.autoDispose<
      DecisionsDossiersNotifier,
      Map<String, EtatDecision>
    >(DecisionsDossiersNotifier.new);
