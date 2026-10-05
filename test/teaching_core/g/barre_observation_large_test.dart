// PAGESHELL-200-1, reserve 2 de la revue OBS-COUPE-1b (4 octobre 2026) : en
// mode large (D1 : son a gauche, agrandir au centre, quitter a droite),
// texte agrandi, « Agrandir » gardait sa largeur propre au centre et
// « Quitter » (parfois « Son interrompu ») se lisait coupe. Avec les polices
// du depot, l'ancienne barre coupait de 400 a 500 px de barre, de 200 a
// 300 % de texte. La barre passe desormais en deux rangees quand une seule
// ne tient pas, et garde D1 la ou elle tient.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/barre_commandes_observation.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (double largeur = 400; largeur <= 640; largeur += 40) {
    for (final double echelle in const <double>[1, 2, 2.5, 3]) {
      for (final TextDirection sens in TextDirection.values) {
        for (final bool sonRecu in const <bool>[true, false]) {
          for (final bool agrandi in const <bool>[false, true]) {
            testWidgets('barre large de ${largeur.toInt()} px, texte '
                'x$echelle, ${sens.name}, '
                '${sonRecu ? 'son recu' : 'son interrompu'}, '
                '${agrandi ? 'agrandi' : 'normal'}', (
              WidgetTester tester,
            ) async {
              tester.view.physicalSize = Size(largeur + 200, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                hote(
                  Builder(
                    builder: (BuildContext context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(echelle)),
                      child: Directionality(
                        textDirection: sens,
                        child: Scaffold(
                          body: Center(
                            child: SizedBox(
                              width: largeur,
                              child: BarreCommandesObservation(
                                sonRecu: sonRecu,
                                agrandi: agrandi,
                                onAgrandir: () {},
                                onQuitter: () {},
                                large: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
              final Finder barre = find.byType(BarreCommandesObservation);
              final Rect cadre = tester.getRect(barre);
              final v = t.tc.observation.visite;
              final String centre = agrandi ? v.reduire : v.agrandir;
              for (final String libelle in <String>[
                sonRecu ? v.sonRecu : v.sonInterrompu,
                centre,
                v.quitter,
              ]) {
                final Finder texte = find.descendant(
                  of: barre,
                  matching: find.text(libelle),
                );
                expect(texte, findsOneWidget);
                final Rect r = tester.getRect(texte);
                expect(
                  r.left >= cadre.left - 0.5 && r.right <= cadre.right + 0.5,
                  isTrue,
                  reason: '« $libelle » sort de la barre : $r dans $cadre',
                );
              }
              verifierAucunMotCoupe(tester, barre);
              // D1 reste tenue la ou elle tient : texte a 100 %, les trois
              // commandes sur une seule rangee.
              if (echelle == 1) {
                expect(
                  tester.getCenter(find.text(v.quitter)).dy,
                  moreOrLessEquals(
                    tester.getCenter(find.text(centre)).dy,
                    epsilon: 4,
                  ),
                );
              }
            });
          }
        }
      }
    }
  }
}
