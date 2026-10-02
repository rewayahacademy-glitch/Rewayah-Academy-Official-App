import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';

import '../../support/garde_interface.dart';
import '../../support/hote_theme.dart';

/// AVATAR-1 (revue du directeur des 01 et 02/10/2026) : le couple avatar + nom
/// vient d'un seul composant, et sa geometrie est mesuree, pas supposee.
void main() {
  const String nom = 'Sayyid Abderrahmane';
  const String role = 'Coran, niveau 2';

  Widget couple(DispositionAvatar d, {String? r, double diametre = 48}) =>
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: d == DispositionAvatar.vertical
            ? Center(
                child: AvatarNom.vertical(
                  prenom: 'Abderrahmane',
                  nom: nom,
                  role: r,
                  diametre: diametre,
                ),
              )
            : AvatarNom.enLigne(
                prenom: 'Abderrahmane',
                nom: nom,
                role: r,
                diametre: diametre,
              ),
      );

  final List<Size> vues = <Size>[const Size(320, 640), const Size(1440, 900)];

  for (final Size vue in vues) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        final String ou =
            '${vue.width.toInt()} px, texte x${echelle.toInt()}, ${lum.name}';

        testWidgets('vertical : avatar et nom sur le meme axe, $ou', (
          WidgetTester tester,
        ) async {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              couple(DispositionAvatar.vertical, r: role),
              echelleTexte: echelle,
              luminosite: lum,
            ),
          );
          expect(tester.takeException(), isNull, reason: 'debordement');
          verifierMemeAxe(tester, find.byType(AvatarTile), find.text(nom));
          verifierMemeAxe(tester, find.byType(AvatarTile), find.text(role));
          // Le nom est SOUS le cercle, jamais a cote.
          expect(
            tester.getRect(find.text(nom)).top,
            greaterThanOrEqualTo(
              tester.getRect(find.byType(AvatarTile)).bottom,
            ),
          );
        });

        testWidgets('en ligne : nom centre sur le cercle, $ou', (
          WidgetTester tester,
        ) async {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              couple(DispositionAvatar.enLigne),
              echelleTexte: echelle,
              luminosite: lum,
            ),
          );
          expect(tester.takeException(), isNull, reason: 'debordement');
          verifierAlignes(tester, find.byType(AvatarTile), find.text(nom));
        });

        testWidgets('en ligne : nom + role centres ensemble, $ou', (
          WidgetTester tester,
        ) async {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              couple(DispositionAvatar.enLigne, r: role),
              echelleTexte: echelle,
              luminosite: lum,
            ),
          );
          expect(tester.takeException(), isNull, reason: 'debordement');
          final Rect n = tester.getRect(find.text(nom));
          final Rect r = tester.getRect(find.text(role));
          final double milieuTexte = (n.top + r.bottom) / 2;
          final double milieuCercle = tester
              .getRect(find.byType(AvatarTile))
              .center
              .dy;
          expect((milieuTexte - milieuCercle).abs(), lessThanOrEqualTo(2));
          // Au plus une ligne de role : nom au-dessus, role dessous.
          expect(r.top, greaterThanOrEqualTo(n.bottom - toleranceGarde));
        });
      }
    }
  }

  group('jamais de carre derriere l avatar', () {
    for (final DispositionAvatar d in DispositionAvatar.values) {
      testWidgets('${d.name} : aucun fond ni cadre carre autour du cercle', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(390, 844));
        await tester.pumpWidget(hoteTheme(couple(d, r: role)));
        final Finder tuile = find.byType(AvatarTile);
        // Entre le composant et le cercle : ni fond plein, ni decoration.
        for (final Type t in <Type>[ColoredBox, DecoratedBox, Material]) {
          expect(
            find.descendant(
              of: find.byType(AvatarNom),
              matching: find.ancestor(
                of: tuile,
                matching: find.byType(t),
              ),
            ),
            findsNothing,
            reason: '$t derriere l avatar',
          );
        }
        // Le cercle se decoupe en ovale : aucun angle droit ne peint.
        expect(
          find.descendant(of: tuile, matching: find.byType(ClipOval)),
          findsOneWidget,
        );
        // Et sa tuile est carree, jamais plus large que le jeton.
        final Size taille = tester.getSize(tuile);
        expect(taille.width, taille.height);
        expect(taille.width, AppAvatar.moyen);
      });
    }
  });

  testWidgets('la taille par defaut vient des jetons', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(hoteTheme(const AvatarTile(prenom: 'Yasmine')));
    expect(tester.getSize(find.byType(AvatarTile)).width, AppAvatar.moyen);
    expect(AppAvatar.petit, lessThan(AppAvatar.moyen));
    expect(AppAvatar.moyen, lessThan(AppAvatar.grand));
  });

  group('cadre sans image : le cercle reste dans son cadre', () {
    for (final Size cadre in <Size>[
      const Size(96, 128),
      const Size(176, 126),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        testWidgets(
          '${cadre.width.toInt()}x${cadre.height.toInt()}, '
          'texte x${echelle.toInt()}',
          (WidgetTester tester) async {
            fixerVue(tester, const Size(320, 640));
            await tester.pumpWidget(
              hoteTheme(
                Center(
                  child: SizedBox.fromSize(
                    size: cadre,
                    child: const DecoratedBox(
                      key: Key('cadre'),
                      decoration: BoxDecoration(),
                      child: AvatarSansImage(
                        prenom: 'Abderrahmane',
                        legende: 'Sans image',
                      ),
                    ),
                  ),
                ),
                echelleTexte: echelle,
                defilant: false,
              ),
            );
            expect(tester.takeException(), isNull, reason: 'debordement');
            verifierContenu(
              tester,
              find.byType(AvatarTile),
              find.byKey(const Key('cadre')),
            );
            verifierMemeAxe(
              tester,
              find.byType(AvatarTile),
              find.text('Sans image'),
            );
          },
        );
      }
    }
  });
}
