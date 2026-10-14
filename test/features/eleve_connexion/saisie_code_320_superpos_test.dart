// SUPERPOS-1b (09/10/2026, reserves de SUPERPOS-1) : la saisie du code de
// l'appareil eleve a 320 en texte double, en francais (LTR) et en arabe
// (RTL), sur le VRAI routeur et avec les vraies polices.
//
// L'aide du champ et chaque refus du serveur (tous les motifs de
// `MotifRefusAppairage`) se lisent en entier sous le champ : aucun mot
// coupe, aucun texte tronque. SUPERPOS-1 avait porte les bornes a
// `ZoneSaisie.lignesAideMax` (8) sur la foi d'une lecture ; la mesure
// manquait (la relecture R2 : « ancienne page de saisie du code, 0 echec »).
//
// Mesure du 09/10 : les bornes portees a 8 suffisent (aucune ellipse), mais
// le refus « revoque » se coupait apres un trait d'union (« Le tuteur a
// retire cet appareil. Demandez- / lui d'afficher un nouveau code. »), en
// francais comme en arabe (repli francais). Corrige : un gluon invisible
// n'est pose que quand la ligne s'y couperait (`sansCoupureAuTrait`), le
// texte reste sinon le texte donne. Contre-epreuve faite : sur la tete
// d'avant (`5a52ff30`), les deux tests echouent (« revoque »).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/cache/secure/stockage_securise.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/eleve_connexion/saisie_code_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import '../appareils/faux_lecteur_qr.dart';

Future<FauxServiceEnfantPilote> _monter(
  WidgetTester tester,
  AppLocale langue,
) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final FauxServiceEnfantPilote service = FauxServiceEnfantPilote();
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession()),
        serviceEnfantProvider.overrideWithValue(service),
        stockageSecuriseProvider.overrideWithValue(FauxStockageSecurise()),
        profilsLocauxProvider.overrideWithValue(FauxProfilsLocaux()),
        lecteurQrDisponibleProvider.overrideWithValue(true),
        fabriqueLecteurQrProvider.overrideWithValue(FauxLecteurQr.new),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
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
  routeur.go(Routes.connexionEleveCode);
  await stabiliser(tester);
  return service;
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La traduction arabe est differee : chargee hors du temps simule.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('saisie du code (${langue.languageCode}), 320 x2 : aide et '
        'chaque refus entiers', (WidgetTester tester) async {
      final FauxServiceEnfantPilote service = await _monter(tester, langue);
      expect(find.byKey(SaisieCodePage.champKey), findsOneWidget);
      expect(tester.takeException(), isNull);
      // L'aide, champ vide.
      expect(
        find.text(t.eleveConnexion.saisie.aide, findRichText: true),
        findsWidgets,
      );
      verifierAucunMotCoupe(tester, find.byType(SaisieCodePage));

      for (final MotifRefusAppairage motif in MotifRefusAppairage.values) {
        service.refus = motif;
        await tester.enterText(find.byKey(SaisieCodePage.champKey), 'AB23CD');
        await stabiliser(tester);
        final Finder valider = find.widgetWithText(
          ActionPrincipale,
          t.eleveConnexion.saisie.valider,
        );
        await tester.ensureVisible(valider);
        await tester.pump();
        await tester.tap(valider);
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        final String phrase = libellesRefusAppairage(motif).phrase;
        // Le texte rendu peut porter un gluon invisible (U+2060) apres un
        // trait d'union : c'est lui qui garde « Demandez-lui » entier.
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is RichText &&
                w.text.toPlainText().replaceAll('\u2060', '') == phrase,
          ),
          findsOneWidget,
          reason: 'refus ${motif.name} non affiche',
        );
        await tester.ensureVisible(find.byKey(SaisieCodePage.champKey));
        await tester.pump();
        expect(
          motsCoupes(tester, find.byType(SaisieCodePage)),
          isEmpty,
          reason: 'refus ${motif.name}',
        );
      }
    });
  }
}
