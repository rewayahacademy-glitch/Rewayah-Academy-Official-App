// Captures du lot ALIGN-RENVOI (pilote, 04/11/2026) : l'ecran « Lien envoye »
// de la connexion a 360 et 1280 points, en clair et en sombre. Les memes
// captures avant et apres le lot.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/connexion/saisie_code_courriel.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_page.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

class _Repondu extends QuestionnaireControleur {
  @override
  QuestionnaireInscription build() => const QuestionnaireInscription(
    usage: UsageInscription.moi,
    niveauTitulaire: NiveauDeclare.lectureLente,
    objectif: ObjectifApprentissage.memoriser,
    moments: <MomentJournee>{MomentJournee.soir},
    langue: 'francais',
  );
}

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  Size taille = const Size(390, 844),
  bool repondu = true,
  bool resteesAilleurs = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        if (repondu)
          questionnaireInscriptionProvider.overrideWith(_Repondu.new),
        if (resteesAilleurs)
          reponsesResteesAilleursProvider.overrideWith(_Ailleurs.new),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  // L'illustration de l'entree joue une fois, puis reste immobile : la
  // capture montre son image finale.
  await tester.pump(AppMouvement.entreeIllustration);
  return routeur;
}

class _Ailleurs extends ReponsesResteesAilleurs {
  @override
  bool build() => true;
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture ONBOARDING-BOUCLE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (Size taille, ThemeMode mode) in <(Size, ThemeMode)>[
      (const Size(390, 844), ThemeMode.light),
      (const Size(1440, 900), ThemeMode.dark),
    ]) {
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final String vue =
            '${taille.width.toInt()}_${mode.name}_${langue.languageCode}';

        testWidgets('creation, reponses gardees $vue', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            '${Routes.connexion}?mode=creer',
            mode: mode,
            taille: taille,
          );
          expect(find.text(t.connexion.revoirReponses), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, 'creation_gardees_$vue')}');
        });

        testWidgets('lien envoye avec le code $vue', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            QuestionnairePage.adresseAcces,
            mode: mode,
            taille: taille,
          );
          await tester.enterText(
            find.byKey(const Key('questionnaire-acces-courriel')),
            'fatou@example.test',
          );
          await stabiliser(tester);
          final Finder envoyer = find.byKey(
            const ValueKey<String>('questionnaire-acces-envoyer'),
          );
          await tester.ensureVisible(envoyer);
          await stabiliser(tester);
          await tester.tap(envoyer);
          await stabiliser(tester);
          expect(find.byKey(SaisieCodeCourriel.cleChamp), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, 'lien_envoye_code_$vue')}');
        });

        testWidgets('reponses restees ailleurs $vue', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            Routes.commencer,
            mode: mode,
            taille: taille,
            repondu: false,
            resteesAilleurs: true,
          );
          expect(
            find.text(t.inscription.questionnaire.acces.absentesTitre),
            findsOneWidget,
          );
          debugPrint('PNG ${await capturer(tester, 'reponses_ailleurs_$vue')}');
        });
      }
    }
  });
}
