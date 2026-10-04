// Captures de recette FORM-L8 (profil enseignant : pays choisi dans une liste
// preselectionnee par le fuseau, langues cochees) et FORM-L9 (cahier de
// transmission : reprise choisie par sourate puis verset, repli au clavier si
// la liste est illisible). Vrais ecrans de la demonstration, ouverts par de
// vrais tap.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// forml8_<etat>_<largeur>_x<echelle>_<mode>.png, idem forml9.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/port_corpus_coran.dart';
import 'package:rewayah_academy/features/cahier/selecteur_reprise.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/profil_enseignant/declaration_choix.dart';

import '../support/cahier_sourates.dart';
import 'outil_capture.dart';

const List<(Size, double, double, String)> _cadres =
    <(Size, double, double, String)>[
      (Size(320, 700), 2, 1, '320_x1'),
      (Size(320, 700), 2, 2, '320_x2'),
      (Size(1440, 900), 1, 1, '1440_x1'),
    ];

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Capture : FORM-L8 et FORM-L9', skip: sautSansCapture, () {
    late List<SourateVM> sourates;
    setUpAll(() async {
      await chargerPolicesDuDepot();
      sourates = souratesDeLaMigration();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, double echelle, String nom)
          in _cadres) {
        final String suffixe = '${nom}_${mode.name}';

        Future<void> monterProfil(WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.profil),
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
        }

        testWidgets('forml8 pays $suffixe', (WidgetTester tester) async {
          await monterProfil(tester);
          await _toucher(tester, find.text(t.enseignant.profil.pays));
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml8_pays_$suffixe')}');
        });

        testWidgets('forml8 langues $suffixe', (WidgetTester tester) async {
          await monterProfil(tester);
          await _toucher(tester, find.text(t.enseignant.profil.langues));
          await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Poular')));
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml8_langues_$suffixe')}');
        });

        testWidgets('forml8 enregistre $suffixe', (WidgetTester tester) async {
          await monterProfil(tester);
          await _toucher(tester, find.text(t.enseignant.profil.langues));
          await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Poular')));
          await _toucher(tester, find.byKey(FeuilleLangues.enregistrerKey));
          await tester.ensureVisible(find.text(t.enseignant.profil.langues));
          await stabiliser(tester);
          expect(find.text('Arabe, Français, Poular'), findsOneWidget);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml8_enregistre_$suffixe')}');
        });

        Future<void> monterCahierCapture(
          WidgetTester tester, {
          bool echoue = false,
        }) => monterCahier(
          tester,
          CorpusSourates(sourates, echoue: echoue),
          taille: taille,
          densite: densite,
          mode: mode,
          echelleTexte: echelle,
        );

        testWidgets('forml9 champ $suffixe', (WidgetTester tester) async {
          await monterCahierCapture(tester);
          await tester.ensureVisible(find.byKey(ChampReprise.champKey));
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml9_champ_$suffixe')}');
        });

        testWidgets('forml9 feuille $suffixe', (WidgetTester tester) async {
          await monterCahierCapture(tester);
          await _toucher(tester, find.byKey(ChampReprise.champKey));
          await tester.enterText(
            find.widgetWithText(
              TextField,
              t.enseignant.cahier.repriseRecherche,
            ),
            'kahf',
          );
          await stabiliser(tester);
          await _toucher(tester, find.byKey(FeuilleReprise.sourateKey(18)));
          await _toucher(tester, find.byKey(FeuilleReprise.versetKey(10)));
          FocusManager.instance.primaryFocus?.unfocus();
          await stabiliser(tester);
          // Le haut de la feuille : la recherche, la sourate retenue, le
          // debut des versets.
          await tester.ensureVisible(
            find.widgetWithText(
              TextField,
              t.enseignant.cahier.repriseRecherche,
            ),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml9_feuille_$suffixe')}');
        });

        testWidgets('forml9 retenue $suffixe', (WidgetTester tester) async {
          await monterCahierCapture(tester);
          await _toucher(tester, find.byKey(ChampReprise.champKey));
          await tester.enterText(
            find.widgetWithText(
              TextField,
              t.enseignant.cahier.repriseRecherche,
            ),
            'kahf',
          );
          await stabiliser(tester);
          await _toucher(tester, find.byKey(FeuilleReprise.sourateKey(18)));
          await _toucher(tester, find.byKey(FeuilleReprise.versetKey(10)));
          await _toucher(tester, find.byKey(FeuilleReprise.retenirKey));
          await tester.ensureVisible(find.byKey(ChampReprise.champKey));
          await stabiliser(tester);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml9_retenue_$suffixe')}');
        });

        testWidgets('forml9 sans liste $suffixe', (WidgetTester tester) async {
          await monterCahierCapture(tester, echoue: true);
          await tester.ensureVisible(find.byKey(ChampReprise.champKey));
          await stabiliser(tester);
          // ignore: avoid_print
          print('PNG ${await capturer(tester, 'forml9_sans_liste_$suffixe')}');
        });
      }
    }
  });
}
