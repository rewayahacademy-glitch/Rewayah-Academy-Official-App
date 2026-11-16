// IMAGE-CANDIDAT (directeur, 16/11/2026, capture) : dans MA bulle (fond violet de
// marque), « Ouvrir le lien (...) » avec sa fleche etait violet sur violet.
// Le lien d'une bulle « de soi » prend l'encre de la bulle (celle du texte),
// souligne, l'icone de la meme encre ; dans une bulle recue il garde l'encre de
// lien. Le contraste mesure est d'au moins 4,5:1 dans les deux bulles, en clair
// et en sombre. Contre-epreuve : echoue sans `EncreLienSurFond`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';

import '../../support/hote_theme.dart';

const Key _soi = ValueKey<String>('lien-de-soi');
const Key _recu = ValueKey<String>('lien-recu');

MessageFil _m(String id, {required bool deSoi, required Key lien}) =>
    MessageFil(
      id: id,
      auteur: deSoi ? 'Vous' : 'Amina',
      texte: 'https://rewayahacademy.com/ar/',
      horodatage: '10:00',
      deSoi: deSoi,
      instant: DateTime.utc(2026, 11, 16, 10, deSoi ? 1 : 0),
      complement: LienFleche(
        key: lien,
        libelle: 'Ouvrir le lien (rewayahacademy.com)',
        onPress: () {},
        alignerEnDebut: true,
      ),
    );

/// Le rapport de contraste WCAG entre deux couleurs opaques.
double _rapport(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double clair = la > lb ? la : lb;
  final double sombre = la > lb ? lb : la;
  return (clair + 0.05) / (sombre + 0.05);
}

/// La couleur de fond de la bulle qui porte [lien].
Color _fondBulle(WidgetTester tester, Key lien) {
  for (final Element e
      in find
          .ancestor(of: find.byKey(lien), matching: find.byType(DecoratedBox))
          .evaluate()) {
    final Decoration d = (e.widget as DecoratedBox).decoration;
    if (d is BoxDecoration && d.color != null) return d.color!;
  }
  throw StateError('aucun fond de bulle derriere $lien');
}

/// Le style du texte du lien et la couleur de son icone.
(TextStyle, Color) _encre(WidgetTester tester, Key lien) {
  final Finder texte = find.descendant(
    of: find.byKey(lien),
    matching: find.byType(RichText),
  );
  final RichText rich = tester.widgetList<RichText>(texte).first;
  final TextStyle style = rich.text.style ?? const TextStyle();
  final Icon icone = tester.widget<Icon>(
    find.descendant(of: find.byKey(lien), matching: find.byType(Icon)).last,
  );
  final Color couleurIcone =
      icone.color ?? IconTheme.of(tester.element(find.byWidget(icone))).color!;
  return (style, couleurIcone);
}

void main() {
  for (final Brightness lum in <Brightness>[
    Brightness.light,
    Brightness.dark,
  ]) {
    testWidgets('lien de bulle, ${lum.name} : au moins 4,5:1 dans les deux', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          FilDiscussion(
            messages: <MessageFil>[
              _m('m1', deSoi: false, lien: _recu),
              _m('m2', deSoi: true, lien: _soi),
            ],
            textes: textesFilCommunication(),
            onEnvoyer: (String _) async {},
            pleinEcran: true,
          ),
          luminosite: lum,
          defilant: false,
        ),
      );
      await tester.pumpAndSettle();

      for (final (Key lien, String nom) in <(Key, String)>[
        (_soi, 'ma bulle'),
        (_recu, 'bulle recue'),
      ]) {
        final Color fond = _fondBulle(tester, lien);
        final (TextStyle style, Color icone) = _encre(tester, lien);
        final Color encre = style.color!;
        expect(
          _rapport(encre, fond),
          greaterThanOrEqualTo(4.5),
          reason: '$nom (${lum.name}) : libelle $encre sur $fond',
        );
        expect(
          _rapport(icone, fond),
          greaterThanOrEqualTo(4.5),
          reason: '$nom (${lum.name}) : fleche $icone sur $fond',
        );
        expect(
          icone,
          encre,
          reason: '$nom (${lum.name}) : fleche et libelle de la meme encre',
        );
      }
      // Dans MA bulle seulement, le lien est souligne en permanence.
      expect(_encre(tester, _soi).$1.decoration, TextDecoration.underline);
      expect(
        _encre(tester, _recu).$1.decoration,
        isNot(TextDecoration.underline),
      );
    });
  }

  testWidgets('un lien dans une carte posee dans MA bulle garde l\'encre de la '
      'page, lisible sur la carte', (WidgetTester tester) async {
    const Key lien = ValueKey<String>('lien-dans-carte');
    fixerVue(tester, const Size(390, 844));
    await tester.pumpWidget(
      hoteTheme(
        FilDiscussion(
          messages: <MessageFil>[
            MessageFil(
              id: 'm1',
              auteur: 'Vous',
              texte: 'Voici le document.',
              horodatage: '10:00',
              deSoi: true,
              instant: DateTime.utc(2026, 11, 16, 10),
              complement: AppCard(
                child: LienFleche(key: lien, libelle: 'Ouvrir', onPress: () {}),
              ),
            ),
          ],
          textes: textesFilCommunication(),
          onEnvoyer: (String _) async {},
          pleinEcran: true,
        ),
        defilant: false,
      ),
    );
    await tester.pumpAndSettle();
    final Color fond = _fondBulle(tester, lien);
    final (TextStyle style, Color _) = _encre(tester, lien);
    expect(_rapport(style.color!, fond), greaterThanOrEqualTo(4.5));
    expect(style.decoration, isNot(TextDecoration.underline));
  });
}
