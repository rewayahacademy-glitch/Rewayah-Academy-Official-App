import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/admin_tableau/tuiles_compteur.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

/// Un mardi de septembre, a dix-sept heures.
///
/// L'ecran recoit son horloge pour la meme raison que `ELV-02` et `TUT-01` :
/// l'anciennete des lignes se compte en jours, et une fixture calee sur
/// `DateTime.now()` changerait de resultat selon l'heure a laquelle la CI
/// lance le test.
final DateTime _maintenant = DateTime(2026, 9, 8, 17);

IndicateursAdmin _indicateurs({
  int dossiers = 0,
  int foyers = 0,
  int rapports = 0,
  int incidents = 0,
  int comptes = 0,
  int demandes = 0,
}) => IndicateursAdmin(
  dossiersEnAttente: dossiers,
  foyersSansEnseignant: foyers,
  rapportsManquants: rapports,
  incidents24h: incidents,
  comptesEchus: comptes,
  demandesEnAttente: demandes,
);

DossierAValider _dossier({
  String id = 'doc1',
  String prenom = 'Moussa',
  DateTime? depose,
  AppRole role = AppRole.teacher,
}) => DossierAValider(
  documentId: id,
  profilId: 'p-$id',
  type: TypePiece.carteIdentite,
  cleObjet: 'p1/piece.webp',
  deposeLe: depose ?? DateTime(2026, 9, 5, 9),
  prenom: prenom,
  nom: 'Barry',
  identifiantImmuable: 'TEACHER-MB-000001',
  role: role,
);

Demande _demande({
  String id = 'req1',
  String prenom = 'Aissatou',
  SorteDemande sorte = SorteDemande.reaffectation,
  DateTime? creee,
}) => Demande(
  id: id,
  sorte: sorte,
  sujetId: 'e1',
  sujetPrenom: prenom,
  sujetIdentifiant: 'STUDENT-AD-000001',
  motif: 'Les horaires ne conviennent plus.',
  roleDemandeur: AppRole.guardian,
  creeeLe: creee ?? DateTime(2026, 9, 7, 9),
);

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAdmin admin,
  FauxServiceValidation? validation,
}) async {
  await tester.pumpWidget(
    hote(
      TableauDeBordPage(horloge: () => _maintenant),
      surcharges: <Override>[
        serviceAdminProvider.overrideWithValue(admin),
        serviceValidationProvider.overrideWithValue(
          validation ?? FauxServiceValidation(),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Fait defiler jusqu'a un libelle, comme l'administrateur le ferait.
Future<void> _allerA(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(
    cible,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la premiere lecture des compteurs montre un squelette', (
    WidgetTester tester,
  ) async {
    final Completer<IndicateursAdmin> reponse = Completer<IndicateursAdmin>();

    await tester.pumpWidget(
      hote(
        TableauDeBordPage(horloge: () => _maintenant),
        surcharges: <Override>[
          serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
          indicateursProvider.overrideWith((_) => reponse.future),
        ],
      ),
    );
    await tester.pump();

    // Un bloc par tuile (DASH-ADM-1), dans la grille. La section Alertes
    // (ALERTE-1) a son propre squelette de lignes, hors de la grille.
    expect(
      find.descendant(
        of: find.byType(GrilleBento),
        matching: find.byType(Skeleton),
      ),
      findsNWidgets(5),
    );
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(_indicateurs());
    await tester.pumpAndSettle();
  });

  group('Scenario 11 : les compteurs affichent zero sans disparaitre', () {
    testWidgets('les six compteurs sont rendus, tous a zero', (
      WidgetTester tester,
    ) async {
      await _monter(tester, admin: FauxServiceAdmin());

      // Invariant I9. Un compteur qui disparait a zero laisse douter s'il a ete
      // charge ou s'il est reellement nul.
      for (final String libelle in <String>[
        t.admin.tableau.dossiers,
        t.admin.tableau.demandes,
        t.admin.tableau.foyers,
        t.admin.tableau.rapports,
        t.admin.tableau.incidents,
        t.admin.tableau.comptes,
      ]) {
        expect(find.text(libelle), findsOneWidget);
      }
      expect(find.text('0'), findsNWidgets(6));
    });

    testWidgets('la mesure inverse : des valeurs non nulles s affichent', (
      WidgetTester tester,
    ) async {
      // Le meme ecran, la meme lecture, avec quatre compteurs remplis : les
      // deux zeros restants sont toujours la, a cote des chiffres.
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(
            dossiers: 3,
            rapports: 1,
            incidents: 2,
            demandes: 4,
          ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('une lecture en echec le dit, et ne rend pas six zeros', (
      WidgetTester tester,
    ) async {
      // Six zeros sur une lecture ratee seraient un mensonge tranquille :
      // l'ecran annoncerait « rien a faire » alors qu'il n'a rien lu.
      await _monter(
        tester,
        admin: FauxServiceAdmin()..erreurIndicateurs = StateError('reseau'),
      );

      expect(find.text(t.admin.tableau.compteursErreur), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('DASH-ADM-1 : resume et liens (DASH_STRATEGIE 3.1)', () {
    testWidgets('la liste A traiter en premier a quitte le tableau de bord', (
      WidgetTester tester,
    ) async {
      // Q1 : chaque file a sa page, la tuile y mene. Une demande ne se voit
      // plus que par son chiffre.
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..file = <Demande>[_demande()]
          ..indicateursRendus = _indicateurs(demandes: 1),
      );

      expect(find.textContaining('Aissatou'), findsNothing);
      expect(find.text('À traiter en premier'), findsNothing);
      expect(find.text(t.admin.tableau.demandes), findsOneWidget);
    });

    testWidgets('les trois plus anciens dossiers, chacun avec son anciennete', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 4),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(prenom: 'Recent', depose: DateTime(2026, 9, 8, 9)),
            _dossier(id: 'd2', prenom: 'Ancien', depose: DateTime(2026, 9, 1)),
            _dossier(id: 'd3', prenom: 'Hier', depose: DateTime(2026, 9, 7, 9)),
            _dossier(id: 'd4', prenom: 'Milieu', depose: DateTime(2026, 9, 5)),
          ],
      );

      final List<String> lus = <String>[
        for (final Text texte in tester.widgetList<Text>(
          find.textContaining(' · '),
        ))
          texte.data ?? '',
      ];
      // Du plus ancien au plus recent ; le quatrieme reste dans la file.
      expect(lus, <String>[
        'Ancien · ${LibellesGroupe.insecable(t.admin.tableau.attenteJours(jours: '7'))}',
        'Milieu · ${LibellesGroupe.insecable(t.admin.tableau.attenteJours(jours: '3'))}',
        'Hier · ${t.admin.tableau.attenteUnJour}',
      ]);
      expect(find.textContaining('Recent'), findsNothing);
    });

    // K-47 (HL-A-6) : un tuteur pending_kyc n'est pas un dossier d'identite ;
    // son nom ouvrirait une fiche que la file ADM-02 ecarte (lien mort).
    testWidgets('l apercu ne porte que des enseignants', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 2),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(prenom: 'Enseignante'),
            _dossier(id: 'doc2', prenom: 'Tutrice', role: AppRole.guardian),
          ],
      );

      expect(find.textContaining('Enseignante'), findsOneWidget);
      expect(find.textContaining('Tutrice'), findsNothing);
    });

    /// Monte le centre de commande dans un routeur ou la file des dossiers
    /// affiche ce qu'elle a recu par `extra`.
    Future<void> monterRoutant(
      WidgetTester tester, {
      required FauxServiceAdmin admin,
      FauxServiceValidation? validation,
    }) async {
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.admin,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.admin,
              builder: (BuildContext _, GoRouterState _) =>
                  TableauDeBordPage(horloge: () => _maintenant),
            ),
            GoRoute(
              path: Routes.adminPersonnesDossiers,
              builder: (BuildContext _, GoRouterState etat) =>
                  Scaffold(body: Text('ADM-02 ${etat.extra}')),
            ),
            for (final (String route, String code) in <(String, String)>[
              (Routes.adminOperationsDemandes, 'ADM-06'),
              (Routes.adminOperationsAttributions, 'ADM-05'),
              (Routes.adminPedagogieQualite, 'ADM-14'),
              (Routes.adminOperationsGroupes, 'GROUPES'),
              (Routes.adminSecuriteAuditAccesAgents, 'ADM-07'),
            ])
              GoRoute(
                path: route,
                builder: (BuildContext _, GoRouterState _) =>
                    Scaffold(body: Text(code)),
              ),
            GoRoute(
              path: Routes.adminPersonnesComptes,
              builder: (BuildContext _, GoRouterState etat) => Scaffold(
                body: Text(
                  etat.uri.queryParameters['filtre'] == 'echus'
                      ? 'ADM-08 echus'
                      : 'ADM-08',
                ),
              ),
            ),
          ],
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(admin),
            serviceValidationProvider.overrideWithValue(
              validation ?? FauxServiceValidation(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('un nom de l apercu ouvre SON dossier, pas la file', (
      WidgetTester tester,
    ) async {
      // Modification UX n°2, conservee par l'exception D4 (a).
      await monterRoutant(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 2),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(prenom: 'Premier', depose: DateTime(2026, 9, 1)),
            _dossier(id: 'doc2', prenom: 'Second'),
          ],
      );

      await tester.tap(find.textContaining('Second'));
      await tester.pumpAndSettle();

      expect(find.text('ADM-02 p-doc2'), findsOneWidget);
    });

    testWidgets('le chiffre des dossiers ouvre la file entiere', (
      WidgetTester tester,
    ) async {
      await monterRoutant(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 1),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[_dossier()],
      );

      await tester.tap(find.text(t.admin.tableau.dossiers));
      await tester.pumpAndSettle();

      expect(find.text('ADM-02 null'), findsOneWidget);
    });

    for (final (String Function() libelle, String code) cas
        in <(String Function(), String)>[
          (() => t.admin.tableau.demandes, 'ADM-06'),
          (() => t.admin.tableau.foyers, 'ADM-05'),
          (() => t.admin.tableau.rapports, 'ADM-14'),
          (() => t.admin.groupes.titre, 'GROUPES'),
          (() => t.admin.tableau.outilsComptes, 'ADM-08'),
          (() => t.admin.tableau.outilsAccesAgents, 'ADM-07'),
          // DASH-ADM-ECHUS : la moitie « Acces echus » de la tuile double.
          (() => t.admin.tableau.comptes, 'ADM-08 echus'),
        ]) {
      testWidgets('un tap ouvre ${cas.$2}', (WidgetTester tester) async {
        await monterRoutant(
          tester,
          admin: FauxServiceAdmin()..indicateursRendus = _indicateurs(),
        );

        await _allerA(tester, find.text(cas.$1()));
        await tester.tap(find.text(cas.$1()));
        await tester.pumpAndSettle();

        expect(find.text(cas.$2), findsOneWidget);
      });
    }

    for (final IndicateursAdmin valeurs in <IndicateursAdmin>[
      _indicateurs(),
      _indicateurs(incidents: 3, comptes: 2),
      _indicateurs(incidents: 3),
    ]) {
      testWidgets('Incidents et acces : une seule tuile, ses deux chiffres '
          '(${valeurs.incidents24h} / ${valeurs.comptesEchus})', (
        WidgetTester tester,
      ) async {
        // D3 : cinq indicateurs dans tous les cas ; la tuile ne s'eclate
        // plus en deux quand l'un des chiffres n'est pas nul.
        await _monter(
          tester,
          admin: FauxServiceAdmin()..indicateursRendus = valeurs,
        );

        expect(find.text(t.admin.tableau.incidentsEtAcces), findsOneWidget);
        expect(find.byType(TuileDouble), findsOneWidget);
        final Finder double = find.byType(TuileDouble);
        for (final String libelle in <String>[
          t.admin.tableau.incidents,
          t.admin.tableau.comptes,
        ]) {
          expect(
            find.descendant(of: double, matching: find.text(libelle)),
            findsOneWidget,
          );
        }
        // DASH-ADM-ECHUS : un seul appui, celui des acces echus ; les
        // incidents restent un rapport sans page (D9, DASH-ADM-INC).
        final Finder appuis = find.descendant(
          of: double,
          matching: find.byType(Pressable),
        );
        expect(appuis, findsOneWidget);
        expect(
          find.descendant(
            of: appuis,
            matching: find.text(t.admin.tableau.comptes),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: appuis,
            matching: find.text(t.admin.tableau.incidents),
          ),
          findsNothing,
        );
      });
    }

    for (final (IndicateursAdmin, bool) cas in <(IndicateursAdmin, bool)>[
      (_indicateurs(), true),
      // Incidents et acces echus sont des rapports, pas des files d'action.
      (_indicateurs(incidents: 4, comptes: 1), true),
      (_indicateurs(dossiers: 1), false),
      (_indicateurs(demandes: 1), false),
      (_indicateurs(foyers: 1), false),
      (_indicateurs(rapports: 1), false),
    ]) {
      testWidgets('phrase calme : ${cas.$2 ? 'dite' : 'tue'} '
          '(${cas.$1.dossiersEnAttente}, ${cas.$1.demandesEnAttente}, '
          '${cas.$1.foyersSansEnseignant}, ${cas.$1.rapportsManquants}, '
          '${cas.$1.incidents24h}, ${cas.$1.comptesEchus})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          admin: FauxServiceAdmin()..indicateursRendus = cas.$1,
        );

        expect(
          find.text(t.admin.tableau.calme),
          cas.$2 ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('pas de phrase calme sur une lecture en echec', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()..erreurIndicateurs = StateError('reseau'),
      );

      expect(find.text(t.admin.tableau.calme), findsNothing);
    });

    testWidgets('le squelette a la forme de la grille', (
      WidgetTester tester,
    ) async {
      final Completer<IndicateursAdmin> reponse = Completer<IndicateursAdmin>();
      await tester.pumpWidget(
        hote(
          TableauDeBordPage(horloge: () => _maintenant),
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
            indicateursProvider.overrideWith((_) => reponse.future),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Cinq blocs, un par tuile, dans une GrilleBento : la page ne saute
      // pas quand les chiffres arrivent (D11).
      expect(
        find.descendant(
          of: find.byType(GrilleBento),
          matching: find.byType(Skeleton),
        ),
        findsNWidgets(5),
      );

      reponse.complete(_indicateurs());
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('une file de dossiers illisible n emporte que les noms', (
      WidgetTester tester,
    ) async {
      // `read_kyc_documents()` refuse la lecture quand le genre du lecteur est
      // inconnu. Les compteurs, eux, viennent d'une autre fonction : la tuile
      // garde son chiffre et dit que la liste manque, jamais un apercu vide
      // en silence.
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 2),
        validation: FauxServiceValidation()
          ..erreurFile = const GenreLecteurInconnu(),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text(t.admin.tableau.apercuErreur), findsOneWidget);
    });
  });

  group('DASH-ADM-1 : aucun mot coupe dans la grille', () {
    setUpAll(chargerPolicesDuDepot);

    for (final (double, double) cas in const <(double, double)>[
      (320, 1),
      (320, 2),
      (390, 1),
      (390, 2),
      (600, 2),
      (768, 1),
      (768, 2),
      (1024, 1),
      (1440, 1),
      (1440, 2),
    ]) {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
            '${sens.name}', (WidgetTester tester) async {
          tester.view.physicalSize = Size(cas.$1, 3000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: <Override>[
                serviceAdminProvider.overrideWithValue(
                  FauxServiceAdmin()
                    ..indicateursRendus = _indicateurs(
                      dossiers: 12,
                      demandes: 4,
                      foyers: 3,
                      rapports: 2,
                      incidents: 1,
                      comptes: 5,
                    ),
                ),
                serviceValidationProvider.overrideWithValue(
                  FauxServiceValidation()
                    ..file = <DossierAValider>[
                      _dossier(
                        prenom: 'Abdourahmane',
                        depose: DateTime(2026, 9, 1),
                      ),
                      _dossier(
                        id: 'd2',
                        prenom: 'Mariama',
                        depose: DateTime(2026, 9, 7, 9),
                      ),
                      _dossier(id: 'd3', prenom: 'Ibrahima'),
                    ],
                ),
              ],
              child: TranslationProvider(
                child: MaterialApp(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  builder: (BuildContext c, Widget? app) => MediaQuery(
                    data: MediaQuery.of(c)
                        .copyWith(textScaler: TextScaler.linear(cas.$2)),
                    child: Directionality(textDirection: sens, child: app!),
                  ),
                  home: TableauDeBordPage(horloge: () => _maintenant),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          final Finder grille = find.byType(GrilleBento);
          expect(grille, findsOneWidget);
          // La mesure porte sur quelque chose : les noms et la tuile double.
          expect(
            find.descendant(
              of: grille,
              matching: find.textContaining('Mariama'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: grille,
              matching: find.text(t.admin.tableau.incidentsEtAcces),
            ),
            findsOneWidget,
          );
          verifierAucunMotCoupe(tester, grille);
        });
      }
    }
  });
}
