// CORAN-CARTE-2 : la ligne lien posee dans une carte (titre, legende,
// chevron). Un seul lien nomme par le titre, le chevron au bord de fin (miroir
// en RTL), aucun mot coupe a 200 %, une cible de la largeur de la ligne.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/widgets/ligne_lien.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

const Key _ligne = ValueKey<String>('ligne');
const String _titre = 'Le Coran';
const String _legende = 'A lire quand tu veux, chaque jour, sans attendre';

void main() {
  setUpAll(chargerPolicesDuDepot);

  Future<int> monter(
    WidgetTester tester, {
    double echelle = 1,
    TextDirection sens = TextDirection.ltr,
    double largeur = 320,
  }) async {
    int ouvertures = 0;
    fixerVueCapture(tester, Size(largeur, 640), 1);
    await tester.pumpWidget(
      hoteCapture(
        Directionality(
          textDirection: sens,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: LigneLien(
                  key: _ligne,
                  titre: _titre,
                  legende: _legende,
                  onPress: () => ouvertures++,
                ),
              ),
            ),
          ),
        ),
        echelleTexte: echelle,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_legende));
    return ouvertures;
  }

  Finder chevron() => find.descendant(
    of: find.byKey(_ligne),
    matching: find.byIcon(AppIcons.chevron.repos),
  );

  testWidgets('un seul lien, nomme par le titre, legende lue a la suite', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    expect(await monter(tester), 1);
    final Finder lien = find.bySemanticsLabel(RegExp('^$_titre'));
    expect(lien, findsOneWidget);
    final SemanticsNode noeud = tester.getSemantics(lien);
    expect(noeud.label, '$_titre\n$_legende');
    expect(noeud.flagsCollection.isLink, isTrue);
    expect(noeud.flagsCollection.isButton, isFalse);
    poignee.dispose();
  });

  for (final TextDirection sens in TextDirection.values) {
    testWidgets(
      '${sens.name} : chevron au bord de fin, titre au bord de debut',
      (WidgetTester tester) async {
        await monter(tester, sens: sens);
        final Rect ligne = tester.getRect(find.byKey(_ligne));
        final Rect c = tester.getRect(chevron());
        final Rect titre = tester.getRect(find.text(_titre));
        expect(
          ligne.width,
          320 - 32,
          reason: 'la ligne prend toute la largeur',
        );
        expect(ligne.height, greaterThanOrEqualTo(48));
        if (sens == TextDirection.ltr) {
          expect(c.right, ligne.right);
          expect(titre.left, ligne.left);
        } else {
          expect(c.left, ligne.left);
          expect(titre.right, ligne.right);
        }
      },
    );
  }

  testWidgets('texte x2 a 320 : aucun mot coupe, aucun debordement', (
    WidgetTester tester,
  ) async {
    await monter(tester, echelle: 2);
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(_ligne),
        matching: find.byType(TexteSansCoupure),
      ),
      findsNWidgets(2),
    );
    verifierAucunMotCoupe(tester, find.byKey(_ligne));
    expect(chevron(), findsOneWidget);
  });
}
