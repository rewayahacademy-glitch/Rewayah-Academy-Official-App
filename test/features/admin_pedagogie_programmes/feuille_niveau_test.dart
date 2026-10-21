import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/champ_etiquete.dart';
import 'package:rewayah_academy/core/widgets/choix_nombre.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

/// Un service de programme en memoire : une version brouillon, deux cycles.
class _Faux implements ServiceProgramme {
  final List<NiveauProgramme> niveauxInitiaux = _niveaux;
  final List<Map<String, Object?>> ajouts = <Map<String, Object?>>[];
  final List<Map<String, Object?>> modifications = <Map<String, Object?>>[];
  bool doublon = false;

  @override
  Future<List<VersionProgramme>> versions() async => <VersionProgramme>[
    VersionProgramme(
      id: 'v1',
      statut: StatutVersionProgramme.brouillon,
      numeroVersion: 1,
      creeParIdentifiant: 'x',
      creeParPrenom: null,
      creeParNom: null,
      publieeAt: null,
      nombreNiveaux: niveauxInitiaux.length,
      createdAt: DateTime.utc(2026, 10, 1),
    ),
  ];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      niveauxInitiaux;

  @override
  Future<String> creerVersion({String? versionSourceId}) async => 'v2';

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {
    if (doublon) {
      throw Exception('PostgrestException: code technique deja utilise');
    }
    ajouts.add(<String, Object?>{
      'code': codeTechnique,
      'nom': nomHumain,
      'cycle': cycle,
      'ordre': ordre,
    });
    return 'n9';
  }

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {
    modifications.add(<String, Object?>{
      'id': niveauId,
      'cycle': cycle,
      'ordre': ordre,
    });
  }

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {}
}

const List<NiveauProgramme> _niveaux = <NiveauProgramme>[
  NiveauProgramme(
    id: 'a',
    codeTechnique: 'f1',
    nomHumain: 'Lettres',
    cycle: 'Fondations',
    ordre: 1,
    description: null,
  ),
  NiveauProgramme(
    id: 'b',
    codeTechnique: 'f2',
    nomHumain: 'Voyelles',
    cycle: 'Fondations',
    ordre: 2,
    description: null,
  ),
  NiveauProgramme(
    id: 'c',
    codeTechnique: 'i1',
    nomHumain: 'Madd',
    cycle: 'Intermediaire',
    ordre: 5,
    description: null,
  ),
];

Future<void> _ouvrir(WidgetTester tester, _Faux service, Size cadre) async {
  tester.view.physicalSize = cadre;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const ProgrammesPage(),
      surcharges: <Override>[
        serviceProgrammeProvider.overrideWithValue(service),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// L'ordre affiche par le choix pas a pas (jamais saisi au clavier, 17/10).
String _ordre(WidgetTester tester) =>
    '${tester.widget<ChoixNombre>(find.byType(ChoixNombre)).valeur}';

/// Fait defiler la feuille jusqu'au bouton d'envoi : avec les etiquettes au
/// dessus des champs (FORM-CORR-1), le formulaire depasse un ecran de 390 x 844.
Future<void> _envoyer(WidgetTester tester, String libelle) async {
  final Element defilant = find
      .ancestor(of: find.text(libelle), matching: find.byType(Scrollable))
      .first
      .evaluate()
      .single;
  final ScrollPosition position =
      ((defilant as StatefulElement).state as ScrollableState).position;
  // Le champ qui a le focus ramene sa frappe a l'ecran : sans lacher le focus,
  // la feuille revient en haut juste apres le defilement.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle));
  await tester.pumpAndSettle();
}

/// FORM-L5 : cycle en puces, ordre deduit, code genere depuis le nom.
void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('codeDepuisNom : minuscules, sans accents, tirets', () {
    expect(codeDepuisNom('Fondations de Lecture'), 'fondations-de-lecture');
    expect(codeDepuisNom('  Élève : Étape 1 !  '), 'eleve-etape-1');
    expect(codeDepuisNom('Cœur à l\'œuvre'), 'coeur-a-l-oeuvre');
    expect(codeDepuisNom('---'), '');
  });

  for (final Size cadre in <Size>[
    const Size(390, 844),
    const Size(1400, 1000),
  ]) {
    final String suffixe = '(${cadre.width.toInt()})';

    testWidgets('ajout : puces des cycles existants, ordre deduit, code '
        'genere, envoi $suffixe', (WidgetTester tester) async {
      final _Faux service = _Faux();
      await _ouvrir(tester, service, cadre);
      await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
      await tester.pumpAndSettle();

      // Les cycles de la version sont des puces, plus « Nouveau cycle ».
      expect(find.text('Fondations'), findsWidgets);
      expect(find.text('Intermediaire'), findsWidgets);
      expect(find.text(t.admin.programmes.nouveauCycle), findsOneWidget);
      // Pas de saisie libre du cycle tant qu'on n'ouvre pas « Nouveau cycle ».
      expect(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNouveauCycle,
          ),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      // Cycle propose : celui du dernier niveau, ordre = 5 + 1.
      expect(_ordre(tester), '6');

      // Choisir « Fondations » : dernier ordre 2, donc 3.
      await tester.tap(find.widgetWithText(FilterPill, 'Fondations').last);
      await tester.pumpAndSettle();
      expect(_ordre(tester), '3');

      // Le pas +1 / -1.
      await tester.tap(find.bySemanticsLabel(t.admin.programmes.ordrePlus));
      await tester.pumpAndSettle();
      expect(_ordre(tester), '4');
      await tester.tap(find.bySemanticsLabel(t.admin.programmes.ordreMoins));
      await tester.pumpAndSettle();
      expect(_ordre(tester), '3');

      // Le code se genere depuis le nom, sans champ code a remplir.
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNomHumain,
          ),
          matching: find.byType(TextField),
        ),
        'Éléments de Tajwîd',
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.admin.programmes.codeGenere(code: 'elements-de-tajwid')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champCodeTechnique,
          ),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );

      await _envoyer(tester, t.admin.programmes.ajouterNiveauEnvoyer);
      expect(service.ajouts, hasLength(1));
      expect(service.ajouts.single, <String, Object?>{
        'code': 'elements-de-tajwid',
        'nom': 'Éléments de Tajwîd',
        'cycle': 'Fondations',
        'ordre': 3,
      });
    });

    testWidgets('nouveau cycle : saisie en dernier recours, ordre = dernier '
        'de la version + 1 $suffixe', (WidgetTester tester) async {
      final _Faux service = _Faux();
      await _ouvrir(tester, service, cadre);
      await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.admin.programmes.nouveauCycle));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNouveauCycle,
          ),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
      expect(_ordre(tester), '6');
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNouveauCycle,
          ),
          matching: find.byType(TextField),
        ),
        'Avance',
      );
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNomHumain,
          ),
          matching: find.byType(TextField),
        ),
        'Waqf',
      );
      await _envoyer(tester, t.admin.programmes.ajouterNiveauEnvoyer);
      expect(service.ajouts.single['cycle'], 'Avance');
      expect(service.ajouts.single['code'], 'waqf');
    });

    testWidgets('le code reste modifiable, et un doublon refuse par le '
        'serveur affiche une erreur « non confirme » $suffixe', (
      WidgetTester tester,
    ) async {
      final _Faux service = _Faux()..doublon = true;
      await _ouvrir(tester, service, cadre);
      await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champNomHumain,
          ),
          matching: find.byType(TextField),
        ),
        'Lettres',
      );
      await tester.tap(find.text(t.admin.programmes.codeModifier));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(
            ChampEtiquete,
            t.admin.programmes.champCodeTechnique,
          ),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
      await _envoyer(tester, t.admin.programmes.ajouterNiveauEnvoyer);
      expect(find.textContaining('pas été confirmé'), findsOneWidget);
      expect(find.textContaining('modifiez-le'), findsOneWidget);
      expect(service.ajouts, isEmpty);
    });

    testWidgets('bouton jamais grise : un nom vide dit ce qui manque '
        '$suffixe', (WidgetTester tester) async {
      final _Faux service = _Faux();
      await _ouvrir(tester, service, cadre);
      await tester.tap(find.text(t.admin.programmes.ajouterNiveau));
      await tester.pumpAndSettle();
      await _envoyer(tester, t.admin.programmes.ajouterNiveauEnvoyer);
      expect(
        find.text(
          t.admin.programmes.manque(
            elements:
                '${t.admin.programmes.manqueNom}, '
                '${t.admin.programmes.manqueCode}',
          ),
        ),
        findsOneWidget,
      );
      expect(service.ajouts, isEmpty);
    });
  }

  testWidgets('320 x 700 en texte x2 : la page defile d\'un bloc, sans '
      'deborder, et les niveaux restent atteignables', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        Builder(
          builder: (BuildContext contexte) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: const ProgrammesPage(),
          ),
        ),
        surcharges: <Override>[
          serviceProgrammeProvider.overrideWithValue(_Faux()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.dragFrom(const Offset(160, 600), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Madd'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modification : le cycle du niveau est retenu, changer de '
      'cycle rededuit l ordre sans compter le niveau lui-meme', (
    WidgetTester tester,
  ) async {
    final _Faux service = _Faux();
    await _ouvrir(tester, service, const Size(390, 844));
    await tester.tap(find.byTooltip('Lettres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.admin.programmes.modifierNiveau));
    await tester.pumpAndSettle();
    expect(_ordre(tester), '1');
    // Vers « Intermediaire » (dernier ordre 5) : 6.
    await tester.tap(find.widgetWithText(FilterPill, 'Intermediaire').last);
    await tester.pumpAndSettle();
    expect(_ordre(tester), '6');
    await _envoyer(tester, t.admin.programmes.modifierNiveauEnvoyer);
    expect(service.modifications.single, <String, Object?>{
      'id': 'a',
      'cycle': 'Intermediaire',
      'ordre': 6,
    });
  });
}
