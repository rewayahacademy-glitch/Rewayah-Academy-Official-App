// BIBLIO-LECTURE (point 3) : la Bibliotheque se rejoint depuis la navigation,
// pas seulement par une adresse : l'eleve (Mon espace), le tuteur (Compte) et
// l'adulte eleve autonome (compte tuteur). Capacite de la session, jamais le
// role ; ni l'enseignant, ni le controleur, ni l'administration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';

import '../../router/support_routeur.dart';
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
  testWidgets('l\'eleve : « Bibliotheque » dans Mon espace, qui l\'ouvre', (
    tester,
  ) async {
    final GoRouter r = await _monter(tester, AppRole.student, Routes.compte);
    expect(find.text('Bibliothèque'), findsOneWidget);
    await tester.tap(find.text('Bibliothèque'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sommet(r), Routes.tcBibliotheque);
  });

  testWidgets('le tuteur : « Ouvrir la bibliotheque » dans son Compte', (
    tester,
  ) async {
    final GoRouter r = await _monter(
      tester,
      AppRole.guardian,
      Routes.tuteurCompte,
    );
    expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
    await tester.ensureVisible(find.text('Ouvrir la bibliothèque'));
    await tester.tap(find.text('Ouvrir la bibliothèque'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sommet(r), Routes.tcBibliotheque);
  });

  testWidgets('l\'adulte eleve autonome : la meme entree, par son compte '
      'tuteur', (tester) async {
    final GoRouter r = await _monter(
      tester,
      AppRole.guardian,
      Routes.tuteurCompte,
      autonome: true,
    );
    expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
    await tester.ensureVisible(find.text('Ouvrir la bibliothèque'));
    await tester.tap(find.text('Ouvrir la bibliothèque'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_sommet(r), Routes.tcBibliotheque);
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
