import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';

import '../../support/garde_interface.dart';
import '../../support/hote_theme.dart';

/// AVATAR-1 : une ligne de liste dont la tete est un avatar (cahier, fiche de
/// classe, membres du foyer, camarades) garde le nom centre sur le cercle.
void main() {
  const String nom = 'Abderrahmane';
  const String legende = 'Coran, reprise page 12';

  for (final Size vue in <Size>[const Size(320, 640), const Size(1440, 900)]) {
    for (final double echelle in <double>[1, 2]) {
      final String ou = '${vue.width.toInt()} px, texte x${echelle.toInt()}';

      testWidgets('ligne avec avatar : nom centre sur le cercle, $ou', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: nom,
                  meneur: AvatarTile(prenom: nom, diametre: AppAvatar.petit),
                ),
              ],
            ),
            echelleTexte: echelle,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'debordement');
        verifierAlignes(tester, find.byType(AvatarTile), find.text(nom));
      });

      testWidgets('ligne avec avatar, nom et legende : centres ensemble, $ou', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: nom,
                  legende: legende,
                  meneur: AvatarTile(prenom: nom, diametre: AppAvatar.moyen),
                ),
              ],
            ),
            echelleTexte: echelle,
          ),
        );
        expect(tester.takeException(), isNull, reason: 'debordement');
        final Rect n = tester.getRect(find.text(nom));
        final Rect l = tester.getRect(find.text(legende));
        final double milieuTexte = (n.top + l.bottom) / 2;
        final double milieuCercle = tester
            .getRect(find.byType(AvatarTile))
            .center
            .dy;
        expect((milieuTexte - milieuCercle).abs(), lessThanOrEqualTo(2));
      });
    }
  }
}
