// TXT-1, UX-012 (pilote, 02/11/2026) : la ligne de presence d'un cours tenu
// dont l'etat n'a pas pu etre lu, sur le vrai ecran « Suivi » de l'eleve, a
// 390 x 844. Elle dit « Présence pas encore connue », jamais « État inconnu »,
// jamais « Absence » (invariant J3).
//
// Pourquoi une capture d'outil et non un robot de la pile locale : obtenir un
// etat de presence non lu en base demande une seance tenue sans aucune trace
// de presence ; la galerie des composants est fermee en build de production
// (`kReleaseMode`). L'ecran est le vrai `SuiviElevePage`, sur son service de
// suivi simule (comme `test/features/suivi_eleve_test.dart`), avec les vraies
// polices et le vrai theme (outil_capture.dart).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Usage : CAPTURE_DIR=docs/current/captures/E2E/txt-1 flutter test --no-pub \
//   test/capture/txt1_presence_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

final DateTime _maintenant = DateTime(2026, 9, 13, 10, 30);

Seance _seance() {
  final DateTime debut = _maintenant.subtract(const Duration(minutes: 90));
  return Seance(
    id: 's1',
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: StatutSeance.terminee,
    eleveId: 'eleve-1',
    elevePrenom: 'Sofia',
    eleveIdentifiant: 'STUD-000001',
    enseignantId: 'ens-1',
    enseignantPrenom: 'Rachid',
    enseignantIdentifiant: 'TEACH-000001',
  );
}

void main() {
  group(
    'Capture TXT-1 : presence non lue sur le Suivi',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);

      testWidgets('390x844, presence non lue', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 844), 2);
        await tester.pumpWidget(
          hoteCapture(
            SuiviElevePage(horloge: () => _maintenant),
            surcharges: <Override>[
              serviceSuiviProvider.overrideWithValue(
                FauxServiceSuivi(
                  seancesRendues: <Seance>[_seance()],
                  // La presence n'a pas pu etre lue.
                  presencesRendues: null,
                ),
              ),
            ],
          ),
        );
        await stabiliser(tester);
        expect(find.text(t.presence.inconnu), findsOneWidget);
        expect(find.text('Présence pas encore connue'), findsOneWidget);
        expect(find.text('État inconnu'), findsNothing);
        expect(find.text(t.presence.absente), findsNothing);
        debugPrint(
          'PNG ${await capturer(tester, '03_suivi_390_ligne_presence')}',
        );
      });
    },
  );
}
