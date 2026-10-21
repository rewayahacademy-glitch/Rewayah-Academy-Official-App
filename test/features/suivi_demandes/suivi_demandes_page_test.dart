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
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
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

/// Un nombre qui n'est pas une heure « hh:mm » ni le jour d'une date
/// (« 8 octobre ») : un compte, un rang. Avant l'etape 3, il n'y en a aucun.
/// Les dates des etapes franchies sont voulues (R20) : un jour du mois n'est
/// pas un nombre de demandeurs.
final RegExp _nombreHorsHeure = RegExp(r'(?<![\d:])\d+(?![\d:])');

/// « 8 octobre » : le jour d'une date, et « 4 jours plus tard » : le temps
/// ecoule entre deux etapes (R20). Retires avant la recherche d'un nombre : ni
/// l'un ni l'autre ne compte des demandeurs.
final RegExp _jourDeDate = RegExp(
  r'\d{1,2}(?=[\s\u00a0]+(?:janvier|f[ée]vrier|mars|avril|mai|juin|juillet|'
  r'ao[uû]t|septembre|octobre|novembre|d[ée]cembre))|'
  r'\d+(?=[\s\u00a0]+(?:minutes?|heures?|jours?)[\s\u00a0]+plus tard)',
);

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
      _nombreHorsHeure.hasMatch(texte.replaceAll(_jourDeDate, '')),
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
        find.text('Prochaine étape\u00a0: constitution de la classe'),
        findsOneWidget,
      );
      expect(find.text('Demande de créneau de Yusuf'), findsOneWidget);
      // Rappel : jours tries (choisis jeudi, lundi, mardi) et heure du foyer.
      expect(find.text('Lundi, mardi et jeudi'), findsOneWidget);
      expect(find.text('18:00, heure de Paris'), findsOneWidget);
      // Frise (R20) : une etape faite, la suivante annoncee, les trois
      // dernieres a venir.
      expect(find.text(t.suiviDemandes.etats.fait), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.prochaine), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.aVenir), findsNWidgets(3));
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      await _demonter(tester);
    });

    testWidgets('2. classe validee : affectation de l enseignant a venir', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_ines));
      // R7 : la classe est prete, elle attend son enseignant, sans delai
      // annonce.
      expect(
        find.text(t.suiviDemandes.situation.classeValidee),
        findsOneWidget,
      );
      expect(
        find.text(t.suiviDemandes.prochaine.classeValidee),
        findsOneWidget,
      );
      expect(find.text(t.suiviDemandes.etats.fait), findsNWidgets(2));
      expect(find.text(t.suiviDemandes.etats.prochaine), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.aVenir), findsNWidgets(2));
      // C-10 bis : chaque jour avec son heure, le fuseau sur sa ligne.
      expect(find.text('Samedi 10:00, dimanche 11:30'), findsOneWidget);
      expect(find.text('Heure de Paris'), findsOneWidget);
      expect(find.text(t.suiviDemandes.heureChoisie), findsNothing);
      await _demonter(tester);
    });

    testWidgets('3. enseignant affecte : debut des cours, heure du foyer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _seule(_aicha));
      expect(find.text('Classe validée · enseignant affecté'), findsOneWidget);
      // « Debut des cours » : la derniere etape de la frise et la ligne de
      // la date.
      expect(find.text(t.suiviDemandes.debutCours), findsNWidgets(2));
      expect(
        find.text('Lundi 19 octobre à 17:30, heure de Paris'),
        findsOneWidget,
      );
      expect(find.text('Sayyida Maryam'), findsOneWidget);
      expect(find.text(t.suiviDemandes.etats.fait), findsNWidgets(3));
      // R20 : apres l'enseignant, l'eleve est integre.
      expect(find.text(t.suiviDemandes.etats.prochaine), findsOneWidget);
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
          creneau: CreneauDemande(
            occurrences: const <OccurrenceCreneau>[
              OccurrenceCreneau(jourIso: 2, heure: 19, minute: 15),
            ],
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
      // Aucune ligne de date : seule reste l'etape de la frise.
      expect(
        find.byKey(const ValueKey<String>('demande-debut-$_aicha')),
        findsNothing,
      );
      expect(find.text(t.suiviDemandes.debutCours), findsOneWidget);
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
      expect(
        find.text(t.suiviDemandes.situation.classeValidee),
        findsOneWidget,
      );
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
          creneau: CreneauDemande(
            occurrences: const <OccurrenceCreneau>[
              OccurrenceCreneau(jourIso: 1, heure: 18, minute: 0),
            ],
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
          creneau: CreneauDemande(
            occurrences: const <OccurrenceCreneau>[
              OccurrenceCreneau(jourIso: 1, heure: 9, minute: 0),
            ],
          ),
          fuseauIana: 'Europe/Paris',
          enseignant: 'Sayyida Khadija',
          debutCours: DateTime(2026, 11, 2, 9),
        );
        final bool affecte = etape.enseignantConnu;
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
      expect(find.text('Yusuf\u00a0: Demande envoyée'), findsOneWidget);
      expect(find.text('Inès\u00a0: Classe validée'), findsOneWidget);
      expect(find.text('Aïcha\u00a0: Enseignant affecté'), findsOneWidget);
      expect(find.text('Bilal\u00a0: Demande retirée'), findsOneWidget);
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
            'Demande de créneau de Yusuf\u00a0: votre demande est arrivée à '
                'l\'administration',
            'Demande de créneau d\'Inès\u00a0: votre classe est prête, elle '
                'attend son enseignant',
            'Demande de créneau d\'Aïcha\u00a0: classe validée · enseignant affecté',
            'Demande de créneau de Bilal\u00a0: l\'académie a retiré ce créneau de '
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
        'Demande de créneau de Yusuf\u00a0: votre classe est prête, elle '
        'attend son enseignant',
      );
      expect(await port.detail(apres.first.id), isNotNull);
    });

    test('libelles : jours tries et dedoublonnes, fuseau en ville', () {
      expect(joursDemande(<int>[4, 1, 2, 1]), 'Lundi, mardi et jeudi');
      expect(joursDemande(<int>[7]), 'Dimanche');
      expect(villeDuFuseauLibelle('America/Los_Angeles'), 'Los Angeles');
    });
  });

  group('Reserves de la verification (OFFRES-1B)', () {
    SuiviDemande demande({
      EtapeDemande etape = EtapeDemande.enseignantAffecte,
      String fuseau = 'Europe/Paris',
      DateTime? debut,
      MotifCloture? motif,
    }) => SuiviDemande(
      demandeId: 'd',
      eleveId: 'e',
      prenom: 'Bilal',
      etape: etape,
      creneau: CreneauDemande(
        occurrences: const <OccurrenceCreneau>[
          OccurrenceCreneau(jourIso: 1, heure: 18),
        ],
      ),
      fuseauIana: fuseau,
      debutCours: debut,
      motif: motif,
    );

    test('FAM 1 : un debut des cours en UTC est refuse au constructeur', () {
      expect(
        () => demande(debut: DateTime.utc(2026, 10, 19, 17, 30)),
        throwsA(isA<AssertionError>()),
      );
      // L'heure murale du foyer passe telle quelle.
      expect(
        demande(debut: DateTime(2026, 10, 19, 17, 30)).debutCours,
        DateTime(2026, 10, 19, 17, 30),
      );
    });

    test('FAM 1 : en production, un instant UTC n affiche aucune heure', () {
      // Les assertions sont coupees en production : le repli ecarte
      // l'instant UTC plutot que de l'afficher comme heure du foyer.
      expect(heureMuraleDuFoyer(DateTime.utc(2026, 10, 19, 17, 30)), isNull);
      expect(heureMuraleDuFoyer(null), isNull);
      expect(
        heureMuraleDuFoyer(DateTime(2026, 10, 19, 17, 30)),
        DateTime(2026, 10, 19, 17, 30),
      );
    });

    testWidgets('FAM 2 : motif absent, phrase neutre et suite selon la '
        'capacite', (WidgetTester tester) async {
      for (final bool peut in <bool>[true, false]) {
        final SuiviDemandesDemo demo = _seule(_bilal);
        demo.demandes.first
          ..motif = null
          ..peutChoisirAutreCreneau = peut;
        await _monter(tester, port: demo);
        expect(find.text('Cette demande est close.'), findsOneWidget);
        // Ni refus ni retrait suppose.
        expect(
          find.text('La direction n\'a pas pu retenir cette demande.'),
          findsNothing,
        );
        expect(find.text('Vous avez retiré cette demande.'), findsNothing);
        expect(
          tester.widget<StatusPill>(find.byType(StatusPill)).libelle,
          'Demande close',
        );
        expect(
          find.text(
            peut
                ? t.suiviDemandes.close.suite
                : t.suiviDemandes.close.suiteSansChoix,
          ),
          findsOneWidget,
        );
        expect(find.byType(LienFleche), peut ? findsOneWidget : findsNothing);
        await _demonter(tester);
      }
    });

    test('FAM 2 : le modele et la notification restent neutres', () {
      final SuiviDemande d = demande(etape: EtapeDemande.close);
      expect(d.motif, MotifCloture.inconnu);
      expect(etatCourtDemande(d), 'Demande close');
      expect(
        titreNotificationDemande(d),
        'Demande de créneau de Bilal\u00a0: cette demande est close.',
      );
    });

    test('FAM 3 : fuseau universel, « heure UTC », jamais « heure d UTC »', () {
      for (final String fuseau in <String>['Etc/UTC', 'UTC']) {
        final SuiviDemande d = demande(
          fuseau: fuseau,
          debut: DateTime(2026, 10, 19, 17, 30),
        );
        expect(heureDemande(d), '18:00, heure UTC');
        expect(debutCoursDemande(d), 'Lundi 19 octobre à 17:30, heure UTC');
      }
      // Une ville garde son « de ».
      expect(heureDemande(demande()), '18:00, heure de Paris');
    });
  });

  group('C-10 bis : une heure par jour', () {
    setUpAll(chargerPolicesDuDepot);

    CreneauDemande creneau(List<(int, int, int)> occurrences) => CreneauDemande(
      occurrences: <OccurrenceCreneau>[
        for (final (int j, int h, int m) in occurrences)
          OccurrenceCreneau(jourIso: j, heure: h, minute: m),
      ],
    );

    SuiviDemande demande(CreneauDemande c, {String fuseau = 'Europe/Paris'}) =>
        SuiviDemande(
          demandeId: 'c10',
          eleveId: 'e-c10',
          prenom: 'Sara',
          etape: EtapeDemande.envoyee,
          creneau: c,
          fuseauIana: fuseau,
        );

    SuiviDemandesDemo seule(CreneauDemande c) =>
        SuiviDemandesDemo(<DemandeServeurDemo>[
          DemandeServeurDemo(
            demandeId: 'c10',
            eleveId: 'e-c10',
            prenom: 'Sara',
            creneau: c,
            etape: EtapeDemande.envoyee,
            transitions: <(EtapeDemande, DateTime)>[],
          ),
        ]);

    test('le creneau trie par jour et garde l heure de chaque jour', () {
      // Choisis mercredi 19:30 puis lundi 18:00.
      final CreneauDemande c = creneau(<(int, int, int)>[
        (3, 19, 30),
        (1, 18, 0),
      ]);
      expect(c.occurrences, const <OccurrenceCreneau>[
        OccurrenceCreneau(jourIso: 1, heure: 18),
        OccurrenceCreneau(jourIso: 3, heure: 19, minute: 30),
      ]);
      expect(c.joursIso, <int>[1, 3]);
      expect(c.heuresToutesEgales, isFalse);
      expect(
        creneau(<(int, int, int)>[(4, 18, 0), (1, 18, 0)]).heuresToutesEgales,
        isTrue,
      );
      // La liste rendue ne se modifie pas.
      expect(
        () => c.occurrences.add(const OccurrenceCreneau(jourIso: 5, heure: 9)),
        throwsUnsupportedError,
      );
    });

    test('doublon de jour, liste vide, valeurs hors bornes : refuses', () {
      expect(
        () => creneau(<(int, int, int)>[(1, 18, 0), (1, 19, 0)]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CreneauDemande(occurrences: const <OccurrenceCreneau>[]),
        throwsA(isA<AssertionError>()),
      );
      for (final (int j, int h, int m) in <(int, int, int)>[
        (0, 18, 0),
        (8, 18, 0),
        (1, -1, 0),
        (1, 24, 0),
        (1, 18, -1),
        (1, 18, 60),
      ]) {
        expect(
          () => OccurrenceCreneau(jourIso: j, heure: h, minute: m),
          throwsA(isA<AssertionError>()),
          reason: '($j, $h, $m)',
        );
      }
    });

    test('libelles : heure commune une fois, sinon chaque jour la sienne', () {
      final SuiviDemande egales = demande(
        creneau(<(int, int, int)>[(4, 18, 0), (1, 18, 0), (2, 18, 0)]),
      );
      expect(joursDemande(egales.creneau.joursIso), 'Lundi, mardi et jeudi');
      expect(heureDemande(egales), '18:00, heure de Paris');

      final SuiviDemande differentes = demande(
        creneau(<(int, int, int)>[(3, 19, 30), (1, 18, 0)]),
      );
      // Jamais l'heure du premier jour prise pour celle des autres.
      expect(heureDemande(differentes), isNull);
      expect(
        joursEtHeuresDemande(differentes.creneau),
        'Lundi 18:00, mercredi 19:30',
      );
      expect(fuseauDemande(differentes), 'Heure de Paris');
      expect(
        fuseauDemande(demande(differentes.creneau, fuseau: 'Etc/UTC')),
        'Heure UTC',
      );
    });

    testWidgets('heures egales : la phrase actuelle, inchangee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: seule(
          creneau(<(int, int, int)>[(4, 18, 0), (1, 18, 0), (2, 18, 0)]),
        ),
      );
      expect(find.text(t.suiviDemandes.joursChoisis), findsOneWidget);
      expect(find.text('Lundi, mardi et jeudi'), findsOneWidget);
      expect(find.text(t.suiviDemandes.heureChoisie), findsOneWidget);
      expect(find.text('18:00, heure de Paris'), findsOneWidget);
      expect(find.text(t.suiviDemandes.creneauxChoisis), findsNothing);
      await _demonter(tester);
    });

    testWidgets('heures differentes : chaque jour avec son heure, dans l ordre '
        'de la semaine', (WidgetTester tester) async {
      await _monter(
        tester,
        port: seule(creneau(<(int, int, int)>[(3, 19, 30), (1, 18, 0)])),
      );
      expect(find.text(t.suiviDemandes.creneauxChoisis), findsOneWidget);
      expect(find.text('Lundi 18:00, mercredi 19:30'), findsOneWidget);
      expect(find.text(t.suiviDemandes.fuseauChoisi), findsOneWidget);
      expect(find.text('Heure de Paris'), findsOneWidget);
      // Ni l'ancienne ligne d'heure unique, ni une heure ecrasee.
      expect(find.text(t.suiviDemandes.heureChoisie), findsNothing);
      expect(find.text('18:00, heure de Paris'), findsNothing);
      expect(find.text('Lundi et mercredi'), findsNothing);
      await _demonter(tester);
    });

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('320 px, texte a 200 %, sept jours a heures differentes '
          '(${direction.name})', (WidgetTester tester) async {
        await _monter(
          tester,
          port: seule(
            creneau(<(int, int, int)>[
              for (int j = 1; j <= 7; j++) (j, 10 + j, j.isEven ? 30 : 0),
            ]),
          ),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey<String>('demande-jours-heures-c10')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Lundi 11:00, mardi 12:30, mercredi 13:00, jeudi 14:30, '
            'vendredi 15:00, samedi 16:30, dimanche 17:00',
          ),
          findsOneWidget,
        );
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        await _demonter(tester);
      });
    }
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
