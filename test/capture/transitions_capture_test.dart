// TRANSITIONS (11/11/2026) : captures image par image de chaque type du
// catalogue (descente, onglet, fenetre, feuille), en clair, en sombre et en
// arabe. Cinq images par transition : 0 %, 25 %, 50 %, 75 %, 100 %.
// Plateforme forcee sur Linux : le meme constructeur que le web
// (`DescenteTransitionsBuilder`). Jamais lance sans `CAPTURE_DIR`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/app_transitions.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';

import 'outil_capture.dart';

/// Une page de demonstration, avec un titre et une carte, pour lire le
/// mouvement.
class _Page extends StatelessWidget {
  const _Page(this.titre);

  final String titre;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(titre, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<BuildContext> _monter(
  WidgetTester tester, {
  required Brightness luminosite,
  required AppLocale langue,
  Widget accueil = const _Page('Liste'),
}) async {
  fixerVueCapture(tester, const Size(390, 640), 1);
  addTearDown(tester.view.reset);
  late BuildContext contexte;
  await tester.pumpWidget(
    RepaintBoundary(
      key: cadreCapture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pour(InterfaceMode.standard, luminosite),
        locale: langue.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Comme `RewayahApp` : un fond opaque, celui du theme, sous toutes
        // les routes (LG-FLASH).
        builder: (BuildContext c, Widget? app) => ColoredBox(
          color: AppPalette.of(c).surfaceCanvas.background,
          child: app,
        ),
        home: Builder(
          builder: (BuildContext c) {
            contexte = c;
            return accueil;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return contexte;
}

/// Pompe la transition et capture cinq images.
Future<void> _cinqImages(
  WidgetTester tester,
  String nom,
  Duration duree,
) async {
  final int pas = duree.inMicroseconds ~/ 4;
  for (int i = 0; i <= 4; i++) {
    if (i > 0) await tester.pump(Duration(microseconds: pas));
    await capturerVue(tester, 'transitions/$nom-${i * 25}');
  }
  await tester.pumpAndSettle();
}

/// Le constructeur du web, sans le web : Linux.
final TargetPlatformVariant _linux = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(masquerRubanDebug);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('TRANSITIONS : captures', skip: sautSansCapture, () {
    for (final (Brightness luminosite, AppLocale langue) cas
        in <(Brightness, AppLocale)>[
          (Brightness.light, AppLocale.fr),
          (Brightness.dark, AppLocale.fr),
          (Brightness.light, AppLocale.ar),
        ]) {
      final String variante =
          '${cas.$1 == Brightness.dark ? 'sombre' : 'clair'}-'
          '${cas.$2.languageCode}';

      testWidgets('descente $variante', variant: _linux, (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(cas.$2));
        final BuildContext c = await _monter(
          tester,
          luminosite: cas.$1,
          langue: cas.$2,
        );
        Navigator.of(
          c,
        ).push(MaterialPageRoute<void>(builder: (_) => const _Page('Fiche')));
        await tester.pump();
        await _cinqImages(tester, 'descente-$variante', AppMouvement.descente);
      });

      testWidgets('fenetre $variante', variant: _linux, (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(cas.$2));
        tester.view.physicalSize = const Size(1280, 800);
        final BuildContext c = await _monter(
          tester,
          luminosite: cas.$1,
          langue: cas.$2,
        );
        fixerVueCapture(tester, const Size(1280, 800), 1);
        await tester.pumpAndSettle();
        unawaited(
          AppBottomSheet.ouvrir<void>(
            c,
            titre: 'Confirmer',
            libelleFermer: 'Fermer',
            constructeur: (_) => const Text('Une confirmation.'),
          ),
        );
        await tester.pump();
        await _cinqImages(
          tester,
          'fenetre-$variante',
          AppMouvement.feuilleOuverture,
        );
      });

      testWidgets('feuille $variante', variant: _linux, (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(cas.$2));
        final BuildContext c = await _monter(
          tester,
          luminosite: cas.$1,
          langue: cas.$2,
        );
        unawaited(
          AppBottomSheet.ouvrir<void>(
            c,
            titre: 'Une feuille',
            libelleFermer: 'Fermer',
            constructeur: (_) => const Text('Une surface temporaire.'),
          ),
        );
        await tester.pump();
        await _cinqImages(
          tester,
          'feuille-$variante',
          AppMouvement.feuilleOuverture,
        );
      });

      testWidgets('onglet $variante', variant: _linux, (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(cas.$2));
        final AnimationController entree = AnimationController(
          vsync: tester,
          duration: AppMouvement.navigation,
        );
        addTearDown(entree.dispose);
        await _monter(
          tester,
          luminosite: cas.$1,
          langue: cas.$2,
          accueil: Stack(
            children: <Widget>[
              AppTransitions.fonduEnchaine(
                const AlwaysStoppedAnimation<double>(1),
                entree,
                const _Page('Onglet A'),
              ),
              AppTransitions.fonduEnchaine(
                entree,
                const AlwaysStoppedAnimation<double>(0),
                const _Page('Onglet B'),
              ),
            ],
          ),
        );
        unawaited(entree.forward());
        await _cinqImages(tester, 'onglet-$variante', AppMouvement.navigation);
      });
    }
  });
}
