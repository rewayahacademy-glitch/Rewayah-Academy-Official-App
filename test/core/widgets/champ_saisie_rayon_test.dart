// MESSAGERIE-COULEURS (directeur, 16/11/2026, capture en sombre sur ordinateur) :
// le champ d'ecriture grandit avec le texte, mais son rayon suivait sa hauteur
// (`AppRadius.full`, ramene a la moitie de la hauteur) : a quatre lignes, un
// demi-cercle dont les coins mangeaient le debut et la fin des lignes.
//
// Le rayon est FIXE (`AppRadius.lg`) : a 1, 3 et 6 lignes, a 390 et 1440, en
// francais et en arabe, a l'echelle de texte x2, aucun glyphe visible ne sort
// de la zone interieure arrondie, et le rayon reste le meme au-dela d'une ligne.
// Contre-epreuve : echoue avec `AppRadius.arrondiFull`.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../support/hote_theme.dart';

/// Un texte de [n] lignes dans la langue demandee.
String _texte(int n, {required bool arabe}) => List<String>.generate(
  n,
  (int i) => arabe ? 'السطر ${i + 1} من الرسالة' : 'Ligne ${i + 1} du message',
).join('\n');

/// Ce que mesure le test pour un champ rempli.
class _Mesure {
  const _Mesure(this.rayonEffectif, this.hors);

  /// Le rayon reellement peint : le rayon demande, borne a la moitie de la
  /// hauteur (c'est ce que fait Flutter).
  final double rayonEffectif;

  /// Les glyphes visibles dont un coin sort de la zone arrondie.
  final List<Rect> hors;
}

Future<_Mesure> _mesurer(
  WidgetTester tester, {
  required Size taille,
  required int lignes,
  required bool arabe,
  double echelle = 2,
}) async {
  fixerVue(tester, taille);
  await tester.pumpWidget(
    hoteTheme(
      Directionality(
        textDirection: arabe ? TextDirection.rtl : TextDirection.ltr,
        child: FilDiscussion(
          pleinEcran: true,
          messages: const <MessageFil>[],
          textes: textesFilCommunication(),
          onEnvoyer: (String _) async {},
        ),
      ),
      echelleTexte: echelle,
      defilant: false,
    ),
  );
  await tester.pumpAndSettle();
  final Finder champ = find.byKey(FilDiscussion.champKey);
  final String texte = _texte(lignes, arabe: arabe);
  await tester.enterText(champ, texte);
  await tester.pumpAndSettle();

  final Finder decorateur = find.descendant(
    of: champ,
    matching: find.byType(InputDecorator),
  );
  final Rect zone = tester.getRect(decorateur.first);
  final InputDecorator d = tester.widget<InputDecorator>(decorateur.first);
  final OutlineInputBorder bord =
      d.decoration.enabledBorder! as OutlineInputBorder;
  final double demande = bord.borderRadius.topLeft.x;
  final double effectif = math.min(demande, zone.height / 2);

  final RenderEditable rendu = tester
      .state<EditableTextState>(
        find.descendant(of: champ, matching: find.byType(EditableText)),
      )
      .renderEditable;
  final RRect contour = RRect.fromRectAndRadius(
    zone,
    Radius.circular(effectif),
  );
  final List<Rect> hors = <Rect>[];
  for (final TextBox b in rendu.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: texte.length),
  )) {
    final Rect local = b.toRect();
    final Offset a = rendu.localToGlobal(local.topLeft);
    final Rect r = Rect.fromLTWH(a.dx, a.dy, local.width, local.height);
    // Seuls les glyphes visibles comptent : une ligne defilee hors du champ
    // n'est pas dessinee.
    if (r.top < zone.top || r.bottom > zone.bottom) continue;
    final List<Offset> coins = <Offset>[
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ];
    if (coins.any((Offset c) => !contour.contains(c))) hors.add(r);
  }
  return _Mesure(effectif, hors);
}

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    for (final bool arabe in <bool>[false, true]) {
      final String cas = '${taille.width.toInt()} ${arabe ? 'ar' : 'fr'} x2';
      testWidgets('champ a 1, 3 et 6 lignes, $cas : aucun glyphe ne sort de '
          'la zone arrondie, rayon constant au-dela d\'une ligne', (
        WidgetTester tester,
      ) async {
        final Map<int, _Mesure> m = <int, _Mesure>{};
        for (final int n in <int>[1, 3, 6]) {
          m[n] = await _mesurer(
            tester,
            taille: taille,
            lignes: n,
            arabe: arabe,
          );
          expect(
            m[n]!.hors,
            isEmpty,
            reason:
                '$n ligne(s), $cas : glyphes hors de la zone arrondie '
                '(rayon ${m[n]!.rayonEffectif}) : ${m[n]!.hors}',
          );
        }
        // Le rayon ne grandit plus au-dela d'une ligne.
        expect(
          m[3]!.rayonEffectif,
          m[6]!.rayonEffectif,
          reason:
              'rayon a 3 lignes ${m[3]!.rayonEffectif}, a 6 lignes '
              '${m[6]!.rayonEffectif} : il doit rester constant',
        );
        expect(m[1]!.rayonEffectif, lessThanOrEqualTo(m[3]!.rayonEffectif));
      });
    }
  }
}
