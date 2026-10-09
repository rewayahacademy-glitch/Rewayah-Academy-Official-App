// SUPERPOS-1, reprise du relecteur : l'arrivee dans le fil du controleur a
// 320 en texte double, avec les vraies polices (la mesure des mots en
// depend). Depuis la VRAIE route de demonstration.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/zone_saisie.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  required Size taille,
  required TextDirection sens,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesDemoControleur('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: routeur,
          builder: (BuildContext _, Widget? enfant) =>
              Directionality(textDirection: sens, child: enfant!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Laisse repondre le port de demonstration (400 ms), puis stabilise.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  // SUPERPOS-1, reprise : a 320 en texte double, l'arrivee dans le fil
  // montrait le titre sur quatre lignes de 56, un contexte qui redisait la
  // Classe et la date, une tranche de bulle et une saisie sous la pliure.
  // Apres : titre compact (un palier au-dessus d'un titre de section
  // agrandi), contexte sans redite, une bulle lisible (200 au moins) et la saisie
  // entiere a l'ecran, sans geste. Contre-epreuve : echoue sur l'ancien
  // code (titre de 56, saisie hors de l'ecran).
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('fil 320 x2 ${sens.name} : titre compact, une bulle lisible '
        'et la saisie a l\'arrivee', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(
        tester,
        adresseDemoControleur(
          EcranDemoControleur.echanges,
          fil: 'demo-mission-al-badr-0924',
        ),
        taille: const Size(320, 640),
        sens: sens,
      );
      await _attendre(tester);
      expect(tester.takeException(), isNull);

      // Titre compact : sous la taille proportionnelle (28 x 2), au-dessus
      // d'un titre de section agrandi (22 x 2).
      final double titre = tester
          .renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(EntetePage),
              matching: find.byWidgetPredicate(
                (Widget w) =>
                    w is RichText &&
                    w.text
                        .toPlainText()
                        .replaceAll('\u2060', '')
                        .startsWith('Classe Al-Badr'),
              ),
            ),
          )
          .textScaler
          .scale(28);
      expect(titre, lessThan(56));
      expect(titre, greaterThan(44));

      // Le contexte ne redit pas la Classe : elle n'est ecrite qu'au titre.
      expect(
        find.descendant(
          of: find.byKey(EchangesControleurPage.contexteCompactKey),
          matching: find.textContaining('Al-Badr'),
        ),
        findsNothing,
      );

      // La zone visible : du haut de l'ecran a la barre du bas.
      final double bas = tester.getRect(find.byKey(NavShell.barreBasseKey)).top;
      final Rect saisie = tester.getRect(find.byType(ZoneSaisie));
      expect(saisie.top, greaterThanOrEqualTo(0));
      expect(
        saisie.bottom,
        lessThanOrEqualTo(bas),
        reason: 'saisie $saisie, barre du bas a $bas',
      );
      final Rect liste = tester.getRect(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.byType(ListView),
        ),
      );
      // Une bulle en texte double mesure environ 200 : la liste en montre
      // au moins autant, et le dernier message y est lisible jusqu'a son
      // pied (un message plus long que la liste en montre 200 au moins).
      expect(liste.height, greaterThanOrEqualTo(200), reason: 'liste $liste');
      final Rect derniere = tester.getRect(
        find
            .byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('message-'),
            )
            .last,
      );
      final double haut = <double>[
        derniere.top,
        liste.top,
        0,
      ].reduce((double a, double b) => a > b ? a : b);
      final double visible =
          (derniere.bottom < liste.bottom ? derniere.bottom : liste.bottom) -
          haut;
      expect(derniere.bottom, lessThanOrEqualTo(liste.bottom + 0.5));
      expect(
        visible,
        greaterThanOrEqualTo(
          derniere.height < 200 ? derniere.height - 0.5 : 200,
        ),
        reason: 'liste $liste, derniere bulle $derniere',
      );
    });
  }
}
