// Captures de recette MUSHAF-DIR-1 et MA-CORAN-X2-1 (05/10/2026) : les etats
// sans texte du lecteur du Coran du Mode Accessibilite (page non chargee,
// page vide), rendu page et verset agrandi.
//
// - phrases francaises de gauche a droite (point final a la fin) ;
// - l'etat s'arrete au-dessus des commandes et defile : une capture a
//   l'ouverture, et une seconde (`_defile`) apres avoir amene la derniere
//   ligne utile a l'ecran (« Reessayer », ou la phrase de la page vide).
//
// 320 x2, 390 x2, 1440 x1 ; clair et sombre ; Idriss (adulte, vouvoye) et
// Mariam (mineure, tutoyee). Chaque capture mesure qu'aucun mot n'est coupe.
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../core/accessibilite/coran_tutoiement_ma_test.dart'
    show EtatSansTexte, surchargesSansTexte;
import '../support/aucun_mot_coupe.dart';
import '../teaching_core/c/goldens/corpus_reference.dart';
import 'outil_capture.dart';

const List<(String, Size, double, double)> _formats =
    <(String, Size, double, double)>[
      ('320_x2', Size(320, 700), 2, 2),
      ('390_x2', Size(390, 844), 2, 2),
      ('1440_x1', Size(1440, 900), 1, 1),
    ];

void _mesurer(WidgetTester tester) {
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
  group('Capture : MUSHAF-DIR-1', skip: sautSansCapture, () {
    late CorpusReference reference;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      reference = CorpusReference.charger();
    });

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final EleveDemoAccessibilite eleve in <EleveDemoAccessibilite>[
        EleveDemoAccessibilite.idriss,
        EleveDemoAccessibilite.mariam,
      ]) {
        final String qui = eleve == EleveDemoAccessibilite.idriss
            ? 'adulte'
            : 'enfant';
        for (final (String nom, Size taille, double densite, double echelle)
            in _formats) {
          for (final EtatSansTexte etat in EtatSansTexte.values) {
            for (final bool grande in <bool>[false, true]) {
              if (grande && nom == '1440_x1') continue;
              final String fichier =
                  'mushaf_dir1_${qui}_${etat.name}_'
                  '${grande ? 'agrandi' : 'page'}_${nom}_${theme.name}';
              testWidgets(fichier, (WidgetTester tester) async {
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
                ).read(preferencesLocalesProvider.notifier).lectureGrande(
                  grande,
                );
                await tester.pump();
                await tester.tap(
                  find.byKey(const ValueKey<String>('coran-ma-principale')),
                );
                await stabiliser(tester);
                debugPrint('PNG ${await capturer(tester, fichier)}');
                _mesurer(tester);

                // La derniere ligne utile, amenee a l'ecran : au-dessus des
                // commandes, jamais dessous.
                final Finder derniere = find.text(
                  etat == EtatSansTexte.indisponible
                      ? t.eleve.coran.reessayer
                      : (DonneesAccessibiliteDemo.mineur(eleve)
                            ? t.eleve.coran.absentDetail
                            : t.accessibilite.coran.absentDetailVous),
                );
                await Scrollable.ensureVisible(tester.element(derniere), alignment: 1);
                await stabiliser(tester);
                expect(
                  tester.getRect(derniere).bottom,
                  lessThanOrEqualTo(
                    tester
                            .getRect(
                              find.byKey(CommandesMasquables.commandesKey),
                            )
                            .top +
                        0.5,
                  ),
                );
                debugPrint('PNG ${await capturer(tester, '${fichier}_defile')}');
                _mesurer(tester);
              });
            }
          }
        }
      }
    }
  });
}
