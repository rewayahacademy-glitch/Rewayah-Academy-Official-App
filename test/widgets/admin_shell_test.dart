import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
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
        expect(
          find.text(domaine.libelle),
          findsOneWidget,
          reason: domaine.name,
        );
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

  testWidgets('des 600, pas de barre superieure : actions dans l en-tete', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    // Aucun champ visible : la recherche est un bouton qui ouvre la feuille.
    expect(find.byType(TextField), findsNothing);
    expect(find.bySemanticsLabel(t.nav.admin.recherche), findsOneWidget);
    expect(find.bySemanticsLabel(t.nav.compte), findsOneWidget);
    expect(find.bySemanticsLabel(t.commun.theme.sombre), findsOneWidget);
    // Pas de cloche tant qu'aucun service de notifications n'existe (Q5).
    expect(find.byIcon(AppIcons.notifications.repos), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sous 600, le champ de recherche est dans la barre mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(599, 900);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(hote(_shell(onAller: (_) {})));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(AppIcons.notifications.repos), findsNothing);
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

      await tester.tap(find.bySemanticsLabel(t.nav.admin.recherche));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        AdminDomaine.securite.libelle,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(chemin, AdminDomaine.securite.chemin);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('la barre 288 porte Rewayah et le pied, pas le rail', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(1200, 900);
    int comptes = 0;
    await tester.pumpWidget(
      hote(
        AdminShell(
          domaines: domainesAdmin(voitDirection: false),
          domaineActif: AdminDomaine.accueil,
          onAller: (_) {},
          onCompte: () => comptes++,
          child: const PageShell(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(t.nav.motSymbole), findsOneWidget);
    expect(find.text(t.compte.roles.admin), findsOneWidget);
    expect(find.text(t.admin.comptes.roleAdmin), findsOneWidget);
    await tester.tap(find.text(t.compte.roles.admin));
    await tester.pump();
    expect(comptes, 1);

    // L'etat actif porte aussi la graisse, pas seulement la couleur.
    final Text actif = tester.widget<Text>(
      find.text(AdminDomaine.accueil.libelle),
    );
    final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.byWidget(actif),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(style.style.fontWeight, FontWeight.w600);

    tester.view.physicalSize = const Size(768, 900);
    await tester.pump();
    expect(find.byKey(AdminShell.railKey), findsOneWidget);
    expect(find.text(t.nav.motSymbole), findsNothing);
    expect(find.text(t.admin.comptes.roleAdmin), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le retour de la coquille s affiche dans l en-tete', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;

    int retours = 0;
    await tester.pumpWidget(
      hote(
        AdminShell(
          domaines: domainesAdmin(voitDirection: false),
          domaineActif: AdminDomaine.personnes,
          onAller: (_) {},
          onCompte: () {},
          onRetour: () => retours++,
          child: const PageShell(titre: 'Titre', child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(DisqueRetour));
    await tester.pump();
    expect(retours, 1);
  });
}
