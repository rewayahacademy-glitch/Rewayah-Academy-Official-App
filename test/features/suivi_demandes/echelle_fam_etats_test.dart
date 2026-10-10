// ECHELLE-FAM-ETATS-1 : cote famille, les etats « classe prete, en attente
// d'enseignant » et « en liste d'attente », la frise datee (R20), et le
// resultat d'une fusion ou d'un transfert (R7, R9, R10, R11,
// DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// Ce que le test prouve :
// - la liste d'attente se dit sans rang ni delai ; la classe prete dit
//   qu'elle attend son enseignant, sans delai ni nom propose ;
// - la frise (demande envoyee, liste d'attente, classe validee, enseignant
//   affecte, eleve integre, debut des cours) date chaque etape franchie, dit
//   le temps ecoule depuis la precedente, met l'etape en cours en avant, et
//   n'invente aucune date ;
// - l'ecran de resultat d'un changement de classe : nouvelle classe, titre de
//   l'enseignant, horaire dans le fuseau du foyer, date ; jamais le nombre de
//   classes paralleles ni d'autres eleves ;
// - fratrie (R4 corrigee) : chaque enfant a son suivi, aucun message ne dit
//   qu'ils sont ensemble ou separes ;
// - les notifications d'un changement ;
// - les 5 etats de l'ecran de resultat, 320 px texte x2, RTL.
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
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_demandes/changement_classe_page.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';
import 'package:rewayah_academy/features/suivi_demandes/suivi_demandes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

const String _yusuf = 'demo-demande-yusuf';
const String _ines = 'demo-demande-ines';
const String _aicha = 'demo-demande-aicha';
const String _bilal = 'demo-demande-bilal';

class _PortFlux implements PortSuiviDemandes {
  _PortFlux(this._flux);

  final Stream<List<SuiviDemande>> Function() _flux;

  @override
  Stream<List<SuiviDemande>> suivre() => _flux();
}

CreneauDemande _lundi18() => CreneauDemande(
  occurrences: const <OccurrenceCreneau>[
    OccurrenceCreneau(jourIso: 1, heure: 18),
  ],
);

SuiviDemande _demande({
  EtapeDemande etape = EtapeDemande.envoyee,
  Map<EtapeDemande, DateTime> jalons = const <EtapeDemande, DateTime>{},
  ChangementClasse? changement,
  String? enseignant,
  DateTime? debutCours,
}) => SuiviDemande(
  demandeId: 'd',
  eleveId: 'e',
  prenom: 'Adam',
  etape: etape,
  creneau: _lundi18(),
  fuseauIana: 'Europe/Paris',
  enseignant: enseignant,
  debutCours: debutCours,
  jalons: jalons,
  changement: changement,
);

Widget _app({
  required Widget home,
  PortSuiviDemandes? port,
  bool horsLigne = false,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  RouterConfig<Object>? routeur,
}) => ProviderScope(
  overrides: <Override>[
    portSuiviDemandesProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  ],
  child: TranslationProvider(
    child: routeur != null
        ? MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          )
        : MaterialApp(
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
  Widget home = const SuiviDemandesPage(),
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 5000);
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

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Tous les textes affiches.
List<String> _textes(WidgetTester tester) => <String>[
  for (final Widget w in tester.widgetList(find.byType(RichText)))
    (w as RichText).text.toPlainText(),
];

/// Les textes d'une carte de demande.
List<String> _textesDe(WidgetTester tester, Finder racine) => <String>[
  for (final Widget w in tester.widgetList(
    find.descendant(of: racine, matching: find.byType(RichText)),
  ))
    (w as RichText).text.toPlainText(),
];

/// « 8 octobre » (le jour d'une date) et « 4 jours plus tard » : voulus par
/// R20, ils ne comptent ni demandeurs ni classes.
final RegExp _datesEtDurees = RegExp(
  r'\d{1,2}(?=[\s ]+(?:janvier|f[ée]vrier|mars|avril|mai|juin|juillet|'
  r'ao[uû]t|septembre|octobre|novembre|d[ée]cembre))|'
  r'\d+(?=[\s ]+(?:minutes?|heures?|jours?)[\s ]+plus tard)',
);
final RegExp _nombreHorsHeure = RegExp(r'(?<![\d:])\d+(?![\d:])');

SuiviDemandesDemo _echelle() => SuiviDemandesDemo.echelle();

void main() {
  group('Le modele', () {
    test(
      'l enseignant et la date de debut se disent des qu il est affecte',
      () {
        for (final EtapeDemande etape in EtapeDemande.values) {
          final SuiviDemande d = _demande(
            etape: etape,
            enseignant: 'Sayyida Khadija',
            debutCours: DateTime(2026, 11, 2, 18),
          );
          final bool connu = const <EtapeDemande>{
            EtapeDemande.enseignantAffecte,
            EtapeDemande.eleveIntegre,
            EtapeDemande.coursCommences,
          }.contains(etape);
          expect(etape.enseignantConnu, connu);
          expect(
            d.enseignant,
            connu ? 'Sayyida Khadija' : isNull,
            reason: '$etape',
          );
          expect(d.debutCours, connu ? isNotNull : isNull, reason: '$etape');
        }
      },
    );

    test('un jalon en UTC est ecarte : aucune heure fausse', () {
      final SuiviDemande d = _demande(
        etape: EtapeDemande.classeValidee,
        jalons: <EtapeDemande, DateTime>{
          EtapeDemande.envoyee: DateTime(2026, 10, 1, 9),
          EtapeDemande.classeValidee: DateTime.utc(2026, 10, 3, 9),
        },
      );
      expect(d.jalons.keys, <EtapeDemande>[EtapeDemande.envoyee]);
      expect(libelleJalon(DateTime.utc(2026, 10, 3, 9)), isNull);
    });

    test('un changement en UTC est refuse au constructeur', () {
      expect(
        () => ChangementClasse(
          type: TypeChangementClasse.fusion,
          quand: DateTime.utc(2026, 10, 9, 18),
          classe: 'Garçons',
          creneau: _lundi18(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('le rang de la frise : la liste d attente n est pas une etape en '
        'plus', () {
      expect(EtapeDemande.envoyee.rang, EtapeDemande.listeAttente.rang);
      expect(EtapeDemande.close.rang, 0);
      expect(
        <int>[for (final EtapeDemande e in EtapeDemande.values) e.rang]..sort(),
        <int>[0, 1, 1, 2, 3, 4, 5],
      );
    });
  });

  group('Les libelles de la frise', () {
    test('le temps ecoule se dit dans l unite la plus grande', () {
      expect(intervalleDemande(const Duration(seconds: 30)), 'aussitôt');
      expect(
        intervalleDemande(const Duration(minutes: 1)),
        '1 minute plus tard',
      );
      expect(
        intervalleDemande(const Duration(minutes: 12)),
        '12 minutes plus tard',
      );
      expect(
        intervalleDemande(const Duration(hours: 1, minutes: 5)),
        '1 heure plus tard',
      );
      expect(intervalleDemande(const Duration(hours: 3)), '3 heures plus tard');
      expect(
        intervalleDemande(const Duration(days: 1, hours: 20)),
        '1 jour plus tard',
      );
      expect(intervalleDemande(const Duration(days: 4)), '4 jours plus tard');
      // Deux dates dans le desordre : aucun intervalle n'est invente.
      expect(intervalleDemande(const Duration(days: -1)), isNull);
    });

    test('une etape franchie porte sa date et le temps ecoule', () {
      final DateTime premiere = DateTime(2026, 9, 30, 18, 2);
      final DateTime seconde = DateTime(2026, 10, 4, 10);
      expect(libelleJalon(premiere), 'Mercredi 30 septembre à 18:02');
      expect(
        libelleJalon(seconde, precedent: premiere),
        'Dimanche 4 octobre à 10:00, 3 jours plus tard',
      );
      expect(libelleJalon(null), isNull);
    });
  });

  group('Les etats, un suivi par enfant', () {
    testWidgets('liste d attente : ni rang, ni delai, ni autres familles', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _echelle());
      final Finder carte = _cle('demande-$_yusuf');
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.suiviDemandes.situation.listeAttente),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.suiviDemandes.prochaine.listeAttente),
        ),
        findsOneWidget,
      );
      // L'etape de l'attente est en cours, mise en avant.
      expect(
        find.descendant(
          of: _cle('demande-etape-$_yusuf-listeAttente'),
          matching: find.text(t.suiviDemandes.etats.enCours),
        ),
        findsOneWidget,
      );
      for (final String texte in _textesDe(tester, carte)) {
        final String nu = texte.replaceAll(_datesEtDurees, '');
        expect(
          _nombreHorsHeure.hasMatch(nu),
          isFalse,
          reason: 'un nombre dans la liste d attente : « $texte »',
        );
        expect(
          texte.toLowerCase(),
          isNot(matches(r'rang|position|file d|dans \d|délai|sous \d')),
          reason: texte,
        );
      }
      await _demonter(tester);
    });

    testWidgets('classe prete : elle attend son enseignant, sans delai ni '
        'nom', (WidgetTester tester) async {
      await _monter(tester, port: _echelle());
      final Finder carte = _cle('demande-$_ines');
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.suiviDemandes.situation.classeValidee),
        ),
        findsOneWidget,
      );
      final List<String> textes = _textesDe(tester, carte);
      // Le serveur simule propose « Sayyida Khadija » : jamais rendu.
      expect(textes.any((String x) => x.contains('Khadija')), isFalse);
      expect(textes.any((String x) => x.contains('Sayyida')), isFalse);
      // Aucune date de debut annoncee.
      expect(_cle('demande-debut-$_ines'), findsNothing);
      await _demonter(tester);
    });

    testWidgets('eleve integre : chaque etape franchie a sa date et son temps '
        'ecoule', (WidgetTester tester) async {
      await _monter(tester, port: _echelle());
      for (final String etape in <String>[
        'envoyee',
        'classeValidee',
        'enseignantAffecte',
        'eleveIntegre',
      ]) {
        final Finder ligne = _cle('demande-etape-$_aicha-$etape');
        expect(ligne, findsOneWidget, reason: etape);
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(t.suiviDemandes.etats.fait),
          ),
          findsOneWidget,
        );
      }
      final List<String> envoyee = _textesDe(
        tester,
        _cle('demande-etape-$_aicha-envoyee'),
      );
      expect(envoyee, contains('Mercredi 30 septembre à 18:02'));
      final List<String> validee = _textesDe(
        tester,
        _cle('demande-etape-$_aicha-classeValidee'),
      );
      expect(
        validee.any((String x) => x.contains('plus tard')),
        isTrue,
        reason: validee.toString(),
      );
      // La derniere etape est annoncee, sans date inventee : la date de
      // debut est celle que le serveur rend.
      final Finder debut = _cle('demande-etape-$_aicha-coursCommences');
      expect(
        find.descendant(
          of: debut,
          matching: find.text(t.suiviDemandes.etats.prochaine),
        ),
        findsOneWidget,
      );
      expect(_cle('demande-debut-$_aicha'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('sans date rendue par le serveur : aucune date inventee', (
      WidgetTester tester,
    ) async {
      final SuiviDemandesDemo demo = SuiviDemandesDemo(<DemandeServeurDemo>[
        DemandeServeurDemo(
          demandeId: 'sans-dates',
          eleveId: 'e',
          prenom: 'Adam',
          creneau: _lundi18(),
          etape: EtapeDemande.classeValidee,
          transitions: <(EtapeDemande, DateTime)>[],
        ),
      ]);
      await _monter(tester, port: demo);
      for (final String texte in _textesDe(
        tester,
        _cle('demande-sans-dates'),
      )) {
        expect(texte, isNot(contains('plus tard')));
        expect(texte, isNot(contains('septembre')));
        expect(texte, isNot(contains('octobre')));
      }
      await _demonter(tester);
    });

    testWidgets('cours commences : toutes les etapes sont faites', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _echelle());
      final Finder carte = _cle('demande-$_bilal');
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.suiviDemandes.etats.fait),
        ),
        findsNWidgets(5),
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.suiviDemandes.debutAFixer),
        ),
        findsNothing,
      );
      await _demonter(tester);
    });

    testWidgets('fratrie : un suivi par enfant, rien sur « ensemble » ou '
        '« separes »', (WidgetTester tester) async {
      await _monter(tester, port: _echelle());
      for (final String id in <String>[_yusuf, _ines, _aicha, _bilal]) {
        expect(_cle('demande-$id'), findsOneWidget, reason: id);
      }
      // Quatre etats differents pour quatre enfants du meme foyer.
      final Set<String> situations = <String>{
        for (final String id in <String>[_yusuf, _ines, _aicha, _bilal])
          ..._textesDe(tester, _cle('demande-$id')).where(
            (String x) =>
                x == t.suiviDemandes.situation.listeAttente ||
                x == t.suiviDemandes.situation.classeValidee ||
                x == t.suiviDemandes.situation.eleveIntegre ||
                x == t.suiviDemandes.situation.coursCommences,
          ),
      };
      expect(situations, hasLength(4));
      final String tout = _textes(tester).join(' | ').toLowerCase();
      for (final String mot in <String>[
        'ensemble',
        'séparé',
        'separe',
        'frère',
        'frere',
        'sœur',
        'soeur',
        'fratrie',
        'même classe',
        'même groupe',
      ]) {
        expect(tout, isNot(contains(mot)), reason: mot);
      }
      // Jamais le nombre de classes paralleles ni d'autres eleves.
      expect(tout, isNot(contains('parallèle')));
      expect(tout, isNot(contains('autres élèves')));
      expect(tout, isNot(contains('autres familles')));
      await _demonter(tester);
    });
  });

  group('Le changement de classe', () {
    testWidgets('la carte le dit et mene a l ecran de resultat', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: Routes.tuteurDemandes,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.tuteurDemandes,
            builder: (BuildContext _, GoRouterState _) =>
                const SuiviDemandesPage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':demandeId/changement',
                builder: (BuildContext _, GoRouterState etat) =>
                    ChangementClassePage(
                      demandeId: etat.pathParameters['demandeId']!,
                    ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _app(home: const SizedBox(), port: _echelle(), routeur: routeur),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_cle('demande-changement-$_aicha'), findsOneWidget);
      expect(_cle('demande-changement-$_yusuf'), findsNothing);
      final Finder lien = _cle('demande-voir-changement-$_aicha');
      await tester.ensureVisible(lien);
      await tester.tap(lien);
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_cle('changement-contenu'), findsOneWidget);
      expect(find.text(t.suiviDemandes.changement.titrePage), findsWidgets);
      await _demonter(tester);
    });

    testWidgets('transfert : nouvelle classe, titre de l enseignant, horaire, '
        'date', (WidgetTester tester) async {
      await _monter(
        tester,
        port: _echelle(),
        home: const ChangementClassePage(demandeId: _aicha),
      );
      expect(_cle('changement-contenu'), findsOneWidget);
      expect(
        find.text(t.suiviDemandes.changement.transfert(prenom: 'Aïcha')),
        findsOneWidget,
      );
      expect(find.text('Filles, lundi et mercredi 17:30'), findsOneWidget);
      expect(find.text('Sayyida Maryam'), findsOneWidget);
      // Horaire dans le fuseau du foyer : une heure commune se dit une fois.
      expect(find.text('Lundi et mercredi'), findsOneWidget);
      expect(find.text('17:30, heure de Paris'), findsOneWidget);
      expect(find.text('Vendredi 9 octobre à 11:20'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('fusion : sa phrase, sans nombre de classes ni d eleves', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _echelle(),
        home: const ChangementClassePage(demandeId: _bilal),
      );
      expect(
        find.text(t.suiviDemandes.changement.fusion(prenom: 'Bilal')),
        findsOneWidget,
      );
      final String tout = _textes(tester).join(' | ').toLowerCase();
      expect(tout, isNot(contains('parallèle')));
      expect(tout, isNot(contains('autres élèves')));
      expect(tout, isNot(contains('ensemble')));
      for (final String texte in _textes(tester)) {
        expect(
          _nombreHorsHeure.hasMatch(texte.replaceAll(_datesEtDurees, '')),
          isFalse,
          reason: texte,
        );
      }
      await _demonter(tester);
    });

    testWidgets('classe sans enseignant : la phrase, pas de nom invente', (
      WidgetTester tester,
    ) async {
      final SuiviDemande d = _demande(
        etape: EtapeDemande.eleveIntegre,
        changement: ChangementClasse(
          type: TypeChangementClasse.transfert,
          quand: DateTime(2026, 10, 9, 11),
          classe: 'Garçons, lundi 18:00',
          creneau: _lundi18(),
        ),
      );
      await _monter(
        tester,
        port: _PortFlux(
          () => Stream<List<SuiviDemande>>.value(<SuiviDemande>[d]),
        ),
        home: const ChangementClassePage(demandeId: 'd'),
      );
      expect(_cle('changement-sans-enseignant'), findsOneWidget);
      expect(_cle('changement-enseignant'), findsNothing);
      await _demonter(tester);
    });

    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      final StreamController<List<SuiviDemande>> jamais =
          StreamController<List<SuiviDemande>>();
      addTearDown(jamais.close);
      await _monter(
        tester,
        port: _PortFlux(() => jamais.stream),
        home: const ChangementClassePage(demandeId: _aicha),
      );
      expect(_cle('changement-contenu'), findsNothing);
      expect(_cle('changement-introuvable'), findsNothing);
      await _demonter(tester);
    });

    testWidgets('vide : un changement qui n est plus a afficher', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _echelle(),
        home: const ChangementClassePage(demandeId: _yusuf),
      );
      expect(_cle('changement-introuvable'), findsOneWidget);
      expect(_cle('changement-retour'), findsNothing);
      expect(find.text(t.suiviDemandes.changement.retour), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('erreur : un message et « Reessayer » ; hors ligne : le bloc '
        'dit ce qui manque', (WidgetTester tester) async {
      await _monter(
        tester,
        port: _PortFlux(
          () => Stream<List<SuiviDemande>>.error(StateError('serveur')),
        ),
        home: const ChangementClassePage(demandeId: _aicha),
      );
      expect(_cle('changement-erreur'), findsOneWidget);
      await _demonter(tester);
      await _monter(
        tester,
        port: _PortFlux(
          () => Stream<List<SuiviDemande>>.error(StateError('serveur')),
        ),
        home: const ChangementClassePage(demandeId: _aicha),
        horsLigne: true,
      );
      expect(_cle('changement-sans-donnees'), findsOneWidget);
      expect(find.textContaining('hors ligne'), findsNothing);
      await _demonter(tester);
    });
  });

  group('Notifications du changement', () {
    test('une notification par changement, vers l ecran de resultat, sans '
        'nombre ni mot sur les autres', () async {
      final List<NotificationTuteur> liste =
          await NotificationsSuiviDemandesDemo(_echelle()).liste();
      final List<NotificationTuteur> changements = <NotificationTuteur>[
        for (final NotificationTuteur n in liste)
          if (n.id.endsWith('-changement')) n,
      ];
      expect(changements, hasLength(2));
      expect(
        changements.map((NotificationTuteur n) => n.destination).toSet(),
        <String>{
          Routes.tuteurChangementPour(_aicha),
          Routes.tuteurChangementPour(_bilal),
        },
      );
      for (final NotificationTuteur n in changements) {
        expect(n.titre, isNot(contains('Sayyid')));
        expect(n.titre.toLowerCase(), isNot(contains('ensemble')));
        expect(n.titre.toLowerCase(), isNot(contains('parallèle')));
        expect(
          _nombreHorsHeure.hasMatch(n.titre.replaceAll(_datesEtDurees, '')),
          isFalse,
          reason: n.titre,
        );
      }
      // Les notifications des nouvelles etapes.
      final List<String> titres = <String>[
        for (final NotificationTuteur n in liste) n.titre,
      ];
      expect(
        titres,
        contains(
          'Demande de créneau de Yusuf\u00a0: votre demande est en liste '
          'd\'attente',
        ),
      );
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('suivi a six etats, avec changements (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: _echelle(),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await _demonter(tester);
      });
      testWidgets('ecran de resultat (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: _echelle(),
          home: const ChangementClassePage(demandeId: _aicha),
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        expect(_cle('changement-contenu'), findsOneWidget);
        verifierEcranSansMotCoupe(tester);
        await _demonter(tester);
      });
    }
  });
}
