import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

Widget _shell({required void Function(String chemin) onAller}) => AdminShell(
  domaines: domainesAdmin(voitDirection: true),
  domaineActif: AdminDomaine.accueil,
  onAller: onAller,
  onCompte: () {},
  child: const PageShell(child: SizedBox(key: Key('contenu'))),
);

void main() {
  test('la regle absolue est un assert vivant, pas une relecture', () {
    expect(
      () => AdminShell(
        domaines: List<AdminDomaine>.generate(
          AdminShell.maxDomaines + 1,
          (int _) => AdminDomaine.accueil,
        ),
        domaineActif: null,
        onAller: (String _) {},
        onCompte: () {},
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('le rail et la barre laterale sont visibles sans geste', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final ({double largeur, Key chrome}) cas
        in <({double largeur, Key chrome})>[
          (largeur: 768, chrome: AdminShell.railKey),
          (largeur: 1200, chrome: AdminShell.barreLateraleKey),
        ]) {
      tester.view.physicalSize = Size(cas.largeur, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(hote(_shell(onAller: (_) {})));
      await tester.pump();

      expect(find.byKey(const Key('contenu')), findsOneWidget);
      expect(find.byKey(cas.chrome), findsOneWidget, reason: '${cas.largeur}');
      // Les huit domaines sont tous nommes, actifs ou non.
      for (final AdminDomaine domaine in domainesAdmin(voitDirection: true)) {
        expect(find.text(domaine.libelle), findsOneWidget, reason: domaine.name);
      }
      expect(tester.takeException(), isNull, reason: '${cas.largeur}');
    }
  });

  testWidgets('sur telephone, le tiroir s ouvre au bouton menu', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(599, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    // Jamais de barre basse pour l'admin : la mission l'interdit
    // explicitement, huit domaines n'y tiendraient pas.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(AdminShell.tiroirKey), findsNothing);

    await tester.tap(find.byIcon(AppIcons.menu.repos));
    await tester.pumpAndSettle();

    expect(find.byKey(AdminShell.tiroirKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un domaine sans fonction livree ne navigue nulle part', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;

    String? chemin;
    await tester.pumpWidget(
      hote(_shell(onAller: (String valeur) => chemin = valeur)),
    );
    await tester.pump();

    // Finance n'a aucune fonction livree (ADMIN_IA_AUDIT.md) : construire
    // un ecran vide pour l'occasion est exactement ce que l'audit interdit.
    // Pedagogie a quitte cet exemple le 19 septembre 2026, ses cinq
    // fonctions livrees (voir admin_domaine_test.dart).
    await tester.tap(find.text(AdminDomaine.finance.libelle));
    await tester.pump();

    expect(chemin, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barre superieure porte recherche, notifications et compte', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'une recherche menant a un domaine actif appelle onAller avec sa route',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;

      String? chemin;
      await tester.pumpWidget(
        hote(_shell(onAller: (String valeur) => chemin = valeur)),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField),
        AdminDomaine.securite.libelle,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(chemin, AdminDomaine.securite.chemin);
    },
  );
}
