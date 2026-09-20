import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart'
    show TypePublicGroupe;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';

import '../support/harnais.dart';

const String _groupeId = 'g1';

GroupeEnseignant _groupe({
  String id = _groupeId,
  String libelle = 'Perles du Coran',
  TypePublicGroupe type = TypePublicGroupe.enfant,
  int seuilMax = 5,
  int nbMembres = 3,
  int jour = 3,
  int heure = 17,
}) => GroupeEnseignant(
  id: id,
  libelle: libelle,
  type: type,
  seuilMax: seuilMax,
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  nbMembres: nbMembres,
  creeLe: DateTime.now(),
);

List<Override> _surcharges(FauxServiceEnseignant enseignant) => <Override>[
  serviceEnseignantProvider.overrideWithValue(enseignant),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

/// Un service qui rend un groupe et ses membres.
FauxServiceEnseignant _avec({
  List<GroupeEnseignant>? groupes,
  List<MembreSeance> membres = const <MembreSeance>[],
}) => FauxServiceEnseignant()
  ..groupesRendus = groupes ?? <GroupeEnseignant>[_groupe()]
  ..membresRendus = <String, List<MembreSeance>>{_groupeId: membres};

/// La fenetre du telephone ou l'enseignant travaille.
void _fenetreTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Une fenetre haute, le temps d'un test.
///
/// `tester.tap` ne touche rien hors du viewport : sans cette fenetre, l'action
/// posee sous la liste des membres ne serait pas atteignable, et le test
/// mesurerait la hauteur de la fenetre au lieu du chemin de navigation.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Le routeur minimal : la fiche, et les deux ecrans qu'elle peut atteindre.
List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: '/enseignant/groupe/:groupeId',
    builder: (BuildContext _, GoRouterState etat) =>
        FicheGroupePage(groupeId: etat.pathParameters['groupeId'] ?? ''),
  ),
  GoRoute(
    path: '/enseignant/groupe/:groupeId/revue',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('revue:${etat.pathParameters['groupeId']}'),
  ),
  GoRoute(
    path: Routes.enseignantJournee,
    builder: (BuildContext _, GoRouterState _) => const Text('journee'),
  ),
];

void main() {
  group('ENS-07 : les etats de la fiche', () {
    testWidgets('loading : un squelette a la forme de la fiche', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant =
          _avec(membres: <MembreSeance>[membreDeTest()])
            ..delai = const Duration(milliseconds: 40);

      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(enseignant),
        ),
      );
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);

      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('content : le groupe, son public, son creneau hebdomadaire', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = _avec(
        membres: <MembreSeance>[
          membreDeTest(prenom: 'Khadija', niveau: 'Debutant'),
          membreDeTest(
            studentId: 'e2',
            identifiant: 'STUD-IB-000004',
            prenom: 'Ibrahim',
          ),
        ],
      );

      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perles du Coran'), findsOneWidget);
      // Les libelles de public existent deja sous `admin.groupes.*` : aucune
      // cle jumelle n'a ete creee.
      expect(find.text(t.admin.groupes.typeEnfant), findsOneWidget);
      expect(
        find.text(
          t.enseignant.ficheGroupe.creneauHebdo(
            jour: t.disponibilites.joursLongs[2],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Khadija'), findsOneWidget);
      expect(find.text('Ibrahim'), findsOneWidget);
    });

    testWidgets('empty : un groupe sans eleve le dit, sans bouton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(_avec(groupes: <GroupeEnseignant>[
            _groupe(nbMembres: 0),
          ])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.ficheGroupe.aucunMembre), findsOneWidget);
      expect(
        find.text(t.enseignant.ficheGroupe.aucunMembreDetail),
        findsOneWidget,
      );
      // L'enseignant ne compose pas son groupe : aucune action ne lui est
      // proposee pour y remedier.
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('error : une phrase, et une relecture qui relit vraiment', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = _avec()
        ..erreurLecture = StateError('mes_groupes_v absente');

      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(enseignant),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.ficheGroupe.erreur), findsOneWidget);

      enseignant.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();

      expect(find.text('Perles du Coran'), findsOneWidget);
    });

    testWidgets('un groupe qui n est pas le sien ne devient pas une erreur', (
      WidgetTester tester,
    ) async {
      // `mes_groupes_v` ne rend que ses groupes actifs : une absence est un
      // groupe cloture ou celui d'un collegue, pas une panne de lecture.
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: 'autre'),
          surcharges: _surcharges(_avec()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.ficheGroupe.introuvable), findsOneWidget);
      expect(find.text(t.enseignant.ficheGroupe.erreur), findsNothing);
    });
  });

  group('ENS-07 : ce que la fiche ne montre jamais', () {
    testWidgets('un membre porte prenom, identifiant immuable et niveau', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              membres: <MembreSeance>[
                membreDeTest(prenom: 'Khadija', niveau: 'Debutant'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khadija'), findsOneWidget);
      // L'identifiant immuable est le seul moyen de nommer un eleve sans nom de
      // famille : il est rendu en entier.
      expect(find.text('RA-0001'), findsOneWidget);
      // « Niveau indique », jamais « niveau du programme » : la valeur vient de
      // `student_profiles.level`, un texte libre.
      expect(
        find.text(t.enseignant.ficheGroupe.niveauIndique(niveau: 'Debutant')),
        findsOneWidget,
      );
    });

    testWidgets('sans niveau, la fiche se tait plutot que d afficher un tiret', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(membres: <MembreSeance>[membreDeTest(prenom: 'Khadija')]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Khadija'), findsOneWidget);
      // Aucune ligne « niveau : - » : une promesse non tenue a chaque eleve
      // coute plus cher que le silence.
      expect(find.textContaining('Niveau'), findsNothing);
    });

    testWidgets('un prenom masque laisse l identifiant nommer l eleve', (
      WidgetTester tester,
    ) async {
      // Sous observation, la base masque le prenom : l'eleve doit rester
      // designable.
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              membres: <MembreSeance>[
                membreDeTest(prenom: null, identifiant: 'RA-0042'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RA-0042'), findsNWidgets(2));
    });
  });

  group('ENS-07 : les places et le seuil', () {
    testWidgets('les places libres se comptent sur le seuil du groupe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              groupes: <GroupeEnseignant>[
                _groupe(seuilMax: 5, nbMembres: 3),
              ],
              membres: <MembreSeance>[membreDeTest()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text(t.enseignant.ficheGroupe.placesLibres), findsOneWidget);
    });

    testWidgets('un groupe complet le dit, et le zero s affiche', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              groupes: <GroupeEnseignant>[
                _groupe(seuilMax: 5, nbMembres: 5),
              ],
              membres: <MembreSeance>[
                membreDeTest(prenom: 'Un'),
                membreDeTest(studentId: 'e2', identifiant: 'RA-2', prenom: 'Deux'),
                membreDeTest(studentId: 'e3', identifiant: 'RA-3', prenom: 'Trois'),
                membreDeTest(studentId: 'e4', identifiant: 'RA-4', prenom: 'Quatre'),
                membreDeTest(studentId: 'e5', identifiant: 'RA-5', prenom: 'Cinq'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.ficheGroupe.complet), findsOneWidget);
      // « 0 place libre » se lit, il ne se masque pas.
      expect(find.text('0'), findsOneWidget);
      expect(
        find.text(t.enseignant.ficheGroupe.placesLibresUn),
        findsNothing,
      );
    });

    testWidgets('une seule place libre se dit au singulier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              groupes: <GroupeEnseignant>[
                _groupe(seuilMax: 6, nbMembres: 5, type: TypePublicGroupe.adulte),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.admin.groupes.typeAdulte), findsOneWidget);
      expect(
        find.text(t.enseignant.ficheGroupe.placesLibresUn),
        findsOneWidget,
      );
    });
  });

  group('ENS-07 : une pose, avec sa sortie', () {
    testWidgets('la sortie ramene a la journee', (WidgetTester tester) async {
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.groupePour(_groupeId),
          routes: _routes(),
          surcharges: _surcharges(_avec()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.ficheGroupe.retour));
      await tester.pumpAndSettle();

      expect(find.text('journee'), findsOneWidget);
    });

    testWidgets('la revue courte du groupe s ouvre depuis la fiche', (
      WidgetTester tester,
    ) async {
      // 1200 de large : la fiche passe a deux colonnes, et l'action de revue
      // reste atteignable. [RESPONSIVE]
      _fenetreHaute(tester);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.groupePour(_groupeId),
          routes: _routes(),
          surcharges: _surcharges(
            _avec(membres: <MembreSeance>[membreDeTest()]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.enseignant.ficheGroupe.revue));
      await tester.pumpAndSettle();

      expect(find.text('revue:g1'), findsOneWidget);
    });

    testWidgets('a 390 x 844, la fiche tient sans deborder', (
      WidgetTester tester,
    ) async {
      _fenetreTelephone(tester);
      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              membres: <MembreSeance>[
                membreDeTest(prenom: 'Khadija', niveau: 'Debutant'),
                membreDeTest(
                  studentId: 'e2',
                  identifiant: 'STUD-IB-000004',
                  prenom: 'Ibrahim',
                  niveau: 'Intermediaire',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a 200 % de taille de texte, rien n est rogne', (
      WidgetTester tester,
    ) async {
      _fenetreTelephone(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        hote(
          const FicheGroupePage(groupeId: _groupeId),
          surcharges: _surcharges(
            _avec(
              membres: <MembreSeance>[
                membreDeTest(prenom: 'Khadija', niveau: 'Debutant'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
