// Captures de JUR-APP-1 : textes juridiques valides le 02/10/2026 portes dans
// l'application. Le bandeau de la salle (guidee) avec son lien « En savoir
// plus », la lecture E-1 ouverte, la carte d'accuse (A3 tuteur, E1
// enseignant) et le contrat (tuteur, enseignant avec clause et case art. 9).
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Les pages de texte
// sont capturees dans une vue haute (390 x 2400) pour montrer le texte entier.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

Future<void> _monterDossier(
  WidgetTester tester, {
  required String depart,
  required AppRole role,
  Size taille = const Size(390, 2400),
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = EtatDossier(
      profilExiste: true,
      role: role,
      statutCompte: AccountStatus.pendingKyc,
      accuseSigne: depart == Routes.attenteContrat,
    );
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.attenteAccuse,
        builder: (BuildContext _, GoRouterState _) => const AccusePage(),
      ),
      GoRoute(
        path: Routes.attenteContrat,
        builder: (BuildContext _, GoRouterState _) => const ContratPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[serviceDossierProvider.overrideWithValue(dossier)],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Future<void> _monterSalle(WidgetTester tester, Size taille) async {
  fixerVueCapture(tester, taille, 2);
  await tester.pumpWidget(
    hoteCapture(
      SalleDemo(
        role: RoleSeance.guidee,
        etat: EtatDemoSalle.repos,
        onSortir: () {},
      ),
      interfaceMode: InterfaceMode.enfant,
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture JUR-APP-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (String nom, Size taille) in <(String, Size)>[
      ('390x844', const Size(390, 844)),
      ('1440x900', const Size(1440, 900)),
    ]) {
      testWidgets('salle guidee, bandeau et lien, $nom', (
        WidgetTester tester,
      ) async {
        await _monterSalle(tester, taille);
        expect(find.text(t.salle.informationControle.lien), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'jur_app1_salle_guidee_bandeau_$nom')}',
        );

        await tester.tap(find.text(t.salle.informationControle.lien));
        await stabiliser(tester);
        expect(find.text(t.salle.informationControle.e1.titre), findsOneWidget);
        debugPrint(
          'PNG ${await capturer(tester, 'jur_app1_salle_guidee_e1_$nom')}',
        );
      });
    }

    testWidgets('accuse tuteur (A3)', (WidgetTester tester) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteAccuse,
        role: AppRole.guardian,
      );
      debugPrint('PNG ${await capturer(tester, 'jur_app1_accuse_tuteur_a3')}');
    });

    testWidgets('accuse enseignant (E1)', (WidgetTester tester) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteAccuse,
        role: AppRole.teacher,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'jur_app1_accuse_enseignant_e1')}',
      );
    });

    testWidgets('contrat tuteur (A3 et observation)', (
      WidgetTester tester,
    ) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteContrat,
        role: AppRole.guardian,
      );
      debugPrint('PNG ${await capturer(tester, 'jur_app1_contrat_tuteur')}');
    });

    testWidgets('contrat enseignant (E1, clause, case art. 9)', (
      WidgetTester tester,
    ) async {
      await _monterDossier(
        tester,
        depart: Routes.attenteContrat,
        role: AppRole.teacher,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'jur_app1_contrat_enseignant')}',
      );
    });
  });
}
