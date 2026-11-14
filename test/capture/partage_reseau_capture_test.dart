// Captures de PARTAGE-RESEAU (directeur, 14/11/2026) : la carte a partager
// porte le lien du SITE PUBLIC dans sa langue (QR et texte imprime :
// rewayahacademy.com/fr/, /ar/, /en/, /pt/), jamais app.rewayahacademy.com ;
// la page de partage, en francais puis en arabe, montre le meme lien.
// Le lien est celui de la production : `lienOffre(configure: '')`, sans
// surcharge de test.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Sortie :
// CAPTURE_DIR=docs/current/captures/E2E/partage-reseau.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/lien_offre.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';

import '../features/partage_offre/hote_partage.dart';
import 'outil_capture.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PARTAGE-RESEAU : captures', skip: sautSansCapture, () {
    for (final LangueCarte l in LangueCarte.values) {
      testWidgets('la carte en ${l.code}, lien du site public', (
        WidgetTester tester,
      ) async {
        final Uri lien = lienOffre(configure: '', langue: l.code);
        expect(lien.toString(), 'https://rewayahacademy.com/${l.code}/');
        fixerVueCapture(tester, const Size(360, 640), 1.5);
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: RepaintBoundary(
                key: cadreCapture,
                child: Builder(
                  builder: (BuildContext context) => MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.pour(
                      InterfaceMode.standard,
                      Brightness.light,
                    ),
                    locale: TranslationProvider.of(context).flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                    home: CartePartage(
                      lien: lien,
                      langue: l,
                      variante: VarianteCarte.hommes,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('rewayahacademy.com/${l.code}/'), findsOne);
        expect(find.textContaining('app.'), findsNothing);
        await capturer(tester, 'carte_${l.code}_540x960');
      });
    }

    for (final (String nom, TextDirection sens, String langue)
        in <(String, TextDirection, String)>[
          ('fr', TextDirection.ltr, 'fr'),
          ('ar', TextDirection.rtl, 'ar'),
        ]) {
      testWidgets('la page de partage, interface $nom', (
        WidgetTester tester,
      ) async {
        masquerRubanDebug();
        if (sens == TextDirection.rtl) {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        }
        await monterPartage(
          tester,
          lien: origineSitePublic(configure: ''),
          direction: sens,
          taille: const Size(390, 1400),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('rewayahacademy.com/$langue/'),
          findsWidgets,
        );
        await capturerVue(tester, 'page_${nom}_390');
      });
    }
  });
}
