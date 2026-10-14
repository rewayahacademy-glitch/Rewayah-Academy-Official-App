// COM-F : la demonstration des Communications n'existe jamais en production
// (DEMO-ENV-1, lecon 14), et son index mene a chaque voie.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

Future<GoRouter> _monter(WidgetTester tester, String depart) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[...routesDemoCommunications('staging')],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return routeur;
}

void main() {
  group('La route de demonstration est fermee hors environnement autorise', () {
    for (final String env in <String>[
      'production',
      'Production ',
      'prod',
      '',
      '   ',
    ]) {
      test('« $env » : aucune route', () {
        expect(routesDemoCommunications(env), isEmpty);
      });
    }
    for (final String env in <String>['staging', 'dev', 'local']) {
      test('« $env » : la route existe', () {
        final List<RouteBase> routes = routesDemoCommunications(env);
        expect(routes, hasLength(1));
        expect((routes.single as GoRoute).path, Routes.demoCommunications);
      });
    }

    test('sans session, la porte ne s ouvre que hors production', () {
      final DateTime maintenant = DateTime.utc(2026, 10, 4, 10);
      for (final String chemin in <String>[
        Routes.demoCommunications,
        '${Routes.demoCommunications}?voie=messages',
      ]) {
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: Uri.parse(chemin).path,
            maintenant: maintenant,
            environnement: 'staging',
          ),
          isNull,
          reason: chemin,
        );
        expect(
          deciderRedirection(
            session: const SessionState.deconnecte(),
            cheminDemande: Uri.parse(chemin).path,
            maintenant: maintenant,
            environnement: 'production',
          ),
          isNotNull,
          reason: chemin,
        );
      }
    });
  });

  group('L index de la demonstration', () {
    testWidgets('un lien par voie, chacun ouvre la voie, retour a l index', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, Routes.demoCommunications);
      expect(find.text(t.com.socle.navigation.demo.titre), findsOneWidget);
      for (final VoieDemoCommunications voie in VoieDemoCommunications.values) {
        expect(
          find.byKey(ValueKey<String>('lien-voie-${voie.name}')),
          findsOneWidget,
          reason: voie.name,
        );
      }

      await tester.tap(
        find.byKey(const ValueKey<String>('lien-voie-messages')),
      );
      await tester.pumpAndSettle();
      expect(
        routeur.routerDelegate.currentConfiguration.uri.toString(),
        adresseDemoCommunications(VoieDemoCommunications.messages),
      );
      expect(find.byType(ComMessagesDemo), findsOneWidget);
      // COM-MSG-1 a rempli sa demonstration : elle ouvre sur le choix du
      // point de vue, plus sur « Bientot disponible ».
      expect(find.text(t.com.messages.demo.choisirRole), findsOneWidget);

      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(find.byType(ComMessagesDemo), findsNothing);
      expect(find.text(t.com.socle.navigation.demo.titre), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le role de l adresse est transmis a la voie', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoCommunications(
          VoieDemoCommunications.messages,
          role: RoleDemoCommunications.enseignant,
        ),
      );
      expect(
        tester.widget<ComMessagesDemo>(find.byType(ComMessagesDemo)).role,
        RoleDemoCommunications.enseignant,
      );
    });
  });
}
