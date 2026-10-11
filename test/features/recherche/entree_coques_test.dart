// RECH-D5 : l'entree universelle dans les coques. Une seule loupe par coque
// (famille, eleve, enseignant, controleur, comptable), la loupe d'en-tete et
// la barre mobile de l'admin reliees, le raccourci Ctrl/Cmd + K ; tout est
// masque (jamais grise) quand aucun domaine n'est servi a l'espace de la
// personne : capacite, jamais role (spec RECH-03 §4.1, §15).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';
import 'package:rewayah_academy/features/recherche/domaines/enseignants_pedagogie_controle/moteur_controle_mission.dart';
import 'package:rewayah_academy/features/recherche/domaines/finance_communications/moteur_finances.dart';
import 'package:rewayah_academy/features/recherche/entree_recherche.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

List<MoteurRechercheDomaine> _moteursControle() => <MoteurRechercheDomaine>[
  MoteurControleMission(
    lire: () async => MissionControle(
      seanceId: 's1',
      classe: 'Classe Al-Fatiha',
      enseignant: 'Sayyid Youssouf',
      nombreEleves: 12,
      debut: DateTime.now(),
      finPrevue: DateTime.now().add(const Duration(hours: 1)),
      etat: EtatMissionControle.enDirect,
    ),
  ),
];

Future<GoRouter> _monter(
  WidgetTester tester,
  AppRole role,
  String depart, {
  List<MoteurRechercheDomaine>? moteurs,
  Size taille = const Size(390, 844),
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  taille: taille,
  surcharges: <Override>[
    moteursRechercheProvider.overrideWithValue(
      moteurs ?? const <MoteurRechercheDomaine>[],
    ),
  ],
);

String _sommet(GoRouter r) =>
    r.routerDelegate.currentConfiguration.matches.last.matchedLocation;

void main() {
  group('enseignant', () {
    testWidgets('domaine servi : une seule loupe, qui ouvre /recherche', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantJournee,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
      await tester.tap(find.byKey(cleLoupeRecherche));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_sommet(routeur), Routes.recherche);
    });

    testWidgets('aucun domaine servi : la loupe est masquee, pas grisee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.teacher, Routes.enseignantJournee);
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });

    testWidgets('une seule loupe sur chaque onglet de la coque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantClasses,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
    });
  });

  group('controleur', () {
    testWidgets('sa mission est servie : la loupe est la, une seule', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.controller,
        Routes.controleur,
        moteurs: _moteursControle(),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
      await tester.tap(find.byKey(cleLoupeRecherche));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_sommet(routeur), Routes.recherche);
    });

    testWidgets('un domaine servi a un autre espace ne donne rien au '
        'controleur (capacite, jamais role)', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.controller,
        Routes.controleur,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });
  });

  group('famille, eleve et comptable : la meme loupe, par capacite', () {
    testWidgets('tuteur : domaine servi, une seule loupe vers /recherche', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.guardian,
        Routes.tuteurAccueil,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
      await tester.tap(find.byKey(cleLoupeRecherche));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_sommet(routeur), Routes.recherche);
    });

    testWidgets('tuteur : aucun domaine servi, la loupe est masquee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.guardian, Routes.tuteurAccueil);
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });

    testWidgets('eleve : domaine servi, une seule loupe', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        AppRole.student,
        Routes.eleve,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
    });

    testWidgets('eleve : aucun domaine servi, la loupe est masquee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.student, Routes.eleve);
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });

    testWidgets('comptable : seul son domaine (finances) lui donne la loupe', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        AppRole.accountant,
        Routes.comptable,
        moteurs: moteursDemoRecherche(),
      );
      // Les domaines de demonstration (classes, supports, pedagogie) ne sont
      // pas les siens : rien n'est servi, rien n'est montre.
      expect(find.byKey(cleLoupeRecherche), findsNothing);
      await _monter(
        tester,
        AppRole.accountant,
        Routes.comptable,
        moteurs: <MoteurRechercheDomaine>[
          MoteurEncaissements(EncaissementsDemo()),
        ],
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
    });

    testWidgets('un domaine d\'une autre famille ne donne rien a l\'eleve '
        '(capacite, jamais role)', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.student,
        Routes.eleve,
        moteurs: <MoteurRechercheDomaine>[
          MoteurEncaissements(EncaissementsDemo()),
        ],
      );
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });
  });

  group('Ctrl / Cmd + K', () {
    Future<void> appuyer(
      WidgetTester tester,
      LogicalKeyboardKey modificateur,
    ) async {
      await tester.sendKeyDownEvent(modificateur);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(modificateur);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final (String nom, LogicalKeyboardKey touche)
        in <(String, LogicalKeyboardKey)>[
          ('Ctrl', LogicalKeyboardKey.controlLeft),
          ('Cmd', LogicalKeyboardKey.metaLeft),
        ]) {
      testWidgets('$nom + K ouvre la meme recherche, domaine servi', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(
          tester,
          AppRole.teacher,
          Routes.enseignantJournee,
          moteurs: moteursDemoRecherche(),
          taille: const Size(1440, 900),
        );
        await appuyer(tester, touche);
        expect(_sommet(routeur), Routes.recherche);
      });
    }

    testWidgets('aucun domaine servi : la touche ne fait rien', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantJournee,
        taille: const Size(1440, 900),
      );
      await appuyer(tester, LogicalKeyboardKey.controlLeft);
      expect(_sommet(routeur), Routes.enseignantJournee);
    });

    testWidgets('K seul ne declenche rien', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantJournee,
        moteurs: moteursDemoRecherche(),
        taille: const Size(1440, 900),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_sommet(routeur), Routes.enseignantJournee);
    });

    testWidgets('administration : Ctrl + K aussi', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.admin,
        Routes.admin,
        moteurs: moteursDemoRecherche(),
        taille: const Size(1440, 900),
      );
      await appuyer(tester, LogicalKeyboardKey.controlLeft);
      expect(_sommet(routeur), Routes.recherche);
    });
  });

  group('administration : la loupe d\'en-tete', () {
    Future<void> ouvrirLoupe(WidgetTester tester) async {
      await tester.tap(find.byIcon(AppIcons.recherche.repos).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('domaine servi : la feuille garde la navigation et ajoute le '
        'lien vers la recherche metier', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.admin,
        Routes.admin,
        moteurs: moteursDemoRecherche(),
        taille: const Size(1440, 900),
      );
      await ouvrirLoupe(tester);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Rechercher dans votre espace'), findsOneWidget);
      await tester.tap(find.text('Rechercher dans votre espace'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lieu(routeur), Routes.recherche);
    });

    testWidgets('aucun domaine servi : la loupe est inchangee, pas de lien', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        AppRole.admin,
        Routes.admin,
        taille: const Size(1440, 900),
      );
      await ouvrirLoupe(tester);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Rechercher dans votre espace'), findsNothing);
    });

    testWidgets('barre mobile (< 600) : le champ de navigation reste en '
        'ligne, la recherche metier s\'ouvre depuis le menu', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.admin,
        Routes.admin,
        moteurs: moteursDemoRecherche(),
        taille: const Size(560, 900),
      );
      expect(find.byType(TextField), findsWidgets);
      await tester.tap(find.byIcon(AppIcons.menu.repos).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rechercher dans votre espace'), findsOneWidget);
      await tester.tap(find.text('Rechercher dans votre espace'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lieu(routeur), Routes.recherche);
    });

    testWidgets('barre mobile : aucun domaine servi, pas de lien dans le '
        'menu', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.admin,
        Routes.admin,
        taille: const Size(560, 900),
      );
      await tester.tap(find.byIcon(AppIcons.menu.repos).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rechercher dans votre espace'), findsNothing);
    });
  });
}
