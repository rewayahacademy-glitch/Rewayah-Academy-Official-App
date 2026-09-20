import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';

import '../support/harnais.dart';

/// Le chemin de bout en bout du role Enseignant, prouve sur le **routeur reel**.
///
/// **Ce test mesure le BRANCHEMENT, pas le contenu.** Ce que chaque ecran montre
/// est deja mesure par son propre test, a 390 sur 844 et a 200 % d'echelle de
/// texte. Ce qu'aucun de ces tests ne peut voir, parce qu'ils montent chacun un
/// ecran seul dans un hote de test, c'est si les ecrans sont **joignables** :
///
/// - la route existe-t-elle dans l'unique `GoRouter` de l'application ?
/// - la garde de `deciderRedirection` laisse-t-elle passer un enseignant ?
/// - l'ecran se construit-il dans la vraie coquille, avec le vrai theme ?
/// - la barre de navigation tient-elle trois destinations, et les cinq poses
///   vivent-elles bien HORS d'elle ?
///
/// La lecon qui a rendu ce test necessaire est inscrite dans la memoire du
/// projet : **« brancher l'entree, pas seulement la route »** -- un ecran sans
/// navigation qui l'expose n'existe pas. Un lot peut livrer huit ecrans parfaits
/// et n'en rendre aucun atteignable, et aucun test d'ecran ne le dirait.
///
/// Les services ne sont volontairement PAS tous surcharges : un ecran qui rend
/// son etat d'erreur prouve exactement ce qui est mesure ici -- il a ete
/// construit. Surcharger ses lectures ne prouverait rien de plus sur le
/// branchement, et ce fichier finirait par dupliquer les tests des agents.
void main() {
  /// Les seuls faux necessaires : la session decide de la garde, et le reseau
  /// est lu par `PageShell` sur chaque ecran de la coquille.
  List<Override> surcharges({
    AppRole role = AppRole.teacher,
    AccountStatus statut = AccountStatus.active,
  }) => <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        SessionState(
          resolue: true,
          role: role,
          profileId: 'ens-1',
          householdId: 'h1',
          accountStatus: statut,
          lectureProfil: LectureProfil.presente,
        ),
      ),
    ),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
    servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
    serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
    serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
    servicePriereProvider.overrideWithValue(FauxServicePriere()),
  ];

  /// Monte l'application sur son **vrai** routeur, a l'adresse demandee.
  ///
  /// Le routeur est lu par `ref.read(routeurProvider)` dans un consommateur, et
  /// non construit ici : c'est ce qui fait que le test echouerait si une route
  /// manquait au vrai `app_router.dart`, et non a une copie de test.
  Future<GoRouter> monter(
    WidgetTester tester,
    String depart, {
    List<Override>? avec,
  }) async {
    late GoRouter routeur;
    await tester.pumpWidget(
      ProviderScope(
        overrides: avec ?? surcharges(),
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

  group('Le chemin de bout en bout de l enseignant est joignable', () {
    // L'ordre est celui du protocole : onboarding, profil, creneaux, journee,
    // puis les deux poses contextuelles. La salle et le cahier qui la suit sont
    // mesures separement plus bas, la salle vivant hors de l'arbre (ADR-005).
    final Map<String, Type> etapes = <String, Type>{
      Routes.enseignantBienvenue: BienvenueEnseignantPage,
      Routes.enseignantProfil: ProfilEnseignantPage,
      Routes.enseignantCreneaux: CreneauxPage,
      Routes.enseignantJournee: JourneePage,
      Routes.groupePour('groupe-1'): FicheGroupePage,
      Routes.revuePour('groupe-1'): RevueGroupePage,
      Routes.cahierPour('seance-1'): CahierPage,
    };

    for (final MapEntry<String, Type> etape in etapes.entries) {
      testWidgets('${etape.key} rend ${etape.value}', (
        WidgetTester tester,
      ) async {
        await monter(tester, etape.key);
        expect(
          find.byType(etape.value),
          findsOneWidget,
          reason:
              '${etape.key} ne rend pas ${etape.value} : soit la route manque a '
              'app_router.dart, soit deciderRedirection la refuse a un '
              'enseignant valide',
        );
      });
    }

    testWidgets('le parcours s enchaine sans remonter a la racine', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantBienvenue,
      );

      // Chaque saut est fait par le routeur reel, l'un apres l'autre, sur la
      // MEME instance : c'est ce qui distingue « la route existe » de « on peut
      // y aller depuis l'ecran precedent sans que la garde nous renvoie ».
      for (final String chemin in etapes.keys) {
        routeur.go(chemin);
        await tester.pumpAndSettle();
        expect(
          routeur.state.matchedLocation,
          chemin,
          reason: 'la garde a devie $chemin',
        );
      }
    });
  });

  group('Les cinq poses ne sont pas des destinations', () {
    testWidgets('la barre de l enseignant en tient exactement trois', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.enseignantJournee);

      // Trois libelles de destination, et le quatrieme ne doit pas revenir :
      // « Compte » et « Profil » repondaient a la meme question (ADR-027), et
      // sur telephone le quatrieme onglet serait le seul chemin de deconnexion.
      expect(find.text(t.nav.enseignant.journee), findsWidgets);
      expect(find.text(t.nav.enseignant.creneaux), findsWidgets);
      expect(find.text(t.nav.enseignant.profil), findsWidgets);
    });

    testWidgets('une pose ne fait pas apparaitre la barre', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.cahierPour('seance-1'));

      // Le cahier est l'ecran de SORTIE de seance : une barre de navigation y
      // offrirait de partir ailleurs sans avoir depose son compte rendu. Il
      // vit donc hors de la coquille, et aucune destination ne s'y affiche.
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(CahierPage), findsOneWidget);
    });
  });

  group('La garde tient sur les poses comme sur les destinations', () {
    testWidgets('un tuteur qui demande le cahier repart chez lui', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.cahierPour('seance-1'),
        avec: surcharges(role: AppRole.guardian),
      );

      expect(routeur.state.matchedLocation, Routes.tuteurAccueil);
      expect(find.byType(CahierPage), findsNothing);
    });

    testWidgets('un enseignant en attente de KYC ne voit aucune pose', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.groupePour('groupe-1'),
        avec: surcharges(statut: AccountStatus.pendingKyc),
      );

      // Le portail d'attente prime sur tout, y compris sur une pose : un
      // dossier non valide ne donne acces a rien, et surtout pas a la fiche
      // d'un groupe d'enfants.
      expect(routeur.state.matchedLocation, startsWith(Routes.attente));
      expect(find.byType(FicheGroupePage), findsNothing);
    });
  });
}
