// REMPL-1 : l'ecran commun des remplacements.
//
// Ce que le test prouve :
// - les cinq etats : chargement (squelette), contenu, vide, erreur, hors
//   ligne (avec et sans donnees deja lues) ;
// - l'alerte urgente en tete, son titre « Remplacement urgent : {jour}
//   {heure} » et sa ligne, un seul bouton plein ;
// - le filtre de genre, simule par l'adaptateur de demonstration (le serveur
//   le portera) : Classe d'hommes aux enseignants, de femmes aux
//   enseignantes, indeterminee a tous ;
// - premier arrive, premier servi : la seconde acceptation est refusee
//   proprement, la carte le dit et ne propose plus rien ;
// - 320 px, texte a 200 %, LTR et RTL : aucun debordement, aucun mot coupe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/remplacements_demo.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';
import 'package:rewayah_academy/features/remplacements/remplacements_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/hors_ligne_une_fois.dart';

OffreRemplacement _offre(String id, String classe, DateTime debut) =>
    OffreRemplacement(
      seanceId: id,
      classe: classe,
      debut: debut,
      fin: debut.add(const Duration(minutes: 45)),
      nbEleves: 3,
    );

final OffreRemplacement _fatiha = _offre(
  'r-fatiha',
  'Al-Fatiha',
  DateTime(2026, 9, 29, 18),
);
final OffreRemplacement _nour = _offre(
  'r-nour',
  'An-Nour',
  DateTime(2026, 9, 30, 19),
);
final OffreRemplacement _maryam = _offre(
  'r-maryam',
  'Maryam',
  DateTime(2026, 9, 30, 17),
);
final OffreRemplacement _kawthar = _offre(
  'r-kawthar',
  'Al-Kawthar',
  DateTime(2026, 10, 1, 18),
);

/// Indeterminee, hommes, femmes, et une deja prise par un collegue.
TableauRemplacementsDemo _tableau() =>
    TableauRemplacementsDemo(<(OffreRemplacement, PublicClasseDemo, String?)>[
      (_fatiha, PublicClasseDemo.indetermine, null),
      (_nour, PublicClasseDemo.hommes, null),
      (_maryam, PublicClasseDemo.femmes, null),
      (_kawthar, PublicClasseDemo.indetermine, 'ens-collegue'),
    ]);

PortRemplacementsDemo _port(
  TableauRemplacementsDemo tableau, {
  String id = 'ens-a',
  GenreEnseignantDemo genre = GenreEnseignantDemo.homme,
  Duration latence = Duration.zero,
  bool horsLigne = false,
}) => PortRemplacementsDemo(
  tableau: tableau,
  enseignantId: id,
  genre: genre,
  latence: latence,
  horsLigne: horsLigne,
);

/// Un port dont le flux est fourni par le test (chargement, echec).
class _PortFlux implements PortRemplacements {
  _PortFlux(this._flux);

  final Stream<List<OffreCommune>> Function() _flux;
  int lectures = 0;

  @override
  Stream<List<OffreCommune>> suivre() {
    lectures++;
    return _flux();
  }

  @override
  Future<ResultatPriseRemplacement> prendre(String seanceId) async =>
      ResultatPriseRemplacement.acceptee;
}

class _ConfirmesFixes extends RemplacementsControleur {
  _ConfirmesFixes(this._depart);

  final List<OffreRemplacement> _depart;

  @override
  List<OffreRemplacement> build() => _depart;
}

Future<void> _monter(
  WidgetTester tester, {
  PortRemplacements? port,
  bool horsLigne = false,
  List<OffreRemplacement> confirmes = const <OffreRemplacement>[],
  double largeur = 390,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portRemplacementsProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
        remplacementsConfirmesProvider.overrideWith(
          () => _ConfirmesFixes(confirmes),
        ),
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
          home: const RemplacementsPage(),
        ),
      ),
    ),
  );
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Demonte la page : les minuteries du bloc asynchrone s'annulent.
Future<void> _demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

Finder _prendre(OffreRemplacement o) =>
    find.byKey(ValueKey<String>('remplacement-prendre-${o.seanceId}'));
Finder _urgente(OffreRemplacement o) =>
    find.byKey(ValueKey<String>('remplacement-urgent-${o.seanceId}'));
Finder _prise(OffreRemplacement o) =>
    find.byKey(ValueKey<String>('remplacement-pris-${o.seanceId}'));

List<OffreRemplacement> _confirmesDans(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RemplacementsPage)))
        .read(remplacementsConfirmesProvider);

void main() {
  group('Les cinq etats', () {
    testWidgets('chargement : le squelette, aucune offre inventee', (
      WidgetTester tester,
    ) async {
      final StreamController<List<OffreCommune>> jamais =
          StreamController<List<OffreCommune>>();
      addTearDown(jamais.close);
      await _monter(tester, port: _PortFlux(() => jamais.stream));
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(AppCard), findsNothing);
      await _demonter(tester);
    });

    testWidgets('contenu : l alerte urgente en tete, titre et ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(_tableau()),
        confirmes: <OffreRemplacement>[
          _offre('r-ikhlas', 'Al-Ikhlas', DateTime(2026, 10, 2, 17)),
        ],
      );
      final Finder titre = find.text(
        'Remplacement urgent : mardi 29 septembre 18:00',
      );
      expect(titre, findsOneWidget);
      expect(
        find.text(t.enseignant.remplacements.urgentPhrase),
        findsNWidgets(2),
        reason: 'Al-Fatiha et An-Nour sont ouvertes',
      );
      expect(
        find.text(
          'Un enseignant est absent. Assurez cette séance à sa place : elle '
          'vous sera payée après validation en fin de mois.',
        ),
        findsNWidgets(2),
      );
      // ALERTE-1 : la premiere carte de l'ecran est l'urgence la plus
      // proche, avant « Vos remplacements » et « Deja pris ».
      final double hautUrgente = tester.getTopLeft(_urgente(_fatiha)).dy;
      final Iterable<AppCard> cartes = tester.widgetList<AppCard>(
        find.byType(AppCard),
      );
      final double hautPremiere = cartes
          .map((AppCard c) => tester.getTopLeft(find.byWidget(c)).dy)
          .reduce((double a, double b) => a < b ? a : b);
      expect(hautUrgente, hautPremiere);
      expect(
        hautUrgente,
        lessThan(
          tester
              .getTopLeft(
                find.text(t.enseignant.remplacements.vosRemplacements),
              )
              .dy,
        ),
      );
      expect(
        tester.getTopLeft(_urgente(_nour)).dy,
        lessThan(
          tester.getTopLeft(find.text(t.enseignant.remplacements.prisTitre)).dy,
        ),
      );
      // Visuel distinct : surface douce d'alerte et contour fort.
      final AppCard urgente = tester.widget<AppCard>(_urgente(_fatiha));
      final AppPalette palette = AppPalette.of(
        tester.element(_urgente(_fatiha)),
      );
      expect(urgente.surface, palette.washAlert);
      expect(urgente.contourFort, isTrue);
      // K-56 : un seul bouton plein, sur la plus proche.
      verifierUnSeulBoutonPlein(tester);
      expect(
        tester.widget<ActionPrincipale>(_prendre(_fatiha)).niveau,
        NiveauAction.principale,
      );
      expect(
        tester.widget<ActionPrincipale>(_prendre(_nour)).niveau,
        NiveauAction.secondaire,
      );
      // L'offre prise par un collegue : sans bouton, la pastille le dit.
      expect(_prise(_kawthar), findsOneWidget);
      expect(_prendre(_kawthar), findsNothing);
      expect(
        find.text(t.enseignant.remplacements.prisPastille),
        findsOneWidget,
      );
      // Vos remplacements : la carte partagee de la Journee.
      expect(find.byType(CarteRemplacement), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('vide : une phrase, pas une page blanche', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _port(
          TableauRemplacementsDemo(
            const <(OffreRemplacement, PublicClasseDemo, String?)>[],
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('remplacements-vide')),
        findsOneWidget,
      );
      expect(find.text(t.enseignant.journee.remplacementsVide), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('erreur en ligne : ce qui manque, et la relecture', (
      WidgetTester tester,
    ) async {
      final _PortFlux port = _PortFlux(
        () => Stream<List<OffreCommune>>.error(StateError('serveur')),
      );
      await _monter(tester, port: port);
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byKey(const ValueKey<String>('remplacements-erreur')),
      );
      expect(etat.nature, NatureEtat.echecServeur);
      expect(find.text(t.enseignant.remplacements.erreur), findsOneWidget);
      expect(find.text(t.enseignant.journee.remplacementsVide), findsNothing);
      expect(port.lectures, 1);
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(port.lectures, 2);
      await _demonter(tester);
    });

    testWidgets('erreur : les remplacements confirmes restent dessous (D11)', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortFlux(
          () => Stream<List<OffreCommune>>.error(StateError('serveur')),
        ),
        confirmes: <OffreRemplacement>[_fatiha],
      );
      expect(find.text(t.enseignant.remplacements.erreur), findsOneWidget);
      expect(find.byType(CarteRemplacement), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('hors ligne sans donnees : ce qui manque, une seule fois', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortFlux(
          () => Stream<List<OffreCommune>>.error(StateError('reseau')),
        ),
        horsLigne: true,
      );
      expectSansDonnees(t.enseignant.remplacements.sansDonnees);
      expect(
        tester.widget<EtatSansDonnees>(find.byType(EtatSansDonnees)).onAction,
        isNotNull,
      );
      expect(find.text(t.enseignant.remplacements.erreur), findsNothing);
      await _demonter(tester);
    });

    testWidgets('hors ligne avec donnees : le bandeau seul, les offres lues', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(_tableau()), horsLigne: true);
      expectAvecDonnees();
      expect(_urgente(_fatiha), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('sans port : aucune offre inventee, ni bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, confirmes: <OffreRemplacement>[_fatiha]);
      expect(find.byType(CarteRemplacement), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
      await _demonter(tester);
    });
  });

  group('Filtre de genre (simule ; le serveur le portera)', () {
    test('Classe d hommes aux enseignants, de femmes aux enseignantes', () {
      final TableauRemplacementsDemo tableau = _tableau();
      Set<String> vues(GenreEnseignantDemo genre) => tableau
          .visibles('ens-x', genre)
          .map((OffreCommune o) => o.offre.seanceId)
          .toSet();
      expect(vues(GenreEnseignantDemo.homme), <String>{
        'r-fatiha',
        'r-nour',
        'r-kawthar',
      });
      expect(vues(GenreEnseignantDemo.femme), <String>{
        'r-fatiha',
        'r-maryam',
        'r-kawthar',
      });
    });

    test('une offre invisible ne se prend pas', () {
      final TableauRemplacementsDemo tableau = _tableau();
      expect(
        tableau.prendre('r-maryam', 'ens-a', GenreEnseignantDemo.homme),
        ResultatPriseRemplacement.dejaPrise,
      );
      expect(
        tableau.prendre('r-maryam', 'ens-f', GenreEnseignantDemo.femme),
        ResultatPriseRemplacement.acceptee,
      );
    });

    for (final GenreEnseignantDemo genre in GenreEnseignantDemo.values) {
      testWidgets('a l ecran : ${genre.name}', (WidgetTester tester) async {
        await _monter(tester, port: _port(_tableau(), genre: genre));
        final bool homme = genre == GenreEnseignantDemo.homme;
        expect(_urgente(_fatiha), findsOneWidget);
        expect(_urgente(_nour), homme ? findsOneWidget : findsNothing);
        expect(_urgente(_maryam), homme ? findsNothing : findsOneWidget);
        expect(find.text('An-Nour'), homme ? findsOneWidget : findsNothing);
        expect(find.text('Maryam'), homme ? findsNothing : findsOneWidget);
        await _demonter(tester);
      });
    }
  });

  group('Premier arrive, premier servi', () {
    test('la seconde acceptation est refusee', () {
      final TableauRemplacementsDemo tableau = _tableau();
      expect(
        tableau.prendre('r-fatiha', 'ens-a', GenreEnseignantDemo.homme),
        ResultatPriseRemplacement.acceptee,
      );
      expect(
        tableau.prendre('r-fatiha', 'ens-b', GenreEnseignantDemo.femme),
        ResultatPriseRemplacement.dejaPrise,
      );
      expect(
        tableau
            .visibles('ens-b', GenreEnseignantDemo.femme)
            .firstWhere((OffreCommune o) => o.offre.seanceId == 'r-fatiha')
            .etat,
        EtatOffreCommune.priseParUnCollegue,
      );
      expect(
        tableau
            .visibles('ens-a', GenreEnseignantDemo.homme)
            .firstWhere((OffreCommune o) => o.offre.seanceId == 'r-fatiha')
            .etat,
        EtatOffreCommune.priseParMoi,
      );
    });

    testWidgets('accepter : la seance devient votre remplacement', (
      WidgetTester tester,
    ) async {
      final TableauRemplacementsDemo tableau = _tableau();
      await _monter(tester, port: _port(tableau));
      await tester.tap(_prendre(_fatiha));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_urgente(_fatiha), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('remplacements-acceptee')),
        findsOneWidget,
      );
      expect(find.byType(CarteRemplacement), findsOneWidget);
      expect(
        _confirmesDans(tester).map((OffreRemplacement o) => o.seanceId),
        <String>['r-fatiha'],
      );
      // Le bouton plein passe a la suivante.
      expect(
        tester.widget<ActionPrincipale>(_prendre(_nour)).niveau,
        NiveauAction.principale,
      );
      await _demonter(tester);
    });

    testWidgets('un collegue accepte pendant l envoi : refus propre', (
      WidgetTester tester,
    ) async {
      final TableauRemplacementsDemo tableau = _tableau();
      await _monter(
        tester,
        port: _port(tableau, latence: const Duration(milliseconds: 300)),
      );
      await tester.tap(_prendre(_fatiha));
      await tester.pump();
      // Le bouton porte son chargement, il n'est pas grise.
      expect(
        tester.widget<ActionPrincipale>(_prendre(_fatiha)).enCours,
        isTrue,
      );
      // Le collegue arrive le premier.
      expect(
        tableau.prendre('r-fatiha', 'ens-b', GenreEnseignantDemo.homme),
        ResultatPriseRemplacement.acceptee,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_prendre(_fatiha), findsNothing);
      expect(_prise(_fatiha), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('remplacement-pris-avant-vous-r-fatiha'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.enseignant.remplacements.prisAvantVous),
        findsOneWidget,
      );
      expect(_confirmesDans(tester), isEmpty);
      expect(find.byType(CarteRemplacement), findsNothing);
      await _demonter(tester);
    });

    testWidgets('les autres voient l offre prise, sans bouton', (
      WidgetTester tester,
    ) async {
      final TableauRemplacementsDemo tableau = _tableau();
      await _monter(tester, port: _port(tableau, id: 'ens-b'));
      expect(_prendre(_nour), findsOneWidget);
      tableau.prendre('r-nour', 'ens-a', GenreEnseignantDemo.homme);
      await tester.pump();
      await tester.pump();
      expect(_prendre(_nour), findsNothing);
      expect(_prise(_nour), findsOneWidget);
      // Aucun message « avant vous » : B n'avait rien tente.
      expect(find.text(t.enseignant.remplacements.prisAvantVous), findsNothing);
      await _demonter(tester);
    });

    testWidgets('sans reponse : rien n est suppose, le bouton reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: _port(_tableau(), horsLigne: true));
      await tester.tap(_prendre(_fatiha));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.byKey(
          const ValueKey<String>('remplacement-sans-reponse-r-fatiha'),
        ),
        findsOneWidget,
      );
      expect(_prendre(_fatiha), findsOneWidget);
      expect(_confirmesDans(tester), isEmpty);
      await _demonter(tester);
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('aucun debordement ni mot coupe (${direction.name})', (
        WidgetTester tester,
      ) async {
        final TableauRemplacementsDemo tableau = _tableau();
        await _monter(
          tester,
          port: _port(tableau, latence: const Duration(milliseconds: 300)),
          confirmes: <OffreRemplacement>[
            _offre('r-ikhlas', 'Al-Ikhlas', DateTime(2026, 10, 2, 17)),
          ],
          largeur: 320,
          echelle: 2,
          direction: direction,
        );
        // L'etat le plus charge : une offre prise juste avant soi.
        await tester.tap(_prendre(_nour));
        await tester.pump();
        tableau.prendre('r-nour', 'ens-b', GenreEnseignantDemo.homme);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(_urgente(_fatiha), findsOneWidget);
        expect(_prise(_nour), findsOneWidget);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);
        await _demonter(tester);
      });
    }
  });
}
