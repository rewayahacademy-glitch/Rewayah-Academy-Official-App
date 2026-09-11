import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';

import '../support/harnais.dart';

const String _monId = 't1';

const SessionState _sessionEnseignant = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

EleveEnAttente _eleve({
  String id = 'e1',
  String prenom = 'Khadija',
  int jours = 0,
  int jour = 2,
  int heure = 17,
}) => EleveEnAttente(
  eleveId: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-KB-000003',
  creneau: Creneau(jour: jour, heure: heure, fuseau: 'Europe/Paris'),
  depuis: DateTime.now().subtract(Duration(days: jours)),
  mode: InterfaceMode.enfant,
  niveau: 'debutant',
);

List<Override> _surcharges({
  required FauxServiceMatching matching,
  required FauxServicePlanning planning,
  required FauxServiceRegles regles,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(_sessionEnseignant),
  ),
  serviceMatchingProvider.overrideWithValue(matching),
  servicePlanningProvider.overrideWithValue(planning),
  serviceReglesProvider.overrideWithValue(regles),
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
/// (`08-catalogue-ecrans.md` section 2). Ces six tests mesurent le parcours
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

Future<void> _ouvrirOngletEleves(WidgetTester tester) async {
  await tester.tap(find.text(t.creneaux.ongletEleves));
  await tester.pumpAndSettle();
}

void main() {
  group('ENS-06 : ce qui se prend est un eleve, pas un creneau', () {
    testWidgets('sous le plafond, le bouton prend l eleve sur son creneau', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()];
      final FauxServicePlanning planning = FauxServicePlanning();
      final FauxServiceRegles regles = _reglesAvecPlafond(5);

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: planning,
            regles: regles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      final Finder bouton = find.text(
        t.creneaux.prendre(jour: 'mardi', heure: '17'),
      );
      expect(bouton, findsOneWidget);

      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(matching.prises.length, 1);
      expect(matching.prises.single.eleveId, 'e1');
      expect(matching.prises.single.creneau.jour, 2);
      expect(matching.prises.single.creneau.heure, 17);
    });

    testWidgets('au plafond, le bouton n existe pas, une phrase le remplace', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()];
      final FauxServicePlanning planning = FauxServicePlanning()
        ..affectationsRendues = <Affectation>[
          for (int i = 0; i < 5; i++)
            Affectation(
              id: 'a$i',
              enseignantId: _monId,
              enseignantPrenom: 'Omar',
              enseignantIdentifiant: 'TEACH-OS-000001',
              eleveId: 'x$i',
              elevePrenom: 'Eleve $i',
              creneau: const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
              depuis: DateTime.now(),
            ),
        ];
      final FauxServiceRegles regles = _reglesAvecPlafond(5);

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: planning,
            regles: regles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      // Un bouton qui echoue apres le geste coute plus cher qu'un bouton
      // absent : la limite s'explique, elle ne se heurte pas.
      expect(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        findsNothing,
      );
      expect(find.text(t.creneaux.plafondAtteint(nombre: '5')), findsOneWidget);
      expect(find.text(t.creneaux.plafondDemander), findsOneWidget);
      // L'eleve reste visible : l'enseignant doit pouvoir constater qui attend
      // avant de demander a en suivre plus.
      expect(find.text('Khadija'), findsOneWidget);
    });

    testWidgets('un plafond surcharge deverrouille le bouton', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()];
      final FauxServicePlanning planning = FauxServicePlanning()
        ..affectationsRendues = <Affectation>[
          for (int i = 0; i < 5; i++)
            Affectation(
              id: 'a$i',
              enseignantId: _monId,
              enseignantPrenom: 'Omar',
              enseignantIdentifiant: 'TEACH-OS-000001',
              eleveId: 'x$i',
              elevePrenom: 'Eleve $i',
              creneau: const Creneau(jour: 4, heure: 9, fuseau: 'Europe/Paris'),
              depuis: DateTime.now(),
            ),
        ];
      // La meme situation, avec la regle de CET enseignant portee a 6.
      final FauxServiceRegles regles = _reglesAvecPlafond(6);

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: planning,
            regles: regles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      expect(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
        findsOneWidget,
      );
      expect(
        find.text(t.creneaux.mesEleves(nombre: '5', plafond: '6')),
        findsOneWidget,
      );
    });

    testWidgets('un refus de la base se lit tel quel', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[_eleve()]
        ..erreurPrise = StateError(
          'cet eleve vient d etre pris par un autre enseignant',
        );
      final FauxServicePlanning planning = FauxServicePlanning();
      final FauxServiceRegles regles = _reglesAvecPlafond(5);

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: planning,
            regles: regles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      await tester.tap(
        find.text(t.creneaux.prendre(jour: 'mardi', heure: '17')),
      );
      await tester.pumpAndSettle();

      // La base tranche, pas l'ecran : le perdant d'une prise simultanee lit
      // une phrase, pas un code d'erreur.
      expect(
        find.textContaining('pris par un autre enseignant'),
        findsOneWidget,
      );
    });

    testWidgets('l attente est datee, et signalee au-dela de trois jours', (
      WidgetTester tester,
    ) async {
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[
          _eleve(jours: 0),
          _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1, jour: 3),
          _eleve(id: 'e3', prenom: 'Fatou', jours: 6, jour: 4),
        ];
      final FauxServicePlanning planning = FauxServicePlanning();
      final FauxServiceRegles regles = _reglesAvecPlafond(5);

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: planning,
            regles: regles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      expect(find.text(t.creneaux.attendAujourdhui), findsOneWidget);
      expect(find.text(t.creneaux.attendUnJour), findsOneWidget);
      expect(find.text(t.creneaux.attendDepuis(jours: '6')), findsOneWidget);
    });

    test('parAnciennete rend la plus longue attente en premier', () {
      final List<EleveEnAttente> range = parAnciennete(<EleveEnAttente>[
        _eleve(jours: 0),
        _eleve(id: 'e3', prenom: 'Fatou', jours: 6),
        _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1),
      ]);

      expect(range.map((EleveEnAttente e) => e.prenom).toList(), <String>[
        'Fatou',
        'Ibrahim',
        'Khadija',
      ]);
    });

    testWidgets('la famille qui attend le plus longtemps est en haut', (
      WidgetTester tester,
    ) async {
      // Le feed arrive volontairement dans le desordre. L'ordre appartient a
      // l'ecran : il vivait dans le seul `.order()` de la lecture, dont le sens
      // par defaut est DESCENDANT, ce qui enfoncait au bas de la liste la
      // famille qui attend depuis le plus longtemps, c'est-a-dire exactement
      // celle que ce tri existe pour faire remonter.
      final FauxServiceMatching matching = FauxServiceMatching()
        ..feed = <EleveEnAttente>[
          _eleve(jours: 0),
          _eleve(id: 'e3', prenom: 'Fatou', jours: 6, jour: 4),
          _eleve(id: 'e2', prenom: 'Ibrahim', jours: 1, jour: 3),
        ];

      _telephone(tester);
      await tester.pumpWidget(
        hote(
          const CreneauxPage(),
          surcharges: _surcharges(
            matching: matching,
            planning: FauxServicePlanning(),
            regles: _reglesAvecPlafond(5),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _ouvrirOngletEleves(tester);

      final double yFatou = tester.getTopLeft(find.text('Fatou')).dy;
      final double yIbrahim = tester.getTopLeft(find.text('Ibrahim')).dy;
      final double yKhadija = tester.getTopLeft(find.text('Khadija')).dy;

      expect(yFatou, lessThan(yIbrahim));
      expect(yIbrahim, lessThan(yKhadija));
    });

    testWidgets(
      'des la tablette, chaque panneau porte le nom de son onglet',
      (WidgetTester tester) async {
        // Le lot R4 a supprime les onglets au-dela de 600 et laisse leurs deux
        // libelles dans le seul `TabBar` mobile : le feed s'est retrouve sans
        // titre sur tablette comme sur desktop. Les six tests ci-dessus ne
        // pouvaient pas le voir, ils mesurent le gabarit mobile.
        for (final double largeur in <double>[768, 1440]) {
          tester.view.physicalSize = Size(largeur, 2000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            hote(
              const CreneauxPage(),
              surcharges: _surcharges(
                matching: FauxServiceMatching()..feed = <EleveEnAttente>[
                  _eleve(),
                ],
                planning: FauxServicePlanning(),
                regles: _reglesAvecPlafond(5),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(t.creneaux.ongletHeures),
            findsOneWidget,
            reason: 'panneau des heures sans titre a $largeur',
          );
          expect(
            find.text(t.creneaux.ongletEleves),
            findsOneWidget,
            reason: 'panneau des eleves sans titre a $largeur',
          );
        }
      },
    );
  });
}
