import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

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

    expect(find.byType(Skeleton), findsOneWidget);
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
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(id: 'd1'),
            _dossier(id: 'd2'),
            _dossier(id: 'd3'),
          ],
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
    });

    // AD-NETTOYAGE (m1) : le compteur serveur compte encore les tuteurs
    // `pending_kyc` (BR-1.c) ; la tuile compte comme la liste « A traiter ».
    testWidgets('la tuile Dossiers ne compte pas les tuteurs', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 3),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(),
            _dossier(id: 'd2', role: AppRole.guardian),
            _dossier(id: 'd3', role: AppRole.guardian),
          ],
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsNothing);
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

  group('La liste a traiter, la plus ancienne en premier', () {
    test('les deux sources se melangent, et seul l age les ordonne', () {
      final List<ATraiter> lignes = aTraiter(
        dossiers: <DossierAValider>[
          _dossier(prenom: 'Recent', depose: DateTime(2026, 9, 7, 12)),
          _dossier(id: 'doc2', prenom: 'Ancien', depose: DateTime(2026, 9, 1)),
        ],
        demandes: <Demande>[
          _demande(prenom: 'Milieu', creee: DateTime(2026, 9, 4)),
        ],
      );

      // Un dossier depose le 1er passe devant une demande du 4, qui passe
      // devant un dossier du 7 : c'est l'anciennete qui ordonne, jamais la
      // nature de la ligne.
      expect(lignes.map((ATraiter l) => l.libelle).toList(), <String>[
        t.admin.tableau.ligneDossier(prenom: 'Ancien'),
        t.admin.tableau.ligneReaffectation(prenom: 'Milieu'),
        t.admin.tableau.ligneDossier(prenom: 'Recent'),
      ]);
    });

    test('chaque sorte de demande mene a l ecran des demandes', () {
      final List<ATraiter> lignes = aTraiter(
        dossiers: <DossierAValider>[_dossier()],
        demandes: <Demande>[
          _demande(sorte: SorteDemande.plafond, creee: DateTime(2026, 9, 6)),
          _demande(
            id: 'req2',
            sorte: SorteDemande.regle,
            creee: DateTime(2026, 9, 6, 1),
          ),
        ],
      );

      expect(
        lignes
            .where(
              (ATraiter l) => l.destination == Routes.adminOperationsDemandes,
            )
            .length,
        2,
      );
      expect(
        lignes
            .where(
              (ATraiter l) => l.destination == Routes.adminPersonnesDossiers,
            )
            .length,
        1,
      );
    });

    testWidgets('une ligne dit depuis quand elle attend', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..file = <Demande>[_demande(creee: DateTime(2026, 9, 5, 17))],
      );

      // Trois jours pleins entre le 5 a 17 h et le 8 a 17 h.
      await _allerA(
        tester,
        find.text(t.admin.tableau.attenteJours(jours: '3')),
      );
      expect(
        find.text(t.admin.tableau.attenteJours(jours: '3')),
        findsOneWidget,
      );
    });

    // K-47 (HL-A-6) : un tuteur pending_kyc n'est pas un dossier d'identite ;
    // sa ligne ouvrirait une fiche que la file ADM-02 ecarte (lien mort).
    testWidgets('la file A traiter ne porte que des enseignants', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        admin: FauxServiceAdmin(),
        validation: FauxServiceValidation()
          ..file = <DossierAValider>[
            _dossier(prenom: 'Enseignante'),
            _dossier(id: 'doc2', prenom: 'Famille', role: AppRole.guardian),
          ],
      );

      await _allerA(
        tester,
        find.text(t.admin.tableau.ligneDossier(prenom: 'Enseignante')),
      );
      expect(
        find.text(t.admin.tableau.ligneDossier(prenom: 'Enseignante')),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.tableau.ligneDossier(prenom: 'Famille')),
        findsNothing,
      );
    });

    testWidgets('un tap sur une ligne ouvre son ecran d action', (
      WidgetTester tester,
    ) async {
      final FauxServiceAdmin admin = FauxServiceAdmin()
        ..file = <Demande>[_demande()];

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
              path: Routes.adminOperationsDemandes,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('ADM-06')),
            ),
          ],
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(admin),
            serviceValidationProvider.overrideWithValue(
              FauxServiceValidation(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _allerA(
        tester,
        find.text(t.admin.tableau.ligneReaffectation(prenom: 'Aissatou')),
      );
      await tester.tap(
        find.text(t.admin.tableau.ligneReaffectation(prenom: 'Aissatou')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADM-06'), findsOneWidget);
    });

    testWidgets('un tap sur le compteur rapports manquants ouvre la qualite', (
      WidgetTester tester,
    ) async {
      final FauxServiceAdmin admin = FauxServiceAdmin()
        ..indicateursRendus = _indicateurs(rapports: 7);

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
              path: Routes.adminPedagogieQualite,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('ADM-14')),
            ),
          ],
          surcharges: <Override>[
            serviceAdminProvider.overrideWithValue(admin),
            serviceValidationProvider.overrideWithValue(
              FauxServiceValidation(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _allerA(tester, find.text(t.admin.tableau.rapports));
      await tester.tap(find.text(t.admin.tableau.rapports));
      await tester.pumpAndSettle();

      expect(find.text('ADM-14'), findsOneWidget);
    });

    testWidgets('rien a traiter est une invitation, pas un ecran mort', (
      WidgetTester tester,
    ) async {
      await _monter(tester, admin: FauxServiceAdmin());

      await _allerA(tester, find.text(t.admin.tableau.aTraiterAucun));
      expect(find.text(t.admin.tableau.aTraiterAucun), findsOneWidget);
      expect(find.text(t.admin.tableau.aTraiterAucunDetail), findsOneWidget);
    });

    testWidgets('une file de dossiers illisible n emporte pas les compteurs', (
      WidgetTester tester,
    ) async {
      // `read_kyc_documents()` refuse la lecture quand le genre du lecteur est
      // inconnu. Les compteurs, eux, viennent d'une autre fonction : les perdre
      // aussi ferait croire a une panne generale.
      await _monter(
        tester,
        admin: FauxServiceAdmin()
          ..indicateursRendus = _indicateurs(dossiers: 2),
        validation: FauxServiceValidation()
          ..erreurFile = const GenreLecteurInconnu(),
      );

      expect(find.text('2'), findsOneWidget);
      await _allerA(tester, find.text(t.admin.tableau.listeErreur));
      expect(find.text(t.admin.tableau.listeErreur), findsOneWidget);
    });
  });
}
