// AD-M2-CAPT : la revue d'un dossier EN PRODUCTION (adaptateur de production,
// avant BR-1), a 390, 1440 et 320, en clair et en sombre. La consultation de
// la piece et la decision y sont indisponibles : « La consultation de la
// pièce est indisponible pour le moment. » et « La décision est indisponible
// pour le moment. » (une seule fois), aucun Refuser ni Valider.
//
// Meme montage que `test/features/dossiers_admin_test.dart` (ServiceValidation
// factice sous `surchargeRevueDossiersProduction`), sans demonstration. Saute
// sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ad_m2_production_<LxH>_<light|dark>.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';

import '../support/dossiers_production.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _vues = <(Size, double, String)>[
  (Size(390, 844), 3, '390x844'),
  (Size(1440, 900), 1, '1440x900'),
  (Size(320, 640), 2, '320x640'),
];

void main() {
  group('Capture : revue en production (AD-M2-CAPT)', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final (Size taille, double densite, String nom) in _vues) {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('$nom, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite);
          final FauxServiceValidation service = FauxServiceValidation()
            ..file = <DossierAValider>[
              DossierAValider(
                documentId: 'doc1',
                profilId: 'p1',
                type: TypePiece.carteIdentite,
                cleObjet: 'p1/piece.webp',
                deposeLe: DateTime.utc(2026, 9, 4),
                prenom: 'Moussa',
                nom: 'Barry',
                identifiantImmuable: 'TEACHER-MB-000001',
                role: AppRole.teacher,
              ),
            ];
          await tester.pumpWidget(
            hoteCapture(
              const DossiersPage(),
              themeMode: mode,
              surcharges: <Override>[
                serviceValidationProvider.overrideWithValue(service),
                surchargeRevueDossiersProduction,
              ],
            ),
          );
          await stabiliser(tester);
          expect(
            await ouvrirPremierDossier(tester),
            isTrue,
            reason: 'la file ADM-02A est vide : aucun dossier a ouvrir',
          );
          await stabiliser(tester);

          // Depuis AD-M3-PROD, la piece et la decision sont fermees : chaque
          // phrase est dite une fois, aucun Voir la piece, Refuser ni Valider.
          expect(find.text(t.dossiers.revue.pieceIndisponible), findsOneWidget);
          expect(
            find.text(t.dossiers.revue.etats.decisionIndisponible),
            findsOneWidget,
          );
          expect(find.text(t.dossiers.revue.voirPiece), findsNothing);
          expect(find.text(t.dossiers.refuser), findsNothing);
          expect(find.text(t.dossiers.approuver), findsNothing);
          // Cadrage : la phrase de decision est la derniere de la fiche ; on la
          // ramene a l'ecran (a 320 elle etait hors cadre).
          await tester.ensureVisible(
            find.text(t.dossiers.revue.etats.decisionIndisponible),
          );
          await stabiliser(tester);
          final String suffixe = mode == ThemeMode.light ? 'light' : 'dark';
          debugPrint(
            'PNG ${await capturer(tester, 'ad_m2_production_${nom}_$suffixe')}',
          );
        });
      }
    }
  });
}
