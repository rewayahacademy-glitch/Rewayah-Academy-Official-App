// RECH-D5 (partiel D1/D3) : l'entree dans les coques. Une seule loupe par
// coque enseignant et controleur, la loupe d'en-tete admin reliee, masquees
// quand aucun domaine n'est servi ; aucune entree dans les coques famille et
// eleve tant que D2 n'est pas fait (spec RECH-03 §4.1, §15).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/recherche/domaines/enseignants_pedagogie_controle/moteur_controle_mission.dart';
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

  group('famille et eleve : aucune entree tant que D2 n\'est pas fait', () {
    testWidgets('tuteur', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.guardian,
        Routes.tuteurAccueil,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });

    testWidgets('eleve', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.student,
        Routes.eleve,
        moteurs: moteursDemoRecherche(),
      );
      expect(find.byKey(cleLoupeRecherche), findsNothing);
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
  });
}
