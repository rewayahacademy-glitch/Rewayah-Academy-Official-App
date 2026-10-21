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
    expect(
      await ouvrirPremierDossier(tester),
      isTrue,
      reason: 'la file ADM-02A est vide ou en erreur : aucun dossier a ouvrir',
    );
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
      // AD-6 : sans piece transmise, valider et refuser sont presents mais
      // fermes, chacun avec sa raison (les deux messages ci-dessus).
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

  testWidgets('une piece a verifier garde la checklist ; en production, '
      'aucun verdict avant BR-1 (AD-M3-PROD)', (WidgetTester tester) async {
    final FauxServiceValidation service = await monter(
      tester,
      <DossierAValider>[
        _dossier(
          piece: EtatPiece.aVerifier,
          documentId: 'doc-1',
          cleObjet: 'kyc/doc-1.jpg',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Vérifications'), findsOneWidget);
    expect(find.text('Aucune pièce déposée'), findsNothing);
    // Decision du 27/09 (S1 -> a) : refus et piece fermes comme la
    // validation ; la raison est dite une fois a la place des boutons.
    expect(find.text('Valider le dossier'), findsNothing);
    expect(find.text('Refuser le dossier'), findsNothing);
    expect(find.text('Voir la pièce'), findsNothing);
    expect(
      find.text('La décision est indisponible pour le moment.'),
      findsOneWidget,
    );
    expect(service.apercus, isEmpty);
    expect(service.verdicts, isEmpty);
  });
}
