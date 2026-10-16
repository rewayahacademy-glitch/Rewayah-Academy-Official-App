// AD-7 : la visionneuse depuis la VRAIE coque admin et le vrai routeur, avec
// l'adaptateur de PRODUCTION et un ServiceValidation factice : aucune
// demonstration pour la revue (K-07). AD-M3-PROD : le vrai branchement
// (surchargeRevueDossiersProduction) ferme piece et refus jusqu'a BR-1 ; la
// visionneuse se teste sur l'adaptateur rebranche comme a BR-1.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/services_admin_demo.dart';

import '../../support/dossiers_production.dart';
import '../../support/harnais.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await _stabiliser(tester);
  await tester.tap(cible);
  await _stabiliser(tester);
}

ActionPrincipale _action(WidgetTester tester, String libelle) =>
    tester.widget<ActionPrincipale>(
      find
          .ancestor(
            of: find.text(libelle).first,
            matching: find.byType(ActionPrincipale),
          )
          .first,
    );

void main() {
  // AD-M3-PROD : le VRAI branchement de main.dart, depuis la coque admin.
  testWidgets('production depuis la coque : ni « Voir la piece » ni refus, '
      'aucune URL signee, aucun appel (decision du 27/09)', (
    WidgetTester tester,
  ) async {
    final FauxServiceValidation service = await _monterCoque(
      tester,
      surchargeRevueDossiersProduction,
    );
    expect(find.text(t.dossiers.revue.voirPiece), findsNothing);
    expect(find.text(t.dossiers.refuser), findsNothing);
    expect(find.text(t.dossiers.approuver), findsNothing);
    await tester.ensureVisible(
      find.text(t.dossiers.revue.etats.decisionIndisponible),
    );
    await _stabiliser(tester);
    expect(
      find.text(t.dossiers.revue.etats.decisionIndisponible),
      findsOneWidget,
    );
    expect(find.text(t.dossiers.revue.pieceIndisponible), findsOneWidget);
    expect(service.apercus, isEmpty);
    expect(service.verdicts, isEmpty);
  });

  testWidgets('branchee comme apres BR-1, depuis la coque : Personnes, la '
      'ligne, « Voir la piece », fermer, cocher ; Valider reste ferme (Q21)', (
    WidgetTester tester,
  ) async {
    final FauxServiceValidation service = await _monterCoque(
      tester,
      surchargeRevueDossiersBrancheeBR1,
    );

    // Avant lecture : cases fermees, validation fermee, refus ouvert.
    await tester.ensureVisible(find.text(t.dossiers.refuser));
    await _stabiliser(tester);
    expect(find.text(t.dossiers.approuver), findsNothing);
    expect(_action(tester, t.dossiers.refuser).onPress, isNotNull);

    await _toucher(tester, find.text(t.dossiers.revue.voirPiece));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await _stabiliser(tester);
    expect(find.byType(VisionneusePiece), findsOneWidget);
    // L2-02 : l'aperçu est demandé par identifiant de document, plus par clé.
    expect(service.apercus, <String>['doc1']);
    expect(find.textContaining('http'), findsNothing);
    await _toucher(
      tester,
      find.descendant(
        of: find.byType(VisionneusePiece),
        matching: find.text(t.commun.fermer),
      ),
    );
    expect(find.byType(VisionneusePiece), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'adm02b-voir-piece');

    for (final String point in <String>[
      t.dossiers.pointLisible,
      t.dossiers.pointNom,
      t.dossiers.pointValidite,
    ]) {
      await _toucher(tester, find.text(point));
    }
    // AD-8, Q21 : la consequence est inconnue en production, 02E ne s'ouvre
    // pas ; la raison est dite sous les actions (Q-AD8-1).
    await tester.ensureVisible(find.text(t.dossiers.validation.indisponible));
    await tester.pumpAndSettle();
    expect(find.text(t.dossiers.approuver), findsNothing);
    expect(find.text(t.dossiers.validation.indisponible), findsOneWidget);
    expect(service.verdicts, isEmpty);
  });
}

/// Monte la vraie coque admin avec [revue] comme adaptateur de revue, puis
/// ouvre le dossier de Moussa depuis « Personnes ».
Future<FauxServiceValidation> _monterCoque(
  WidgetTester tester,
  Override revue,
) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final FauxServiceValidation service = FauxServiceValidation()
    ..file = <DossierAValider>[
      DossierAValider(
        documentId: 'doc1',
        profilId: 'p1',
        type: TypePiece.carteIdentite,
        cleObjet: 'p1/piece.webp',
        deposeLe: DateTime(2026, 9, 4),
        prenom: 'Moussa',
        nom: 'Barry',
        identifiantImmuable: 'TEACHER-MB-000001',
        role: AppRole.teacher,
      ),
    ];
  final EtatRevueDemo e = EtatRevueDemo.initial();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        // Seules la session admin et la politique du relecteur sont
        // simulees ; la revue et la piece passent par la production.
        sourceSessionProvider.overrideWithValue(const SourceSessionDemoAdmin()),
        portPolitiqueRevueKycProvider.overrideWithValue(
          PolitiqueRevueKycDemo(e),
        ),
        // Aucune base locale : runAsync ferait sinon ouvrir drift.
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(),
        ),
        serviceValidationProvider.overrideWithValue(service),
        revue,
        imagePieceProvider.overrideWithValue(
          (Uri _) => MemoryImage(pngSynthetique),
        ),
        indicateursProvider.overrideWith(
          (Ref ref) async => const IndicateursAdmin(
            dossiersEnAttente: 1,
            foyersSansEnseignant: 0,
            rapportsManquants: 0,
            incidents24h: 0,
            comptesEchus: 0,
            demandesEnAttente: 0,
          ),
        ),
        demandesProvider.overrideWith((Ref ref) async => const <Demande>[]),
        ...surchargesServicesAdminIndisponibles(),
      ],
      child: TranslationProvider(child: const RewayahApp()),
    ),
  );
  await _stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(Routes.admin);
  await _stabiliser(tester);

  await _toucher(
    tester,
    find.descendant(
      of: find.byKey(AdminShell.barreLateraleKey),
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await _toucher(
    tester,
    find.bySemanticsLabel(RegExp('^Ouvrir le dossier de Moussa')),
  );
  return service;
}
