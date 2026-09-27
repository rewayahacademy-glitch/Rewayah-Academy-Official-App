// AD-10 (P-ADM-08) : famille dispensee et piece absente, depuis la VRAIE
// coque admin et le vrai routeur, en demonstration (`?demo=admin`). Chaque
// geste part d'un bouton reel (K-07) : Personnes dans la coque, la ligne du
// dossier, puis « Valider le dossier » / « Refuser le dossier ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/file_dossiers.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(WidgetTester tester, EtatRevueDemo etat) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging', etat: etat),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
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

Finder _ligne(String debutNom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$debutNom"));

/// « Personnes » dans la barre laterale de la coque.
Future<void> _personnes(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(AdminShell.barreLateraleKey),
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _stabiliser(tester);
}

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await _personnes(tester);
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

ActionPrincipale _action(WidgetTester tester, String libelle) =>
    tester.widget<ActionPrincipale>(
      find
          .ancestor(
            of: find.text(libelle),
            matching: find.byType(ActionPrincipale),
          )
          .first,
    );

/// La personne, titulaire du dossier [id], dans la vraie application en
/// demonstration tuteur, sur le MEME etat que la revue admin.
Future<GoRouter> _monterPersonne(
  WidgetTester tester,
  EtatRevueDemo etat,
  String id,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surchargesDemoTuteur(
        environnement: 'staging',
        dossiers: etat,
        titulaire: id,
      ),
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  // Aucun `go` force : la garde de session conduit seule un compte en
  // attente ou refuse vers /attente (entree naturelle).
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  expect(_chemin(routeur), Routes.attente);
  return routeur;
}

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

/// Pause puis retour, transition par transition comme la plateforme.
Future<void> _pauseEtRetour(WidgetTester tester) async {
  for (final AppLifecycleState s in <AppLifecycleState>[
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await _stabiliser(tester);
  await _stabiliser(tester);
}

void main() {
  testWidgets('T1 famille dispensee : aucune piece requise, validable', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    final int avant = etat.fileTriee.length;
    await _monter(tester, etat);
    await _ouvrir(tester, 'Hana');

    expect(find.text(t.dossiers.revue.pieceNonRequise), findsOneWidget);
    expect(find.text(t.dossiers.verifications), findsNothing);
    expect(find.text(t.dossiers.revue.voirPiece), findsNothing);
    expect(
      find.text(t.dossiers.revue.etats.decisionIndisponible),
      findsNothing,
    );
    expect(_action(tester, t.dossiers.approuver).onPress, isNotNull);

    await _toucher(tester, t.dossiers.approuver);
    await tester.tap(find.text(t.dossiers.approuver).last);
    await _stabiliser(tester);
    await _stabiliser(tester);

    expect(etat.nombreDecisions, 1);
    expect(find.text(t.dossiers.validation.succes), findsOneWidget);
    expect(etat.fileTriee.length, avant - 1);
    expect(
      etat.dossiers[DonneesDossiersDemo.familleDispensee]!.statut,
      isNot(StatutRevue.aVerifier),
    );
  });

  testWidgets('T2 piece absente : la raison dite une fois, Valider absent, '
      'Refuser ouvre 02D', (WidgetTester tester) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, etat);
    await _ouvrir(tester, 'Yanis');

    // Dite une fois dans la carte Piece ; l'emplacement de decision dit « pas pret ».
    expect(find.text(t.dossiers.revue.pieceNonTransmise), findsOneWidget);
    expect(find.text(t.dossiers.revue.pasPret), findsOneWidget);
    expect(find.text(t.dossiers.approuver), findsNothing);
    expect(etat.nombreDecisions, 0);
    expect(find.text(t.dossiers.refus.corps), findsNothing);

    await _toucher(tester, t.dossiers.refuser);
    expect(find.text(t.dossiers.refus.corps), findsOneWidget);
  });

  testWidgets('T3 et T4 : pastilles de la file, aucune promesse d audit', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    await _monter(tester, etat);
    await _personnes(tester);

    // La pastille de chaque ligne, telle que le port la rend a l'ecran.
    final PageDossiers page = await RevueDossiersDemo(etat).listerDossiers();
    final DossierEnFile hana = page.elements.firstWhere(
      (DossierEnFile d) => d.dossierId == DonneesDossiersDemo.familleDispensee,
    );
    final DossierEnFile yanis = page.elements.firstWhere(
      (DossierEnFile d) => d.dossierId == DonneesDossiersDemo.pieceAbsente,
    );
    expect(pastilleDossier(hana).$1, t.dossiers.file.enVerification);
    expect(pastilleDossier(yanis).$1, t.dossiers.sansPiece);
    await tester.ensureVisible(_ligne('Yanis'));
    await _stabiliser(tester);
    expect(find.textContaining("journal d'audit"), findsNothing);

    await tester.tap(_ligne('Yanis'));
    await _stabiliser(tester);
    expect(find.textContaining("journal d'audit"), findsNothing);
  });

  testWidgets('T5 refus, correction par la personne, retour en file en '
      'revision nouvelle, cases vides', (WidgetTester tester) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.tuteurDocumentaire;
    const String motif = 'Motif fictif : photo floue.';

    // Admin : refus avec motif, depuis la coque.
    await _monter(tester, etat);
    await _ouvrir(tester, 'Amina');
    await _toucher(tester, t.dossiers.refuser);
    await tester.enterText(
      find
          .ancestor(
            of: find.text(t.dossiers.refus.champ),
            matching: find.byType(TextField),
          )
          .first,
      motif,
    );
    await _stabiliser(tester);
    await tester.tap(find.text(t.dossiers.refuser).last);
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(etat.nombreDecisions, 1);

    // Personne : « Dossier refusé », le motif, « Corriger ».
    await _monterPersonne(tester, etat, id);
    expect(find.text(t.attente.refuse), findsOneWidget);
    expect(find.text(motif), findsOneWidget);
    await tester.tap(find.text(t.attente.corriger));
    await _stabiliser(tester);
    expect(find.text(t.kyc.titre), findsOneWidget);
    await tester.tap(find.text(t.kyc.passeport));
    await _stabiliser(tester);
    await tester.tap(find.text(t.kyc.choisirFichier));
    await _stabiliser(tester);
    await tester.tap(find.text(t.kyc.envoyer));
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(find.text(t.attente.titre), findsOneWidget);
    expect(find.textContaining('notification'), findsNothing);
    expect(find.text(t.attente.actualiser), findsOneWidget);

    // Admin : Amina revient, piece en revision 2, cases vides, Valider ferme.
    final DossierDemo d = etat.dossiers[id]!;
    expect(d.statut, StatutRevue.aVerifier);
    expect(d.revisionDocument, 2);
    expect(d.motifRefus, isNull);
    await _monter(tester, etat);
    await _ouvrir(tester, 'Amina');
    expect(find.text(t.dossiers.approuver), findsNothing);
    expect(etat.nombreDecisions, 1);
  });

  testWidgets('T8 validee pendant l absence : le retour mene a /tuteur', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.familleDispensee;
    final GoRouter routeur = await _monterPersonne(tester, etat, id);
    expect(_chemin(routeur), Routes.attente);
    expect(find.text(t.attente.titre), findsOneWidget);

    // L'administration valide (le geste admin est prouve par T1).
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: etat.dossiers[id]!.revision,
      decision: DecisionDossier.valider,
      commandeId: 'ad10-t8',
      verificationsFaites: const <String>{},
    );
    expect(etat.dossiers[id]!.etatCompte, AccountStatus.active);

    await _pauseEtRetour(tester);
    expect(_chemin(routeur), startsWith(Routes.tuteurAccueil));
    expect(find.byType(NavShell), findsOneWidget);
  });

  testWidgets('T8 variante : « Actualiser l etat du dossier » mene a /tuteur', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.familleDispensee;
    final GoRouter routeur = await _monterPersonne(tester, etat, id);
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: etat.dossiers[id]!.revision,
      decision: DecisionDossier.valider,
      commandeId: 'ad10-t8b',
      verificationsFaites: const <String>{},
    );
    await tester.tap(find.text(t.attente.actualiser));
    await _stabiliser(tester);
    await _stabiliser(tester);
    expect(_chemin(routeur), startsWith(Routes.tuteurAccueil));
  });

  test('demonstration : un refus garde le motif, la resoumission ouvre une '
      'nouvelle revision', () async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.tuteurDocumentaire;
    final int revision = etat.dossiers[id]!.revision;
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: revision,
      decision: DecisionDossier.refuser,
      commandeId: 'ad10-u1',
      verificationsFaites: const <String>{},
      motif: '  Motif fictif.  ',
    );
    final DossierDemo d = etat.dossiers[id]!;
    expect(d.motifRefus, 'Motif fictif.');
    final String? ancienne = d.documentId;
    etat.resoumettre(id);
    expect(d.statut, StatutRevue.aVerifier);
    expect(d.revision, revision + 2);
    expect(d.revisionDocument, 2);
    expect(d.documentId, isNot(ancienne));
    expect(d.motifRefus, isNull);
  });

  testWidgets('T9 validee avec une condition restante : reste sur /attente', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.tuteurDocumentaire;
    final GoRouter routeur = await _monterPersonne(tester, etat, id);
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: etat.dossiers[id]!.revision,
      decision: DecisionDossier.valider,
      commandeId: 'ad10-t9',
      verificationsFaites: verificationsDemo.toSet(),
    );
    await _pauseEtRetour(tester);
    expect(_chemin(routeur), Routes.attente);
  });

  testWidgets('T1 bis famille dispensee refusee : aucune piece demandee', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.familleDispensee;
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: etat.dossiers[id]!.revision,
      decision: DecisionDossier.refuser,
      commandeId: 'ad10-t1b',
      verificationsFaites: const <String>{},
      motif: 'Motif fictif.',
    );
    final GoRouter routeur = await _monterPersonne(tester, etat, id);
    expect(find.text(t.attente.refuse), findsOneWidget);
    expect(find.text(t.attente.refuseSansElement), findsOneWidget);
    expect(find.textContaining('pièce'), findsNothing);
    expect(find.text(t.attente.corriger), findsNothing);
    expect(_chemin(routeur), isNot(Routes.attentePiece));
  });

  testWidgets(
    'T6 ?dossier=refuse-fige : correction impossible, sans Corriger',
    (WidgetTester tester) async {
      final ({EtatRevueDemo dossiers, String titulaire}) fige =
          dossierTitulaireDemoPour(
            Uri.parse('/?demo=tuteur&dossier=refuse-fige'),
          )!;
      await _monterPersonne(tester, fige.dossiers, fige.titulaire);
      expect(find.text(t.attente.correctionImpossible), findsOneWidget);
      expect(find.text(t.attente.corriger), findsNothing);
    },
  );

  testWidgets('T8 bis : apres validation, aucun enfant ni classe deduits', (
    WidgetTester tester,
  ) async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String id = DonneesDossiersDemo.familleDispensee;
    final GoRouter routeur = await _monterPersonne(tester, etat, id);
    await RevueDossiersDemo(etat).decider(
      dossierId: id,
      revisionAttendue: etat.dossiers[id]!.revision,
      decision: DecisionDossier.valider,
      commandeId: 'ad10-t8c',
      verificationsFaites: const <String>{},
    );
    await _pauseEtRetour(tester);
    expect(_chemin(routeur), startsWith(Routes.tuteurAccueil));
    expect(find.textContaining('Aïcha'), findsNothing);
    expect(find.textContaining('Yusuf'), findsNothing);
  });

  test('deux resoumissions : pieces distinctes, decisions separees', () async {
    final EtatRevueDemo etat = EtatRevueDemo.initial();
    const String a = DonneesDossiersDemo.tuteurDocumentaire;
    const String b = DonneesDossiersDemo.enseignantNominal;
    for (final String id in <String>[a, b]) {
      await RevueDossiersDemo(etat).decider(
        dossierId: id,
        revisionAttendue: etat.dossiers[id]!.revision,
        decision: DecisionDossier.refuser,
        commandeId: 'ad10-u2-$id',
        verificationsFaites: const <String>{},
        motif: 'Motif fictif.',
      );
      etat.resoumettre(id);
    }
    final String? pieceA = etat.dossiers[a]!.documentId;
    final String? pieceB = etat.dossiers[b]!.documentId;
    expect(pieceA, isNot(pieceB));

    final ServiceValidationDemo service = ServiceValidationDemo(etat);
    await service.decider(
      documentId: pieceB!,
      approuve: false,
      motif: 'Motif fictif B.',
    );
    expect(etat.dossiers[b]!.statut, StatutRevue.refuse);
    expect(etat.dossiers[a]!.statut, StatutRevue.aVerifier);
    await service.decider(
      documentId: pieceA!,
      approuve: false,
      motif: 'Motif fictif A.',
    );
    expect(etat.dossiers[a]!.motifRefus, 'Motif fictif A.');
    expect(etat.dossiers[b]!.motifRefus, 'Motif fictif B.');
  });

  test('T11 garde : la demonstration titulaire est fermee en production', () {
    expect(
      () => surchargesDemoTuteur(
        environnement: 'production',
        dossiers: EtatRevueDemo.initial(),
        titulaire: DonneesDossiersDemo.tuteurDocumentaire,
      ),
      throwsStateError,
    );
  });
}
