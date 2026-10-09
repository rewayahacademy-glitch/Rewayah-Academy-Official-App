// FILTRES-1 : le composant `RangeeFiltres` seul. Une rangee, des puces de
// meme hauteur, une barre de defilement des qu'elle deborde (et seulement
// alors), un libelle trop long qui passe a la ligne entre ses mots, un mot
// plus large que la rangee jamais coupe, le debut au debut du sens de lecture.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/sens_et_echelle.dart';

Future<void> _monter(
  WidgetTester tester,
  List<String> libelles, {
  int? retenue,
  double largeur = 320,
  double echelle = 2,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      builder: sensEtEchelle(direction: sens, echelle: echelle),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RangeeFiltres(
                filtres: <Widget>[
                  for (final String l in libelles)
                    FilterPill(
                      libelle: l,
                      compteur: 3,
                      retenue: libelles.indexOf(l) == retenue,
                      onPress: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Rect> _boites(WidgetTester tester) => <Rect>[
  for (final Element e in find.byType(FilterPill).evaluate())
    tester.getRect(find.byWidget(e.widget)),
];

bool _barreVisible(WidgetTester tester) => tester
    .widget<Scrollbar>(
      find.descendant(
        of: find.byType(RangeeFiltres),
        matching: find.byType(Scrollbar),
      ),
    )
    .thumbVisibility!;

/// Vrai quand un bord de la rangee s'efface.
bool _fondu(WidgetTester tester) =>
    tester
        .widget<ShaderMask>(
          find.descendant(
            of: find.byType(RangeeFiltres),
            matching: find.byType(ShaderMask),
          ),
        )
        .blendMode ==
    BlendMode.dstIn;

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('tout tient : une rangee, aucune barre de defilement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>['Tous', 'Actif'], largeur: 1440, echelle: 1);
    final List<Rect> b = _boites(tester);
    expect(b[0].top, b[1].top);
    expect(_barreVisible(tester), isFalse);
    // Rien de cache : aucun fondu de bord.
    expect(_fondu(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ca deborde : une rangee, la barre de defilement se voit', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
      'Suspendu',
    ]);
    final List<Rect> b = _boites(tester);
    for (final Rect r in b) {
      expect(r.top, b.first.top);
      expect(r.height, b.first.height);
    }
    expect(_barreVisible(tester), isTrue);
    // Des puces cachees apres la fin : le bord de fin s'efface.
    expect(_fondu(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un libelle plus long que la rangee passe a la ligne entre ses '
      'mots ; toutes les puces prennent sa hauteur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Toutes les classes de la semaine',
      'Actif',
    ]);
    final List<Rect> b = _boites(tester);
    // Jamais plus large que la rangee (320 - 2 x 16).
    expect(b[0].width, lessThanOrEqualTo(288));
    expect(b[1].height, b[0].height);
    verifierAucunMotCoupe(tester, find.byType(RangeeFiltres));
    expect(tester.takeException(), isNull);
  });

  testWidgets('un mot plus large que la rangee elargit sa puce, sans coupure', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>['Anticonstitutionnellement', 'Actif']);
    expect(_boites(tester)[0].width, greaterThan(288));
    verifierAucunMotCoupe(tester, find.byType(RangeeFiltres));
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL : la rangee commence a droite', (WidgetTester tester) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
    ], sens: TextDirection.rtl);
    final List<Rect> b = _boites(tester);
    expect(b.first.right, 304);
    expect(b[1].right, lessThan(b.first.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('le filtre retenu, loin dans la rangee, se voit a l ouverture', (
    WidgetTester tester,
  ) async {
    await _monter(tester, <String>[
      'Tous',
      'En attente',
      'Actif',
      'Provisoire',
      'Suspendu',
    ], retenue: 4);
    final Rect r = _boites(tester).last;
    expect(r.left, greaterThanOrEqualTo(16));
    expect(r.right, lessThanOrEqualTo(304));
    expect(tester.takeException(), isNull);
  });
}
