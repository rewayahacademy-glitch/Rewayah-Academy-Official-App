// SNT (03/11/2026) : les seances reportees du planning de la direction, sur
// ports fictifs.
//
// Ce que le test prouve :
// - l'adaptateur lit la liste du serveur et ecarte une ligne illisible ; il
//   traduit chaque refus (chevauchement nomme de C1, date passee, deja fixee,
//   classe close, autre role) sans le texte SQL ;
// - la section « Séances reportées » n'apparait que s'il y a un geste a
//   faire : rien sans port, rien sans seance reportee ; une lecture en echec
//   le dit avec « Réessayer » ;
// - « Fixer la nouvelle date » : le jour au calendrier, l'heure au menu, la
//   date part au serveur a l'heure de l'appareil ; la confirmation dit la
//   date ; un refus de chevauchement nomme la classe en conflit ;
// - un seul bouton plein dans la feuille ; 320 px et texte a 200 %.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creation_classe_refusee.dart'
    show ConflitHoraire;
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/admin/port_seances_reportees.dart';
import 'package:rewayah_academy/core/admin/seances_reportees_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_planning/feuille_nouvelle_date.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';

import '../../support/garde_interface.dart' show verifierUnSeulBoutonPlein;
import 'session_direction.dart';

final DateTime _aujourdhui = DateTime(2030, 1, 10, 9);
final DateTime _lundi = lundiDe(_aujourdhui);

SeanceReportee _reportee() => SeanceReportee(
  id: 'r-1',
  seanceId: 's-1',
  classe: 'Alif',
  debut: DateTime(2030, 1, 9, 18).toUtc(),
  fin: DateTime(2030, 1, 9, 19).toUtc(),
  fuseau: 'Europe/Paris',
  enseignant: 'Titulaire A',
);

class _Planning implements PortPlanningDirection {
  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async =>
      const <SeancePlanning>[];
}

class _Reportees implements PortSeancesReportees {
  _Reportees({this.seances, this.refus, this.echec = false});

  final List<SeanceReportee>? seances;
  final NouvelleDateRefusee? refus;
  final bool echec;
  final List<({String report, DateTime debut})> envois =
      <({String report, DateTime debut})>[];

  @override
  Future<List<SeanceReportee>> lister() async {
    if (echec) throw StateError('lecture');
    return seances ?? <SeanceReportee>[_reportee()];
  }

  @override
  Future<String> fixer({
    required String reportId,
    required DateTime debut,
  }) async {
    envois.add((report: reportId, debut: debut));
    if (refus case final NouvelleDateRefusee r) throw r;
    return 's-nouvelle';
  }
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortSeancesReportees? port,
  Size taille = const Size(1440, 3000),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portPlanningDirectionProvider.overrideWithValue(_Planning()),
        portSeancesReporteesProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        sessionProvider.overrideWith(SessionPlanning.new),
        horlogeFormulairesProvider.overrideWithValue(() => _aujourdhui),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, luminosite),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? enfant) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: enfant!,
          ),
          home: PlanningPage(semaineInitiale: _lundi),
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _ouvrirFeuille(WidgetTester tester) async {
  final Finder ligne = find.text(t.snt.planning.ligne(classe: 'Alif'));
  await tester.ensureVisible(ligne);
  await tester.tap(ligne);
  await _laisser(tester);
}

Future<void> _choisirJourEtHeure(WidgetTester tester) async {
  final Finder jour = find.byKey(const ValueKey<String>('nouvelle-date-jour'));
  await tester.ensureVisible(jour);
  await tester.tap(jour);
  await _laisser(tester);
  await tester.tap(find.text('15').last);
  await _laisser(tester);
  await tester.tap(find.text('OK').last);
  await _laisser(tester);
  final Finder heure = find.byKey(
    const ValueKey<String>('nouvelle-date-heure'),
  );
  await tester.ensureVisible(heure);
  await tester.tap(heure);
  await _laisser(tester);
  final Finder dixHuit = find.text('18 h').last;
  await tester.ensureVisible(dixHuit);
  await tester.tap(dixHuit);
  await _laisser(tester);
}

Future<void> _confirmer(WidgetTester tester) async {
  final Finder bouton = find.text(t.snt.planning.confirmer).last;
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await _laisser(tester);
}

void main() {
  final p = t.snt.planning;

  group('adaptateur', () {
    test('lit la liste du serveur, ecarte une ligne illisible', () {
      final List<SeanceReportee> l = seancesReporteesDepuisJson(<dynamic>[
        <String, dynamic>{
          'id': 'r',
          'session_id': 's',
          'classe': 'Alif',
          'debut': '2030-01-09T17:00:00+00:00',
          'fin': '2030-01-09T18:00:00+00:00',
          'fuseau': 'Europe/Paris',
          'enseignant': ' Titulaire A ',
        },
        <String, dynamic>{'id': 'x', 'debut': 'pas une date'},
        'pas une ligne',
      ]);
      expect(l, hasLength(1));
      expect(l.single.enseignant, 'Titulaire A');
      expect(l.single.duree, const Duration(hours: 1));
      expect(seancesReporteesDepuisJson(null), isEmpty);
    });

    test('traduit chaque refus, jamais le texte SQL', () {
      final NouvelleDateRefusee c = refusNouvelleDate(
        code: 'P0001',
        message: 'chevauchement avec une séance existante',
        detail:
            'cette date chevauche une seance a venir de cet enseignant '
            '{"classe" : "Ba", "date" : "2030-01-15", "jour" : 2, '
            '"heure" : 18, "minute" : 0, "fuseau" : "Europe/Paris"}',
      );
      expect(c.motif, MotifNouvelleDateRefusee.chevauchement);
      expect(c.conflit?.classe, 'Ba');
      expect(
        refusNouvelleDate(code: '23P01', message: 'conflicting key').motif,
        MotifNouvelleDateRefusee.chevauchement,
      );
      expect(
        refusNouvelleDate(code: '22023', message: 'NouvelleDateInvalide').motif,
        MotifNouvelleDateRefusee.datePassee,
      );
      expect(
        refusNouvelleDate(
          code: '23505',
          message: 'NouvelleDateDejaFixee',
        ).motif,
        MotifNouvelleDateRefusee.dejaFixee,
      );
      expect(
        refusNouvelleDate(code: '22023', message: 'ClasseClose').motif,
        MotifNouvelleDateRefusee.classeClose,
      );
      expect(
        refusNouvelleDate(code: '42501', message: 'autre').motif,
        MotifNouvelleDateRefusee.nonAutorisee,
      );
      expect(
        refusNouvelleDate(code: 'XX000', message: 'boom').motif,
        MotifNouvelleDateRefusee.inconnu,
      );
    });
  });

  group('section', () {
    testWidgets('sans port, rien', (WidgetTester tester) async {
      await _monter(tester);
      expect(find.text(p.section), findsNothing);
    });

    testWidgets('sans seance reportee, rien', (WidgetTester tester) async {
      await _monter(
        tester,
        port: _Reportees(seances: const <SeanceReportee>[]),
      );
      expect(find.text(p.section), findsNothing);
    });

    testWidgets('une lecture en echec le dit, avec Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Reportees(echec: true));
      expect(
        find.byKey(const ValueKey<String>('seances-reportees-erreur')),
        findsOneWidget,
      );
      expect(find.text(p.erreurLecture), findsOneWidget);
    });

    testWidgets('la ligne dit la classe, la seance, l enseignant et le geste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _Reportees());
      expect(find.text(p.section), findsOneWidget);
      expect(find.text(p.ligne(classe: 'Alif')), findsOneWidget);
      expect(
        find.textContaining(
          p.ligneQuand(quand: quandSeanceReportee(_reportee().debut)),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(p.fixer), findsOneWidget);
    });
  });

  group('Fixer la nouvelle date', () {
    testWidgets('le jour et l heure partent au serveur, la date est dite', (
      WidgetTester tester,
    ) async {
      final _Reportees port = _Reportees();
      await _monter(tester, port: port);
      await _ouvrirFeuille(tester);
      expect(find.text(p.feuilleTitre), findsOneWidget);
      expect(
        find.text(p.feuilleContexte(enseignant: 'Titulaire A', minutes: '60')),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
      await _choisirJourEtHeure(tester);
      await _confirmer(tester);
      expect(port.envois, hasLength(1));
      expect(port.envois.single.report, 'r-1');
      expect(port.envois.single.debut, DateTime(2030, 1, 15, 18));
      expect(
        find.text(
          p.fixee(quand: quandSeanceReportee(DateTime(2030, 1, 15, 18))),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans jour ni heure, la feuille le dit, rien ne part', (
      WidgetTester tester,
    ) async {
      final _Reportees port = _Reportees();
      await _monter(tester, port: port);
      await _ouvrirFeuille(tester);
      await _confirmer(tester);
      expect(port.envois, isEmpty);
      expect(find.text(p.choixManquant), findsOneWidget);
    });

    testWidgets('un chevauchement nomme la classe en conflit', (
      WidgetTester tester,
    ) async {
      final _Reportees port = _Reportees(
        refus: const NouvelleDateRefusee(
          MotifNouvelleDateRefusee.chevauchement,
          conflit: ConflitHoraire(
            classe: 'Ba',
            jour: 2,
            heure: 18,
            fuseau: 'Europe/Paris',
            date: '2030-01-15',
          ),
        ),
      );
      await _monter(tester, port: port);
      await _ouvrirFeuille(tester);
      await _choisirJourEtHeure(tester);
      await _confirmer(tester);
      expect(
        find.byKey(const ValueKey<String>('nouvelle-date-message')),
        findsOneWidget,
      );
      expect(find.textContaining('Ba'), findsWidgets);
      expect(find.text(p.feuilleTitre), findsOneWidget);
    });

    for (final (String nom, Size taille, double echelle, Brightness l)
        in <(String, Size, double, Brightness)>[
          ('320 px, texte a 200 %', const Size(320, 3000), 2, Brightness.light),
          ('1440 px, sombre', const Size(1440, 3000), 1, Brightness.dark),
        ]) {
      testWidgets('feuille lisible : $nom', (WidgetTester tester) async {
        await _monter(
          tester,
          port: _Reportees(),
          taille: taille,
          echelle: echelle,
          luminosite: l,
        );
        await _ouvrirFeuille(tester);
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
      });
    }
  });
}
