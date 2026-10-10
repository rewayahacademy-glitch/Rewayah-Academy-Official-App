// TB-6, revue du 09/10 : a 320 px et texte x2, l'enseignant sans support
// voit la phrase du §12 (« Choisissez un support ou ecrivez au tableau. »)
// en entier. Avant : la surface ne gardait que 99 px, la phrase (4 lignes,
// 192 px avec les polices du depot) etait tranchee a mi-ligne par le bas
// de la carte.
//
// Mesures sur le rendu, avec les VRAIES polices (la police de test, carree,
// donnerait d'autres hauteurs) : le rectangle de la phrase est dans la vue,
// dans la carte de la surface, sous la rangee « Eleves » et au-dessus du
// declencheur « Commandes ». La tete qui cede sa place defile en fondu, et
// son contenu reste joignable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/mention_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';

import '../../capture/outil_capture.dart' hide stabiliser;

final Finder _consigne = find.byKey(SurfacePageFixe.cleConsigne);
final Finder _zone = find.byKey(const ValueKey<String>('zone-support'));
final Finder _eleves = find.byKey(const ValueKey<String>('bouton-eleves'));
final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  RoleSeance role = RoleSeance.enseignant,
  SituationTb situation = SituationTb.ped01,
  double texte = 2,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      echelleTexte: texte,
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// La phrase entiere est visible : dans la vue, dans la carte de la
/// surface (qui la rogne sinon), sans chevaucher la rangee « Eleves » ni le
/// declencheur.
void _phraseEntiere(WidgetTester tester, Size taille) {
  expect(tester.takeException(), isNull);
  final Rect phrase = tester.getRect(_consigne);
  final Rect carte = tester.getRect(_zone);
  expect(phrase.height, greaterThan(0));
  expect(phrase.left, greaterThanOrEqualTo(0));
  expect(phrase.top, greaterThanOrEqualTo(0));
  expect(phrase.right, lessThanOrEqualTo(taille.width));
  expect(phrase.bottom, lessThanOrEqualTo(taille.height));
  expect(phrase.top, greaterThanOrEqualTo(carte.top - 0.5));
  expect(phrase.bottom, lessThanOrEqualTo(carte.bottom + 0.5));
  if (_eleves.evaluate().isNotEmpty) {
    expect(phrase.top, greaterThan(tester.getRect(_eleves).bottom));
  }
  if (_declencheur.evaluate().isNotEmpty) {
    expect(phrase.bottom, lessThan(tester.getRect(_declencheur).top));
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Phrase du §12 jamais rognee (enseignant, texte x2)', () {
    for (final Size taille in <Size>[
      const Size(320, 700),
      const Size(320, 640),
      const Size(390, 844),
    ]) {
      testWidgets('${taille.width.toInt()} x ${taille.height.toInt()}', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille);
        _phraseEntiere(tester, taille);
      });
    }
  });

  group('Phrase du §12 jamais rognee, arabe (RTL)', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    testWidgets('320 x2', (WidgetTester tester) async {
      const Size taille = Size(320, 700);
      await _monter(tester, taille);
      expect(Directionality.of(tester.element(_consigne)), TextDirection.rtl);
      _phraseEntiere(tester, taille);
    });
  });

  group('La tete qui cede sa place defile en fondu', () {
    testWidgets('320 x2 : fondu, puis la mention se lit en defilant', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(320, 700));
      expect(find.byKey(TeteSalleBornee.cleFondu), findsOneWidget);
      final Finder tete = find.byKey(TeteSalleBornee.defilementKey);
      final Rect cadre = tester.getRect(tete);
      // Au repos, la mention est sous le bord de la tete.
      expect(
        tester.getRect(find.byType(MentionSeance)).bottom,
        greaterThan(cadre.bottom),
      );
      // Joignable en faisant defiler la tete.
      await tester.ensureVisible(find.byType(MentionSeance));
      await tester.pump();
      final Rect mention = tester.getRect(find.byType(MentionSeance));
      expect(mention.bottom, lessThanOrEqualTo(cadre.bottom + 0.5));
      expect(mention.top, greaterThanOrEqualTo(cadre.top - 0.5));
      // Au bout du defilement, plus de fondu : rien n'est a suivre.
      expect(find.byKey(TeteSalleBornee.cleFondu), findsNothing);
    });

    testWidgets('390 x1 : la tete tient, ni fondu ni place reservee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(390, 844), texte: 1);
      expect(find.byKey(TeteSalleBornee.cleFondu), findsNothing);
      _phraseEntiere(tester, const Size(390, 844));
    });
  });

  // SALLE-200 et TB-5 : avec un support, la place ne change pas (aucune
  // phrase a reserver).
  testWidgets('320 x2 avec support : la tete garde sa hauteur', (
    WidgetTester tester,
  ) async {
    await _monter(tester, const Size(320, 700), situation: SituationTb.ped03);
    expect(tester.takeException(), isNull);
    expect(_consigne, findsNothing);
    expect(find.byKey(TeteSalleBornee.cleFondu), findsNothing);
    expect(find.byType(ZoneSupport), findsOneWidget);
  });
}
