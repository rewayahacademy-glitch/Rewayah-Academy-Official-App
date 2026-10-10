// COUPE-MOTS-4 (1) : `ChoiceCardGroup`, composant partage, coupait des mots
// a 320 px en texte x2 (« nor / malement », « obser / vation »,
// « administ / ration », « Acc / essibilité », « Présentat / ion »).
//
// En liste, l'icone et le radio prenaient la largeur du libelle et de sa
// description : la colonne de texte n'avait plus la place d'un mot long.
// Le composant pose desormais l'icone et le radio sur leur propre rangee
// quand un mot ne tient pas a cote d'eux, et chaque texte passe par
// `TexteSansCoupure`.
//
// Ce test porte sur le composant, avec les libelles reels de ses appelants
// (compte rendu du Controleur, fiche eleve, reglages). Les tests d'ecran des
// appelants sont dans `test/features/coupe_mots_4/`.
// Contre-epreuve : sur l'ancien code (5a52ff30), ce test echoue en nommant
// les mots coupes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

List<OptionChoix> _options() => <OptionChoix>[
  OptionChoix(
    valeur: 'a',
    libelle: t.controleur.compteRendu.rienASignaler,
    description: t.controleur.compteRendu.rienASignalerAide,
    icone: AppIcons.succes,
  ),
  OptionChoix(
    valeur: 'b',
    libelle: t.controleur.compteRendu.ajouterObservation,
    description: t.controleur.compteRendu.ajouterObservationAide,
    icone: AppIcons.noter,
  ),
  OptionChoix(
    valeur: 'c',
    libelle: t.controleur.compteRendu.pointImportant,
    description: t.controleur.compteRendu.pointImportantAide,
    icone: AppIcons.signaler,
  ),
  const OptionChoix(
    valeur: 'd',
    libelle: 'Mode Accessibilité',
    description: 'Présentation standard',
    icone: AppIcons.noter,
    disponible: false,
    raisonIndisponible: "Réservé à l'administration",
  ),
];

Future<void> _monter(
  WidgetTester tester, {
  required double largeur,
  required double echelle,
  required TextDirection sens,
  required InterfaceMode interface,
  bool coteACote = false,
  bool multiple = false,
}) async {
  tester.view.physicalSize = Size(largeur, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(interface, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(largeur, 4000),
          textScaler: TextScaler.linear(echelle),
        ),
        child: Directionality(
          textDirection: sens,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ChoiceCardGroup(
                coteACote: coteACote,
                selectionMultiple: multiple,
                valeurInitiale: const ReponseChoix(valeurs: <String>{'a'}),
                options: _options(),
                onChange: (ReponseChoix _) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final InterfaceMode interface in <InterfaceMode>[
    InterfaceMode.standard,
    InterfaceMode.enfant,
  ]) {
    for (final TextDirection sens in TextDirection.values) {
      for (final bool coteACote in <bool>[false, true]) {
        for (final bool multiple in <bool>[false, true]) {
          testWidgets('320 x2 ${sens.name} ${interface.name} '
              '${coteACote ? 'cote a cote' : 'liste'}'
              '${multiple ? ' multiple' : ''} : aucun mot coupe', (
            WidgetTester tester,
          ) async {
            await _monter(
              tester,
              largeur: 320,
              echelle: 2,
              sens: sens,
              interface: interface,
              coteACote: coteACote,
              multiple: multiple,
            );
            expect(tester.takeException(), isNull);
            expect(motsCoupes(tester, find.byType(ChoiceCardGroup)), isEmpty);
          });
        }
      }
    }
  }

  testWidgets('390 x1 : la liste garde icone, texte et radio sur une rangee', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      largeur: 390,
      echelle: 1,
      sens: TextDirection.ltr,
      interface: InterfaceMode.standard,
    );
    expect(tester.takeException(), isNull);
    final Rect libelle = tester.getRect(
      find.text(t.controleur.compteRendu.rienASignaler),
    );
    final Rect icone = tester.getRect(
      find.byIcon(AppIcons.succes.resoudre(selectionne: true)).first,
    );
    // L'icone est a cote du libelle, pas au-dessus.
    expect(icone.right, lessThanOrEqualTo(libelle.left));
    expect(motsCoupes(tester, find.byType(ChoiceCardGroup)), isEmpty);
  });

  testWidgets('320 x2 : l icone passe au-dessus du texte, qui garde x2', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      largeur: 320,
      echelle: 2,
      sens: TextDirection.ltr,
      interface: InterfaceMode.standard,
    );
    final Rect libelle = tester.getRect(
      find.text(t.controleur.compteRendu.rienASignaler),
    );
    final Rect icone = tester.getRect(
      find.byIcon(AppIcons.succes.resoudre(selectionne: true)).first,
    );
    expect(icone.bottom, lessThanOrEqualTo(libelle.top));
  });
}
