import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';

import '../support/harnais.dart';

/// L'instant de reference de tous ces tests.
///
/// Un mardi a dix-sept heures, fige comme celui de `ELV-02` : le minuteur
/// ecoule et le partage entre « aujourd'hui » et « un autre jour » se comptent
/// en minutes, et un test cale sur l'horloge de la machine changerait de
/// resultat selon l'heure a laquelle la CI le lance.
final DateTime _maintenant = DateTime(2026, 9, 8, 17);

EleveDuFoyer _enfant({
  String id = 'e1',
  String prenom = 'Amina',
  DateTime? finAcces,
}) => EleveDuFoyer(
  id: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-AD-000001',
  mode: InterfaceMode.enfant,
  camera: CameraPolicy.forbidden,
  finAcces: finAcces,
);

Seance _cours({
  required DateTime debut,
  String id = 's1',
  String eleveId = 'e1',
  StatutSeance statut = StatutSeance.planifiee,
}) => Seance(
  id: id,
  debut: debut,
  fin: debut.add(const Duration(minutes: 60)),
  statut: statut,
  eleveId: eleveId,
  elevePrenom: 'Amina',
  eleveIdentifiant: 'STUD-AD-000001',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
);

Affectation _affectation({String eleveId = 'e1'}) => Affectation(
  id: 'a1',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'TEACH-AD-000001',
  eleveId: eleveId,
  elevePrenom: 'Amina',
  creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  depuis: DateTime(2026, 9, 1),
);

List<Override> _surcharges({
  required FauxServiceAppairage appairage,
  required FauxServicePlanning planning,
}) => <Override>[
  serviceAppairageProvider.overrideWithValue(appairage),
  servicePlanningProvider.overrideWithValue(planning),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

/// L'ecran, a l'instant de reference.
Widget _ecran() => AccueilFamillePage(horloge: () => _maintenant);

/// Une fenetre haute, le temps d'un test.
///
/// Un foyer de deux enfants, ses deux blocs secondaires et son bloc d'acces
/// depassent l'ecran d'un telephone, et un `ListView` ne construit pas ce qui
/// n'est pas visible : sans cette fenetre, le test mesure la hauteur du
/// viewport et non le contenu de l'ecran. Meme piege qu'a `ENS-02` en L6.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _monter(
  WidgetTester tester, {
  required FauxServiceAppairage appairage,
  required FauxServicePlanning planning,
}) async {
  _fenetreHaute(tester);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.tuteurAccueil,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.tuteurAccueil,
          builder: (BuildContext _, GoRouterState _) => _ecran(),
        ),
        GoRoute(
          path: Routes.tuteurFoyer,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-02'),
        ),
        GoRoute(
          path: Routes.tuteurReglages,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-05'),
        ),
        GoRoute(
          path: Routes.tuteurDisponibilites,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-04'),
        ),
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState _) => const Text('ELV-03'),
        ),
      ],
      surcharges: _surcharges(appairage: appairage, planning: planning),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TUT-01 : les cinq etats, une ligne par enfant', () {
    testWidgets('un cours en direct porte la pastille verte et Assister', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(
              debut: _maintenant.subtract(const Duration(minutes: 12)),
              statut: StatutSeance.enCours,
            ),
          ]
          ..affectationsRendues = <Affectation>[_affectation()],
      );

      // Le prenom de l'enseignante, jamais son nom de famille (ADR-008).
      expect(
        find.text(t.tuteur.accueil.enCours(prenom: 'Aminata')),
        findsOneWidget,
      );
      // Le minuteur ecoule de la fiche produit.
      expect(
        find.text(t.tuteur.accueil.depuisMinutes(minutes: '12')),
        findsOneWidget,
      );
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byType(ActionPrincipale),
      );
      expect(bouton.libelle, t.tuteur.accueil.assister);
      expect(bouton.onPress, isNotNull);
      // La ligne bascule sur la surface d'accent, comme le bloc en direct de
      // `ELV-02` : les deux ecrans disent la meme chose du meme cours.
      final BentoTile ligne = tester.widget<BentoTile>(
        find.byType(BentoTile).first,
      );
      expect(ligne.surface, AppPalette.claire().surfacePrimary);
    });

    testWidgets('hors seance, Assister n est pas rendu du tout', (
      WidgetTester tester,
    ) async {
      // La mesure inverse : le meme enfant, le meme enseignant, un cours qui
      // n'a pas commence. Un bouton qui ne peut pas aboutir n'est pas rendu.
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(debut: _maintenant.add(const Duration(minutes: 40))),
          ]
          ..affectationsRendues = <Affectation>[_affectation()],
      );

      expect(
        find.text(
          t.tuteur.accueil.aujourdhui(heure: '17:40', prenom: 'Aminata'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ActionPrincipale), findsNothing);
      final BentoTile ligne = tester.widget<BentoTile>(
        find.byType(BentoTile).first,
      );
      expect(ligne.surface, AppPalette.claire().surfaceCanvas);
    });

    testWidgets('rien aujourd hui : le prochain cours est date', (
      WidgetTester tester,
    ) async {
      final DateTime jeudi = _maintenant.add(const Duration(days: 2));
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[_cours(debut: jeudi)]
          ..affectationsRendues = <Affectation>[_affectation()],
      );

      expect(find.text(t.tuteur.accueil.rienAujourdhui), findsOneWidget);
      // Date et heure, contrairement a `ELV-02` qui compte en jours : le parent
      // organise sa semaine, l'enfant attend son cours.
      expect(
        find.text(
          t.tuteur.accueil.unAutreJour(
            jour: t.disponibilites.joursLongs[jeudi.weekday - 1],
            heure: '17:00',
            prenom: 'Aminata',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans enseignant, la ligne dit depuis quand le foyer attend', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux['e1'] = <Creneau>[
          Creneau(
            jour: 2,
            heure: 17,
            fuseau: 'Europe/Paris',
            poseLe: DateTime(2026, 9, 3),
          ),
          Creneau(
            jour: 4,
            heure: 18,
            fuseau: 'Europe/Paris',
            poseLe: DateTime(2026, 9, 1),
          ),
        ];

      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: planning,
      );

      expect(find.text(t.tuteur.accueil.enRecherche), findsOneWidget);
      // La plus ancienne des heures proposees, pas la derniere : c'est
      // l'anciennete sur laquelle `ENS-06` trie son feed.
      expect(
        find.text(t.tuteur.accueil.enRechercheDepuis(date: '01/09/2026')),
        findsOneWidget,
      );
    });

    testWidgets('sans heure proposee, la recherche ne peut pas aboutir', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning(),
      );

      expect(
        find.text(t.tuteur.accueil.sansCreneau(prenom: 'Amina')),
        findsOneWidget,
      );
      await tester.tap(find.text(t.tuteur.accueil.poserDesHeures));
      await tester.pumpAndSettle();

      expect(find.text('TUT-04'), findsOneWidget);
    });

    testWidgets('une seance annulee dit le motif, et ce qui est propose', (
      WidgetTester tester,
    ) async {
      final DateTime demain = _maintenant.add(const Duration(days: 1));
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(
              debut: _maintenant.add(const Duration(minutes: 30)),
              statut: StatutSeance.annulee,
            ),
            _cours(id: 's2', debut: demain),
          ]
          ..affectationsRendues = <Affectation>[_affectation()],
      );

      expect(
        find.text(t.tuteur.accueil.annulee(heure: '17:30')),
        findsOneWidget,
      );
      // Le motif est le statut dit en clair, jamais sa valeur SQL : le tuteur
      // est un adulte, mais ce n'est pas un lecteur de base de donnees.
      expect(find.text(t.tuteur.accueil.motifAnnulee), findsOneWidget);
      expect(find.textContaining(StatutSeance.annulee.valeurSql), findsNothing);
      expect(
        find.text(
          t.tuteur.accueil.proposeApres(
            jour: t.disponibilites.joursLongs[demain.weekday - 1],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('TUT-01 : ce que le foyer lit autour des enfants', () {
    testWidgets('la date de fin d acces se lit enfant par enfant', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[
            _enfant(finAcces: DateTime(2026, 10, 15)),
            _enfant(id: 'e2', prenom: 'Ibrahim'),
          ],
        planning: FauxServicePlanning(),
      );

      expect(
        find.text(
          t.tuteur.accueil.accesJusqua(prenom: 'Amina', date: '15/10/2026'),
        ),
        findsOneWidget,
      );
      // Sans echeance, la ligne existe quand meme : un compteur qui disparait
      // laisse croire que l'information manque.
      expect(
        find.text(t.tuteur.accueil.accesSansFin(prenom: 'Ibrahim')),
        findsOneWidget,
      );
    });

    testWidgets('les deux blocs secondaires menent la ou ils annoncent', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning(),
      );

      await tester.tap(find.text(t.tuteur.accueil.blocReglages));
      await tester.pumpAndSettle();
      expect(find.text('TUT-05'), findsOneWidget);
    });

    testWidgets('un foyer sans enfant invite a en ajouter un', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage(),
        planning: FauxServicePlanning(),
      );

      expect(find.text(t.tuteur.accueil.aucunEnfant), findsOneWidget);
      expect(find.text(t.tuteur.accueil.aucunEnfantDetail), findsOneWidget);
    });
  });

  group('TUT-01 : l etat se decide sans monter d ecran', () {
    final Seance enCours = _cours(
      debut: _maintenant.subtract(const Duration(minutes: 10)),
      statut: StatutSeance.enCours,
    );

    test('sans affectation et sans cours, l enfant est en recherche', () {
      expect(
        etatEnfant(
          prochain: null,
          annulee: null,
          affecte: false,
          maintenant: _maintenant,
        ),
        EtatEnfant.enRecherche,
      );
      // Affecte mais sans seance materialisee : ce n'est pas une recherche,
      // c'est une semaine qui n'est pas encore posee.
      expect(
        etatEnfant(
          prochain: null,
          annulee: null,
          affecte: true,
          maintenant: _maintenant,
        ),
        EtatEnfant.rienAujourdhui,
      );
    });

    test('un cours en direct passe devant une affectation absente', () {
      // Un enfant dont l'enseignant vient de changer garde ses seances : dire
      // « en recherche » au-dessus d'un cours qui se tient serait faux.
      expect(
        etatEnfant(
          prochain: enCours,
          annulee: null,
          affecte: false,
          maintenant: _maintenant,
        ),
        EtatEnfant.enCours,
      );
    });

    test('une annulation ne passe devant que si elle vient avant', () {
      final Seance annuleeTot = _cours(
        id: 's0',
        debut: _maintenant.subtract(const Duration(minutes: 5)),
        statut: StatutSeance.annulee,
      );
      final Seance plusTard = _cours(
        id: 's2',
        debut: _maintenant.add(const Duration(hours: 3)),
      );

      expect(
        etatEnfant(
          prochain: plusTard,
          annulee: annuleeTot,
          affecte: true,
          maintenant: _maintenant,
        ),
        EtatEnfant.seanceAnnulee,
      );
      expect(
        etatEnfant(
          prochain: _cours(debut: _maintenant.add(const Duration(minutes: 30))),
          annulee: _cours(
            id: 's4',
            debut: _maintenant.add(const Duration(hours: 5)),
            statut: StatutSeance.annulee,
          ),
          affecte: true,
          maintenant: _maintenant,
        ),
        EtatEnfant.coursAujourdhui,
      );
    });

    test('l attente se compte sur la plus ancienne heure proposee', () {
      expect(
        attendDepuis(<Creneau>[
          Creneau(
            jour: 2,
            heure: 17,
            fuseau: 'Europe/Paris',
            poseLe: DateTime(2026, 9, 3),
          ),
          Creneau(
            jour: 4,
            heure: 18,
            fuseau: 'Europe/Paris',
            poseLe: DateTime(2026, 9, 1),
          ),
        ]),
        DateTime(2026, 9, 1),
      );
      // Une source qui ne date pas ses lignes ne fabrique pas de date : le feed
      // de `ENS-06` rend ses creneaux sans `created_at`, et l'ecran le dit
      // autrement plutot que d'afficher aujourd'hui.
      expect(
        attendDepuis(const <Creneau>[
          Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ]),
        isNull,
      );
      expect(attendDepuis(const <Creneau>[]), isNull);
    });
  });
}
