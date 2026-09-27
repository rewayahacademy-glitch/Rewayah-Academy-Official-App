import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart' show EtatPiece;
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_dossiers/dossiers_page.dart';

import '../support/dossiers_production.dart';
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

/// Vrai quand le bouton [libelle] se presse. Un bouton ferme n'est pas
/// rendu (HL-A-5) : absent vaut ferme.
bool _actif(WidgetTester tester, String libelle) =>
    find.text(libelle).evaluate().isNotEmpty &&
    tester
            .widget<ActionPrincipale>(
              find
                  .ancestor(
                    of: find.text(libelle),
                    matching: find.byType(ActionPrincipale),
                  )
                  .first,
            )
            .onPress !=
        null;

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
          surchargeRevueDossiersProduction,
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await ouvrirPremierDossier(tester);
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
      // AD-6 : l'identifiant immuable n'est plus affiche dans le detail.
      expect(find.textContaining('TEACHER-AS-000001'), findsNothing);
      // HL-A-5 : la raison est dite une fois, dans la carte ; l'emplacement
      // de decision dit « pas pret ».
      expect(
        find.text('La pièce requise n’a pas été transmise.'),
        findsOneWidget,
      );
      expect(
        find.text("Ce dossier n'est pas encore prêt à être validé."),
        findsOneWidget,
      );
      expect(
        find.text('Ce dossier ne peut pas être refusé dans son état actuel.'),
        findsOneWidget,
      );
      // AD-6 : les deux decisions sont presentes mais fermees, avec leur
      // raison ; la base refuserait un verdict sans piece.
      expect(_actif(tester, 'Valider le dossier'), isFalse);
      expect(_actif(tester, 'Refuser le dossier'), isFalse);
      // La carte des verifications reste (§10.4, §26 ter, AD-6), mais
      // aucune case ne se coche : il n'y a rien a verifier.
      expect(find.text('Vérifications'), findsOneWidget);
      await tester.ensureVisible(find.text('La pièce est lisible').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('La pièce est lisible').first);
      await tester.pumpAndSettle();
      expect(_actif(tester, 'Valider le dossier'), isFalse);
    },
  );

  testWidgets(
    'une piece hors de portee le dit, et ne se confond pas avec une absence',
    (WidgetTester tester) async {
      await monter(tester, <DossierAValider>[
        _dossier(piece: EtatPiece.nonVisible),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text('Pièce hors de votre portée'), findsOneWidget);
      expect(find.text('Aucune pièce déposée'), findsNothing);
      expect(_actif(tester, 'Valider le dossier'), isFalse);
    },
  );

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
    // Valider n'apparait qu'une fois la piece lue et verifiee (HL-A-5) ;
    // d'ici la, sa raison tient sa place.
    expect(find.text('Valider le dossier'), findsNothing);
    expect(find.text('Refuser le dossier'), findsWidgets);
    expect(find.text('Aucune pièce déposée'), findsNothing);
  });
}
