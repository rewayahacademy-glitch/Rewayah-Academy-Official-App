// Captures avant / apres de BENTO-1 : le Centre de commande de la direction,
// dont les six compteurs etaient six carres identiques (damier).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Meme fichier lance sur la base (avant) puis sur la branche (apres) : seul
// `CAPTURE_DIR` change. Voir LISEZ-MOI.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

Widget _tableau() => TableauDeBordPage(horloge: () => DateTime(2026, 9, 8, 17));

List<Override> _surcharges() => <Override>[
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()
      ..indicateursRendus = const IndicateursAdmin(
        dossiersEnAttente: 3,
        foyersSansEnseignant: 2,
        rapportsManquants: 1,
        incidents24h: 0,
        comptesEchus: 0,
        demandesEnAttente: 4,
      ),
  ),
  serviceValidationProvider.overrideWithValue(
    FauxServiceValidation()
      ..file = <DossierAValider>[
        for (int i = 0; i < 3; i++)
          DossierAValider(
            documentId: 'doc$i',
            profilId: 'p$i',
            type: TypePiece.carteIdentite,
            cleObjet: 'p/$i.webp',
            deposeLe: DateTime(2026, 9, 5 + i),
            prenom: 'Moussa$i',
            nom: 'Barry',
            identifiantImmuable: 'TEACHER-MB-00000$i',
            role: AppRole.teacher,
          ),
      ],
  ),
];

void main() {
  group('Capture : BENTO-1 Centre de commande', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size, ThemeMode, String, double) cas
        in <(Size, ThemeMode, String, double)>[
          (
            const Size(320, 1500),
            ThemeMode.light,
            'centre_commande_320_clair',
            1,
          ),
          (
            const Size(1440, 1100),
            ThemeMode.light,
            'centre_commande_1440_clair',
            1,
          ),
          (
            const Size(390, 1500),
            ThemeMode.dark,
            'centre_commande_390_sombre',
            1,
          ),
          // BENTO-1b : texte double, une colonne a 320 px, plusieurs a 1440.
          (
            const Size(320, 3000),
            ThemeMode.light,
            'centre_commande_320x2_clair',
            2,
          ),
          (
            const Size(1440, 2400),
            ThemeMode.light,
            'centre_commande_1440x2_clair',
            2,
          ),
        ]) {
      testWidgets(cas.$3, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$1, 1);
        await tester.pumpWidget(
          hoteCapture(
            _tableau(),
            surcharges: _surcharges(),
            themeMode: cas.$2,
            echelleTexte: cas.$4,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, cas.$3)}');
      });
    }
  });
}
