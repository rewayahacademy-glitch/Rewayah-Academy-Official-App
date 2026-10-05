// Appareils du foyer et appareils d'un profil eleve (lot D, sous-paquet 3) :
// contenu, tri explicite, vide, erreur, chargement, hors ligne, introuvable,
// retrait confirme (reponse du service, echec, annulation, hors ligne),
// aucune limite figee, retours, composition bureau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/appareils/appareils_eleve_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/appareils/liste_appareils_eleve.dart';

import '../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';
import 'appareils/faux_appareils.dart';

class _Montage {
  _Montage(this.routeur, this.service);

  final GoRouter routeur;
  final FauxAppairagePilote service;

  String get lieu => routeur.routerDelegate.currentConfiguration.uri.toString();
}

Future<_Montage> _monter(
  WidgetTester tester, {
  required FauxAppairagePilote service,
  String depart = Routes.tuteurFoyerAppareils,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  double echelleTexte = 1,
  ThemeMode mode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.tuteurFoyer,
        builder: (BuildContext _, GoRouterState _) => const Text('FOYER'),
        routes: <RouteBase>[
          GoRoute(
            path: 'ajouter',
            builder: (BuildContext _, GoRouterState _) =>
                const Text('AJOUTER UN PROFIL'),
          ),
          GoRoute(
            path: 'appareils',
            builder: (BuildContext _, GoRouterState _) => const AppareilsPage(),
          ),
          GoRoute(
            path: 'appairer/:eleveId',
            builder: (BuildContext _, GoRouterState etat) =>
                Text('EMETTEUR ${etat.pathParameters['eleveId']}'),
          ),
          GoRoute(
            path: ':eleveId',
            builder: (BuildContext _, GoRouterState etat) =>
                Text('FICHE ${etat.pathParameters['eleveId']}'),
            routes: <RouteBase>[
              GoRoute(
                path: 'appareils',
                builder: (BuildContext _, GoRouterState etat) =>
                    AppareilsElevePage(
                      eleveId: etat.pathParameters['eleveId'] ?? '',
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceAppairageProvider.overrideWithValue(service),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(interface, Brightness.light),
          darkTheme: AppTheme.pour(interface, Brightness.dark),
          themeMode: mode,
          routerConfig: routeur,
          builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: enfant ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  return _Montage(routeur, service);
}

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _stabiliser(tester);
}

FauxAppairagePilote _foyer() => FauxAppairagePilote()
  ..elevesRendus = <EleveDuFoyer>[
    eleveDeTest(id: 'e2', prenom: 'Yusuf'),
    eleveDeTest(),
  ]
  ..appareilsRendus = <AppareilAppaire>[
    appareilDeTest(
      id: 'd2',
      plateforme: 'web',
      appaireA: DateTime(2026, 9, 20, 9, 5),
      derniereUtilisation: DateTime(2026, 9, 22, 14, 20),
    ),
    appareilDeTest(),
    appareilDeTest(id: 'd3', plateforme: 'ios', revoqueA: DateTime(2026, 9, 3)),
  ];

String _page(String eleveId) => Routes.ficheEleveSousPage(eleveId, 'appareils');

void main() {
  group('Appareils du foyer', () {
    testWidgets(
      'contenu : UN groupe, profils par prenom, appareils actifs nommes',
      (WidgetTester tester) async {
        await _monter(tester, service: _foyer());

        expect(find.text(t.appareils.foyer.titre), findsOneWidget);
        expect(find.byType(GroupeReglages), findsOneWidget);
        // Tri explicite par prenom : Amina avant Yusuf, quel que soit l ordre
        // de la vue.
        final double amina = tester.getTopLeft(find.text('Amina')).dy;
        final double yusuf = tester.getTopLeft(find.text('Yusuf')).dy;
        expect(amina, lessThan(yusuf));
        // L appareil retire (d3) ne compte plus.
        expect(
          find.text(
            t.appareils.foyer.plusieursAppareils(
              nombre: 2,
              noms:
                  '${t.appareils.plateforme.android}, '
                  '${t.appareils.plateforme.web}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(t.appareils.foyer.aucunAppareil), findsOneWidget);
        // Aucune limite figee, aucun compteur decoratif.
        expect(find.textContaining('maximum'), findsNothing);
        expect(find.textContaining('/2'), findsNothing);
        expect(find.text(t.appareils.foyer.partageTitre), findsOneWidget);
      },
    );

    testWidgets(
      'toucher un profil ouvre ses appareils ; le retour mene au Foyer',
      (WidgetTester tester) async {
        final _Montage m = await _monter(tester, service: _foyer());

        await _taper(tester, find.text('Yusuf'));
        expect(m.lieu, _page('e2'));
        expect(find.byType(AppareilsElevePage), findsOneWidget);

        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.tuteurFoyerAppareils);
        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.tuteurFoyer);
      },
    );

    testWidgets('vide : aucun profil, invitation au meme flux d ajout', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(tester, service: FauxAppairagePilote());

      expect(find.text(t.appareils.foyer.videTitre), findsOneWidget);
      expect(find.byType(GroupeReglages), findsNothing);
      await _taper(tester, find.text(t.appareils.foyer.videAction));
      expect(m.lieu, Routes.tuteurAjouterEnfant);
    });

    testWidgets('chargement : un squelette, aucun contenu invente', (
      WidgetTester tester,
    ) async {
      final FauxAppairagePilote service = _foyer()
        ..attenteLecture = Completer<void>();
      await _monter(tester, service: service);

      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text('Amina'), findsNothing);
      service.attenteLecture!.complete();
      await _stabiliser(tester);
      expect(find.text('Amina'), findsOneWidget);
    });

    testWidgets('erreur : Reessayer relit et affiche le contenu', (
      WidgetTester tester,
    ) async {
      final FauxAppairagePilote service = _foyer()
        ..erreurLecture = StateError('panne');
      await _monter(tester, service: service);

      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);
      service.erreurLecture = null;
      await _taper(tester, find.text(t.commun.etats.actions.reessayer));
      expect(find.text('Amina'), findsOneWidget);
    });

    testWidgets('hors ligne sans donnees : etat hors ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        service: _foyer()..attenteLecture = Completer<void>(),
        horsLigne: true,
      );
      // EA-HL-DOUBLE-1 : le bandeau dit le reseau, le bloc dit ce qui manque.
      expectSansDonnees(t.appareils.foyer.sansDonnees);
    });

    testWidgets('bureau 1440 : le groupe a gauche, l explication a droite', (
      WidgetTester tester,
    ) async {
      await _monter(tester, service: _foyer(), taille: const Size(1440, 900));
      final Offset groupe = tester.getTopLeft(find.byType(GroupeReglages));
      final Offset partage = tester.getTopLeft(
        find.text(t.appareils.foyer.partageTitre),
      );
      expect(partage.dx, greaterThan(groupe.dx + 300));
      expect(tester.takeException(), isNull);
    });
  });

  group('Appareils d un profil eleve', () {
    testWidgets(
      'contenu : appareils actifs du plus ancien au plus recent, dates lisibles',
      (WidgetTester tester) async {
        await _monter(tester, service: _foyer(), depart: _page('e1'));

        expect(
          find.text(t.appareils.eleve.sousTitre(prenom: 'Amina')),
          findsOneWidget,
        );
        expect(find.byKey(ListeAppareilsEleve.groupeKey), findsOneWidget);
        // d1 (1er septembre) avant d2 (20 septembre), alors que la vue les
        // rend dans l autre ordre : tri croissant explicite.
        final double android = tester
            .getTopLeft(find.text(t.appareils.plateforme.android))
            .dy;
        final double web = tester
            .getTopLeft(find.text(t.appareils.plateforme.web))
            .dy;
        expect(android, lessThan(web));
        // L appareil retire n est pas liste.
        expect(find.text(t.appareils.plateforme.ios), findsNothing);
        expect(
          find.textContaining(
            t.appareils.eleve.utiliseLe(date: '22 septembre 2026, 14:20'),
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(t.appareils.eleve.jamaisUtilise),
          findsOneWidget,
        );
        expect(find.text(t.appareils.revoquer), findsNWidgets(2));
        expect(find.text(t.appareils.eleve.connecter), findsOneWidget);
        expect(find.text(t.appareils.eleve.partageTitre), findsOneWidget);
      },
    );

    test('tri croissant explicite, meme si la vue rend autre chose', () {
      final List<AppareilAppaire> tries = appareilsActifsDe(
        'e1',
        <AppareilAppaire>[
          appareilDeTest(id: 'c', appaireA: DateTime(2026, 9, 3)),
          appareilDeTest(id: 'a', appaireA: DateTime(2026, 9, 1)),
          appareilDeTest(id: 'b', appaireA: DateTime(2026, 9, 1)),
          appareilDeTest(id: 'z', profilId: 'e2'),
          appareilDeTest(id: 'r', revoqueA: DateTime(2026, 9, 2)),
        ],
      );
      expect(tries.map((AppareilAppaire a) => a.id).toList(), <String>[
        'a',
        'b',
        'c',
      ]);
      expect(
        elevesParPrenom(<EleveDuFoyer>[
          eleveDeTest(id: 'x', prenom: 'yusuf'),
          eleveDeTest(id: 'y', prenom: 'Amina'),
        ]).map((EleveDuFoyer e) => e.prenom).toList(),
        <String>['Amina', 'yusuf'],
      );
    });

    testWidgets(
      'retrait : confirmation qui dit la limite, service appele, liste relue',
      (WidgetTester tester) async {
        final FauxAppairagePilote service = _foyer();
        await _monter(tester, service: service, depart: _page('e1'));

        await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
        expect(find.text(t.appareils.retrait.question), findsOneWidget);
        expect(
          find.text(
            t.appareils.retrait.consequence(
              appareil: t.appareils.plateforme.android,
              prenom: 'Amina',
            ),
          ),
          findsOneWidget,
          reason: 'DB-APP-03 : une connexion ouverte n est pas fermee',
        );
        expect(service.revocations, isEmpty, reason: 'rien avant le geste');

        await _taper(tester, find.text(t.appareils.retrait.confirmer));
        expect(service.revocations, <String>['d1']);
        expect(find.text(t.appareils.retrait.reussi), findsOneWidget);
        // La liste est relue : d1 n y est plus, d2 reste.
        expect(find.text(t.appareils.plateforme.android), findsNothing);
        expect(find.text(t.appareils.plateforme.web), findsOneWidget);
      },
    );

    testWidgets('retrait annule : rien n est envoye', (
      WidgetTester tester,
    ) async {
      final FauxAppairagePilote service = _foyer();
      await _monter(tester, service: service, depart: _page('e1'));

      await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
      await _taper(tester, find.text(t.commun.annuler));
      expect(service.revocations, isEmpty);
      expect(find.text(t.appareils.plateforme.android), findsOneWidget);
    });

    testWidgets(
      'retrait en attente : bouton en cours, aucun second retrait ; puis echec dit',
      (WidgetTester tester) async {
        final FauxAppairagePilote service = _foyer()
          ..attenteRetrait = Completer<void>()
          ..erreurRetrait = StateError('refus');
        await _monter(tester, service: service, depart: _page('e1'));

        await _taper(tester, find.byKey(ListeAppareilsEleve.retirerKey('d1')));
        await _taper(tester, find.text(t.appareils.retrait.confirmer));
        // Le second bouton ne part pas pendant l attente.
        await tester.tap(
          find.byKey(ListeAppareilsEleve.retirerKey('d2')),
          warnIfMissed: false,
        );
        await _stabiliser(tester);
        expect(find.text(t.appareils.retrait.question), findsNothing);

        service.attenteRetrait!.complete();
        await _stabiliser(tester);
        expect(find.text(t.appareils.retrait.echec), findsOneWidget);
        expect(service.revocations, isEmpty);
        expect(find.text(t.appareils.plateforme.android), findsOneWidget);
      },
    );

    testWidgets('hors ligne : aucun bouton Retirer, la raison est dite', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        service: _foyer(),
        depart: _page('e1'),
        horsLigne: true,
      );
      expect(find.text(t.appareils.revoquer), findsNothing);
      expect(find.text(t.appareils.eleve.horsLigne), findsOneWidget);
      expect(find.text(t.appareils.plateforme.android), findsOneWidget);
      // La note dit ce qui ne peut pas se faire et quand, sans redire le
      // reseau que porte le bandeau (EA-HL-DOUBLE-1c).
      expectAvecDonnees();
    });

    testWidgets('hors ligne sans donnees : le bloc dit ce qui manque, sans '
        'redire le reseau (EA-HL-DOUBLE-1)', (WidgetTester tester) async {
      await _monter(
        tester,
        service: _foyer()..attenteLecture = Completer<void>(),
        depart: _page('e1'),
        horsLigne: true,
      );
      expectSansDonnees(t.appareils.eleve.sansDonnees);
    });

    testWidgets('vide : aucun appareil, une seule action : Connecter', (
      WidgetTester tester,
    ) async {
      await _monter(tester, service: _foyer(), depart: _page('e2'));
      expect(find.text(t.appareils.eleve.videTitre), findsOneWidget);
      expect(find.text(t.appareils.revoquer), findsNothing);
      expect(find.text(t.appareils.eleve.connecter), findsOneWidget);
    });

    testWidgets(
      'aucune limite codee : avec trois appareils, Connecter reste propose',
      (WidgetTester tester) async {
        final FauxAppairagePilote service = _foyer()
          ..appareilsRendus = <AppareilAppaire>[
            appareilDeTest(),
            appareilDeTest(id: 'd4', appaireA: DateTime(2026, 9, 2)),
            appareilDeTest(id: 'd5', appaireA: DateTime(2026, 9, 3)),
          ];
        await _monter(tester, service: service, depart: _page('e1'));
        expect(find.text(t.appareils.revoquer), findsNWidgets(3));
        expect(find.text(t.appareils.eleve.connecter), findsOneWidget);
      },
    );

    testWidgets('introuvable : profil hors du foyer, retour aux appareils', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        service: _foyer(),
        depart: _page('inconnu'),
      );
      expect(find.text(t.appareils.eleve.introuvableTitre), findsOneWidget);
      expect(find.text(t.appareils.eleve.connecter), findsNothing);
      await _taper(tester, find.text(t.appareils.eleve.introuvableAction));
      expect(m.lieu, Routes.tuteurFoyerAppareils);
    });

    testWidgets('chargement puis erreur puis Reessayer', (
      WidgetTester tester,
    ) async {
      final FauxAppairagePilote service = _foyer()
        ..attenteLecture = Completer<void>();
      await _monter(tester, service: service, depart: _page('e1'));
      expect(find.byType(Skeleton), findsWidgets);

      service
        ..erreurLecture = StateError('panne')
        ..attenteLecture!.complete();
      await _stabiliser(tester);
      expect(find.text(t.commun.etats.echecServeur.titre), findsOneWidget);

      service
        ..erreurLecture = null
        ..attenteLecture = null;
      await _taper(tester, find.text(t.commun.etats.actions.reessayer));
      expect(find.text(t.appareils.plateforme.android), findsOneWidget);
    });

    testWidgets('Connecter un appareil ouvre l emetteur avec son retour', (
      WidgetTester tester,
    ) async {
      final _Montage m = await _monter(
        tester,
        service: _foyer(),
        depart: _page('e1'),
      );
      await _taper(tester, find.byKey(AppareilsElevePage.connecterKey));
      expect(find.text('EMETTEUR e1'), findsOneWidget);
      final Uri uri = Uri.parse(m.lieu);
      expect(uri.path, Routes.appairerPour('e1'));
      expect(uri.queryParameters['retour'], _page('e1'));
    });

    testWidgets(
      'retour : vers le chemin demande, sinon les appareils du foyer',
      (WidgetTester tester) async {
        final _Montage m = await _monter(
          tester,
          service: _foyer(),
          depart: '${_page('e1')}?retour=${Routes.ficheElevePour('e1')}',
        );
        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.ficheElevePour('e1'));
        expect(find.text('FICHE e1'), findsOneWidget);

        m.routeur.go('${_page('e1')}?retour=https://exemple.test');
        await _stabiliser(tester);
        await _taper(tester, find.byType(DisqueRetour));
        expect(m.lieu, Routes.tuteurFoyerAppareils);
      },
    );

    testWidgets(
      'bureau 1440 : liste et action a gauche, explications a droite',
      (WidgetTester tester) async {
        await _monter(
          tester,
          service: _foyer(),
          depart: _page('e1'),
          taille: const Size(1440, 900),
        );
        final Offset liste = tester.getTopLeft(
          find.byKey(ListeAppareilsEleve.groupeKey),
        );
        final Offset explication = tester.getTopLeft(
          find.text(t.appareils.eleve.partageTitre),
        );
        final Offset action = tester.getTopLeft(
          find.byKey(AppareilsElevePage.connecterKey),
        );
        expect(explication.dx, greaterThan(liste.dx + 300));
        expect(action.dx, closeTo(liste.dx, 1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'texte a 200 % (390x844) : aucun debordement, Retirer, Connecter et '
      'retour touchables',
      (WidgetTester tester) async {
        final _Montage m = await _monter(
          tester,
          service: _foyer(),
          depart: _page('e1'),
          echelleTexte: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(DisqueRetour).hitTestable(), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(ListeAppareilsEleve.retirerKey('d1')),
        );
        await tester.pump();
        expect(
          find.byKey(ListeAppareilsEleve.retirerKey('d1')).hitTestable(),
          findsOneWidget,
        );
        await _taper(tester, find.byKey(AppareilsElevePage.connecterKey));
        expect(find.text('EMETTEUR e1'), findsOneWidget);
        expect(Uri.parse(m.lieu).path, Routes.appairerPour('e1'));
        expect(tester.takeException(), isNull);
      },
    );
  });

  // EA-HL-DOUBLE-1c : sombre, Interface guidee et 1440 des appareils hors
  // ligne (revue EA-HL-DOUBLE-1-R, m4). Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, String, Size, ThemeMode, InterfaceMode, bool) cas
        in <(String, String, Size, ThemeMode, InterfaceMode, bool)>[
          (
            'foyer_sans_donnees_390_sombre',
            Routes.tuteurFoyerAppareils,
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            true,
          ),
          (
            'foyer_sans_donnees_390_guidee',
            Routes.tuteurFoyerAppareils,
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            true,
          ),
          (
            'foyer_avec_donnees_1440_clair',
            Routes.tuteurFoyerAppareils,
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            false,
          ),
          (
            'eleve_avec_donnees_390_sombre',
            _page('e1'),
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            false,
          ),
          (
            'eleve_avec_donnees_390_guidee',
            _page('e1'),
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            false,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        final FauxAppairagePilote service = _foyer();
        if (cas.$6) {
          service.attenteLecture = Completer<void>();
        }
        await _monter(
          tester,
          service: service,
          depart: cas.$2,
          horsLigne: true,
          taille: cas.$3,
          mode: cas.$4,
          interface: cas.$5,
        );
        expect(tester.takeException(), isNull);
        if (cas.$6) {
          expect(find.byType(EtatSansDonnees), findsOneWidget);
          expectHorsLigneUneFois();
        } else {
          expectAvecDonnees();
        }
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_appareils_${cas.$1}')}',
        );
      });
    }
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve des appareils hors ligne,
  // sans donnees (le bloc dit ce qui manque) et avec donnees (le bandeau
  // seul). Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, String, Size, double, bool) cas
        in <(String, String, Size, double, bool)>[
          (
            'foyer_sans_donnees_390',
            Routes.tuteurFoyerAppareils,
            const Size(390, 844),
            1,
            true,
          ),
          (
            'foyer_sans_donnees_320x2',
            Routes.tuteurFoyerAppareils,
            const Size(320, 900),
            2,
            true,
          ),
          (
            'eleve_sans_donnees_390',
            _page('e1'),
            const Size(390, 844),
            1,
            true,
          ),
          (
            'foyer_avec_donnees_390',
            Routes.tuteurFoyerAppareils,
            const Size(390, 844),
            1,
            false,
          ),
          (
            'eleve_avec_donnees_390',
            _page('e1'),
            const Size(390, 844),
            1,
            false,
          ),
          (
            'eleve_avec_donnees_1440',
            _page('e1'),
            const Size(1440, 900),
            1,
            false,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        final FauxAppairagePilote service = _foyer();
        if (cas.$5) {
          service.attenteLecture = Completer<void>();
        }
        await _monter(
          tester,
          service: service,
          depart: cas.$2,
          horsLigne: true,
          taille: cas.$3,
          echelleTexte: cas.$4,
        );
        expect(tester.takeException(), isNull);
        if (cas.$5) {
          expect(find.byType(EtatSansDonnees), findsOneWidget);
          expectHorsLigneUneFois();
        } else {
          expectAvecDonnees();
        }
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_appareils_${cas.$1}_clair')}',
        );
      });
    }
  });
}
