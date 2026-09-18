import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart' show EtatPiece;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';

import '../support/harnais.dart';

/// `ADM-02` apres la migration `0015` : la file contient des **personnes**, pas
/// seulement des documents.
///
/// Trois enseignants inscrits les 11 et 15 septembre 2026, contrats signes,
/// sans piece deposee, n'apparaissaient nulle part : `dossiers_en_attente()`
/// lisait `kyc_documents where status = 'pending'`. Ils sont desormais dans
/// cette file, et l'ecran doit tenir les deux cas sans jamais proposer un
/// verdict qui echouerait en base.
DossierAValider _dossier({
  required EtatPiece piece,
  String? documentId,
  String? cleObjet,
  int joursDepuisInscription = 7,
}) => DossierAValider(
  documentId: documentId,
  profilId: 'profil-1',
  type: documentId == null ? null : TypePiece.carteIdentite,
  cleObjet: cleObjet,
  deposeLe: DateTime.now().subtract(Duration(days: joursDepuisInscription)),
  prenom: 'Aicha',
  nom: 'Sow',
  identifiantImmuable: 'TEACHER-AS-000001',
  role: AppRole.teacher,
  etatPiece: piece,
  inscritLeConnue: DateTime.now().subtract(
    Duration(days: joursDepuisInscription),
  ),
  etatCompte: AccountStatus.pendingKyc,
);

void main() {
  Future<FauxServiceValidation> monter(
    WidgetTester tester,
    List<DossierAValider> file,
  ) async {
    final FauxServiceValidation service = FauxServiceValidation()..file = file;
    await tester.pumpWidget(
      hote(
        const DossiersPage(),
        surcharges: <Override>[
          serviceValidationProvider.overrideWithValue(service),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets(
    'une personne sans piece est visible, dit ce qui manque, et n offre aucun verdict',
    (WidgetTester tester) async {
      await monter(tester, <DossierAValider>[
        _dossier(piece: EtatPiece.aucune),
      ]);

      expect(tester.takeException(), isNull);
      // La personne est la — c'est tout l'objet de la migration 0015.
      expect(find.textContaining('Aicha Sow'), findsWidgets);
      expect(find.textContaining('TEACHER-AS-000001'), findsWidgets);
      expect(find.text('Aucune pièce déposée'), findsOneWidget);
      expect(find.text('Rien à trancher pour l\'instant'), findsOneWidget);
      // Aucun verdict : la base refuserait, et un bouton qui echoue apres le
      // geste coute plus cher en confiance qu'un bouton absent.
      expect(find.text('Valider le dossier'), findsNothing);
      expect(find.text('Refuser'), findsNothing);
      // Ni la checklist, qui n'a rien a verifier.
      expect(find.text('Vérifications'), findsNothing);
    },
  );

  testWidgets('une piece hors de portee le dit, et ne se confond pas avec une absence', (
    WidgetTester tester,
  ) async {
    await monter(tester, <DossierAValider>[
      _dossier(piece: EtatPiece.nonVisible),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Pièce hors de votre portée'), findsOneWidget);
    expect(find.text('Aucune pièce déposée'), findsNothing);
    expect(find.text('Valider le dossier'), findsNothing);
  });

  testWidgets('une piece a verifier garde la checklist et les deux verdicts', (
    WidgetTester tester,
  ) async {
    await monter(tester, <DossierAValider>[
      _dossier(
        piece: EtatPiece.aVerifier,
        documentId: 'doc-1',
        cleObjet: 'kyc/doc-1.jpg',
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Vérifications'), findsOneWidget);
    expect(find.text('Valider le dossier'), findsOneWidget);
    expect(find.text('Refuser'), findsWidgets);
    expect(find.text('Aucune pièce déposée'), findsNothing);
  });
}
