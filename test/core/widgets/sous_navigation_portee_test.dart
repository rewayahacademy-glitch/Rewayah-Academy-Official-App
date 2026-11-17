// BE-2b : la coquille annonce les pages qu'elle laisse ouvrir ; la
// sous-navigation retire les autres sections, sans qu'une page lise un role.
// Portee fermee (une seule page) : aucun onglet reserve. Portee absente : tout.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/admin/sous_liens_coquille.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';

import '../../support/harnais.dart';

Widget _page({Set<String>? ouvertes}) {
  final Widget nav = SousNavigationDomaine(
    onglets: ongletsPersonnes(),
    indexActif: 2,
  );
  return hote(
    Scaffold(
      body: ouvertes == null
          ? nav
          : PagesOuvertesCoquille(chemins: ouvertes, child: nav),
    ),
  );
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('portee absente : les onglets de Personnes sont proposes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_page());
    final SelecteurSection<int> sel = tester.widget(
      find.byType(SelecteurSection<int>),
    );
    expect(sel.sections.length, ongletsPersonnes().length);
  });

  testWidgets(
    'portee fermee (candidatures seules) : onglets reserves absents',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1500, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _page(ouvertes: <String>{Routes.adminPersonnesCandidatures}),
      );
      expect(find.text(t.admin.comptes.titre), findsNothing);
      expect(find.text(t.dossiers.titre), findsNothing);
      expect(find.text(t.admin.suppressions.onglet), findsNothing);
    },
  );

  testWidgets(
    'portee a deux pages : seules ces pages restent, l\'active suit',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1500, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _page(
          ouvertes: <String>{
            Routes.adminPersonnesCandidatures,
            Routes.adminPersonnesComptes,
          },
        ),
      );
      expect(find.text(t.admin.comptes.titre), findsWidgets);
      expect(find.text(t.admin.candidatures.titre), findsWidgets);
      expect(find.text(t.dossiers.titre), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
