// Captures R3 du lecteur de textes (Markdown ferme) : un document avec un verset
// vocalise, un paragraphe mixte, des listes, une citation. Interface francaise
// et arabe, 360 et 1440, texte x1 et x2.
//
// CAPTURE_DIR=docs/current/captures/E2E/PX-BD-SUPPORT flutter test \
//   test/features/tc_catalogue/capture_lecteur_markdown_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/tc_catalogue/lecteur_markdown.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

const String _document =
    '# Les bases de la lecture\n\n'
    'Un paragraphe en **gras** et en *italique*, pour commencer.\n\n'
    '## Un verset vocalisé\n\n'
    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ\n\n'
    '## Un paragraphe mixte\n\n'
    'نقرأ **الحمد** (Al-Hamd) ensemble, puis on explique en français.\n\n'
    'On lit بِسْمِ ٱللَّهِ puis on revient au français.\n\n'
    '- une puce\n- ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ\n\n'
    '1. un\n2. deux\n\n'
    '> Une citation à retenir.\n\n'
    '---\n\n'
    '### Pour finir\n\n'
    'À la semaine prochaine.';

void main() {
  group('captures PX-BD-SUPPORT', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size taille, AppLocale langue, double echelle)
        in <(Size, AppLocale, double)>[
          (const Size(360, 1700), AppLocale.fr, 1),
          (const Size(360, 1700), AppLocale.ar, 1),
          (const Size(360, 2900), AppLocale.fr, 2),
          (const Size(1440, 1300), AppLocale.fr, 1),
          (const Size(1440, 1300), AppLocale.ar, 1),
          (const Size(1440, 1900), AppLocale.ar, 2),
        ]) {
      final String nom =
          'lecteur-${taille.width.toInt()}-${langue.languageCode}-x${echelle.toInt()}';
      testWidgets(nom, (WidgetTester tester) async {
        masquerRubanDebug();
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hote(
            Builder(
              builder: (BuildContext c) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(
                  textDirection: langue == AppLocale.ar
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: const Scaffold(
                    body: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: LecteurMarkdown(source: _document),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capturerVue(tester, nom);
      });
    }
  }, skip: sautSansCapture);
}
