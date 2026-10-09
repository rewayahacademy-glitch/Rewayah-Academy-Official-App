// DISPO-1 (directeur, 01/10 23:16) : les disponibilites de l'enseignant se
// lisent et se saisissent par plages « Lundi | de 17 h | a 23 h », plus par
// une grille de cases jour x heure.
//
// Tout part du vrai ecran `CreneauxPage` et passe par de vrais gestes ; les
// ecritures sont lues sur le `FauxServicePlanning` (heure par heure, comme
// `weekly_availability` les stocke).
//
// Contre-epreuve : ce fichier echoue sur l'ancien `creneaux_page.dart`
// (liste par jour « 17 h, 18 h » et `GrilleSemaine`) : ni ligne « de 17 h »,
// ni « Ajouter une plage ».

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/creneaux/feuille_plage.dart';
import 'package:rewayah_academy/features/creneaux/plages.dart';
import 'package:rewayah_academy/features/creneaux/plages_disponibilite.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';

import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const String _monId = 't1';
const String _fuseau = 'Europe/Paris';

const SessionState _session = SessionState(
  resolue: true,
  role: AppRole.teacher,
  profileId: _monId,
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

String _de(int h) => t.enseignant.creneaux.plageDe(heure: '$h');
String _a(int h) => t.enseignant.creneaux.plageA(heure: '$h');

List<Creneau> _plage(int jour, int de, int a) => <Creneau>[
  for (int h = de; h < a; h++) Creneau(jour: jour, heure: h, fuseau: _fuseau),
];

/// Un planning qui refuse certaines heures : l'echec PARTIEL.
class _PlanningCapricieux extends FauxServicePlanning {
  final Set<int> refusees = <int>{};

  @override
  Future<void> poser({
    required String profilId,
    required Creneau creneau,
  }) async {
    if (refusees.contains(creneau.heure)) {
      throw StateError('refus ${creneau.heure}');
    }
    return super.poser(profilId: profilId, creneau: creneau);
  }
}

Affectation _affectation({required int jour, required int heure}) =>
    Affectation(
      id: 'a-$jour-$heure',
      enseignantId: _monId,
      enseignantPrenom: 'Omar',
      enseignantIdentifiant: 'TEACH-OS-000001',
      eleveId: 'e1',
      elevePrenom: 'Yasmine',
      creneau: Creneau(jour: jour, heure: heure, fuseau: _fuseau),
      depuis: DateTime(2026, 9),
    );

Widget _hote(
  FauxServicePlanning planning, {
  bool horsLigne = false,
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
}) => ProviderScope(
  overrides: <Override>[
    sourceSessionProvider.overrideWithValue(FausseSourceSession(_session)),
    serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
    servicePlanningProvider.overrideWithValue(planning),
    serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
    serviceReseauProvider.overrideWithValue(
      FauxServiceReseau(horsLigneRendu: horsLigne),
    ),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: theme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(echelle)),
        child: app!,
      ),
      home: const CreneauxPage(),
    ),
  ),
);

Future<void> _monter(
  WidgetTester tester,
  FauxServicePlanning planning, {
  // 800 de large : la police de test (Ahem, un carre par lettre) est bien
  // plus large que la vraie ; a 390 les trois colonnes s'y empilent. Le
  // telephone reel est mesure par les captures et les gardes a 320.
  Size vue = const Size(800, 1000),
  bool horsLigne = false,
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
}) async {
  tester.view.physicalSize = vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _hote(planning, horsLigne: horsLigne, theme: theme, echelle: echelle),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// La ligne d'une plage : la ligne pressable du groupe qui porte le jour,
/// « de » et « a » (en colonnes ou empilee).
Finder _ligne(String jour, int de, int a) {
  bool porte(Element e, String texte) => find
      .descendant(
        of: find.byElementPredicate((Element x) => identical(x, e)),
        matching: find.textContaining(texte),
      )
      .evaluate()
      .isNotEmpty;
  return find.byElementPredicate(
    (Element e) =>
        e.widget is Pressable &&
        e.findAncestorWidgetOfExactType<GroupeReglages>() != null &&
        porte(e, jour) &&
        porte(e, _de(de)) &&
        porte(e, _a(a)),
  );
}

Finder get _feuille => find.byType(FeuillePlage);

Finder _dansFeuille(String texte) =>
    find.descendant(of: _feuille, matching: find.text(texte));

/// Choisit une heure dans un menu de la feuille (« de » ou « a »).
Future<void> _choisir(
  WidgetTester tester, {
  required String courant,
  required String voulu,
}) async {
  await _toucher(tester, _dansFeuille(courant));
  await _toucher(tester, find.text(voulu).last);
}

void main() {
  group('DISPO-1 : la liste des plages', () {
    testWidgets('les heures consecutives se lisent en plages, une par ligne', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = <Creneau>[
          ..._plage(1, 17, 23),
          ..._plage(1, 8, 9),
          ..._plage(2, 9, 11),
        ];
      await _monter(tester, planning);

      // Trois lignes, triees par jour puis par debut.
      expect(_ligne('Lundi', 8, 9), findsOneWidget);
      expect(_ligne('Lundi', 17, 23), findsOneWidget);
      expect(_ligne('Mardi', 9, 11), findsOneWidget);
      expect(find.text(_de(17)), findsOneWidget);
      expect(find.text(_a(23)), findsOneWidget);
      // La grille de cases n'est plus rendue a l'enseignant.
      expect(find.byType(GrilleSemaine), findsNothing);
      // Trois colonnes alignees : « de » commence au meme bord sur chaque
      // ligne, « a » aussi, quel que soit le jour.
      expect(
        tester.getTopLeft(find.text(_de(17))).dx,
        tester.getTopLeft(find.text(_de(9))).dx,
      );
      expect(
        tester.getTopLeft(find.text(_a(23))).dx,
        tester.getTopLeft(find.text(_a(11))).dx,
      );
      expect(
        tester.getTopLeft(find.text('Lundi').first).dx,
        tester.getTopLeft(find.text('Mardi')).dx,
      );
      verifierSansChevauchement(tester, <Finder>[
        find.text('Mardi'),
        find.text(_de(9)),
        find.text(_a(11)),
      ]);
    });

    testWidgets('une plage qui finit a minuit le dit', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(5, 22, 24);
      await _monter(tester, planning);

      expect(find.text(t.enseignant.creneaux.plageAMinuit), findsOneWidget);
    });

    testWidgets('empty : aucune plage se dit, et l ajout reste la', (
      WidgetTester tester,
    ) async {
      await _monter(tester, FauxServicePlanning());

      expect(find.text(t.enseignant.creneaux.aucuneHeure), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.ajouterPlage), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('le conflit avec une Classe est ECRIT sur la plage', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(4, 9, 11)
        ..affectationsRendues = <Affectation>[_affectation(jour: 4, heure: 9)];
      await _monter(tester, planning);

      expect(
        find.text(t.enseignant.creneaux.plageEngagee(heures: nommerHeure((jour: 4, heure: 9)))),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.creneaux.heureEngagee(heures: nommerHeure((jour: 4, heure: 9)))),
        findsOneWidget,
      );
    });

    testWidgets('offline : la liste se lit, rien ne s ouvre', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(2, 17, 19);
      await _monter(tester, planning, horsLigne: true);

      expect(find.text(_de(17)), findsOneWidget);
      expect(find.text(t.enseignant.creneaux.horsLigneGrille), findsOneWidget);
      // Le bouton n'est pas grise : il n'est pas rendu.
      expect(find.text(t.enseignant.creneaux.ajouterPlage), findsNothing);
      await tester.tap(find.text(_de(17)));
      await tester.pumpAndSettle();
      expect(_feuille, findsNothing);
    });
  });

  group('DISPO-1 : la feuille « Ajouter une plage »', () {
    testWidgets('jours en puces, de et a dans deux listes, puis poser', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      expect(_feuille, findsOneWidget);
      expect(
        find.text(t.enseignant.creneaux.feuilleAjouterTitre),
        findsOneWidget,
      );
      // Aucune saisie au clavier.
      expect(
        find.descendant(of: _feuille, matching: find.byType(TextField)),
        findsNothing,
      );

      await _toucher(tester, _dansFeuille('Lundi'));
      await _toucher(tester, _dansFeuille('Mercredi'));
      // Prerempli sur la soiree (17 h a 23 h) : on choisit 18 h a 21 h.
      await _choisir(tester, courant: _de(17), voulu: _de(18));
      await _toucher(tester, _dansFeuille(_a(23)));
      // « a » est strictement apres « de » : 18 h n'est pas proposee.
      expect(find.text(_a(18)), findsNothing);
      expect(find.text(_a(19)), findsWidgets);
      await _toucher(tester, find.text(_a(21)).last);

      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(
        planning.poses
            .map((({String profilId, Creneau creneau}) p) =>
                (p.creneau.jour, p.creneau.heure))
            .toList(),
        <(int, int)>[(1, 18), (1, 19), (1, 20), (3, 18), (3, 19), (3, 20)],
      );
      expect(planning.retires, isEmpty);
      expect(_feuille, findsNothing);
      expect(
        find.text(
          t.enseignant.creneaux.plageEnregistree(
            jours: 'lundi, mercredi',
            de: _de(18),
            a: _a(21),
          ),
        ),
        findsOneWidget,
      );
      // La liste relue montre les deux plages.
      expect(_ligne('Lundi', 18, 21), findsOneWidget);
      expect(_ligne('Mercredi', 18, 21), findsOneWidget);
    });

    testWidgets('raccourcis : Matinee 8 h-12 h et Week-end', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(
        tester,
        _dansFeuille(t.enseignant.creneaux.raccourciMatinee),
      );
      await _toucher(
        tester,
        _dansFeuille(t.enseignant.creneaux.raccourciWeekEnd),
      );
      // Les listes suivent le raccourci.
      expect(_dansFeuille(_de(8)), findsOneWidget);
      expect(_dansFeuille(_a(12)), findsOneWidget);
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(planning.poses.length, 8);
      expect(
        planning.poses
            .map((({String profilId, Creneau creneau}) p) => p.creneau.jour)
            .toSet(),
        <int>{6, 7},
      );
      expect(
        planning.poses
            .map((({String profilId, Creneau creneau}) p) => p.creneau.heure)
            .toSet(),
        <int>{8, 9, 10, 11},
      );
    });

    testWidgets('sans jour choisi, rien ne part et la feuille le dit', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning();
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(planning.poses, isEmpty);
      expect(find.text(t.enseignant.creneaux.manqueJour), findsOneWidget);
      expect(_feuille, findsOneWidget);
    });

    testWidgets('chevauchement : fusion dite AVANT, seules les heures '
        'manquantes partent', (WidgetTester tester) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(1, 17, 20);
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(tester, _dansFeuille('Lundi'));
      final String fusion = t.enseignant.creneaux.fusion(
        jour: 'Lundi',
        de: _de(17),
        a: _a(23),
      );
      // 17 h a 23 h sur 17 h a 20 h : deja dit, avant tout envoi.
      expect(find.text(fusion), findsOneWidget);
      await _choisir(tester, courant: _de(17), voulu: _de(19));
      expect(find.text(fusion), findsOneWidget);
      expect(planning.poses, isEmpty);

      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(
        planning.poses
            .map((({String profilId, Creneau creneau}) p) => p.creneau.heure)
            .toList(),
        <int>[20, 21, 22],
      );
      // Une seule plage reunie.
      expect(_ligne('Lundi', 17, 23), findsOneWidget);
      expect(find.text(_de(19)), findsNothing);
    });

    testWidgets('echec partiel : les heures non confirmees sont nommees, '
        'un second envoi ne renvoie qu elles', (WidgetTester tester) async {
      final _PlanningCapricieux planning = _PlanningCapricieux()
        ..refusees.add(21);
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(tester, _dansFeuille('Lundi'));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(planning.poses.length, 5);
      expect(
        find.text(t.enseignant.creneaux.echecPartiel(heures: nommerHeure((jour: 1, heure: 21)))),
        findsOneWidget,
      );
      // La feuille reste ouverte ; la liste derriere montre ce qui est passe.
      expect(_feuille, findsOneWidget);

      planning.refusees.clear();
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );
      expect(planning.poses.length, 6);
      expect(planning.poses.last.creneau.heure, 21);
      expect(_feuille, findsNothing);
      expect(_ligne('Lundi', 17, 23), findsOneWidget);
    });

    testWidgets('echec total : non confirme, cause et quoi faire', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, planning);

      await _toucher(tester, find.text(t.enseignant.creneaux.ajouterPlage));
      await _toucher(tester, _dansFeuille('Mardi'));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(find.text(t.enseignant.creneaux.echecTotal), findsOneWidget);
      expect(_feuille, findsOneWidget);
    });
  });

  group('DISPO-1 : toucher une plage pour la modifier ou la supprimer', () {
    testWidgets('modifier : la feuille est preremplie, seules les heures '
        'retirees partent', (WidgetTester tester) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(1, 17, 23);
      await _monter(tester, planning);

      await _toucher(tester, _ligne('Lundi', 17, 23));
      expect(
        find.text(t.enseignant.creneaux.feuilleModifierTitre(jour: 'lundi')),
        findsOneWidget,
      );
      expect(_dansFeuille(_de(17)), findsOneWidget);
      expect(_dansFeuille(_a(23)), findsOneWidget);

      await _choisir(tester, courant: _a(23), voulu: _a(21));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.enregistrerPlage),
      );

      expect(planning.poses, isEmpty);
      expect(
        planning.retires
            .map((({String profilId, Creneau creneau}) p) => p.creneau.heure)
            .toList(),
        <int>[21, 22],
      );
      expect(_ligne('Lundi', 17, 21), findsOneWidget);
    });

    testWidgets('supprimer une plage libre : sans confirmation', (
      WidgetTester tester,
    ) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(2, 17, 20);
      await _monter(tester, planning);

      await _toucher(tester, _ligne('Mardi', 17, 20));
      await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));

      expect(planning.retires.length, 3);
      expect(
        find.text(
          t.enseignant.creneaux.plageSupprimee(
            jour: 'mardi',
            de: _de(17),
            a: _a(20),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.creneaux.aucuneHeure), findsOneWidget);
    });

    testWidgets('supprimer une plage engagee : confirmee, et retirer '
        'n annule aucun cours', (WidgetTester tester) async {
      final FauxServicePlanning planning = FauxServicePlanning()
        ..creneaux[_monId] = _plage(4, 9, 10)
        ..affectationsRendues = <Affectation>[_affectation(jour: 4, heure: 9)];
      await _monter(tester, planning);

      await _toucher(tester, _ligne('Jeudi', 9, 10));
      await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));

      // La confirmation dit la consequence ; renoncer ne retire rien.
      expect(
        find.text(
          t.enseignant.creneaux.confirmerRetraitConsequence(heures: nommerHeure((jour: 4, heure: 9))),
        ),
        findsOneWidget,
      );
      await _toucher(tester, find.text(t.commun.annuler));
      expect(planning.retires, isEmpty);

      await _toucher(tester, find.text(t.enseignant.creneaux.supprimerPlage));
      await _toucher(
        tester,
        find.text(t.enseignant.creneaux.confirmerRetraitAction),
      );

      expect(planning.retires.length, 1);
      expect(
        find.textContaining(
          t.enseignant.creneaux.seanceContinue(heures: nommerHeure((jour: 4, heure: 9))),
        ),
        findsOneWidget,
      );
    });
  });

  group('DISPO-1 : gardes de rendu', () {
    for (final (Size vue, String nom) in <(Size, String)>[
      (const Size(320, 800), '320'),
      (const Size(1440, 900), '1440'),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('$nom x${echelle.toInt()} ${theme.name} : liste et '
              'feuille lisibles, un seul bouton plein', (
            WidgetTester tester,
          ) async {
            final FauxServicePlanning planning = FauxServicePlanning()
              ..creneaux[_monId] = <Creneau>[
                ..._plage(3, 17, 23),
                ..._plage(7, 8, 12),
              ];
            await _monter(
              tester,
              planning,
              vue: echelle == 2 && nom == '320' ? const Size(320, 1400) : vue,
              theme: theme,
              echelle: echelle,
            );

            expect(tester.takeException(), isNull);
            // Un mot compose (« pouvez-vous ») peut passer a la ligne apres
            // son trait d'union, chaque partie entiere (police de test, plus
            // large que la vraie) ; aucun autre mot ne se coupe.
            expect(
              motsCoupes(
                tester,
                find.byType(PlagesDisponibilite),
                traitDUnionPermis: true,
              ),
              isEmpty,
            );
            verifierUnSeulBoutonPlein(tester);
            verifierSansChevauchement(tester, <Finder>[
              find.text('Mercredi'),
              find.textContaining(_de(17)),
              find.text(t.enseignant.creneaux.ajouterPlage),
            ]);

            await _toucher(tester, _ligne('Mercredi', 17, 23));
            expect(tester.takeException(), isNull);
            expect(_feuille, findsOneWidget);
            expect(
              motsCoupes(tester, _feuille, traitDUnionPermis: true),
              isEmpty,
            );
            // La feuille posee sur sa page : son bouton plein et celui de la
            // page, de deux contextes distincts.
            verifierUnSeulBoutonPlein(tester, maximum: 2);
            expect(
              find.descendant(
                of: _feuille,
                matching: find.text(t.enseignant.creneaux.enregistrerPlage),
              ),
              findsOneWidget,
            );
          });
        }
      }
    }
  });
}
