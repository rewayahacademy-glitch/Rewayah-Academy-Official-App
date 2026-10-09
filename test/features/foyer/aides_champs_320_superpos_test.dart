// SUPERPOS-1, reprise du relecteur : les aides et erreurs des champs d'une
// ligne bornees a 2 ou 3 lignes (`helperMaxLines`, `errorMaxLines`) n'avaient
// pas ete mesurees a 320 en texte double. Mesure ici sur les vrais ecrans,
// avec les vraies polices, en francais et en arabe : invitation du conjoint
// (aide du courriel accordee au genre) et identite d'un profil eleve, sur le
// vrai routeur (Foyer, puis « Ajouter un profil eleve ») ; aide seule, puis
// erreurs affichees. Contre-epreuve faite : sur l'ancien code, l'aide du
// courriel et celle de l'age passaient a l'ellipse (3 lignes), et « e-mail »
// se coupait apres son trait d'union dans l'erreur du courriel. La saisie du
// code de l'eleve a ete mesuree de meme : deja entiere sur la base. Aucun texte
// tronque (ellipse) ni mot coupe.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';

Future<void> _poser(WidgetTester tester, Widget page, AppLocale langue) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La traduction arabe est differee : chargee hors du temps simule.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final bool f in <bool>[true, false]) {
      testWidgets('invitation du conjoint (${langue.languageCode}, '
          '${f ? 'elle' : 'lui'}), 320 x2 : aides et erreurs entieres', (
        WidgetTester tester,
      ) async {
        await _poser(
          tester,
          InviterConjointPage(
            placeFeminine: f,
            onAbandon: () {},
            onTerminee: () {},
          ),
          langue,
        );
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(InviterConjointPage));
        // Erreurs : un courriel invalide, sans prenom.
        await tester.enterText(
          find.byKey(InviterConjointPage.courrielKey),
          'pas-un-courriel',
        );
        await _taper(tester, find.byKey(InviterConjointPage.verifierKey));
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(InviterConjointPage));
      });
    }
  }

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('identite d\'un profil eleve (${langue.languageCode}), '
        '320 x2 : aides et erreurs entieres', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      LocaleSettings.setLocaleSync(langue);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      final FauxServiceAppairage appairage = FauxServiceAppairage()
        ..elevesRendus = List<EleveDuFoyer>.of(FoyersFictifs.foyerA);
      late GoRouter routeur;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...surchargesRouteur(
              FausseSourceSession(sessionActive(AppRole.guardian)),
              appairage: appairage,
            ),
            horlogeFoyerProvider.overrideWithValue(
              () => DateTime(2026, 9, 24, 12),
            ),
          ],
          child: TranslationProvider(
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? _) {
                routeur = ref.read(routeurProvider);
                return MaterialApp.router(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  locale: langue.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  routerConfig: routeur,
                );
              },
            ),
          ),
        ),
      );
      await stabiliser(tester);
      routeur.go(Routes.tuteurAccueil);
      await stabiliser(tester);
      await _taper(
        tester,
        find.descendant(
          of: find.byKey(NavShell.barreBasseKey),
          matching: find.text(t.nav.tuteur.foyer),
        ),
      );
      await _taper(tester, find.byKey(FoyerPage.ajouterKey));
      await _taper(tester, find.text(t.foyer.ajout.pourQui.enfantTitre));
      await _taper(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(find.byKey(FormulaireProfilEleve.nomKey), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(FormulaireProfilEleve));
      // Erreurs : l'action, champs vides ; puis un age hors bornes.
      await _taper(tester, find.byKey(FormulaireProfilEleve.actionKey));
      expect(find.text(t.foyer.ajout.erreurs.nomRequis), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(FormulaireProfilEleve));
      await tester.enterText(find.byKey(FormulaireProfilEleve.ageKey), '25');
      await _taper(tester, find.byKey(FormulaireProfilEleve.actionKey));
      verifierAucunMotCoupe(tester, find.byType(FormulaireProfilEleve));
    });
  }
}
