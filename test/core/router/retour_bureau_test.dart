// BUREAU-NAV (contrat de navigation du 20/11/2026, §4 et §6) : le parent
// logique du retour du bureau quand rien n'est empile, et le maillon de la
// liste du fil d'Ariane qui garde son filtre. Calcul pur, sans routeur.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/router/fil_ariane.dart';
import 'package:rewayah_academy/core/router/retour_bureau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';

void main() {
  final PlanFil plan = planFilPour(
    const SessionState(
      resolue: true,
      role: AppRole.admin,
      profileId: 'p1',
      accountStatus: AccountStatus.active,
      lectureProfil: LectureProfil.presente,
    ),
  )!;
  final String dossier = Routes.adminPersonnesCandidaturePour(
    'CAND-1',
    fileDeLaListe: const <String, String>{'etape': 'entretien', 'tri': 'nom'},
  );
  final String listeFiltree = Uri(
    path: Routes.adminPersonnesCandidatures,
    queryParameters: const <String, String>{'etape': 'entretien', 'tri': 'nom'},
  ).toString();

  group('retourLogiqueBureau', () {
    test('l Accueil n a pas de retour', () {
      expect(retourLogiqueBureau(adresse: Uri.parse(Routes.admin)), isNull);
    });

    test('un dossier ouvert depuis une liste : la liste et son filtre', () {
      expect(
        retourLogiqueBureau(adresse: Uri.parse(dossier), plan: plan),
        listeFiltree,
      );
    });

    test('un dossier sans file (message, lien) : la liste nue', () {
      expect(
        retourLogiqueBureau(
          adresse: Uri.parse(Routes.adminPersonnesCandidaturePour('CAND-1')),
          plan: plan,
        ),
        Routes.adminPersonnesCandidatures,
      );
    });

    test('un onglet de rubrique ou une rubrique : l Accueil', () {
      for (final String page in <String>[
        Routes.adminPersonnesCandidatures,
        Routes.adminPersonnesDossiers,
        Routes.adminPersonnes,
      ]) {
        expect(
          retourLogiqueBureau(adresse: Uri.parse(page), plan: plan),
          Routes.admin,
          reason: page,
        );
      }
    });

    test('une page sous un onglet : cet onglet', () {
      expect(
        retourLogiqueBureau(
          adresse: Uri.parse(Routes.adminPersonnesCreneauxEntretien),
          plan: plan,
        ),
        Routes.adminPersonnesCandidatures,
      );
    });
  });

  group('fil d Ariane du dossier', () {
    test('le maillon de la liste rouvre la file d ou l on vient', () {
      final List<SegmentFil> ancetres = ancetresFil(
        plan: plan,
        chemin: dossier,
      );
      expect(ancetres.last.chemin, listeFiltree);
      expect(
        ancetres.map((SegmentFil s) => s.chemin),
        isNot(contains(Routes.admin)),
      );
    });

    test('sans file, le maillon reste la liste nue', () {
      final List<SegmentFil> ancetres = ancetresFil(
        plan: plan,
        chemin: Routes.adminPersonnesCandidaturePour('CAND-1'),
      );
      expect(ancetres.last.chemin, Routes.adminPersonnesCandidatures);
    });
  });
}
