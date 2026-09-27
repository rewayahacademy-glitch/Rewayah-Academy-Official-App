// Classe du tuteur et ses sous-pages (lot C, sous-paquet 2) : parcours touches
// depuis la barre de navigation, sur le VRAI routeur, puis etats de chaque
// ecran et fonctions pures.
//
// Donnees : fixtures isolees de `test/fixtures/tuteur/` et doubles de
// `support_classe.dart` (politique d'observation, catalogue, progression).
// Aucun service reel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_observation/disponibilite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_outils/learning_assignment.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';
import 'package:rewayah_academy/features/classe_tuteur/bloc_observation_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/carte_seance_classe.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/planning_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/progression_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/ressources_classe_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/travail_classe_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/detail_ressource_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/entree_observation_page.dart';

import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart' show hoteRoutant;
import 'support_classe.dart';

const String _a1 = eleveA1;
const String _classe = classeA;

/// Monte l'application sur son vrai routeur (surcharges de
/// `support_classe.dart`), puis va a [depart].
Future<GoRouter> _monter(
  WidgetTester tester, {
  String depart = Routes.tuteurFoyer,
  List<SeanceFamille>? seances,
  PortClassesFoyer? portClasses,
  bool observation = false,
  BudgetObservation? budget,
  List<PresenceParticipant>? presence,
  PortAssignations? travail,
  PortCatalogue? catalogue,
  PortProgressionFamille? progression,
  bool horsLigne = false,
  bool seancesIndisponibles = false,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesClasse(
        seances: seances,
        portClasses: portClasses,
        observation: observation,
        budget: budget,
        presence: presence,
        travail: travail,
        catalogue: catalogue,
        progression: progression,
        horsLigne: horsLigne,
        seancesIndisponibles: seancesIndisponibles,
      ),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche un element apres l'avoir amene a l'ecran.
Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// De la barre basse a la classe : Accueil, puis « Voir la classe ».
Future<void> _ouvrirLaClasse(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(NavShell.barreBasseKey),
      matching: find.text(t.nav.tuteur.accueil),
    ),
  );
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);
  await _toucher(tester, find.text(t.tuteur.accueil.voirLaClasse));
  expect(find.byType(ClasseTuteurPage), findsOneWidget);
}

/// Revient par le disque retour de l'en-tete.
Future<void> _retour(WidgetTester tester) async {
  await _toucher(tester, find.byType(DisqueRetour));
}

/// Une rubrique de la carte groupee de la classe (la barre de navigation porte
/// aussi « Historique »).
Finder _rubrique(String libelle) => find.descendant(
  of: find.byType(GroupeReglages),
  matching: find.text(libelle),
);

String _lieu(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('Classe : parcours touches depuis la barre de navigation', () {
    testWidgets('la classe dit l enseignant, la seance et ses rubriques ; '
        'le disque retour ramene a l Accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirLaClasse(tester);

      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
      // En-tete et carte : la classe, l'eleve et l'enseignant nomme.
      expect(find.text('Classe fictive A'), findsNWidgets(2));
      expect(
        find.text(
          t.classe.sousTitre(
            prenom: 'Eleve A1',
            enseignant: '${t.tc.groupe.enseignant.sayyid} Enseignant X',
          ),
        ),
        findsOneWidget,
      );
      // Meme calcul que l'Accueil : salle ouverte et compte a rebours.
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsOneWidget);
      expect(find.text(LibellesGroupe.dansMinutes(10)), findsOneWidget);
      for (final String rubrique in <String>[
        t.classe.planning,
        t.classe.travail,
        t.classe.ressources,
        t.classe.progression,
        t.classe.historique,
      ]) {
        expect(_rubrique(rubrique), findsOneWidget, reason: rubrique);
      }
      // Aucune entree « Rejoindre » pour le tuteur.
      expect(find.text(LibellesGroupe.rejoindre), findsNothing);
      // L'onglet Accueil reste actif sur cette page de niveau 2.
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 0);

      await _retour(tester);
      expect(_lieu(routeur), Routes.tuteurAccueil);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Planning » ouvre les seances a venir, le retour ramene a '
        'la classe', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[
          seanceSalleOuverte(),
          seanceSalleOuverte(
            seanceId: 's2',
            avant: const Duration(days: 2),
            statut: StatutSeance.annulee,
          ),
        ],
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.planning));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
      );
      expect(find.byType(PlanningClassePage), findsOneWidget);
      expect(find.text(t.classe.pagePlanning.prochaines), findsOneWidget);
      // L'annulation se voit : jamais un cours normal.
      expect(
        find.widgetWithText(StatusPill, t.tuteur.accueil.pastilleAnnulee),
        findsOneWidget,
      );

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Travail a preparer » liste le travail sans limite de '
        'trois, statut du service, jamais le travail retire', (
      WidgetTester tester,
    ) async {
      final AssignationsMemoire travaux = await travauxFictifs();
      final GoRouter routeur = await _monter(tester, travail: travaux);
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.travail));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
      );
      expect(find.byType(TravailClassePage), findsOneWidget);
      expect(find.textContaining('Consigne fictive 1'), findsOneWidget);
      expect(find.textContaining('Consigne fictive 2'), findsOneWidget);
      expect(find.textContaining('Consigne retiree'), findsNothing);
      expect(
        find.widgetWithText(StatusPill, t.classe.pageTravail.statut.fait),
        findsOneWidget,
      );
      expect(find.text(t.classe.pageTravail.nonCochable), findsOneWidget);

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
    });

    testWidgets('« Bibliotheque » liste les ressources ; une ressource ouvre '
        'le detail existant, dont le disque retour revient ici', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        catalogue: FauxCatalogueClasse(<LibraryResource>[
          ressourceFictive('r1', 'Support fictif 1'),
        ]),
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.ressources));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.byType(RessourcesClassePage), findsOneWidget);

      await _toucher(tester, find.text('Support fictif 1'));
      expect(_lieu(routeur), startsWith('${Routes.tcBibliotheque}/r1?retour='));
      expect(find.byType(DetailRessourcePage), findsOneWidget);

      await _retour(tester);
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.byType(RessourcesClassePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail d une ressource ouvert par lien profond, sans '
        '?retour= : un disque retour mene a la Bibliotheque, jamais une '
        'impasse', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        depart: '${Routes.tcBibliotheque}/r1',
        catalogue: FauxCatalogueClasse(<LibraryResource>[
          ressourceFictive('r1', 'Support fictif 1'),
        ]),
      );
      expect(find.byType(DetailRessourcePage), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);

      await _retour(tester);
      expect(_lieu(routeur), Routes.tcBibliotheque);
      expect(find.byType(DetailRessourcePage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail d une ressource sans ?retour= ni ecran dessous : le '
        'disque retour ouvre la Bibliotheque (repli, revue m5)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteRoutant(
          depart: '${Routes.tcBibliotheque}/r1',
          routes: <RouteBase>[
            GoRoute(
              path: Routes.tcBibliotheque,
              builder: (BuildContext _, GoRouterState _) =>
                  const Text('bibliotheque'),
            ),
            // Route soeur, pas enfant : rien a depiler.
            GoRoute(
              path: '${Routes.tcBibliotheque}/:id',
              builder: (BuildContext _, GoRouterState etat) =>
                  DetailRessourcePage(resourceId: etat.pathParameters['id']!),
            ),
          ],
          surcharges: surchargesClasse(
            catalogue: FauxCatalogueClasse(<LibraryResource>[
              ressourceFictive('r1', 'Support fictif 1'),
            ]),
          ),
        ),
      );
      await stabiliser(tester);
      expect(find.byType(DisqueRetour), findsOneWidget);

      await _retour(tester);
      expect(find.text('bibliotheque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Progression » dit le niveau et les etapes partagees', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        progression: const FausseProgressionClasse(
          ProgressionEleve(
            eleveId: _a1,
            niveauHumain: 'Niveau fictif',
            jalons: <String>['Etape fictive 1'],
          ),
        ),
      );
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.progression));
      expect(
        _lieu(routeur),
        '${Routes.classeSousPage(_classe, 'progression')}?eleve=$_a1',
      );
      expect(find.byType(ProgressionClassePage), findsOneWidget);
      expect(find.text('Niveau fictif'), findsOneWidget);
      expect(find.text('Etape fictive 1'), findsOneWidget);

      await _retour(tester);
      expect(_lieu(routeur), Routes.classePour(_classe, eleveId: _a1));
    });

    testWidgets('« Historique » ouvre l Historique filtre sur l eleve et la '
        'classe', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _ouvrirLaClasse(tester);

      await _toucher(tester, _rubrique(t.classe.historique));
      expect(
        _lieu(routeur),
        '${Routes.tuteurSuivi}?eleve=$_a1&classe=$_classe',
      );
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 2);
    });

    testWidgets('observation ouverte (simulation) : « Observer la seance » et '
        '« Comment ca marche ? » ouvrent l entree du lot O avec le contexte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[seanceEnDirect()],
        observation: true,
        presence: <PresenceParticipant>[presenceA1],
      );
      await _ouvrirLaClasse(tester);

      expect(find.text(t.tuteur.accueil.seanceEnDirect), findsOneWidget);
      expect(
        find.text(
          t.classe.observation.resume(
            visites: t.classe.observation.visites(nombre: 2),
            duree: t.classe.observation.minutes(minutes: 2),
          ),
        ),
        findsOneWidget,
      );

      await _toucher(tester, find.text(t.classe.observer));
      expect(
        _lieu(routeur),
        '${Routes.tcObservation('s1')}?classe=$_classe&eleve=$_a1',
      );
      expect(find.byType(EntreeObservationPage), findsOneWidget);
    });

    testWidgets('« Comment ca marche ? » ouvre l explication seule', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(
        tester,
        seances: <SeanceFamille>[seanceEnDirect()],
        observation: true,
        presence: <PresenceParticipant>[presenceA1],
      );
      await _ouvrirLaClasse(tester);

      // Revue C m4 : icone info devant le lien, horloge (pas sablier)
      // devant la duree.
      expect(
        find.descendant(
          of: find.byType(LienFleche),
          matching: find.byIcon(AppIcons.info.repos),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.horloge.repos), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(CarteSeanceClasse),
          matching: find.byIcon(AppIcons.attente.repos),
        ),
        findsNothing,
      );

      await _toucher(tester, find.text(t.classe.observation.commentCaMarche));
      expect(
        _lieu(routeur),
        '${Routes.tcObservation('s1')}?classe=$_classe&eleve=$_a1&aide=1',
      );
    });
  });

  group('Classe : etats', () {
    testWidgets('production (P3) : aucune porte d observation appelee, une '
        'phrase, aucun CTA', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[seanceEnDirect()],
      );
      expect(
        find.text(t.classe.observation.motif.garantieServeurAbsente),
        findsOneWidget,
      );
      expect(find.text(t.classe.observer), findsNothing);
    });

    testWidgets('visites epuisees : le motif et « Aucune visite restante »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[seanceEnDirect()],
        observation: true,
        budget: budgetEpuise,
        presence: <PresenceParticipant>[presenceA1],
      );
      expect(
        find.text(t.classe.observation.motif.visitesEpuisees),
        findsOneWidget,
      );
      expect(find.text(t.classe.observation.restanteAucune), findsOneWidget);
      expect(find.text(t.classe.observer), findsNothing);
    });

    testWidgets('presence non lue : « en cours de verification », jamais une '
        'absence', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[seanceEnDirect()],
        observation: true,
      );
      expect(
        find.text(
          t.classe.observation.motif.presenceEnVerification(prenom: 'Eleve A1'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(t.presence.absente), findsNothing);
    });

    testWidgets('seance a venir : l observation ouvre quand elle commence', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[
          seanceSalleOuverte(
            avant: const Duration(hours: 3, minutes: 28, seconds: 30),
          ),
        ],
        observation: true,
      );
      expect(
        find.text(LibellesGroupe.dansHeures(heures: 3, minutes: 28)),
        findsOneWidget,
      );
      expect(
        find.text(t.classe.observation.motif.seanceNonCommencee),
        findsOneWidget,
      );
    });

    testWidgets(
      'seance annulee : bandeau d alerte, jamais de compte a rebours',
      (WidgetTester tester) async {
        await _monter(
          tester,
          depart: Routes.classePour(_classe, eleveId: _a1),
          seances: <SeanceFamille>[
            seanceSalleOuverte(statut: StatutSeance.annulee),
          ],
        );
        expect(find.text(t.tuteur.accueil.seanceAnnulee), findsOneWidget);
        expect(find.text(LibellesGroupe.dansMinutes(10)), findsNothing);
      },
    );

    testWidgets('sans horloge serveur : heure de l appareil dite comme telle', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: <SeanceFamille>[seanceSalleOuverte(avecHorloge: false)],
      );
      expect(find.text(t.tuteur.accueil.horaireIncertain), findsOneWidget);
      expect(find.text(t.tuteur.accueil.heureAppareil), findsOneWidget);
      expect(find.text(LibellesGroupe.salleOuverteCourt), findsNothing);
    });

    testWidgets('aucune seance : la classe reste lisible', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        seances: const <SeanceFamille>[],
      );
      expect(find.text(t.classe.seance.aucune), findsOneWidget);
      expect(find.text(t.classe.planning), findsOneWidget);
    });

    testWidgets('classes indisponibles (production) : pas encore disponible, '
        'jamais « introuvable »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        portClasses: const ClassesFoyerIndisponible(),
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.indisponible);
      expect(find.text(t.classe.indisponiblePhrase), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('classe d un autre eleve ou inconnue : introuvable, retour a '
        'l accueil', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        depart: Routes.classePour('inconnue', eleveId: _a1),
      );
      expect(find.text(t.classe.introuvableTitre), findsOneWidget);
      await _toucher(tester, find.text(t.commun.etats.actions.retourAccueil));
      expect(_lieu(routeur), Routes.tuteurAccueil);
    });

    testWidgets('un eleve d un autre foyer dans l adresse : introuvable', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: 'foyer-b-eleve-1'),
      );
      expect(find.text(t.classe.introuvableTitre), findsOneWidget);
    });

    testWidgets('lecture en echec : echec de bloc, « Reessayer » relit et la '
        'classe apparait', (WidgetTester tester) async {
      final ClassesEnEchecPuisRendues port = ClassesEnEchecPuisRendues();
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        portClasses: port,
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.byType(DisqueRetour), findsOneWidget);

      await _toucher(tester, find.text(t.commun.etats.actions.reessayer));
      expect(port.lectures, greaterThanOrEqualTo(2));
      expect(find.byType(CarteSeanceClasse), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne : le bandeau de la coquille, la classe reste '
        'lisible et le retour possible', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        horsLigne: true,
      );
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(find.byType(CarteSeanceClasse), findsOneWidget);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('bureau 1440 : deux colonnes, carte a gauche, rubriques a '
        'droite', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: Routes.classePour(_classe, eleveId: _a1),
        taille: const Size(1440, 900),
      );
      final Offset carte = tester.getTopLeft(find.byType(CarteSeanceClasse));
      final Offset planning = tester.getTopLeft(find.text(t.classe.planning));
      expect(planning.dx, greaterThan(carte.dx + 400));
      expect(planning.dy, lessThan(carte.dy + 200));
      expect(tester.takeException(), isNull);
    });

    testWidgets('telephone 390 : une colonne, rubriques sous la carte', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.classePour(_classe, eleveId: _a1));
      final Rect carte = tester.getRect(find.byType(CarteSeanceClasse));
      await tester.ensureVisible(find.text(t.classe.planning));
      await stabiliser(tester);
      final Rect carteApres = tester.getRect(find.byType(CarteSeanceClasse));
      final Offset planning = tester.getTopLeft(find.text(t.classe.planning));
      expect(planning.dy, greaterThan(carteApres.bottom));
      expect(carte.width, carteApres.width);
      expect(tester.takeException(), isNull);
    });
  });

  group('Sous-pages : etats', () {
    testWidgets('travail non branche (production) : phrase honnete, jamais '
        '« Rien a preparer »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
      );
      expect(find.text(t.classe.pageTravail.indisponible), findsOneWidget);
      expect(find.text(t.classe.pageTravail.aucun), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('travail branche et vide : « Rien a preparer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'travail')}?eleve=$_a1',
        travail: AssignationsMemoire('enseignant-x'),
      );
      expect(find.text(t.classe.pageTravail.aucun), findsOneWidget);
    });

    testWidgets('bibliotheque locale (production) : pas encore reliee, jamais '
        '« aucune ressource »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
      );
      expect(find.text(t.classe.pageRessources.indisponible), findsOneWidget);
      expect(find.text(t.classe.pageRessources.aucune), findsNothing);
    });

    testWidgets('bibliotheque branchee et vide : aucune ressource', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'ressources')}?eleve=$_a1',
        catalogue: const FauxCatalogueClasse(<LibraryResource>[]),
      );
      expect(find.text(t.classe.pageRessources.aucune), findsOneWidget);
    });

    testWidgets('progression (production) : pas encore partagee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'progression')}?eleve=$_a1',
      );
      expect(
        find.text(t.classe.pageProgression.indisponible(prenom: 'Eleve A1')),
        findsOneWidget,
      );
    });

    testWidgets('planning vide : aucune seance a venir', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
        seances: const <SeanceFamille>[],
      );
      expect(find.text(t.classe.pagePlanning.aucune), findsOneWidget);
    });

    testWidgets('planning sans source : « pas encore relie », jamais « aucune '
        'seance »', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
        seancesIndisponibles: true,
      );
      expect(find.text(t.classe.pagePlanning.indisponible), findsOneWidget);
      expect(find.text(t.classe.pagePlanning.aucune), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });

    testWidgets('bureau 1440 : la precision a droite de la liste, jamais une '
        'colonne de telephone etiree', (WidgetTester tester) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'planning')}?eleve=$_a1',
        taille: const Size(1440, 900),
      );
      final Offset titre = tester.getTopLeft(
        find.text(t.classe.pagePlanning.prochaines),
      );
      final Offset precision = tester.getTopLeft(
        find.text(t.classe.pagePlanning.habituelIndisponible),
      );
      expect(precision.dx, greaterThan(titre.dx + 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('bureau 1440 : la progression garde une largeur de lecture', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: '${Routes.classeSousPage(_classe, 'progression')}?eleve=$_a1',
        taille: const Size(1440, 900),
        progression: const FausseProgressionClasse(
          ProgressionEleve(eleveId: _a1, niveauHumain: 'Niveau fictif'),
        ),
      );
      final Rect carte = tester.getRect(
        find.ancestor(
          of: find.text('Niveau fictif'),
          matching: find.byType(AppCard),
        ),
      );
      expect(carte.width, lessThanOrEqualTo(AppPage.largeurLecture));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sous-page sans eleve dans l adresse : l eleve inscrit est '
        'retrouve', (WidgetTester tester) async {
      await _monter(tester, depart: Routes.classeSousPage(_classe, 'planning'));
      expect(
        find.text(LibellesGroupe.joindre('Classe fictive A', 'Eleve A1')),
        findsOneWidget,
      );
    });
  });

  group('Fonctions pures', () {
    test('visites accordees et restantes, au singulier et au pluriel', () {
      expect(visitesDisponibles(1), t.classe.observation.uneVisite);
      expect(visitesDisponibles(2), t.classe.observation.visites(nombre: 2));
      expect(visitesRestantes(0), t.classe.observation.restanteAucune);
      expect(visitesRestantes(1), t.classe.observation.restanteUne);
      expect(visitesRestantes(2), t.classe.observation.restantes(nombre: 2));
    });

    test('duree d une visite : minutes, secondes, jamais arrondie', () {
      expect(
        dureeVisite(const Duration(seconds: 120)),
        t.classe.observation.minutes(minutes: 2),
      );
      expect(
        dureeVisite(const Duration(seconds: 80)),
        t.classe.observation.minutesSecondes(minutes: 1, secondes: 20),
      );
      expect(
        dureeVisite(const Duration(seconds: 40)),
        t.classe.observation.secondes(secondes: 40),
      );
    });

    test('chaque motif a sa phrase, aucun code', () {
      for (final MotifIndisponibilite motif in MotifIndisponibilite.values) {
        final String texte = texteMotif(motif, prenom: 'Eleve A1');
        expect(texte, isNotEmpty, reason: motif.name);
        expect(texte.contains('_'), isFalse, reason: motif.name);
      }
    });

    test('le budget ne se lit que salle ouverte, en direct ou horaire '
        'incertain', () {
      expect(budgetUtile(EtatSeanceFamille.enDirect), isTrue);
      expect(budgetUtile(EtatSeanceFamille.horaireIncertain), isTrue);
      expect(budgetUtile(EtatSeanceFamille.aVenir), isFalse);
      expect(budgetUtile(EtatSeanceFamille.annulee), isFalse);
    });

    test('bandeau : salle ouverte a droite le compte a rebours, en direct la '
        'presence', () {
      final AffichageSeance salle = AffichageSeance.depuis(
        seanceSalleOuverte(),
        maintenantServeurUtc: instantServeurFige,
      );
      final ({String gauche, String? droite, TonEtat ton}) b1 = bandeauSeance(
        salle,
      );
      expect(b1.gauche, LibellesGroupe.salleOuverteCourt);
      expect(b1.droite, LibellesGroupe.dansMinutes(10));
      expect(b1.ton, TonEtat.succes);

      final AffichageSeance direct = AffichageSeance.depuis(
        seanceEnDirect(),
        maintenantServeurUtc: instantServeurFige,
      );
      final ({String gauche, String? droite, TonEtat ton}) b2 = bandeauSeance(
        direct,
        presence: 'presence fictive',
      );
      expect(b2.gauche, t.tuteur.accueil.seanceEnDirect);
      expect(b2.droite, 'presence fictive');
    });

    test('seances a venir : de la plus proche a la plus lointaine, closes et '
        'passees ecartees, autre classe ecartee', () {
      final List<SeanceFamille> seances = <SeanceFamille>[
        seanceSalleOuverte(seanceId: 'loin', avant: const Duration(days: 3)),
        seanceSalleOuverte(seanceId: 'proche'),
        seanceSalleOuverte(
          seanceId: 'passee',
          avant: const Duration(days: -2),
          statut: StatutSeance.terminee,
        ),
        seanceFictive(
          seanceId: 'autre-eleve',
          eleveId: 'foyer-a-eleve-2',
          debutUtc: instantServeurFige.add(const Duration(days: 1)),
        ),
      ];
      final List<SeanceFamille> retenues = seancesAVenir(
        seances,
        classeId: _classe,
        eleveId: _a1,
        referenceUtc: instantServeurFige,
      );
      expect(retenues.map((SeanceFamille s) => s.seanceId), <String>[
        'proche',
        'loin',
      ]);
    });

    test(
      'travaux : echeance la plus proche d abord, retires ecartes',
      () async {
        final List<LearningAssignment> travaux = travauxAffiches(
          await (await travauxFictifs()).pourGroupe(_classe, studentId: _a1),
        );
        expect(travaux, hasLength(2));
        expect(travaux.first.instructions, 'Consigne fictive 1');
        expect(
          statutTravail(StatutAssignation.fait).libelle,
          t.classe.pageTravail.statut.fait,
        );
      },
    );

    test('progression vide : ni niveau ni etape', () {
      expect(progressionVide(const ProgressionEleve(eleveId: _a1)), isTrue);
      expect(
        progressionVide(
          const ProgressionEleve(eleveId: _a1, niveauHumain: 'N'),
        ),
        isFalse,
      );
    });
  });
}
