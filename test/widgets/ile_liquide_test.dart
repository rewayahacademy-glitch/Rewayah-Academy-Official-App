// ILE-SALLE (directeur, 11/11/2026) : l'ile liquide. Sa forme suit son
// contenu sur les ressorts de l'effet liquide, sans jamais depasser sa cible
// (aucun rebond) ; la dimension qui change le plus arrive la premiere (la
// capsule s'etire puis se reforme) ; miroir arabe ; « reduire les
// animations » : changement immediat ; le contenu sortant d'un fondu ne
// retient pas la forme.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/ile_liquide.dart';

const Key _ile = Key('ile');
const Key _contenu = Key('contenu');
const double _marge = 8;

Widget _hote(
  Size contenu, {
  bool reduit = false,
  TextDirection sens = TextDirection.ltr,
  Object? cleFondu,
}) {
  final Widget boite = SizedBox(
    key: _contenu,
    width: contenu.width,
    height: contenu.height,
  );
  return MediaQuery(
    data: MediaQueryData(size: const Size(800, 600), disableAnimations: reduit),
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: Directionality(
        textDirection: sens,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: IleLiquide(
            key: _ile,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(_marge),
            child: cleFondu == null
                ? boite
                : FonduLiquide(cle: cleFondu, child: boite),
          ),
        ),
      ),
    ),
  );
}

Size _taille(WidgetTester tester) {
  final Size s = tester.getSize(find.byKey(_ile));
  return Size(s.width, s.height);
}

/// Les tailles de l'ile image par image, jusqu'au repos.
Future<List<Size>> _film(WidgetTester tester) async {
  final List<Size> images = <Size>[];
  for (int i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    images.add(_taille(tester));
  }
  return images;
}

void main() {
  testWidgets('depart : la taille du contenu et de sa marge, sans mouvement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const Size(100, 20)));
    expect(_taille(tester), const Size(116, 36));
  });

  testWidgets('croissance : la capsule arrive a sa cible sans la depasser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const Size(100, 20)));
    await tester.pumpWidget(_hote(const Size(220, 60)));
    final List<Size> images = await _film(tester);
    double avantL = 0;
    double avantH = 0;
    for (final Size s in images) {
      expect(s.width, lessThanOrEqualTo(236));
      expect(s.height, lessThanOrEqualTo(76));
      // Un seul sens : jamais de retour en arriere (aucun tremblement).
      expect(s.width, greaterThanOrEqualTo(avantL));
      expect(s.height, greaterThanOrEqualTo(avantH));
      avantL = s.width;
      avantH = s.height;
    }
    await tester.pumpAndSettle();
    expect(_taille(tester), const Size(236, 76));
  });

  testWidgets('la dimension qui change le plus part la premiere : la capsule '
      's etire, puis se reforme', (WidgetTester tester) async {
    await tester.pumpWidget(_hote(const Size(100, 20)));
    await tester.pumpWidget(_hote(const Size(300, 40)));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 64));
    final Size s = _taille(tester);
    final double avanceL = (s.width - 116) / (316 - 116);
    final double avanceH = (s.height - 36) / (56 - 36);
    expect(avanceL, greaterThan(avanceH));
  });

  testWidgets('retrait : la capsule rejoint sa cible sans passer dessous', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const Size(220, 60)));
    await tester.pumpWidget(_hote(const Size(100, 20)));
    final List<Size> images = await _film(tester);
    for (final Size s in images) {
      expect(s.width, greaterThanOrEqualTo(116));
      expect(s.height, greaterThanOrEqualTo(36));
    }
    await tester.pumpAndSettle();
    expect(_taille(tester), const Size(116, 36));
  });

  testWidgets('reduire les animations : la nouvelle taille d un coup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_hote(const Size(100, 20), reduit: true));
    await tester.pumpWidget(_hote(const Size(220, 60), reduit: true));
    expect(_taille(tester), const Size(236, 76));
  });

  testWidgets('arabe : le contenu se pose au bord de debut, a droite', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _hote(const Size(100, 20), sens: TextDirection.rtl),
    );
    final Rect ile = tester.getRect(find.byKey(_ile));
    final Rect contenu = tester.getRect(find.byKey(_contenu));
    expect(ile.right, 800);
    expect(contenu.right, 800 - _marge);
  });

  testWidgets('fondu : le contenu sortant ne retient pas la forme, elle part '
      'tout de suite vers l entrant', (WidgetTester tester) async {
    await tester.pumpWidget(_hote(const Size(220, 20), cleFondu: 'a'));
    await tester.pumpWidget(_hote(const Size(100, 20), cleFondu: 'b'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 48));
    expect(_taille(tester).width, lessThan(236));
    await tester.pumpAndSettle();
    expect(_taille(tester), const Size(116, 36));
    expect(find.byKey(_contenu), findsOneWidget);
  });
}
