// Lot O, sous-paquet 3 : fins de visite et etats (maquette V8 M5 et ses
// variantes derivees : sortie volontaire, duree atteinte, fin de seance,
// visites epuisees, observation interrompue). Chaque parcours part d'une
// classe et se fait en TOUCHANT les boutons : « Observer la seance »,
// « Observer maintenant », « Quitter », la confirmation, puis « Retour a la
// classe » ou « Voir mes observations ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/tc_observation_ui/ouverture_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';
import 'package:rewayah_academy/features/tc_observation_ui/resultat_visite_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';

import '../e/faux/faux_classe.dart'
    show FauxMoteurClasse, FauxServiceVideoClasse, accesDe, participantDe;
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

/// La classe, reduite a son bouton « Observer la seance » (lot C).
class _ClasseDouble extends StatelessWidget {
  const _ClasseDouble({required this.classeId, this.eleveId});

  final String classeId;
  final String? eleveId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text('CLASSE $classeId ELEVE ${eleveId ?? '-'}'),
        ActionPrincipale(
          libelle: t.classe.observer,
          onPress: () => ouvrirObservation(
            context,
            seanceId: 's1',
            classeId: classeId,
            eleveId: eleveId,
          ),
        ),
      ],
    ),
  );
}

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: '${Routes.tuteurClasses}/:classeId',
    builder: (BuildContext _, GoRouterState etat) => _ClasseDouble(
      classeId: etat.pathParameters['classeId']!,
      eleveId: etat.uri.queryParameters['eleve'],
    ),
  ),
  GoRoute(
    path: Routes.tuteurSuiviObservations,
    builder: (BuildContext _, GoRouterState etat) => Text(
      'HISTORIQUE OBSERVATIONS ${etat.uri.queryParameters['eleve'] ?? '-'}',
    ),
  ),
  ...routesTcG(),
];

/// La reponse du serveur a l'entree.
ResultatEntreeObservation _entree({
  int rang = 1,
  int utilisees = 1,
  int max = 2,
}) => ResultatEntreeObservation(
  autorise: true,
  visite: uneVisite(visitNumber: rang),
  budget: unBudget(
    restant: const Duration(seconds: 102),
    visitesUtilisees: utilisees,
    visitesMax: max,
    total: const Duration(seconds: 240),
  ),
);

class _Salle {
  _Salle(this.visites, this.politique, this.moteur);

  final FauxPortVisite visites;
  final FauxPortPolitique politique;
  final FauxMoteurClasse moteur;
}

Future<_Salle> _entrerEnSalle(
  WidgetTester tester, {
  ResultatEntreeObservation? reponse,
  Size taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
  String depart = '/tuteur/classes/c1?eleve=enfant-1',
  FauxPortVisite? visites,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxPortVisite porte = (visites ?? FauxPortVisite())
    ..reponse = reponse ?? _entree();
  final FauxPortPolitique politique = FauxPortPolitique();
  addTearDown(politique.fermer);
  final FauxMoteurClasse moteur = FauxMoteurClasse();

  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesTcG(
        role: AppRole.guardian,
        visites: porte,
        politique: politique,
        moteur: moteur,
        video: FauxServiceVideoClasse(acces0: accesDe('guardian_observer')),
      ),
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: mode,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(echelleTexte)),
            child: enfant!,
          ),
          routerConfig: GoRouter(initialLocation: depart, routes: _routes()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.text(t.classe.observer));
  await _presser(tester, find.text(t.tc.observation.explication.observer));
  moteur.publier(<ParticipantSalle>[
    participantDe(identite: 'prof-1', role: 'teacher', nom: 'Amina'),
    participantDe(identite: 'enfant-1', role: 'student', nom: 'Mariam'),
  ]);
  await tester.pumpAndSettle();
  expect(find.byType(PanneauObservationTuteur), findsOneWidget);
  return _Salle(porte, politique, moteur);
}

/// Un tour de la vraie boucle : la fermeture de la visite attend un futur de
/// la zone racine que l'horloge simulee n'avance pas.
Future<void> _laisserFinir(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// « Quitter », puis « Quitter la visite ».
Future<void> _quitter(WidgetTester tester) async {
  await _presser(tester, find.text(t.tc.observation.visite.quitter));
  await _presser(tester, find.text(t.tc.observation.visite.quitterConfirmer));
  await _laisserFinir(tester);
}

final r = t.tc.observation.resultat;

void main() {
  group('Fin de visite, au format telephone (M5)', () {
    testWidgets('sortie volontaire, premiere visite : M5 avec les visites '
        'restantes relues aupres du serveur', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      // Apres la fermeture, le serveur compte une visite sur deux.
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 1,
        visitesMax: 2,
        restant: const Duration(seconds: 138),
        total: const Duration(seconds: 240),
      );
      final int lecturesAvant = salle.politique.lecturesBudget;
      await _quitter(tester);

      expect(salle.visites.sorties, <String>['s1']);
      expect(find.byType(ResultatVisite), findsOneWidget);
      expect(find.byType(PanneauObservationTuteur), findsNothing);
      expect(find.text(r.premiereTerminee), findsOneWidget);
      expect(find.text(r.continuePour(prenom: 'Mariam')), findsOneWidget);
      // Relu aupres du serveur, jamais deduit : duree de la politique
      // effective de la classe (120 s).
      expect(salle.politique.lecturesBudget, greaterThan(lecturesAvant));
      expect(find.text(r.resteUne(duree: '2 minutes')), findsOneWidget);
      // Horloge de la maquette M5 (demande O-4), plus le sablier.
      expect(find.byIcon(AppIcons.horloge.repos), findsOneWidget);
      expect(find.byIcon(AppIcons.attente.repos), findsNothing);
      expect(find.text(r.voirObservations), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Retour a la classe » ramene a la classe avec l\'enfant', (
      WidgetTester tester,
    ) async {
      await _entrerEnSalle(tester);
      await _quitter(tester);

      await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
      expect(find.text('CLASSE c1 ELEVE enfant-1'), findsOneWidget);
    });

    testWidgets('sans enfant dans l\'adresse, le retour reprend l\'enfant de '
        'la visite', (WidgetTester tester) async {
      await _entrerEnSalle(tester, depart: '/tuteur/classes/c1');
      await _quitter(tester);

      await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
      expect(find.text('CLASSE c1 ELEVE enfant-1'), findsOneWidget);
    });

    testWidgets('« Voir mes observations » ouvre l\'Historique, segment '
        'Observations, pour l\'enfant', (WidgetTester tester) async {
      await _entrerEnSalle(tester);
      await _quitter(tester);

      await _presser(tester, find.text(r.voirObservations));
      expect(find.text('HISTORIQUE OBSERVATIONS enfant-1'), findsOneWidget);
    });

    testWidgets('le retour du systeme sur la fin mene a la classe', (
      WidgetTester tester,
    ) async {
      await _entrerEnSalle(tester);
      await _quitter(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('CLASSE c1 ELEVE enfant-1'), findsOneWidget);
    });

    testWidgets('visites epuisees : « derniere visite », aucune restante', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(
        tester,
        reponse: _entree(rang: 2, utilisees: 2),
      );
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 2,
        visitesMax: 2,
        peutEntrer: false,
        motifRefus: MotifRefusObservation.quotaVisitesAtteint,
        total: const Duration(seconds: 240),
      );
      await _quitter(tester);

      expect(find.text(r.derniereTerminee), findsOneWidget);
      expect(find.text(r.aucune), findsOneWidget);
      expect(find.text(r.resteUne(duree: '2 minutes')), findsNothing);
    });

    testWidgets('plusieurs visites restantes : accord au pluriel', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(
        tester,
        reponse: _entree(max: 3),
      );
      salle.politique.dernierBudget = unBudget(
        visitesUtilisees: 1,
        visitesMax: 3,
        total: const Duration(seconds: 360),
      );
      await _quitter(tester);

      expect(find.text(r.restent(n: 2, duree: '2 minutes')), findsOneWidget);
    });

    testWidgets('duree atteinte : le serveur epuise le budget', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.politique.flux.add(
        unBudget(restant: Duration.zero, peutEntrer: false),
      );
      await _laisserFinir(tester);

      expect(find.text(r.dureeAtteinte), findsOneWidget);
      expect(find.text(r.continuePour(prenom: 'Mariam')), findsOneWidget);
      expect(salle.visites.sorties, <String>['s1']);
    });

    testWidgets('fin de seance : le serveur dit que la seance n\'est plus '
        'active', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.politique.flux.add(
        unBudget(
          restant: const Duration(seconds: 90),
          peutEntrer: false,
          motifRefus: MotifRefusObservation.seanceNonActive,
        ),
      );
      await _laisserFinir(tester);

      expect(
        find.text(t.tc.observation.disponibilite.seanceTermineeTitre),
        findsOneWidget,
      );
      expect(find.text(r.prochaineSeance), findsOneWidget);
      // Aucune visite a « revenir voir » apres la seance.
      expect(
        find.byKey(const ValueKey<String>('resultat-visite-encart')),
        findsNothing,
      );
      expect(salle.visites.sorties, <String>['s1']);
    });

    testWidgets('observation interrompue : reconnexion echouee, l\'intervalle '
        'est referme', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);

      salle.moteur.poser(EtatSalle.echec);
      await _laisserFinir(tester);

      expect(find.text(r.interrompue), findsOneWidget);
      expect(find.text(t.tc.observation.fin.deconnexion), findsOneWidget);
      expect(salle.visites.sorties, <String>['s1']);
      expect(salle.moteur.departs, 1);
    });

    testWidgets('observation retiree par le serveur (desactivee) : '
        'interrompue', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.politique.flux.add(
        unBudget(
          restant: const Duration(seconds: 90),
          peutEntrer: false,
          motifRefus: MotifRefusObservation.policyDesactivee,
        ),
      );
      await _laisserFinir(tester);

      expect(find.text(r.interrompue), findsOneWidget);
      expect(find.text(t.tc.observation.fin.revocationServeur), findsOneWidget);
    });

    testWidgets('visites restantes illisibles : rien n\'est suppose', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);
      salle.politique.echecBudget = const EchecObservation(
        MotifEchecObservation.reseau,
      );
      await _quitter(tester);

      expect(find.text(r.premiereTerminee), findsOneWidget);
      expect(find.text(r.inconnues), findsOneWidget);
      expect(find.textContaining('Il vous reste'), findsNothing);
    });

    testWidgets('relecture en cours : l\'encart attend le serveur', (
      WidgetTester tester,
    ) async {
      final _Salle salle = await _entrerEnSalle(tester);
      final Completer<void> lecture = Completer<void>();
      salle.politique.budgetSuspendu = lecture;
      await _presser(tester, find.text(t.tc.observation.visite.quitter));
      // L'indicateur d'activite tourne tant que la lecture attend : on avance
      // image par image, jamais jusqu'au repos.
      await tester.tap(find.text(t.tc.observation.visite.quitterConfirmer));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(r.verification), findsOneWidget);
      lecture.complete();
      await tester.pumpAndSettle();
      expect(find.text(r.verification), findsNothing);
    });

    testWidgets('sortie non confirmee par le serveur : dit a l\'ecran', (
      WidgetTester tester,
    ) async {
      await _entrerEnSalle(
        tester,
        visites: FauxPortVisite(
          echecSortie: const EchecObservation(MotifEchecObservation.reseau),
        ),
      );
      await _quitter(tester);

      expect(find.text(r.premiereTerminee), findsOneWidget);
      expect(
        find.text(t.tc.observation.visite.sortieNonConfirmee),
        findsOneWidget,
      );
    });

    testWidgets('la visite finie par le serveur pendant la confirmation '
        'referme la question', (WidgetTester tester) async {
      final _Salle salle = await _entrerEnSalle(tester);
      await _presser(tester, find.text(t.tc.observation.visite.quitter));
      expect(find.text(t.tc.observation.visite.quitterQuestion), findsOneWidget);

      salle.politique.flux.add(
        unBudget(restant: Duration.zero, peutEntrer: false),
      );
      await _laisserFinir(tester);

      expect(find.text(t.tc.observation.visite.quitterQuestion), findsNothing);
      expect(find.text(r.dureeAtteinte), findsOneWidget);
      // Une seule fermeture, celle du serveur.
      expect(salle.visites.sorties, <String>['s1']);
    });
  });

  group('Formats et themes', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
        const Size(844, 390),
      ]) {
        testWidgets('fin de visite ${taille.width.toInt()}x'
            '${taille.height.toInt()} ${mode.name} : rien ne deborde, colonne '
            'bornee', (WidgetTester tester) async {
          await _entrerEnSalle(tester, taille: taille, mode: mode);
          await _quitter(tester);
          expect(tester.takeException(), isNull);
          final double largeur = tester
              .getSize(find.byType(ResultatVisite))
              .width;
          expect(largeur, lessThanOrEqualTo(taille.width));
          // Sur ordinateur, une colonne de lecture, jamais la feuille etiree.
          final double action = tester
              .getSize(
                find.ancestor(
                  of: find.text(t.tc.observation.entree.retourClasse),
                  matching: find.byType(ActionPrincipale),
                ),
              )
              .width;
          expect(action, lessThanOrEqualTo(400));
          await _presser(
            tester,
            find.text(t.tc.observation.entree.retourClasse),
          );
          expect(find.text('CLASSE c1 ELEVE enfant-1'), findsOneWidget);
        });
      }
    }

    testWidgets('texte a 200 % a 390 : rien ne deborde, les deux actions '
        'atteignables', (WidgetTester tester) async {
      await _entrerEnSalle(tester, echelleTexte: 2);
      await _quitter(tester);
      expect(tester.takeException(), isNull);
      await _presser(tester, find.text(r.voirObservations));
      expect(find.text('HISTORIQUE OBSERVATIONS enfant-1'), findsOneWidget);
    });
  });
}
