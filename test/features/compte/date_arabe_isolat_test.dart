// DATE-ARABE-ISOLAT (garde-cap, 12/11/2026) : dateLongue met la marque de
// lettre arabe (U+061C) en tete en arabe. Sans elle, une phrase qui isole la
// date entiere (« انتهى في {date} », date isolee) recevait un isolat exterieur de gauche
// a droite (aucune lettre forte hors des isolats imbriques du jour, du mois
// et de l'annee), et la date se lisait a l'envers.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';

import 'support_compte.dart';

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test(
    'en arabe, la date longue commence par U+061C ; en francais, rien',
    () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      final String ar = dateLongue(DateTime(2026, 9, 13, 12));
      expect(ar.startsWith(marqueLettreArabe), isTrue);
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final String fr = dateLongue(DateTime(2026, 9, 13, 12));
      expect(fr, '13 septembre 2026');
      expect(fr.contains(marqueLettreArabe), isFalse);
    },
  );

  testWidgets('acces : « انتهى في {date} » se lit le mot, puis le jour, puis '
      'l annee (de droite a gauche)', (WidgetTester tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await monterCompte(
      tester,
      depart: Routes.compteTuteurSousPage('acces'),
      direction: TextDirection.rtl,
      // Une seule ligne : a 390, l'annee passe a la ligne suivante, et les
      // positions horizontales ne disent plus l'ordre de lecture.
      taille: const Size(1440, 1200),
      eleves: <EleveDuFoyer>[
        EleveDuFoyer(
          id: 'foyer-a-eleve-9',
          prenom: 'Élève A9',
          identifiantImmuable: 'STUD-FA-000009',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
          finAcces: DateTime.utc(2026, 9, 13, 12),
        ),
      ],
    );
    RenderParagraph? phrase;
    for (final Element e in find.byType(RichText).evaluate()) {
      final RenderParagraph p = e.renderObject! as RenderParagraph;
      final String s = p.text.toPlainText();
      if (s.contains('انتهى') && s.contains('2026')) phrase = p;
    }
    expect(phrase, isNotNull, reason: 'la phrase « انتهى في … » est affichee');
    final RenderParagraph p = phrase!;
    final String s = p.text.toPlainText();
    expect(p.textDirection, TextDirection.rtl);
    double x(String morceau) => p
        .getBoxesForSelection(
          TextSelection(
            baseOffset: s.indexOf(morceau),
            extentOffset: s.indexOf(morceau) + morceau.length,
          ),
        )
        .first
        .left;
    TextBox boite(String morceau) => p
        .getBoxesForSelection(
          TextSelection(
            baseOffset: s.indexOf(morceau),
            extentOffset: s.indexOf(morceau) + morceau.length,
          ),
        )
        .first;
    // Meme ligne : le bas des deux boites a quelques points pres.
    expect(
      (boite('13').bottom - boite('2026').bottom).abs(),
      lessThan(6),
      reason: 'une seule ligne',
    );
    expect(x('انتهى'), greaterThan(x('13')), reason: 'le mot avant la date');
    expect(x('13'), greaterThan(x('2026')), reason: 'le jour avant l annee');
  });
}
