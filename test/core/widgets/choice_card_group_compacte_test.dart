// CANDIDATURE-UX (directeur, 14/11/2026) : dans une longue liste (langue
// maternelle : des centaines de choix), les cartes etaient enormes (5 par
// ecran) et chaque toucher gelait l'ecran environ 1 s. `ChoiceCardGroup.compacte`
// pose des lignes de 48 a 56 ; et au-dela de `maxVoisins` options, une carte
// ne mesure plus les mots de toutes les autres (N x N mesures a chaque toucher).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

Future<void> _monter(
  WidgetTester tester,
  Widget enfant, {
  double largeur = 390,
  double echelle = 1,
}) async {
  tester.view.physicalSize = Size(largeur, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(largeur, 4000),
          textScaler: TextScaler.linear(echelle),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: enfant,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<OptionChoix> _options(int n) => <OptionChoix>[
  for (int i = 0; i < n; i++)
    OptionChoix(
      valeur: 'l$i',
      libelle: 'Langue numero $i',
      cle: ValueKey<String>('l$i'),
    ),
];

const List<ElementChoix> _riwayat = <ElementChoix>[
  ElementChoix(code: 'hafs', libelle: 'Hafs', cle: ValueKey<String>('hafs')),
  ElementChoix(code: 'warsh', libelle: 'Warsh', cle: ValueKey<String>('warsh')),
  ElementChoix(
    code: 'qalun',
    libelle: 'Qaloun',
    cle: ValueKey<String>('qalun'),
  ),
  ElementChoix(code: 'rawh', libelle: 'Rawh', cle: ValueKey<String>('rawh')),
];

const TextesRecherche _textes = TextesRecherche(
  recherche: 'Rechercher',
  aide: 'Nom',
  aucun: 'Aucune',
  retour: 'Revenir',
  autre: 'Une autre riwaya',
);

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('les lignes compactes font de 48 a 56 et sont a 16', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      ChoiceCardGroup(
        compacte: true,
        autoriserSaisieLibre: false,
        options: _options(12),
        onChange: (ReponseChoix _) {},
      ),
    );
    for (int i = 0; i < 12; i++) {
      final double h = tester
          .getSize(find.byKey(ValueKey<String>('l$i')))
          .height;
      expect(h, inInclusiveRange(48, 56), reason: 'ligne $i : $h');
    }
    final double ecart =
        tester.getTopLeft(find.byKey(const ValueKey<String>('l1'))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey<String>('l0'))).dy;
    expect(ecart, 16);
  });

  testWidgets('a 320 en texte x2 : aucun mot coupe', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      ChoiceCardGroup(
        compacte: true,
        autoriserSaisieLibre: false,
        options: _options(6),
        onChange: (ReponseChoix _) {},
      ),
      largeur: 320,
      echelle: 2,
    );
    expect(tester.takeException(), isNull);
    verifierAucunMotCoupe(tester, find.byType(ChoiceCardGroup));
  });

  testWidgets('trois cents options : un toucher retient tout de suite', (
    WidgetTester tester,
  ) async {
    final List<Set<String>> recus = <Set<String>>[];
    await _monter(
      tester,
      ChoiceCardGroup(
        autoriserSaisieLibre: false,
        options: _options(300),
        onChange: (ReponseChoix r) => recus.add(r.valeurs),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('l3')));
    await tester.pump();
    expect(recus.single, <String>{'l3'});
  });

  group('« toutes les riwayat », exclusive', () {
    Future<ValueNotifier<Set<String>>> monterRiwayat(
      WidgetTester tester,
    ) async {
      final ValueNotifier<Set<String>> selection = ValueNotifier<Set<String>>(
        <String>{},
      );
      await _monter(
        tester,
        ValueListenableBuilder<Set<String>>(
          valueListenable: selection,
          builder: (BuildContext _, Set<String> s, Widget? _) =>
              ChoixAvecRecherche(
                cle: 'riwayat',
                multiple: true,
                rechercheEnTete: false,
                toutes: const ElementChoix(
                  code: ChoixAvecRecherche.valeurToutes,
                  libelle: 'Je recite toutes les riwayat',
                  cle: ValueKey<String>('toutes'),
                ),
                courants: _riwayat.take(3).toList(),
                tous: _riwayat,
                selection: s,
                textes: _textes,
                onChange: (Set<String> v) => selection.value = v,
              ),
        ),
      );
      return selection;
    }

    testWidgets('toutes retient chaque code, une autre ligne la remplace', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Set<String>> s = await monterRiwayat(tester);
      // L'ordre : toutes, les connues, puis la recherche dessous.
      final double yToutes = tester
          .getTopLeft(find.byKey(const ValueKey<String>('toutes')))
          .dy;
      final double yHafs = tester
          .getTopLeft(find.byKey(const ValueKey<String>('hafs')))
          .dy;
      final double yChamp = tester
          .getTopLeft(find.byKey(ChoixAvecRecherche.champKey))
          .dy;
      expect(yToutes, lessThan(yHafs));
      expect(yHafs, lessThan(yChamp));
      expect(find.text('Une autre riwaya'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('toutes')));
      await tester.pumpAndSettle();
      expect(s.value, <String>{'hafs', 'warsh', 'qalun', 'rawh'});
      // Retenue, elle se voit seule cochee ; Rawh n'est pas ajoutee en ligne.
      expect(find.byKey(const ValueKey<String>('rawh')), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('warsh')));
      await tester.pumpAndSettle();
      expect(s.value, <String>{'warsh'});

      await tester.tap(find.byKey(const ValueKey<String>('toutes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('toutes')));
      await tester.pumpAndSettle();
      expect(s.value, isEmpty, reason: 'la retirer vide tout');
    });

    testWidgets('« Une autre riwaya » : la recherche trouve Rawh', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Set<String>> s = await monterRiwayat(tester);
      await tester.enterText(find.byKey(ChoixAvecRecherche.champKey), 'raw');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rawh')));
      await tester.pumpAndSettle();
      expect(s.value, <String>{'rawh'});
    });
  });
}
