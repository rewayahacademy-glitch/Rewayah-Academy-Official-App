// Captures de recette AD-X (docs/current/AD-X_DECOUPAGE.md), sur le vrai
// routeur en demonstration admin, comme `main.dart` (`?demo=admin`) : chaque
// ecran a 390x844, 768x1024, 1440x900 et 320 px au texte x2, clair et
// sombre ; puis, si `CAPTURE_IMAGES` designe le dossier des images du
// directeur (`11_admin/V/coque/`), la planche image | capture a 1448x1086 et
// la planche image + rangee des petites largeurs (K-61 : comparer au meme
// endroit que l'image).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees :
// fixtures synthetiques de la demonstration uniquement.

import 'dart:io';

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
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

/// Le dossier des images du directeur, ou nul (planches sautees).
final String? _images = Platform.environment['CAPTURE_IMAGES'];

/// Un ecran du lot : son nom de fichier, sa route, l'image du directeur, la
/// ligne a choisir au bureau, et le texte a amener en haut de la vue a 320 px
/// au texte x2 (K-61.1 : la capture montre l'endroit que la recette verifie).
typedef _Ecran = ({
  String code,
  String route,
  String image,
  String? choisir,
  String? defilerA320,
});

final List<_Ecran> _ecrans = <_Ecran>[
  // A 320 px et texte double, « Activite recente » passe sous les tuiles,
  // hors de la premiere vue : la capture defile jusqu'a elle.
  (
    code: 'adm01',
    route: Routes.admin,
    image: 'ADMIN-SHELL-01_accueil.png',
    choisir: null,
    defilerA320: t.admin.tableau.activite.titre,
  ),
  (
    code: 'adm18',
    route: Routes.adminOperationsTraitement,
    image: 'ADMIN-SHELL-02_liste-detail.png',
    choisir: null,
    defilerA320: null,
  ),
  // A partir du bureau, la premiere classe s'ouvre dans l'inspecteur, comme
  // sur l'image ; ailleurs, la collection seule.
  (
    code: 'adm09',
    route: Routes.adminOperationsGroupes,
    image: 'ADMIN-SHELL-03_collection-inspecteur.png',
    choisir: 'Classe An-Nour',
    defilerA320: null,
  ),
];

/// Les formats de recette : nom, taille logique, densite, echelle du texte.
const List<(String, Size, double, double)> _formats =
    <(String, Size, double, double)>[
      ('390', Size(390, 1200), 2, 1),
      ('768', Size(768, 1024), 1, 1),
      ('1440', Size(1440, 900), 1, 1),
      ('320x2', Size(320, 1800), 2, 2),
    ];

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  String route, {
  double echelle = 1,
  String? choisir,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surchargesDemoAdmin(environnement: 'staging'),
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
                builder: (BuildContext context, Widget? child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: RepereDemonstration(child: child),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(route);
  await stabiliser(tester);
  if (choisir != null &&
      tester.view.physicalSize.width / tester.view.devicePixelRatio >= 1200) {
    await tester.tap(find.text(choisir).first);
    await stabiliser(tester);
  }
}

void main() {
  group('Capture : AD-X', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Ecran ecran in _ecrans) {
      final Map<String, String> sorties = <String, String>{};
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final (String, Size, double, double) f in _formats) {
          final String nom = 'adx_${ecran.code}_${f.$1}_${mode.name}';
          testWidgets(nom, (WidgetTester tester) async {
            fixerVueCapture(tester, f.$2, f.$3);
            await _monter(
              tester,
              mode,
              ecran.route,
              echelle: f.$4,
              choisir: ecran.choisir,
            );
            final String? cible = ecran.defilerA320;
            if (cible != null && f.$1 == '320x2') {
              await tester.ensureVisible(find.text(cible).first);
              await stabiliser(tester);
              expect(
                tester.getRect(find.text(cible).first).top,
                lessThan(f.$2.height),
              );
            }
            sorties[nom] = await capturer(tester, nom);
            debugPrint('PNG ${sorties[nom]}');
          });
        }

        final String nomPlanche = 'adx_${ecran.code}_planche_1448_${mode.name}';
        testWidgets(nomPlanche, skip: _images == null, (
          WidgetTester tester,
        ) async {
          fixerVueMaquette(
            tester,
            largeurPx: 1448,
            hauteurPx: 1086,
            largeurLogique: 1448,
          );
          await _monter(tester, mode, ecran.route, choisir: ecran.choisir);
          debugPrint(
            'PNG ${await capturerEtComparer(tester, nomPlanche, '$_images/${ecran.image}')}',
          );
        });

        final String nomRangee =
            'adx_${ecran.code}_planche_rangee_${mode.name}';
        testWidgets(nomRangee, skip: _images == null, (
          WidgetTester tester,
        ) async {
          debugPrint(
            'PNG ${await plancheRangee(tester, nom: nomRangee, cheminImage: '$_images/${ecran.image}', captures: <String>[for (final (String, Size, double, double) f in _formats) cheminSortie('adx_${ecran.code}_${f.$1}_${mode.name}')])}',
          );
        });
      }
    }
  });
}
