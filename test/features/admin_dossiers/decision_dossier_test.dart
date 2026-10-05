// AD-8, revue : la machine d'etat des decisions ne double jamais une
// commande et ne purge jamais une commande non resolue (P-ADM-10.6).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/features/admin_dossiers/decision_dossier.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';

/// Retient `decider` et compte les appels ; le reste va a la demonstration.
class _PortRetenu implements PortRevueDossiers {
  _PortRetenu(this._base);

  final PortRevueDossiers _base;
  final Completer<void> porte = Completer<void>();
  int appels = 0;

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async {
    appels++;
    await porte.future;
    return _base.decider(
      dossierId: dossierId,
      revisionAttendue: revisionAttendue,
      decision: decision,
      commandeId: commandeId,
      verificationsFaites: verificationsFaites,
      motif: motif,
    );
  }

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => _base.resultatDecision(dossierId: dossierId, commandeId: commandeId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CommandeDecision _refus(EtatRevueDemo etat, String id) => CommandeDecision(
  dossierId: id,
  revision: etat.dossiers[id]!.revision,
  decision: DecisionDossier.refuser,
  verifications: const <String>{},
  motif: 'Motif fictif.',
);

void main() {
  test('une commande non resolue survit au depart de la page', () async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        portRevueDossiersProvider.overrideWithValue(RevueDossiersDemo(etat)),
      ],
    );
    addTearDown(c.dispose);
    const String id = DonneesDossiersDemo.reponsePerdue;
    final ProviderSubscription<Map<String, EtatDecision>> page = c.listen(
      decisionsDossiersProvider,
      (_, _) {},
    );
    final EtatDecision e = await c
        .read(decisionsDossiersProvider.notifier)
        .envoyer(_refus(etat, id));
    expect(e, isA<DecisionInconnue>());

    // La page quitte (changement de domaine) : l'etat inconnu reste, les
    // decisions restent fermees au retour.
    page.close();
    await c.pump();
    expect(c.read(decisionsDossiersProvider)[id], isA<DecisionInconnue>());
    expect(c.read(decisionsDossiersProvider)[id]!.nonResolue, isTrue);

    // Resolu par relecture : plus rien a garder, l'etat est purge.
    final DecisionsDossiersNotifier n = c.read(
      decisionsDossiersProvider.notifier,
    );
    await n.verifier(id);
    expect(await n.verifier(id), isA<DecisionReussie>());
    await c.pump();
    expect(c.read(decisionsDossiersProvider), isEmpty);
    expect(etat.nombreDecisions, 1);
  });

  test('deux envois avant toute reponse : un seul appel au port', () async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final _PortRetenu port = _PortRetenu(RevueDossiersDemo(etat));
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[portRevueDossiersProvider.overrideWithValue(port)],
    );
    addTearDown(c.dispose);
    c.listen(decisionsDossiersProvider, (_, _) {});
    const String id = DonneesDossiersDemo.enseignantNominal;
    final DecisionsDossiersNotifier n = c.read(
      decisionsDossiersProvider.notifier,
    );
    final Future<EtatDecision> premier = n.envoyer(_refus(etat, id));
    final EtatDecision second = await n.envoyer(_refus(etat, id));
    expect(second, isA<DecisionEnvoi>());
    expect(port.appels, 1);
    port.porte.complete();
    expect(await premier, isA<DecisionReussie>());
    expect(port.appels, 1);
    expect(etat.nombreDecisions, 1);

    // AD-NETTOYAGE-2 (n8) : une decision reussie n'est pas renvoyee non plus
    // (Entree repetee apres la reponse) : l'etat est rendu, aucun appel.
    final EtatDecision encore = await n.envoyer(_refus(etat, id));
    expect(encore, isA<DecisionReussie>());
    expect(port.appels, 1);
    expect(etat.nombreDecisions, 1);
  });

  test('refus : verification ou accord manquant ne dit jamais « valide »', () {
    final CommandeDecision r = CommandeDecision(
      dossierId: 'x',
      revision: 0,
      decision: DecisionDossier.refuser,
      verifications: const <String>{},
      motif: 'm',
    );
    for (final CodeErreurRevue code in <CodeErreurRevue>[
      CodeErreurRevue.verificationManquante,
      CodeErreurRevue.accordManquant,
      CodeErreurRevue.activationImpossible,
    ]) {
      expect(etatPourCode(r, code), isA<DecisionInterdite>(), reason: '$code');
    }
  });
}
