import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_outils/couleur_intention.dart';
import 'package:rewayah_academy/core/tc_outils/intention_pedagogique.dart';
import 'package:rewayah_academy/core/tc_outils/libelles_outils.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/tc_dock/puce_intention.dart';

import 'support/hote_d.dart';

void main() {
  group('la couleur derive de l intention', () {
    test('les cinq intentions ont cinq familles distinctes', () {
      final Set<TonEtat> tons = <TonEtat>{
        for (final IntentionPedagogique intention
            in IntentionPedagogique.values)
          CouleurIntention.ton(intention),
      };
      expect(tons.length, IntentionPedagogique.values.length);
    });

    test('les cinq intentions ont cinq encres distinctes', () {
      final AppPalette palette = AppPalette.claire();
      final Set<Color> couleurs = <Color>{
        for (final IntentionPedagogique intention
            in IntentionPedagogique.values)
          CouleurIntention.encre(palette, intention).couleur(),
      };
      expect(couleurs.length, IntentionPedagogique.values.length);
    });

    test('la derivation tient dans les deux themes', () {
      for (final IntentionPedagogique intention
          in IntentionPedagogique.values) {
        expect(
          CouleurIntention.encre(AppPalette.claire(), intention).couleur(),
          isNot(
            CouleurIntention.encre(AppPalette.sombre(), intention).couleur(),
          ),
          reason:
              'une intention prend l encre de SON theme, pas une teinte '
              'figee : sinon le mode sombre porterait les couleurs du clair',
        );
      }
    });

    test(
      'le surligneur voile la meme encre, il n en choisit pas une autre',
      () {
        final AppPalette palette = AppPalette.claire();
        final EncreIntention encre = CouleurIntention.encre(
          palette,
          IntentionPedagogique.aRenforcer,
        );
        expect(encre.couleur(opacite: 0.32).a, closeTo(0.32, 0.01));
        expect(encre.couleur(opacite: 0.32).r, encre.couleur().r);
        expect(encre.couleur(opacite: 0.32).g, encre.couleur().g);
        expect(encre.couleur(opacite: 0.32).b, encre.couleur().b);
      },
    );

    test('les cinq libelles sont ceux de la spec 8.2', () {
      expect(
        <String>[
          for (final IntentionPedagogique intention
              in IntentionPedagogique.values)
            libelleIntentionPedagogique(intention),
        ],
        <String>[
          'À apprendre',
          'À revoir',
          'À renforcer',
          'À entretenir',
          "Pour l'évaluation",
        ],
      );
    });

    test('les valeurs SQL font l aller-retour, et refusent l inconnu', () {
      for (final IntentionPedagogique intention
          in IntentionPedagogique.values) {
        expect(IntentionPedagogique.depuisSql(intention.valeurSql), intention);
      }
      expect(IntentionPedagogique.depuisSql('rouge'), isNull);
      expect(IntentionPedagogique.depuisSql(null), isNull);
    });
  });

  testWidgets('une intention ne se rend jamais en couleur seule', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteD(
        Column(
          children: <Widget>[
            for (final IntentionPedagogique intention
                in IntentionPedagogique.values)
              PuceIntention(intention: intention),
          ],
        ),
      ),
    );

    // Le mot est present pour chacune des cinq : c'est l'invariant J7, et il
    // est tenu par construction puisque `StatusPill` exige un libelle.
    for (final IntentionPedagogique intention in IntentionPedagogique.values) {
      expect(find.text(libelleIntentionPedagogique(intention)), findsOneWidget);
    }
  });
}
