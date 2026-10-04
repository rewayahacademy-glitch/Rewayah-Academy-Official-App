// Captures de recette MA-TUTOIEMENT-1 (decision A4 = a) :
//
// - le lecteur du Coran du Mode Accessibilite ouvert par Idriss (adulte) sur
//   une page illisible et sur une page vide : phrases vouvoyees, rendu du
//   Coran intouche ; 390 x1 et x2, 320 x2, 1440 x1, clair et sombre ; plus
//   Mariam (mineure, tutoyee) a 390 clair pour comparaison, et le verset
//   agrandi a 390 x2 ;
// - la VRAIE salle (`SallePage`) apres « Quitter », age inconnu (port neutre
//   de l'application) : ecran de fin vouvoye ; memes formats.
//
// Chaque capture mesure aussi qu'aucun mot n'est coupe ni tronque.
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie dans
// `docs/current/captures/MA-TUTOIEMENT-1/`. Donnees de demonstration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../core/accessibilite/coran_tutoiement_ma_test.dart'
    show EtatSansTexte, surchargesSansTexte;
import '../features/salle_seance/support_ma_apres1.dart';
import '../support/aucun_mot_coupe.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

/// [exceptions] : les paragraphes exclus de la mesure. Seul cas : le bouton
/// « Reessayer » de l'etat « texte non charge » des vues de rendu
/// (`tc_mushaf`), qui se coupe en plein mot a 320 x2 dans le cadre de page,
/// AVANT cette etape et quel que soit le registre (meme capture chez
/// l'enfant tutoye). Defaut signale dans le rapport de l'etape, hors de son
/// perimetre (le rendu de `tc_mushaf` ne change pas ici).
void _mesurer(
  WidgetTester tester, {
  Set<String> exceptions = const <String>{},
}) {
  final List<String> fautes = motsCoupes(
    tester,
    find.byKey(cadreCapture),
    traitDUnionPermis: true,
    exceptions: exceptions,
  );
  if (fautes.isNotEmpty) debugPrint('FAUTES ${fautes.toSet().join(' | ')}');
  if (exceptions.isNotEmpty) {
    // La trace du defaut anterieur exclu, pour le rapport.
    final List<String> brutes = motsCoupes(
      tester,
      find.byKey(cadreCapture),
      traitDUnionPermis: true,
    );
    debugPrint('EXCLUES ${brutes.toSet().join(' | ')}');
  }
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
  expect(tester.takeException(), isNull);
}

/// Le defaut anterieur exclu (voir [_mesurer]) : seulement la ou il se voit.
Set<String> _exceptions(EtatSansTexte etat, String format) =>
    etat == EtatSansTexte.indisponible && format == '320_x2'
    ? const <String>{'Réessayer'}
    : const <String>{};

const List<(String, Size, double, double)> _formats =
    <(String, Size, double, double)>[
      ('390_x1', Size(390, 844), 2, 1),
      ('390_x2', Size(390, 844), 2, 2),
      ('320_x2', Size(320, 700), 2, 2),
      ('1440_x1', Size(1440, 900), 1, 1),
    ];

void main() {
  group('Capture : MA-TUTOIEMENT-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    Future<void> lecteur(
      WidgetTester tester, {
      required EleveDemoAccessibilite eleve,
      required EtatSansTexte etat,
      required Size taille,
      required double densite,
      required double echelle,
      required ThemeMode theme,
      bool grande = false,
    }) async {
      fixerVueCapture(tester, taille, densite);
      await tester.pumpWidget(
        hoteCapture(
          EcranAccessibiliteDemo(
            eleve: eleve,
            destinationInitiale: EcranAccessibiliteDemo.indexCoran,
            surchargesCoran: surchargesSansTexte(reference, etat),
          ),
          themeMode: theme,
          echelleTexte: echelle,
          interfaceMode: InterfaceMode.enfant,
        ),
      );
      await stabiliser(tester);
      ProviderScope.containerOf(
        tester.element(find.byType(EcranAccessibiliteDemo)),
      ).read(preferencesLocalesProvider.notifier).lectureGrande(grande);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('coran-ma-principale')),
      );
      await stabiliser(tester);
    }

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final (String nom, Size taille, double densite, double echelle)
          in _formats) {
        for (final EtatSansTexte etat in EtatSansTexte.values) {
          final String fichier =
              'ma_tutoiement1_coran_adulte_${etat.name}_${nom}_${theme.name}';
          testWidgets(fichier, (WidgetTester tester) async {
            await lecteur(
              tester,
              eleve: EleveDemoAccessibilite.idriss,
              etat: etat,
              taille: taille,
              densite: densite,
              echelle: echelle,
              theme: theme,
            );
            debugPrint('PNG ${await capturer(tester, fichier)}');
            _mesurer(tester, exceptions: _exceptions(etat, nom));
          });
        }

        final String fichier =
            'ma_tutoiement1_salle_fin_adulte_${nom}_'
            '${theme.name}';
        testWidgets(fichier, (WidgetTester tester) async {
          await quitterLaSalleMa(
            tester,
            groupes: GroupesMaApres(classeAVenir),
            taille: taille,
            densite: densite,
            echelle: echelle,
            themeMode: theme,
            cadre: cadreCapture,
            age: null,
          );
          debugPrint('PNG ${await capturer(tester, fichier)}');
          _mesurer(tester);
        });
      }
    }

    for (final EtatSansTexte etat in EtatSansTexte.values) {
      for (final (String nom, Size taille, double densite, double echelle)
          in _formats.where(
            ((String, Size, double, double) f) =>
                f.$1 == '390_x1' || f.$1 == '320_x2',
          )) {
        final String fichier =
            'ma_tutoiement1_coran_enfant_${etat.name}_${nom}_light';
        testWidgets(fichier, (WidgetTester tester) async {
          await lecteur(
            tester,
            eleve: EleveDemoAccessibilite.mariam,
            etat: etat,
            taille: taille,
            densite: densite,
            echelle: echelle,
            theme: ThemeMode.light,
          );
          debugPrint('PNG ${await capturer(tester, fichier)}');
          _mesurer(tester, exceptions: _exceptions(etat, nom));
        });
      }
      final String agrandi =
          'ma_tutoiement1_coran_adulte_${etat.name}_verset_agrandi_390_x2_light';
      testWidgets(agrandi, (WidgetTester tester) async {
        await lecteur(
          tester,
          eleve: EleveDemoAccessibilite.idriss,
          etat: etat,
          taille: const Size(390, 844),
          densite: 2,
          echelle: 2,
          theme: ThemeMode.light,
          grande: true,
        );
        debugPrint('PNG ${await capturer(tester, agrandi)}');
        _mesurer(tester);
      });
    }
  });
}
