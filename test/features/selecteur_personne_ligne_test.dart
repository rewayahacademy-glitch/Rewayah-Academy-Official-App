// FORM-MINEURS : a 320 de large en texte x2, l'identifiant d'une carte de
// personne tient sur une seule ligne (« ELV- / MS-010 » coupait au tiret).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;

void main() {
  setUpAll(chargerPolicesDuDepot);

  testWidgets('320 x2 : l\'identifiant de chaque carte tient sur une ligne', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(640, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    const List<PersonneProposee> gens = <PersonneProposee>[
      PersonneProposee(id: 'a', nom: 'Maryam Sow', identifiant: 'ELV-MS-010'),
      PersonneProposee(
        id: 'b',
        nom: 'Abdourahmane Diallo-Barry',
        identifiant: 'ELV-AD-011',
      ),
      PersonneProposee(
        id: 'c',
        nom: 'Fatoumata Bah',
        identifiant: 'ELV-FB-012',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                // Largeur utile de la page jeton a 320 (gouttieres et carte).
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: SelecteurPersonne(
                  sorte: SortePersonne.observable,
                  personnes: const AsyncValue<List<PersonneProposee>>.data(
                    gens,
                  ),
                  choisie: null,
                  onChoix: (_) {},
                  onReessayer: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final PersonneProposee p in gens) {
      // Insensible au tiret : la meme assertion vaut avant et apres la correction.
      final Finder f = find.byWidgetPredicate(
        (Widget w) =>
            w is Text && w.data?.replaceAll('\u2011', '-') == p.identifiant,
      );
      expect(f, findsOneWidget, reason: p.identifiant);
      final Size taille = tester.getSize(f);
      final double ligne = tester
          .renderObject<RenderParagraph>(f)
          .text
          .style!
          .fontSize!;
      // Une seule ligne : hauteur inferieure a deux fois la taille de police x2 (echelle)
      // (interligne compris), texte mis a l'echelle x2.
      expect(taille.height, lessThan(ligne * 2 * 2), reason: p.identifiant);
    }
  });
}
