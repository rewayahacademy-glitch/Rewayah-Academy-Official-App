// PORTS-COMPTABLE (garde-cap, 11/11/2026) : les Paiements du Comptable, seul
// domaine des lots a, b et d qui tombe a un seul onglet, en production (ports
// des contractuels et des profils de paiement « indisponibles ») : la barre
// d'onglets n'est plus montree, et le titre dit toujours ou l'on est.
// Sautees sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';

import '../features/comptable/paiements/support_paiements.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/demo/comptable/paiements_demo.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

void main() {
  group(
    'Capture PORTS-COMPTABLE : Paiements a un seul onglet',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      setUp(masquerRubanDebug);

      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final int largeur = taille.width.toInt();
        testWidgets('paiements du comptable, $largeur', (
          WidgetTester tester,
        ) async {
          await monterRouteur(
            tester,
            Routes.comptablePaiements,
            source: FausseSourceSession(sessionActive(AppRole.accountant)),
            taille: taille,
            surcharges: <Override>[
              portObligationsPayablesProvider.overrideWithValue(
                ObligationsPayablesDemo(EtatDemoPaiements()),
              ),
              ...surchargesCommunes(),
            ],
          );
          await stabiliser(tester);
          expect(find.byType(SelecteurSection<int>), findsNothing);
          expect(find.text(t.comptable.paiements.titre), findsWidgets);
          await capturerVue(tester, 'ports_comptable_paiements_$largeur');
        });
      }
    },
  );
}
