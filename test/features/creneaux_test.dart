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
import 'package:rewayah_academy/features/creneaux/plages.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';

import '../support/harnais.dart';

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

/// Touche un texte, apres l'avoir rendu visible.
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

String _de(int h) => t.enseignant.creneaux.plageDe(heure: '$h');
String _a(int h) => t.enseignant.creneaux.plageA(heure: '$h');

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

    testWidgets('mobile : une ligne par plage, sans date (E15, DISPO-1)', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
          const Creneau(jour: 1, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning);

      // 17 h et 18 h se lisent « Lundi | de 17 h | a 19 h » (empilee a 390
      // avec la police de test).
      expect(find.text('Lundi'), findsOneWidget);
      expect(find.textContaining(_de(17)), findsOneWidget);
      expect(find.textContaining(_a(19)), findsOneWidget);
      // Plus de grille de cases a l'enseignant (directeur, 01/10).
      expect(find.byType(GrilleSemaine), findsNothing);
      expect(find.text(t.enseignant.creneaux.ajouterPlage), findsOneWidget);
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

  group('ENS-06 : les etats des plages (DISPO-1)', () {
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

    testWidgets('sauvegarde : la plage enregistree est NOMMEE', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();

      await _monter(tester, planning: planning);
      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(tester, find.text('Mardi'));
      await _toucher(tester, find.text(t.enseignant.creneaux.enregistrerPlage));

      // La soiree par defaut, 17 h a 23 h : six heures pleines.
      expect(planning.poses.length, 6);
      expect(planning.poses.first.creneau.jour, 2);
      expect(planning.poses.first.creneau.heure, 17);
      expect(
        find.text(
          t.enseignant.creneaux.plageEnregistree(
            jours: 'mardi',
            de: _de(17),
            a: _a(23),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('conflit : une heure qui porte un eleve se VOIT', (
      WidgetTester tester,
    ) async {
      // Le conflit se voit, il ne se bloque pas : retirer une disponibilite
      // n'annule aucun cours ; la suppression est confirmee et le dit.
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
        ]
        ..affectationsRendues = <Affectation>[_affectation(eleveId: 'x1')];

      await _monter(tester, planning: planning);

      // 1. Le conflit est visible AVANT le geste.
      expect(
        find.text(t.enseignant.creneaux.heureEngagee(heures: nommerHeure((jour: 4, heure: 9)))),
        findsOneWidget,
      );

      await _toucher(tester, find.text('Jeudi'));
      await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.confirmerRetraitAction),
      );

      // 2. Le geste passe, et la confirmation dit ce qu'il ne fait PAS.
      expect(planning.retires.length, 1);
      expect(planning.retires.single.creneau.heure, 9);
      expect(
        find.textContaining(
          t.enseignant.creneaux.seanceContinue(heures: nommerHeure((jour: 4, heure: 9))),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une plage libre retiree ne parle d aucune reaffectation', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning);
      await _toucher(tester, find.text('Mardi'));
      await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));

      expect(planning.retires.length, 1);
      expect(
        find.text(
          t.enseignant.creneaux.plageSupprimee(
            jour: 'mardi',
            de: _de(17),
            a: _a(18),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('offline : les plages restent lisibles mais rien ne s ouvre', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
        ];

      await _monter(tester, planning: planning, horsLigne: true);

      // Consultable : la plage et le compteur d'heures posees sont la.
      expect(find.text('Mardi'), findsOneWidget);
      expect(find.text(t.disponibilites.poseeUne), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.horsLigneGrille), findsOneWidget);
      // Et inerte : aucun ajout rendu, la plage ne s'ouvre pas.
      expect(find.text(t.enseignant.creneaux.ajouterPlage), findsNothing);
      await tester.tap(find.text('Mardi'));
      await tester.pumpAndSettle();
      expect(find.text(t.enseignant.creneaux.supprimerPlage), findsNothing);
      expect(planning.poses, isEmpty);
      expect(planning.retires, isEmpty);
    });
  });
}
