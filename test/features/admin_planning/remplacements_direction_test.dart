// Remplacements cote direction (finir REMPL-1, 31/10/2026), sur ports fictifs.
//
// Ce que le test prouve :
// - l'adaptateur lit le bilan et les refus du serveur sans rien calculer ;
// - le planning dit l'etat de remplacement d'une seance et le bilan de la
//   semaine par titulaire et par classe ;
// - le menu d'une seance prevue a venir ouvre la feuille ; une seance deja
//   remplacee n'a pas de menu ;
// - R12 : un enseignant du genre de la classe part sans choix hors genre ; un
//   enseignant de l'autre genre est dit avant le bouton, et part avec le choix
//   explicite ;
// - un refus du serveur (occupe) se dit en phrase, la liste est relue ;
// - sans port, ni menu ni bilan ;
// - un seul bouton plein dans la feuille ; 320 px et texte a 200 %.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/admin/port_remplacements_direction.dart';
import 'package:rewayah_academy/core/admin/remplacements_direction_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_planning/planning_page.dart';

import '../../support/garde_interface.dart' show verifierUnSeulBoutonPlein;

final DateTime _lundi = lundiDe(DateTime.now().add(const Duration(days: 14)));
final DateTime _debut = DateTime(_lundi.year, _lundi.month, _lundi.day + 1, 18);

List<SeancePlanning> _seances() => <SeancePlanning>[
  SeancePlanning(
    id: 's-1',
    classe: 'Alif',
    debut: _debut,
    dureeMinutes: 45,
    statut: StatutSeance.planifiee,
    enseignant: 'Titulaire A',
  ),
  SeancePlanning(
    id: 's-2',
    classe: 'Ba',
    debut: _debut.add(const Duration(hours: 1)),
    dureeMinutes: 45,
    statut: StatutSeance.planifiee,
    enseignant: 'Titulaire A',
  ),
];

class _Planning implements PortPlanningDirection {
  @override
  Future<List<SeancePlanning>> semaine(DateTime lundi) async => _seances();
}

class _Remplacements implements PortRemplacementsDirection {
  _Remplacements({this.refus});

  final ResultatDesignation? refus;
  final List<({String seance, String remplacant, bool horsGenre})> envois =
      <({String seance, String remplacant, bool horsGenre})>[];
  int lecturesPossibles = 0;

  @override
  Future<BilanRemplacements> periode(DateTime debut, DateTime fin) async =>
      const BilanRemplacements(
        parTitulaire: <RemplacementsTitulaire>[
          RemplacementsTitulaire(
            titulaireId: 't-1',
            titulaire: 'Titulaire A',
            groupeId: 'g-1',
            classe: 'Alif',
            seances: 3,
            remplacees: 2,
            sansRemplacant: 1,
          ),
        ],
        seances: <String, RemplacementSeanceDirection>{
          's-1': RemplacementSeanceDirection(
            seanceId: 's-1',
            etat: EtatRemplacementSeance.absenceDeclaree,
          ),
          's-2': RemplacementSeanceDirection(
            seanceId: 's-2',
            etat: EtatRemplacementSeance.remplacee,
            remplacant: 'Autre E',
            horsGenre: true,
          ),
        },
      );

  @override
  Future<List<RemplacantPossible>> possibles(String seanceId) async {
    lecturesPossibles++;
    return const <RemplacantPossible>[
      RemplacantPossible(
        id: 'e-libre',
        nom: 'Libre B',
        identifiant: 'ENS-LB-1',
        genreCompatible: true,
      ),
      RemplacantPossible(
        id: 'e-autre',
        nom: 'Autre E',
        identifiant: 'ENS-AE-1',
        genreCompatible: false,
      ),
    ];
  }

  @override
  Future<ResultatDesignation> designer({
    required String seanceId,
    required String remplacantId,
    required bool horsGenre,
  }) async {
    envois.add((
      seance: seanceId,
      remplacant: remplacantId,
      horsGenre: horsGenre,
    ));
    return refus ?? ResultatDesignation.designe;
  }
}

Future<void> _monter(
  WidgetTester tester, {
  PortRemplacementsDirection? port,
  Size taille = const Size(1440, 3000),
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portPlanningDirectionProvider.overrideWithValue(_Planning()),
        portRemplacementsDirectionProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
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

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _ouvrirFeuille(WidgetTester tester) async {
  final Finder menu = find.bySemanticsLabel(
    t.commun.listes.actionsDe(objet: 'Alif'),
  );
  await tester.ensureVisible(menu.first);
  await tester.tap(menu.first);
  await _laisser(tester);
  await tester.tap(
    find.text(t.admin.planning.remplacement.action(deClasse: deDevant('Alif'))),
  );
  await _laisser(tester);
}

Future<void> _choisir(WidgetTester tester, String nom) async {
  final Finder carte = find.text(nom).last;
  await tester.ensureVisible(carte);
  await tester.tap(carte);
  await _laisser(tester);
}

Future<void> _confirmer(WidgetTester tester, String libelle) async {
  final Finder bouton = find.text(libelle).last;
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
  await _laisser(tester);
}

void main() {
  final r = t.admin.planning.remplacement;

  group('adaptateur', () {
    test('lit le bilan rendu par le serveur', () {
      final BilanRemplacements b = bilanDepuisJson(<String, dynamic>{
        'par_enseignant': <dynamic>[
          <String, dynamic>{
            'titulaire_id': 't',
            'titulaire': 'Titulaire A',
            'groupe_id': 'g',
            'classe': 'Alif',
            'numero_dans_famille': 2,
            'seances': 3,
            'remplacees': 2,
            'sans_remplacant': 1,
          },
        ],
        'seances': <dynamic>[
          <String, dynamic>{
            'seance_id': 's',
            'etat': 'remplacee',
            'remplacant': 'Autre E',
            'hors_genre': true,
          },
          <String, dynamic>{'seance_id': 'x', 'etat': 'inconnu'},
        ],
      });
      expect(b.parTitulaire.single.numeroDansFamille, 2);
      expect(b.parTitulaire.single.sansRemplacant, 1);
      expect(b.seances.keys, <String>['s']);
      expect(b.seances['s']!.horsGenre, isTrue);
      expect(bilanDepuisJson(null).parTitulaire, isEmpty);
    });

    test('traduit les refus du serveur, jamais un autre message', () {
      expect(
        resultatDesignationDepuisErreur('RemplacantOccupe'),
        ResultatDesignation.occupe,
      );
      expect(
        resultatDesignationDepuisErreur('RemplacementDejaPris'),
        ResultatDesignation.dejaPris,
      );
      expect(resultatDesignationDepuisErreur('autre chose'), isNull);
    });
  });

  testWidgets('le planning dit le remplacement et le bilan de la semaine', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: _Remplacements());
    expect(find.textContaining(r.absenceSansRemplacant), findsOneWidget);
    expect(
      find.textContaining(r.remplaceParHorsGenre(nom: 'Autre E')),
      findsOneWidget,
    );
    expect(
      find.text(r.bilanLigne(titulaire: 'Titulaire A', classe: 'Alif')),
      findsOneWidget,
    );
    expect(
      find.text(r.bilanDetail(seances: '3', remplacees: '2', sans: '1')),
      findsOneWidget,
    );
    // La seance deja remplacee n'a pas de menu.
    expect(
      find.bySemanticsLabel(t.commun.listes.actionsDe(objet: 'Ba')),
      findsNothing,
    );
  });

  testWidgets('sans port, ni menu ni bilan', (WidgetTester tester) async {
    await _monter(tester);
    expect(
      find.byKey(const ValueKey<String>('planning-remplacements')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(t.commun.listes.actionsDe(objet: 'Alif')),
      findsNothing,
    );
  });

  testWidgets('R12 : un enseignant du genre de la classe, sans choix hors '
      'genre', (WidgetTester tester) async {
    final _Remplacements port = _Remplacements();
    await _monter(tester, port: port);
    await _ouvrirFeuille(tester);
    expect(
      find.byKey(const ValueKey<String>('feuille-remplacant')),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
    await _choisir(tester, 'Libre B');
    expect(
      find.byKey(const ValueKey<String>('remplacant-hors-genre')),
      findsNothing,
    );
    await _confirmer(tester, r.confirmer);
    expect(port.envois.single.remplacant, 'e-libre');
    expect(port.envois.single.horsGenre, isFalse);
    expect(find.text(r.designe(nom: 'Libre B')), findsOneWidget);
  });

  testWidgets('R12 : l\'autre genre est dit avant le bouton et part avec le '
      'choix explicite', (WidgetTester tester) async {
    final _Remplacements port = _Remplacements();
    await _monter(tester, port: port);
    await _ouvrirFeuille(tester);
    await _choisir(tester, 'Autre E');
    expect(
      find.byKey(const ValueKey<String>('remplacant-hors-genre')),
      findsOneWidget,
    );
    await _confirmer(tester, r.confirmerHorsGenre);
    expect(port.envois.single.horsGenre, isTrue);
  });

  testWidgets('un refus du serveur se dit en phrase, la liste est relue', (
    WidgetTester tester,
  ) async {
    final _Remplacements port = _Remplacements(
      refus: ResultatDesignation.occupe,
    );
    await _monter(tester, port: port);
    await _ouvrirFeuille(tester);
    final int avant = port.lecturesPossibles;
    await _choisir(tester, 'Libre B');
    await _confirmer(tester, r.confirmer);
    expect(find.text(r.refusOccupe), findsOneWidget);
    expect(port.lecturesPossibles, greaterThan(avant));
  });

  testWidgets('320 px, texte a 200 % : la feuille s\'ouvre sans debordement', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: _Remplacements(),
      taille: const Size(320, 2400),
      echelle: 2,
    );
    await _ouvrirFeuille(tester);
    expect(
      find.byKey(const ValueKey<String>('feuille-remplacant')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
