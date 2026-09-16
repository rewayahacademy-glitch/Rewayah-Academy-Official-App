import 'dart:async';

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
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/child_card.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
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
  FauxServiceVideo? video,
}) => <Override>[
  serviceAppairageProvider.overrideWithValue(appairage),
  servicePlanningProvider.overrideWithValue(planning),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  // Depuis le lot `CTR-01`, « Assister » ecrit avant de naviguer : il inscrit
  // le tuteur comme temoin de la seance. Sans ce faux, le premier tap tenterait
  // d'atteindre Supabase.
  serviceVideoProvider.overrideWithValue(video ?? FauxServiceVideo()),
];

/// L'ecran, a l'instant de reference.
Widget _ecran() => AccueilFamillePage(horloge: () => _maintenant);

/// Une fenetre haute, le temps d'un test.
///
/// Un foyer de deux enfants, ses deux blocs secondaires et son bloc d'acces
/// depassent l'ecran d'un telephone. `PageShell` construit tout son contenu
/// d'un coup (contrairement a un `ListView`), mais un widget hors du viewport
/// ne se laisse pas taper : sans cette fenetre, les tests qui tapent une action
/// echoueraient. Meme piege qu'a `ENS-02` en L6.
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
  FauxServiceVideo? video,
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
          path: Routes.tuteurAjouterEnfant,
          builder: (BuildContext _, GoRouterState _) => const Text('TUT-02/a'),
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
      surcharges: _surcharges(
        appairage: appairage,
        planning: planning,
        video: video,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// La decoration du `Container` le plus externe d'une carte enfant : celui
/// d'`AppCard`, qui porte la surface de la carte. Les autres `Container` de la
/// carte (pastille, bouton) viennent apres dans l'ordre de l'arbre.
BoxDecoration _decoCarte(WidgetTester tester) {
  final Container carte = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(ChildCard),
          matching: find.byType(Container),
        ),
      )
      .first;
  return carte.decoration! as BoxDecoration;
}

void main() {
  testWidgets('la premiere lecture montre un squelette', (
    WidgetTester tester,
  ) async {
    final Completer<List<EleveDuFoyer>> reponse =
        Completer<List<EleveDuFoyer>>();

    await tester.pumpWidget(
      hote(
        _ecran(),
        surcharges: <Override>[
          ..._surcharges(
            appairage: FauxServiceAppairage(),
            planning: FauxServicePlanning(),
          ),
          elevesDuFoyerProvider.overrideWith((_) => reponse.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    expect(find.text(t.commun.chargement), findsNothing);

    reponse.complete(const <EleveDuFoyer>[]);
    await tester.pumpAndSettle();
  });

  final AppPalette palette = AppPalette.claire();

  group('TUT-01 : les cinq phases, une carte par enfant', () {
    testWidgets('un cours en direct : pastille verte, Assister, carte posee', (
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

      // Le bouton de confiance, cable.
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.byType(ActionPrincipale),
      );
      expect(bouton.libelle, t.tuteur.accueil.assister);
      expect(bouton.onPress, isNotNull);

      // La pastille verte accompagne la phrase : une couleur seule ne porte
      // jamais un etat.
      final StatusPill pastille = tester.widget<StatusPill>(
        find.byType(StatusPill),
      );
      expect(pastille.ton, TonEtat.succes);

      // Comme le bloc en direct d'`ELV-02` repris : la carte redevient une
      // surface posee, seul le bouton porte l'aplat sature. Deux enfants en
      // cours ne font donc plus deux zones pleines
      // (`docs/design/01-systeme-visuel.md` section 3).
      expect(_decoCarte(tester).color, palette.surfaceRaised.background);
      expect(
        _decoCarte(tester).color,
        isNot(palette.surfacePrimary.background),
      );
    });

    testWidgets('Assister inscrit le tuteur AVANT d\'ouvrir la salle', (
      WidgetTester tester,
    ) async {
      final FauxServiceVideo video = FauxServiceVideo();
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
        video: video,
      );

      await tester.tap(find.text(t.tuteur.accueil.assister));
      await tester.pumpAndSettle();

      // L'ordre est tout le sujet : jusqu'au lot `CTR-01`, ce bouton faisait un
      // simple `go` vers la salle, et le tuteur y arrivait dans l'impasse
      // d'acces -- `autoriser_jeton_video()` lit l'appartenance dans
      // `session_participants`, ou personne ne l'inscrivait.
      expect(video.assistances, <String>['s1']);
      expect(find.text('ELV-03'), findsOneWidget);
    });

    testWidgets('un refus d\'inscription n\'ouvre aucune salle et se dit', (
      WidgetTester tester,
    ) async {
      final FauxServiceVideo video = FauxServiceVideo()
        ..refusInscription = StateError('seance close');
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
        video: video,
      );

      await tester.tap(find.text(t.tuteur.accueil.assister));
      await tester.pumpAndSettle();

      expect(find.text('ELV-03'), findsNothing);
      // Le refus se dit la ou le geste a eu lieu, jamais au centre de l'ecran.
      expect(find.text(t.tuteur.accueil.assisterRefuse), findsOneWidget);
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
      expect(_decoCarte(tester).color, palette.surfaceRaised.background);
    });

    testWidgets(
      'rien aujourd hui : le prochain cours est date, sans preambule',
      (WidgetTester tester) async {
        final DateTime jeudi = _maintenant.add(const Duration(days: 2));
        await _monter(
          tester,
          appairage: FauxServiceAppairage()
            ..elevesRendus = <EleveDuFoyer>[_enfant()],
          planning: FauxServicePlanning()
            ..seancesRendues = <Seance>[_cours(debut: jeudi)]
            ..affectationsRendues = <Affectation>[_affectation()],
        );

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
        // La reprise laisse tomber le preambule « Rien aujourd'hui » : la carte
        // affiche directement le rendez-vous date.
        expect(find.text(t.tuteur.accueil.rienAujourdhui), findsNothing);
      },
    );

    testWidgets('sans enseignant, la carte dit depuis quand le foyer attend', (
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

      // Le libelle de la pastille neutre.
      expect(find.text(t.tuteur.accueil.enRecherche), findsOneWidget);
      final StatusPill pastille = tester.widget<StatusPill>(
        find.byType(StatusPill),
      );
      expect(pastille.ton, TonEtat.neutre);
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
      await tester.ensureVisible(find.text(t.tuteur.accueil.poserDesHeures));
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

      // Le motif tient en une phrase : quel cours n'aura pas lieu.
      expect(
        find.text(t.tuteur.accueil.annulee(heure: '17:30')),
        findsOneWidget,
      );
      // Le statut « Annule » vit maintenant dans la pastille, pas dans une
      // phrase, et jamais dans sa valeur SQL : le tuteur est un adulte, mais
      // pas un lecteur de base de donnees.
      final StatusPill pastille = tester.widget<StatusPill>(
        find.byType(StatusPill),
      );
      expect(pastille.libelle, t.etat.annule);
      expect(pastille.ton, TonEtat.alerte);
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

    testWidgets('deux enfants en direct : deux cartes posees, aucun aplat', (
      WidgetTester tester,
    ) async {
      // L'ancien ecran posait la ligne en cours sur un aplat `surfacePrimary`
      // plein : deux enfants en cours donnaient deux zones pleines. Chaque
      // carte est desormais posee, l'aplat sature ne vit que dans le bouton.
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[
            _enfant(),
            _enfant(id: 'e2', prenom: 'Ibrahim'),
          ],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(
              debut: _maintenant.subtract(const Duration(minutes: 5)),
              statut: StatutSeance.enCours,
            ),
            _cours(
              id: 's2',
              eleveId: 'e2',
              debut: _maintenant.subtract(const Duration(minutes: 3)),
              statut: StatutSeance.enCours,
            ),
          ]
          ..affectationsRendues = <Affectation>[
            _affectation(),
            _affectation(eleveId: 'e2'),
          ],
      );

      expect(find.byType(ChildCard), findsNWidgets(2));
      // La surface propre de chaque carte, c'est-a-dire le `Container` le plus
      // externe (celui d'`AppCard`), pas le fond du bouton qui vit dedans.
      for (int i = 0; i < 2; i++) {
        final Container carte = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(ChildCard).at(i),
                matching: find.byType(Container),
              ),
            )
            .first;
        final BoxDecoration deco = carte.decoration! as BoxDecoration;
        expect(deco.color, palette.surfaceRaised.background);
        expect(deco.color, isNot(palette.surfacePrimary.background));
      }
    });
  });

  group('TUT-01 : ce que le foyer lit autour des enfants', () {
    testWidgets('l ecran passe par PageShell et porte la section de gestion', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        appairage: FauxServiceAppairage()
          ..elevesRendus = <EleveDuFoyer>[_enfant()],
        planning: FauxServicePlanning()
          ..seancesRendues = <Seance>[
            _cours(debut: _maintenant.add(const Duration(days: 2))),
          ]
          ..affectationsRendues = <Affectation>[_affectation()],
      );

      expect(find.byType(PageShell), findsOneWidget);
      expect(find.text(t.tuteur.accueil.titre), findsOneWidget);
      expect(find.text(t.tuteur.accueil.gererLeFoyer), findsOneWidget);
    });

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

      await tester.ensureVisible(find.text(t.tuteur.accueil.blocReglages));
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

  group('TUT-01 : la phase se decide sans monter d ecran', () {
    final Seance enCours = _cours(
      debut: _maintenant.subtract(const Duration(minutes: 10)),
      statut: StatutSeance.enCours,
    );

    test('sans affectation et sans cours, l enfant est en recherche', () {
      expect(
        phaseEnfant(
          prochain: null,
          annulee: null,
          affecte: false,
          maintenant: _maintenant,
        ),
        PhaseEnfant.enRecherche,
      );
      // Affecte mais sans seance materialisee : ce n'est pas une recherche,
      // c'est une semaine qui n'est pas encore posee.
      expect(
        phaseEnfant(
          prochain: null,
          annulee: null,
          affecte: true,
          maintenant: _maintenant,
        ),
        PhaseEnfant.rienAujourdhui,
      );
    });

    test('un cours en direct passe devant une affectation absente', () {
      // Un enfant dont l'enseignant vient de changer garde ses seances : dire
      // « en recherche » au-dessus d'un cours qui se tient serait faux.
      expect(
        phaseEnfant(
          prochain: enCours,
          annulee: null,
          affecte: false,
          maintenant: _maintenant,
        ),
        PhaseEnfant.enCours,
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
        phaseEnfant(
          prochain: plusTard,
          annulee: annuleeTot,
          affecte: true,
          maintenant: _maintenant,
        ),
        PhaseEnfant.seanceAnnulee,
      );
      expect(
        phaseEnfant(
          prochain: _cours(debut: _maintenant.add(const Duration(minutes: 30))),
          annulee: _cours(
            id: 's4',
            debut: _maintenant.add(const Duration(hours: 5)),
            statut: StatutSeance.annulee,
          ),
          affecte: true,
          maintenant: _maintenant,
        ),
        PhaseEnfant.coursAujourdhui,
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
