// JONCTION-4 : captures de preuve de la jonction 282bc950 (feuille des
// cartes de la classe passee par ZoneSaisie, parametre optionnel `sens`).
//
// En arabe (locale `ar`, sens RTL donne par la langue, pas force), a
// 320 px et texte x2, clair et sombre : la feuille de l'enseignant avec ses
// trois erreurs (titre vide, lien incomplet, devoir sans echeance), puis la
// meme feuille avec un titre arabe et un texte francais (chaque champ prend
// le sens de sa premiere lettre). En francais (LTR), la saisie mixte aussi.
// Le meme script, rejoue sur le parent de 282bc950, donne les `avant_`.
//
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

const String _id = 'classe-capture';

/// Le prefixe des fichiers : `apres_` par defaut, `avant_` sur l'ancien code.
final String _prefixe = Platform.environment['PREFIXE_CAPTURE'] ?? 'apres';

Widget _app({required AppLocale langue, required Brightness luminosite}) =>
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portCartesClasseProvider.overrideWith(
          (Ref _) => PortCartesClasseDemo(
            peutModifier: true,
            cartes: cartesClasseDemo(DateTime(2026, 10, 8)),
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, luminosite),
            // Le sens vient de la langue : `ar` rend l'interface RTL.
            locale: langue.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: FeuilleCarteClasse(groupeId: _id),
              ),
            ),
          ),
        ),
      ),
    );

void _langue(AppLocale langue) {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

String _suffixe(AppLocale langue, Brightness lum) =>
    '${langue == AppLocale.ar ? 'ar_rtl' : 'fr_ltr'}_'
    '${lum == Brightness.light ? 'clair' : 'sombre'}';

void main() {
  group('Capture : JONCTION-4', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      // La traduction arabe est differee : chargee hors du temps simule.
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    const List<(AppLocale, Brightness)> erreurs = <(AppLocale, Brightness)>[
      (AppLocale.ar, Brightness.light),
      (AppLocale.ar, Brightness.dark),
    ];
    for (final (AppLocale langue, Brightness lum) in erreurs) {
      final String suffixe = _suffixe(langue, lum);
      testWidgets('feuille erreurs 320 x2 $suffixe', (
        WidgetTester tester,
      ) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 3600), 2);
        await tester.pumpWidget(_app(langue: langue, luminosite: lum));
        await stabiliser(tester);
        expect(
          Directionality.of(tester.element(find.byType(FeuilleCarteClasse))),
          TextDirection.rtl,
        );
        await tester.tap(
          find.byKey(const ValueKey<String>('classe.cartes.modele.devoir')),
        );
        await stabiliser(tester);
        await tester.enterText(find.byKey(FeuilleCarteClasse.titreKey), '');
        await tester.enterText(find.byKey(FeuilleCarteClasse.lienKey), 'www');
        await tester.ensureVisible(
          find.byKey(FeuilleCarteClasse.enregistrerKey),
        );
        await tester.tap(find.byKey(FeuilleCarteClasse.enregistrerKey));
        await stabiliser(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 8000));
        await stabiliser(tester);
        await capturer(tester, '${_prefixe}_feuille_erreurs_320x2_$suffixe');
      });
    }

    const List<(AppLocale, Brightness)> mixtes = <(AppLocale, Brightness)>[
      (AppLocale.ar, Brightness.light),
      (AppLocale.ar, Brightness.dark),
      (AppLocale.fr, Brightness.light),
    ];
    for (final (AppLocale langue, Brightness lum) in mixtes) {
      final String suffixe = _suffixe(langue, lum);
      testWidgets('feuille saisie mixte 320 x2 $suffixe', (
        WidgetTester tester,
      ) async {
        _langue(langue);
        fixerVueCapture(tester, const Size(320, 3600), 2);
        await tester.pumpWidget(_app(langue: langue, luminosite: lum));
        await stabiliser(tester);
        await tester.enterText(
          find.byKey(FeuilleCarteClasse.titreKey),
          'مراجعة سورة الفيل',
        );
        await tester.enterText(
          find.byKey(FeuilleCarteClasse.texteKey),
          'Lire la sourate trois fois à voix haute.',
        );
        await stabiliser(tester);
        TextDirection rendu(Key cle) => tester
            .state<EditableTextState>(
              find.descendant(
                of: find.byKey(cle),
                matching: find.byType(EditableText),
              ),
            )
            .renderEditable
            .textDirection;
        expect(rendu(FeuilleCarteClasse.titreKey), TextDirection.rtl);
        expect(rendu(FeuilleCarteClasse.texteKey), TextDirection.ltr);
        // Haut de la feuille : modele, titre, texte.
        await capturer(tester, '${_prefixe}_feuille_mixte_320x2_$suffixe');
      });
    }
  });
}
