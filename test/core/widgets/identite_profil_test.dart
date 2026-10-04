// FI-2 (decision du directeur du 04/10/2026, K-62) : l'identite d'un profil
// et son bandeau de couleur choisi par le tuteur, derriere l'avatar
// (maquette 11 « Foyer »).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';

import '../../support/hote_theme.dart';

void main() {
  Finder bandeau() => find.byKey(BandeauProfil.bandeauKey);

  testWidgets('le lecteur d ecran lit une phrase entiere', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        const IdentiteProfil(
          prenom: 'Mariam',
          accent: AccentProfil.rose,
          age: 10,
          classe: 'An-Nour',
        ),
      ),
    );
    expect(
      find.bySemanticsLabel('Mariam, profil enfant, Classe An-Nour'),
      findsOneWidget,
    );
    expect(find.text('10 ans · Classe An-Nour'), findsOneWidget);
  });

  testWidgets('profil adulte, sans classe : « Fatimah, profil adulte »', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(
        const IdentiteProfil(prenom: 'Fatimah', accent: null, estAdulte: true),
      ),
    );
    expect(find.bySemanticsLabel('Fatimah, profil adulte'), findsOneWidget);
  });

  testWidgets('sans couleur choisie : le cercle seul, aucun bandeau', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteTheme(const IdentiteProfil(prenom: 'Ibrahim', accent: null)),
    );
    expect(bandeau(), findsNothing);
    expect(find.byType(AvatarTile), findsOneWidget);
  });

  for (final Size vue in <Size>[const Size(320, 640), const Size(1440, 900)]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        final String ou =
            '${vue.width.toInt()} px, texte x${echelle.toInt()}, ${lum.name}';
        for (final TailleIdentite taille in TailleIdentite.values) {
          testWidgets('bandeau derriere le cercle, dans le bloc, '
              '${taille.name}, $ou', (WidgetTester tester) async {
            fixerVue(tester, vue);
            await tester.pumpWidget(
              hoteTheme(
                IdentiteProfil(
                  prenom: 'Mariam',
                  accent: AccentProfil.menthe,
                  age: 10,
                  classe: 'An-Nour',
                  taille: taille,
                ),
                echelleTexte: echelle,
                luminosite: lum,
              ),
            );
            expect(tester.takeException(), isNull, reason: 'debordement');
            final Rect b = tester.getRect(bandeau());
            final Rect c = tester.getRect(find.byType(AvatarTile));
            final Rect bloc = tester.getRect(find.byType(BandeauProfil));
            // Le bandeau depasse au-dessus du cercle, puis passe derriere.
            expect(b.top, lessThan(c.top));
            expect(b.bottom, greaterThan(c.top));
            expect(b.bottom, lessThan(c.bottom));
            // Centre sur le cercle, moins large que lui, jamais hors du bloc.
            expect((b.center.dx - c.center.dx).abs(), lessThan(0.5));
            expect(b.width, lessThan(c.width));
            expect(bloc.contains(b.topLeft), isTrue);
            expect(bloc.contains(b.bottomRight - const Offset(1, 1)), isTrue);
            // Le cercle est le dernier enfant de la pile : il passe devant.
            final Stack pile = tester.widget<Stack>(
              find.descendant(
                of: find.byType(BandeauProfil),
                matching: find.byType(Stack),
              ),
            );
            expect(pile.children, hasLength(2));
            expect(
              find.descendant(
                of: find.byWidget(pile.children.last),
                matching: find.byType(AvatarTile),
              ),
              findsOneWidget,
            );
            // La couleur est celle du jeton de l'accent choisi.
            final DecoratedBox boite = tester.widget<DecoratedBox>(bandeau());
            final BuildContext ctx = tester.element(bandeau());
            expect(
              (boite.decoration as BoxDecoration).color,
              AppPalette.of(ctx).accentProfil(AccentProfil.menthe).background,
            );
          });
        }
      }
    }
  }
}
