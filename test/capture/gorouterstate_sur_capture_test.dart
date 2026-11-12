// Captures R3 de GOROUTERSTATE-SUR : les ecrans dont la lecture de l'etat du
// routeur passe maintenant par etatRouteurSur s'affichent comme avant, y
// compris dans les deux formes qui gelaient (donnees de demonstration).
//
// - le Compte de l'enseignant, puis « Identite professionnelle » ouverte
//   (page poussee par Navigator.push : la forme de CRASH-MON-ESPACE) ;
// - la demonstration des Messages (lecture `?situation=` substituee), dans
//   un onglet d'une coquille StatefulShellRoute ;
// - une feuille du bas ouverte au-dessus de cette demonstration, qui lit
//   l'adresse de la page du dessous.
// 390 et 1440, clair ; arabe pour chacune.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/GOROUTERSTATE-SUR \
//   flutter test test/capture/gorouterstate_sur_capture_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/etat_routeur_sur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

import '../support/demo/demo_enseignant_page.dart';
import '../support/demo/enseignant_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const List<(String, double, AppLocale)> _variantes =
    <(String, double, AppLocale)>[
      ('390-clair', 390, AppLocale.fr),
      ('390-arabe', 390, AppLocale.ar),
      ('1440-clair', 1440, AppLocale.fr),
    ];

GoRouter _routeur() => GoRouter(
  initialLocation: '/demo/messages?situation=normale',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext _,
        GoRouterState _,
        StatefulNavigationShell coquille,
      ) => Scaffold(body: coquille),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/demo/messages',
              builder: (BuildContext _, GoRouterState _) =>
                  const ComMessagesDemo(role: RoleDemoCommunications.tuteur),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _hoteRouteur(GoRouter routeur) => ProviderScope(
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
);

void main() {
  group('Capture : GOROUTERSTATE-SUR', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final (String v, double l, AppLocale langue) in _variantes) {
      testWidgets('compte-enseignant-identite-$v', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, Size(l, l < 600 ? 1400 : 1000), 1);
        await tester.pumpWidget(
          hoteCapture(
            const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.profil),
            surcharges: <Override>[
              depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            ],
          ),
        );
        await stabiliser(tester);
        await tester.ensureVisible(
          find.byKey(ProfilEnseignantPage.identiteKey),
        );
        await tester.pump();
        await tester.tap(find.byKey(ProfilEnseignantPage.identiteKey));
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(ProfilEnseignantPage.identiteKey), findsNothing);
        await capturerVue(tester, 'compte-enseignant-identite-$v');
      });

      testWidgets('demo-messages-onglet-$v', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, Size(l, l < 600 ? 1200 : 900), 1);
        await tester.pumpWidget(_hoteRouteur(_routeur()));
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(ComMessagesDemo), findsOneWidget);
        await capturerVue(tester, 'demo-messages-onglet-$v');
      });

      testWidgets('feuille-sur-demo-messages-$v', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        fixerVueCapture(tester, Size(l, l < 600 ? 1200 : 900), 1);
        await tester.pumpWidget(_hoteRouteur(_routeur()));
        await stabiliser(tester);
        final BuildContext page = tester.element(find.byType(ComMessagesDemo));
        // La feuille lit l'adresse de la page du dessous par etatRouteurSur :
        // une route qui n'est pas une page du routeur, sans gel.
        unawaited(
          AppBottomSheet.ouvrir<void>(
            page,
            titre: 'situation',
            constructeur: (BuildContext feuille) => Text(
              '${adresseRouteurSur(feuille)?.path} · '
              '${parametreRouteurSur(feuille, 'situation')}',
            ),
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('/demo/messages · normale'), findsOneWidget);
        await capturerVue(tester, 'feuille-sur-demo-messages-$v');
      });
    }
  });
}
