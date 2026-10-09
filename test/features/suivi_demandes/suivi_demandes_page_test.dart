// OFFRES-FAM-1 : le suivi des demandes de creneau, cote famille.
//
// Ce que le test prouve :
// - les quatre etapes de la decision du 09/10 (§4) : phrase de situation,
//   prochaine etape, frise, rappel des jours et de l'heure, debut des cours
//   dans le fuseau du foyer, motif en clair et suite d'une demande close ;
// - la notice du creneau personnalise en attente, et elle seule ;
// - aucune information sur les autres demandeurs (ni nombre, ni identite),
//   aucun nom d'enseignant avant l'etape 3, alors que le serveur simule les
//   connait ;
// - les cinq etats : chargement, contenu, vide, erreur, hors ligne (avec et
//   sans donnees) ; sans port, aucune carte inventee ;
// - la carte d'entree de l'accueil et son lien vers l'ecran ;
// - les notifications de demonstration de chaque transition ;
// - 320 px, texte a 200 %, LTR et RTL : aucun debordement, aucun mot coupe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_demandes/carte_suivi_demandes.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';
import 'package:rewayah_academy/features/suivi_demandes/suivi_demandes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/hors_ligne_une_fois.dart';

/// Un port dont le flux est fourni par le test (chargement, echec).
class _PortFlux implements PortSuiviDemandes {
  _PortFlux(this._flux);

  final Stream<List<SuiviDemande>> Function() _flux;
  int lectures = 0;

  @override
  Stream<List<SuiviDemande>> suivre() {
    lectures++;
    return _flux();
  }
}

DemandeServeurDemo _parId(SuiviDemandesDemo demo, String id) =>
    demo.demandes.firstWhere((DemandeServeurDemo d) => d.demandeId == id);

/// Le suivi reduit a une seule demande de [quatreEtapes].
SuiviDemandesDemo _seule(String id) => SuiviDemandesDemo(<DemandeServeurDemo>[
  _parId(SuiviDemandesDemo.quatreEtapes(), id),
]);

const String _yusuf = 'demo-demande-yusuf';
const String _ines = 'demo-demande-ines';
const String _aicha = 'demo-demande-aicha';
const String _bilal = 'demo-demande-bilal';

Widget _app({
  required Widget home,
  PortSuiviDemandes? port,
  bool horsLigne = false,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) => ProviderScope(
  overrides: <Override>[
    portSuiviDemandesProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext contexte, Widget? app) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(contexte)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: app!,
        ),
      ),
      home: home,
    ),
  ),
);

Future<void> _monter(
  WidgetTester tester, {
  PortSuiviDemandes? port,
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  Widget home = const SuiviDemandesPage(),
}) async {
  tester.view.physicalSize = Size(largeur, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      home: home,
      port: port,
      horsLigne: horsLigne,
      echelle: echelle,
      direction: direction,
    ),
  );
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

/// Tous les textes affiches (Text et RichText des composants).
List<String> _textes(WidgetTester tester) => <String>[
  for (final Widget w in tester.widgetList(find.byType(RichText)))
    (w as RichText).text.toPlainText(),
];

/// Un nombre qui n'est pas une heure « hh:mm » : un compte, un rang, une
/// date. Avant l'etape 3, il n'y en a aucun.
final RegExp _nombreHorsHeure = RegExp(r'(?<![\d:])\d+(?![\d:])');

void _verifierConfidentiel(WidgetTester tester, DemandeServeurDemo serveur) {
  final List<String> textes = _textes(tester);
  expect(textes, isNotEmpty);
  for (final String texte in textes) {
    final String? nom = serveur.enseignant;
    if (nom != null) {
      expect(
        texte.contains(nom),
        isFalse,
        reason: 'nom d enseignant avant l etape 3 : « $texte »',
      );
    }
    expect(
      texte.contains(RegExp('Sayyid', caseSensitive: false)),
      isFalse,
      reason: 'titre d enseignant avant l etape 3 : « $texte »',
    );
    expect(
      _nombreHorsHeure.hasMatch(texte),
      isFalse,
      reason: 'nombre affiche avant l etape 3 : « $texte »',
    );
    expect(
      texte.contains(RegExp(r'autres? (?:élève|famille|demande)s? ont')),
      isFalse,
      reason: 'information sur d autres demandeurs : « $texte »',
    );
  }
}

void main() {
  group('Les quatre etapes', () {
    testWidgets('1. demande envoyee : situation, prochaine etape, rappel', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_yusuf));
      expect(
        find.text('Votre demande est arrivée à l\'administration'),
        findsOneWidget,
      );
      expect(
        find.text('Prochaine étape : constitution de la classe'),
        findsOneWidget,
      );
      expect(find.text('Demande de créneau de Yusuf'), findsOneWidget);
      // Rappel : jours tries (choisis jeudi, lundi, mardi) et heure du foyer.
      expect(find.text('Lundi, mardi et jeudi'), findsOneWidget);
      expect(find.text('18:00, heure de Paris'), findsOneWidget);
      // Frise : une etape faite, la suivante annoncee, la derniere a venir.
      expect(find.text(t.suiviDemandes.etats.fait), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.prochaine), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.aVenir), findsOneWidget);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      await _demonter(tester);
    });

    testWidgets('2. classe validee : affectation de l enseignant a venir', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_ines));
      expect(find.text('Votre classe a été validée'), findsOneWidget);
      expect(
        find.text('Prochaine étape : affectation de l\'enseignant'),
        findsOneWidget,
      );
      expect(find.text(t.suiviDemandes.etats.fait), findsNWidgets(2));
      expect(find.text(t.suiviDemandes.etats.prochaine), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.aVenir), findsNothing);
      expect(find.text('Samedi et dimanche'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('3. enseignant affecte : debut des cours, heure du foyer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_aicha));
      expect(find.text('Classe validée · enseignant affecté'), findsOneWidget);
      expect(find.text(t.suiviDemandes.debutCours), findsOneWidget);
      expect(
        find.text('Lundi 19 octobre à 17:30, heure de Paris'),
        findsOneWidget,
      );
      expect(find.text('Sayyida Maryam'), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.fait), findsNWidgets(3));
      expect(find.text(t.suiviDemandes.etats.prochaine), findsNothing);
      await _demonter(tester);
    });

    testWidgets('3. le fuseau du foyer, jamais celui de l appareil', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo(<DemandeServeurDemo>[
        DemandeServeurDemo(
          demandeId: 'ny',
          eleveId: 'e-ny',
          prenom: 'Adam',
          fuseauIana: 'America/New_York',
          creneau: const CreneauDemande(
            joursIso: <int>[2],
            heure: 19,
            minute: 15,
          ),
          etape: EtapeDemande.enseignantAffecte,
          transitions: <(EtapeDemande, DateTime)>[],
          enseignant: 'Sayyid Ibrahim',
          debutCours: DateTime(2026, 11, 3, 19, 15),
        ),
      ]);
      await _monter(tester, port: demo);
      expect(find.text('19:15, heure de New York'), findsOneWidget);
      expect(
        find.text('Mardi 3 novembre à 19:15, heure de New York'),
        findsOneWidget,
      );
      await _demonter(tester);
    });

    testWidgets('3. date pas encore fixee : la phrase, pas de date inventee', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = _seule(_aicha);
      demo.demandes.first.debutCours = null;
      await _monter(tester, port: demo);
      expect(find.text(t.suiviDemandes.debutAFixer), findsOneWidget);
      expect(find.text(t.suiviDemandes.debutCours), findsNothing);
      await _demonter(tester);
    });

    testWidgets('4. retrait : motif en clair, suite, lien pour rechoisir', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_bilal));
      expect(
        find.text('L\'académie a retiré ce créneau de ses offres.'),
        findsOneWidget,
      );
      expect(find.text(t.suiviDemandes.close.suite), findsOneWidget);
      final StatusPill pastille = tester.widget<StatusPill>(
        find.byType(StatusPill),
      );
      expect(pastille.libelle, 'Demande retirée');
      expect(pastille.ton, TonEtat.avertissement);
      expect(find.text('Choisir un autre créneau pour Bilal'), findsOneWidget);
      // Pas de frise pour une demande close : le motif la remplace.
      expect(find.text(t.suiviDemandes.etats.fait), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      await _demonter(tester);
    });

    testWidgets('4. refus sans capacite de rechoisir : pas de lien grise', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = _seule(_bilal);
      demo.demandes.first
        ..motif = MotifCloture.refusDirection
        ..peutChoisirAutreCreneau = false;
      await _monter(tester, port: demo);
      expect(
        find.text('La direction n\'a pas pu retenir cette demande.'),
        findsOneWidget,
      );
      expect(find.text(t.suiviDemandes.close.suiteSansChoix), findsOneWidget);
      expect(find.byType(LienFleche), findsNothing);
      expect(
        tester.widget<StatusPill>(find.byType(StatusPill)).libelle,
        'Demande non retenue',
      );
      await _demonter(tester);
    });

    testWidgets('une transition arrive : la carte change sans relecture', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = _seule(_yusuf);
      await _monter(tester, port: demo);
      demo.avancer(
        _yusuf,
        EtapeDemande.classeValidee,
        DateTime(2026, 10, 9, 20),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Votre classe a été validée'), findsOneWidget);
      // La notice ne vaut que pour l'attente du quota.
      expect(find.text(t.suiviDemandes.personnaliseNotice), findsNothing);
      await _demonter(tester);
    });

    testWidgets('les demandes closes passent apres les demandes en cours', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo.quatreEtapes();
      demo.demandes.insert(0, demo.demandes.removeAt(3));
      await _monter(tester, port: demo);
      final double bilal = tester
          .getTopLeft(find.byKey(const ValueKey<String>('demande-$_bilal')))
          .dy;
      for (final String id in <String>[_yusuf, _ines, _aicha]) {
        expect(
          tester.getTopLeft(find.byKey(ValueKey<String>('demande-$id'))).dy,
          lessThan(bilal),
        );
      }
      await _demonter(tester);
    });
  });

  group('Creneau personnalise en attente du quota', () {
    testWidgets('la notice, sur la seule demande concernee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: SuiviDemandesDemo.quatreEtapes());
      expect(
        find.text(
          'Ce créneau ne s\'ouvrira que si d\'autres élèves le choisissent '
          'et remplissent la classe.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('demande-notice-$_yusuf')),
        findsOneWidget,
      );
      await _demonter(tester);
    });

    testWidgets('un creneau de la vitrine n a pas de notice', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo(<DemandeServeurDemo>[
        DemandeServeurDemo(
          demandeId: 'vitrine',
          eleveId: 'e-v',
          prenom: 'Sara',
          creneau: const CreneauDemande(
            joursIso: <int>[1],
            heure: 18,
            minute: 0,
          ),
          etape: EtapeDemande.envoyee,
          transitions: <(EtapeDemande, DateTime)>[],
          autresDemandeurs: 2,
        ),
      ]);
      await _monter(tester, port: demo);
      expect(find.text(t.suiviDemandes.personnaliseNotice), findsNothing);
      await _demonter(tester);
    });
  });

  group('Confidentialite : rien sur les autres demandeurs avant l etape 3', () {
    test('le modele efface l enseignant avant l etape 3', () {
      for (final EtapeDemande etape in EtapeDemande.values) {
        final SuiviDemande d = SuiviDemande(
          demandeId: 'd',
          eleveId: 'e',
          prenom: 'P',
          etape: etape,
          creneau: const CreneauDemande(
            joursIso: <int>[1],
            heure: 9,
            minute: 0,
          ),
          fuseauIana: 'Europe/Paris',
          enseignant: 'Sayyida Khadija',
          debutCours: DateTime(2026, 11, 2, 9),
        );
        final bool affecte = etape == EtapeDemande.enseignantAffecte;
        expect(d.enseignant, affecte ? 'Sayyida Khadija' : isNull);
        expect(d.debutCours, affecte ? isNotNull : isNull);
      }
    });

    for (final String id in <String>[_yusuf, _ines, _bilal]) {
      testWidgets('aucun nombre de demandeurs ni nom d enseignant ($id)', (
        WidgetTester tester,
      ) async {
        final SuiviDemandesDemo demo = _seule(id);
        final DemandeServeurDemo serveur = demo.demandes.first;
        // Le serveur simule connait d'autres demandeurs et, a l'etape 2,
        // l'enseignant propose : rien de cela ne doit sortir.
        serveur
          ..autresDemandeurs = 7
          ..enseignant = serveur.enseignant ?? 'Sayyid Harun';
        await _monter(tester, port: demo);
        _verifierConfidentiel(tester, serveur);
        // La carte de l'accueil non plus.
        await _demonter(tester);
        await _monter(tester, port: demo, home: const _Accueil());
        _verifierConfidentiel(tester, serveur);
        await _demonter(tester);
      });
    }

    test('les notifications non plus', () async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo.quatreEtapes();
      for (final NotificationTuteur n in await NotificationsSuiviDemandesDemo(
        demo,
      ).liste()) {
        expect(n.titre, isNot(contains('Sayyid')));
        expect(_nombreHorsHeure.hasMatch(n.titre), isFalse, reason: n.titre);
      }
    });
  });

  group('Les cinq etats', () {
    testWidgets('chargement : le squelette, aucune carte inventee', (
      WidgetTester tester,
    ) async {
      final StreamController<List<SuiviDemande>> jamais =
          StreamController<List<SuiviDemande>>();
      addTearDown(jamais.close);
      await _monter(tester, port: _PortFlux(() => jamais.stream));
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(AppCard), findsNothing);
      await _demonter(tester);
    });

    testWidgets('contenu : une carte par eleve concerne', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: SuiviDemandesDemo.quatreEtapes());
      expect(
        find.byKey(const ValueKey<String>('suivi-demandes-contenu')),
        findsOneWidget,
      );
      for (final String id in <String>[_yusuf, _ines, _aicha, _bilal]) {
        expect(find.byKey(ValueKey<String>('demande-$id')), findsOneWidget);
      }
      expect(find.text(t.suiviDemandes.titre), findsOneWidget);
      expect(find.text(t.suiviDemandes.contexte), findsOneWidget);
      // K-55 : cartes detachees, jamais collees.
      verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard);
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      await _demonter(tester);
    });

    testWidgets('vide : une phrase, pas une page blanche', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: SuiviDemandesDemo(<DemandeServeurDemo>[]));
      expect(
        find.byKey(const ValueKey<String>('suivi-demandes-vide')),
        findsOneWidget,
      );
      expect(find.text(t.suiviDemandes.vide), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('sans port : vide, aucune carte inventee', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.text(t.suiviDemandes.vide), findsOneWidget);
      expect(find.byType(AppCard), findsNothing);
      await _demonter(tester);
    });

    testWidgets('erreur en ligne : ce qui manque, et la relecture', (
      WidgetTester tester,
    ) async {
      final _PortFlux port = _PortFlux(
        () => Stream<List<SuiviDemande>>.error(StateError('serveur')),
      );
      await _monter(tester, port: port);
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byKey(const ValueKey<String>('suivi-demandes-erreur')),
      );
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.text(t.suiviDemandes.erreur), findsOneWidget);
      expect(port.lectures, 1);
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(port.lectures, 2);
      await _demonter(tester);
    });

    testWidgets('hors ligne sans donnees : ce qui manque, une seule fois', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: SuiviDemandesDemo(<DemandeServeurDemo>[], echec: true),
        horsLigne: true,
      );
      expectSansDonnees(t.suiviDemandes.sansDonnees);
      expect(
        tester.widget<EtatSansDonnees>(find.byType(EtatSansDonnees)).onAction,
        isNotNull,
      );
      expect(find.text(t.suiviDemandes.erreur), findsNothing);
      await _demonter(tester);
    });

    testWidgets('hors ligne avec donnees : le bandeau seul, les cartes lues', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: SuiviDemandesDemo.quatreEtapes(),
        horsLigne: true,
      );
      expectAvecDonnees();
      expect(
        find.byKey(const ValueKey<String>('demande-$_yusuf')),
        findsOneWidget,
      );
      await _demonter(tester);
    });
  });

  group('Carte d entree de l accueil', () {
    testWidgets('sans port : rien', (WidgetTester tester) async {
      await _monter(tester, home: const _Accueil());
      expect(find.byType(AppCard), findsNothing);
      await _demonter(tester);
    });

    testWidgets('sans demande : rien', (WidgetTester tester) async {
      await _monter(
        tester,
        port: SuiviDemandesDemo(<DemandeServeurDemo>[]),
        home: const _Accueil(),
      );
      expect(find.byType(AppCard), findsNothing);
      await _demonter(tester);
    });

    testWidgets('une ligne par eleve, et le lien vers le suivi', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: SuiviDemandesDemo.quatreEtapes(),
        home: const _Accueil(),
      );
      expect(find.text(t.suiviDemandes.accueil.titre), findsOneWidget);
      expect(find.text('Yusuf : Demande envoyée'), findsOneWidget);
      expect(find.text('Inès : Classe validée'), findsOneWidget);
      expect(find.text('Aïcha : Enseignant affecté'), findsOneWidget);
      expect(find.text('Bilal : Demande retirée'), findsOneWidget);
      expect(find.text(t.suiviDemandes.accueil.voir), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('en echec : ce qui manque, et le lien reste', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: SuiviDemandesDemo(<DemandeServeurDemo>[], echec: true),
        home: const _Accueil(),
      );
      expect(find.text(t.suiviDemandes.sansDonnees), findsOneWidget);
      expect(find.text(t.suiviDemandes.accueil.voir), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('le lien mene a l ecran de suivi', (WidgetTester tester) async {
      final GoRouter routeur = GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext _, GoRouterState _) => const _Accueil(),
          ),
          GoRoute(
            path: Routes.tuteurDemandes,
            builder: (BuildContext _, GoRouterState _) =>
                const SuiviDemandesPage(),
          ),
        ],
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            portSuiviDemandesProvider.overrideWithValue(
              SuiviDemandesDemo.demonstration(),
            ),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text(t.suiviDemandes.accueil.voir));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SuiviDemandesPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('demande-demo-demande-aicha')),
        findsOneWidget,
      );
      await _demonter(tester);
    });
  });

  group('Notifications de chaque transition (demonstration)', () {
    test(
      'une par etape atteinte, la plus recente d abord, vers le suivi',
      () async {
        final List<NotificationTuteur> liste =
            await NotificationsSuiviDemandesDemo(
              SuiviDemandesDemo.quatreEtapes(),
            ).liste();
        final List<String> titres = <String>[
          for (final NotificationTuteur n in liste) n.titre,
        ];
        expect(
          titres,
          containsAll(<String>[
            'Demande de créneau de Yusuf : votre demande est arrivée à '
                'l\'administration',
            'Demande de créneau d\'Inès : votre classe a été validée',
            'Demande de créneau d\'Aïcha : classe validée · enseignant affecté',
            'Demande de créneau de Bilal : l\'académie a retiré ce créneau de '
                'ses offres.',
          ]),
        );
        // Aicha : trois transitions ; Ines : deux ; Bilal : deux ; Yusuf : une.
        expect(liste, hasLength(8));
        for (int i = 1; i < liste.length; i++) {
          expect(liste[i - 1].date.isBefore(liste[i].date), isFalse);
        }
        for (final NotificationTuteur n in liste) {
          expect(n.destination, Routes.tuteurDemandes);
        }
      },
    );

    test('une transition simulee ajoute sa notification', () async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo.demonstration();
      final NotificationsSuiviDemandesDemo port =
          NotificationsSuiviDemandesDemo(demo);
      final int avant = (await port.liste()).length;
      demo.avancer(
        'demo-demande-yusuf',
        EtapeDemande.classeValidee,
        DateTime(2026, 10, 10, 9),
      );
      final List<NotificationTuteur> apres = await port.liste();
      expect(apres, hasLength(avant + 1));
      expect(
        apres.first.titre,
        'Demande de créneau de Yusuf : votre classe a été validée',
      );
      expect(await port.detail(apres.first.id), isNotNull);
    });

    test('libelles : jours tries et dedoublonnes, fuseau en ville', () {
      expect(joursDemande(<int>[4, 1, 2, 1]), 'Lundi, mardi et jeudi');
      expect(joursDemande(<int>[7]), 'Dimanche');
      expect(villeDuFuseau('America/Los_Angeles'), 'Los Angeles');
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('aucun debordement ni mot coupe (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: SuiviDemandesDemo.quatreEtapes(),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        for (final String id in <String>[_yusuf, _ines, _aicha, _bilal]) {
          expect(find.byKey(ValueKey<String>('demande-$id')), findsOneWidget);
        }
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        verifierAucuneCarteCollee(tester, estCarte: (Widget w) => w is AppCard);
        await _demonter(tester);
      });

      testWidgets('carte de l accueil (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: SuiviDemandesDemo.quatreEtapes(),
          largeur: 320,
          echelle: 2,
          direction: direction,
          home: const _Accueil(),
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await _demonter(tester);
      });
    }
  });
}

/// La carte de l'accueil, posee seule sur un ecran.
class _Accueil extends StatelessWidget {
  const _Accueil();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: CarteSuiviDemandes(),
    ),
  );
}
