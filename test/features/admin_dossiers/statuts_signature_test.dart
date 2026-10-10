// RECRUT-ECRANS (4/5) : le dossier admin montre le contrat ET l'accuse
// (signe version courante / ancienne version / non signe), ferme « Approuver »
// avec sa raison quand l'un n'est pas a la version courante, et dit
// « Contrat non signe a la version courante » quand le serveur refuse quand
// meme l'activation (course).
//
// Ce que le test prouve : les trois statuts en mots, pour le contrat et pour
// l'accuse ; sans port, aucune carte et rien de ferme en plus ; le refus du
// serveur (`ContratNonSigneVersionCourante`) arrive en clair avec ce qui
// manque, et la reprise releve le dossier ; la machine d'etat l'enregistre.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recrutement/port_statuts_signature.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/decision_dossier.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le port de la demonstration, sauf `decider` qui leve l'erreur d'activation.
class _PortQuiRefuse implements PortRevueDossiers {
  _PortQuiRefuse(this._base);
  final PortRevueDossiers _base;

  @override
  Future<PageDossiers> listerDossiers({
    String? curseur,
    int limite = 20,
    AppRole? role,
  }) => _base.listerDossiers(curseur: curseur, limite: limite, role: role);

  @override
  Future<DossierPourRevue> dossierPourRevue(String dossierId) =>
      _base.dossierPourRevue(dossierId);

  @override
  Future<VuePiece> demanderVuePiece({
    required String dossierId,
    required String documentId,
  }) => _base.demanderVuePiece(dossierId: dossierId, documentId: documentId);

  @override
  Future<ResultatDecision> decider({
    required String dossierId,
    required int revisionAttendue,
    required DecisionDossier decision,
    required String commandeId,
    required Set<String> verificationsFaites,
    String? motif,
  }) async => throw const ContratNonSigneVersionCourante(<ManqueSignature>[
    ManqueSignature.contrat,
  ]);

  @override
  Future<EtatCommande> resultatDecision({
    required String dossierId,
    required String commandeId,
  }) => _base.resultatDecision(dossierId: dossierId, commandeId: commandeId);
}

Future<void> _monter(
  WidgetTester tester, {
  Override? statuts,
  bool refus = false,
  bool sansPort = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final EtatRevueDemo etat = EtatRevueDemo.initial();
  final List<Override> demo = surchargesDemoAdmin(
    environnement: 'staging',
    etat: etat,
  );
  if (refus) {
    demo[1] = portRevueDossiersProvider.overrideWithValue(
      _PortQuiRefuse(RevueDossiersDemo(etat)),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: demo,
      // Une portee imbriquee : elle surcharge le port de statuts de la
      // demonstration sans en dupliquer l'override.
      child: ProviderScope(
        overrides: <Override>[
          if (sansPort)
            statutsSignatureDossierProvider.overrideWith(
              (Ref ref, String id) async => null,
            ),
          ?statuts,
        ],
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);
}

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
  await _stabiliser(tester);
  await tester.tap(
    find.descendant(
      of: find.byKey(AdminShell.tiroirKey),
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle).first);
  await _stabiliser(tester);
  await tester.tap(find.text(libelle).first);
  await _stabiliser(tester);
}

Future<void> _verifier(WidgetTester tester) async {
  for (final String point in <String>[
    t.dossiers.pointLisible,
    t.dossiers.pointNom,
    t.dossiers.pointValidite,
  ]) {
    await _toucher(tester, point);
  }
}

Override _statuts(StatutsSignature s) =>
    statutsSignatureDossierProvider.overrideWith(
      (Ref ref, String id) async =>
          id == DonneesDossiersDemo.enseignantNominal ? s : null,
    );

void main() {
  final r = t.recrutement.statuts;

  testWidgets('signe version courante des deux cotes : « Valider » reste', (
    tester,
  ) async {
    await _monter(tester);
    await _ouvrir(tester, 'Omar');
    expect(find.text(r.titre), findsOneWidget);
    expect(find.text(r.signeCourante), findsNWidgets(2));
    expect(find.text(r.bloque), findsNothing);
    await _verifier(tester);
    expect(find.text('Valider le dossier'), findsOneWidget);
  });

  testWidgets('contrat a une ancienne version : version dite, « Valider » '
      'ferme avec sa raison', (tester) async {
    await _monter(
      tester,
      statuts: _statuts(
        const StatutsSignature(
          contrat: SigneAncienneVersion('2026-09'),
          accuse: SigneVersionCourante(),
        ),
      ),
    );
    await _ouvrir(tester, 'Omar');
    expect(find.text(r.signeAncienne(version: '2026-09')), findsOneWidget);
    expect(find.text(r.signeCourante), findsOneWidget);
    expect(find.text(r.bloque), findsOneWidget);
    await _verifier(tester);
    expect(find.text('Valider le dossier'), findsNothing);
    expect(find.text(r.bloque), findsOneWidget);
    // Le refus reste possible : le motif n'a rien a voir avec la signature.
    expect(find.text('Refuser le dossier'), findsOneWidget);
  });

  testWidgets('accuse non signe : « Non signe » et la meme raison', (
    tester,
  ) async {
    await _monter(
      tester,
      statuts: _statuts(
        const StatutsSignature(
          contrat: SigneVersionCourante(),
          accuse: NonSigne(),
        ),
      ),
    );
    await _ouvrir(tester, 'Omar');
    expect(find.text(r.nonSigne), findsOneWidget);
    expect(find.text(r.bloque), findsOneWidget);
    await _verifier(tester);
    expect(find.text('Valider le dossier'), findsNothing);
  });

  testWidgets('sans port : aucune carte, rien de ferme en plus', (
    tester,
  ) async {
    await _monter(tester, sansPort: true);
    await _ouvrir(tester, 'Omar');
    expect(find.text(r.titre), findsNothing);
    await _verifier(tester);
    expect(find.text('Valider le dossier'), findsOneWidget);
  });

  testWidgets('le serveur refuse l\'activation : le message est clair, la '
      'reprise releve le dossier', (tester) async {
    await _monter(tester, refus: true);
    await _ouvrir(tester, 'Omar');
    await _verifier(tester);
    await _toucher(tester, t.dossiers.approuver);
    await tester.tap(find.text(t.dossiers.approuver).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(
      find.textContaining('Contrat non signé à la version courante'),
      findsWidgets,
    );
    expect(find.textContaining(r.manqueContrat), findsWidgets);
    expect(find.text(t.dossiers.validation.succes), findsNothing);
    // Aucun bouton « Reessayer » aveugle : la seule suite est de relire.
    expect(find.text(t.dossiers.revue.etats.actualiserDossier), findsWidgets);
  });

  test('la machine d\'etat enregistre le refus d\'activation', () async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        portRevueDossiersProvider.overrideWithValue(
          _PortQuiRefuse(RevueDossiersDemo(etat)),
        ),
      ],
    );
    addTearDown(c.dispose);
    final EtatDecision fin = await c
        .read(decisionsDossiersProvider.notifier)
        .envoyer(
          CommandeDecision(
            dossierId: DonneesDossiersDemo.enseignantNominal,
            revision: 0,
            decision: DecisionDossier.valider,
            verifications: const <String>{},
          ),
        );
    expect(fin, isA<DecisionContratNonSigne>());
    expect((fin as DecisionContratNonSigne).manque, <ManqueSignature>[
      ManqueSignature.contrat,
    ]);
    expect(fin.nonResolue, isFalse);
  });
}
