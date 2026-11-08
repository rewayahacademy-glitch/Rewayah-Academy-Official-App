// Garde-cap, 08/11/2026 (PR 375) : en Interface guidee, `/compte` ne montre
// « Mon espace » guide qu'au compte qui peut demander la presentation
// standard (eleve mineur). Tout autre compte garde le Compte entier, avec
// « Mes donnees ». Le mineur garde « Mes donnees » dans « Mon espace ».
// Par le vrai routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/demande_presentation_supabase.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/accessibilite/port_demande_presentation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/features/accueil_eleve/mon_espace_accessibilite.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/mes_donnees_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

class _Port implements PortDemandePresentation {
  @override
  Future<void> demanderPresentationStandard() async {}
}

Future<void> _monter(
  WidgetTester tester,
  AppRole role, {
  required bool autonome,
}) async {
  await monterRouteur(
    tester,
    Routes.compte,
    source: FausseSourceSession(sessionActive(role)),
    taille: const Size(390, 2400),
    interface: InterfaceMode.enfant,
    surcharges: <Override>[
      portCapaciteEleveProvider.overrideWithValue(
        PortCapaciteEleveFactice(
          autonomes: autonome ? <String>{'p-${role.valeurSql}'} : <String>{},
        ),
      ),
      modeAccessibiliteActifProvider.overrideWithValue(true),
      mesDonneesDisponiblesProvider.overrideWithValue(true),
      prenomDuCompteProvider.overrideWith((Ref _) async => 'Yasmine'),
      portDemandePresentationProvider.overrideWithValue(_Port()),
    ],
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('eleve adulte en Interface guidee : le Compte entier, avec '
      '« Mes donnees »', (WidgetTester tester) async {
    await _monter(tester, AppRole.student, autonome: true);
    expect(find.byType(ComptePage), findsOneWidget);
    expect(find.byType(MonEspaceAccessibiliteBranche), findsNothing);
    expect(find.byKey(RubriqueMesDonnees.ligneKey), findsOneWidget);
  });

  testWidgets('eleve mineur en Interface guidee : « Mon espace » guide, '
      'qui garde « Mes donnees »', (WidgetTester tester) async {
    await _monter(tester, AppRole.student, autonome: false);
    expect(find.byType(MonEspaceAccessibiliteBranche), findsOneWidget);
    expect(find.byType(ComptePage), findsNothing);
    expect(find.byKey(RubriqueMesDonnees.ligneKey), findsOneWidget);
    expect(
      find.text(t.accessibilite.monEspace.presentationStandard),
      findsOneWidget,
    );
  });
}
