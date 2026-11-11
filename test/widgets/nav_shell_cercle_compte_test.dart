// NAV-REFONTE, etape 1 (decisions du directeur du 09/11/2026) : la barre
// flottante du telephone porte les onglets du role dans une pilule, et le
// Compte dans un cercle a sa fin, avec la photo ou l'initiale de la personne.
// Seul l'onglet ouvert montre son nom ; les autres n'ont que leur icone, nom
// lu et en infobulle. En Mode Accessibilite, tous les noms restent visibles et
// le cercle devient une tuile nommee (MA-NAV-1).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/cercle_selectionnable.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart';

List<Destination> _tuteur(InterfaceMode mode) =>
    destinationsPour(role: AppRole.guardian, mode: mode);

Widget _barre({
  required List<Destination> destinations,
  required int? indexActif,
  void Function(String chemin)? onAller,
  InterfaceMode mode = InterfaceMode.standard,
  TextDirection direction = TextDirection.ltr,
}) => hote(
  Directionality(
    textDirection: direction,
    child: NavShell(
      destinations: destinations,
      indexActif: indexActif,
      onAller: onAller ?? (_) {},
      child: const PageShell(child: SizedBox(key: Key('contenu'))),
    ),
  ),
  surcharges: <Override>[sansPersonneConnectee()],
  mode: mode,
);

void _vue(WidgetTester tester, Size taille, {double texte = 1}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder _dansBarre(Finder f) =>
    find.descendant(of: find.byKey(NavShell.barreBasseKey), matching: f);

void main() {
  test('une seule destination Compte par role NavShell', () {
    for (final AppRole role in <AppRole>[
      AppRole.guardian,
      AppRole.student,
      AppRole.teacher,
      AppRole.controller,
      AppRole.accountant,
    ]) {
      final List<Destination> d = destinationsPour(
        role: role,
        mode: InterfaceMode.standard,
      );
      expect(d.where((Destination x) => x.compte).length, 1, reason: '$role');
      // Le Compte vient en dernier : la pilule garde l'ordre des autres.
      expect(d.last.compte, isTrue, reason: '$role');
    }
    final List<Destination> adulte = destinationsPour(
      role: AppRole.student,
      mode: InterfaceMode.standard,
      eleveAdulte: true,
    );
    expect(
      adulte.where((Destination x) => x.compte).single.libelle,
      t.nav.eleve.profil,
    );
  });

  test(
    "enseignant : Aujourd'hui, Classes, Messages, puis le cercle Compte",
    () {
      final List<Destination> d = destinationsPour(
        role: AppRole.teacher,
        mode: InterfaceMode.standard,
      );
      expect(d.map((Destination x) => x.chemin).toList(), <String>[
        Routes.enseignantJournee,
        Routes.enseignantClasses,
        Routes.enseignantMessages,
        Routes.enseignantProfil,
      ]);
      expect(d.last.libelle, t.nav.enseignant.compte);
      // Les disponibilites ne sont plus une destination.
      expect(
        d.any((Destination x) => x.chemin == Routes.enseignantCreneaux),
        isFalse,
      );
    },
  );

  testWidgets('390 : seul l\'onglet ouvert montre son nom, le cercle est '
      'nomme « Compte »', (WidgetTester tester) async {
    _vue(tester, const Size(390, 844));
    final List<Destination> d = _tuteur(InterfaceMode.standard);
    await tester.pumpWidget(_barre(destinations: d, indexActif: 1));
    await tester.pump();

    // Foyer ouvert : son nom se voit ; Accueil et Historique, non.
    expect(_dansBarre(find.text(t.nav.tuteur.foyer)), findsOneWidget);
    expect(_dansBarre(find.text(t.nav.tuteur.accueil)), findsNothing);
    expect(_dansBarre(find.text(t.nav.tuteur.historique)), findsNothing);
    // Les noms restent lus par le lecteur d'ecran.
    expect(find.bySemanticsLabel(t.nav.tuteur.accueil), findsOneWidget);
    expect(find.bySemanticsLabel(t.nav.tuteur.historique), findsOneWidget);
    expect(find.bySemanticsLabel(t.nav.tuteur.compte), findsOneWidget);
    // Le Compte n'est pas un onglet de la pilule : pas de nom ecrit.
    expect(_dansBarre(find.text(t.nav.tuteur.compte)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le cercle est a la fin : a droite, et a gauche en arabe', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    final List<Destination> d = _tuteur(InterfaceMode.standard);
    for (final TextDirection sens in TextDirection.values) {
      await tester.pumpWidget(
        _barre(destinations: d, indexActif: 0, direction: sens),
      );
      await tester.pump();
      final Rect cercle = tester.getRect(
        find.bySemanticsLabel(t.nav.tuteur.compte),
      );
      final Rect accueil = tester.getRect(
        find.bySemanticsLabel(t.nav.tuteur.accueil),
      );
      if (sens == TextDirection.ltr) {
        expect(cercle.left, greaterThan(accueil.right));
      } else {
        expect(cercle.right, lessThan(accueil.left));
      }
      // La barre ne touche ni les bords ni le bas.
      final Rect barre = tester.getRect(
        find
            .descendant(
              of: find.byKey(NavShell.barreBasseKey),
              matching: find.byType(Row),
            )
            .first,
      );
      expect(barre.left, greaterThan(0));
      expect(barre.right, lessThan(390));
      expect(barre.bottom, lessThan(844));
    }
  });

  testWidgets('toucher le cercle mene au Compte', (WidgetTester tester) async {
    _vue(tester, const Size(390, 844));
    String? alle;
    await tester.pumpWidget(
      _barre(
        destinations: _tuteur(InterfaceMode.standard),
        indexActif: 0,
        onAller: (String c) => alle = c,
      ),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(t.nav.tuteur.compte));
    expect(alle, Routes.tuteurCompte);
  });

  testWidgets('320 en texte x2 : le nom ouvert passe sous l\'icone, rien ne '
      'deborde', (WidgetTester tester) async {
    _vue(tester, const Size(320, 700), texte: 2);
    await tester.pumpWidget(
      _barre(destinations: _tuteur(InterfaceMode.standard), indexActif: 2),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_dansBarre(find.text(t.nav.tuteur.historique)), findsOneWidget);
  });

  testWidgets('Mode Accessibilite : tous les noms visibles, tuile Compte '
      'nommee', (WidgetTester tester) async {
    _vue(tester, const Size(390, 844));
    await tester.pumpWidget(
      _barre(
        destinations: _tuteur(InterfaceMode.enfant),
        indexActif: 0,
        mode: InterfaceMode.enfant,
      ),
    );
    await tester.pump();
    for (final String nom in <String>[
      t.nav.tuteur.accueil,
      t.nav.tuteur.foyer,
      t.nav.tuteur.historique,
      t.nav.tuteur.compte,
    ]) {
      expect(_dansBarre(find.text(nom)), findsOneWidget, reason: nom);
    }
    expect(tester.takeException(), isNull);
  });

  // Decisions du directeur du 10/11/2026 : non choisi, un rond de 58 et une
  // photo de 48 ; choisi, un rond de 64 et une photo de 52, bord d'accent ;
  // le passage suit un ressort ; 8 au moins jusqu'au bord de l'ecran et
  // jusqu'a la pilule, verifie a 320 en texte x2.
  Rect rondDessine(WidgetTester tester) => tester.getRect(
    find
        .descendant(
          of: find.byType(CercleSelectionnable),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  Rect photo(WidgetTester tester) => tester.getRect(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.byType(AvatarTile),
    ),
  );

  for (final (Size taille, double texte) cas in <(Size, double)>[
    (const Size(320, 700), 2),
    (const Size(320, 700), 1),
    (const Size(390, 844), 1),
  ]) {
    testWidgets('${cas.$1.width.toInt()}, texte x${cas.$2} : choisi, rond de '
        '64 et photo de 52, avec 8 de marge', (WidgetTester tester) async {
      _vue(tester, cas.$1, texte: cas.$2);
      final List<Destination> d = _tuteur(InterfaceMode.standard);
      await tester.pumpWidget(_barre(destinations: d, indexActif: 3));
      await tester.pumpAndSettle();
      final Rect rond = rondDessine(tester);
      expect(rond.width, closeTo(64, 0.5));
      expect(photo(tester).width, closeTo(52, 0.5));
      // Le bord de la pilule : la place qu'elle prend dans la rangee.
      final Rect pilule = tester.getRect(
        find
            .ancestor(
              of: find.bySemanticsLabel(t.nav.tuteur.historique),
              matching: find.byType(Expanded),
            )
            .first,
      );
      expect(rond.left - pilule.right, greaterThanOrEqualTo(8));
      expect(cas.$1.width - rond.right, greaterThanOrEqualTo(8));
      expect(cas.$1.height - rond.bottom, greaterThanOrEqualTo(8));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('non choisi : rond de 58, photo de 48 ; au ressort vers 64', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    final List<Destination> d = _tuteur(InterfaceMode.standard);
    await tester.pumpWidget(_barre(destinations: d, indexActif: 0));
    await tester.pumpAndSettle();
    expect(rondDessine(tester).width, closeTo(58, 0.5));
    expect(photo(tester).width, closeTo(48, 0.5));
    // Le passage n'est pas un saut : a mi-chemin, entre les deux tailles.
    await tester.pumpWidget(_barre(destinations: d, indexActif: 3));
    await tester.pump(const Duration(milliseconds: 60));
    final double milieu = rondDessine(tester).width;
    expect(milieu, greaterThan(58));
    expect(milieu, lessThan(64));
    await tester.pumpAndSettle();
    expect(rondDessine(tester).width, closeTo(64, 0.5));
    // Jamais au-dela : le ressort ne rebondit pas.
    expect(rondDessine(tester).width, lessThanOrEqualTo(64.01));
  });

  testWidgets('mouvement reduit : le passage est immediat', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(390, 844));
    final List<Destination> d = _tuteur(InterfaceMode.standard);
    Widget reduit(int i) => MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      child: _barre(destinations: d, indexActif: i),
    );
    await tester.pumpWidget(reduit(0));
    await tester.pump();
    await tester.pumpWidget(reduit(3));
    await tester.pump();
    expect(rondDessine(tester).width, closeTo(64, 0.5));
  });
}
