// Captures de recette de FILTRES-1b : chaque ecran a filtres de la branche
// commune (les cas de `test/features/filtres1_rangee_unique_test.dart`,
// doubles en memoire, vraies polices), en six vues :
//
//   * 320x568 texte x2 (hauteur d'un telephone reel), LTR et RTL, clair ;
//   * 320x568 texte x2, Interface guidee ;
//   * 390x844, clair ; 1440x900, clair ;
//   * 390x844, sombre ;
//   * 390x844, Interface guidee (theme `InterfaceMode.enfant`).
//
// Plus des vues d'Observations (admin) avec un tuteur et un eleve retenus,
// de 700 a 1440, texte x1 et x2, LTR et RTL (une seule rangee a cote de la
// recherche ; la personne retenue en dernier se voit entiere).
//
// La rangee de filtres est amenee dans la vue (defilement vertical
// seulement) : on la voit comme a l'ouverture. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`). Sortie versionnee dans
// `docs/current/captures/FILTRES-1b/`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/features/admin_observations/observations_admin_page.dart';

import '../features/filtres1_rangee_unique_test.dart'
    show CasFiltres1, casFiltres1;
import 'outil_capture.dart';

String _nom(String cas) => cas
    .toLowerCase()
    .replaceAll(RegExp(r'\(.*\)'), '')
    .trim()
    .replaceAll(RegExp('[^a-z0-9]+'), '_');

typedef _Vue = ({
  String nom,
  Size taille,
  double echelle,
  TextDirection sens,
  Brightness eclairage,
  InterfaceMode mode,
});

const List<_Vue> _vues = <_Vue>[
  (
    nom: '320_x2_ltr',
    taille: Size(320, 568),
    echelle: 2,
    sens: TextDirection.ltr,
    eclairage: Brightness.light,
    mode: InterfaceMode.standard,
  ),
  (
    nom: '320_x2_rtl',
    taille: Size(320, 568),
    echelle: 2,
    sens: TextDirection.rtl,
    eclairage: Brightness.light,
    mode: InterfaceMode.standard,
  ),
  (
    nom: '320_x2_guidee',
    taille: Size(320, 568),
    echelle: 2,
    sens: TextDirection.ltr,
    eclairage: Brightness.light,
    mode: InterfaceMode.enfant,
  ),
  (
    nom: '390',
    taille: Size(390, 844),
    echelle: 1,
    sens: TextDirection.ltr,
    eclairage: Brightness.light,
    mode: InterfaceMode.standard,
  ),
  (
    nom: '1440',
    taille: Size(1440, 900),
    echelle: 1,
    sens: TextDirection.ltr,
    eclairage: Brightness.light,
    mode: InterfaceMode.standard,
  ),
  (
    nom: '390_sombre',
    taille: Size(390, 844),
    echelle: 1,
    sens: TextDirection.ltr,
    eclairage: Brightness.dark,
    mode: InterfaceMode.standard,
  ),
  (
    nom: '390_guidee',
    taille: Size(390, 844),
    echelle: 1,
    sens: TextDirection.ltr,
    eclairage: Brightness.light,
    mode: InterfaceMode.enfant,
  ),
];

Widget _hote(Widget ecran, List<Override> surcharges, _Vue v) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.pour(v.mode, v.eclairage),
        locale: AppLocale.fr.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (BuildContext contexte, Widget? app) => MediaQuery(
          data: MediaQuery.of(contexte)
              .copyWith(textScaler: TextScaler.linear(v.echelle)),
          child: Directionality(textDirection: v.sens, child: app!),
        ),
        home: ecran,
      ),
    ),
  ),
);

Future<void> _monter(
  WidgetTester tester,
  Widget ecran,
  List<Override> surcharges,
  _Vue v,
) async {
  tester.view.physicalSize = v.taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_hote(ecran, surcharges, v));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _rangeeEnVue(WidgetTester tester) async {
  final Finder rangee = find.byType(RangeeFiltres);
  if (rangee.evaluate().isNotEmpty) {
    await tester.ensureVisible(rangee.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('FILTRES-1b : captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    final List<CasFiltres1> cas = casFiltres1();
    for (int i = 0; i < cas.length; i++) {
      for (final _Vue v in _vues) {
        testWidgets('${cas[i].nom} ${v.nom}', (WidgetTester tester) async {
          final CasFiltres1 c = casFiltres1()[i];
          await _monter(tester, c.ecran, c.surcharges, v);
          await _rangeeEnVue(tester);
          await capturer(tester, 'filtres1b_${_nom(c.nom)}_${v.nom}');
        });
      }
    }

    // Observations (admin), tuteur et eleve retenus : une seule rangee.
    final CasFiltres1 obs = cas.firstWhere(
      (CasFiltres1 c) => c.nom.startsWith('Observations'),
    );
    for (final (double largeur, double echelle, TextDirection sens)
        in <(double, double, TextDirection)>[
          (700, 1, TextDirection.ltr),
          (1024, 1, TextDirection.ltr),
          (1024, 2, TextDirection.ltr),
          (1440, 2, TextDirection.ltr),
          (1440, 2, TextDirection.rtl),
        ]) {
      testWidgets('Observations personnes retenues $largeur x$echelle '
          '${sens.name}', (WidgetTester tester) async {
        final _Vue v = (
          nom: '',
          taille: Size(largeur, 900),
          echelle: echelle,
          sens: sens,
          eclairage: Brightness.light,
          mode: InterfaceMode.standard,
        );
        await _monter(tester, obs.ecran, obs.surcharges, v);
        final Finder champ = find.descendant(
          of: find.byType(RechercheObservations),
          matching: find.byType(TextField),
        );
        for (final (String saisie, String cle) in <(String, String)>[
          ('Fatou', 'personne-tuteur-fatoumata'),
          ('Mari', 'personne-eleve-mariam'),
        ]) {
          await tester.enterText(champ, saisie);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey<String>(cle)));
          await tester.pumpAndSettle();
        }
        await capturer(
          tester,
          'filtres1b_observations_personnes_${largeur.toInt()}_'
          'x${echelle.toInt()}_${sens.name}',
        );
      });
    }
  }, skip: sautSansCapture);
}
