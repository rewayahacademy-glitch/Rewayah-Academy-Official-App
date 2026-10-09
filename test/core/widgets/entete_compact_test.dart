// SUPERPOS-1, reprise du relecteur : l'en-tete de page compact selon
// l'echelle HIER-1. A 320 en texte double, « Dossiers a valider » et son
// sous-titre prenaient la moitie de l'ecran, et un titre long passait sur
// quatre lignes. En mode compact, le titre reste un palier au-dessus d'un
// titre de section agrandi, le sous-titre descend d'un rang du corps, et le
// disque retour passe au-dessus quand un mot du titre ne tiendrait pas a
// cote. Mesure a 320 x2 : en-tete de 242 (38 % de 640), titre de 46.
// Contre-epreuve faite : sur l'ancien code, titre de 56 (« Dossiers a
// valider ») et titre long reduit a 43,5, sous un titre de section agrandi.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/hote_theme.dart';

const String _titre = 'Dossiers à valider';
const String _sousTitre = 'Examinez les dossiers prêts pour une décision.';

/// La taille rendue de [texte] : taille du style, a l'echelle appliquee.
double _taille(WidgetTester tester, String texte) {
  final RenderParagraph p = tester.renderObject<RenderParagraph>(
    find.byWidgetPredicate(
      (Widget w) =>
          w is RichText &&
          w.text.toPlainText().replaceAll('\u2060', '') == texte,
    ),
  );
  return p.textScaler.scale(p.text.style!.fontSize!);
}

Future<void> _poser(
  WidgetTester tester, {
  required Size vue,
  required double echelle,
  String titre = _titre,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVue(tester, vue);
  await tester.pumpWidget(
    hoteTheme(
      Directionality(
        textDirection: sens,
        child: EntetePage(titre: titre, sousTitre: _sousTitre, onRetour: () {}),
      ),
      echelleTexte: echelle,
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final TextDirection sens in TextDirection.values) {
    testWidgets('320 x2 ${sens.name} : titre un palier au-dessus d\'un titre '
        'de section agrandi, en-tete sous 40 % de l\'ecran', (
      WidgetTester tester,
    ) async {
      await _poser(tester, vue: const Size(320, 640), echelle: 2, sens: sens);
      expect(tester.takeException(), isNull);
      final double titre = _taille(tester, _titre);
      // Titre de section (22) agrandi : 44 ; corps (16) agrandi : 32.
      expect(titre, lessThan(56));
      expect(titre, greaterThan(44));
      expect(_taille(tester, _sousTitre), lessThanOrEqualTo(28));
      final double hauteur = tester.getSize(find.byType(EntetePage)).height;
      expect(hauteur, lessThanOrEqualTo(640 * 0.4), reason: 'en-tete $hauteur');
    });
  }

  testWidgets('320 x2 : un mot long passe le disque retour au-dessus, '
      'jamais reduit sous un titre de section agrandi', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      vue: const Size(320, 640),
      echelle: 2,
      titre: 'Classe Al-Badr · Jeudi 24 septembre',
    );
    expect(tester.takeException(), isNull);
    expect(
      _taille(tester, 'Classe Al-Badr · Jeudi 24 septembre'),
      greaterThan(44),
    );
    // Le nom compose reste entier : « Al- » et « Badr » sur la meme ligne
    // (avant : « Classe Al- / Badr »).
    final RenderParagraph p = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(EnteteCompact.titreKey),
        matching: find.byType(RichText),
      ),
    );
    final String brut = p.text.toPlainText();
    final int al = brut.indexOf('Al-');
    final int badr = brut.indexOf('Badr');
    double haut(int debut, int fin) => p
        .getBoxesForSelection(
          TextSelection(baseOffset: debut, extentOffset: fin),
        )
        .first
        .top;
    expect(haut(al, al + 3), haut(badr, badr + 4));
    // Le lecteur d'ecran lit le texte d'origine.
    expect(
      find.bySemanticsLabel('Classe Al-Badr · Jeudi 24 septembre'),
      findsOneWidget,
    );
  });

  for (final (Size, double) cas in <(Size, double)>[
    (const Size(390, 844), 1),
    (const Size(1440, 900), 1),
  ]) {
    testWidgets('${cas.$1.width.toInt()} x${cas.$2.toInt()} : en-tete '
        'inchange (pas compact)', (WidgetTester tester) async {
      await _poser(tester, vue: cas.$1, echelle: cas.$2);
      expect(
        EnteteCompact.actif(tester.element(find.byType(EntetePage))),
        isFalse,
      );
      expect(find.byKey(EnteteCompact.rangeeAuDessusKey), findsNothing);
    });
  }
}
