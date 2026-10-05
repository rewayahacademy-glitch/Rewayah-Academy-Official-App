// Lot O, sous-paquet 1 : l'entree dans l'observation et l'explication de
// premiere utilisation (maquette V8 M2, logigramme V7). Chaque parcours part
// d'une classe et se fait en TOUCHANT les boutons : « Observer la seance »,
// « Comment ca marche ? », « Observer maintenant », « Pas maintenant », le
// disque retour, « Reessayer ».
//
// La classe est ici un double minimal : ses deux boutons appellent
// `ouvrirObservation`, exactement le geste que le bloc Observation de la
// classe (lot C, sous-paquet 2) doit poser. Le parcours depuis la vraie
// navigation de l'application est dans `entree_observation_navigation_test`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/libelles_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/tc_observation_ui/explication_premiere_visite.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/verification_prealable.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart' show FauxServicePresence;
import '../../support/hors_ligne_une_fois.dart';
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

/// La memoire « explication deja lue » du compte de test (`p1`).
final String _cleVue = clefExplicationVue('p1');

/// Les tests qui ENTRENT en salle se font au format telephone : la salle
/// refondue au sous-paquet 2 ne deborde plus a 390 (elle debordait de 49 px
/// dans la base).
const Size _tailleSalle = Size(390, 844);

/// Libelle du lien « Comment ca marche ? » de la classe double (le vrai
/// libelle appartient au lot C).
const String _commentCaMarche = 'Comment ca marche ?';

/// La classe, reduite a son bloc Observation : les deux gestes du lot C.
class _ClasseDouble extends StatelessWidget {
  const _ClasseDouble({required this.classeId, this.eleveId});

  final String classeId;
  final String? eleveId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('CLASSE $classeId ${eleveId ?? '-'}'),
        ActionPrincipale(
          libelle: t.classe.observer,
          onPress: () => ouvrirObservation(
            context,
            seanceId: 's1',
            classeId: classeId,
            eleveId: eleveId,
          ),
        ),
        ActionPrincipale(
          libelle: _commentCaMarche,
          niveau: NiveauAction.tertiaire,
          onPress: () => ouvrirObservation(
            context,
            seanceId: 's1',
            classeId: classeId,
            eleveId: eleveId,
            entrer: false,
          ),
        ),
      ],
    ),
  );
}

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: Routes.racine,
    builder: (BuildContext _, GoRouterState _) => const Text('RACINE'),
  ),
  GoRoute(
    path: '${Routes.tuteurClasses}/:classeId',
    builder: (BuildContext _, GoRouterState etat) => _ClasseDouble(
      classeId: etat.pathParameters['classeId']!,
      eleveId: etat.uri.queryParameters['eleve'],
    ),
  ),
  ...routesTcG(),
];

/// Monte la classe double (ou [depart]) avec les faux de l'observation.
Future<void> _monter(
  WidgetTester tester, {
  FauxPortVisite? visites,
  FauxPortPolitique? politique,
  FauxServicePresence? presence,
  StockagePreferences? stockage,
  bool observationReelle = true,
  bool horsLigne = false,
  String depart = '/tuteur/classes/c1?eleve=enfant-1',
  Size taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
  bool attendre = true,
  TextDirection direction = TextDirection.ltr,
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: visites,
        politique: politique,
        presence: presence,
        stockage: stockage,
        observationReelle: observationReelle,
        horsLigne: horsLigne,
      ),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(interface, Brightness.light),
          darkTheme: AppTheme.pour(interface, Brightness.dark),
          themeMode: mode,
          // Sens et echelle du texte des captures (EA-HL-DOUBLE-1d) ; par
          // defaut, ceux de l'application.
          builder: (BuildContext contexte, Widget? app) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          routerConfig: GoRouter(initialLocation: depart, routes: _routes()),
        ),
      ),
    ),
  );
  if (attendre) {
    await tester.pumpAndSettle();
  }
}

/// Laisse passer navigation, lectures et rappels d'apres-trame, sans exiger
/// que tout s'arrete : un indicateur d'activite tourne sans fin.
Future<void> _avancer(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Amene la cible dans le cadre, puis la presse.
Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Finder get _titreExplication => find.text(t.tc.observation.explication.titre);
Finder get _observerMaintenant =>
    find.text(t.tc.observation.explication.observer);
Finder get _pasMaintenant =>
    find.text(t.tc.observation.explication.pasMaintenant);

void main() {
  group('Premiere utilisation : l\'explication, puis l\'entree', () {
    testWidgets(
      'Observer la seance ouvre l\'explication ; rien n\'est compte avant '
      '« Observer maintenant »',
      (WidgetTester tester) async {
        final FauxPortVisite visites = FauxPortVisite();
        final FauxPortPolitique politique = FauxPortPolitique();
        addTearDown(politique.fermer);
        await _monter(
          tester,
          taille: _tailleSalle,
          visites: visites,
          politique: politique,
        );

        await _presser(tester, find.text(t.classe.observer));

        // M2, dans l'ordre de la maquette, avec la regle du serveur.
        expect(_titreExplication, findsOneWidget);
        expect(
          find.text(regleVisitesObservation(2, const Duration(seconds: 120))),
          findsOneWidget,
        );
        expect(find.text('2 visites de 2\u00A0minutes'), findsOneWidget);
        final e = t.tc.observation.explication;
        for (final String texte in <String>[
          e.regleDetail,
          e.ecoute,
          e.ecouteDetail,
          e.sansMedia,
          e.sansMediaDetail,
          e.revenir,
          e.ecourtee,
          e.sansIntervenir,
          e.informes,
        ]) {
          expect(find.text(texte), findsOneWidget, reason: texte);
        }
        // Aucune visite consommee : la regle suffit, comme sur M2.
        expect(find.textContaining('restante'), findsNothing);

        // **Le compteur n'a pas demarre** : aucune entree demandee, aucun flux
        // de budget ouvert, aucun panneau de visite.
        expect(visites.rolesDemandes, isEmpty);
        expect(politique.abonnements, 0);
        expect(find.byType(PanneauObservationTuteur), findsNothing);

        await _presser(tester, _observerMaintenant);

        expect(visites.rolesDemandes, <RoleObservateur>[
          RoleObservateur.tuteur,
        ]);
        expect(find.byType(PanneauObservationTuteur), findsOneWidget);
      },
    );

    testWidgets('« Pas maintenant » ramene a la classe de l\'enfant, sans '
        'rien consommer', (WidgetTester tester) async {
      final FauxPortVisite visites = FauxPortVisite();
      await _monter(tester, visites: visites);

      await _presser(tester, find.text(t.classe.observer));
      await _presser(tester, _pasMaintenant);

      expect(find.text('CLASSE c1 enfant-1'), findsOneWidget);
      expect(visites.rolesDemandes, isEmpty);
    });

    testWidgets('le disque retour ramene aussi a la classe', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite();
      await _monter(tester, visites: visites);

      await _presser(tester, find.text(t.classe.observer));
      await _presser(tester, find.byType(DisqueRetour));

      expect(find.text('CLASSE c1 enfant-1'), findsOneWidget);
      expect(visites.rolesDemandes, isEmpty);
    });

    testWidgets('« Observer maintenant » retient l\'explication comme lue', (
      WidgetTester tester,
    ) async {
      final StockagePreferencesMemoire stockage = StockagePreferencesMemoire();
      await _monter(tester, taille: _tailleSalle, stockage: stockage);

      await _presser(tester, find.text(t.classe.observer));
      expect(stockage.valeurs[_cleVue], isNull);
      await _presser(tester, _observerMaintenant);

      expect(stockage.valeurs[_cleVue], isNotNull);
    });
  });

  group('Explication deja lue', () {
    testWidgets(
      'Observer la seance : directement « Connexion et verification », '
      'puis la visite',
      (WidgetTester tester) async {
        final FauxPortVisite visites = FauxPortVisite()
          ..entreeSuspendue = Completer<void>();
        await _monter(
          tester,
          taille: _tailleSalle,
          visites: visites,
          stockage: StockagePreferencesMemoire(<String, String>{
            _cleVue: 'oui',
          }),
        );

        // L'attente tourne (indicateur d'activite) : pas de `pumpAndSettle`.
        await tester.tap(find.text(t.classe.observer));
        await _avancer(tester);

        // Logigramme V7 : « Explication deja vue » -> connexion.
        expect(_titreExplication, findsNothing);
        expect(find.text(t.tc.observation.connexion.titre), findsOneWidget);
        expect(visites.rolesDemandes, <RoleObservateur>[
          RoleObservateur.tuteur,
        ]);
        // Une demande en vol ne se laisse pas en plan : pas de retour.
        expect(find.byType(DisqueRetour), findsNothing);

        visites.entreeSuspendue!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(PanneauObservationTuteur), findsOneWidget);
        // Une seule entree, jamais deux.
        expect(visites.rolesDemandes, hasLength(1));
      },
    );

    testWidgets(
      '« Comment ca marche ? » montre l\'explication et n\'entre pas',
      (WidgetTester tester) async {
        final FauxPortVisite visites = FauxPortVisite();
        await _monter(
          tester,
          visites: visites,
          stockage: StockagePreferencesMemoire(<String, String>{
            _cleVue: 'oui',
          }),
        );

        await _presser(tester, find.text(_commentCaMarche));

        expect(_titreExplication, findsOneWidget);
        expect(_observerMaintenant, findsOneWidget);
        expect(visites.rolesDemandes, isEmpty);
      },
    );

    testWidgets('un lien direct ou un rechargement n\'ouvre JAMAIS de visite', (
      WidgetTester tester,
    ) async {
      // L'adresse seule, sans le geste de la classe : c'est ce que rend un
      // rechargement, un retour arriere ou un lien colle.
      final FauxPortVisite visites = FauxPortVisite();
      await _monter(
        tester,
        visites: visites,
        stockage: StockagePreferencesMemoire(<String, String>{_cleVue: 'oui'}),
        depart: cheminObservation('s1', classeId: 'c1', eleveId: 'enfant-1'),
      );

      expect(_titreExplication, findsOneWidget);
      expect(visites.rolesDemandes, isEmpty);
    });
  });

  group('Deuxieme visite', () {
    testWidgets('les visites restantes se disent, « revenez plus tard » non', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..dernierBudget = unBudget(
          visitesUtilisees: 1,
          visitesMax: 2,
          total: const Duration(seconds: 240),
        );
      addTearDown(politique.fermer);
      await _monter(tester, politique: politique);

      await _presser(tester, find.text(t.classe.observer));

      expect(
        find.text(visitesRestantesLisible(restantes: 1, max: 2)),
        findsOneWidget,
      );
      expect(
        find.text('1/2 visite restante pour cette séance'),
        findsOneWidget,
      );
      // Apres cette visite, il n'en restera aucune : le conseil serait faux.
      expect(find.text(t.tc.observation.explication.revenir), findsNothing);
      expect(find.text(t.tc.observation.explication.ecourtee), findsOneWidget);
    });
  });

  group('Indisponibilites et etats', () {
    testWidgets('presence en verification : jamais « absent », on reverifie', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      final FauxServicePresence presence = FauxServicePresence(
        lignes: <PresenceParticipant>[
          presenceDe(etat: EtatPresence.enConnexion),
        ],
      );
      await _monter(
        tester,
        taille: _tailleSalle,
        politique: politique,
        presence: presence,
        stockage: StockagePreferencesMemoire(<String, String>{_cleVue: 'oui'}),
      );

      await _presser(tester, find.text(t.classe.observer));

      final d = t.tc.observation.disponibilite;
      expect(find.text(d.presenceTitre), findsOneWidget);
      expect(find.text(d.enfantAbsentTitre), findsNothing);
      final int lectures = politique.lecturesBudget;

      // La presence se confirme : « Reessayer » relit, et le geste de la
      // classe, toujours valable, mene a l'entree (explication deja lue).
      presence.lignes = <PresenceParticipant>[presenceDe()];
      await _presser(tester, find.text(t.commun.etats.actions.reessayer));
      expect(politique.lecturesBudget, greaterThan(lectures));
      expect(find.text(d.presenceTitre), findsNothing);
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    });

    testWidgets('« Comment ca marche ? » alors que l\'entree est impossible : '
        'l\'explication, et le motif a la place de l\'action', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..dernierBudget = unBudget(
          visitesUtilisees: 2,
          visitesMax: 2,
          total: const Duration(seconds: 240),
          restant: Duration.zero,
          peutEntrer: false,
          motifRefus: MotifRefusObservation.quotaVisitesAtteint,
        );
      addTearDown(politique.fermer);
      await _monter(tester, politique: politique);

      await _presser(tester, find.text(_commentCaMarche));

      expect(_titreExplication, findsOneWidget);
      expect(
        find.text(t.tc.observation.disponibilite.visitesEpuiseesTitre),
        findsOneWidget,
      );
      expect(_observerMaintenant, findsNothing);
      await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
      expect(find.text('CLASSE c1 enfant-1'), findsOneWidget);
    });

    testWidgets('visites epuisees apres le geste : la page le dit', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite();
      final FauxPortPolitique politique = FauxPortPolitique()
        ..dernierBudget = unBudget(
          visitesUtilisees: 2,
          visitesMax: 2,
          total: const Duration(seconds: 240),
          restant: Duration.zero,
          peutEntrer: false,
          motifRefus: MotifRefusObservation.quotaVisitesAtteint,
        );
      addTearDown(politique.fermer);
      await _monter(
        tester,
        visites: visites,
        politique: politique,
        stockage: StockagePreferencesMemoire(<String, String>{_cleVue: 'oui'}),
      );

      await _presser(tester, find.text(t.classe.observer));

      expect(
        find.text(t.tc.observation.disponibilite.visitesEpuiseesTitre),
        findsOneWidget,
      );
      expect(visites.rolesDemandes, isEmpty);
    });

    testWidgets('une visite deja ouverte ne se rouvre pas', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite();
      final FauxPortPolitique politique = FauxPortPolitique()
        ..dernierBudget = unBudget(
          visitesUtilisees: 1,
          visitesMax: 2,
          total: const Duration(seconds: 240),
          visiteEnCours: true,
        );
      addTearDown(politique.fermer);
      await _monter(
        tester,
        visites: visites,
        politique: politique,
        stockage: StockagePreferencesMemoire(<String, String>{_cleVue: 'oui'}),
      );

      await _presser(tester, find.text(t.classe.observer));

      expect(
        find.text(t.tc.observation.disponibilite.visiteOuverteTitre),
        findsOneWidget,
      );
      expect(visites.rolesDemandes, isEmpty);
    });

    testWidgets('chargement : un squelette, puis le contenu', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..budgetSuspendu = Completer<void>();
      addTearDown(politique.fermer);
      await _monter(
        tester,
        politique: politique,
        depart: cheminObservation('s1', classeId: 'c1'),
        attendre: false,
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(Skeleton), findsWidgets);
      expect(_observerMaintenant, findsNothing);

      politique.budgetSuspendu!.complete();
      await tester.pumpAndSettle();
      expect(_observerMaintenant, findsOneWidget);
    });

    testWidgets('erreur du serveur : « Verification impossible », '
        'Reessayer relit', (WidgetTester tester) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..echecBudget = const EchecObservation(MotifEchecObservation.reseau);
      addTearDown(politique.fermer);
      await _monter(tester, politique: politique);

      await _presser(tester, find.text(t.classe.observer));

      final d = t.tc.observation.disponibilite;
      expect(find.text(d.reseauTitre), findsOneWidget);
      expect(find.text(t.tc.observation.entree.retourClasse), findsOneWidget);

      politique.echecBudget = null;
      await _presser(tester, find.text(t.commun.etats.actions.reessayer));
      expect(find.text(d.reseauTitre), findsNothing);
      expect(_titreExplication, findsOneWidget);
    });

    testWidgets('hors ligne : le motif dit ce qui manque, le bandeau seul '
        'dit le reseau (EA-HL-DOUBLE-1), jamais une entree', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite();
      final FauxPortPolitique politique = FauxPortPolitique()
        ..echecBudget = const EchecObservation(MotifEchecObservation.reseau);
      addTearDown(politique.fermer);
      await _monter(
        tester,
        visites: visites,
        politique: politique,
        horsLigne: true,
      );

      await _presser(tester, find.text(t.classe.observer));

      expect(find.text(t.commun.etats.horsLigne.titre), findsNothing);
      expect(
        find.text(t.tc.observation.disponibilite.reseauTitre),
        findsOneWidget,
      );
      expectHorsLigneUneFois();
      expect(visites.rolesDemandes, isEmpty);
    });

    testWidgets('capacite absente : indisponible, sans Reessayer', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..echecBudget = const EchecObservation(
          MotifEchecObservation.capaciteAbsente,
        );
      addTearDown(politique.fermer);
      await _monter(tester, politique: politique);

      await _presser(tester, find.text(t.classe.observer));

      expect(
        find.text(t.tc.observation.disponibilite.capaciteTitre),
        findsOneWidget,
      );
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.text(t.tc.observation.entree.retourClasse), findsOneWidget);
    });

    testWidgets('observation reelle fermee (P3) : aucun appel, retour a la '
        'classe', (WidgetTester tester) async {
      final FauxPortVisite visites = FauxPortVisite();
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      await _monter(
        tester,
        visites: visites,
        politique: politique,
        observationReelle: false,
      );

      await _presser(tester, find.text(t.classe.observer));

      expect(
        find.text(t.tc.observation.disponibilite.fermeeTitre),
        findsOneWidget,
      );
      expect(politique.lecturesBudget, 0);
      expect(visites.rolesDemandes, isEmpty);

      await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
      expect(find.text('CLASSE c1 enfant-1'), findsOneWidget);
    });

    testWidgets('un identifiant de seance illisible : introuvable', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      await _monter(
        tester,
        politique: politique,
        depart: '/tc/observation/s1%20x',
      );

      expect(find.text(t.commun.etats.introuvable.titre), findsOneWidget);
      expect(politique.lecturesBudget, 0);
    });

    testWidgets('une classe illisible dans l\'adresse ne sert pas de retour', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: '/tc/observation/s1?classe=..%2Fcompte');

      await _presser(tester, _pasMaintenant);
      expect(find.text('RACINE'), findsOneWidget);
    });
  });

  group('Connexion et verification', () {
    testWidgets('la connexion qui tarde se dit, sans retour possible', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite()
        ..entreeSuspendue = Completer<void>();
      await _monter(tester, taille: _tailleSalle, visites: visites);

      await _presser(tester, find.text(t.classe.observer));
      await tester.ensureVisible(_observerMaintenant);
      await tester.tap(_observerMaintenant);
      await tester.pump();
      await tester.pump();

      expect(find.text(t.tc.observation.connexion.enCours), findsOneWidget);
      expect(_pasMaintenant, findsNothing);
      expect(find.byType(DisqueRetour), findsNothing);
      expect(find.text(t.tc.observation.connexion.prolongee), findsNothing);

      await tester.pump(AppDelais.chargementProlonge);
      await tester.pump();
      expect(find.text(t.tc.observation.connexion.prolongee), findsOneWidget);

      visites.entreeSuspendue!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    });

    testWidgets('connexion impossible, puis Reessayer : relecture et nouvelle '
        'entree', (WidgetTester tester) async {
      final FauxPortVisite visites = FauxPortVisite(
        echecEntree: const EchecObservation(MotifEchecObservation.reseau),
      );
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      await _monter(
        tester,
        taille: _tailleSalle,
        visites: visites,
        politique: politique,
      );

      await _presser(tester, find.text(t.classe.observer));
      await _presser(tester, _observerMaintenant);

      final c = t.tc.observation.connexion;
      expect(find.text(c.impossibleTitre), findsOneWidget);
      expect(find.text(t.tc.observation.entree.retourClasse), findsOneWidget);
      final int lectures = politique.lecturesBudget;

      visites.echecEntree = null;
      await _presser(tester, find.text(t.commun.etats.actions.reessayer));

      // Les visites restantes sont relues, jamais supposees ; puis l'entree
      // repart, la pression sur « Reessayer » etant le geste.
      expect(politique.lecturesBudget, greaterThan(lectures));
      expect(visites.rolesDemandes, hasLength(2));
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    });

    // EA-HL-DOUBLE-1d : le reseau tombe apres la verification prealable.
    // L'echec de l'entree, pose sous le bandeau, dit ce qui manque ; ni
    // « Connexion impossible », ni « Verifiez votre connexion ».
    testWidgets('hors ligne pendant l\'entree : l\'echec ne redit pas le '
        'reseau sous le bandeau', (WidgetTester tester) async {
      final FauxPortVisite visites = FauxPortVisite(
        echecEntree: const EchecObservation(MotifEchecObservation.reseau),
      );
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      await _monter(
        tester,
        taille: _tailleSalle,
        visites: visites,
        politique: politique,
        horsLigne: true,
      );

      await _presser(tester, find.text(t.classe.observer));
      await _presser(tester, _observerMaintenant);

      final c = t.tc.observation.connexion;
      expect(find.text(c.impossibleTitre), findsOneWidget);
      expect(find.text(c.impossible), findsOneWidget);
      expect(visites.rolesDemandes, hasLength(1));
      expectHorsLigneUneFois();
    });

    testWidgets('un refus du serveur a l\'entree se dit par son motif', (
      WidgetTester tester,
    ) async {
      final FauxPortVisite visites = FauxPortVisite(
        reponse: const ResultatEntreeObservation(
          autorise: false,
          motifRefus: MotifRefusObservation.horsFenetre,
        ),
      );
      await _monter(tester, visites: visites);

      await _presser(tester, find.text(t.classe.observer));
      await _presser(tester, _observerMaintenant);

      expect(
        find.text(t.tc.observation.disponibilite.horsFenetreTitre),
        findsOneWidget,
      );
      await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
      expect(find.text('CLASSE c1 enfant-1'), findsOneWidget);
    });
  });

  group('Formats et themes', () {
    testWidgets('bureau 1440 : une colonne de lecture bornee, pas la feuille '
        'mobile etiree', (WidgetTester tester) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        depart: cheminObservation('s1', classeId: 'c1', eleveId: 'enfant-1'),
      );

      expect(_titreExplication, findsOneWidget);
      final double largeur = tester
          .getSize(find.byType(ExplicationPremiereVisite))
          .width;
      expect(largeur, lessThanOrEqualTo(AppPage.largeurDialogue));
      // La colonne est centree dans la fenetre.
      final double centre = tester
          .getCenter(find.byType(ExplicationPremiereVisite))
          .dx;
      expect((centre - 720).abs(), lessThan(AppSpacing.xl));
    });

    testWidgets('sombre : meme arbre, aucune erreur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        mode: ThemeMode.dark,
        depart: cheminObservation('s1', classeId: 'c1', eleveId: 'enfant-1'),
      );

      expect(_titreExplication, findsOneWidget);
      expect(_observerMaintenant, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('texte agrandi a 200 % : rien ne deborde', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(
        tester,
        depart: cheminObservation('s1', classeId: 'c1', eleveId: 'enfant-1'),
      );

      expect(_titreExplication, findsOneWidget);
      expect(tester.takeException(), isNull);
      // L'action reste atteignable, entiere, au doigt.
      await tester.ensureVisible(_observerMaintenant);
      await tester.pumpAndSettle();
      expect(_observerMaintenant.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('La politique effective, jamais une constante', () {
    testWidgets('trois visites de 90 secondes se disent telles quelles', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique =
          FauxPortPolitique(
              politique: const GuardianObservationPolicy(
                policyVersion: 'g:4',
                source: SourcePolitique.groupe,
                observationActivee: true,
                maxVisitsPerSession: 3,
                maxTotalObservationTime: Duration(seconds: 270),
                maxParVisite: Duration(seconds: 90),
              ),
            )
            ..dernierBudget = unBudget(
              visitesUtilisees: 0,
              visitesMax: 3,
              total: const Duration(seconds: 270),
              restant: const Duration(seconds: 90),
            );
      addTearDown(politique.fermer);
      await _monter(tester, politique: politique);

      await _presser(tester, find.text(_commentCaMarche));

      expect(
        find.text('3 visites de 1\u00A0min\u00A030\u00A0s'),
        findsOneWidget,
      );
      expect(find.text('2 visites de 2\u00A0minutes'), findsNothing);
    });

    testWidgets('sans regle lisible, aucune explication chiffree', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique politique = FauxPortPolitique()
        ..dernierBudget = unBudget(
          visitesUtilisees: 0,
          visitesMax: 0,
          total: Duration.zero,
          restant: Duration.zero,
        );
      addTearDown(politique.fermer);
      await _monter(
        tester,
        politique: politique,
        depart: cheminObservation('s1'),
      );

      expect(_titreExplication, findsNothing);
      expect(find.textContaining('visites de'), findsNothing);
      expect(_observerMaintenant, findsNothing);
    });
  });

  // EA-HL-DOUBLE-1d : l'echec de l'entree quand le reseau tombe apres la
  // verification (revue EA-HL-DOUBLE-1c-R, mineur 3), dans tous ses formats ;
  // et la verification hors ligne a 320 texte x2, LTR et RTL (mineur 2).
  // Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1d', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, ThemeMode, InterfaceMode, double, TextDirection)
        cas
        in <(String, Size, ThemeMode, InterfaceMode, double, TextDirection)>[
          (
            '390_clair',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.standard,
            1,
            TextDirection.ltr,
          ),
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            1,
            TextDirection.ltr,
          ),
          (
            '390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            1,
            TextDirection.ltr,
          ),
          (
            '320x2_clair',
            const Size(320, 1800),
            ThemeMode.light,
            InterfaceMode.standard,
            2,
            TextDirection.ltr,
          ),
          (
            '320x2_rtl_clair',
            const Size(320, 1800),
            ThemeMode.light,
            InterfaceMode.standard,
            2,
            TextDirection.rtl,
          ),
          (
            '1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            1,
            TextDirection.ltr,
          ),
        ]) {
      testWidgets('echec de l\'entree ${cas.$1}', (WidgetTester tester) async {
        final FauxPortVisite visites = FauxPortVisite(
          echecEntree: const EchecObservation(MotifEchecObservation.reseau),
        );
        final FauxPortPolitique politique = FauxPortPolitique();
        addTearDown(politique.fermer);
        await _monter(
          tester,
          visites: visites,
          politique: politique,
          horsLigne: true,
          taille: cas.$2,
          mode: cas.$3,
          interface: cas.$4,
          echelle: cas.$5,
          direction: cas.$6,
        );
        await _presser(tester, find.text(t.classe.observer));
        await _presser(tester, _observerMaintenant);
        expect(tester.takeException(), isNull);
        expect(
          find.text(t.tc.observation.connexion.impossibleTitre),
          findsOneWidget,
        );
        expectHorsLigneUneFois();
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1d_observation_echec_entree_${cas.$1}')}',
        );
      });

      if (cas.$5 == 2) {
        testWidgets('verification ${cas.$1}', (WidgetTester tester) async {
          final FauxPortPolitique politique = FauxPortPolitique()
            ..echecBudget = const EchecObservation(
              MotifEchecObservation.reseau,
            );
          addTearDown(politique.fermer);
          await _monter(
            tester,
            politique: politique,
            horsLigne: true,
            taille: cas.$2,
            mode: cas.$3,
            interface: cas.$4,
            echelle: cas.$5,
            direction: cas.$6,
          );
          await _presser(tester, find.text(t.classe.observer));
          expect(tester.takeException(), isNull);
          expectHorsLigneUneFois();
          verifierAucunMotCoupe(tester, find.byType(MaterialApp));
          debugPrint(
            'PNG ${await capturerVue(tester, 'ea_hl_double1d_observation_verification_${cas.$1}')}',
          );
        });
      }
    }
  });

  // EA-HL-DOUBLE-1c : Interface guidee et texte x2 de la verification de
  // l'observation hors ligne (revue EA-HL-DOUBLE-1-R, m4). Sautees sans
  // CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, ThemeMode) cas in <(String, ThemeMode)>[
      ('390_guidee', ThemeMode.light),
      ('390_guidee_sombre', ThemeMode.dark),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        final FauxPortPolitique politique = FauxPortPolitique()
          ..echecBudget = const EchecObservation(MotifEchecObservation.reseau);
        addTearDown(politique.fermer);
        await _monter(
          tester,
          politique: politique,
          horsLigne: true,
          mode: cas.$2,
          interface: InterfaceMode.enfant,
        );
        await _presser(tester, find.text(t.classe.observer));
        expect(tester.takeException(), isNull);
        expectHorsLigneUneFois();
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_observation_${cas.$1}')}',
        );
      });
    }
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve de la verification de
  // l'observation hors ligne : le motif dit ce qui manque, le bandeau seul
  // dit le reseau. Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, ThemeMode) cas in <(String, Size, ThemeMode)>[
      ('390_clair', const Size(390, 844), ThemeMode.light),
      ('390_sombre', const Size(390, 844), ThemeMode.dark),
      ('320_clair', const Size(320, 900), ThemeMode.light),
      ('1440_clair', const Size(1440, 900), ThemeMode.light),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        final FauxPortPolitique politique = FauxPortPolitique()
          ..echecBudget = const EchecObservation(MotifEchecObservation.reseau);
        addTearDown(politique.fermer);
        await _monter(
          tester,
          politique: politique,
          horsLigne: true,
          taille: cas.$2,
          mode: cas.$3,
        );
        await _presser(tester, find.text(t.classe.observer));
        expect(tester.takeException(), isNull);
        expectHorsLigneUneFois();
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1_observation_${cas.$1}')}',
        );
      });
    }
  });
}
