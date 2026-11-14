// BIBLIO-LECTURE (point 3) : la Bibliotheque se rejoint depuis la navigation,
// pas seulement par une adresse : l'eleve (en tete de « Ma classe », un
// toucher depuis la barre, garde-cap 11/11/2026), le tuteur (Compte) et
// l'adulte eleve autonome (compte tuteur). Capacite de la session, jamais le
// role ; ni l'enseignant, ni le controleur, ni l'administration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/features/suivi_eleve/entree_bibliotheque.dart';
import 'package:rewayah_academy/features/suivi_foyer/carte_suivi_pedagogique.dart';

import '../../router/support_routeur.dart';
import '../../support/destination_nav.dart';
import '../../support/harnais.dart';

String _sommet(GoRouter r) =>
    r.routerDelegate.currentConfiguration.matches.last.matchedLocation;

Future<GoRouter> _monter(
  WidgetTester tester,
  AppRole role,
  String depart, {
  bool autonome = false,
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  taille: const Size(390, 1600),
  surcharges: <Override>[
    portCapaciteEleveProvider.overrideWithValue(
      PortCapaciteEleveFactice(
        autonomes: autonome ? <String>{'p-${role.valeurSql}'} : <String>{},
      ),
    ),
  ],
);

void main() {
  testWidgets('l\'eleve : un seul toucher sur « Ma classe » dans la barre, '
      'la Bibliotheque est en tete et l\'ouvre', (tester) async {
    final GoRouter r = await _monter(tester, AppRole.student, Routes.eleve);
    // Un seul toucher depuis la barre.
    await tester.tap(destinationNav(t.nav.eleve.maClasse));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sommet(r), Routes.eleveSuivi);
    final Finder ligne = find.byKey(EntreeBibliothequeMaClasse.ligneKey);
    expect(ligne, findsOneWidget);
    // En tete : avant « Ou j'en suis ».
    expect(
      tester.getTopLeft(ligne).dy,
      lessThan(tester.getTopLeft(find.byType(CarteSuiviPedagogique)).dy),
    );
    await tester.tap(ligne);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    // ESPACE-APPRENDRE (lot 5) : un raccourci vers l'espace Apprendre, qui n'a
    // qu'une Bibliotheque ; plus vers l'ancienne liste.
    expect(_sommet(r), Routes.eleveApprendre);
  });

  testWidgets('l\'eleve : la Bibliotheque sort du Compte', (tester) async {
    await _monter(tester, AppRole.student, Routes.compte);
    expect(find.text('Bibliothèque'), findsNothing);
  });

  testWidgets('le tuteur : la Bibliotheque sort de son Compte', (tester) async {
    await _monter(tester, AppRole.guardian, Routes.tuteurCompte);
    expect(find.text('Ouvrir la bibliothèque'), findsNothing);
    expect(find.text('Bibliothèque'), findsNothing);
  });

  for (final AppRole role in <AppRole>[
    AppRole.teacher,
    AppRole.controller,
    AppRole.admin,
  ]) {
    testWidgets('${role.name} : aucune entree vers la Bibliotheque', (
      tester,
    ) async {
      await _monter(tester, role, Routes.compte);
      expect(find.text('Bibliothèque'), findsNothing);
      expect(find.text('Ouvrir la bibliothèque'), findsNothing);
    });
  }
}
