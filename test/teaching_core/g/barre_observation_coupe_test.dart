// OBS-COUPE-1 : la barre de commandes de la salle d'observation ne coupe
// aucun mot, de 320 a 390 px, texte a 100 % et a 200 %, de gauche a droite
// et de droite a gauche (« Q/u/i/t/t/e/r », « Agrand/ir », « Son interr/ompu »
// relevés sur af20f6c2).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/barre_commandes_observation.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final double largeur in const <double>[320, 390]) {
    for (final double echelle in const <double>[1, 2]) {
      for (final TextDirection sens in TextDirection.values) {
        for (final bool sonRecu in const <bool>[true, false]) {
          testWidgets(
            '${largeur.toInt()} px, texte x${echelle.toInt()}, ${sens.name}, '
            '${sonRecu ? 'son recu' : 'son interrompu'}',
            (WidgetTester tester) async {
              tester.view.physicalSize = Size(largeur, 800);
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
                          body: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: BarreCommandesObservation(
                                sonRecu: sonRecu,
                                agrandi: false,
                                onAgrandir: () {},
                                onQuitter: () {},
                                large: false,
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
              final v = t.tc.observation.visite;
              // La mesure porte sur quelque chose : les trois libelles.
              for (final String libelle in <String>[
                sonRecu ? v.sonRecu : v.sonInterrompu,
                v.agrandir,
                v.quitter,
              ]) {
                expect(
                  find.descendant(of: barre, matching: find.text(libelle)),
                  findsOneWidget,
                );
              }
              verifierAucunMotCoupe(tester, barre);
              // La maquette M4 reste tenue la ou elle tient : a 390 px et
              // texte a 100 %, les trois commandes sur une seule rangee.
              if (largeur == 390 && echelle == 1) {
                expect(
                  tester.getCenter(find.text(v.quitter)).dy,
                  moreOrLessEquals(
                    tester.getCenter(find.text(v.agrandir)).dy,
                    epsilon: 4,
                  ),
                );
              }
              // La barre laisse la salle a la salle : jamais plus d'un tiers
              // de la hauteur d'un telephone.
              expect(tester.getSize(barre).height, lessThan(800 / 3));
            },
          );
        }
      }
    }
  }
}
