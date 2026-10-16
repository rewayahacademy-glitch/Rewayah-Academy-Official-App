// L2-07 (reprise) : le matricule visible en demonstration. Chaque
// demonstration qui affiche une personne rend sa ligne « Matricule RA-AA-NNNN
// · role », par les surcharges de demonstration (aucun serveur).
// Source : DECISION-IMMATRICULATION-2026-10-12 section 1.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/identite/port_matricule.dart';
import 'package:rewayah_academy/features/compte/ligne_matricule.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../../support/harnais.dart';

Future<void> _montrerLigne(
  WidgetTester tester, {
  required String profileId,
  required String valeurAttendue,
  required RoleAffiche role,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  LocaleSettings.setLocaleSync(AppLocale.fr);

  await tester.pumpWidget(
    hote(
      Material(child: LigneMatricule(profileId: profileId)),
      surcharges: surchargesDemoTuteur(environnement: 'staging'),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text(valeurAttendue), findsOneWidget);
  expect(RegExp(r'^RA-[0-9]{2}-[0-9]{4}$').hasMatch(valeurAttendue), isTrue);
  expect(
    find.textContaining(libelleRoleAffiche(role), findRichText: true),
    findsOneWidget,
  );
  expect(find.byKey(LigneMatricule.copierKey), findsOneWidget);
}

void main() {
  testWidgets('demonstration tuteur : la ligne du tuteur, role Tuteur', (
    WidgetTester tester,
  ) async {
    await _montrerLigne(
      tester,
      profileId: DonneesDemo.tuteurId,
      valeurAttendue: 'RA-26-5301',
      role: RoleAffiche.tuteur,
    );
  });

  testWidgets('demonstration tuteur : la fiche enfant d Aicha, role Élève', (
    WidgetTester tester,
  ) async {
    await _montrerLigne(
      tester,
      profileId: DonneesDemo.aichaId,
      valeurAttendue: 'RA-26-5302',
      role: RoleAffiche.eleve,
    );
  });

  testWidgets('demonstration adulte : l eleve adulte Mamadou, role Élève', (
    WidgetTester tester,
  ) async {
    await _montrerLigne(
      tester,
      profileId: DonneesAdulteDemo.mamadouId,
      valeurAttendue: 'RA-26-5304',
      role: RoleAffiche.eleve,
    );
  });

  testWidgets('demonstration adulte : la fiche enfant d Oumar, role Élève', (
    WidgetTester tester,
  ) async {
    await _montrerLigne(
      tester,
      profileId: DonneesAdulteDemo.oumarId,
      valeurAttendue: 'RA-26-5306',
      role: RoleAffiche.eleve,
    );
  });
}
