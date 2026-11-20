// PE-D12 (pilote, 20/11/2026 : « un geste qui montre une attente sans rien
// relire trompe la personne ») : tirer l'accueil du candidat (`/attente`) vers
// le bas relit vraiment son dossier. Le faux service du dossier compte ses
// lectures ; la relecture est la vraie (`RelectureGenerale`).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_accord_publication.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/fraicheur/relecture_page.dart';
import 'package:rewayah_academy/core/fraicheur/veille_fraicheur.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';

import '../../features/candidature/hote_candidature.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';

/// Le service du dossier qui compte ses lectures.
class _DossierCompte extends FauxServiceDossier {
  int lectures = 0;

  @override
  Future<EtatDossier> etat() {
    lectures++;
    return super.etat();
  }
}

void main() {
  test('les lectures du geste couvrent l accueil du candidat', () {
    expect(lecturesDuGeste, isNotEmpty);
  });

  testWidgets('tirer /attente vers le bas relit le dossier du candidat', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _DossierCompte dossier = _DossierCompte()
      ..etatRendu = etatCandidat(
        candidature: const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
          version: 5,
        ),
      );
    // Une session avec un profil : sans profil, aucune lecture ne part (R9).
    final List<Override> surcharges = <Override>[
      portAccordPublicationProvider.overrideWithValue(
        FauxAccordPublication(enCours: true),
      ),
      serviceDossierProvider.overrideWithValue(dossier),
      portMaCandidatureProvider.overrideWithValue(FauxMaCandidature()),
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          const SessionState(
            resolue: true,
            role: AppRole.teacher,
            profileId: 'p-candidat',
            accountStatus: AccountStatus.pendingKyc,
            lectureProfil: LectureProfil.presente,
          ),
        ),
      ),
    ];
    await tester.pumpWidget(
      hoteRoutant(
        depart: Routes.attente,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.attente,
            builder: (BuildContext _, GoRouterState _) =>
                const RelectureGenerale(child: AttentePage()),
          ),
        ],
        surcharges: surcharges,
      ),
    );
    await tester.pumpAndSettle();
    final int avant = dossier.lectures;
    expect(find.byType(RefreshIndicator), findsOneWidget);
    // Dans l'application, la session est toujours ecoutee ; ici, on l'ecoute
    // une fois pour qu'elle porte le profil.
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(AttentePage)),
    );
    final ProviderSubscription<SessionState> ecoute = conteneur.listen(
      sessionProvider,
      (SessionState? _, SessionState _) {},
    );
    addTearDown(ecoute.close);
    await tester.pumpAndSettle();
    expect(conteneur.read(sessionProvider).profileId, 'p-candidat');
    expect(avant, greaterThan(0));

    await tester.flingFrom(const Offset(195, 300), const Offset(0, 400), 1000);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(dossier.lectures, greaterThan(avant));
  });
}
