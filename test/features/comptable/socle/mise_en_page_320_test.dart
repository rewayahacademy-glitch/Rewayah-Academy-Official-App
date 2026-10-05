// CPT-F-CORR : les trois pages de la coquille du Comptable (Aujourd'hui,
// Paiements, Tresorerie) a 320 px, texte x2, en VRAIES polices, en francais
// (LTR) et en arabe (RTL), sur le vrai routeur.
//
// Defauts mesures sur 62cde25c (refus de la verification croisee) :
//  - la bascule des montants avec mot d'etat (« Montants masques »), posee
//    dans les actions d'EntetePage, prenait toute la largeur : titre
//    « Aujourd'hui » une lettre par ligne, « RenderFlex overflowed by 26
//    pixels » (entete_page.dart:62) ;
//  - barre basse : « Aujourd'/hui », « Paieme/nts », « Tresorer/ie ».
//
// Criteres : aucune exception de mise en page, aucun mot coupe ni tronque
// sur l'ecran entier (verifierEcranSansMotCoupe), titre de la page sur une
// seule ligne.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';

import '../../../capture/outil_capture.dart';
import '../../../router/support_routeur.dart' hide stabiliser;
import '../../../support/aucun_mot_coupe.dart';
import '../../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  required Locale locale,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesRouteur(
        FausseSourceSession(sessionActive(AppRole.accountant)),
      ),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: locale,
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
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
  });

  testWidgets('garde-fou : les vraies polices sont actives', (
    WidgetTester tester,
  ) async {
    expect(
      largeurSonde('PlusJakartaSans'),
      lessThan(largeurSonde('FamilleInexistante') * 0.6),
    );
  });

  for (final (String sens, Locale locale) langue in <(String, Locale)>[
    ('LTR', AppLocale.fr.flutterLocale),
    ('RTL', AppLocale.ar.flutterLocale),
  ]) {
    for (final (String nom, String chemin, String titre) ecran
        in <(String, String, String)>[
          ('aujourdhui', Routes.comptable, t.comptable.aujourdhui.titre),
          ('paiements', Routes.comptablePaiements, t.comptable.paiements.titre),
          (
            'tresorerie',
            Routes.comptableTresorerie,
            t.comptable.tresorerie.titre,
          ),
        ]) {
      testWidgets('320 px, texte x2, ${langue.$1}, ${ecran.$1} : aucune '
          'exception, aucun mot coupe', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 640), 2);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _monter(tester, ecran.$2, locale: langue.$2);

        expect(tester.takeException(), isNull);
        expect(find.byType(BasculeMontants), findsOneWidget);
        verifierEcranSansMotCoupe(tester);

        // Le titre de la page (le plus haut des textes portant ce libelle,
        // l'autre est l'onglet de la barre basse) tient sur une ligne :
        // sa hauteur reste celle d'une ligne de titre, pas d'une colonne.
        final List<Rect> boites = <Rect>[
          for (final Element e in find.text(ecran.$3).evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ]..sort((Rect a, Rect b) => a.top.compareTo(b.top));
        expect(boites, isNotEmpty);
        final Rect titre = boites.first;
        expect(
          titre.width,
          greaterThan(titre.height),
          reason: 'Le titre « ${ecran.$3} » est ecrase ($titre)',
        );
      });
    }
  }

  testWidgets('390 px, texte x1 : la bascule est le bouton seul, le '
      'sous-titre garde sa largeur', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 844), 1);
    await _monter(tester, Routes.comptable, locale: AppLocale.fr.flutterLocale);
    expect(tester.takeException(), isNull);
    expect(find.text(t.comptable.commun.montantsMasques), findsNothing);
    expect(
      tester.getSize(find.byKey(BasculeMontants.cleBouton)).width,
      tester.getSize(find.byType(BasculeMontants)).width,
    );
  });

  testWidgets('1440 px : le mot d\'etat est ecrit a cote du bouton', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(1440, 900), 1);
    await _monter(tester, Routes.comptable, locale: AppLocale.fr.flutterLocale);
    expect(tester.takeException(), isNull);
    expect(find.text(t.comptable.commun.montantsMasques), findsOneWidget);
  });
}
