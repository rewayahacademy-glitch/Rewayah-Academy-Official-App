// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : l'onglet Messages de la barre
// montre seulement le nombre de messages recus non lus, en pastille. Le
// compteur de `Destination` est facultatif : nul par defaut, rien ne change
// pour les autres roles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/badge_non_lu.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

Widget _page(int? compteur) => hote(
  NavShell(
    destinations: <Destination>[
      const Destination(
        libelle: 'Dossier',
        icone: AppIcons.dossiers,
        chemin: '/a',
      ),
      Destination(
        libelle: 'Messages',
        icone: AppIcons.discussion,
        chemin: '/b',
        compteur: compteur,
        compteurLu: compteur == null ? null : '$compteur messages non lus',
      ),
      const Destination(
        libelle: 'Academie',
        icone: AppIcons.apprendre,
        chemin: '/c',
      ),
    ],
    indexActif: 0,
    onAller: (_) {},
    child: const PageShell(titre: 'Page', child: SizedBox(height: 40)),
  ),
  surcharges: <Override>[sansPersonneConnectee()],
);

void main() {
  for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
    final String l = '${taille.width.toInt()}';
    testWidgets('$l : sans compteur, aucune pastille', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page(null));
      await tester.pumpAndSettle();
      expect(find.byType(PastilleNombre), findsNothing);
      expect(find.byKey(NavShell.cleCompteur('/b')), findsNothing);
    });

    testWidgets('$l : un compteur pose la pastille et se dit au lecteur', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final SemanticsHandle lecteur = tester.ensureSemantics();
      await tester.pumpWidget(_page(3));
      await tester.pumpAndSettle();
      expect(find.byKey(NavShell.cleCompteur('/b')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(NavShell.cleCompteur('/b')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Messages, 3 messages non lus$')),
        findsOneWidget,
      );
      lecteur.dispose();
    });

    testWidgets('$l : 0 ne pose rien ; au-dela du plafond, le plafond et +', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page(0));
      await tester.pumpAndSettle();
      expect(find.byType(PastilleNombre), findsNothing);
      await tester.pumpWidget(_page(250));
      await tester.pumpAndSettle();
      expect(find.text(PastilleNombre.texte(250)), findsOneWidget);
    });
  }
}
