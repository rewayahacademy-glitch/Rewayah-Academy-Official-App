// Captures du lot CURSEUR-CLIC (directeur, 08/11/2026) : « Tout
// selectionner » surligne le texte de contenu, jamais le libelle d'un lien,
// d'un bouton ou d'une ligne qui se touche. Ce qui se touche est hors de la
// selection : le pointeur y garde la fleche (le curseur ne se voit pas sur
// une image ; il est prouve par `test/core/widgets/curseur_clic_test.dart`).
//
// Scene composee avec les VRAIS composants (`LienFleche`, `ActionPrincipale`,
// `SettingRow`) sous le VRAI `SelectionRacine` ; ce n'est pas un ecran de
// l'application. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../support/hote_selection.dart';
import 'outil_capture.dart';

Widget _scene() => Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(height: AppSpacing.respiration),
      Text(t.kyc.intro),
      const SizedBox(height: AppSpacing.lg),
      LienFleche(libelle: t.admin.groupes.nomClasse.action, onPress: () {}),
      const SizedBox(height: AppSpacing.lg),
      SettingRow(
        title: t.admin.groupes.nomClasse.titre(nom: 'Hafsa'),
        onPress: () {},
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(t.kyc.confidentialite),
      const SizedBox(height: AppSpacing.xl),
      ActionPrincipale(
        libelle: t.admin.groupes.nomClasse.enregistrer,
        onPress: () {},
        pleineLargeur: false,
      ),
    ],
  ),
);

void main() {
  group('Capture : curseur des elements cliquables', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      for (final (String taille, Size vue, double densite)
          in <(String, Size, double)>[
            ('390', const Size(390, 844), 2),
            ('1440', const Size(1440, 900), 1),
          ]) {
        testWidgets('$nom $taille : tout selectionner, liens et boutons '
            'restent hors de la selection', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, vue, densite);
          await tester.pumpWidget(hoteSelection(_scene()));
          await tester.pump();
          tester
              .state<SelectableRegionState>(find.byType(SelectableRegion))
              .selectAll(SelectionChangedCause.toolbar);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 700));
          debugPrint(
            'PNG ${await capturer(tester, 'curseur-clic_${nom}_${taille}_tout-selectionne-cliquables-exclus')}',
          );
        });
      }
    }
  });
}
