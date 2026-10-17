// Captures avant / apres de la revue du directeur (CARTES-ECART-1, HIER-1) :
// reglages du compte (cartes collees), tableau de bord de la direction
// (tuiles et lignes serrees).
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
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

Widget _tableau() => TableauDeBordPage(horloge: () => DateTime(2026, 9, 8, 17));

List<Override> _surchargesTableau() => <Override>[
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

List<Override> _surchargesCompte() => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
];

void main() {
  group(
    'Capture : cartes et hierarchie (K-55, HIER-1)',
    skip: sautSansCapture,
    () {
      setUpAll(() async {
        await chargerPolicesDuDepot();
      });

      final List<(String, Widget Function(), List<Override> Function())>
      ecrans = <(String, Widget Function(), List<Override> Function())>[
        (
          'reglages_compte',
          () => const ReglagesComptePage(),
          _surchargesCompte,
        ),
        ('tableau_direction', _tableau, _surchargesTableau),
      ];

      for (final (String, Widget Function(), List<Override> Function()) e
          in ecrans) {
        for (final Size vue in <Size>[
          const Size(320, 1500),
          const Size(1440, 1100),
        ]) {
          testWidgets('${e.$1} ${vue.width.round()} px', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, vue, 1);
            await tester.pumpWidget(hoteCapture(e.$2(), surcharges: e.$3()));
            await stabiliser(tester);
            debugPrint(
              'PNG ${await capturer(tester, '${e.$1}_${vue.width.round()}')}',
            );
          });
        }
      }
    },
  );
}
