// AD-X, ecran 2 : l'Espace de traitement (ADM-18, image ADMIN-SHELL-02),
// docs/current/AD-X_DECOUPAGE.md §2, ecran 2.
//
// Ce que le test tient : la file reunit les dossiers (enseignants seulement)
// et les demandes, groupes par jour, du plus recent au plus ancien ; les
// filtres et le tri ; le maitre-detail a 1440 et la feuille a 390 ; le seul
// bouton plein mene a l'ecran de decision (le dossier par `extra`) ; les
// cinq etats, dont l'erreur d'une source qui laisse l'autre affichee.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart' show EtatPiece;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_traitement/elements_a_traiter.dart';
import 'package:rewayah_academy/features/admin_traitement/traitement_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Lundi 5 octobre 2026, dix heures.
final DateTime _maintenant = DateTime(2026, 10, 5, 10);

DossierAValider _dossier(
  String id,
  String prenom, {
  required DateTime depose,
  AppRole role = AppRole.teacher,
  EtatPiece piece = EtatPiece.aVerifier,
}) => DossierAValider(
  documentId: 'doc-$id',
  profilId: 'p-$id',
  type: TypePiece.carteIdentite,
  cleObjet: 'p/$id.webp',
  deposeLe: depose,
  prenom: prenom,
  nom: 'Exemple',
  identifiantImmuable: 'TEACHER-$id',
  role: role,
  etatPiece: piece,
);

Demande _demande(String id, String prenom, {required DateTime creee}) =>
    Demande(
      id: id,
      sorte: SorteDemande.reaffectation,
      sujetId: 's-$id',
      sujetPrenom: prenom,
      sujetIdentifiant: 'STUDENT-$id',
      motif: 'Les horaires ne conviennent plus.',
      roleDemandeur: AppRole.guardian,
      creeeLe: creee,
    );

FauxServiceValidation _validation() =>
    FauxServiceValidation()
      ..file = <DossierAValider>[
        _dossier('a', 'Amina', depose: DateTime(2026, 10, 5, 8, 30)),
        _dossier('o', 'Omar', depose: DateTime(2026, 9, 20, 9)),
        // Un tuteur : jamais dans la file (K-47).
        _dossier(
          't',
          'Tarek',
          depose: DateTime(2026, 10, 5, 9),
          role: AppRole.guardian,
        ),
        _dossier(
          'y',
          'Yanis',
          depose: DateTime(2026, 10, 2, 9),
          piece: EtatPiece.aucune,
        ),
      ];

FauxServiceAdmin _admin() => FauxServiceAdmin()
  ..file = <Demande>[_demande('r1', 'Sami', creee: DateTime(2026, 10, 4, 18))];

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  FauxServiceValidation? validation,
  FauxServiceAdmin? admin,
  List<Override> plus = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.adminOperationsTraitement,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminOperationsTraitement,
          builder: (BuildContext _, GoRouterState _) =>
              TraitementPage(horloge: () => _maintenant),
        ),
        GoRoute(
          path: Routes.adminPersonnesDossiers,
          builder: (BuildContext _, GoRouterState etat) =>
              Scaffold(body: Text('ADM-02 ${etat.extra}')),
        ),
        GoRoute(
          path: Routes.adminOperationsDemandes,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ADM-06')),
        ),
        GoRoute(
          path: Routes.adminOperationsGroupes,
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('ADM-09')),
        ),
      ],
      surcharges: <Override>[
        serviceValidationProvider.overrideWithValue(
          validation ?? _validation(),
        ),
        serviceAdminProvider.overrideWithValue(admin ?? _admin()),
        ...plus,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// L'ordre vertical des noms dans la file.
List<String> _ordre(WidgetTester tester, List<String> noms) {
  final List<String> presents = <String>[
    for (final String n in noms)
      if (find.text(n).evaluate().isNotEmpty) n,
  ];
  presents.sort(
    (String a, String b) => tester
        .getTopLeft(find.text(a).first)
        .dy
        .compareTo(tester.getTopLeft(find.text(b).first).dy),
  );
  return presents;
}

void main() {
  group('ADM-18 : la file reunie', () {
    test('groupePour : jour, veille, semaine, plus ancien', () {
      expect(
        groupePour(DateTime(2026, 10, 5, 0, 1), _maintenant),
        GroupeTemps.aujourdhui,
      );
      expect(
        groupePour(DateTime(2026, 10, 4, 23), _maintenant),
        GroupeTemps.hier,
      );
      expect(
        groupePour(DateTime(2026, 9, 29, 9), _maintenant),
        GroupeTemps.semaine,
      );
      expect(
        groupePour(DateTime(2026, 9, 28, 9), _maintenant),
        GroupeTemps.plusAncien,
      );
    });

    testWidgets('1440 : dossiers et demandes, plus recent d abord, groupes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));

      final Finder file = find.byKey(TraitementPage.cleFile);
      for (final String n in <String>[
        'Amina Exemple',
        'Sami',
        'Yanis Exemple',
        'Omar Exemple',
      ]) {
        expect(
          find.descendant(of: file, matching: find.text(n)),
          findsOneWidget,
        );
      }
      // K-47 : aucun tuteur.
      expect(find.text('Tarek Exemple'), findsNothing);
      expect(find.text(t.admin.traitement.compteur(n: 4)), findsOneWidget);
      expect(
        find.text('${t.admin.traitement.groupeAujourdhui} (1)'),
        findsOneWidget,
      );
      expect(find.text('${t.admin.traitement.groupeHier} (1)'), findsOneWidget);
      expect(
        find.text('${t.admin.traitement.groupeSemaine} (1)'),
        findsOneWidget,
      );
      expect(
        find.text('${t.admin.traitement.groupePlusAncien} (1)'),
        findsOneWidget,
      );
      expect(
        _ordre(tester, <String>[
          'Amina Exemple',
          'Sami',
          'Yanis Exemple',
          'Omar Exemple',
        ]),
        <String>['Amina Exemple', 'Sami', 'Yanis Exemple', 'Omar Exemple'],
      );
      // L'etat de piece dit par le serveur, seulement lui.
      expect(find.text(t.dossiers.sansPiece), findsWidgets);
    });

    testWidgets('filtre Demandes, puis tri Plus ancien', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));
      await tester.tap(find.text(t.admin.traitement.filtreDemandes));
      await tester.pumpAndSettle();
      final Finder file = find.byKey(TraitementPage.cleFile);
      expect(
        find.descendant(of: file, matching: find.text('Sami')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: file, matching: find.text('Amina Exemple')),
        findsNothing,
      );

      await tester.tap(find.text(t.admin.traitement.filtreTous));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MenuFiltre<TriFile>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.admin.traitement.triAncien).last);
      await tester.pumpAndSettle();
      expect(
        _ordre(tester, <String>['Amina Exemple', 'Omar Exemple']),
        <String>['Omar Exemple', 'Amina Exemple'],
      );
    });
  });

  group('ADM-18 : detail et decision ailleurs', () {
    testWidgets(
      '1440 : maitre-detail, le premier choisi, un seul bouton plein',
      (WidgetTester tester) async {
        await _monter(tester, taille: const Size(1440, 900));
        final Finder detail = find.byKey(TraitementPage.cleDetail);
        expect(detail, findsOneWidget);
        final Rect rFile = tester.getRect(find.byKey(TraitementPage.cleFile));
        final Rect rDetail = tester.getRect(detail);
        expect(rFile.width, 336);
        expect(rDetail.left, greaterThanOrEqualTo(rFile.right + 24 - 0.5));
        expect(
          find.descendant(
            of: detail,
            matching: find.text("Dossier d'Amina Exemple"),
          ),
          findsOneWidget,
        );
        verifierUnSeulBoutonPlein(tester);

        await tester.tap(find.text("Ouvrir le dossier d'Amina Exemple"));
        await tester.pumpAndSettle();
        // Le dossier par `extra`, jamais par l'URL.
        expect(find.text('ADM-02 p-a'), findsOneWidget);
      },
    );

    testWidgets('1440 : choisir une demande, puis l ouvrir', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));
      await tester.tap(
        find.descendant(
          of: find.byKey(TraitementPage.cleFile),
          matching: find.text('Sami'),
        ),
      );
      await tester.pumpAndSettle();
      final Finder detail = find.byKey(TraitementPage.cleDetail);
      expect(
        find.descendant(
          of: detail,
          matching: find.text(t.admin.traitement.titreDemande(nom: 'Sami')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text('Les horaires ne conviennent plus.'),
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.traitement.suiviPhrase), findsOneWidget);
      await tester.tap(
        find.text(t.admin.traitement.ouvrirDemande(nom: 'Sami')),
      );
      await tester.pumpAndSettle();
      expect(find.text('ADM-06'), findsOneWidget);
    });

    testWidgets('390 : la file seule, le detail en feuille', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(390, 844));
      expect(find.byKey(TraitementPage.cleDetail), findsNothing);
      await tester.tap(find.text('Amina Exemple'));
      await tester.pumpAndSettle();
      expect(find.text("Ouvrir le dossier d'Amina Exemple"), findsOneWidget);
      await tester.tap(find.text("Ouvrir le dossier d'Amina Exemple"));
      await tester.pumpAndSettle();
      expect(find.text('ADM-02 p-a'), findsOneWidget);
    });
  });

  group('ADM-18 : etats', () {
    testWidgets('vide : une phrase, sans file', (WidgetTester tester) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        validation: FauxServiceValidation(),
        admin: FauxServiceAdmin(),
      );
      expect(find.text(t.admin.traitement.vide), findsOneWidget);
      expect(find.byKey(TraitementPage.cleFile), findsNothing);
    });

    testWidgets('erreur des dossiers : les demandes restent', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        validation: FauxServiceValidation()..erreurFile = Exception('muet'),
      );
      expect(find.text(t.admin.traitement.erreurDossiers), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TraitementPage.cleFile),
          matching: find.text('Sami'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('erreur des dossiers, demandes vides : l erreur seule', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        validation: FauxServiceValidation()..erreurFile = Exception('muet'),
        admin: FauxServiceAdmin(),
      );
      expect(find.text(t.admin.traitement.erreurDossiers), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      // La file n'est pas connue : jamais « Rien a traiter ».
      expect(find.text(t.admin.traitement.vide), findsNothing);
      expect(find.text(t.admin.traitement.videDetail), findsNothing);
    });

    testWidgets('erreur des demandes, dossiers vides : l erreur seule', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        validation: FauxServiceValidation(),
        plus: <Override>[
          demandesProvider.overrideWith(
            (_) => Future<List<Demande>>.error(Exception('muet')),
          ),
        ],
      );
      expect(find.text(t.admin.traitement.erreurDemandes), findsOneWidget);
      expect(find.text(t.admin.traitement.vide), findsNothing);
    });

    testWidgets('erreur des deux sources : une phrase et Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        validation: FauxServiceValidation()..erreurFile = Exception('muet'),
        plus: <Override>[
          demandesProvider.overrideWith(
            (_) => Future<List<Demande>>.error(Exception('muet')),
          ),
        ],
      );
      expect(find.text(t.admin.traitement.erreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('chargement : un squelette de file', (
      WidgetTester tester,
    ) async {
      final Completer<List<Demande>> reponse = Completer<List<Demande>>();
      final Completer<List<DossierAValider>> reponse2 =
          Completer<List<DossierAValider>>();
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          TraitementPage(horloge: () => _maintenant),
          surcharges: <Override>[
            demandesProvider.overrideWith((_) => reponse.future),
            dossiersEnAttenteProvider.overrideWith((_) => reponse2.future),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(Skeleton), findsOneWidget);
      reponse.complete(const <Demande>[]);
      reponse2.complete(const <DossierAValider>[]);
      await tester.pumpAndSettle();
      expect(find.text(t.admin.traitement.vide), findsOneWidget);
    });
  });
}
