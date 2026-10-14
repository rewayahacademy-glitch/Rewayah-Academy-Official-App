// FORM-L4-11-12 : quatre corrections de formulaires.
//
//   * L4  : la date d'une evaluation se choisit dans un calendrier (fr, de
//           aujourd'hui a un an), elle ne se tape plus en JJ/MM/AAAA ;
//   * L11 : le depot de piece n'a plus de carte « Autre » a champ libre jamais
//           lu ; le type `autre` existe en base (`other`) et se choisit
//           explicitement ;
//   * L12 : le libelle du jeton d'acces agent est prerempli, modifiable ;
//   * L10 : le courriel saisi a la connexion arrive prerempli a la
//           recuperation.
//
// Les cas partent des VRAIS ecrans et de leurs vraies feuilles ; seuls les
// services sont des doubles. Horloge fixe : le 4 octobre 2026.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/selecteur_fichier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_acces_agents/acces_agents_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';
import 'package:rewayah_academy/features/dossier/depot_piece_page.dart';

import '../router/support_routeur.dart';
import '../support/harnais.dart';
import 'support_form_l2.dart';

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Un hote en francais, comme l'application (`app.dart`) : le calendrier lit
/// la langue de l'application.
Widget _hoteFr(Widget ecran, List<Override> surcharges) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: const Locale('fr'),
      supportedLocales: const <Locale>[Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ecran,
    ),
  ),
);

Future<FauxEvaluationsFormL2> _ouvrirPlanification(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FauxEvaluationsFormL2 evaluations = FauxEvaluationsFormL2();
  await tester.pumpWidget(
    _hoteFr(
      const EvaluationsPage(),
      surchargesFormL2(
        comptes: FauxComptesFormL2(comptesFormL2),
        evaluations: evaluations,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.text(t.admin.evaluations.planifier).first);
  return evaluations;
}

void main() {
  group('L11 : le depot de piece n\'a plus de champ libre jamais lu', () {
    Future<(FauxServiceDossier, _SelecteurQuiRetient)> monter(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxServiceDossier dossier = FauxServiceDossier();
      final _SelecteurQuiRetient selecteur = _SelecteurQuiRetient();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attentePiece,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attentePiece,
              builder: (BuildContext _, GoRouterState _) =>
                  const DepotPiecePage(),
            ),
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('portail')),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            selecteurFichierProvider.overrideWithValue(selecteur),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (dossier, selecteur);
    }

    testWidgets('« Autre » est un type explicite : aucune carte a champ libre, '
        'aucun champ texte', (WidgetTester tester) async {
      await monter(tester);

      expect(find.text(t.kyc.autrePiece), findsOneWidget);
      // La carte generique « Autre » (champ libre) a disparu.
      expect(find.text(t.choix.autre), findsNothing);

      await _presser(tester, find.text(t.kyc.autrePiece));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('choisir « Autre pièce » envoie bien le type `other`', (
      WidgetTester tester,
    ) async {
      final (FauxServiceDossier dossier, _SelecteurQuiRetient selecteur) =
          await monter(tester);

      await _presser(tester, find.text(t.kyc.autrePiece));
      await tester.tap(find.text(t.kyc.choisirFichier));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.kyc.envoyer));
      await tester.pumpAndSettle();

      expect(selecteur.demandes, <TypePiece>[TypePiece.autre]);
      expect(dossier.depots.single.type, TypePiece.autre);
      expect(dossier.depots.single.type.valeurSql, 'other');
    });
  });

  group('L10 : le courriel de la connexion arrive a la recuperation', () {
    String champRecuperation(WidgetTester tester) => tester
        .widget<TextField>(
          find.byKey(const ValueKey<String>('recuperation-courriel')),
        )
        .controller!
        .text;

    Future<void> versRecuperation(WidgetTester tester) async {
      final Finder probleme = find.text(t.connexion.probleme);
      await tester.ensureVisible(probleme);
      await tester.pumpAndSettle();
      await tester.tap(probleme);
      await tester.pumpAndSettle();
    }

    testWidgets('l\'adresse deja saisie est pre-remplie (et rognee)', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.connexion,
        source: FausseSourceSession(),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        '  awa@exemple.fr ',
      );
      await tester.pumpAndSettle();

      await versRecuperation(tester);

      expect(lieu(routeur), Routes.connexionRecuperation);
      expect(champRecuperation(tester), 'awa@exemple.fr');
    });

    testWidgets('l\'adresse ne passe pas par l\'URL', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.connexion,
        source: FausseSourceSession(),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('connexion-courriel')),
        'awa@exemple.fr',
      );
      await versRecuperation(tester);

      expect(lieu(routeur), isNot(contains('awa')));
    });

    testWidgets('rien de saisi : le champ de recuperation reste vide', (
      WidgetTester tester,
    ) async {
      await monterRouteur(
        tester,
        Routes.connexion,
        source: FausseSourceSession(),
      );
      await versRecuperation(tester);

      expect(champRecuperation(tester), isEmpty);
    });
  });

  group('L12 : le libelle du jeton d\'acces agent est prerempli', () {
    testWidgets('choisir une personne propose « Observation de <prenom>, le '
        '<date>, <duree> h », et la duree le met a jour', (
      WidgetTester tester,
    ) async {
      await _ouvrirAgents(tester);
      expect(_libelleJeton(tester), isEmpty);

      await _presser(tester, _personne('Maryam Sow'));
      expect(
        _libelleJeton(tester),
        // Duree insecable (DUREE-INSECABLE-3, JONCTION-LIGNES-1).
        LibellesGroupe.insecable('Observation de Maryam, le 04/10/2026, 8 h'),
      );

      await _presser(
        tester,
        find.text(
          LibellesGroupe.valeurSeule(t.admin.agents.dureeHeure(nombre: 4)),
        ),
      );
      expect(
        _libelleJeton(tester),
        // Duree insecable (DUREE-INSECABLE-3, JONCTION-LIGNES-1).
        LibellesGroupe.insecable('Observation de Maryam, le 04/10/2026, 4 h'),
      );

      await _presser(tester, _personne('Yacine Benali'));
      expect(
        _libelleJeton(tester),
        // Duree insecable (DUREE-INSECABLE-3, JONCTION-LIGNES-1).
        LibellesGroupe.insecable('Observation de Yacine, le 04/10/2026, 4 h'),
      );
    });

    testWidgets('un libelle ecrit a la main n\'est jamais ecrase', (
      WidgetTester tester,
    ) async {
      final _AgentsQuiRetient agents = await _ouvrirAgents(tester);
      await _presser(tester, _personne('Maryam Sow'));

      await tester.enterText(
        find.byType(TextField).first,
        'Relecture du suivi',
      );
      await tester.pumpAndSettle();
      await _presser(
        tester,
        find.text(
          LibellesGroupe.valeurSeule(t.admin.agents.dureeHeure(nombre: 1)),
        ),
      );
      await _presser(tester, _personne('Yacine Benali'));
      expect(_libelleJeton(tester), 'Relecture du suivi');

      await _presser(tester, find.text(t.admin.agents.emettre));
      expect(agents.emissions.single.libelle, 'Relecture du suivi');
      expect(agents.emissions.single.profil, 'p-yacine');
      expect(agents.emissions.single.duree, 1);
    });

    testWidgets('emettre envoie le libelle propose, tel quel', (
      WidgetTester tester,
    ) async {
      final _AgentsQuiRetient agents = await _ouvrirAgents(tester);
      await _presser(tester, _personne('Maryam Sow'));
      await _presser(tester, find.text(t.admin.agents.emettre));

      expect(
        agents.emissions.single.libelle,
        // Duree insecable (DUREE-INSECABLE-3, JONCTION-LIGNES-1).
        LibellesGroupe.insecable('Observation de Maryam, le 04/10/2026, 8 h'),
      );
    });

    testWidgets('sans personne, le bouton dit ce qui manque et n\'emet rien', (
      WidgetTester tester,
    ) async {
      final _AgentsQuiRetient agents = await _ouvrirAgents(tester);
      await _presser(tester, find.text(t.admin.agents.emettre));

      expect(find.text(t.admin.agents.manquePersonne), findsOneWidget);
      expect(agents.emissions, isEmpty);
    });
  });

  group('L4 : la date d\'une evaluation se choisit dans un calendrier', () {
    testWidgets('plus aucun champ texte pour la date, un champ a toucher', (
      WidgetTester tester,
    ) async {
      await _ouvrirPlanification(tester);

      expect(
        find.widgetWithText(TextField, t.admin.evaluations.champDatePrevue),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('champ-date')), findsOneWidget);
      expect(find.text(t.commun.champDate.choisir), findsOneWidget);
    });

    testWidgets('le calendrier est en francais, borne d\'aujourd\'hui a +1 an, '
        'et le jour choisi est planifie', (WidgetTester tester) async {
      final FauxEvaluationsFormL2 evaluations = await _ouvrirPlanification(
        tester,
      );
      await _presser(tester, _carte('e-mariam'));
      await _presser(tester, find.text(niveauFormL2.nomHumain));

      await _presser(tester, find.byKey(const ValueKey<String>('champ-date')));

      final CalendarDatePicker calendrier = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendrier.firstDate, DateTime(2026, 10, 4));
      expect(calendrier.lastDate, DateTime(2027, 10, 4));
      // Langue de l'application : le mois s'ecrit en francais.
      expect(find.textContaining('octobre 2026'), findsWidgets);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('15/10/2026'), findsOneWidget);
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));
      expect(evaluations.planifiees.single.$3, DateTime(2026, 10, 15));
    });

    testWidgets('sans date, l\'ecran dit ce qui manque et n\'envoie rien', (
      WidgetTester tester,
    ) async {
      final FauxEvaluationsFormL2 evaluations = await _ouvrirPlanification(
        tester,
      );
      await _presser(tester, _carte('e-mariam'));
      await _presser(tester, find.text(niveauFormL2.nomHumain));
      await _presser(tester, find.text(t.admin.evaluations.planifierEnvoyer));

      expect(find.text(t.admin.evaluations.manqueDate), findsOneWidget);
      expect(evaluations.planifiees, isEmpty);
    });
  });
}

/// Un selecteur qui retient le type de piece qu'on lui demande.
class _SelecteurQuiRetient implements SelecteurFichier {
  final List<TypePiece> demandes = <TypePiece>[];

  @override
  Future<PieceAEnvoyer?> choisirPiece(TypePiece type) async {
    demandes.add(type);
    return PieceAEnvoyer(
      octets: Uint8List(1024),
      nomFichier: 'piece.webp',
      type: type,
    );
  }
}

/// Un service d'agents qui retient les emissions.
class _AgentsQuiRetient implements ServiceAgent {
  final List<({String libelle, String profil, int duree})> emissions =
      <({String libelle, String profil, int duree})>[];

  @override
  Future<List<JetonAgent>> lister() async => const <JetonAgent>[];

  @override
  Future<List<PersonneObservable>> personnes() async =>
      const <PersonneObservable>[
        PersonneObservable(
          id: 'p-maryam',
          identifiant: 'ELV-MS-010',
          prenom: 'Maryam',
          nom: 'Sow',
          role: AppRole.student,
        ),
        PersonneObservable(
          id: 'p-yacine',
          identifiant: 'ENS-YB-002',
          prenom: 'Yacine',
          nom: 'Benali',
          role: AppRole.teacher,
        ),
      ];

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) async {
    emissions.add((
      libelle: libelle,
      profil: profilObserve,
      duree: dureeHeures,
    ));
    return JetonEmis(
      secret: 'secret',
      id: 'j1',
      expireLe: DateTime(2026, 10, 4, 18),
    );
  }

  @override
  Future<bool> revoquer(String id) async => true;
}

Future<_AgentsQuiRetient> _ouvrirAgents(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _AgentsQuiRetient agents = _AgentsQuiRetient();
  await tester.pumpWidget(
    hote(
      const AccesAgentsPage(),
      surcharges: <Override>[
        serviceAgentProvider.overrideWithValue(agents),
        horlogeFormulairesProvider.overrideWithValue(() => aujourdhuiFormL2),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return agents;
}

String _libelleJeton(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

Finder _personne(String libelle) => find.text(libelle);

Finder _carte(String id) => find.byKey(ValueKey<String>('personne-$id'));
