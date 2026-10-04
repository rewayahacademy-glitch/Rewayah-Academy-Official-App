// AD-M2-CAPT : la revue d'un dossier EN PRODUCTION (adaptateur de production,
// avant BR-1), a 390, 1440 et 320, en clair et en sombre. La consultation de
// la piece et la decision y sont indisponibles : « La consultation de la
// pièce est indisponible pour le moment. » et « La décision est indisponible
// pour le moment. » (une seule fois), aucun Refuser ni Valider.
//
// Meme montage que `test/features/dossiers_admin_test.dart` (ServiceValidation
// factice sous `surchargeRevueDossiersProduction`), sans demonstration. Saute
// sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ad_m2_production_<revue|piece>_<LxH>_<light|dark>.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';

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

          final String suffixe = mode == ThemeMode.light ? 'light' : 'dark';
          // La piece : l'apercu est ferme, la visionneuse le dit.
          await tester.ensureVisible(find.text(t.dossiers.revue.voirPiece));
          await stabiliser(tester);
          await tester.tap(find.text(t.dossiers.revue.voirPiece));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await stabiliser(tester);
          expect(find.text(t.dossiers.revue.pieceIndisponible), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'ad_m2_production_piece_${nom}_$suffixe')}',
          );

          // Piece vue (ou tentee) : la decision, dite une fois, sans Refuser
          // ni Valider grises.
          await tester.tap(
            find.descendant(
              of: find.byType(VisionneusePiece),
              matching: find.text(t.commun.fermer),
            ),
          );
          await stabiliser(tester);
          expect(
            find.text(t.dossiers.revue.etats.decisionIndisponible),
            findsOneWidget,
          );
          expect(find.text(t.dossiers.refuser), findsNothing);
          expect(find.text(t.dossiers.approuver), findsNothing);
          debugPrint(
            'PNG ${await capturer(tester, 'ad_m2_production_revue_${nom}_$suffixe')}',
          );
        });
      }
    }
  });
}
