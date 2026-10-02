import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';

import '../support/garde_interface.dart';
import '../support/hote_theme.dart';

/// Gardes de la revue du directeur des 01 et 02/10/2026 (K-54, K-55) sur les
/// composants partages : un defaut vu a l'ecran doit echouer ici.
void main() {
  const String court = 'Poser un creneau';
  const String long =
      'Declarer l\'absence de Yasmine pour la seance du mardi 14 octobre';

  group('K-54 : libelle de bouton centre', () {
    for (final double echelle in <double>[1, 2]) {
      for (final NiveauAction niveau in NiveauAction.values) {
        for (final bool pleine in <bool>[true, false]) {
          for (final String libelle in <String>[court, long]) {
            testWidgets(
              '${niveau.name}, pleine largeur $pleine, echelle $echelle, '
              '${libelle.length} car. a 320 px',
              (WidgetTester tester) async {
                fixerVue(tester, const Size(320, 640));
                await tester.pumpWidget(
                  hoteTheme(
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ActionPrincipale(
                          libelle: libelle,
                          onPress: () {},
                          niveau: niveau,
                          pleineLargeur: pleine,
                        ),
                      ),
                    ),
                    echelleTexte: echelle,
                  ),
                );
                verifierBoutonCentre(
                  tester,
                  find.byType(ActionPrincipale),
                  libelle,
                );
              },
            );
          }
        }
      }
    }
  });

  group('K-55 : cartes jamais collees', () {
    testWidgets('des cartes separees par Ecart passent la garde', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              AppCard(child: Text('Une')),
              Ecart.vMd,
              AppCard(child: Text('Deux')),
              Ecart.vMd,
              AppCard(child: Text('Trois')),
            ],
          ),
        ),
      );
      verifierEcartCartes(tester, find.byType(AppCard), minimum: AppSpacing.md);
    });

    testWidgets('des cartes jointives font echouer la garde', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              AppCard(child: Text('Une')),
              AppCard(child: Text('Deux')),
            ],
          ),
        ),
      );
      expect(
        () => verifierEcartCartes(
          tester,
          find.byType(AppCard),
          minimum: AppSpacing.md,
        ),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('Avatar et nom', () {
    testWidgets('les centres sont alignes sur une ligne, a 320 px', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AvatarTile(prenom: 'Yasmine', diametre: 48),
                Ecart.hMd,
                Text('Yasmine'),
              ],
            ),
          ),
        ),
      );
      verifierAlignes(
        tester,
        find.byType(AvatarTile),
        find.text('Yasmine').last,
      );
    });

    testWidgets('les initiales sont centrees dans le cercle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          const Align(
            alignment: Alignment.topLeft,
            child: AvatarTile(prenom: 'Yasmine', diametre: 48),
          ),
        ),
      );
      final Rect cercle = tester.getRect(find.byType(AvatarTile));
      final Rect initiale = tester.getRect(
        find.descendant(
          of: find.byType(AvatarTile),
          matching: find.byType(Text),
        ),
      );
      expect((initiale.center.dx - cercle.center.dx).abs(), lessThan(1.5));
      expect((initiale.center.dy - cercle.center.dy).abs(), lessThan(1.5));
    });
  });

  group('Aucun element ne recouvre un contenu', () {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('carte, titre et bouton a 320 px, echelle $echelle', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(320, 640));
        await tester.pumpWidget(
          hoteTheme(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  const Text('Seance du mardi 14 octobre', key: Key('titre')),
                  Ecart.vMd,
                  const AppCard(child: Text('Yasmine, Coran, 30 min')),
                  Ecart.vMd,
                  ActionPrincipale(libelle: court, onPress: () {}),
                ],
              ),
            ),
            echelleTexte: echelle,
          ),
        );
        verifierSansChevauchement(tester, <Finder>[
          find.byKey(const Key('titre')),
          find.byType(AppCard),
          find.byType(ActionPrincipale),
        ]);
      });
    }
  });
}
