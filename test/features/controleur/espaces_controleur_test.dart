// CT-9 : commutation d'espaces et etats transverses du controle.
//
// Par la VRAIE route de demonstration (/demo/controleur) : Enseignant et
// Admin passent en Controle par `Compte > Espaces` (C6), le raccourci
// d'en-tete ouvre le MEME selecteur, une mission en cours retient en
// Controle (§4.2), l'acces revoque pendant la navigation ne laisse rien du
// contenu (C7, P-CTR-01), la mission indisponible ramene au Controle
// (P-CTR-08), l'utilisateur sans capacite est refuse, et la propre Classe de
// l'Enseignant-Controleur n'est jamais proposee.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/espaces_compte.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/controleur/garde_controle.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/espaces_controleur_demo.dart';

const SituationEspacesDemo _enseignant = SituationEspacesDemo(
  profil: ProfilDemoControleur.enseignant,
);
const SituationEspacesDemo _admin = SituationEspacesDemo(
  profil: ProfilDemoControleur.admin,
);

Widget _app(GoRouter routeur) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp.router(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: routeur,
    ),
  ),
);

Future<GoRouter> _monter(WidgetTester tester, String adresse) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: <RouteBase>[
      ...routesDemoControleur('dev'),
      GoRoute(
        path: Routes.demoEnseignant,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('demo enseignant')),
      ),
    ],
  );
  await tester.pumpWidget(_app(routeur));
  await tester.pumpAndSettle();
  return routeur;
}

Finder _ligne(EspaceTravail e) => find.byKey(SelecteurEspaces.cleEspace(e));

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Aucune action de l'autre role ne reste active en Controle (C6, §9.3) :
/// la barre est celle du controleur, quatre destinations.
void _coquilleControle() {
  expect(find.byType(NavShell), findsOneWidget);
  expect(find.byType(AdminShell), findsNothing);
  final NavShell barre =
      find.byType(NavShell).evaluate().single.widget as NavShell;
  expect(barre.destinations.map((Destination d) => d.chemin).toList(), <String>[
    Routes.controleur,
    Routes.controleurHistorique,
    Routes.controleurEchanges,
    Routes.compte,
  ]);
}

class _Session extends SessionControleur {
  _Session(this._role);

  final AppRole? _role;

  @override
  SessionState build() => SessionState(
    resolue: true,
    role: _role,
    profileId: 'test',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

void main() {
  group('1. Compte > Espaces', () {
    testWidgets('Enseignant-Controleur : Controle actif, Enseignant propose ; '
        'passer en Enseignant puis revenir en Controle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(EcranDemoControleur.compte, espaces: _enseignant),
      );
      _coquilleControle();
      expect(find.byType(SelecteurEspaces), findsOneWidget);
      expect(_ligne(EspaceTravail.enseignement), findsOneWidget);
      expect(_ligne(EspaceTravail.controle), findsOneWidget);
      expect(_ligne(EspaceTravail.administration), findsNothing);
      expect(
        find.descendant(
          of: _ligne(EspaceTravail.controle),
          matching: find.text(t.compte.actif),
        ),
        findsOneWidget,
      );
      // Capacites recalculees : en Controle, le compte est celui du
      // controleur (§4.2).
      expect(find.text(t.compte.roles.controller), findsWidgets);

      await _toucher(tester, _ligne(EspaceTravail.enseignement));
      expect(find.byType(EspacePrincipalDemo), findsOneWidget);
      expect(find.byType(ControleControleurPage), findsNothing);
      expect(find.text(t.compte.roles.teacher), findsWidgets);
      expect(
        find.descendant(
          of: _ligne(EspaceTravail.enseignement),
          matching: find.text(t.compte.actif),
        ),
        findsOneWidget,
      );

      await _toucher(tester, _ligne(EspaceTravail.controle));
      expect(find.byType(ControleControleurPage), findsOneWidget);
      _coquilleControle();
    });

    testWidgets('Admin-Controleur : Admin et Controle, aucune action Admin '
        'en Controle', (WidgetTester tester) async {
      await _monter(
        tester,
        adresseDemoControleur(EcranDemoControleur.compte, espaces: _admin),
      );
      _coquilleControle();
      expect(_ligne(EspaceTravail.administration), findsOneWidget);
      expect(_ligne(EspaceTravail.controle), findsOneWidget);
      expect(_ligne(EspaceTravail.enseignement), findsNothing);

      await _toucher(tester, _ligne(EspaceTravail.administration));
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(ComptePage), findsOneWidget);
      expect(_ligne(EspaceTravail.controle), findsOneWidget);
    });

    testWidgets('controleur externe : Controle seul, aucun selecteur', (
      WidgetTester tester,
    ) async {
      await _monter(tester, adresseDemoControleur(EcranDemoControleur.compte));
      _coquilleControle();
      expect(find.byType(SelecteurEspaces), findsNothing);
      expect(find.byKey(const ValueKey<String>('controleur')), findsOneWidget);
      expect(find.byKey(RaccourciEspaces.cle), findsNothing);
    });

    test('le tuteur, l eleve et le comptable n ont jamais Controle', () {
      for (final AppRole role in <AppRole>[
        AppRole.guardian,
        AppRole.student,
        AppRole.accountant,
      ]) {
        final EspacesCompte e = EspacesCompte.roleSeul(role);
        expect(e.disponibles, isEmpty, reason: role.name);
        expect(e.accesControle, AccesControle.refuse, reason: role.name);
      }
      // Sans projection serveur, aucun cumul n'est deduit.
      expect(
        EspacesCompte.roleSeul(AppRole.teacher).disponibles,
        <EspaceTravail>[EspaceTravail.enseignement],
      );
      expect(EspacesCompte.roleSeul(AppRole.teacher).plusieurs, isFalse);
    });

    testWidgets('le Compte d un tuteur ne propose pas Controle', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => ProviderScope(
              overrides: <Override>[
                sessionProvider.overrideWith(() => _Session(AppRole.guardian)),
              ],
              child: const ComptePage(),
            ),
          ),
        ],
      );
      await tester.pumpWidget(_app(routeur));
      await tester.pumpAndSettle();
      expect(find.byType(SelecteurEspaces), findsNothing);
      expect(_ligne(EspaceTravail.controle), findsNothing);
      expect(find.text(t.nav.controleur.controle), findsNothing);
    });
  });

  group('2. Raccourci d en-tete', () {
    testWidgets('il ouvre le MEME selecteur, qui fait passer d espace', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.controle,
          espaces: _enseignant,
        ),
      );
      expect(find.byType(ControleControleurPage), findsOneWidget);
      expect(find.byKey(RaccourciEspaces.cle), findsOneWidget);
      expect(find.byType(SelecteurEspaces), findsNothing);

      await tester.tap(find.byKey(RaccourciEspaces.cle));
      await tester.pumpAndSettle();
      expect(find.byType(SelecteurEspaces), findsOneWidget);
      expect(find.text(t.compte.espaces), findsWidgets);

      await tester.tap(_ligne(EspaceTravail.enseignement));
      await tester.pumpAndSettle();
      expect(find.byType(EspacePrincipalDemo), findsOneWidget);
      expect(find.byType(ControleControleurPage), findsNothing);
      // Depuis l'espace Enseignant, le raccourci reste la.
      expect(find.byKey(RaccourciEspaces.cle), findsOneWidget);
    });

    testWidgets('absent pour le controleur externe (un seul espace)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(EcranDemoControleur.controle),
      );
      expect(find.byType(ControleControleurPage), findsOneWidget);
      expect(find.byKey(RaccourciEspaces.cle), findsNothing);
    });
  });

  group('3. Mission en cours', () {
    testWidgets('le selecteur le dit au lieu de basculer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.compte,
          espaces: _enseignant.enMission(),
        ),
      );
      expect(find.byKey(SelecteurEspaces.missionEnCoursKey), findsOneWidget);
      expect(find.text(t.compte.espacesMissionEnCours), findsOneWidget);
      await _toucher(tester, _ligne(EspaceTravail.enseignement));
      // Toujours en Controle.
      expect(find.byType(EspacePrincipalDemo), findsNothing);
      _coquilleControle();
    });

    testWidgets('apres la sortie de mission, l espace principal revient', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        Uri(
          path: cheminDemoCompteRenduControleur,
          queryParameters: _enseignant.parametres,
        ).toString(),
      );
      expect(find.byType(CompteRenduControlePage), findsOneWidget);
      // Aucun raccourci d'espaces dans le compte rendu (C13).
      expect(find.byKey(RaccourciEspaces.cle), findsNothing);
      await _toucher(
        tester,
        find.byKey(
          CompteRenduControlePage.cleChoix(ChoixCompteRendu.rienASignaler),
        ),
      );
      await tester.ensureVisible(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CompteRenduControlePage.actionKey));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.controleur.compteRendu.revenir));
      await tester.pumpAndSettle();
      expect(find.byType(ControleControleurPage), findsOneWidget);

      await tester.tap(find.byKey(RaccourciEspaces.cle));
      await tester.pumpAndSettle();
      expect(find.byKey(SelecteurEspaces.missionEnCoursKey), findsNothing);
      await tester.tap(_ligne(EspaceTravail.enseignement));
      await tester.pumpAndSettle();
      expect(find.byType(EspacePrincipalDemo), findsOneWidget);
    });
  });

  group('4. Acces revoque pendant la navigation (P-CTR-01)', () {
    Future<void> revoquer(WidgetTester tester, Finder page) async {
      final ProviderContainer c = ProviderScope.containerOf(
        tester.element(page),
      );
      c.read(espacesCompteProvider.notifier).revoquerControle();
      await tester.pumpAndSettle();
    }

    void refus() {
      expect(find.byKey(GardeControle.refusKey), findsOneWidget);
      expect(find.text(t.controleur.acces.revoque), findsOneWidget);
      expect(find.text(t.controleur.acces.revenir), findsOneWidget);
      // Rien du contenu precedent, ni la barre.
      expect(find.byType(NavShell), findsNothing);
      expect(find.byType(ControleControleurPage), findsNothing);
      expect(find.byType(HistoriqueControleurPage), findsNothing);
      expect(find.byType(EchangesControleurPage), findsNothing);
      expect(find.textContaining('Classe'), findsNothing);
    }

    testWidgets('sur Historique : refus generique, retour a mon espace', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.historique,
          espaces: _enseignant,
        ),
      );
      expect(find.byType(HistoriqueControleurPage), findsOneWidget);
      await revoquer(tester, find.byType(HistoriqueControleurPage));
      refus();

      await tester.tap(find.text(t.controleur.acces.revenir));
      await tester.pumpAndSettle();
      expect(find.byType(EspacePrincipalDemo), findsOneWidget);
    });

    testWidgets('sur Echanges : rien du fil ne reste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(EcranDemoControleur.echanges, espaces: _admin),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(EchangesControleurPage), findsOneWidget);
      expect(find.textContaining('Classe Al-Badr'), findsWidgets);
      await revoquer(tester, find.byType(EchangesControleurPage));
      refus();
    });

    testWidgets('par l adresse de demonstration', (WidgetTester tester) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.historique,
          espaces: const SituationEspacesDemo(
            profil: ProfilDemoControleur.enseignant,
            acces: AccesDemoControleur.revoque,
          ),
        ),
      );
      refus();
    });
  });

  group('5. Mission indisponible (P-CTR-08)', () {
    testWidgets(
      'pendant le compte rendu : message et « Revenir au controle »',
      (WidgetTester tester) async {
        await _monter(
          tester,
          Uri(
            path: cheminDemoCompteRenduControleur,
            queryParameters: <String, String>{
              'etat': EtatDemoControleur.indisponible.name,
            },
          ).toString(),
        );
        expect(find.byKey(MissionIndisponible.cle), findsOneWidget);
        expect(find.text(t.controleur.controle.indisponible), findsOneWidget);
        expect(find.text('Classe An-Nour'), findsNothing);
        expect(find.byKey(CompteRenduControlePage.plusTardKey), findsNothing);
        await tester.tap(find.text(t.controleur.compteRendu.revenir));
        await tester.pumpAndSettle();
        expect(find.byType(ControleControleurPage), findsOneWidget);
      },
    );
  });

  group('6. Utilisateur sans capacite', () {
    testWidgets(
      'un enseignant sans Controle : refus generique, aucun contenu',
      (WidgetTester tester) async {
        await _monter(
          tester,
          adresseDemoControleur(
            EcranDemoControleur.controle,
            espaces: const SituationEspacesDemo(
              profil: ProfilDemoControleur.enseignant,
              acces: AccesDemoControleur.sansCapacite,
            ),
          ),
        );
        expect(find.byKey(GardeControle.refusKey), findsOneWidget);
        expect(find.byType(ControleControleurPage), findsNothing);
        expect(find.byType(NavShell), findsNothing);
        await tester.tap(find.text(t.controleur.acces.revenir));
        await tester.pumpAndSettle();
        expect(find.byType(EspacePrincipalDemo), findsOneWidget);
        // Sans capacite, Controle n'est pas propose.
        expect(_ligne(EspaceTravail.controle), findsNothing);
      },
    );

    testWidgets('la garde reelle refuse une session enseignant', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => ProviderScope(
              overrides: <Override>[
                sessionProvider.overrideWith(() => _Session(AppRole.teacher)),
              ],
              child: const GardeControle(child: Text('contenu du controle')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(_app(routeur));
      await tester.pumpAndSettle();
      expect(find.byKey(GardeControle.refusKey), findsOneWidget);
      expect(find.text('contenu du controle'), findsNothing);
    });

    testWidgets('la garde reelle laisse passer le controleur', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => ProviderScope(
              overrides: <Override>[
                sessionProvider.overrideWith(
                  () => _Session(AppRole.controller),
                ),
              ],
              child: const GardeControle(child: Text('contenu du controle')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(_app(routeur));
      await tester.pumpAndSettle();
      expect(find.byKey(GardeControle.refusKey), findsNothing);
      expect(find.text('contenu du controle'), findsOneWidget);
    });
  });

  group('7. Propre Classe exclue', () {
    test('An-Nour n est jamais attribuee a Sayyid Ibrahim', () {
      final ControleurDemo ibrahim = _enseignant.controleur;
      expect(ibrahim.classeExclue, 'demo-classe-an-nour');
      for (final EtatDemoControleur etat in EtatDemoControleur.values) {
        expect(missionAttribueeDemo(etat, ibrahim), isNull, reason: etat.name);
      }
      expect(
        missionAttribueeDemo(
          EtatDemoControleur.enDirect,
          const SituationEspacesDemo().controleur,
        )?.classe,
        'Classe An-Nour',
      );
    });

    testWidgets('le Controle de l Enseignant-Controleur ne la propose pas', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.controle,
          espaces: _enseignant,
        ),
      );
      expect(find.byType(ControleControleurPage), findsOneWidget);
      expect(find.text('Classe An-Nour'), findsNothing);
      expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
      expect(find.text(t.controleur.controle.vide), findsOneWidget);
    });
  });

  group('8. Demonstration', () {
    testWidgets('la liste mene a chaque situation', (
      WidgetTester tester,
    ) async {
      await _monter(tester, Routes.demoControleur);
      for (final String cle in <String>[
        'enseignant-controle',
        'enseignant-principal',
        'admin-controle',
        'admin-principal',
        'mission-en-cours',
        'acces-revoque',
        'sans-capacite',
        'compte-rendu-indisponible',
      ]) {
        expect(
          find.byKey(ValueKey<String>('lien-espaces-$cle')),
          findsOneWidget,
          reason: cle,
        );
      }
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('lien-espaces-admin-principal')),
      );
      expect(find.byType(AdminShell), findsOneWidget);
    });
  });
}
