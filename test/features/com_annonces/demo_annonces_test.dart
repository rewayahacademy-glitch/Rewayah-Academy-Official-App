// COM-ANN-1 : la demonstration de la voie (`/demo/communications?voie=
// annonces`), hors production seulement. Le catalogue par role de la spec
// section 13.2 dans la VRAIE `NotificationsPage`, et le parcours R-COM-12 de
// bout en bout : notification d'annonce, annonce, Espace Classe ou la meme
// annonce se lit, deja marquee lue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_de_classe.dart';
import 'package:rewayah_academy/features/com_annonces/carte_annonce_classe.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../router/support_routeur.dart';

final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
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
  await stabiliser(tester);
  return routeur;
}

String _adresse(RoleDemoCommunications role) =>
    adresseDemoCommunications(VoieDemoCommunications.annonces, role: role);

Finder _ligne(String id) => find.byKey(ValueKey<String>('notification-$id'));

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Catalogue de demonstration (spec section 13.2)', () {
    test('chaque role a son catalogue, chaque notification un type du '
        'catalogue ; une urgence et une annonce pour la famille', () {
      for (final RoleDemoCommunications role in RoleDemoCommunications.values) {
        final List<NotificationTuteur> liste = notificationsDemo(
          role,
          _maintenant,
        );
        expect(liste, isNotEmpty, reason: role.name);
        for (final NotificationTuteur n in liste) {
          expect(n.type, isNot(TypeNotification.autre), reason: n.id);
          // Aucune destination vers une page a session.
          expect(n.destination, isNull, reason: n.id);
        }
      }
      final List<NotificationTuteur> famille = notificationsDemo(
        RoleDemoCommunications.tuteur,
        _maintenant,
      );
      expect(
        famille.where((NotificationTuteur n) => n.niveau.name == 'urgent'),
        hasLength(1),
      );
      expect(
        famille.where((NotificationTuteur n) => n.annonceId != null),
        hasLength(1),
      );
      // Les types annonces aux familles ne sont pas ceux de la direction.
      expect(
        famille.map((NotificationTuteur n) => n.type),
        isNot(contains(TypeNotification.dossierATraiter)),
      );
    });

    test('les annonces de demonstration menent a l Espace Classe de '
        'demonstration, jamais a une page a session', () {
      final Map<String, List<AnnonceClasse>> annonces = annoncesDemo(
        RoleDemoCommunications.tuteur,
        _maintenant,
      );
      final AnnonceClasse a = annonces[ClassesDemoAnnonces.nour]!.single;
      expect(
        a.classe.destination,
        adresseClasseDemo(
          RoleDemoCommunications.tuteur,
          ClassesDemoAnnonces.nour,
        ),
      );
      expect(a.classe.destination, startsWith(Routes.demoCommunications));
    });
  });

  group('La demonstration rendue', () {
    testWidgets('sans role : un lien par role, chacun ouvre le centre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        adresseDemoCommunications(VoieDemoCommunications.annonces),
      );
      for (final RoleDemoCommunications r in RoleDemoCommunications.values) {
        expect(
          find.byKey(ValueKey<String>('lien-role-${r.name}')),
          findsOneWidget,
        );
      }
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('lien-role-enseignant')),
      );
      expect(lieu(routeur), _adresse(RoleDemoCommunications.enseignant));
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(_ligne('demo-e-mention'), findsOneWidget);
    });

    for (final RoleDemoCommunications role in RoleDemoCommunications.values) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        testWidgets('${role.name}, ${taille.width.toInt()} : le centre rend '
            'son catalogue, sans exception', (WidgetTester tester) async {
          await _monter(tester, _adresse(role), taille: taille);
          expect(find.byType(ComAnnoncesDemo), findsOneWidget);
          expect(find.byType(NotificationsPage), findsOneWidget);
          for (final NotificationTuteur n in notificationsDemo(
            role,
            _maintenant,
          )) {
            expect(_ligne(n.id), findsOneWidget, reason: n.id);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('famille, 390 : R-COM-12 de bout en bout, la lecture suit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        _adresse(RoleDemoCommunications.tuteur),
      );
      // L'urgence en tete.
      expect(
        tester.getTopLeft(_ligne('demo-t-urgent')).dy,
        lessThan(tester.getTopLeft(_ligne('demo-t-annonce')).dy),
      );
      await _toucher(tester, _ligne('demo-t-annonce'));
      expect(find.byType(CarteAnnonceClasse), findsOneWidget);
      expect(find.text(t.com.annonces.demo.f.annonceNourTexte), findsOneWidget);

      await _toucher(tester, find.byKey(CarteAnnonceClasse.cleOuvrirClasse));
      expect(
        lieu(routeur),
        adresseClasseDemo(
          RoleDemoCommunications.tuteur,
          ClassesDemoAnnonces.nour,
        ),
      );
      expect(find.text(t.com.annonces.demo.classeNour), findsWidgets);
      expect(find.byType(AnnoncesDeClasse), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('annonce-demo-annonce-nour')),
        findsOneWidget,
      );
      // Lue depuis la notification : plus de « Marquer comme lue ».
      expect(find.byKey(CarteAnnonceClasse.cleMarquerLue), findsNothing);

      // Le retour ramene au centre, ou la notification n'est plus non lue.
      await _toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(
        find.descendant(
          of: _ligne('demo-t-annonce'),
          matching: find.textContaining(t.notifications.nonLue),
        ),
        findsNothing,
      );
    });

    testWidgets('famille, 1440 : liste et detail cote a cote', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        _adresse(RoleDemoCommunications.tuteur),
        taille: const Size(1440, 900),
      );
      expect(find.byKey(NotificationsPage.cleDetail), findsOneWidget);
      await _toucher(tester, _ligne('demo-t-urgent'));
      expect(
        find.descendant(
          of: find.byKey(NotificationsPage.cleDetail),
          matching: find.text(t.com.annonces.demo.f.tuteurUrgentTexte),
        ),
        findsOneWidget,
      );
    });

    test('jamais en production : aucune route', () {
      expect(routesDemoCommunications('production'), isEmpty);
    });
  });
}
