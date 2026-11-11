// « Aide et contact » pour l'eleve (garde-cap, 11/11/2026) : la ligne de son
// Compte ouvre `/eleve/aide`, et le retour ramene au Compte. Les autres
// comptes ne l'ont pas (ils lisent le canal directement dans leur Compte).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

String _sommet(GoRouter r) =>
    r.routerDelegate.currentConfiguration.matches.last.matchedLocation;

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('l\'eleve : « Aide et contact » ouvre /eleve/aide, retour au '
      'Compte', (tester) async {
    final GoRouter r = await monterRouteur(
      tester,
      Routes.compte,
      source: FausseSourceSession(sessionActive(AppRole.student)),
      taille: const Size(390, 1600),
    );
    final Finder ligne = find.byKey(ComptePage.aideEleveKey);
    expect(ligne, findsOneWidget);
    expect(find.text('Aide et contact'), findsOneWidget);
    await tester.ensureVisible(ligne);
    await tester.tap(ligne);
    await _attendre(tester);
    expect(_sommet(r), Routes.eleveAide);
    expect(find.byType(AideComptePage), findsOneWidget);
    tester.widget<AideComptePage>(find.byType(AideComptePage)).onRetour!();
    await _attendre(tester);
    expect(_sommet(r), Routes.compte);
  });

  for (final AppRole role in <AppRole>[AppRole.teacher, AppRole.admin]) {
    testWidgets('${role.name} : pas de ligne « Aide et contact » eleve', (
      tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.compte,
        source: FausseSourceSession(sessionActive(role)),
        taille: const Size(390, 1600),
      );
      expect(find.byKey(ComptePage.aideEleveKey), findsNothing);
    });
  }
}
