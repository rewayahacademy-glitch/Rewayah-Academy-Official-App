// Captures de recette de MA-APRES-1 : l'ecran unique de fin en Mode
// Accessibilite, monte par la VRAIE salle (`SallePage`) apres « Quitter le
// cours », vraies polices, vrai theme.
//
// - contenu : 390 x1 et x2, 320 x2, 1440 x1, clair et sombre ;
// - les quatre autres etats (chargement, vide, erreur, hors ligne) : 390 x1,
//   clair.
//
// Chaque capture mesure aussi qu'aucun mot de l'ecran n'est coupe ni
// tronque, et qu'aucun debordement n'est leve.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/MA-APRES-1/`. Donnees : Classe de
// demonstration uniquement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/features/accueil_eleve/apres_seance_accessibilite.dart';

import '../features/salle_seance/support_ma_apres1.dart';
import '../support/aucun_mot_coupe.dart';
import 'outil_capture.dart';

void _mesurer(WidgetTester tester) {
  expect(find.byType(ApresSeanceAccessibilite), findsOneWidget);
  final List<String> fautes = motsCoupes(
    tester,
    find.byKey(cadreCapture),
    traitDUnionPermis: true,
  );
  if (fautes.isNotEmpty) debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : MA-APRES-1', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, double echelle)
          in <(Size, double, double)>[
            (const Size(390, 844), 2, 1),
            (const Size(390, 844), 2, 2),
            (const Size(320, 700), 2, 2),
            (const Size(1440, 900), 1, 1),
          ]) {
        final String nom =
            'ma_apres1_contenu_${taille.width.round()}_x${echelle.round()}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          await quitterLaSalleMa(
            tester,
            groupes: GroupesMaApres(classeAVenir),
            taille: taille,
            densite: densite,
            echelle: echelle,
            themeMode: mode,
            cadre: cadreCapture,
          );
          _mesurer(tester);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }
    }

    final Completer<GroupSummaryVM?> jamais = Completer<GroupSummaryVM?>();
    for (final (String etat, PortGroupes Function() groupes, bool horsLigne)
        in <(String, PortGroupes Function(), bool)>[
          ('chargement', () => GroupesMaApres(() => jamais.future), false),
          ('vide', () => GroupesMaApres(() async => null), false),
          (
            'erreur',
            () => GroupesMaApres(
              () => Future<GroupSummaryVM?>.error(StateError('reseau')),
            ),
            false,
          ),
          ('hors_ligne', () => GroupesMaApres(classeAVenir), true),
        ]) {
      final String nom = 'ma_apres1_${etat}_390_x1_light';
      testWidgets(nom, (WidgetTester tester) async {
        await quitterLaSalleMa(
          tester,
          groupes: groupes(),
          densite: 2,
          horsLigne: horsLigne,
          cadre: cadreCapture,
        );
        _mesurer(tester);
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });
}
