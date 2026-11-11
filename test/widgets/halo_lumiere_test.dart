// HALO 2a-bis (pilote, 11/11/2026 ; conditions du garde-cap) : la lumiere du
// halo, cercle ou rectangle arrondi, et l'arbitre de l'ecran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';

import '../support/harnais.dart';

const Size _carte = Size(240, 96);

Widget _scene(Widget enfant, {bool reduit = false}) => hote(
  Builder(
    builder: (BuildContext contexte) => MediaQuery(
      data: MediaQuery.of(contexte).copyWith(disableAnimations: reduit),
      child: Center(child: enfant),
    ),
  ),
);

Finder _lumieres() => find.byKey(HaloLumiere.lumiereKey);
Finder _lueurs() => find.byKey(HaloLumiere.lueurKey);

double _ratio(Color a, Color b) {
  final double la = a.computeLuminance() + 0.05;
  final double lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  group('NatureHalo : l ordre de l arbitre et WCAG 2.2.2', () {
    test('rouge > vert > orange > bleu', () {
      expect(NatureHalo.values, <NatureHalo>[
        NatureHalo.urgent,
        NatureHalo.salle,
        NatureHalo.aPreparer,
        NatureHalo.nouveau,
      ]);
    });

    test('toute lumiere s arrete avant cinq secondes', () {
      for (final NatureHalo n in NatureHalo.values) {
        expect(
          n.dureeTour * n.tours <= const Duration(seconds: 5),
          isTrue,
          reason: n.name,
        );
      }
    });

    test('a preparer : orange, pastille lisible (icone blanche, 4,5:1)', () {
      final AppColorPair p = CouleursHalo.aPreparer.pastille;
      expect(NatureHalo.aPreparer.couleurs, CouleursHalo.aPreparer);
      expect(_ratio(p.background, p.onBackground), greaterThanOrEqualTo(4.5));
    });
  });

  group('HaloLumiere : rectangle arrondi', () {
    testWidgets('elle tourne, puis devient une lueur fixe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scene(
          const HaloLumiere(
            nature: NatureHalo.aPreparer,
            forme: FormeHalo.rectangle,
            taille: _carte,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_lumieres(), findsOneWidget);
      expect(tester.getSize(_lumieres()), _carte);
      // LUMIERE-DOUCE (11/11/2026) : autour d'une carte, la lumiere suit
      // la duree des cartes, quelle que soit la nature (2 x 2 400 ms).
      await tester.pump(
        AppMouvement.tourHaloCarte * AppMouvement.toursHaloCarte,
      );
      await tester.pump();
      expect(_lumieres(), findsNothing);
      expect(_lueurs(), findsOneWidget);
      expect(tester.getSize(_lueurs()), _carte);
    });

    testWidgets('mouvement reduit : la lueur fixe d emblee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scene(
          const HaloLumiere(
            nature: NatureHalo.aPreparer,
            forme: FormeHalo.rectangle,
            taille: _carte,
          ),
          reduit: true,
        ),
      );
      await tester.pump();
      expect(_lumieres(), findsNothing);
      expect(_lueurs(), findsOneWidget);
    });
  });

  group('ArbitreLumieres : une seule lumiere tourne par ecran', () {
    Widget deux({required bool avecUrgence, bool arbitre = true}) {
      final Widget rangee = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HaloLumiere(
            key: ValueKey<String>('bleu'),
            nature: NatureHalo.nouveau,
            taille: Size.square(48),
          ),
          const HaloLumiere(
            key: ValueKey<String>('orange'),
            nature: NatureHalo.aPreparer,
            forme: FormeHalo.rectangle,
            taille: _carte,
          ),
          if (avecUrgence)
            const HaloLumiere(
              key: ValueKey<String>('rouge'),
              nature: NatureHalo.urgent,
              taille: Size.square(48),
            ),
        ],
      );
      return _scene(arbitre ? ArbitreLumieres(child: rangee) : rangee);
    }

    Finder dans(String cle, Finder quoi) =>
        find.descendant(of: find.byKey(ValueKey<String>(cle)), matching: quoi);

    testWidgets('la plus prioritaire tourne, les autres en lueur fixe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(deux(avecUrgence: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_lumieres(), findsOneWidget);
      expect(dans('rouge', _lumieres()), findsOneWidget);
      expect(dans('orange', _lueurs()), findsOneWidget);
      expect(dans('bleu', _lueurs()), findsOneWidget);
    });

    testWidgets('l urgence partie, la suivante (orange) tourne a son tour', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(deux(avecUrgence: true));
      await tester.pump();
      await tester.pumpWidget(deux(avecUrgence: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_lumieres(), findsOneWidget);
      expect(dans('orange', _lumieres()), findsOneWidget);
      expect(dans('bleu', _lueurs()), findsOneWidget);
    });

    testWidgets('sans arbitre, chaque lumiere tourne seule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(deux(avecUrgence: true, arbitre: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_lumieres(), findsNWidgets(3));
    });
  });

  testWidgets('la direction (AdminShell) pose aussi l arbitre, une fois', (
    WidgetTester tester,
  ) async {
    final List<EtatArbitreLumieres?> vus = <EtatArbitreLumieres?>[];
    await tester.pumpWidget(
      hote(
        AdminShell(
          domaines: domainesAdmin(voitDirection: true),
          domaineActif: AdminDomaine.accueil,
          onAller: (String _) {},
          onCompte: () {},
          child: Builder(
            builder: (BuildContext contexte) {
              vus.add(ArbitreLumieres.de(contexte));
              return const SizedBox();
            },
          ),
        ),
        surcharges: <Override>[sansPersonneConnectee()],
      ),
    );
    await tester.pump();
    expect(vus.last, isNotNull);
  });
}
