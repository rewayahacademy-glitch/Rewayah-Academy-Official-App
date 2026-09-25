import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../support/harnais.dart';

EleveDuFoyer _enfant({String id = 'e1', String prenom = 'Amina'}) =>
    EleveDuFoyer(
      id: id,
      prenom: prenom,
      identifiantImmuable: 'STUD-AD-000001',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
    );

void main() {
  test('les preferences locales se modifient sans service distant', () {
    final ProviderContainer conteneur = ProviderContainer();
    addTearDown(conteneur.dispose);

    expect(
      conteneur.read(preferencesLocalesProvider).theme,
      PreferenceTheme.systeme,
    );
    conteneur
        .read(preferencesLocalesProvider.notifier)
        .theme(PreferenceTheme.sombre);
    conteneur
        .read(preferencesLocalesProvider.notifier)
        .notificationsCours(false);

    expect(
      conteneur.read(preferencesLocalesProvider),
      allOf(
        isA<PreferencesLocales>(),
        predicate<PreferencesLocales>(
          (PreferencesLocales preferences) =>
              preferences.theme == PreferenceTheme.sombre &&
              !preferences.notificationsCours,
        ),
      ),
    );
  });

  testWidgets('les reglages presentent les sections locales', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const ReglagesComptePage(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      ),
    );

    expect(find.text(t.compte.apparence), findsOneWidget);
    expect(find.text(t.compte.accessibilite), findsOneWidget);
    expect(find.text(t.compte.notifications), findsOneWidget);
    expect(find.text(t.compte.economieDonnees), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(6));
    expect(find.byType(Radio<PreferenceTheme>), findsNWidgets(3));
  });

  testWidgets('les reglages restent lisibles en RTL a 200 pour cent', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      hote(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 8000),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ReglagesComptePage(),
          ),
        ),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsNWidgets(6));
    expect(find.byType(Radio<PreferenceTheme>), findsNWidgets(3));
  });

  testWidgets('un tuteur voit les profils rendus par le foyer', (
    WidgetTester tester,
  ) async {
    final FauxServiceAppairage service = FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[_enfant()];

    await tester.pumpWidget(
      hote(
        const ProfilsComptePage(),
        surcharges: <Override>[
          serviceAppairageProvider.overrideWithValue(service),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amina'), findsWidgets);
    expect(find.textContaining('STUD-AD-000001'), findsOneWidget);
    expect(find.text(t.compte.modeEnfant), findsOneWidget);
  });

  testWidgets('les profils tiennent en RTL a 200 pour cent', (
    WidgetTester tester,
  ) async {
    final FauxServiceAppairage service = FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[_enfant()];
    tester.view.physicalSize = const Size(390, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      hote(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 8000),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ProfilsComptePage(),
          ),
        ),
        surcharges: <Override>[
          serviceAppairageProvider.overrideWithValue(service),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Amina'), findsWidgets);
  });

  testWidgets('un admin ne voit pas de roles deduits par la page Compte', (
    WidgetTester tester,
  ) async {
    const SessionState session = SessionState(
      resolue: true,
      role: AppRole.admin,
      profileId: 'admin-1',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    );

    await tester.pumpWidget(
      hote(
        const ComptePage(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession(session)),
        ],
      ),
    );
    await tester.pump();

    expect(find.text(t.compte.roles.admin), findsWidgets);
    expect(find.text(t.compte.roles.teacher), findsNothing);
    expect(find.text(t.compte.roles.accountant), findsNothing);
  });

  testWidgets('les reglages d un profil enfant menent a sa fiche du Foyer', (
    WidgetTester tester,
  ) async {
    final FauxServiceAppairage service = FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[_enfant()];
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.compteProfilEnfantPour('e1'),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.compteProfilEnfantPour('e1'),
            builder: (BuildContext _, GoRouterState _) =>
                const ProfilEnfantPage(profilId: 'e1'),
          ),
          GoRoute(
            path: Routes.ficheElevePour('e1'),
            builder: (BuildContext _, GoRouterState _) => const Text('FICHE'),
          ),
        ],
        surcharges: <Override>[
          serviceAppairageProvider.overrideWithValue(service),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final Finder reglages = find.text(t.compte.reglages);
    await tester.ensureVisible(reglages);
    await tester.tap(reglages);
    await tester.pumpAndSettle();

    expect(find.text('FICHE'), findsOneWidget);
  });

  testWidgets('les profils exposent le chargement sous forme de squelette', (
    WidgetTester tester,
  ) async {
    final Completer<List<EleveDuFoyer>> attente =
        Completer<List<EleveDuFoyer>>();
    await tester.pumpWidget(
      hote(
        const ProfilsComptePage(),
        surcharges: <Override>[
          elevesDuFoyerProvider.overrideWith((ref) => attente.future),
        ],
      ),
    );

    await tester.pump();
    expect(find.byType(Skeleton), findsOneWidget);
  });

  testWidgets('les profils exposent une erreur recuperable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        const ProfilsComptePage(),
        surcharges: <Override>[
          elevesDuFoyerProvider.overrideWith(
            (ref) async => throw StateError('fixture'),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(t.compte.erreurProfils), findsOneWidget);
    expect(find.text(t.compte.reessayer), findsWidgets);
  });
}
