// CANDIDATURE-UX (directeur, 14/11/2026) : captures R3 du parcours candidat
// corrige. Langue maternelle en lignes compactes, recherche en tete ; riwayat
// avec « toutes » en tete, les plus connues, puis « Une autre riwaya » ; la
// mention que candidater ne coute rien (presentation et recapitulatif). 390 et
// 1440, francais, anglais, arabe.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/candidature/choix_avec_recherche.dart';
import 'package:rewayah_academy/features/candidature/recapitulatif_etape.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import 'outil_capture.dart';

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  FauxMaCandidature? port,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.attenteCandidature,
    routes: routesCandidature(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesCandidature(
        port: port ?? FauxMaCandidature(),
        etat: etatCandidat(candidature: candidatureAFaire()),
      ),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  await capturer(tester, nom);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CANDIDATURE-UX : captures', skip: sautSansCapture, () {
    for (final (String langue, AppLocale locale) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('en', AppLocale.en),
      ('ar', AppLocale.ar),
    ]) {
      for (final (String nom, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('1440', const Size(1440, 900)),
      ]) {
        testWidgets('$langue $nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          await _monter(tester, taille);
          await _photo(tester, 'presentation-gratuit_${langue}_$nom');
          await passerLaPresentation(tester);
          await _photo(tester, 'langue-maternelle-compacte_${langue}_$nom');
          await toucherCle(tester, 'option-langueMaternelle-wo');
          await _photo(tester, 'langue-maternelle-choisie_${langue}_$nom');
          await tester.enterText(
            find.byKey(ChoixAvecRecherche.champKey),
            locale == AppLocale.ar ? 'ال' : 'a',
          );
          await tester.pumpAndSettle();
          await _photo(tester, 'langue-maternelle-recherche_${langue}_$nom');
        });

        testWidgets('riwayat $langue $nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          await _monter(tester, taille);
          await repondreAvant(tester, 'riwayat');
          await _photo(tester, 'riwayat_${langue}_$nom');
          await toucherCle(tester, 'option-riwayat-toutes');
          await _photo(tester, 'riwayat-toutes_${langue}_$nom');
        });
      }
    }

    testWidgets('recapitulatif : ne coute rien (fr, ar)', (
      WidgetTester tester,
    ) async {
      for (final AppLocale locale in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monter(
          tester,
          const Size(390, 844),
          port: FauxMaCandidature(
            questionnaireJson: questionnaireJsonDeTest(
              dernieresReponses: reponsesCompletesDeTest(),
            ),
          ),
        );
        await passerLaPresentation(tester);
        await tester.pumpAndSettle();
        if (find.byKey(RecapitulatifEtape.gratuitKey).evaluate().isNotEmpty) {
          await _photo(
            tester,
            'recapitulatif-gratuit_${locale.languageCode}_390',
          );
        }
      }
    });
  });
}
