// PE-A5 (20/11/2026) : « The check did not complete », sans issue.
//
// Production (journaux d'authentification lus le 20/11) : plus aucune demande
// de lien acceptee depuis le 17/11 vers 10 h UTC ; le 18/11, six demandes
// parties SANS jeton. Ce que le test prouve :
//
// - la case de Cloudflare reste peinte quand elle est cachee (aucune opacite
//   nulle au-dessus d'elle : Flutter ne peint pas l'enfant d'une opacite 0, et
//   l'element HTML sortait alors de la page) ;
// - le code d'erreur de Cloudflare donne sa phrase (navigateur, heure de
//   l'appareil, reglage), et le second echec propose un autre navigateur ;
// - un delai depasse devient un echec dit, avec « Reessayer » et « Recharger
//   la page » (avant : etat « en cours » et aucune issue) ;
// - un echec n'est pas efface par l'envoi qui n'a pas eu lieu ;
// - une cle lue nulle est relue avant l'envoi : le controle se pose et le
//   jeton part ;
// - la cle se relit sans session quand le client Supabase refuse de partir ;
// - captures 390, francais et arabe.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/auth/anti_robot.dart';
import 'package:rewayah_academy/core/auth/anti_robot_supabase.dart';
import 'package:rewayah_academy/core/auth/rendu_turnstile.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/controle_anti_robot.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';
import 'package:rewayah_academy/features/connexion/recuperation_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/harnais.dart';

const ValueKey<String> _cleCourriel = ValueKey<String>('connexion-courriel');

/// Une cle illisible au premier essai, lisible ensuite.
class _CleTardive implements PortCleTurnstile {
  int lectures = 0;

  @override
  Future<String?> lire() async {
    lectures++;
    if (lectures == 1) throw StateError('session expiree');
    return '0xCleDuSite';
  }
}

class _Cle implements PortCleTurnstile {
  const _Cle(this.valeur);

  final String? valeur;

  @override
  Future<String?> lire() async => valeur;
}

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
  required Widget page,
  required PortCleTurnstile cle,
  required ControleurAntiRobot Function() fabrique,
  FauxServiceAuth? auth,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      page,
      surcharges: <Override>[
        serviceAuthProvider.overrideWithValue(auth ?? FauxServiceAuth()),
        demoAuthActiveProvider.overrideWithValue(false),
        portCleTurnstileProvider.overrideWithValue(cle),
        fabriqueControleurAntiRobotProvider.overrideWithValue(fabrique),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('la cause d un echec', () {
    test('codes de Cloudflare', () {
      expect(causeDepuisCode(null), CauseEchecAntiRobot.inconnue);
      expect(causeDepuisCode('200100'), CauseEchecAntiRobot.horloge);
      expect(causeDepuisCode('110200'), CauseEchecAntiRobot.reglage);
      expect(causeDepuisCode('110100'), CauseEchecAntiRobot.reglage);
      expect(causeDepuisCode('400020'), CauseEchecAntiRobot.reglage);
      expect(causeDepuisCode('110500'), CauseEchecAntiRobot.navigateur);
      expect(causeDepuisCode('200500'), CauseEchecAntiRobot.navigateur);
      expect(causeDepuisCode('300030'), CauseEchecAntiRobot.navigateur);
      expect(causeDepuisCode('600010'), CauseEchecAntiRobot.navigateur);
      expect(causeDepuisCode('102001'), CauseEchecAntiRobot.inconnue);
    });

    test('la phrase : par cause, puis un autre navigateur au second essai', () {
      expect(
        phraseEchecControle(CauseEchecAntiRobot.inconnue, 1),
        t.connexion.controle.erreur,
      );
      expect(
        phraseEchecControle(CauseEchecAntiRobot.delai, 2),
        t.connexion.controle.erreurNavigateur,
      );
      expect(
        phraseEchecControle(CauseEchecAntiRobot.horloge, 1),
        t.connexion.controle.erreurHorloge,
      );
      expect(
        phraseEchecControle(CauseEchecAntiRobot.reglage, 1),
        t.connexion.controle.erreurReglage,
      );
    });

    test('le controleur compte les echecs, un jeton remet a zero', () {
      final ControleurAntiRobot c = ControleurAntiRobot()
        ..signalerErreur(code: '600010');
      expect(c.cause, CauseEchecAntiRobot.navigateur);
      expect(c.echecs, 1);
      c.signalerErreur();
      expect(c.echecs, 2);
      c.recevoirJeton('j');
      expect(c.echecs, 0);
      expect(c.cause, CauseEchecAntiRobot.inconnue);
    });

    test('delai depasse : un echec dit, plus un etat « en cours »', () async {
      final ControleurAntiRobot c = ControleurAntiRobot();
      expect(
        await c.jetonPourEnvoi(delai: const Duration(milliseconds: 10)),
        isNull,
      );
      expect(c.etat, EtatAntiRobot.erreur);
      expect(c.cause, CauseEchecAntiRobot.delai);
    });
  });

  group('la case reste dans la page', () {
    testWidgets('cachee : aucune opacite nulle au-dessus de la case', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        page: const ConnexionPage(),
        cle: const _Cle('0xCleDuSite'),
        fabrique: () => _ControleurJetons(rendre: false),
      );
      final Finder rendu = find.byType(RenduTurnstile);
      expect(rendu, findsOneWidget);
      final Finder ancetres = find.ancestor(
        of: rendu,
        matching: find.byWidgetPredicate((Widget _) => true),
      );
      for (final Widget w in tester.widgetList(ancetres)) {
        if (w is Opacity) expect(w.opacity, greaterThan(0));
        if (w is AnimatedOpacity) expect(w.opacity, greaterThan(0));
        if (w is FadeTransition) expect(w.opacity.value, greaterThan(0));
      }
      // La case garde une place (un point), donc elle est peinte.
      expect(tester.getSize(rendu).height, greaterThan(0));
    });
  });

  group('la sortie de secours', () {
    testWidgets('connexion : echec, Reessayer, Recharger la page, Google', (
      WidgetTester tester,
    ) async {
      late _ControleurJetons controleur;
      final FauxServiceAuth auth = FauxServiceAuth();
      await _monter(
        tester,
        page: const ConnexionPage(),
        cle: const _Cle('0xCleDuSite'),
        fabrique: () => controleur = _ControleurJetons(rendre: false),
        auth: auth,
      );
      controleur.signalerErreur();
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_cleCourriel), 'fatou@example.test');
      await tester.pump();
      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.connexion.envoyerLien,
      );
      await tester.ensureVisible(bouton);
      await tester.pumpAndSettle();
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      // Rien ne part ; l'echec reste dit (l'envoi n'a pas eu lieu, rien
      // n'est relance en silence), avec ses issues.
      expect(auth.liensEnvoyes, isEmpty);
      expect(controleur.relances, 0);
      expect(find.text(t.connexion.controle.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.byKey(ControleAntiRobot.cleRecharger), findsOneWidget);
      expect(find.text(t.connexion.controle.autreCheminGoogle), findsOneWidget);
      // Reessayer : un nouveau tour de verification.
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(controleur.relances, 1);
      expect(find.text(t.connexion.controle.erreur), findsNothing);
      // Second echec : un autre navigateur est propose.
      controleur.signalerErreur();
      await tester.pumpAndSettle();
      expect(find.text(t.connexion.controle.erreurNavigateur), findsOneWidget);
    });

    testWidgets('recuperation : pas de Google, mais les deux issues', (
      WidgetTester tester,
    ) async {
      late _ControleurJetons controleur;
      await _monter(
        tester,
        page: const RecuperationPage(),
        cle: const _Cle('0xCleDuSite'),
        fabrique: () => controleur = _ControleurJetons(rendre: false),
      );
      controleur.signalerErreur(code: '200100');
      await tester.pumpAndSettle();
      expect(find.text(t.connexion.controle.erreurHorloge), findsOneWidget);
      expect(find.byKey(ControleAntiRobot.cleRecharger), findsOneWidget);
      expect(find.text(t.connexion.controle.autreCheminGoogle), findsNothing);
    });
  });

  group('la cle relue avant l envoi', () {
    testWidgets('lue nulle a l ouverture : relue, le controle se pose, le '
        'jeton part', (WidgetTester tester) async {
      final FauxServiceAuth auth = FauxServiceAuth();
      final _CleTardive cle = _CleTardive();
      await _monter(
        tester,
        page: const ConnexionPage(),
        cle: cle,
        fabrique: _ControleurJetons.new,
        auth: auth,
      );
      expect(find.byType(ControleAntiRobot), findsNothing);
      await tester.enterText(find.byKey(_cleCourriel), 'fatou@example.test');
      await tester.pump();
      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.connexion.envoyerLien,
      );
      await tester.ensureVisible(bouton);
      await tester.pumpAndSettle();
      await tester.tap(bouton);
      await tester.pumpAndSettle();
      expect(cle.lectures, 2);
      expect(auth.jetonsControle, <String?>['jeton-1']);
    });
  });

  group('la cle se lit sans session', () {
    test(
      'le client Supabase echoue : la meme fonction, sans session',
      () async {
        final List<http.Request> appels = <http.Request>[];
        final SupabaseClient client = SupabaseClient(
          'https://exemple.supabase.test',
          'cle-publique',
          httpClient: MockClient((http.Request r) async {
            throw StateError('refus avant envoi');
          }),
        );
        addTearDown(client.dispose);
        final CleTurnstileSupabase port = CleTurnstileSupabase(
          client,
          url: 'https://exemple.supabase.test',
          clePublique: 'cle-publique',
          clientHttp: MockClient((http.Request r) async {
            appels.add(r);
            return http.Response(jsonEncode('0xCleDuSite'), 200);
          }),
        );
        expect(await port.lire(), '0xCleDuSite');
        expect(appels, hasLength(1));
        expect(
          appels.single.url.toString(),
          'https://exemple.supabase.test/rest/v1/rpc/turnstile_cle_site',
        );
        expect(appels.single.headers['apikey'], 'cle-publique');
        expect(appels.single.headers.containsKey('Authorization'), isFalse);
      },
    );
  });

  // Preuve visuelle (R3) : `CAPTURE_DIR=docs/current/captures/E2E`.
  group('captures de l echec et de sa sortie', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('echec $nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
        late _ControleurJetons controleur;
        await _monter(
          tester,
          page: const ConnexionPage(),
          cle: const _Cle('0xCleDuSite'),
          fabrique: () => controleur = _ControleurJetons(rendre: false),
        );
        controleur.signalerErreur();
        await tester.pumpAndSettle();
        final Finder recharger = find.byKey(ControleAntiRobot.cleRecharger);
        await tester.ensureVisible(recharger);
        await tester.pumpAndSettle();
        await capturerVue(tester, 'pe-entree-candidat/echec-1_${nom}_390');
        controleur.signalerErreur();
        await tester.pumpAndSettle();
        await tester.ensureVisible(recharger);
        await tester.pumpAndSettle();
        await capturerVue(tester, 'pe-entree-candidat/echec-2_${nom}_390');
      });
    }
  });
}
