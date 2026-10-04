import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../capture/outil_capture.dart'
    show
        capturer,
        chargerPolicesDuDepot,
        fixerVueCapture,
        hoteCapture,
        sautSansCapture;
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

Affectation _affectation({
  required String eleveId,
  int jour = 4,
  int heure = 9,
  DateTime? closeLe,
}) => Affectation(
  id: 'a-$eleveId',
  enseignantId: _monId,
  enseignantPrenom: 'Omar',
  enseignantIdentifiant: 'TEACH-OS-000001',
  eleveId: eleveId,
  elevePrenom: 'Eleve $eleveId',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now(),
  closeLe: closeLe,
);

/// Les surcharges communes.
///
/// **Le reseau en fait partie.** Sans lui, `horsLigneProvider` retombe sur
/// `connectivity_plus`, dont le canal de plateforme n'existe pas sous
/// `flutter_test` : l'etat « hors ligne » de l'ecran serait alors decide par un
/// echec de plugin plutot que par la fixture.
List<Override> _surcharges({
  required FauxServiceMatching matching,
  required FauxServicePlanning planning,
  required FauxServiceRegles regles,
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  serviceMatchingProvider.overrideWithValue(matching),
  servicePlanningProvider.overrideWithValue(planning),
  serviceReglesProvider.overrideWithValue(regles),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
];

FauxServiceRegles _reglesAvecPlafond(int plafond) =>
    FauxServiceRegles()
      ..parProfil[_monId] = <RegleProfil>[
        RegleProfil(
          cle: CleRegle.plafondEleves,
          valeurEffective: plafond,
          valeurPlateforme: 5,
        ),
      ];

/// Mesure sur un telephone reel, jamais sur la surface par defaut.
///
/// `flutter_test` monte tout sur 800 x 600, c'est-a-dire au gabarit
/// **tablette**. Or `ENS-06` n'a d'onglets qu'au gabarit mobile : depuis le lot
/// R4, la tablette empile les deux panneaux et le desktop les met cote a cote
/// (`08-catalogue-ecrans.md` section 2). Ces tests mesurent le parcours
/// mobile -- prendre un eleve depuis l'onglet -- et cherchaient donc un onglet
/// qui n'existe plus a 800 de large. Ils le disent maintenant.
///
/// 390 x 844, et non une hauteur inventee : c'est le gabarit de reference du
/// produit. Une mesure faite sur une fenetre plus haute que les telephones
/// reels cache les depassements au lieu de les montrer.
void _telephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _monter(
  WidgetTester tester, {
  FauxServiceMatching? matching,
  FauxServicePlanning? planning,
  FauxServiceRegles? regles,
  bool horsLigne = false,
  List<Override> extra = const <Override>[],
}) async {
  _telephone(tester);
  await tester.pumpWidget(
    hote(
      const CreneauxPage(),
      surcharges: <Override>[
        ..._surcharges(
          matching: matching ?? FauxServiceMatching(),
          planning: planning ?? FauxServicePlanning(),
          regles: regles ?? _reglesAvecPlafond(5),
          horsLigne: horsLigne,
        ),
        ...extra,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Tape une case de la grille par son libelle parle.
///
/// La grille n'expose aucune cle : la seule prise stable sur une case donnee
/// est le libelle semantique que `ENS-06` doit de toute facon porter (fiche
/// `ENS-06`, section Accessibilite). Le mesurer ici verifie les deux choses a
/// la fois.
Future<void> _taperCase(WidgetTester tester, {required String libelle}) async {
  // Sur mobile, des plages deja posees se lisent en liste : la grille s'ouvre
  // par « Ajouter un creneau » (EN-5).
  final Finder ajouter = find.text(t.enseignant.creneaux.ajouterCreneau);
  if (ajouter.evaluate().isNotEmpty) {
    await tester.ensureVisible(ajouter);
    await tester.tap(ajouter);
    await tester.pumpAndSettle();
  }
  final Finder cellule = find.bySemanticsLabel(libelle);
  expect(cellule, findsOneWidget, reason: 'case introuvable : $libelle');
  await tester.ensureVisible(cellule);
  await tester.pumpAndSettle();
  await tester.tap(cellule);
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-06 Disponibilites : l ancien modele est retire (EN-5)', () {
    testWidgets('le titre concorde avec la destination de la coquille', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      expect(find.text(t.nav.enseignant.creneaux), findsWidgets);
      expect(find.text(t.enseignant.creneaux.mesDisponibilites), findsNothing);
    });

    testWidgets('ni onglet « Eleves en attente », ni « Prendre… » (E1)', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      expect(find.byType(TabBar), findsNothing);
      expect(find.text(t.creneaux.ongletEleves), findsNothing);
      expect(find.textContaining('Prendre'), findsNothing);
    });

    testWidgets('mobile : la liste par jour, sans date (E15)', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
          const Creneau(jour: 1, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning);

      expect(find.text('Lundi'), findsOneWidget);
      expect(find.text('17 h, 18 h'), findsOneWidget);
      // La grille attend « Ajouter un creneau ».
      expect(find.text(t.disponibilites.titreEnseignant), findsNothing);
      await tester.tap(find.text(t.enseignant.creneaux.ajouterCreneau));
      await tester.pumpAndSettle();
      expect(find.text(t.disponibilites.titreEnseignant), findsOneWidget);
    });

    testWidgets('sans offres branchees, aucune section Classes (BR-1)', (
      WidgetTester tester,
    ) async {
      await _monter(tester);

      expect(find.text(t.enseignant.creneaux.classesDisponibles), findsNothing);
    });
  });

  group('ENS-06 Classes disponibles et ENS-06B', () {
    testWidgets('les trois etats sont ECRITS', (WidgetTester tester) async {
      await _monter(
        tester,
        extra: <Override>[
          offresClassesProvider.overrideWithValue(DonneesEnseignantDemo.offres),
        ],
      );

      expect(
        find.text(t.enseignant.creneaux.classesDisponibles),
        findsOneWidget,
      );
      // E2 : seule l'exception porte une pastille.
      expect(find.text(t.enseignant.creneaux.etatDisponible), findsNothing);
      expect(find.text(t.enseignant.creneaux.etatEnAttente), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.etatLimite), findsOneWidget);
      expect(
        find.textContaining(t.enseignant.creneaux.limiteDetail),
        findsOneWidget,
      );
    });

    testWidgets('aucune offre : le texte vide du document §15.7', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        extra: <Override>[
          offresClassesProvider.overrideWithValue(const <OffreClasseDemo>[]),
        ],
      );

      expect(find.text(t.enseignant.creneaux.aucuneClasse), findsOneWidget);
      expect(
        find.text(t.enseignant.creneaux.aucuneClasseDetail),
        findsOneWidget,
      );
    });

    testWidgets('detail, confirmation, puis succes honnete (E7)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        extra: <Override>[
          offresClassesProvider.overrideWithValue(DonneesEnseignantDemo.offres),
        ],
      );

      final Finder carte = find.text('Ar-Rahma');
      await tester.ensureVisible(carte);
      await tester.tap(carte);
      await tester.pumpAndSettle();

      // Tout le rendez-vous est lu avant de s'engager (doc 04 §16.2).
      expect(find.text('Mercredi, Vendredi'), findsOneWidget);

      final Finder reserver = find.text(t.enseignant.creneaux.reserver);
      await tester.ensureVisible(reserver);
      await tester.tap(reserver);
      await tester.pumpAndSettle();

      expect(find.text(t.enseignant.creneaux.confirmerTitre), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.revenir), findsOneWidget);

      // « Revenir » ne reserve rien.
      await tester.tap(find.text(t.enseignant.creneaux.revenir));
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.demo.mention), findsNothing);

      await tester.tap(find.text(t.enseignant.creneaux.reserver));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.enseignant.creneaux.confirmer));
      await tester.pumpAndSettle();

      // La demonstration ne pretend aucun envoi reel.
      expect(find.text(t.enseignant.demo.mention), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.reserver), findsNothing);
      expect(find.text(t.enseignant.creneaux.etatEnAttente), findsOneWidget);
    });
  });

  group('ENS-06 : les etats de la grille', () {
    testWidgets('loading : aucune heure avant que le fuseau ait repondu', (
      WidgetTester tester,
    ) async {
      // La grille se repliait sur 'Europe/Paris' code en dur : un enseignant de
      // Conakry lisait ses heures en heure de Paris, puis les voyait changer.
      final Completer<String> jamais = Completer<String>();

      await _monter(
        tester,
        extra: <Override>[monFuseauProvider.overrideWith((_) => jamais.future)],
      );

      expect(find.byType(Skeleton), findsWidgets);
      expect(
        find.text(t.disponibilites.fuseau(fuseau: 'Europe/Paris')),
        findsNothing,
        reason: 'un fuseau de repli affiche est un fuseau faux',
      );
    });

    testWidgets('error : la grille dit son echec et propose la relecture', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        extra: <Override>[
          monFuseauProvider.overrideWith((_) async => throw StateError('fix')),
        ],
      );

      expect(find.text(t.enseignant.creneaux.grilleErreur), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
    });

    testWidgets('empty : aucune heure posee se dit, et dit sa consequence', (
      WidgetTester tester,
    ) async {
      // Une grille vide pendant le chargement etait identique a une grille sans
      // aucune heure posee : les deux ne disaient rien.
      await _monter(tester);

      expect(find.text(t.enseignant.creneaux.aucuneHeure), findsOneWidget);
    });

    testWidgets('sauvegarde : la case enregistree est NOMMEE', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();

      await _monter(tester, planning: planning);
      await _taperCase(
        tester,
        libelle: t.disponibilites.celluleLibre(jour: 'mardi', heure: '17'),
      );

      expect(planning.poses.length, 1);
      expect(planning.poses.single.creneau.jour, 2);
      expect(planning.poses.single.creneau.heure, 17);
      // `enCours` figeait la grille sans jamais dire qu'une case etait passee.
      expect(
        find.text(t.enseignant.creneaux.heureEnregistree(heure: 'mardi 17 h')),
        findsOneWidget,
      );
    });

    testWidgets('conflit : une heure qui porte un eleve se VOIT', (
      WidgetTester tester,
    ) async {
      // Sans ce calcul, la case d'une heure engagee est indiscernable d'une
      // case libre. Le conflit se voit, il ne se bloque pas : retirer une
      // disponibilite n'annule aucun cours, et refuser le geste serait une
      // regle metier qu'aucun document du depot ne pose.
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
        ]
        ..affectationsRendues = <Affectation>[_affectation(eleveId: 'x1')];

      await _monter(tester, planning: planning);

      // 1. Le conflit est visible AVANT le geste.
      expect(
        find.text(t.enseignant.creneaux.heureEngagee(heures: 'jeudi 9 h')),
        findsOneWidget,
      );

      await _taperCase(
        tester,
        libelle: t.disponibilites.cellulePosee(jour: 'jeudi', heure: '9'),
      );

      // 2. Le geste passe, et la confirmation dit ce qu'il ne fait PAS.
      expect(planning.retires.length, 1);
      expect(planning.retires.single.creneau.heure, 9);
      expect(
        find.text(t.enseignant.creneaux.retraitEngage(heure: 'jeudi 9 h')),
        findsOneWidget,
      );
    });

    testWidgets('une heure libre retiree ne parle d aucune reaffectation', (
      WidgetTester tester,
    ) async {
      // Le pendant du test ci-dessus : sans eleve sur l'heure, la confirmation
      // reste courte. Une phrase de reaffectation partout serait du bruit.
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning);
      await _taperCase(
        tester,
        libelle: t.disponibilites.cellulePosee(jour: 'mardi', heure: '17'),
      );

      expect(planning.retires.length, 1);
      expect(
        find.text(t.enseignant.creneaux.heureRetiree(heure: 'mardi 17 h')),
        findsOneWidget,
      );
    });

    testWidgets('offline : la grille reste lisible mais n accepte rien', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning, horsLigne: true);

      // Consultable : le compteur d'heures posees est la.
      expect(find.text(t.disponibilites.poseeUne), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.horsLigneGrille), findsOneWidget);
      // EA-HL-DOUBLE-1 (reprise) : la note dit ce qui ne peut pas se faire ;
      // le bandeau seul dit « hors ligne ».
      expectHorsLigneUneFois();
      // Et inerte : la case n'expose plus de libelle pressable.
      expect(
        find.bySemanticsLabel(
          t.disponibilites.cellulePosee(jour: 'mardi', heure: '17'),
        ),
        findsNothing,
      );
      expect(planning.poses, isEmpty);
      expect(planning.retires, isEmpty);
    });
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve, hors ligne, la note dit
  // ce qui ne peut pas se faire, le bandeau seul dit le reseau. Sautees sans
  // CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String, Size, ThemeMode, double, InterfaceMode) cas
        in <(String, Size, ThemeMode, double, InterfaceMode)>[
          (
            '390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            InterfaceMode.standard,
          ),
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
            InterfaceMode.standard,
          ),
          (
            '320x2_clair',
            const Size(320, 900),
            ThemeMode.light,
            2,
            InterfaceMode.standard,
          ),
          (
            '1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            1,
            InterfaceMode.standard,
          ),
          (
            '390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            1,
            InterfaceMode.enfant,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        final FauxServicePlanning planning = FauxServicePlanning()
          ..creneaux[_monId] = <Creneau>[
            const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
          ];
        await tester.pumpWidget(
          hoteCapture(
            const CreneauxPage(),
            surcharges: _surcharges(
              matching: FauxServiceMatching(),
              planning: planning,
              regles: _reglesAvecPlafond(5),
              horsLigne: true,
            ),
            themeMode: cas.$3,
            echelleTexte: cas.$4,
            interfaceMode: cas.$5,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(t.enseignant.creneaux.horsLigneGrille),
          findsOneWidget,
        );
        expectHorsLigneUneFois();
        debugPrint(
          'PNG ${await capturer(tester, 'ea_hl_double1_creneaux_${cas.$1}')}',
        );
      });
    }
  });
}
