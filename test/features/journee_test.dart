// ENS-02 Aujourd'hui (EN-2) : carte « Prochaine seance » (E11), « Ma
// journee », « A terminer » (K-45), « Alertes utiles », une ou deux colonnes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/horaires_priere.dart';
import 'package:rewayah_academy/core/priere/libelle_priere.dart';
import 'package:rewayah_academy/core/priere/reglages_priere.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/widgets/point_rappel.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../support/harnais.dart';

const String _monId = 't1';

/// Le « maintenant » des tests : lundi 28 septembre 2026, 16 h.
final DateTime _m = DateTime(2026, 9, 28, 16);

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

PresenceParticipant _presence({
  required EtatPresence etat,
  String profilId = 'e1',
  String prenom = 'Maryam',
}) => PresenceParticipant(
  profilId: profilId,
  role: 'student',
  prenom: prenom,
  identifiantImmuable: 'STUD-XX-000003',
  etat: etat,
  consolide: false,
);

FauxServiceRegles _reglesAvecPause(int minutes) =>
    FauxServiceRegles()
      ..parProfil[_monId] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.pauseEntreCours,
          valeurEffective: minutes,
          valeurPlateforme: 30,
        ),
      ];

List<Override> _surcharges({
  FauxServiceEnseignant? enseignant,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
  FauxServicePresence? presence,
  FauxServiceReseau? reseau,
  DateTime? maintenant,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  serviceEnseignantProvider.overrideWithValue(
    enseignant ?? FauxServiceEnseignant(),
  ),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(regles ?? FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(priere ?? FauxServicePriere()),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  servicePresenceProvider.overrideWithValue(presence ?? FauxServicePresence()),
  serviceReseauProvider.overrideWithValue(reseau ?? FauxServiceReseau()),
  maintenantJourneeProvider.overrideWithValue(() => maintenant ?? _m),
];

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

SeanceEnseignant _anNour({StatutSeance statut = StatutSeance.planifiee}) =>
    seanceDeTest(
      id: 'an-nour',
      debut: DateTime(2026, 9, 28, 17, 30),
      statut: statut,
      nbParticipants: 4,
      groupeId: 'g-an-nour',
      groupeLibelle: 'An-Nour',
    );

CahierEnRetard _cahier(String id, String classe, int jour) => CahierEnRetard(
  seanceId: id,
  debut: DateTime(2026, 9, jour, 17),
  fin: DateTime(2026, 9, jour, 17, 45),
  nbParticipants: 3,
  heuresDeRetard: 30,
  groupeId: 'g-$id',
  groupeLibelle: classe,
);

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: Routes.enseignantJournee,
    builder: (BuildContext _, GoRouterState _) => const JourneePage(),
  ),
  GoRoute(
    path: '/enseignant/groupe/:groupeId',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('groupe:${etat.pathParameters['groupeId']}'),
  ),
  GoRoute(
    path: '/enseignant/seance/:seanceId/cahier',
    builder: (BuildContext _, GoRouterState etat) =>
        Text('cahier:${etat.pathParameters['seanceId']}'),
  ),
];

Future<void> _ouvrir(
  WidgetTester tester, {
  FauxServiceEnseignant? enseignant,
  FauxServiceRegles? regles,
  FauxServicePriere? priere,
  FauxServicePresence? presence,
  FauxServiceReseau? reseau,
  DateTime? maintenant,
  Size taille = const Size(390, 2400),
}) async {
  _fenetre(tester, taille);
  await tester.pumpWidget(
    hote(
      const JourneePage(),
      surcharges: _surcharges(
        enseignant: enseignant,
        regles: regles,
        priere: priere,
        presence: presence,
        reseau: reseau,
        maintenant: maintenant,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-02 : les etats de l ecran', () {
    testWidgets('chargement : un squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..delai = const Duration(milliseconds: 40);
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(enseignant: enseignant),
        ),
      );
      await tester.pump();
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
    });

    testWidgets('titre « Aujourd hui » et la date du jour', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      expect(find.text(t.enseignant.journee.titre), findsWidgets);
      expect(find.text('Lundi 28 septembre'), findsOneWidget);
    });

    testWidgets('vide : aucune seance, ni A terminer ni Alertes', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester);
      expect(find.text(t.enseignant.journee.aucuneSeance), findsOneWidget);
      expect(find.text(t.enseignant.journee.rienAujourdhui), findsOneWidget);
      expect(find.text(t.enseignant.journee.aTerminer), findsNothing);
      expect(find.text(t.enseignant.journee.alertesUtiles), findsNothing);
    });

    testWidgets('erreur : une phrase, et de quoi relire', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..erreurLecture = StateError('vue absente');
      await _ouvrir(tester, enseignant: enseignant);
      expect(find.text(t.enseignant.journee.erreur), findsOneWidget);

      final int avant = enseignant.lecturesSeances;
      enseignant.erreurLecture = null;
      await tester.tap(find.text(t.commun.reessayer).first);
      await tester.pumpAndSettle();
      expect(enseignant.lecturesSeances, greaterThan(avant));
    });

    testWidgets('retires : eleves en attente et cours individuel', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            seanceDeTest(debut: DateTime(2026, 9, 28, 17, 30)),
          ],
      );
      expect(find.text(t.enseignant.journee.enAttenteTitre), findsNothing);
      expect(find.text(t.enseignant.journee.coursIndividuel), findsNothing);
      // Une seance sans nom de Classe dit « Classe », rien d'autre.
      expect(find.text(t.enseignant.journee.classe), findsOneWidget);
    });
  });

  group('ENS-02 : la carte « Prochaine seance » (E11, E12)', () {
    testWidgets('peu de donnees : nom, heure, duree, eleves', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.enseignant.journee.prochaineSeance), findsOneWidget);
      expect(find.text('An-Nour'), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.plage(debut: '17:30', fin: '18:15')),
        findsWidgets,
      );
      expect(
        find.text(t.enseignant.journee.effectif(nombre: '4')),
        findsWidgets,
      );
    });

    testWidgets('avant la fenetre : le contexte, puis Preparer la seance', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.enseignant.journee.preparerSeance), findsOneWidget);
      expect(find.text(t.classe.entree.preparer), findsNothing);
    });

    testWidgets('fenetre ouverte : Preparer l entree (CL-4)', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 25),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.classe.entree.preparer), findsOneWidget);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
    });

    testWidgets('le bouton mene a la Classe', (WidgetTester tester) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..seancesRendues = <SeanceEnseignant>[_anNour()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.journee.preparerSeance));
      await tester.pumpAndSettle();
      expect(find.text('groupe:g-an-nour'), findsOneWidget);
    });

    testWidgets('hors ligne : la ligne d etat et Reessayer, sans bouton', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        reseau: FauxServiceReseau(horsLigneRendu: true),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[_anNour()],
      );
      expect(find.text(t.classe.entree.horsLigne), findsOneWidget);
      expect(find.text(t.enseignant.journee.preparerSeance), findsNothing);
    });
  });

  group('E11 : emplacementJournee, sans fork d EmplacementEntree', () {
    EmplacementEntree ligne(EtatEntree etat) => EmplacementEntree(
      role: RoleEntree.enseignant,
      etat: etat,
      forme: FormeEntree.ligne,
      libelle: 'contexte',
      annonce: 'annonce',
    );

    test('a venir : Preparer la seance, la ligne devient le contexte', () {
      final EmplacementEntree e = emplacementJournee(
        ligne(EtatEntree.aVenir),
        nomClasse: 'An-Nour',
        cahierAFinaliser: false,
      );
      expect(e.estBouton, isTrue);
      expect(e.libelle, t.enseignant.journee.preparerSeance);
      expect(e.detail, 'contexte');
      expect(e.annonce, 'annonce');
    });

    test('terminee, cahier non depose : Finaliser le cahier', () {
      final EmplacementEntree e = emplacementJournee(
        ligne(EtatEntree.terminee),
        nomClasse: 'An-Nour',
        cahierAFinaliser: true,
      );
      expect(e.libelle, t.enseignant.journee.finaliserCahier);
    });

    test('terminee et deposee, ou annulee : Voir la Classe', () {
      for (final EtatEntree etat in <EtatEntree>[
        EtatEntree.terminee,
        EtatEntree.annulee,
      ]) {
        expect(
          emplacementJournee(
            ligne(etat),
            nomClasse: 'An-Nour',
            cahierAFinaliser: false,
          ).libelle,
          t.enseignant.journee.voirClasse,
        );
      }
    });

    test('preparation et reessai restent tels quels (jamais grise)', () {
      final EmplacementEntree prep = ligne(EtatEntree.preparation);
      expect(
        emplacementJournee(prep, nomClasse: 'x', cahierAFinaliser: true),
        same(prep),
      );
      const EmplacementEntree reessai = EmplacementEntree(
        role: RoleEntree.enseignant,
        etat: EtatEntree.indisponible,
        forme: FormeEntree.ligne,
        libelle: 'hors ligne',
        annonce: 'hors ligne',
        reessayer: true,
      );
      expect(
        emplacementJournee(reessai, nomClasse: 'x', cahierAFinaliser: true),
        same(reessai),
      );
    });
  });

  group('ENS-02 : Ma journee', () {
    testWidgets('cours, pause et prieres dans la meme colonne', (
      WidgetTester tester,
    ) async {
      final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[
          seanceDeTest(
            debut: DateTime(2026, 9, 28, 9),
            duree: const Duration(hours: 1),
            groupeId: 'g1',
            groupeLibelle: 'An-Nour',
            nbParticipants: 4,
          ),
          seanceDeTest(
            id: 's2',
            debut: DateTime(2026, 9, 28, 10, 30),
            duree: const Duration(hours: 1),
            groupeId: 'g2',
            groupeLibelle: 'Al-Badr',
            nbParticipants: 3,
          ),
        ];
      final FauxServicePriere priere = FauxServicePriere()
        ..parEnseignant[_monId] = _paris;
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 8),
        enseignant: enseignant,
        priere: priere,
        regles: _reglesAvecPause(30),
      );

      expect(find.text(t.enseignant.journee.maJournee), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.ligneCours(prenom: 'la Classe Al-Badr')),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.lignePause), findsOneWidget);
      final List<InterruptionPriere> interruptions = interruptionsEntre(
        reglages: _paris,
        debut: DateTime(2026, 9, 28),
        fin: DateTime(2026, 9, 29),
      );
      expect(interruptions, isNotEmpty);
      for (final InterruptionPriere interruption in interruptions) {
        expect(find.text(libellePriere(interruption.priere)), findsWidgets);
      }
    });
  });

  group('ENS-02 : A terminer (K-45)', () {
    testWidgets('trois cahiers au plus, une phrase qui aide, le point', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        enseignant: FauxServiceEnseignant()
          ..retardsRendus = <CahierEnRetard>[
            _cahier('a', 'Al-Badr', 26),
            _cahier('b', 'An-Nour', 24),
            _cahier('c', 'Al-Fatiha', 23),
            _cahier('d', 'Al-Ikhlas', 22),
          ],
      );
      expect(find.text(t.enseignant.journee.aTerminer), findsOneWidget);
      expect(find.text(t.enseignant.journee.aTerminerAide), findsOneWidget);
      expect(find.byType(PointRappel), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.cahierLigne(classe: 'Al-Badr')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.cahierLigne(classe: 'Al-Fatiha')),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.cahierLigne(classe: 'Al-Ikhlas')),
        findsNothing,
      );
    });

    testWidgets('la ligne mene au cahier de la seance', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantJournee,
          routes: _routes(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(t.enseignant.journee.cahierLigne(classe: 'Al-Badr')),
      );
      await tester.pumpAndSettle();
      expect(find.text('cahier:a'), findsOneWidget);
    });

    testWidgets('le point pulse quelques secondes, puis reste fixe', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey<String>('point-rappel-halo')), findsOne);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('point-rappel')), findsOne);
    });

    testWidgets('mouvement reduit : le point est fixe d emblee', (
      WidgetTester tester,
    ) async {
      _fenetre(tester, const Size(390, 2400));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        hote(
          const JourneePage(),
          surcharges: _surcharges(
            enseignant: FauxServiceEnseignant()
              ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey<String>('point-rappel-halo')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('point-rappel')), findsOne);
    });
  });

  group('ENS-02 : Alertes utiles', () {
    testWidgets('une absence pendant le cours se dit avec un prenom', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 40),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            _anNour(statut: StatutSeance.enCours),
          ],
        presence: FauxServicePresence(
          lignes: <PresenceParticipant>[
            _presence(etat: EtatPresence.presente, prenom: 'Yusuf'),
            _presence(
              etat: EtatPresence.absente,
              profilId: 'e2',
              prenom: 'Maryam',
            ),
          ],
        ),
      );
      expect(find.text(t.enseignant.journee.alertesUtiles), findsOneWidget);
      expect(
        find.text(t.enseignant.journee.absenceDetectee(eleve: 'Maryam')),
        findsOneWidget,
      );
    });

    testWidgets('une presence inconnue n est pas une alerte', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        maintenant: DateTime(2026, 9, 28, 17, 40),
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = <SeanceEnseignant>[
            _anNour(statut: StatutSeance.enCours),
          ],
      );
      expect(find.text(t.enseignant.journee.alertesUtiles), findsNothing);
    });
  });

  group('ENS-02 : une ou deux colonnes', () {
    Future<void> journeeComplete(WidgetTester tester, Size taille) => _ouvrir(
      tester,
      taille: taille,
      enseignant: FauxServiceEnseignant()
        ..seancesRendues = <SeanceEnseignant>[_anNour()]
        ..retardsRendus = <CahierEnRetard>[_cahier('a', 'Al-Badr', 26)],
    );

    testWidgets('bureau : A terminer a droite de la carte', (
      WidgetTester tester,
    ) async {
      await journeeComplete(tester, const Size(1440, 1000));
      final double xCarte = tester.getTopLeft(find.text('An-Nour')).dx;
      final double xCahiers = tester
          .getTopLeft(find.text(t.enseignant.journee.aTerminer))
          .dx;
      expect(xCahiers, greaterThan(xCarte + 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile : une colonne, A terminer sous Ma journee', (
      WidgetTester tester,
    ) async {
      await journeeComplete(tester, const Size(390, 2400));
      final double yJournee = tester
          .getTopLeft(find.text(t.enseignant.journee.maJournee))
          .dy;
      final double yCahiers = tester
          .getTopLeft(find.text(t.enseignant.journee.aTerminer))
          .dy;
      expect(yCahiers, greaterThan(yJournee));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 200 % de texte sur mobile, rien ne deborde', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await journeeComplete(tester, const Size(390, 2400));
      expect(tester.takeException(), isNull);
    });
  });
}
