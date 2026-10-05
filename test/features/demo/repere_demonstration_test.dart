// P2-07, P2-10, SUPERPOS-1 : le repere « Démonstration » de l'apercu.
//
// SUPERPOS-1 (05/10/2026, decision prise par delegation) : le repere ne
// recouvre plus rien. Il etait un ruban d'angle peint par-dessus
// l'application (`Banner`) ; a 320 en texte double, il couvrait le bouton du
// compte de la coquille. Il est desormais une bande en tete, dans le flux :
// l'application est poussee dessous. Contre-epreuve faite sur l'ancien code :
// « aucun recouvrement » echoue (le ruban couvre le bouton de fin), « la
// bande pousse l'application » echoue (aucune bande).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../support/garde_interface.dart';

const Key _boutonFin = ValueKey<String>('bouton-fin');
const Key _titre = ValueKey<String>('titre');

/// Une page dont le titre est au debut et un bouton de 48 au bout de la
/// premiere ligne, comme la coquille admin (menu ... compte).
Widget _page({
  required Size taille,
  required double echelle,
  required TextDirection sens,
  EdgeInsets zoneSure = EdgeInsets.zero,
}) => ProviderScope(
  child: MediaQuery(
    data: MediaQueryData(
      size: taille,
      padding: zoneSure,
      viewPadding: zoneSure,
      textScaler: TextScaler.linear(echelle),
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: sens,
        child: RepereDemonstration(child: child),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const OfflineBanner.message(message: 'Pas de reseau.'),
              Row(
                children: <Widget>[
                  const Expanded(child: Text('Dossiers', key: _titre)),
                  SizedBox.square(
                    key: _boutonFin,
                    dimension: 48,
                    child: Semantics(button: true, label: 'Compte'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final (Size, double, TextDirection) cas
      in <(Size, double, TextDirection)>[
        (const Size(320, 640), 2, TextDirection.ltr),
        (const Size(320, 640), 2, TextDirection.rtl),
        (const Size(390, 844), 1, TextDirection.ltr),
        (const Size(1440, 900), 1, TextDirection.ltr),
      ]) {
    final String nom =
        '${cas.$1.width.toInt()} x${cas.$2.toInt()} ${cas.$3.name}';

    testWidgets('$nom : le repere ne recouvre ni le titre, ni le bouton de '
        'fin, ni le bandeau hors ligne', (WidgetTester tester) async {
      tester.view.physicalSize = cas.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _page(taille: cas.$1, echelle: cas.$2, sens: cas.$3),
      );
      final Finder repere = find.byKey(RepereDemonstration.bandeKey);
      expect(repere, findsOneWidget);
      verifierSansChevauchement(tester, <Finder>[
        repere,
        find.byKey(_titre),
        find.byKey(_boutonFin),
        find.byType(OfflineBanner),
      ]);
      // Le mot reste entier : une seule ligne, dans l'ecran.
      final Rect mot = tester.getRect(
        find.descendant(
          of: repere,
          matching: find.text(libelleRepereDemonstration),
        ),
      );
      expect(mot.left, greaterThanOrEqualTo(0));
      expect(mot.right, lessThanOrEqualTo(cas.$1.width));
    });
  }

  testWidgets('la bande porte la zone sure du haut et pousse l application '
      'dessous', (WidgetTester tester) async {
    const Size taille = Size(390, 844);
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _page(
        taille: taille,
        echelle: 1,
        sens: TextDirection.ltr,
        zoneSure: const EdgeInsets.only(top: 47),
      ),
    );
    final Rect bande = tester.getRect(find.byKey(RepereDemonstration.bandeKey));
    expect(bande.top, 0);
    // Le texte de la bande est sous la barre d'etat.
    expect(
      tester.getRect(find.text(libelleRepereDemonstration)).top,
      greaterThanOrEqualTo(47),
    );
    // L'application commence sous la bande, sans redoubler la zone sure.
    final Rect hors = tester.getRect(find.byType(OfflineBanner));
    expect(hors.top, closeTo(bande.bottom, toleranceGarde));
  });

  testWidgets('le repere est annonce au lecteur d ecran (P2-10)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        builder: (BuildContext context, Widget? child) =>
            RepereDemonstration(child: child),
        home: const Text('accueil'),
      ),
    );
    expect(find.text('accueil'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Mode $libelleRepereDemonstration'),
      findsOneWidget,
    );
    semantique.dispose();
  });
}
