import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/etats_routeur.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/bienvenue_enseignant/bienvenue_page.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/creneaux/creneaux_page.dart';
import 'package:rewayah_academy/features/enseignant_classes/mes_classes_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../support/aucun_mot_coupe.dart';
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
    FauxServiceEnseignant? enseignant,
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
    serviceEnseignantProvider.overrideWithValue(
      enseignant ?? FauxServiceEnseignant(),
    ),
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
    double echelleTexte = 1,
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
                builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelleTexte)),
                  child: enfant!,
                ),
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
      Routes.enseignantClasses: MesClassesPage,
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
      final GoRouter routeur = await monter(tester, Routes.enseignantBienvenue);

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
    testWidgets('la barre de l enseignant en tient exactement quatre', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.enseignantJournee);

      // Quatre destinations, dans l'ordre E10 : Aujourd'hui, Classes,
      // Disponibilites, Profil (decision du directeur du 26/09/2026, qui
      // remplace ADR-027). « Compte » ne revient pas : Profil le porte.
      // A cette largeur (tablette), le rail est replie mais garde ses
      // libelles visibles, comme avant le chantier Tuteur V1 : le rail a
      // icones seules est reserve au tuteur (revue phase 0, jetons D2).
      final NavShell coquille = tester.widget<NavShell>(find.byType(NavShell));
      expect(coquille.destinations, hasLength(4));
      expect(coquille.libellesDansLeRail, isTrue);
      for (final String libelle in <String>[
        t.nav.enseignant.journee,
        t.nav.enseignant.classes,
        t.nav.enseignant.creneaux,
        t.nav.enseignant.profil,
      ]) {
        expect(
          find.descendant(
            of: find.byKey(NavShell.railKey),
            matching: find.text(libelle),
          ),
          findsOneWidget,
          reason: libelle,
        );
      }
    });

    testWidgets('chacune des quatre destinations se tape depuis la coquille', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(tester, Routes.enseignantJournee);

      // Depuis la VRAIE coquille enseignant, on tape chaque destination dans
      // l'ordre E10 : la branche doit s'ouvrir sur son chemin et sa page.
      final Map<String, (String, Type)> destinations = <String, (String, Type)>{
        t.nav.enseignant.classes: (Routes.enseignantClasses, MesClassesPage),
        t.nav.enseignant.creneaux: (Routes.enseignantCreneaux, CreneauxPage),
        t.nav.enseignant.profil: (
          Routes.enseignantProfil,
          ProfilEnseignantPage,
        ),
        t.nav.enseignant.journee: (Routes.enseignantJournee, JourneePage),
      };
      for (final MapEntry<String, (String, Type)> d in destinations.entries) {
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.railKey),
            matching: find.text(d.key),
          ),
        );
        await tester.pumpAndSettle();
        expect(routeur.state.matchedLocation, d.value.$1, reason: d.key);
        expect(find.byType(d.value.$2), findsOneWidget, reason: d.key);
        final NavShell coquille = tester.widget<NavShell>(
          find.byType(NavShell),
        );
        expect(
          coquille.destinations[coquille.indexActif!].chemin,
          d.value.$1,
          reason: 'destination active pour ${d.key}',
        );
      }
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
    testWidgets('un tuteur qui demande le cahier voit l acces refuse', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.cahierPour('seance-1'),
        avec: surcharges(role: AppRole.guardian),
      );

      // Une page qui le dit et ramene a sa racine, plus un renvoi muet
      // (mandat Tuteur V1 section 8).
      expect(routeur.state.matchedLocation, Routes.accesRefuse);
      expect(find.byType(PageAccesRefuse), findsOneWidget);
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

  // DASH-ENS-ROUTE : « A terminer » a son adresse ; un rechargement Web ou un
  // lien la garde, au lieu d'une page poussee sans adresse.
  group('DASH-ENS-ROUTE : la liste « A terminer » a son adresse', () {
    CahierEnRetard cahier(String id, String classe, int jour) => CahierEnRetard(
      seanceId: id,
      debut: DateTime(2026, 9, jour, 17),
      fin: DateTime(2026, 9, jour, 17, 45),
      nbParticipants: 3,
      heuresDeRetard: 30,
      groupeId: 'g-$id',
      groupeLibelle: classe,
    );
    final List<CahierEnRetard> quatre = <CahierEnRetard>[
      cahier('a', 'Al-Badr', 26),
      cahier('b', 'As-Salam', 25),
      cahier('c', 'Al-Fatiha', 23),
      cahier('d', 'Al-Ikhlas', 22),
    ];

    List<Override> avecCahiers(List<CahierEnRetard> cahiers) => surcharges(
      enseignant: FauxServiceEnseignant()..retardsRendus = cahiers,
    );

    testWidgets('« Voir tout » ouvre l adresse, et la liste entiere', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantJournee,
        avec: avecCahiers(quatre),
      );
      final Finder voirTout = find.byKey(
        const ValueKey<String>('journee-a-terminer-voir-tout'),
      );
      await tester.ensureVisible(voirTout);
      await tester.pumpAndSettle();
      await tester.tap(voirTout);
      await tester.pumpAndSettle();

      expect(routeur.state.matchedLocation, Routes.enseignantATerminer);
      expect(find.byType(ListeATerminerPage), findsOneWidget);
      for (final String classe in <String>[
        'Al-Badr',
        'As-Salam',
        'Al-Fatiha',
        'Al-Ikhlas',
      ]) {
        expect(find.textContaining(classe), findsWidgets);
      }
    });

    testWidgets('l adresse ouverte directement rend la liste', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantATerminer,
        avec: avecCahiers(quatre),
      );
      expect(routeur.state.matchedLocation, Routes.enseignantATerminer);
      expect(find.byType(ListeATerminerPage), findsOneWidget);
      expect(find.textContaining('Al-Ikhlas'), findsWidgets);
      // Laisse expirer les minuteries courtes de la coquille (premiere image
      // ouverte sur une adresse profonde) avant le demontage.
      await tester.pump(const Duration(seconds: 5));
    });

    // DASH-ENS-ROUTE-R, mineur 2 : le retour d'une adresse ouverte
    // directement (rechargement, lien) ramene a la Journee ; ouverte par
    // « Voir tout », il revient a la page precedente.
    testWidgets('ouverte directement, le retour mene a la Journee', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantATerminer,
        avec: avecCahiers(quatre),
      );
      // Sous-route de la Journee : go_router empile la Journee dessous.
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(routeur.state.matchedLocation, Routes.enseignantJournee);
      expect(find.byType(ListeATerminerPage), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('ouverte par un push, le retour revient en arriere', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantJournee,
        avec: avecCahiers(quatre),
      );
      unawaited(routeur.push<void>(Routes.enseignantATerminer));
      await tester.pumpAndSettle();
      expect(find.byType(ListeATerminerPage), findsOneWidget);
      expect(routeur.canPop(), isTrue);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(routeur.state.matchedLocation, Routes.enseignantJournee);
      expect(find.byType(ListeATerminerPage), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('rien a terminer : une phrase, pas une page vide', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        Routes.enseignantATerminer,
        avec: avecCahiers(const <CahierEnRetard>[]),
      );
      expect(find.text(t.enseignant.journee.aTerminerVide), findsOneWidget);
    });

    testWidgets('une lecture ratee le dit et propose de relire', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await monter(
        tester,
        Routes.enseignantATerminer,
        avec: <Override>[
          ...surcharges(),
          cahiersEnRetardProvider.overrideWith((Ref _) async {
            lectures++;
            if (lectures == 1) throw StateError('reseau');
            return quatre;
          }),
        ],
      );
      expect(find.text(t.enseignant.journee.aTerminerErreur), findsOneWidget);
      expect(find.text(t.enseignant.journee.aTerminerVide), findsNothing);

      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();
      expect(lectures, 2);
      expect(find.textContaining('Al-Ikhlas'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  // DASH-ENS-LISTES : les remplacements au-dela de trois et toutes les
  // « Alertes utiles » ont leur adresse, sous-routes de la Journee
  // (DASH_STRATEGIE §5, lignes DASH-ENS-REMPL et DASH-ENS-ALERTES).
  group('DASH-ENS-LISTES : remplacements et alertes ont leur adresse', () {
    setUpAll(chargerPolicesDuDepot);

    // Lundi 28 septembre 2026, 16 h 10 : la seance d'Al-Badr est en cours.
    final DateTime maintenant = DateTime(2026, 9, 28, 16, 10);
    final SeanceEnseignant enDirect = SeanceEnseignant(
      id: 'live',
      debut: DateTime(2026, 9, 28, 16),
      fin: DateTime(2026, 9, 28, 16, 45),
      statut: StatutSeance.enCours,
      nbParticipants: 6,
      cahierDepose: false,
      groupeId: 'g-live',
      groupeLibelle: 'Al-Badr',
    );
    PresenceParticipant eleve(String prenom, EtatPresence etat) =>
        PresenceParticipant(
          profilId: 'p-$prenom',
          role: 'student',
          prenom: prenom,
          identifiantImmuable: 'id-$prenom',
          etat: etat,
          consolide: false,
        );
    final List<PresenceParticipant> cinqManquants = <PresenceParticipant>[
      eleve('Yasmine', EtatPresence.absente),
      eleve('Ilyas', EtatPresence.deconnectee),
      eleve('Maryam', EtatPresence.absente),
      eleve('Souhayl', EtatPresence.absente),
      eleve('Khadija', EtatPresence.deconnectee),
    ];
    OffreRemplacement remplacement(String classe, int mois, int jour) =>
        OffreRemplacement(
          seanceId: 'r-$classe',
          classe: classe,
          debut: DateTime(2026, mois, jour, 18),
          fin: DateTime(2026, mois, jour, 18, 45),
          nbEleves: 4,
          groupeId: 'g-$classe',
        );
    // Donnes dans le desordre : la Journee montre les trois plus proches.
    final List<OffreRemplacement> cinqRemplacements = <OffreRemplacement>[
      remplacement('An-Nour', 10, 2),
      remplacement('Al-Fatiha', 9, 29),
      remplacement('Al-Ikhlas', 10, 4),
      remplacement('As-Salam', 9, 30),
      remplacement('Al-Kawthar', 10, 1),
    ];
    const List<String> troisPlusProches = <String>[
      'Al-Fatiha',
      'As-Salam',
      'Al-Kawthar',
    ];

    List<Override> avec({
      List<OffreRemplacement> remplacements = const <OffreRemplacement>[],
      List<PresenceParticipant>? presence = const <PresenceParticipant>[],
      List<SeanceEnseignant>? seances,
      List<Override> plus = const <Override>[],
    }) => <Override>[
      ...surcharges(
        enseignant: FauxServiceEnseignant()
          ..seancesRendues = seances ?? <SeanceEnseignant>[enDirect],
      ),
      maintenantJourneeProvider.overrideWithValue(() => maintenant),
      remplacementsConfirmesProvider.overrideWith(
        () => _RemplacementsFixes(remplacements),
      ),
      presenceSeanceProvider('live').overrideWith(
        (Ref _) => Stream<List<PresenceParticipant>?>.value(presence),
      ),
      ...plus,
    ];

    void vueHaute(WidgetTester tester, {double largeur = 390}) {
      tester.view.physicalSize = Size(largeur, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    Future<void> toucher(WidgetTester tester, Finder cible) async {
      await tester.ensureVisible(cible);
      await tester.pumpAndSettle();
      await tester.tap(cible);
      await tester.pumpAndSettle();
    }

    testWidgets('la Journee montre 3 remplacements sur 5, les plus proches', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(remplacements: cinqRemplacements),
      );
      expect(find.byType(CarteRemplacement), findsNWidgets(3));
      for (final String classe in troisPlusProches) {
        expect(find.text(classe), findsOneWidget, reason: classe);
      }
      expect(find.text('Al-Ikhlas'), findsNothing);
      expect(find.text('An-Nour'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('journee-remplacements-voir-tout')),
        findsOneWidget,
      );
    });

    testWidgets('trois remplacements ou moins : aucun lien', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(remplacements: cinqRemplacements.take(3).toList()),
      );
      expect(find.byType(CarteRemplacement), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey<String>('journee-remplacements-voir-tout')),
        findsNothing,
      );
    });

    testWidgets('« Voir tout » ouvre l adresse des remplacements, tous', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(remplacements: cinqRemplacements),
      );
      await toucher(
        tester,
        find.byKey(const ValueKey<String>('journee-remplacements-voir-tout')),
      );
      expect(routeur.state.matchedLocation, Routes.enseignantRemplacements);
      expect(find.byType(ListeRemplacementsPage), findsOneWidget);
      expect(find.byType(CarteRemplacement), findsNWidgets(5));
      // Les plus proches d'abord.
      final List<double> ordre = <String>[
        'Al-Fatiha',
        'As-Salam',
        'Al-Kawthar',
        'An-Nour',
        'Al-Ikhlas',
      ].map((String c) => tester.getTopLeft(find.text(c)).dy).toList();
      expect(ordre, orderedEquals(List<double>.of(ordre)..sort()));
    });

    testWidgets('l adresse des remplacements ouverte directement, et retour', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantRemplacements,
        avec: avec(remplacements: cinqRemplacements),
      );
      expect(routeur.state.matchedLocation, Routes.enseignantRemplacements);
      expect(find.byType(CarteRemplacement), findsNWidgets(5));
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(routeur.state.matchedLocation, Routes.enseignantJournee);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('aucun remplacement : une phrase, pas une page vide', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.enseignantRemplacements, avec: avec());
      expect(find.text(t.enseignant.journee.remplacementsVide), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('la Journee montre 2 alertes et un lien vers les 3 autres', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(presence: cinqManquants),
      );
      expect(find.textContaining('Yasmine'), findsOneWidget);
      expect(find.textContaining('Ilyas'), findsOneWidget);
      expect(find.textContaining('Khadija'), findsNothing);
      final Finder lien = find.byKey(
        const ValueKey<String>('journee-alertes-voir-autres'),
      );
      expect(
        find.descendant(
          of: lien,
          matching: find.text(
            t.enseignant.journee.voirAutresAlertes(nombre: '3'),
          ),
        ),
        findsOneWidget,
      );
      await toucher(tester, lien);
      expect(routeur.state.matchedLocation, Routes.enseignantAlertes);
      expect(find.byType(ListeAlertesPage), findsOneWidget);
      for (final String prenom in <String>[
        'Yasmine',
        'Ilyas',
        'Maryam',
        'Souhayl',
        'Khadija',
      ]) {
        expect(find.textContaining(prenom), findsOneWidget, reason: prenom);
      }
    });

    // DASH-ENS-LISTES-R (contre-revue) : une seule alerte cachee, le lien
    // le dit au singulier.
    testWidgets('trois alertes : « Voir l autre alerte », au singulier', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(presence: cinqManquants.take(3).toList()),
      );
      final Finder lien = find.byKey(
        const ValueKey<String>('journee-alertes-voir-autres'),
      );
      expect(
        find.descendant(
          of: lien,
          matching: find.text(t.enseignant.journee.voirAutreAlerte),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.journee.voirAutresAlertes(nombre: '1')),
        findsNothing,
      );
      await toucher(tester, lien);
      expect(routeur.state.matchedLocation, Routes.enseignantAlertes);
      expect(find.textContaining('Maryam'), findsOneWidget);
    });

    // DASH-ENS-LISTES-R (contre-revue), WCAG 2.5.3 : le nom accessible du
    // lien contient le texte visible « Voir tout », puis dit quoi.
    testWidgets('« Voir tout » : le nom accessible commence par le visible', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final SemanticsHandle semantique = tester.ensureSemantics();
      await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(remplacements: cinqRemplacements),
      );
      final String nom = tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>('journee-remplacements-voir-tout'),
            ),
          )
          .label;
      expect(nom, startsWith(t.tuteur.accueil.voirTout));
      expect(nom, contains('5'));
      semantique.dispose();
    });

    testWidgets('deux alertes ou moins : aucun lien', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      await monter(
        tester,
        Routes.enseignantJournee,
        avec: avec(presence: cinqManquants.take(2).toList()),
      );
      expect(find.textContaining('Ilyas'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('journee-alertes-voir-autres')),
        findsNothing,
      );
    });

    testWidgets('l adresse des alertes ouverte directement rend la liste', (
      WidgetTester tester,
    ) async {
      vueHaute(tester);
      final GoRouter routeur = await monter(
        tester,
        Routes.enseignantAlertes,
        avec: avec(presence: cinqManquants),
      );
      expect(routeur.state.matchedLocation, Routes.enseignantAlertes);
      expect(find.textContaining('Khadija'), findsOneWidget);
      await tester.tap(find.byType(DisqueRetour));
      await tester.pumpAndSettle();
      expect(routeur.state.matchedLocation, Routes.enseignantJournee);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('aucune alerte : une phrase, pas une page vide', (
      WidgetTester tester,
    ) async {
      await monter(tester, Routes.enseignantAlertes, avec: avec());
      expect(find.text(t.enseignant.journee.alertesVide), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('seances illisibles : l echec le dit, puis la relecture', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await monter(
        tester,
        Routes.enseignantAlertes,
        avec: avec(
          presence: cinqManquants,
          plus: <Override>[
            seancesEnseignantProvider.overrideWith((Ref _) async {
              lectures++;
              if (lectures == 1) throw StateError('reseau');
              return <SeanceEnseignant>[enDirect];
            }),
          ],
        ),
      );
      expect(find.text(t.enseignant.journee.alertesErreur), findsOneWidget);
      expect(find.text(t.enseignant.journee.alertesVide), findsNothing);
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();
      expect(lectures, 2);
      expect(find.textContaining('Khadija'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('presence illisible : jamais « aucune alerte » (J3, D10)', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        Routes.enseignantAlertes,
        avec: avec(presence: null),
      );
      expect(find.text(t.enseignant.journee.alertesErreur), findsOneWidget);
      expect(find.text(t.enseignant.journee.alertesVide), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    for (final String adresse in <String>[
      Routes.enseignantJournee,
      Routes.enseignantRemplacements,
      Routes.enseignantAlertes,
    ]) {
      testWidgets('$adresse a 320 px, texte double : aucun mot coupe', (
        WidgetTester tester,
      ) async {
        vueHaute(tester, largeur: 320);
        await monter(
          tester,
          adresse,
          avec: avec(remplacements: cinqRemplacements, presence: cinqManquants),
          echelleTexte: 2,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pump(const Duration(seconds: 5));
      });
    }
  });
}

/// Des remplacements deja confirmes par le serveur, pour le test.
class _RemplacementsFixes extends RemplacementsControleur {
  _RemplacementsFixes(this._depart);

  final List<OffreRemplacement> _depart;

  @override
  List<OffreRemplacement> build() => _depart;
}
