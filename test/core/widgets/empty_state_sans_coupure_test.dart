// ELV-VIDE-COUPE-1 : l'etat vide partage (`EmptyState`) ne coupe aucun mot,
// meme a 320 px et texte x2, en mode standard comme en Interface guidee, en
// LTR comme en RTL. Avant la correction, « Pas de cours aujourd'hui » rendait
// « aujourd'hu / i » (standard) et « aujour / d'hui » (Interface guidee) sur
// l'accueil eleve, et l'invitation coupait « enseignant ».
//
// Le constat et l'invitation passent par `TexteSansCoupure` : a l'echelle 1,
// ou chaque mot tient, le rendu ne change pas (echelle de l'appareil gardee).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

const String _message = "Pas de cours aujourd'hui";
const String _invitation = 'Ton enseignant prépare le prochain.';

void main() {
  setUpAll(chargerPolicesDuDepot);

  Future<void> monter(
    WidgetTester tester, {
    double echelle = 1,
    TextDirection sens = TextDirection.ltr,
    double largeur = 320,
    InterfaceMode mode = InterfaceMode.standard,
  }) async {
    fixerVueCapture(tester, Size(largeur, 900), 1);
    await tester.pumpWidget(
      hoteCapture(
        Directionality(
          textDirection: sens,
          child: const Scaffold(
            body: EmptyState(
              message: _message,
              invitation: _invitation,
              registre: RegistreVide.subi,
            ),
          ),
        ),
        echelleTexte: echelle,
        interfaceMode: mode,
      ),
    );
    await tester.pumpAndSettle();
  }

  RenderParagraph paragraphe(WidgetTester tester, String texte) =>
      tester.renderObject<RenderParagraph>(find.text(texte));

  for (final InterfaceMode mode in InterfaceMode.values) {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${mode.name}, 320 px, texte x2, ${sens.name} : '
          'aucun mot coupe, aucun debordement', (WidgetTester tester) async {
        await monter(tester, echelle: 2, sens: sens, mode: mode);
        expect(tester.takeException(), isNull);
        expect(find.byType(TexteSansCoupure), findsNWidgets(2));
        verifierAucunMotCoupe(tester, find.byType(EmptyState));
        // Le texte reste agrandi : la reduction est bornee, jamais un retour
        // silencieux a la taille du theme.
        expect(
          paragraphe(tester, _message).textScaler.scale(1),
          greaterThanOrEqualTo(echelleMinimaleLisible),
        );
      });
    }
  }

  testWidgets('echelle 1 : rendu inchange, echelle de l appareil gardee', (
    WidgetTester tester,
  ) async {
    await monter(tester, largeur: 390);
    for (final String texte in <String>[_message, _invitation]) {
      final RenderParagraph p = paragraphe(tester, texte);
      expect(p.textScaler.scale(1), 1);
      expect(p.textAlign, TextAlign.center);
    }
  });

  testWidgets('texte x2 a 390 px : l echelle de l appareil est gardee', (
    WidgetTester tester,
  ) async {
    await monter(tester, largeur: 390, echelle: 2);
    expect(paragraphe(tester, _invitation).textScaler.scale(1), 2);
    verifierAucunMotCoupe(tester, find.byType(EmptyState));
  });
}
