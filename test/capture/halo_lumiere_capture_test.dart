// Captures du lot HALO 2a-bis (pilote, 11/11/2026) : la lumiere « a
// preparer » autour d'un rectangle arrondi (une carte), en mouvement puis en
// lueur fixe, clair et sombre ; et l'arbitre de l'ecran : le cercle Compte
// en urgence tourne, la carte orange de la page reste en lueur fixe.
//
// Donnees de test seulement. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/harnais.dart' show sansPersonneConnectee;
import 'outil_capture.dart';

/// Une carte de la page entouree de la lumiere « a preparer ».
Widget _carte() => const SizedBox(
  height: 96,
  child: Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned.fill(child: LayoutBuilder(builder: _lumiere)),
      Positioned.fill(
        child: AppCard(child: Text('Carte de test : à préparer')),
      ),
    ],
  ),
);

Widget _lumiere(BuildContext _, BoxConstraints c) => HaloLumiere(
  nature: NatureHalo.aPreparer,
  forme: FormeHalo.rectangle,
  arrondi: AppRadius.arrondiLg,
  taille: c.biggest,
);

void main() {
  group('Capture : HaloLumiere et arbitre', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, ThemeMode theme, bool enMouvement)
        in <(String, ThemeMode, bool)>[
          ('rectangle_a-preparer_rotation_clair', ThemeMode.light, true),
          ('rectangle_a-preparer_lueur_clair', ThemeMode.light, false),
          ('rectangle_a-preparer_lueur_sombre', ThemeMode.dark, false),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 300), 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: _carte()),
              ),
            ),
            themeMode: theme,
          ),
        );
        if (enMouvement) {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
        } else {
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'halo-lumiere_$nom')}');
      });
    }

    testWidgets('arbitre_cercle-urgent-tourne_carte-orange-fixe', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 700), 1);
      final List<Destination> d = destinationsPour(
        role: AppRole.guardian,
        mode: InterfaceMode.standard,
      );
      await tester.pumpWidget(
        hoteCapture(
          NavShell(
            destinations: d,
            indexActif: 0,
            onAller: (_) {},
            halo: EtatHaloCompte.urgent(
              titre: 'Alerte de test',
              chemin: Routes.tuteurNotifications,
            ),
            child: PageShell(titre: d.first.libelle, child: _carte()),
          ),
          surcharges: <Override>[sansPersonneConnectee()],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'halo-lumiere_arbitre_cercle-urgent-tourne_carte-orange-fixe')}',
      );
    });
  });
}
