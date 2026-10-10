// Reprise de EA-HL-DOUBLE-1f (K-59, decide par delegation le 09/10,
// DIR-REP-1) : l'entree d'observation dont l'appel n'a pas abouti ne dit
// plus « L'observation n'est pas disponible pour le moment. », qui affirmait
// une indisponibilite cote service quand c'est l'appareil qui est hors
// ligne. Elle dit ce qui n'a pas abouti et, quand l'echec se reessaye
// (reseau), la cause probable dans la formulation unique de EA-HL-DOUBLE-1e,
// sous le bandeau qui seul dit le reseau.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/moteur_visite_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

Future<void> _monterEtEntrer(
  WidgetTester tester, {
  required MotifEchecObservation motif,
  bool horsLigne = true,
  ThemeMode themeMode = ThemeMode.light,
  TextDirection? direction,
  double echelle = 1,
}) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: RoutesTcG.versObservation('s1'),
      routes: routesTcG(),
      surcharges: surchargesTcG(
        role: AppRole.admin,
        visites: FauxPortVisite(echecEntree: EchecObservation(motif)),
        horsLigne: horsLigne,
      ),
      themeMode: themeMode,
      direction: direction,
      echelle: echelle,
    ),
  );
  await tester.pumpAndSettle();
  final Finder entrer = find.text(t.tc.observation.entree.entrer);
  await tester.ensureVisible(entrer);
  await tester.pumpAndSettle();
  await tester.tap(entrer);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reseau, hors ligne : ce qui n a pas abouti, la cause probable '
      'sans l affirmer, et Entrer pour reessayer', (WidgetTester tester) async {
    await _monterEtEntrer(tester, motif: MotifEchecObservation.reseau);

    expect(find.text(t.tc.observation.refus.indisponible), findsOneWidget);
    expect(
      find.text(t.tc.observation.refus.indisponibleInvitation),
      findsOneWidget,
    );
    expect(causesAffirmees(), findsNothing);
    expect(find.textContaining(formulationCauseProbable), findsOneWidget);
    expectHorsLigneUneFois();
    expect(find.text(t.tc.observation.entree.entrer), findsOneWidget);
  });

  testWidgets('reponse illisible : ni cause probable ni bouton', (
    WidgetTester tester,
  ) async {
    await _monterEtEntrer(
      tester,
      motif: MotifEchecObservation.reponseIllisible,
      horsLigne: false,
    );

    expect(find.text(t.tc.observation.refus.indisponible), findsOneWidget);
    expect(causesAffirmees(), findsNothing);
    expect(find.textContaining(formulationCauseProbable), findsNothing);
    expect(find.text(t.tc.observation.entree.entrer), findsNothing);
  });

  testWidgets('flux d etats en echec : aucune indisponibilite affirmee, la '
      'relecture est offerte', (WidgetTester tester) async {
    int abonnements = 0;
    await tester.pumpWidget(
      hoteRoutant(
        depart: RoutesTcG.versObservation('s1'),
        routes: routesTcG(),
        surcharges: <Override>[
          ...surchargesTcG(role: AppRole.admin, horsLigne: true),
          etatVisiteObservationProvider.overrideWith((Ref ref, String _) {
            abonnements++;
            return Stream<EtatVisiteObservation>.error(StateError('coupe'));
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.tc.observation.refus.indisponible), findsOneWidget);
    expect(causesAffirmees(), findsNothing);
    expectHorsLigneUneFois();
    final int avant = abonnements;
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pumpAndSettle();
    expect(abonnements, greaterThan(avant));
  });

  group('320 texte x2 (polices du depot)', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 texte x2, ${sens.name} : aucun mot coupe ni tronque', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(320, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _monterEtEntrer(
          tester,
          motif: MotifEchecObservation.reseau,
          direction: sens,
          echelle: 2,
        );
        expect(
          find.text(t.tc.observation.refus.indisponibleInvitation),
          findsOneWidget,
        );
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
      });
    }
  });

  // Captures de preuve, sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1f', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String, Size, ThemeMode, double, TextDirection, bool) cas
        in <(String, Size, ThemeMode, double, TextDirection, bool)>[
          (
            '390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            true,
          ),
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
            true,
          ),
          (
            '320x2_clair',
            const Size(320, 1400),
            ThemeMode.light,
            2,
            TextDirection.ltr,
            true,
          ),
          (
            '320x2_rtl_clair',
            const Size(320, 1400),
            ThemeMode.light,
            2,
            TextDirection.rtl,
            true,
          ),
          (
            '320x2_rtl_sombre',
            const Size(320, 1400),
            ThemeMode.dark,
            2,
            TextDirection.rtl,
            true,
          ),
          (
            '1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            true,
          ),
          (
            '390_en_ligne_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
            false,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await _monterEtEntrer(
          tester,
          motif: MotifEchecObservation.reseau,
          horsLigne: cas.$6,
          themeMode: cas.$3,
          direction: cas.$5,
          echelle: cas.$4,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(t.tc.observation.refus.indisponibleInvitation),
          findsOneWidget,
        );
        expect(causesAffirmees(), findsNothing);
        if (cas.$6) {
          expectHorsLigneUneFois();
        }
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1f_observation_echec_${cas.$1}')}',
        );
      });
    }
  });
}
