// CAP29-H : captures du VRAI Flutter de la bibliotheque d'administration, cinq
// ecrans sur quatre cadrages. Sautees sans `CAPTURE_DIR`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../support/monter_admin_demo.dart' as hote;
import 'outil_capture.dart';

const List<(String, Size, double)> _cadrages = <(String, Size, double)>[
  ('320_x2', Size(320, 700), 2),
  ('390_x1', Size(390, 844), 1),
  ('768_x1', Size(768, 1024), 1),
  ('1440_x1', Size(1440, 900), 1),
];

void main() {
  setUpAll(() async {
    if (dossierCapture != null) await chargerPolicesDuDepot();
  });

  final Map<String, String> ecrans = <String, String>{
    'catalogue': Routes.adminPedagogieBibliotheque,
    'fiche': Routes.adminPedagogieSupport('demo-support-002'),
    'import': Routes.adminPedagogieBibliothequeNouveau,
    'publication': Routes.adminPedagogieSupportPublication('demo-support-002'),
    'attribution': Routes.adminPedagogieSupportAttribution('demo-support-003'),
  };

  group('captures bibliotheque admin', skip: sautSansCapture, () {
    for (final MapEntry<String, String> e in ecrans.entries) {
      for (final (String cas, Size taille, double echelle) in _cadrages) {
        testWidgets('${e.key}_$cas', (WidgetTester tester) async {
          await hote.monterAdminDemo(
            tester,
            route: e.value,
            plus: <Override>[
              // Pas de base locale native dans un test : preferences en memoire.
              stockagePreferencesProvider.overrideWithValue(
                StockagePreferencesMemoire(),
              ),
            ],
            bibliotheque: BibliothequeAdminDemo(),
            taille: taille,
            echelle: echelle,
          );
          await hote.stabiliser(tester);
          expect(tester.takeException(), isNull);
          await capturerVue(tester, 'bibliotheque_admin_${e.key}_$cas');
        });
      }
    }
  });
}
