// Captures du lot CONNEXION-ALIGN (fiche du garde-cap, 04/11/2026) : la page
// de connexion a 360 et 1280 points, en clair et en sombre, en connexion et
// en creation. Les memes captures avant et apres le lot.
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
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';
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
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        // La creation ne s'ouvre qu'apres le questionnaire.
        questionnaireInscriptionProvider.overrideWith(_Repondu.new),
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

void main() {
  group('Capture CONNEXION-ALIGN', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (String nom, bool creation) in <(String, bool)>[
      ('connexion', false),
      ('creation', true),
    ]) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final Size taille in <Size>[
          const Size(360, 800),
          const Size(1280, 800),
        ]) {
          final String vue = '${taille.width.toInt()}';
          testWidgets('$nom $vue, ${mode.name}', (WidgetTester tester) async {
            await _monter(tester, Routes.connexion, mode: mode, taille: taille);
            if (creation) {
              await tester.tap(find.text(t.connexion.modeCreation));
              await stabiliser(tester);
            }
            debugPrint(
              'PNG ${await capturer(tester, '${nom}_${vue}_${mode.name}')}',
            );
          });
        }
      }
    }
  });
}
