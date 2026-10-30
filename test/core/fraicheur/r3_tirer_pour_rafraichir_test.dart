// R3 (30/10/2026) : au telephone, rien ne se rafraichissait. Une page qui
// defile se tire vers le bas pour relire (`PageShell`, relecture posee par
// `RelectureGenerale`) ; le retour sur un onglet ou dans l'application relit,
// au plus toutes les 10 s.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/fraicheur/relecture_page.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../../support/harnais.dart';

/// Une page courte : son contenu tient dans l'ecran.
Widget _page({bool defilante = true}) => PageShell(
  titre: 'Accueil',
  defilante: defilante,
  child: const SizedBox(height: 80, child: Text('contenu')),
);

void main() {
  late int relectures;
  late DateTime maintenant;

  List<Override> surcharges() => <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    relectureGeneraleProvider.overrideWithValue(() => relectures++),
  ];

  setUp(() {
    relectures = 0;
    maintenant = DateTime(2026, 10, 30, 18);
  });

  testWidgets('tirer une page courte vers le bas la relit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(RelectureGenerale(child: _page()), surcharges: surcharges()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(find.text('contenu'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(relectures, 1);
  });

  testWidgets('une page montee seule, ou qui ne defile pas, ne se tire pas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hote(_page(), surcharges: surcharges()));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);

    await tester.pumpWidget(
      hote(
        RelectureGenerale(child: _page(defilante: false)),
        surcharges: surcharges(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('le retour sur un onglet relit, au plus toutes les 10 s', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        RelectureGenerale(horloge: () => maintenant, child: _page()),
        surcharges: surcharges(),
      ),
    );
    await tester.pumpAndSettle();
    final VoidCallback auRetour = RelecturePage.auRetourDe(
      tester.element(find.byType(PageShell)),
    )!;

    auRetour();
    expect(relectures, 1);
    maintenant = maintenant.add(const Duration(seconds: 5));
    auRetour();
    expect(relectures, 1, reason: 'onglets en rafale : une seule relecture');
    maintenant = maintenant.add(const Duration(seconds: 6));
    auRetour();
    expect(relectures, 2);
  });

  testWidgets('le retour dans l application relit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        RelectureGenerale(horloge: () => maintenant, child: _page()),
        surcharges: surcharges(),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(relectures, 1);
  });
}
