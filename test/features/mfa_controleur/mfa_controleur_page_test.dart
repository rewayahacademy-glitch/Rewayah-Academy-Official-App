// L1-10 : l'ecran de seconde etape du controleur, aux cinq etats (chargement,
// contenu en enrolement et en verification, vide, erreur, hors ligne), en
// francais et en arabe (RTL), a 390 et a 1440, clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/mfa_controleur/mfa_controleur_page.dart';
import 'package:rewayah_academy/features/mfa_controleur/port_mfa.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

class _PortFaux implements PortMfa {
  _PortFaux({this.situationRendue = const MfaAEnroler()});

  SituationMfa situationRendue;
  Object? erreurSituation;
  Object? erreurVerification;
  Completer<SituationMfa>? attente;
  int enrolements = 0;
  final List<({String facteurId, String code})> verifications =
      <({String facteurId, String code})>[];

  @override
  Future<SituationMfa> situation() {
    final Object? e = erreurSituation;
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
    return attente?.future ?? Future<SituationMfa>.value(situationRendue);
  }

  @override
  Future<EnrolementTotp> enroler() async {
    enrolements++;
    return const EnrolementTotp(
      facteurId: 'f-nouveau',
      uri: 'otpauth://totp/Rewayah:c@test?secret=JBSWY3DPEHPK3PXP&issuer=Rewayah',
      secret: 'JBSWY3DPEHPK3PXP',
    );
  }

  @override
  Future<void> verifier({
    required String facteurId,
    required String code,
  }) async {
    verifications.add((facteurId: facteurId, code: code));
    final Object? e = erreurVerification;
    if (e != null) {
      // ignore: only_throw_errors
      throw e;
    }
  }
}

Future<void> _monter(
  WidgetTester tester,
  _PortFaux port, {
  FauxServiceAuth? auth,
  Size taille = const Size(390, 844),
  bool ar = false,
  bool sombre = false,
}) async {
  await tester.runAsync(
    () => LocaleSettings.setLocale(ar ? AppLocale.ar : AppLocale.fr),
  );
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.mfaControleur,
      direction: ar ? TextDirection.rtl : null,
      themeMode: sombre ? ThemeMode.dark : ThemeMode.light,
      surcharges: <Override>[
        portMfaProvider.overrideWithValue(port),
        serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
      ],
      routes: <RouteBase>[
        GoRoute(
          path: Routes.mfaControleur,
          builder: (BuildContext _, GoRouterState _) =>
              const MfaControleurPage(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void _proprete(WidgetTester tester) {
  expect(tester.takeException(), isNull, reason: 'exception de mise en page');
  expect(
    motsCoupes(tester, find.byType(Scaffold)),
    isEmpty,
    reason: 'un mot coupe ou tronque',
  );
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final (String nom, bool ar, Size taille, bool sombre)
      in <(String, bool, Size, bool)>[
        ('fr 390 clair', false, const Size(390, 844), false),
        ('fr 1440 clair', false, const Size(1440, 900), false),
        ('ar 390 sombre', true, const Size(390, 844), true),
        ('ar 1440 clair', true, const Size(1440, 900), false),
      ]) {
    group(nom, () {
      testWidgets('enrolement : QR, cle, code a six chiffres', (
        WidgetTester tester,
      ) async {
        final _PortFaux port = _PortFaux();
        await _monter(tester, port, taille: taille, ar: ar, sombre: sombre);
        final m = t.controleur.mfa;
        expect(find.text(m.titreEnrolement), findsOneWidget);
        expect(find.text(m.champCode), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
        expect(find.text(m.activer), findsOneWidget);
        expect(port.enrolements, 1);
        _proprete(tester);
      });

      testWidgets('verification : facteur deja enrole, aucun QR', (
        WidgetTester tester,
      ) async {
        final _PortFaux port = _PortFaux(
          situationRendue: const MfaAVerifier('f-1'),
        );
        await _monter(tester, port, taille: taille, ar: ar, sombre: sombre);
        final m = t.controleur.mfa;
        expect(find.text(m.titreVerification), findsOneWidget);
        expect(find.text(m.titreEnrolement), findsNothing);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text(m.confirmer), findsOneWidget);
        expect(port.enrolements, 0);
        _proprete(tester);
      });

      testWidgets('vide : pas d application, aide et retour', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          _PortFaux(),
          taille: taille,
          ar: ar,
          sombre: sombre,
        );
        final m = t.controleur.mfa;
        await tester.ensureVisible(
          find.byKey(MfaControleurPage.sansApplicationKey),
        );
        await tester.tap(find.byKey(MfaControleurPage.sansApplicationKey));
        await tester.pumpAndSettle();
        expect(find.text(m.videTitre), findsOneWidget);
        expect(find.text(m.videPhrase), findsOneWidget);
        expect(find.text(m.videRetour), findsOneWidget);
        _proprete(tester);
      });

      testWidgets('erreur : phrase humaine, reessayer relit', (
        WidgetTester tester,
      ) async {
        final _PortFaux port = _PortFaux()..erreurSituation = StateError('x');
        await _monter(tester, port, taille: taille, ar: ar, sombre: sombre);
        final e = t.commun.etats;
        expect(find.text(e.echecServeur.titre), findsOneWidget);
        port.erreurSituation = null;
        await tester.tap(find.text(e.actions.reessayer));
        await tester.pumpAndSettle();
        expect(find.text(t.controleur.mfa.titreEnrolement), findsOneWidget);
        _proprete(tester);
      });

      testWidgets('hors ligne : dit hors ligne, jamais une erreur', (
        WidgetTester tester,
      ) async {
        final _PortFaux port = _PortFaux()
          ..erreurSituation = const MfaHorsLigne();
        await _monter(tester, port, taille: taille, ar: ar, sombre: sombre);
        expect(find.text(t.commun.etats.horsLigne.titre), findsWidgets);
        expect(find.text(t.commun.etats.echecServeur.titre), findsNothing);
        _proprete(tester);
      });
    });
  }

  testWidgets('chargement : squelette tant que le serveur n a pas repondu', (
    WidgetTester tester,
  ) async {
    final Completer<SituationMfa> attente = Completer<SituationMfa>();
    final _PortFaux port = _PortFaux()..attente = attente;
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.mfaControleur,
        surcharges: <Override>[
          portMfaProvider.overrideWithValue(port),
          serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        ],
        routes: <RouteBase>[
          GoRoute(
            path: Routes.mfaControleur,
            builder: (BuildContext _, GoRouterState _) =>
                const MfaControleurPage(),
          ),
        ],
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('mfa-chargement')),
      findsOneWidget,
    );
    expect(find.text(t.controleur.mfa.titreEnrolement), findsNothing);
    attente.complete(const MfaAVerifier('f-1'));
    await tester.pumpAndSettle();
    expect(find.text(t.controleur.mfa.titreVerification), findsOneWidget);
  });

  group('saisie du code', () {
    testWidgets('moins de six chiffres : refus local, aucun appel serveur', (
      WidgetTester tester,
    ) async {
      final _PortFaux port = _PortFaux(
        situationRendue: const MfaAVerifier('f-1'),
      );
      await _monter(tester, port);
      await tester.enterText(
        find.byKey(MfaControleurPage.champCodeKey),
        '12a34',
      );
      await tester.tap(find.byKey(MfaControleurPage.boutonKey));
      await tester.pumpAndSettle();
      expect(find.text(t.controleur.mfa.codeIncomplet), findsOneWidget);
      expect(port.verifications, isEmpty);
    });

    testWidgets('six chiffres : envoyes au facteur enrole', (
      WidgetTester tester,
    ) async {
      final _PortFaux port = _PortFaux(
        situationRendue: const MfaAVerifier('f-1'),
      );
      await _monter(tester, port);
      await tester.enterText(
        find.byKey(MfaControleurPage.champCodeKey),
        '123456',
      );
      await tester.tap(find.byKey(MfaControleurPage.boutonKey));
      await tester.pumpAndSettle();
      expect(port.verifications, <({String facteurId, String code})>[
        (facteurId: 'f-1', code: '123456'),
      ]);
    });

    testWidgets('enrolement : le code verifie le facteur tout juste cree', (
      WidgetTester tester,
    ) async {
      final _PortFaux port = _PortFaux();
      await _monter(tester, port);
      await tester.enterText(
        find.byKey(MfaControleurPage.champCodeKey),
        '654321',
      );
      await tester.ensureVisible(find.byKey(MfaControleurPage.boutonKey));
      await tester.tap(find.byKey(MfaControleurPage.boutonKey));
      await tester.pumpAndSettle();
      expect(port.verifications.single.facteurId, 'f-nouveau');
    });

    testWidgets('code refuse par le serveur : phrase sur le champ', (
      WidgetTester tester,
    ) async {
      final _PortFaux port = _PortFaux(
        situationRendue: const MfaAVerifier('f-1'),
      )..erreurVerification = const MfaCodeRefuse();
      await _monter(tester, port);
      await tester.enterText(
        find.byKey(MfaControleurPage.champCodeKey),
        '000000',
      );
      await tester.tap(find.byKey(MfaControleurPage.boutonKey));
      await tester.pumpAndSettle();
      expect(find.text(t.controleur.mfa.codeRefuse), findsOneWidget);
    });

    testWidgets('reseau muet a la verification : dit hors ligne', (
      WidgetTester tester,
    ) async {
      final _PortFaux port = _PortFaux(
        situationRendue: const MfaAVerifier('f-1'),
      )..erreurVerification = const MfaHorsLigne();
      await _monter(tester, port);
      await tester.enterText(
        find.byKey(MfaControleurPage.champCodeKey),
        '111111',
      );
      await tester.tap(find.byKey(MfaControleurPage.boutonKey));
      await tester.pumpAndSettle();
      expect(find.text(t.commun.etats.horsLigne.phrase), findsOneWidget);
    });

    testWidgets('se deconnecter reste possible', (WidgetTester tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        _PortFaux(situationRendue: const MfaAVerifier('f-1')),
        auth: auth,
      );
      await tester.ensureVisible(find.text(t.controleur.mfa.seDeconnecter));
      await tester.tap(find.text(t.controleur.mfa.seDeconnecter));
      await tester.pumpAndSettle();
      expect(auth.deconnexions, 1);
    });
  });
}
