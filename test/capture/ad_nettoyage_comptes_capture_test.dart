// Captures AD-NETTOYAGE : Comptes (tri, « Sans objet », role illisible signale)
// et tuile Dossiers du Centre de commande (enseignants seulement).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Donnees
// synthetiques, horloge fixe.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._l);
  final List<CompteAdmin> _l;
  @override
  Future<List<CompteAdmin>> comptes() async => _l;
}

CompteAdmin _c(
  String id,
  AppRole? role,
  AccountStatus etat,
  String? prenom, {
  int jours = 7,
}) => CompteAdmin(
  profilId: id,
  identifiant: id,
  prenom: prenom,
  nom: prenom == null ? null : 'Sow',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(Duration(days: jours)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 2,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

List<Override> _surchargesComptes() => <Override>[
  serviceComptesProvider.overrideWithValue(
    _Comptes(<CompteAdmin>[
      _c(
        'GUARDIAN-MS-000003',
        AppRole.guardian,
        AccountStatus.pendingKyc,
        'Mariam',
      ),
      _c('STUDENT-LS-000001', AppRole.student, AccountStatus.active, 'Lina'),
      _c(
        'TEACHER-AS-000001',
        AppRole.teacher,
        AccountStatus.pendingKyc,
        'Aicha',
      ),
      _c('UNKNOWN-XX-000001', null, AccountStatus.pendingKyc, null),
    ]),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

List<Override> _surchargesTableau() => <Override>[
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()
      ..indicateursRendus = const IndicateursAdmin(
        dossiersEnAttente: 3,
        foyersSansEnseignant: 0,
        rapportsManquants: 0,
        incidents24h: 0,
        comptesEchus: 0,
        demandesEnAttente: 0,
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
            identifiantImmuable: 'ID-00000$i',
            role: i == 0 ? AppRole.teacher : AppRole.guardian,
          ),
      ],
  ),
];

void main() {
  group('Capture : AD-NETTOYAGE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String, Size, double) cas in <(String, Size, double)>[
        ('390', const Size(390, 1000), 1),
        ('1440', const Size(1440, 900), 1),
        ('320x2', const Size(320, 2400), 2),
      ]) {
        final String nom = 'ad_nettoyage_comptes_${cas.$1}_${mode.name}';
        testWidgets(nom, (WidgetTester tester) async {
          fixerVueCapture(tester, cas.$2, 1);
          await tester.pumpWidget(
            hoteCapture(
              const ComptesPage(),
              surcharges: _surchargesComptes(),
              themeMode: mode,
              echelleTexte: cas.$3,
            ),
          );
          await stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, nom)}');
        });
      }

      final String nomTableau = 'ad_nettoyage_tableau_1440_${mode.name}';
      testWidgets(nomTableau, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await tester.pumpWidget(
          hoteCapture(
            TableauDeBordPage(horloge: () => DateTime(2026, 9, 8, 17)),
            surcharges: _surchargesTableau(),
            themeMode: mode,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, nomTableau)}');
      });
    }
  });
}
