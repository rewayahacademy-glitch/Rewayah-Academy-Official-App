// R-FIN-12 (spec §52) : « Admin consulte enseignant : aucun `Modifier les
// coordonnees` ». Test dedie demande par la revue CPT-R (m6) : jusque-la,
// tenu seulement par absence du libelle.
//
// Ce que l'admin voit d'un enseignant : sa ligne dans les comptes
// (`/admin/personnes/comptes`, ADM-08). Ce qu'il ne voit pas : le profil de
// paiement du Comptable (`/comptable/beneficiaires/...`), dont il est renvoye
// a sa racine. Dans les deux cas, aucune action de modification des
// coordonnees de paiement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  @override
  Future<List<CompteAdmin>> comptes() async => <CompteAdmin>[
    CompteAdmin(
      profilId: 'p-ens-1',
      identifiant: 'TEACHER-AS-000001',
      prenom: 'Aicha',
      nom: 'Sow',
      role: AppRole.teacher,
      etat: AccountStatus.active,
      inscritLe: DateTime(2026, 9, 1),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.validee,
      contrats: 2,
      aEnseignant: false,
      enfantsDuFoyer: 0,
    ),
  ];
}

/// Aucune action qui modifierait des coordonnees : ni « Modifier les
/// coordonnees », ni un « Modifier » a cote du mot « coordonnees ».
void _aucuneModificationDeCoordonnees() {
  expect(find.textContaining('Modifier les coordonnées'), findsNothing);
  expect(
    find.byWidgetPredicate(
      (Widget w) =>
          w is Text &&
          (w.data ?? '').contains('oordonnées') &&
          (w.data ?? '').toLowerCase().contains('modifier'),
    ),
    findsNothing,
  );
}

void main() {
  testWidgets('R-FIN-12 : l admin consulte un enseignant dans les comptes, '
      'aucun « Modifier les coordonnees »', (WidgetTester tester) async {
    await tester.pumpWidget(
      hote(
        // Comptes par role (30/10/2026) : l'enseignant est dans sa vue.
        const ComptesPage(requete: <String, String>{'vue': 'enseignants'}),
        surcharges: <Override>[
          serviceComptesProvider.overrideWithValue(_Comptes()),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aicha'), findsWidgets);
    _aucuneModificationDeCoordonnees();
  });

  testWidgets('R-FIN-12 : l admin n ouvre pas le profil de paiement d un '
      'enseignant, renvoye a sa racine', (WidgetTester tester) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      Routes.comptableBeneficiairePour(SocleComptableDemo.enseignants.first.id),
      source: FausseSourceSession(sessionActive(AppRole.admin)),
    );
    expect(routeur.routerDelegate.currentConfiguration.uri.path, Routes.admin);
    expect(find.byType(ProfilPaiementPage), findsNothing);
    _aucuneModificationDeCoordonnees();
  });
}
