// L4-01 : le libelle du bouton et la phrase d'introduction suivent le chemin
// choisi. Champ de mot de passe vide : lien par courriel. Rempli : connexion de
// demonstration. Le champ n'existe qu'hors production (K-59 : dire ce qui se
// passe, aucun bouton grise).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../../support/harnais.dart';

const ValueKey<String> _cleCourriel = ValueKey<String>('connexion-courriel');
const ValueKey<String> _cleMotDePasse = ValueKey<String>(
  'connexion-mot-de-passe',
);

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAuth auth,
  bool demoAutorisee = true,
  String environnement = 'developpement',
  Size taille = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    hote(
      const ConnexionPage(),
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(auth),
        demoAuthActiveProvider.overrideWithValue(demoAutorisee),
        environnementConnexionProvider.overrideWithValue(environnement),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

ActionPrincipale _bouton(WidgetTester tester) =>
    tester.widget<ActionPrincipale>(find.byType(ActionPrincipale).first);

void _verifierEtatVide(WidgetTester tester) {
  expect(
    find.widgetWithText(ActionPrincipale, t.connexion.envoyerLien),
    findsOneWidget,
  );
  expect(find.text(t.connexion.entrerDemo), findsNothing);
  expect(find.text(t.connexion.intro), findsOneWidget);
  expect(find.text(t.connexion.introDemo), findsNothing);
}

void _verifierEtatRempli(WidgetTester tester) {
  expect(
    find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
    findsOneWidget,
  );
  expect(find.text(t.connexion.envoyerLien), findsNothing);
  expect(find.text(t.connexion.introDemo), findsOneWidget);
  expect(find.text(t.connexion.intro), findsNothing);
}

void main() {
  group('libelles selon le chemin (FR)', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('champ vide puis rempli : le bouton et la phrase basculent '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        final FauxServiceAuth auth = FauxServiceAuth();
        await _monter(tester, auth: auth, taille: taille);

        _verifierEtatVide(tester);
        expect(_bouton(tester).onPress, isNotNull);

        await tester.enterText(find.byKey(_cleMotDePasse), 'essai-local');
        await tester.pump();
        _verifierEtatRempli(tester);
        expect(_bouton(tester).onPress, isNotNull);

        await tester.enterText(find.byKey(_cleMotDePasse), '');
        await tester.pump();
        _verifierEtatVide(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'le champ vide envoie un lien, le champ rempli connecte sans lien',
      (WidgetTester tester) async {
        final FauxServiceAuth auth = FauxServiceAuth();
        await _monter(tester, auth: auth);

        await tester.enterText(find.byKey(_cleCourriel), 'fatou@example.test');
        await tester.pump();
        await tester.tap(
          find.widgetWithText(ActionPrincipale, t.connexion.envoyerLien),
        );
        await tester.pumpAndSettle();
        expect(auth.liensEnvoyes, <String>['fatou@example.test']);
        expect(auth.connexionsMotDePasse, isEmpty);
      },
    );

    testWidgets('le champ rempli se connecte avec le mot de passe', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(tester, auth: auth);

      await tester.enterText(find.byKey(_cleCourriel), 'fatou@example.test');
      await tester.enterText(find.byKey(_cleMotDePasse), 'essai-local');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
      );
      await tester.pumpAndSettle();

      expect(auth.liensEnvoyes, isEmpty);
      expect(
        auth.connexionsMotDePasse,
        <({String courriel, String motDePasse})>[
          (courriel: 'fatou@example.test', motDePasse: 'essai-local'),
        ],
      );
    });
  });

  group('champ de mot de passe absent hors demonstration', () {
    testWidgets('production : ni champ, ni libelle alternatif', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        auth: FauxServiceAuth(),
        environnement: 'production',
      );
      expect(find.byKey(_cleMotDePasse), findsNothing);
      _verifierEtatVide(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'demonstration non compilee : ni champ, ni libelle alternatif',
      (WidgetTester tester) async {
        await _monter(tester, auth: FauxServiceAuth(), demoAutorisee: false);
        expect(find.byKey(_cleMotDePasse), findsNothing);
        _verifierEtatVide(tester);
      },
    );
  });

  group('libelles en arabe', () {
    setUpAll(() async {
      await LocaleSettings.setLocale(AppLocale.ar);
    });
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      testWidgets('AR : le bouton et la phrase basculent avec le champ '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        await _monter(tester, auth: FauxServiceAuth(), taille: taille);

        expect(find.text('استلام الرابط'), findsOneWidget);
        expect(find.text(t.connexion.envoyerLien), findsOneWidget);

        await tester.enterText(find.byKey(_cleMotDePasse), 'essai-local');
        await tester.pump();
        expect(find.text('الدخول إلى العرض التجريبي'), findsOneWidget);
        expect(
          find.text(
            'وضع العرض التجريبي: لن يُرسل أي رابط. ستدخل مباشرة دون بريد إلكتروني.',
          ),
          findsOneWidget,
        );
        expect(find.text(t.connexion.envoyerLien), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('trois chemins, un seul libelle', () {
    test('cheminConnexion : un cas par branche', () {
      expect(
        cheminConnexion(
          demo: false,
          courriel: 'admin@demo.test',
          motDePasse: 'x',
        ),
        CheminConnexion.lien,
      );
      expect(
        cheminConnexion(
          demo: true,
          courriel: 'fatou@example.test',
          motDePasse: 'x',
        ),
        CheminConnexion.motDePasse,
      );
      expect(
        cheminConnexion(
          demo: true,
          courriel: 'admin@demo.test',
          motDePasse: '',
        ),
        CheminConnexion.demoDirecte,
      );
      expect(
        cheminConnexion(
          demo: true,
          courriel: 'fatou@example.test',
          motDePasse: '',
        ),
        CheminConnexion.lien,
      );
    });

    testWidgets(
      'adresse fictive sans mot de passe : entree directe, libelle de demonstration',
      (WidgetTester tester) async {
        final FauxServiceAuth auth = FauxServiceAuth();
        await _monter(tester, auth: auth);

        await tester.enterText(find.byKey(_cleCourriel), 'admin@demo.test');
        await tester.pump();
        _verifierEtatRempli(tester);
        expect(find.byKey(_cleMotDePasse), findsOneWidget);

        await tester.tap(
          find.widgetWithText(ActionPrincipale, t.connexion.entrerDemo),
        );
        await tester.pumpAndSettle();
        expect(auth.liensEnvoyes, isEmpty);
        expect(auth.connexionsMotDePasse, isEmpty);
      },
    );
  });
}
