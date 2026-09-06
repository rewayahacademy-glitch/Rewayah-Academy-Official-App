import 'dart:ui' show Size;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/harnais.dart';

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

const ReglagesPriere _paris = ReglagesPriere(
  enseignantId: _monId,
  latitude: 48.85341,
  longitude: 2.34880,
  methode: MethodeCalcul.ligueMondiale,
  madhab: Madhab.shafi,
  lieu: 'Paris',
);

/// Une seance de l'enseignant observe.
Seance _cours({
  required DateTime debut,
  required DateTime fin,
  String id = 's1',
  String prenom = 'Khadija',
  String identifiant = 'STUD-KB-000003',
  StatutSeance statut = StatutSeance.planifiee,
}) => Seance(
  id: id,
  debut: debut,
  fin: fin,
  statut: statut,
  eleveId: 'e-$id',
  elevePrenom: prenom,
  eleveIdentifiant: identifiant,
  enseignantId: _monId,
  enseignantPrenom: 'Omar',
  enseignantIdentifiant: 'TEACH-OS-000001',
);

EleveEnAttente _enAttente({
  required String eleveId,
  required int jour,
  required int heure,
  String prenom = 'Ibrahim',
}) => EleveEnAttente(
  eleveId: eleveId,
  prenom: prenom,
  identifiantImmuable: 'STUD-IB-000004',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now(),
  mode: InterfaceMode.enfant,
);

FauxServiceRegles _reglesAvecPause(int minutes) => FauxServiceRegles()
  ..parProfil[_monId] = <RegleProfil>[
    RegleProfil(
      cle: CleRegle.pauseEntreCours,
      valeurEffective: minutes,
      valeurPlateforme: 30,
    ),
  ];

List<Override> _surcharges({
  required FauxServicePlanning planning,
  FauxServiceMatching? matching,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  servicePlanningProvider.overrideWithValue(planning),
  serviceMatchingProvider.overrideWithValue(
    matching ?? FauxServiceMatching(),
  ),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(priere ?? FauxServicePriere()),
];

/// L'heure locale d'un instant, comme l'ecran l'ecrit.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// Une fenetre haute, le temps d'un test.
///
/// La colonne d'une journee chargee depasse l'ecran d'un telephone, et un
/// `ListView` ne construit pas ce qui n'est pas visible : sans cette fenetre,
/// le test mesure la hauteur du viewport et non le contenu de la colonne. La
/// deuxieme priere du jour manquait pour cette seule raison.
void _fenetreHaute(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Un instant du jour civil local courant, a l'heure demandee.
DateTime _aujourdhuiA(int heure, [int minute = 0]) {
  final DateTime maintenant = DateTime.now();
  return DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
    heure,
    minute,
  );
}

void main() {
  group('ENS-02 : le bloc dominant', () {
    testWidgets('il porte le prenom, l identifiant immuable et le minuteur', (
      WidgetTester tester,
    ) async {
      // Trente secondes de marge : sans elles, les microsecondes ecoulees entre
      // la fixture et le build feraient tomber le compte a 24 minutes.
      final DateTime debut = DateTime.now().add(
        const Duration(minutes: 25, seconds: 30),
      );
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.prochainCours), findsOneWidget);
      expect(find.text('Khadija'), findsWidgets);
      // Prenom et identifiant immuable, jamais le nom de famille (ADR-008).
      expect(find.text('STUD-KB-000003'), findsWidgets);
      expect(
        find.text(t.enseignant.journee.minuteurMinutes(minutes: '25')),
        findsOneWidget,
      );
    });

    testWidgets('le bouton de lancement n existe pas, une phrase le remplace', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().add(const Duration(minutes: 30));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(minutes: 60))),
        ];

      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      // Le pre-flight est l'etape 5 : un bouton qui echoue apres le geste coute
      // plus cher qu'un bouton absent.
      expect(find.text(t.enseignant.journee.lancer), findsNothing);
      expect(find.text(t.enseignant.journee.preflight), findsNothing);
      expect(find.text(t.enseignant.journee.sansLancement), findsOneWidget);
    });

    testWidgets('un cours commence annonce son heure de fin', (
      WidgetTester tester,
    ) async {
      final DateTime debut = DateTime.now().subtract(
        const Duration(minutes: 10),
      );
      final DateTime fin = debut.add(const Duration(minutes: 60));
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[_cours(debut: debut, fin: fin)];

      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.coursEnCours), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.jusqua(heure: _hhmm(fin))),
        findsOneWidget,
      );
    });

    testWidgets('sans cours a venir, l ecran invite a prendre un eleve', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(planning: FauxServicePlanning()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.aucunCours), findsOneWidget);
      expect(find.text(t.enseignant.journee.aucunCoursDetail), findsOneWidget);
    });
  });

  group('ENS-02 : une seule colonne, du haut vers le bas', () {
    testWidgets('cours, pause et prieres y sont des entrees de meme nature', (
      WidgetTester tester,
    ) async {
      final DateTime premier = _aujourdhuiA(9);
      final DateTime second = _aujourdhuiA(10, 30);
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: premier, fin: premier.add(const Duration(hours: 1))),
          _cours(
            debut: second,
            fin: second.add(const Duration(hours: 1)),
            id: 's2',
            prenom: 'Ibrahim',
            identifiant: 'STUD-IB-000004',
          ),
        ];
      final FauxServicePriere priere = FauxServicePriere()
        ..parEnseignant[_monId] = _paris;

      _fenetreHaute(tester);
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            planning: planning,
            priere: priere,
            regles: _reglesAvecPause(30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Khadija')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Ibrahim')),
        findsOneWidget,
      );
      // Le trou de trente minutes entre les deux cours est une pause, parce que
      // la regle de cet enseignant le dit.
      expect(find.text(t.enseignant.journee.lignePause), findsOneWidget);

      // Les prieres du jour ne sont pas dans un bloc a part : chacune est une
      // ligne de la meme colonne. Un jour civil de vingt-quatre heures en
      // contient toujours plusieurs, quel que soit le fuseau de la machine.
      final List<InterruptionPriere> interruptions = interruptionsEntre(
        reglages: _paris,
        debut: _aujourdhuiA(0),
        fin: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 1,
        ),
      );
      expect(interruptions, isNotEmpty);
      for (final InterruptionPriere interruption in interruptions) {
        expect(
          find.text(libellePriere(interruption.priere)),
          findsWidgets,
          reason: 'la priere doit etre une ligne de la colonne',
        );
      }
    });

    testWidgets('sans regle de pause lisible, aucun trou n est une pause', (
      WidgetTester tester,
    ) async {
      final DateTime premier = _aujourdhuiA(9);
      final DateTime second = _aujourdhuiA(10, 30);
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: premier, fin: premier.add(const Duration(hours: 1))),
          _cours(
            debut: second,
            fin: second.add(const Duration(hours: 1)),
            id: 's2',
            prenom: 'Ibrahim',
          ),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          // La meme journee, sans la regle : la valeur ne se remplace pas par
          // une constante, et les deux cours restent exacts.
          surcharges: _surcharges(planning: planning),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.lignePause), findsNothing);
      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'Khadija')),
        findsOneWidget,
      );
    });

    testWidgets('une journee vide dit quand le prochain cours arrive', (
      WidgetTester tester,
    ) async {
      final DateTime demain = DateTime.now().add(const Duration(days: 2));
      final DateTime debut = DateTime(
        demain.year,
        demain.month,
        demain.day,
        17,
      );
      final FauxServicePlanning planning = FauxServicePlanning()
        ..seancesRendues = <Seance>[
          _cours(debut: debut, fin: debut.add(const Duration(hours: 1))),
        ];

      await tester.pumpWidget(
        hote(const JourneePage(), surcharges: _surcharges(planning: planning)),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.rienAujourdhui), findsOneWidget);
      expect(
        find.text(
          t.enseignant.journee.rienAujourdhuiDetail(
            jour: t.disponibilites.joursLongs[debut.weekday - 1],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
      // Le bloc dominant n'est pas borne a aujourd'hui : il dit quand on
      // reprend, au lieu de rester vide.
      expect(
        find.text(
          t.enseignant.journee.unAutreJour(
            jour: t.disponibilites.joursLongs[debut.weekday - 1],
            heure: '17:00',
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('ENS-02 : le bloc secondaire', () {
    testWidgets('il compte les eleves, pas les lignes du feed', (
      WidgetTester tester,
    ) async {
      // Le feed rend une ligne par creneau compatible : Ibrahim y figure trois
      // fois. Compter les lignes annoncerait quatre familles pour deux.
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[
          _enAttente(eleveId: 'e1', jour: 2, heure: 17),
          _enAttente(eleveId: 'e1', jour: 3, heure: 17),
          _enAttente(eleveId: 'e1', jour: 4, heure: 18),
          _enAttente(eleveId: 'e2', jour: 5, heure: 9, prenom: 'Fatou'),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            planning: FauxServicePlanning(),
            matching: matching,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.elevesEnAttente(nombre: '2')),
        findsOneWidget,
      );
    });

    testWidgets('un compteur a zero s affiche, il ne disparait pas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(planning: FauxServicePlanning()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(t.enseignant.journee.aucunEleveEnAttente),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.voirCreneaux), findsOneWidget);
    });

    testWidgets('un seul eleve se dit au singulier', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[
          _enAttente(eleveId: 'e1', jour: 2, heure: 17),
          _enAttente(eleveId: 'e1', jour: 3, heure: 17),
        ];

      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            planning: FauxServicePlanning(),
            matching: matching,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.journee.unEleveEnAttente), findsOneWidget);
    });
  });
}
