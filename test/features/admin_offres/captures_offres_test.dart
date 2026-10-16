// L2-05 : les captures de l'administration des offres vitrine. Sautees sans
// CAPTURE_DIR (voir test/capture/LISEZ-MOI.md). Ecran isole, sans la coquille
// administrateur, avec le port de demonstration.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offres_admin_demo.dart';
import 'package:rewayah_academy/core/offres/port_offres_admin.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_offres/admin_offres_page.dart';

import '../../capture/outil_capture.dart';

Future<void> _prendre(
  WidgetTester tester, {
  required String nom,
  required double largeur,
  required double hauteur,
  bool arabe = false,
  bool sombre = false,
  bool vide = false,
  bool formulaire = false,
}) async {
  if (arabe) {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
  } else {
    LocaleSettings.setLocaleSync(AppLocale.fr);
  }
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, Size(largeur, hauteur), 1);
  masquerRubanDebug();
  await tester.pumpWidget(
    hoteCapture(
      const AdminOffresPage(),
      themeMode: sombre ? ThemeMode.dark : ThemeMode.light,
      surcharges: <Override>[
        portOffresAdminProvider.overrideWithValue(
          OffresAdminDemo(offres: vide ? <OffreAdmin>[] : null),
        ),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
    ),
  );
  await stabiliser(tester);
  if (formulaire) {
    await tester.tap(find.byKey(const ValueKey<String>('offres-nouvelle')));
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : L2-05', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets(
      'liste 390 clair',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_offres_390_light',
        largeur: 390,
        hauteur: 1100,
      ),
    );
    testWidgets(
      'liste 1440 clair',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_offres_1440_light',
        largeur: 1440,
        hauteur: 900,
      ),
    );
    testWidgets(
      'liste 1440 sombre',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_offres_1440_dark',
        largeur: 1440,
        hauteur: 900,
        sombre: true,
      ),
    );
    testWidgets(
      'liste 390 arabe',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_offres_390ar_light',
        largeur: 390,
        hauteur: 1100,
        arabe: true,
      ),
    );
    testWidgets(
      'formulaire 390 clair',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_nouvelle_offre_390_light',
        largeur: 390,
        hauteur: 1800,
        formulaire: true,
      ),
    );
    testWidgets(
      'vide 390 clair',
      (WidgetTester t) => _prendre(
        t,
        nom: 'L2-05_offres_vide_390_light',
        largeur: 390,
        hauteur: 800,
        vide: true,
      ),
    );
  });
}
