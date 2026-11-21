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

    // PERSONNES-UNE-PAGE (e).
    test('un dossier ouvert depuis Personnes : Personnes, l onglet, la vue, '
        'les filtres, la personne', () {
      final String depuisPersonnes = Routes.adminPersonnesCandidaturePour(
        'CAND-00012',
        fileDeLaListe: const <String, String>{
          'file': 'enseignants',
          'vue': 'actifs',
          'phase': 'en_poste',
          'phase_file': 'en_poste',
          'tri': 'recente',
          'page': '2',
        },
      );
      final Uri retour = Uri.parse(
        retourLogiqueBureau(adresse: Uri.parse(depuisPersonnes), plan: plan)!,
      );
      expect(retour.path, Routes.adminPersonnes);
      expect(retour.queryParameters, <String, String>{
        'onglet': 'enseignants',
        'vue': 'actifs',
        'phase': 'en_poste',
        'tri': 'recente',
        'page': '2',
        'element': 'CAND-00012',
      });
      // Le fil d'Ariane : sous « Personnes », plus sous « Candidatures ».
      final List<SegmentFil> fil = ancetresFil(
        plan: plan,
        chemin: depuisPersonnes,
      );
      expect(fil.last.chemin, retour.toString());
      expect(
        fil.any(
          (SegmentFil s) => s.chemin == Routes.adminPersonnesCandidatures,
        ),
        isFalse,
      );
    });

    test('un dossier de l ancienne liste (sans vue) : la liste des '
        'candidatures, celle que l associe peut lire', () {
      expect(
        adressePersonnesDeLaFile(const <String, String>{}, 'CAND-1'),
        null,
      );
      expect(
        adressePersonnesDeLaFile(const <String, String>{
          'etape': 'entretien',
        }, 'CAND-1'),
        isNull,
      );
    });

    test('une page secondaire de Personnes rechargee : Personnes, pas '
        'l Accueil', () {
      for (final String page in <String>[
        Routes.adminPersonnesDossiers,
        Routes.adminPersonnesComptes,
        Routes.adminPersonnesEnseignants,
        Routes.adminPersonnesReprises,
        Routes.adminPersonnesImport,
        Routes.adminPersonnesSuppressions,
        Routes.adminPersonnesInvitations,
        Routes.adminPersonnesEquipe,
        Routes.adminPersonnesAdmissions,
      ]) {
        expect(
          retourLogiqueBureau(adresse: Uri.parse(page), plan: plan),
          Routes.adminPersonnes,
          reason: page,
        );
      }
    });

    test('un onglet de rubrique ou une rubrique : l Accueil', () {
      for (final String page in <String>[
        Routes.adminPersonnesCandidatures,
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
