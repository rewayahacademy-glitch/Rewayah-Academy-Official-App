import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/appareils/appairage_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';

import '../support/harnais.dart';

EleveDuFoyer _eleve({String id = 'e1', String prenom = 'Amina'}) =>
    EleveDuFoyer(
      id: id,
      prenom: prenom,
      identifiantImmuable: 'STUDENT-AD-000001',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
    );

AppareilAppaire _appareil({
  String id = 'd1',
  String profilId = 'e1',
  DateTime? revoque,
}) => AppareilAppaire(
  id: id,
  profilId: profilId,
  prenom: 'Amina',
  plateforme: 'android',
  appaireA: DateTime(2026, 9, 1),
  revoqueA: revoque,
);

Future<FauxServiceAppairage> _monter(
  WidgetTester tester,
  FauxServiceAppairage service,
) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.tuteurFoyer,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.tuteurFoyer,
          builder: (BuildContext _, GoRouterState _) => const AppareilsPage(),
        ),
        GoRoute(
          path: '${Routes.tuteurAppairer}/:eleveId',
          builder: (BuildContext _, GoRouterState etat) =>
              AppairagePage(eleveId: etat.pathParameters['eleveId'] ?? ''),
        ),
      ],
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(service),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  group('Scenario 11 : a la limite, le bouton disparait au lieu d echouer', () {
    testWidgets('un appareil sur deux : le bouton d ajout est la', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_eleve()]
          ..appareilsRendus = <AppareilAppaire>[_appareil()],
      );

      expect(find.text(t.appareils.ajouter), findsOneWidget);
      expect(find.textContaining('Amina'), findsWidgets);
    });

    testWidgets('deux appareils sur deux : un message, et plus de bouton', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_eleve()]
          ..appareilsRendus = <AppareilAppaire>[
            _appareil(),
            _appareil(id: 'd2'),
          ],
      );

      expect(find.text(t.appareils.ajouter), findsNothing);
      expect(
        find.text(t.appareils.limiteAtteinte(prenom: 'Amina')),
        findsOneWidget,
        reason:
            'La limite doit s expliquer. Un bouton qui echoue apres le geste '
            'coute plus cher en confiance qu un bouton absent.',
      );
    });

    testWidgets('un appareil revoque ne compte plus dans le plafond', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_eleve()]
          ..appareilsRendus = <AppareilAppaire>[
            _appareil(),
            _appareil(id: 'd2', revoque: DateTime(2026, 9, 3)),
          ],
      );

      expect(find.text(t.appareils.ajouter), findsOneWidget);
    });

    testWidgets('la regle des deux appareils est affichee en clair', (
      WidgetTester tester,
    ) async {
      // ADR-010 : « deux appareils au maximum, un seul en seance a la fois ».
      // Une regle que l utilisateur decouvre en la heurtant est une mauvaise
      // surprise.
      await _monter(
        tester,
        FauxServiceAppairage()..elevesRendus = <EleveDuFoyer>[_eleve()],
      );
      expect(find.text(t.appareils.regle), findsOneWidget);
    });

    testWidgets('sans enfant, l ecran invite a en ajouter un', (
      WidgetTester tester,
    ) async {
      await _monter(tester, FauxServiceAppairage());
      expect(find.text(t.enfant.aucun), findsOneWidget);
      expect(find.text(t.enfant.aucunDetail), findsOneWidget);
    });

    testWidgets('la revocation passe par le service, pas par l ecran', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = await _monter(
        tester,
        FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_eleve()]
          ..appareilsRendus = <AppareilAppaire>[_appareil()],
      );

      await tester.tap(find.text(t.appareils.revoquer));
      await tester.pumpAndSettle();

      expect(service.revocations, <String>['d1']);
    });
  });

  group('L ecran d appairage', () {
    testWidgets('le code est demande a l entree, et affiche avec son delai', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = await _monter(
        tester,
        FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_eleve()]
          ..appareilsRendus = <AppareilAppaire>[],
      );

      await tester.tap(find.text(t.appareils.ajouter));
      await tester.pumpAndSettle();

      expect(service.codesDemandes, <String>['e1']);
      // Le code est espace pour etre lu a voix haute sans se tromper.
      expect(find.text('A B 2 3 C D'), findsOneWidget);
      expect(find.textContaining('Encore 9:'), findsOneWidget);
    });

    testWidgets('un code expire propose d en generer un autre', (
      WidgetTester tester,
    ) async {
      final FauxServiceAppairage service = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_eleve()]
        ..code = CodeAppairage(
          code: 'AB23CD',
          expireA: DateTime.now().subtract(const Duration(seconds: 1)),
        );
      await _monter(tester, service);

      await tester.tap(find.text(t.appareils.ajouter));
      await tester.pumpAndSettle();

      expect(find.text(t.appareils.emetteur.expire.titre), findsOneWidget);
      expect(find.text(t.appareils.regenerer), findsOneWidget);
    });

    testWidgets('un refus de plafond de la base se dit, sans texte brut', (
      WidgetTester tester,
    ) async {
      // Le plafond est verifie EN BASE : deux ecrans ouverts en meme temps ne
      // doivent pas pouvoir creer un troisieme appareil.
      final FauxServiceAppairage service = FauxServiceAppairage()
        ..elevesRendus = <EleveDuFoyer>[_eleve()]
        ..erreurAJeter = StateError('plafond d appareils atteint');
      await _monter(tester, service);

      await tester.tap(find.text(t.appareils.ajouter));
      await tester.pumpAndSettle();

      expect(
        find.text(t.appareils.emetteur.erreur.plafondTitre),
        findsOneWidget,
      );
      expect(
        find.text(t.appareils.emetteur.erreur.plafondAction),
        findsOneWidget,
      );
    });
  });
}
