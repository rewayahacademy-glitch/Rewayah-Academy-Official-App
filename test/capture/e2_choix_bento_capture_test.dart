// Lot E2 : captures de preuve, avant et apres (variable `PHASE`, par defaut
// `apres`). Etapes « usage » (famille retenue, sous-question visible) et
// « genre » de l'inscription, 390 x 844 et 1440 x 900, clair et sombre.
// Jamais sans `CAPTURE_DIR`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final String _phase = Platform.environment['PHASE'] ?? 'apres';

Future<void> _monter(WidgetTester tester, Size taille, ThemeMode theme) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.inscription,
      themeMode: theme,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.inscription,
          builder: (BuildContext _, GoRouterState _) => const InscriptionPage(),
        ),
        GoRoute(
          path: Routes.inscriptionUsage,
          builder: (BuildContext _, GoRouterState _) => const UsageEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionIdentite,
          builder: (BuildContext _, GoRouterState _) => const IdentiteEtape(),
        ),
        GoRoute(
          path: Routes.inscriptionGenre,
          builder: (BuildContext _, GoRouterState _) => const GenreEtape(),
        ),
      ],
      surcharges: <Override>[
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
      ],
    ),
  );
  await stabiliser(tester);
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Capture : lot E2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1440, 900),
    ]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String s =
            '${taille.width.toInt()}x${taille.height.toInt()}_'
            '${theme == ThemeMode.light ? 'clair' : 'sombre'}';

        testWidgets('usage $s', (WidgetTester tester) async {
          await _monter(tester, taille, theme);
          await _taper(tester, find.text(t.inscription.usage.familleTitre));
          debugPrint(
            'PNG ${await capturerVue(tester, 'e2_${_phase}_usage_$s')}',
          );
        });

        testWidgets('genre $s', (WidgetTester tester) async {
          await _monter(tester, taille, theme);
          await _taper(tester, find.text(t.inscription.usage.moiTitre));
          await _taper(tester, find.text(t.commun.continuer));
          await tester.enterText(
            find.byKey(const Key('inscription-prenom')),
            'Amina',
          );
          await tester.enterText(
            find.byKey(const Key('inscription-nom')),
            'Diallo',
          );
          await _taper(tester, find.text(t.commun.continuer));
          debugPrint(
            'PNG ${await capturerVue(tester, 'e2_${_phase}_genre_$s')}',
          );
        });
      }
    }
  });
}
