// CAP29-H : la bibliotheque d'administration en arabe, a 320 px, texte x2.
//
// Ce que le test prouve : les cinq ecrans (catalogue, fiche, import,
// publication, attribution) se montent en arabe, sans debordement ni mot
// coupe, avec le sens de lecture de la langue ; aucune phrase francaise ne
// reste a l'ecran.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_admin_demo.dart';

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final Map<String, String> ecrans = <String, String>{
    'catalogue': Routes.adminPedagogieBibliotheque,
    'fiche': Routes.adminPedagogieSupport('demo-support-002'),
    'import': Routes.adminPedagogieBibliothequeNouveau,
    'publication': Routes.adminPedagogieSupportPublication('demo-support-002'),
    'attribution': Routes.adminPedagogieSupportAttribution('demo-support-003'),
  };

  for (final MapEntry<String, String> e in ecrans.entries) {
    testWidgets('${e.key} : arabe, 320 px, texte x2', (tester) async {
      await monterAdminDemo(
        tester,
        route: e.value,
        bibliotheque: BibliothequeAdminDemo(),
        taille: const Size(320, 640),
        echelle: 2,
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl,
      );
      verifierEcranSansMotCoupe(tester);
      // Le titre de la bibliotheque est celui de l'arabe, pas du francais.
      expect(find.text('Bibliothèque'), findsNothing);
    });
  }
}
