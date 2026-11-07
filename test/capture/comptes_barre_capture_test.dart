// Captures de la barre de selection de Comptes (SANS-BARRE-FIXE, option (A)
// du garde-cap, 07/11) :
// - 390 : sans selection, puis avec une selection (la barre en tete de la
//   liste, qui defile avec elle), puis au defilement 0 ;
// - 1440 : sans selection, puis avec une selection (la barre collee sous la
//   liste, sur une ligne).
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees : comptes synthetiques, aucune personne reelle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../support/harnais.dart';
import 'outil_capture.dart';

class _Service implements ServiceComptes {
  _Service(this.lus);
  final List<CompteAdmin> lus;

  @override
  Future<List<CompteAdmin>> comptes() async => lus;
}

class _Port implements PortRetraitsComptes {
  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) async => <ResultatRetrait>[];

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) => throw UnimplementedError();

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId) =>
      throw UnimplementedError();
}

CompteAdmin _eleve(int i) => CompteAdmin(
  profilId: 'p-$i',
  identifiant: 'STUDENT-AA-${'$i'.padLeft(6, '0')}',
  prenom: 'Prenom',
  nom: 'Eleve $i',
  role: AppRole.student,
  etat: AccountStatus.active,
  inscritLe: DateTime(2026, 10, 28),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
  detailsServis: true,
);

void main() {
  group('Capture : barre de selection de Comptes', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      testWidgets('${taille.width.toInt()}', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, densite);
        await tester.pumpWidget(
          hoteCapture(
            const ComptesPage(requete: <String, String>{'vue': 'eleves'}),
            surcharges: <Override>[
              serviceComptesProvider.overrideWithValue(
                _Service(<CompteAdmin>[
                  for (int i = 1; i <= 12; i++) _eleve(i),
                ]),
              ),
              portRetraitsComptesProvider.overrideWithValue(_Port()),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await stabiliser(tester);
        final String l = '${taille.width.toInt()}';
        debugPrint(
          'PNG ${await capturer(tester, 'comptes_sans_selection_$l')}',
        );
        final Finder caseUn = find
            .byWidgetPredicate(
              (Widget w) =>
                  w is CaseACocher &&
                  w.libelle.startsWith('Cocher Prenom Eleve 1'),
            )
            .first;
        await tester.ensureVisible(caseUn);
        await stabiliser(tester);
        await tester.tap(caseUn);
        await stabiliser(tester);
        expect(find.byKey(ComptesPage.barreSuppressionKey), findsOneWidget);
        debugPrint('PNG ${await capturer(tester, 'comptes_selection_$l')}');
        // Au defilement 0, la selection active (demande du garde-cap, 07/11).
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'comptes_selection_haut_$l')}',
        );
      });
    }
  });
}
