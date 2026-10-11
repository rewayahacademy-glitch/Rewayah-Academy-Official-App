// Verification TB (10/10, TB-9) : en francais, la ponctuation haute (? ! : ;)
// ne passe jamais seule a la ligne. L'espace qui la precede est insecable
// (U+00A0, la convention de fr.i18n.json) dans les domaines de la salle et
// du Teaching Core ; et, sur le rendu, a 320 px texte x2, le « ? » de
// « Effacer toutes les notes de cette page ? » reste sur la ligne de « page ».

import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../capture/outil_capture.dart' hide stabiliser;

Map<String, String> _aplatir(Object? valeur, String prefixe) {
  if (valeur is Map<String, dynamic>) {
    return <String, String>{
      for (final MapEntry<String, dynamic> e in valeur.entries)
        ..._aplatir(e.value, prefixe.isEmpty ? e.key : '$prefixe.${e.key}'),
    };
  }
  return valeur is String ? <String, String>{prefixe: valeur} : {};
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Le haut de la ligne ou se dessine le caractere [i] de [p].
double _ligne(RenderParagraph p, int i) => p
    .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
    .first
    .top;

void main() {
  setUpAll(chargerPolicesDuDepot);

  test(
    'salle.*, tc.*, destructif.* : aucune espace ordinaire avant ? ! : ;',
    () {
      final Map<String, String> fr = _aplatir(
        jsonDecode(File('assets/i18n/fr.i18n.json').readAsStringSync()),
        '',
      );
      final List<String> fautes = <String>[
        for (final MapEntry<String, String> e in fr.entries)
          if (RegExp(r'^(salle|tc|destructif)\.').hasMatch(e.key) &&
              RegExp(r' [?!:;]').hasMatch(e.value))
            e.key,
      ];
      expect(fautes, isEmpty);
    },
  );

  for (final (String nom, SituationTb situation, String Function() question)
      in <(String, SituationTb, String Function())>[
        (
          'page',
          SituationTb.dlg01,
          () => t.salle.seance.rangement.questionPage,
        ),
        (
          'tableau',
          SituationTb.effacementTableau,
          () => t.salle.seance.rangement.questionTableau,
        ),
      ]) {
    testWidgets('320 x2 : le « ? » de la question ($nom) reste avec son mot', (
      WidgetTester tester,
    ) async {
      // Les vraies polices du depot et la densite du harnais (tb9_) : la
      // police de test, plus large, ne coupe pas les lignes au meme endroit.
      fixerVueCapture(tester, const Size(320, 700), 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(role: RoleSeance.enseignant, situation: situation),
          echelleTexte: 2,
        ),
      );
      await tester.pumpAndSettle();
      await _taper(tester, find.byKey(DeclencheurCommandes.cle));
      await _taper(tester, find.byKey(CommandesPedagogiques.cleMenu));
      await _taper(tester, find.text(t.salle.seance.rangement.effacer).last);
      final List<RenderParagraph> paragraphes = <RenderParagraph>[
        for (final RenderParagraph p
            in tester.allRenderObjects.whereType<RenderParagraph>())
          if (p.text.toPlainText(includeSemanticsLabels: false) == question())
            p,
      ];
      expect(paragraphes, isNotEmpty);
      for (final RenderParagraph p in paragraphes) {
        final String texte = p.text.toPlainText(includeSemanticsLabels: false);
        final int point = texte.length - 1;
        expect(texte[point], '?');
        expect(texte[point - 1], ' ');
        // Le dernier caractere du mot qui precede (avant l'espace) et le
        // « ? » sont sur la meme ligne.
        expect(_ligne(p, point), _ligne(p, point - 2), reason: texte);
      }
    });
  }
}
