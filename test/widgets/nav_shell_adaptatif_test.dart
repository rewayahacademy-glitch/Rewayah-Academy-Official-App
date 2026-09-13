import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

const List<Destination> _destinations = <Destination>[
  Destination(libelle: 'Accueil', icone: AppIcons.accueil, chemin: '/accueil'),
  Destination(libelle: 'Suivi', icone: AppIcons.suivi, chemin: '/suivi'),
  Destination(
    libelle: 'Réglages',
    icone: AppIcons.reglages,
    chemin: '/reglages',
  ),
  Destination(libelle: 'Profil', icone: AppIcons.profil, chemin: '/profil'),
];

Widget _shell({required void Function(String chemin) onAller}) => NavShell(
  destinations: _destinations,
  indexActif: 0,
  onAller: onAller,
  child: const PageShell(child: SizedBox(key: Key('contenu'))),
);

void main() {
  test('les seuils du shell correspondent aux quatre classes R2', () {
    expect(AppGabarit.pour(599), Gabarit.mobile);
    expect(AppGabarit.pour(600), Gabarit.tablette);
    expect(AppGabarit.pour(839), Gabarit.tablette);
    expect(AppGabarit.pour(840), Gabarit.tablette);
    expect(AppGabarit.pour(1199), Gabarit.tablette);
    expect(AppGabarit.pour(1200), Gabarit.desktop);

    expect(AppGabarit.margePour(390), AppSpacing.lg);
    expect(AppGabarit.margePour(768), AppSpacing.xxl);
    expect(AppGabarit.margePour(1440), AppSpacing.xxxl);
  });

  testWidgets('le chrome change sans modifier le contenu aux seuils R2', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final ({double largeur, Key chrome, double? largeurChrome}) cas
        in <({double largeur, Key chrome, double? largeurChrome})>[
          (largeur: 599, chrome: NavShell.barreBasseKey, largeurChrome: null),
          (
            largeur: 600,
            chrome: NavShell.railKey,
            largeurChrome: AppGabarit.largeurRail,
          ),
          (
            largeur: 1199,
            chrome: NavShell.railKey,
            largeurChrome: AppGabarit.largeurRail,
          ),
          (
            largeur: 1200,
            chrome: NavShell.barreLateraleKey,
            largeurChrome: AppGabarit.largeurBarreLaterale,
          ),
        ]) {
      tester.view.physicalSize = Size(cas.largeur, 720);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(hote(_shell(onAller: (_) {})));
      await tester.pump();

      expect(find.byKey(const Key('contenu')), findsOneWidget);
      expect(find.byKey(cas.chrome), findsOneWidget, reason: '${cas.largeur}');
      if (cas.largeurChrome != null) {
        expect(tester.getSize(find.byKey(cas.chrome)).width, cas.largeurChrome);
      }
      expect(tester.takeException(), isNull, reason: '${cas.largeur}');
    }
  });

  testWidgets('la destination conserve son contrat de chemin au clavier', (
    WidgetTester tester,
  ) async {
    String? chemin;
    await tester.pumpWidget(
      hote(_shell(onAller: (String valeur) => chemin = valeur)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(chemin, '/accueil');
  });

  testWidgets('le shell reste sans débordement à 200 % et en RTL', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 360);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      hote(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _shell(onAller: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
