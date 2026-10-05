// CPT-RC (M1 de la revue CPT-R) : la route de demonstration REELLE, montee
// comme l'app en preproduction, c'est-a-dire `routesDemoComptable('staging')`
// dans un `ProviderScope` SANS AUCUNE surcharge a la racine. Les ports de
// demonstration ne sont poses que par la `ProviderScope` imbriquee de
// `CoquilleComptableDemo` : chaque fournisseur derive qui lit un port doit
// donc declarer `dependencies:`, sinon il est resolu a la racine, lit le port
// `...Indisponible` et l'operateur voit « en preparation » ou « Pas encore
// disponible » au lieu des donnees de demonstration.
//
// Ce test echoue sur 8fb00a71 (8 ecrans sur 16 vides).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';

import '../../../support/harnais.dart';

/// Les textes des etats « port indisponible » : aucun ne doit apparaitre sur
/// la demonstration.
List<String> _textesIndisponibles() => <String>[
  t.comptable.commun.enPreparationTitre,
  'en préparation',
  'Pas encore disponible',
];

void main() {
  for (final EcranDemoComptable ecran in EcranDemoComptable.values) {
    if (ecran == EcranDemoComptable.reserveDelegation) continue;
    for (final Size taille in const <Size>[Size(390, 844), Size(1440, 900)]) {
      testWidgets(
        'route reelle ${ecran.name} a ${taille.width.toInt()} : les donnees '
        'de demonstration, jamais un etat indisponible',
        (WidgetTester tester) async {
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            hoteRoutant(
              depart: adresseDemoComptable(ecran),
              routes: routesDemoComptable('staging'),
            ),
          );
          await tester.pumpAndSettle();

          // Seul un debordement de gabarit est tolere ici : la police de test
          // (Ahem, un carre par glyphe) elargit tout texte bien au-dela de la
          // vraie police ; les gabarits sont recettes par les captures. Toute
          // autre exception (fournisseur, port) fait echouer.
          final Object? exception = tester.takeException();
          expect(
            exception == null || '$exception'.contains('overflowed'),
            isTrue,
            reason: '${ecran.name} : $exception',
          );
          for (final String texte in _textesIndisponibles()) {
            expect(
              find.textContaining(texte, findRichText: true),
              findsNothing,
              reason: '${ecran.name} affiche « $texte »',
            );
          }
          // Le contenu de l'ecran est bien la, pas un ecran blanc.
          expect(find.byType(Text), findsWidgets);
        },
      );
    }
  }
}
