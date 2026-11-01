// FN-112, second defaut (prod du 01/11/2026) : l'eleve adulte accepte qui
// recharge `/eleve/adulte` tombait sur « Vous n'avez pas acces a cette
// page ». Au rechargement, la session arrive avant sa capacite « eleve
// autonome » : le routeur refusait sur un faux qui n'etait pas une reponse,
// puis la capacite lue ne le sortait plus de `/acces-refuse`.
//
// Le vrai routeur, une session qui se resout pendant le test (comme au
// rechargement), et un port de capacite qui repond quand le test le dit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/routes_accueil_adulte.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';

import '../../router/support_routeur.dart';
import 'support_accueil_adulte_route.dart';

/// Un port de capacite qui ne repond que quand le test le decide.
class _PortLent implements PortCapaciteEleve {
  final Completer<CapaciteEleve> reponse = Completer<CapaciteEleve>();

  @override
  Future<CapaciteEleve> lire(String profileId) => reponse.future;
}

/// Monte l'application sur `/eleve/adulte` avec une session encore en
/// chargement, comme un navigateur qui recharge cette adresse.
Future<(GoRouter, SourcePilotee)> _recharger(
  WidgetTester tester,
  PortCapaciteEleve port,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final SourcePilotee source = SourcePilotee();
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(source),
        portCapaciteEleveProvider.overrideWithValue(port),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        ...surchargesAccueilAdulte(
          accueil: Valeur(accueilDemo()),
          historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
        ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.watch(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  // L'adresse rechargee, pendant que la session se resout.
  routeur.go(Routes.eleveAdulte);
  await stabiliser(tester);
  expect(lieu(routeur), Routes.eleveAdulte);
  // La session arrive : compte actif, capacite pas encore lue.
  source.emettre(sessionActive(AppRole.guardian));
  await stabiliser(tester);
  return (routeur, source);
}

void main() {
  group('decision du routeur (fonction pure)', () {
    SessionState adulte({required bool autonome, required bool enLecture}) =>
        sessionActive(AppRole.guardian).copyWith(
          eleveAutonome: autonome,
          capaciteEleveEnLecture: enLecture,
        );
    String? decider(SessionState s, String chemin) => deciderRedirection(
      session: s,
      cheminDemande: chemin,
      maintenant: DateTime.utc(2026, 11, 1, 22),
    );

    test('capacite en lecture : rien n\'est decide sur /eleve/*', () {
      final SessionState s = adulte(autonome: false, enLecture: true);
      expect(decider(s, Routes.eleveAdulte), isNull);
      expect(decider(s, Routes.eleveFinances), isNull);
      // Hors de /eleve, la lecture ne change rien.
      expect(decider(s, '/enseignant'), Routes.accesRefuse);
    });

    test('capacite lue, autonome : /eleve/adulte s\'ouvre', () {
      final SessionState s = adulte(autonome: true, enLecture: false);
      expect(decider(s, Routes.eleveAdulte), isNull);
      expect(decider(s, Routes.eleve), Routes.eleveAdulte);
    });

    test('capacite lue, pas autonome : le tuteur seul reste refuse', () {
      final SessionState s = adulte(autonome: false, enLecture: false);
      expect(decider(s, Routes.eleveAdulte), Routes.accesRefuse);
    });

    test('finances : en lecture, rien n\'est decide', () {
      expect(
        redirectionFinancesAdulte(eleveAutonome: false, enLecture: true),
        isNull,
      );
      expect(redirectionFinancesAdulte(eleveAutonome: false), Routes.eleve);
    });
  });

  group('rechargement de /eleve/adulte (vrai routeur)', () {
    testWidgets('capacite lue apres la session : l\'Accueil adulte '
        's\'affiche, jamais « acces refuse »', (WidgetTester tester) async {
      final _PortLent port = _PortLent();
      final (GoRouter routeur, SourcePilotee _) = await _recharger(
        tester,
        port,
      );
      // Pendant la lecture (loading) : on reste, rien n'est refuse.
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(PageAccesRefuse), findsNothing);

      port.reponse.complete(const EleveAutonome());
      await stabiliser(tester);
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
      expect(find.byType(PageAccesRefuse), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('capacite lue, pas d\'eleve autonome : le tuteur seul est '
        'refuse, une fois la reponse connue', (WidgetTester tester) async {
      final _PortLent port = _PortLent();
      final (GoRouter routeur, SourcePilotee _) = await _recharger(
        tester,
        port,
      );
      expect(find.byType(PageAccesRefuse), findsNothing);

      port.reponse.complete(const PasEleve());
      await stabiliser(tester);
      expect(lieu(routeur), Routes.accesRefuse);
      expect(find.byType(PageAccesRefuse), findsOneWidget);
    });

    testWidgets('echec de lecture (error) : traite comme « pas autonome », '
        'rien n\'est ouvert sur une capacite non lue (contrat C-24)', (
      WidgetTester tester,
    ) async {
      final _PortLent port = _PortLent();
      final (GoRouter routeur, SourcePilotee _) = await _recharger(
        tester,
        port,
      );
      port.reponse.complete(const CapaciteInconnue());
      await stabiliser(tester);
      expect(lieu(routeur), Routes.accesRefuse);
    });
  });

  test('le controleur : en lecture jusqu\'a la reponse, puis lue', () async {
    final SourcePilotee source = SourcePilotee();
    final _PortLent port = _PortLent();
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        sourceSessionProvider.overrideWithValue(source),
        portCapaciteEleveProvider.overrideWithValue(port),
      ],
    );
    addTearDown(c.dispose);
    c.listen(sessionProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(sessionProvider).capaciteEleveEnLecture, isFalse);

    source.emettre(sessionActive(AppRole.guardian));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(sessionProvider).capaciteEleveEnLecture, isTrue);
    expect(c.read(sessionProvider).eleveAutonome, isFalse);

    port.reponse.complete(const EleveAutonome());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(sessionProvider).capaciteEleveEnLecture, isFalse);
    expect(c.read(sessionProvider).eleveAutonome, isTrue);

    // Un nouvel etat du meme profil : la reponse est gardee, pas relue.
    source.emettre(sessionActive(AppRole.guardian));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(sessionProvider).capaciteEleveEnLecture, isFalse);
    expect(c.read(sessionProvider).eleveAutonome, isTrue);
  });
}
