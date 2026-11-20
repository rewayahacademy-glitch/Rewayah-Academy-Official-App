// PE-FORMULAIRE-CANDIDAT (vague B du parcours de l'enseignant, 20/11/2026) :
// captures des questions juz (tout, rien, nombre, ancienne tranche) et riwayat
// (les dix, les sept, une seule, quelques-unes), des aides (juz, ijaza) et de
// la proposition d'adresse a la connexion. 390 de large, francais et arabe.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/core/widgets/proposition_courriel.dart';
import 'package:rewayah_academy/features/candidature/modele_questions.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../features/candidature/hote_candidature.dart';
import '../fixtures/candidature/faux_ma_candidature.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Size _taille = Size(390, 844);

Future<void> _monterParcours(
  WidgetTester tester,
  FauxMaCandidature port,
) async {
  fixerVueCapture(tester, _taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.attenteCandidature,
    routes: routesCandidature(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesCandidature(
        port: port,
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

Future<void> _monterConnexion(WidgetTester tester) async {
  fixerVueCapture(tester, _taille, 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        demoAuthActiveProvider.overrideWithValue(false),
        environnementConnexionProvider.overrideWithValue('production'),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const ConnexionPage(mode: ModeConnexion.connexion),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fait voir [cle] (en bas de l'ecran s'il le faut ; en HAUT de l'ecran avec
/// [enHaut]), puis capture.
Future<void> _photo(
  WidgetTester tester,
  String nom, {
  String? cle,
  bool enHaut = false,
}) async {
  if (cle != null) {
    final Finder f = find.byKey(ValueKey<String>(cle));
    if (enHaut) {
      await Scrollable.ensureVisible(tester.element(f), alignment: 0.05);
    } else {
      await tester.ensureVisible(f);
    }
    await tester.pumpAndSettle();
  }
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('PE-FORMULAIRE-CANDIDAT : captures', skip: sautSansCapture, () {
    for (final (String l, AppLocale locale) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      testWidgets('juz $l', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monterParcours(
          tester,
          FauxMaCandidature(questionnaireJson: questionnaireAvecJuz()),
        );
        await repondreAvant(tester, champMemorisation);
        await _photo(tester, 'juz-question_${l}_390');
        await toucherCle(tester, 'option-$champMemorisation-coran_entier');
        await _photo(tester, 'juz-tout_${l}_390');
        await toucherCle(tester, 'option-$champMemorisation-aucune');
        await _photo(
          tester,
          'juz-rien_${l}_390',
          cle: 'option-$champMemorisation-aucune',
        );
        await toucherCle(tester, 'option-$champMemorisation-nombre');
        // Aucun nombre par defaut : le compteur attend un choix.
        await _photo(
          tester,
          'juz-nombre-choisir_${l}_390',
          cle: 'juz-raccourci-20',
        );
        await toucherCle(tester, 'juz-raccourci-10');
        final Finder plus = find.descendant(
          of: find.byKey(const ValueKey<String>('juz-compteur')),
          matching: find.byKey(ChoixNombre.clePlus),
        );
        await tester.tap(plus);
        await tester.pumpAndSettle();
        await tester.tap(plus);
        await tester.pumpAndSettle();
        await _photo(tester, 'juz-nombre-12_${l}_390', cle: 'juz-raccourci-20');
        await toucherCle(tester, 'aide-juz');
        await _photo(tester, 'aide-juz_${l}_390', cle: 'aide-juz-texte');
      });

      testWidgets('juz ancienne tranche $l', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monterParcours(
          tester,
          FauxMaCandidature(
            questionnaireJson: questionnaireAvecJuz(
              dernieresReponses: <String, Object?>{
                'langueMaternelle': 'poular',
                'languesExplication': <String>['poular'],
                champMemorisation: 'moins_10_juz',
              },
            ),
          ),
        );
        await toucherCle(tester, 'parcours-retour');
        await _photo(tester, 'juz-ancienne_${l}_390', cle: 'juz-raccourci-20');
      });

      testWidgets('riwayat $l', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monterParcours(tester, FauxMaCandidature());
        await repondreAvant(tester, 'riwayat');
        await _photo(tester, 'riwayat-question_${l}_390');
        await toucherCle(tester, 'option-riwayat-dix');
        await _photo(tester, 'riwayat-dix_${l}_390');
        await toucherCle(tester, 'option-riwayat-sept');
        await _photo(tester, 'riwayat-sept_${l}_390');
        await toucherCle(tester, 'option-riwayat-une');
        await toucherCle(tester, 'option-riwayat-hafs');
        await _photo(
          tester,
          'riwayat-une_${l}_390',
          cle: 'option-riwayat-hafs',
        );
        await toucherCle(tester, 'option-riwayat-quelques');
        await toucherCle(tester, 'option-riwayat-warsh');
        // Le haut de la grille : la recherche, puis Nafi et Ibn Kathir.
        await _photo(
          tester,
          'riwayat-quelques_${l}_390',
          cle: 'riwayat-grille-recherche',
          enHaut: true,
        );
        await _photo(
          tester,
          'riwayat-quelques-suite_${l}_390',
          cle: 'option-riwayat-idris',
        );
      });

      testWidgets('aide ijaza $l', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monterParcours(tester, FauxMaCandidature());
        await repondreAvant(tester, 'ijazaPresentable');
        await toucherCle(tester, 'aide-ijaza');
        await _photo(tester, 'aide-ijaza_${l}_390');
      });

      testWidgets('proposition d adresse $l', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _monterConnexion(tester);
        await tester.enterText(
          find.byKey(const ValueKey<String>('connexion-courriel')),
          'fatou.exemple@gmial.com',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(PropositionCourriel.cleLien), findsOneWidget);
        await _photo(tester, 'adresse-proposition_${l}_390');
        await tester.tap(find.byKey(PropositionCourriel.cleLien));
        await tester.pumpAndSettle();
        expect(find.byKey(PropositionCourriel.cleLien), findsNothing);
        await _photo(tester, 'adresse-acceptee_${l}_390');
      });
    }
  });
}
