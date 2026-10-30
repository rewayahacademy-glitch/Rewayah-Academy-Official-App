// Admission, lot B (directeur, 29/10/2026) : une eleve adulte inscrite « pour
// moi » arrivait sur l'accueil du tuteur et a du ajouter un profil eleve pour
// etre placee dans une classe. Le titulaire « Je m'inscris pour moi », eleve
// autonome, atterrit desormais sur l'accueil de l'eleve adulte ; le parent qui
// suit aussi des cours garde l'accueil du tuteur.

import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/atterrissage_adulte.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';

import '../../router/support_routeur.dart' show lieu;
import 'support_accueil_adulte_route.dart';

EtatDossier _titulaire(UsageTitulaire usage) => EtatDossier(
  profilExiste: true,
  role: AppRole.guardian,
  statutCompte: AccountStatus.active,
  accuseSigne: true,
  contratSigne: true,
  codeConduiteSigne: true,
  pieceDeposee: false,
  usage: usage,
);

List<Override> _surcharges(UsageTitulaire usage) => <Override>[
  ...surchargesAccueilAdulte(
    accueil: Valeur(accueilDemo()),
    historique: Valeur(DonneesAdulteDemo.historiqueSeances()),
  ),
  usageTitulaireProvider.overrideWith(
    (Ref _, String _) async => _titulaire(usage).usage,
  ),
];

const SessionState _actif = SessionState(
  resolue: true,
  role: AppRole.guardian,
  profileId: 'p-guardian',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  eleveAutonome: true,
);

void main() {
  group('redirection', () {
    test('« pour moi » : la racine et l accueil du tuteur menent a l accueil '
        'adulte', () {
      for (final String chemin in <String>[
        Routes.racine,
        Routes.connexion,
        Routes.tuteurAccueil,
      ]) {
        expect(
          deciderRedirection(
            session: _actif,
            cheminDemande: chemin,
            maintenant: DateTime(2026, 10, 29),
            atterrissageAdulte: true,
          ),
          Routes.eleveAdulte,
          reason: chemin,
        );
      }
    });

    test('« pour moi » : le reste de l espace du tuteur reste ouvert', () {
      expect(
        deciderRedirection(
          session: _actif,
          cheminDemande: Routes.tuteurFoyer,
          maintenant: DateTime(2026, 10, 29),
          atterrissageAdulte: true,
        ),
        isNull,
      );
    });

    test('sans atterrissage adulte : l accueil du tuteur, comme avant', () {
      expect(
        deciderRedirection(
          session: _actif,
          cheminDemande: Routes.racine,
          maintenant: DateTime(2026, 10, 29),
        ),
        Routes.tuteurAccueil,
      );
    });
  });

  group('vrai routeur', () {
    testWidgets('« Je m inscris pour moi » : l accueil adulte, sans profil '
        'eleve a ajouter', (WidgetTester tester) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: _surcharges(UsageTitulaire.moi),
      );
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.eleveAdulte);
      expect(find.byType(AccueilAdultePage), findsOneWidget);
    });

    testWidgets('parent qui suit aussi des cours : l accueil du tuteur', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterAccueilAdulteReel(
        tester,
        surcharges: _surcharges(UsageTitulaire.famille),
      );
      await tester.pumpAndSettle();
      expect(lieu(routeur), Routes.tuteurAccueil);
      expect(find.byType(AccueilAdultePage), findsNothing);
    });
  });
}
