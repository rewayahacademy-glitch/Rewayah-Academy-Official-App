// EN-12 (tests) : pour chaque pose de la vague Enseignant, un test part de la
// VRAIE coquille (NavShell, quatre destinations, `app_router.dart`) et tape
// le vrai bouton qui y mene -- jamais la demonstration, jamais un hote de
// test isole. Les quatre destinations elles-memes (Aujourd'hui, Classes,
// Disponibilites, Profil) sont deja mesurees ainsi par
// `test/router/parcours_enseignant_test.dart` ; ce fichier couvre les poses
// qui s'ouvrent DEPUIS elles.
//
// ENS-13 (absence) reste hors de ce fichier : son port
// (`declarationAbsenceProvider`) vaut `null` en dehors de la demonstration
// (K-28, backend reporte a BR-1), donc aucun bouton ne l'ouvre depuis la
// vraie coquille avant BR-1. Il est mesure depuis `CoquilleEnseignantDemo`,
// elle-meme batie sur le vrai `NavShell`
// (`test/features/journee/absence_remplacement_test.dart`).
// ENS-13B (remplacement) se mesure depuis la vraie coquille depuis REMPL-1b :
// l'Alerte utile « Remplacement urgent » lit `offresCommunesProvider` et mene a
// l'ecran commun (`test/router/parcours_enseignant_test.dart`, groupe REMPL-1b).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';

import '../../support/harnais.dart';

/// Le groupe et les deux eleves de la demonstration reutilises ici (An-Nour) :
/// les memes identifiants que `enseignant_demo.dart`, pour que ce test et les
/// captures parlent de la meme Classe.
const String _groupeId = 'demo-classe-an-nour';
const String _elevePrenom = 'Yusuf';

void main() {
  /// Les memes faux que `parcours_enseignant_test.dart`, plus des donnees
  /// d'enseignant reelles (Classes, seances, eleves, cahiers en retard) : sans
  /// elles, les lignes que ce fichier tape n'existeraient pas.
  List<Override> surcharges() {
    final FauxServiceEnseignant serviceEnseignant = FauxServiceEnseignant()
      ..groupesRendus = DonneesEnseignantDemo.groupes()
      ..seancesRendues = DonneesEnseignantDemo.seances(
        EtatDemoEnseignant.nominal,
      )
      ..retardsRendus = DonneesEnseignantDemo.cahiersEnRetard(
        EtatDemoEnseignant.nominal,
      )
      ..membresRendus = <String, List<MembreSeance>>{
        _groupeId: <MembreSeance>[
          membreDeTest(studentId: 'demo-eleve-yusuf', prenom: _elevePrenom),
          membreDeTest(
            studentId: 'demo-eleve-mariam',
            identifiant: 'RA-0002',
            prenom: 'Mariam',
          ),
        ],
      };

    return <Override>[
      sourceSessionProvider.overrideWithValue(
        FausseSourceSession(
          const SessionState(
            resolue: true,
            role: AppRole.teacher,
            profileId: 'ens-1',
            householdId: 'h1',
            accountStatus: AccountStatus.active,
            lectureProfil: LectureProfil.presente,
          ),
        ),
      ),
      serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      serviceEnseignantProvider.overrideWithValue(serviceEnseignant),
      servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
      serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
      serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
      servicePriereProvider.overrideWithValue(FauxServicePriere()),
      // Profil (ENS-05A) : sans cette surcharge, `profilEnseignantProvider`
      // interroge un vrai service Supabase absent du test et la photo
      // publique ne s'affiche jamais.
      profilEnseignantProvider.overrideWith(
        (Ref _) async => DonneesEnseignantDemo.profil,
      ),
    ];
  }

  /// Monte l'application sur son **vrai** routeur, a l'adresse demandee --
  /// identique a `parcours_enseignant_test.dart` (meme lecon : brancher
  /// l'entree, pas seulement la route).
  Future<GoRouter> monter(WidgetTester tester, String depart) async {
    late GoRouter routeur;
    await tester.pumpWidget(
      ProviderScope(
        overrides: surcharges(),
        child: TranslationProvider(
          child: Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              routeur.go(depart);
              return MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return routeur;
  }

  group('ENS-07 : Mes Classes ouvre le vrai Espace Classe', () {
    testWidgets('taper la ligne de la Classe ouvre FicheGroupePage', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(tester, Routes.enseignantClasses);
      expect(find.text('An-Nour'), findsOneWidget);

      await tester.tap(find.text('An-Nour'));
      await tester.pumpAndSettle();

      expect(routeur.state.matchedLocation, Routes.groupePour(_groupeId));
      expect(find.byType(FicheGroupePage), findsOneWidget);
    });
  });

  group('ENS-08 : Espace Classe ouvre la vraie Revue de Classe', () {
    testWidgets('taper « Revue » ouvre RevueGroupePage', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.groupePour(_groupeId),
      );
      final Finder revue = find.text(t.enseignant.ficheGroupe.revue);
      await tester.ensureVisible(revue);
      await tester.tap(revue);
      await tester.pumpAndSettle();

      expect(routeur.state.matchedLocation, Routes.revuePour(_groupeId));
      expect(find.byType(RevueGroupePage), findsOneWidget);
    });
  });

  group('ENS-11 : Espace Classe ouvre la vraie fiche eleve hors seance', () {
    testWidgets('taper la ligne d un eleve ouvre sa fiche', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.groupePour(_groupeId));
      final Finder ligneEleve = find.text(_elevePrenom);
      await tester.ensureVisible(ligneEleve);
      await tester.tap(ligneEleve);
      await tester.pumpAndSettle();

      expect(find.byType(FicheEleveEnseignant), findsOneWidget);
    });

    testWidgets('« Signaler un besoin » depuis la fiche ouvre ENS-12', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.groupePour(_groupeId));
      final Finder ligneEleve = find.text(_elevePrenom);
      await tester.ensureVisible(ligneEleve);
      await tester.tap(ligneEleve);
      await tester.pumpAndSettle();

      final Finder signaler = find.byKey(FicheEleveEnseignant.signalerKey);
      await tester.ensureVisible(signaler);
      await tester.tap(signaler);
      await tester.pumpAndSettle();

      expect(find.byType(SignalerBesoin), findsOneWidget);
    });
  });

  group('ENS-04 : Aujourd hui ouvre le vrai Cahier de seance', () {
    testWidgets('taper une ligne « A terminer » ouvre CahierPage', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(tester, Routes.enseignantJournee);
      expect(find.byType(JourneePage), findsOneWidget);

      // Al-Badr, 26/09 : le seul cahier en retard de la demonstration
      // (`DonneesEnseignantDemo.cahiersEnRetard`).
      final Finder ligneATerminer = find.textContaining('Al-Badr');
      await tester.ensureVisible(ligneATerminer.first);
      await tester.tap(ligneATerminer.first);
      await tester.pumpAndSettle();

      expect(
        routeur.state.matchedLocation,
        Routes.cahierPour('demo-seance-al-badr-2409'),
      );
      expect(find.byType(CahierPage), findsOneWidget);
    });
  });

  group('ENS-05A : Profil ouvre le vrai editeur de photo publique', () {
    testWidgets('taper le bouton de la photo ouvre EditeurPhotoPublique', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.enseignantProfil);
      expect(find.byType(ProfilEnseignantPage), findsOneWidget);

      final Finder bouton = find.text(t.enseignant.photo.choisir);
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(find.byType(EditeurPhotoPublique), findsOneWidget);
    });
  });
}
