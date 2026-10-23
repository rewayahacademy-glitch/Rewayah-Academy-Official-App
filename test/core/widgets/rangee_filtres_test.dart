// FILTRES-1 : le composant `RangeeFiltres` seul. Une rangee, des puces de
// meme hauteur, une barre de defilement des qu'elle deborde (et seulement
// alors), un libelle trop long qui passe a la ligne entre ses mots, un mot
// plus large que la rangee jamais coupe, le debut au debut du sens de lecture.
// L4-07 : trois puces au plus, puis « Plus » ; le defilement horizontal, la
// barre et le fondu ne servent plus qu'en dernier recours (une puce qui,
// avec « Plus », ne tient pas dans la largeur : texte x2, mot tres long).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
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
  Brightness eclairage = Brightness.light,
  bool envelopper = false,
}) async {
  tester.view.physicalSize = Size(largeur, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, eclairage),
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
                    if (envelopper)
                      _Enveloppe(
                        libelle: l,
                        retenue: libelles.indexOf(l) == retenue,
                      )
                    else
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

/// Une puce composee, comme la pastille de personne d'Observations : une
/// `FilterPill` dans un `Semantics`, qui se declare [PuceFiltre].
class _Enveloppe extends StatelessWidget implements PuceFiltre {
  const _Enveloppe({required this.libelle, required this.retenue});

  final String libelle;

  @override
  final bool retenue;

  @override
  Widget build(BuildContext context) => Semantics(
    label: libelle,
    excludeSemantics: true,
    child: FilterPill(
      libelle: libelle,
      compteur: 3,
      retenue: retenue,
      onPress: () {},
    ),
  );
}

/// Les puces posees dans la rangee (celles qu'on peut toucher : une puce
/// rangee sous « Plus » reste dans l'arbre, ni peinte ni touchable).
List<Rect> _boites(WidgetTester tester) => <Rect>[
  for (final Element e in find.byType(FilterPill).hitTestable().evaluate())
    tester.getRect(find.byWidget(e.widget)),
];

/// Une rangee qui deborde meme avec une seule puce et « Plus » : un mot
/// plus large que la rangee (dernier recours, le defilement horizontal).
const List<String> _qUiDeborde = <String>[
  'Anticonstitutionnellement',
  'En attente',
  'Actif',
];

RawScrollbar _barre(WidgetTester tester) => tester.widget<RawScrollbar>(
  find.descendant(
    of: find.byType(RangeeFiltres),
    matching: find.byType(RawScrollbar),
  ),
);

bool _barreVisible(WidgetTester tester) => _barre(tester).thumbVisibility!;

/// Vrai quand un bord de la rangee s'efface : le masque reellement compose
/// (`ShaderMaskLayer`, COUPE-MOTS-FOND-1 : le fondu se peint par son
/// propre rendu, sans reconstruire la rangee) est actif.
bool _fondu(WidgetTester tester) {
  final Layer? calque = tester
      .renderObject(
        find.descendant(
          of: find.byType(RangeeFiltres),
          matching: find.byType(FonduBordsRangee),
        ),
      )
      .debugLayer;
  return calque is ShaderMaskLayer && calque.blendMode == BlendMode.dstIn;
}

/// Le rapport de contraste WCAG entre deux couleurs opaques.
double _contraste(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

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

  testWidgets('ca deborde meme avec Plus : la barre de defilement se voit', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _qUiDeborde);
    final List<Rect> b = _boites(tester);
    // Une puce et « Plus », sur une seule rangee, de meme hauteur ; « Plus »
    // est au-dela de la vue : la rangee defile (dernier recours).
    expect(b.length, 1);
    final Rect plus = tester.getRect(
      find.byKey(const ValueKey<String>('rangee-filtres-plus-0')),
    );
    expect(plus.top, b.first.top);
    expect(plus.height, b.first.height);
    expect(_barreVisible(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trois puces qui tiennent : ni barre ni fondu, aucun Plus', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      <String>['Tous', 'Actif', 'Suspendu'],
      largeur: 1440,
      echelle: 1,
    );
    expect(_boites(tester).length, 3);
    expect(find.text('Plus').hitTestable(), findsNothing);
    expect(_barreVisible(tester), isFalse);
    expect(_fondu(tester), isFalse);
  });

  testWidgets('au-dela de trois puces : trois puces et Plus, sans barre', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      <String>['Tous', 'En attente', 'Actif', 'Provisoire', 'Suspendu'],
      largeur: 1440,
      echelle: 1,
    );
    expect(_boites(tester).length, 4);
    expect(find.text('Plus').hitTestable(), findsOneWidget);
    expect(_barreVisible(tester), isFalse);
    expect(_fondu(tester), isFalse);
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
    // « Plus » (hors de la vue, la rangee defile) a la meme hauteur.
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('rangee-filtres-plus-0')))
          .height,
      b[0].height,
    );
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

  // FILTRES-1b (2) : la barre de defilement ne se lit pas comme le
  // soulignement d'un onglet actif : piste visible sur toute la largeur,
  // curseur et piste neutres, jamais l'accent.
  testWidgets('la barre de defilement est neutre, avec sa piste', (
    WidgetTester tester,
  ) async {
    for (final Brightness eclairage in Brightness.values) {
      await _monter(tester, _qUiDeborde, retenue: 0, eclairage: eclairage);
      final RawScrollbar barre = _barre(tester);
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(RangeeFiltres)),
      );
      final ColorScheme schema = Theme.of(
        tester.element(find.byType(RangeeFiltres)),
      ).colorScheme;
      expect(barre.trackVisibility, isTrue);
      expect(barre.trackColor, palette.borderHairline.asBorderSide().color);
      // Reprise FILTRES-1b : un curseur discret, qui se distingue de la
      // piste mais reste moins marque que le bord d'une puce (borderStrong) :
      // jamais un trait fonce sous la puce retenue.
      final Color fond = palette.surfaceCanvas.background;
      final Color bordPuce = palette.borderStrong.asBorderSide().color;
      expect(barre.thumbColor, isNot(bordPuce));
      expect(
        _contraste(barre.thumbColor!, fond),
        lessThan(_contraste(bordPuce, fond)),
      );
      expect(barre.thumbColor, isNot(barre.trackColor));
      for (final Color accent in <Color>[
        schema.primary,
        palette.inkAccent.asBorderSide().color,
      ]) {
        expect(barre.thumbColor, isNot(accent));
      }
      // Fine : moins haute que l'ecart qui la separe des puces.
      expect(barre.thickness, lessThan(AppSpacing.md));
      expect(tester.takeException(), isNull);
    }
  });

  // L4-07 : un filtre retenu qui ne tient pas dans la rangee n'est pas perdu
  // de vue : « Plus » le dit (« Plus, 1 »), a l'ouverture comme apres coup,
  // pour une `FilterPill` nue comme pour une puce composee ([PuceFiltre]).
  for (final TextDirection sens in TextDirection.values) {
    for (final bool envelopper in <bool>[false, true]) {
      testWidgets('filtre retenu range sous Plus, ${sens.name}'
          '${envelopper ? ', puce composee' : ''} : Plus le dit', (
        WidgetTester tester,
      ) async {
        const List<String> libelles = <String>[
          'Tous',
          'En attente',
          'Actif',
          'Provisoire',
          'Suspendu',
        ];
        await _monter(
          tester,
          libelles,
          sens: sens,
          envelopper: envelopper,
          echelle: 1,
        );
        expect(find.text('Plus').hitTestable(), findsOneWidget);
        await _monter(
          tester,
          libelles,
          retenue: 4,
          sens: sens,
          envelopper: envelopper,
          echelle: 1,
        );
        final Finder plus = find.text('Plus, 1').hitTestable();
        expect(plus, findsOneWidget);
        final Rect r = tester.getRect(plus);
        expect(r.left, greaterThanOrEqualTo(16 - 0.5), reason: '$r');
        expect(r.right, lessThanOrEqualTo(304 + 0.5), reason: '$r');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
