// ANTI-ROBOT (03/11/2026) : le controle « je ne suis pas un robot » devant
// l'envoi du lien de connexion (fiche PLAN-LOTS §13).
//
// Ce que le test prouve :
// - reglage vide (aucun port, ou cle vide) : aucun controle a l'ecran, et
//   l'envoi part sans jeton, comme avant ;
// - la cle : celle du reglage, celle de TEST sur un apercu, aucune si la
//   lecture echoue ;
// - le controleur : il attend le jeton, le rend une fois, en demande un autre
//   apres l'envoi, rend nul si la verification n'aboutit pas ;
// - cle reglee : le controle est pose, le jeton part avec l'envoi (connexion
//   et recuperation) ; sans jeton, rien ne part et l'ecran dit « La
//   verification n'a pas abouti. Reessayez. » ; un refus du serveur
//   (`captcha_failed`) se dit pareil ;
// - 390 et 1440 px, texte x2, sans debordement.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/anti_robot.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/controle_anti_robot.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import '../../support/harnais.dart';

const ValueKey<String> _cleCourriel = ValueKey<String>('connexion-courriel');

class _Cle implements PortCleTurnstile {
  _Cle(this.valeur, {this.panne = false});

  final String? valeur;
  final bool panne;

  @override
  Future<String?> lire() async {
    if (panne) throw StateError('lecture');
    return valeur;
  }
}

/// Un controleur qui rend tout de suite un jeton, puis un autre a chaque
/// relance (comme le widget de Cloudflare).
class _ControleurJetons extends ControleurAntiRobot {
  _ControleurJetons({this.rendre = true}) {
    if (rendre) recevoirJeton('jeton-1');
  }

  final bool rendre;
  int relances = 0;

  @override
  void relancer() {
    super.relancer();
    relances++;
    if (rendre) recevoirJeton('jeton-${relances + 1}');
  }
}

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAuth auth,
  required Widget page,
  PortCleTurnstile? cle,
  ControleurAntiRobot Function()? fabrique,
  Size taille = const Size(390, 844),
  double echelle = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    hote(
      page,
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(auth),
        demoAuthActiveProvider.overrideWithValue(false),
        if (cle != null) portCleTurnstileProvider.overrideWithValue(cle),
        if (fabrique != null)
          fabriqueControleurAntiRobotProvider.overrideWithValue(fabrique),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _envoyer(
  WidgetTester tester,
  String libelle, {
  Key champ = _cleCourriel,
}) async {
  await tester.enterText(find.byKey(champ), 'fatou@example.test');
  await tester.pump();
  final Finder bouton = find.widgetWithText(ActionPrincipale, libelle);
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}

void main() {
  group('la cle', () {
    Future<String?> lire(List<Override> surcharges) async {
      final ProviderContainer c = ProviderContainer(overrides: surcharges);
      addTearDown(c.dispose);
      return c.read(cleTurnstileProvider.future);
    }

    test('sans port : aucune cle, aucun controle', () async {
      expect(await lire(const <Override>[]), isNull);
    });

    test('reglage vide ou blanc : aucune cle', () async {
      expect(
        await lire(<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle('   ')),
        ]),
        isNull,
      );
      expect(
        await lire(<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle(null)),
        ]),
        isNull,
      );
    });

    test('reglee : la cle du reglage', () async {
      expect(
        await lire(<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle(' 0xCleDuSite ')),
        ]),
        '0xCleDuSite',
      );
    });

    test('apercu : la cle de test publique, jamais celle du reglage', () async {
      expect(
        await lire(<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle('0xCleDuSite')),
          environnementAntiRobotProvider.overrideWithValue('staging'),
        ]),
        cleTurnstileApercu,
      );
    });

    test('lecture impossible : aucun controle', () async {
      expect(
        await lire(<Override>[
          portCleTurnstileProvider.overrideWithValue(_Cle('x', panne: true)),
        ]),
        isNull,
      );
    });
  });

  group('le controleur', () {
    test('attend le jeton, puis en demande un autre apres l envoi', () async {
      final ControleurAntiRobot c = ControleurAntiRobot();
      int relances = 0;
      c.brancher(() => relances++);
      final Future<String?> attente = c.jetonPourEnvoi();
      expect(c.etat, EtatAntiRobot.chargement);
      c.recevoirJeton('j1');
      expect(await attente, 'j1');
      expect(await c.jetonPourEnvoi(), 'j1');
      c.apresEnvoi();
      expect(c.etat, EtatAntiRobot.chargement);
      expect(c.jeton, isNull);
      expect(relances, 1);
    });

    test('verification sans issue : nul, et l etat le dit', () async {
      final ControleurAntiRobot c = ControleurAntiRobot();
      final Future<String?> attente = c.jetonPourEnvoi();
      c.signalerErreur();
      expect(await attente, isNull);
      expect(c.etat, EtatAntiRobot.erreur);
      expect(await c.jetonPourEnvoi(), isNull);
      c.signalerErreur(horsLigne: true);
      expect(c.etat, EtatAntiRobot.horsLigne);
    });

    test('un jeton expire ne vaut plus', () {
      final ControleurAntiRobot c = ControleurAntiRobot()
        ..recevoirJeton('j1')
        ..signalerExpiration();
      expect(c.jeton, isNull);
      expect(c.etat, EtatAntiRobot.chargement);
    });
  });

  group('reglage vide : l ecran d avant', () {
    testWidgets('connexion : aucun controle, le lien part sans jeton', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(tester, auth: auth, page: const ConnexionPage());
      expect(find.byType(ControleAntiRobot), findsNothing);
      await _envoyer(tester, t.connexion.envoyerLien);
      expect(auth.liensEnvoyes, <String>['fatou@example.test']);
      expect(auth.jetonsControle, <String?>[null]);
    });

    testWidgets('cle vide reglee : toujours aucun controle', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        auth: auth,
        page: const ConnexionPage(),
        cle: _Cle(''),
      );
      expect(find.byType(ControleAntiRobot), findsNothing);
      await _envoyer(tester, t.connexion.envoyerLien);
      expect(auth.jetonsControle, <String?>[null]);
    });

    testWidgets('recuperation : aucun controle, le lien part sans jeton', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(tester, auth: auth, page: const RecuperationPage());
      expect(find.byType(ControleAntiRobot), findsNothing);
      await _envoyer(
        tester,
        t.connexion.recuperation.envoyer,
        champ: const ValueKey<String>('recuperation-courriel'),
      );
      expect(auth.jetonsControle, <String?>[null]);
    });
  });

  group('cle reglee', () {
    testWidgets('connexion : le controle est pose, le jeton part, un autre est '
        'demande', (WidgetTester tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      late _ControleurJetons controleur;
      await _monter(
        tester,
        auth: auth,
        page: const ConnexionPage(),
        cle: _Cle('0xCleDuSite'),
        fabrique: () => controleur = _ControleurJetons(),
      );
      expect(find.byType(ControleAntiRobot), findsOneWidget);
      await _envoyer(tester, t.connexion.envoyerLien);
      expect(auth.liensEnvoyes, <String>['fatou@example.test']);
      expect(auth.jetonsControle, <String?>['jeton-1']);
      expect(controleur.relances, 1);

      // « Renvoyer le lien » : le controle reste pose, un nouveau jeton part.
      expect(find.byType(ControleAntiRobot), findsOneWidget);
      final Finder renvoyer = find.byKey(
        const ValueKey<String>('connexion-renvoyer'),
      );
      await tester.ensureVisible(renvoyer);
      await tester.pumpAndSettle();
      await tester.tap(renvoyer);
      await tester.pumpAndSettle();
      expect(auth.jetonsControle, <String?>['jeton-1', 'jeton-2']);
    });

    testWidgets('sans jeton : rien ne part, l ecran le dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      late _ControleurJetons controleur;
      await _monter(
        tester,
        auth: auth,
        page: const ConnexionPage(),
        cle: _Cle('0xCleDuSite'),
        fabrique: () => controleur = _ControleurJetons(rendre: false),
      );
      controleur.signalerErreur();
      await tester.pump();
      expect(find.byKey(ControleAntiRobot.cleErreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      await _envoyer(tester, t.connexion.envoyerLien);
      expect(auth.liensEnvoyes, isEmpty);
      expect(find.text(t.connexion.controle.erreur), findsWidgets);
      expect(
        t.connexion.controle.erreur,
        "La vérification n'a pas abouti. Réessayez.",
      );
    });

    testWidgets('jeton attendu au-dela du delai : rien ne part', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        auth: auth,
        page: const ConnexionPage(),
        cle: _Cle('0xCleDuSite'),
        fabrique: () => _ControleurJetons(rendre: false),
      );
      await tester.enterText(find.byKey(_cleCourriel), 'fatou@example.test');
      await tester.pump();
      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.connexion.envoyerLien,
      );
      await tester.ensureVisible(bouton);
      await tester.pumpAndSettle();
      await tester.tap(bouton);
      await tester.pump();
      // Pendant l'attente, la verification se dit.
      expect(find.text(t.connexion.controle.chargement), findsOneWidget);
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(auth.liensEnvoyes, isEmpty);
      expect(find.text(t.connexion.controle.erreur), findsOneWidget);
    });

    testWidgets('refus du serveur (captcha_failed) : la meme phrase', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth()
        ..erreurAJeter = const AuthApiException(
          'captcha protection: request disallowed (timeout-or-duplicate)',
          statusCode: '400',
          code: 'captcha_failed',
        );
      await _monter(
        tester,
        auth: auth,
        page: const ConnexionPage(),
        cle: _Cle('0xCleDuSite'),
        fabrique: _ControleurJetons.new,
      );
      await _envoyer(tester, t.connexion.envoyerLien);
      expect(find.text(t.connexion.controle.erreur), findsOneWidget);
    });

    testWidgets('recuperation : le jeton part avec la demande', (
      WidgetTester tester,
    ) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        auth: auth,
        page: const RecuperationPage(),
        cle: _Cle('0xCleDuSite'),
        fabrique: _ControleurJetons.new,
      );
      expect(find.byType(ControleAntiRobot), findsOneWidget);
      await _envoyer(
        tester,
        t.connexion.recuperation.envoyer,
        champ: const ValueKey<String>('recuperation-courriel'),
      );
      expect(auth.jetonsControle, <String?>['jeton-1']);
    });

    for (final (Size taille, double echelle) in <(Size, double)>[
      (const Size(390, 844), 2),
      (const Size(1440, 900), 1),
    ]) {
      testWidgets('erreur lisible a ${taille.width.toInt()} px, texte x'
          '${echelle.toInt()}', (WidgetTester tester) async {
        late _ControleurJetons controleur;
        await _monter(
          tester,
          auth: FauxServiceAuth(),
          page: const ConnexionPage(),
          cle: _Cle('0xCleDuSite'),
          fabrique: () => controleur = _ControleurJetons(rendre: false),
          taille: taille,
          echelle: echelle,
        );
        controleur.signalerErreur(horsLigne: true);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(t.connexion.controle.horsLigne), findsOneWidget);
      });
    }
  });

  test('issueEchecEnvoi : captcha_failed est une verification sans issue', () {
    expect(
      issueEchecEnvoi(
        const AuthApiException('x', statusCode: '400', code: 'captcha_failed'),
      ),
      IssueEnvoiLien.verificationNonAboutie,
    );
    expect(
      phraseEchecEnvoi(IssueEnvoiLien.verificationNonAboutie),
      t.connexion.controle.erreur,
    );
    unawaited(Future<void>.value());
  });
}
