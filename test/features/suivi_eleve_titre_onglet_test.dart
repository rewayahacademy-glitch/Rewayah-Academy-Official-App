// Le titre de la page de suivi de l'eleve est le libelle de l'onglet actif
// (garde-cap, 11/11/2026) : « Ma classe » pour l'eleve, « Suivi » pour l'eleve
// adulte (barre du lot B2, capacite « eleve autonome »). Vrai routeur, vraie
// coquille.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';

Future<void> _verifier(
  WidgetTester tester, {
  required bool autonome,
  required String attendu,
}) async {
  await monterRouteur(
    tester,
    Routes.eleveSuivi,
    source: FausseSourceSession(sessionActive(AppRole.student)),
    taille: const Size(390, 1600),
    surcharges: <Override>[
      portCapaciteEleveProvider.overrideWithValue(
        PortCapaciteEleveFactice(
          autonomes: autonome
              ? <String>{'p-${AppRole.student.valeurSql}'}
              : <String>{},
        ),
      ),
    ],
  );
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(SuiviElevePage), findsOneWidget);
  final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
  final String onglet = coquille.destinations[coquille.indexActif!].libelle;
  final PageShell page = tester.widget<PageShell>(
    find.descendant(
      of: find.byType(SuiviElevePage),
      matching: find.byType(PageShell),
    ),
  );
  expect(onglet, attendu);
  expect(page.titre, onglet);
}

void main() {
  testWidgets(
    'eleve : onglet actif « Ma classe » = titre de la page',
    (tester) =>
        _verifier(tester, autonome: false, attendu: t.nav.eleve.maClasse),
  );

  testWidgets(
    'eleve adulte : onglet actif « Suivi » = titre de la page',
    (tester) => _verifier(tester, autonome: true, attendu: t.nav.eleve.suivi),
  );
}
