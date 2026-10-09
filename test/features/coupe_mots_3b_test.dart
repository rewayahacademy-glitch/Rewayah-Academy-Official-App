// COUPE-MOTS-3b (reserves de COUPE-MOTS-3).
//
// 1. Taille de fichier, test d'ECRAN : l'Espace Classe enseignant
//    (`FicheGroupePage`) recoit des ressources dont le titre court porte une
//    taille ecrite avec une espace ORDINAIRE (« 8,1 Mo », aucune espace
//    insecable prealable). L'ecran doit lier chaque nombre a son unite
//    (`lierTaillesFichier` dans `emplacements_groupe.dart`). Remplacer cet
//    appel par l'identite fait echouer le test.
// 2. Texte francais dans l'interface arabe (RTL) : la valeur de progression
//    (« Chapitre 1 · 60 % ») et les phrases du recapitulatif de
//    l'observation (« ... avant l'envoi. », « Élève précis · Mariam S. »,
//    « ... à l'administration. »), la capacite (« 3 élèves sur 6 places »)
//    et le conseil d'appareil (« ... pris en charge. ») gardent leur ordre
//    de lecture : le signe
//    « % » a droite de « 60 », le point a droite du dernier mot, le point
//    median a droite de « précis ». Mesure par la position des glyphes
//    rendus (`getBoxesForSelection`), en francais (LTR) comme en arabe.
//
// Contre-epreuve : sur l'ancien code (6e2c91c4), le test 1 echoue si
// `lierTaillesFichier` est remplace par l'identite, et les tests 2 echouent
// en arabe.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_groupe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';

/// Les ressources de demonstration, titre court ecrit avec une espace
/// ORDINAIRE entre le nombre et l'unite (« 8,1 Mo ») : la donnee brute, telle
/// qu'un catalogue la livrerait, sans le point de formatage `tailleFichier`.
List<LibraryResource> _ressourcesBrutes() => <LibraryResource>[
  for (final (int i, RessourceDemo r) in DonneesClasseDemo.ressources.indexed)
    LibraryResource.depuisJson(<String, dynamic>{
      'id': 'brut-$i',
      'title': r.titre,
      'short_title': '${r.titre}, ${r.type}, ${r.nombre} ${r.unite}',
    }),
];

/// Monte [ecran] sous un routeur, a 320 px et texte x2, dans la locale
/// [langue] (l'arabe donne le sens RTL).
Future<void> _monter(
  WidgetTester tester,
  AppLocale langue,
  Widget Function() ecran,
) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, const Size(320, 6000), 1);
  final GoRouter routeur = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (BuildContext _, GoRouterState _) => ecran()),
    ],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// L'Espace Classe de demonstration du [role], par sa vraie route.
Future<void> _monterDemo(
  WidgetTester tester,
  AppLocale langue,
  RoleEntree role,
) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, const Size(320, 6000), 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoClasse(role, EtatDemoClasse.aVenir),
    routes: routesDemoClasse('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext c, Widget? app) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: app!,
            ),
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// L'observation du Controleur jusqu'au recapitulatif (etape 5).
Future<void> _jusquAuRecapitulatif(
  WidgetTester tester,
  AppLocale langue,
) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, const Size(320, 1400), 1);
  final CompteRenduEnSuspens visite = CompteRenduEnSuspens(
    seanceId: 'seance-A',
    classe: 'Classe Al-Fajr',
    debut: DateTime(2026, 9, 28, 16),
  );
  await tester.pumpWidget(
    hoteCapture(
      ObservationControlePage(seanceId: visite.seanceId),
      echelleTexte: 2,
      surcharges: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            visite.seanceId: visite,
          }),
        ),
        rosterControleProvider.overrideWith(
          (Ref _, String _) async => const <EleveRoster>[
            EleveRoster(id: 'e1', prenom: 'Mariam', initialeNom: 'S'),
          ],
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  await _toucher(
    tester,
    find.byKey(ObservationControlePage.cleNature(NatureObservation.aSuivre)),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
    ),
  );
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(
    tester,
    find.byKey(
      ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
    ),
  );
  await _toucher(tester, find.byKey(ObservationControlePage.cleEleve('e1')));
  await _toucher(tester, find.text(t.commun.continuer).last);
  await _toucher(tester, find.text(t.commun.continuer).last);
}

/// Le paragraphe rendu dont le texte contient [marque] (un seul).
RenderParagraph _paragraphe(WidgetTester tester, String marque) {
  final Set<RenderParagraph> trouves = <RenderParagraph>{
    for (final RenderParagraph p
        in tester.allRenderObjects.whereType<RenderParagraph>())
      if (p.attached && p.text.toPlainText().contains(marque)) p,
  };
  expect(trouves, hasLength(1), reason: 'Paragraphe « $marque »');
  return trouves.single;
}

/// La boite rendue du dernier [extrait] de [p] (une seule ligne).
TextBox _boite(RenderParagraph p, String extrait) {
  final String texte = p.text.toPlainText();
  final int debut = texte.lastIndexOf(extrait);
  expect(debut, isNonNegative, reason: '« $extrait » dans « $texte »');
  final List<TextBox> boites = p.getBoxesForSelection(
    TextSelection(baseOffset: debut, extentOffset: debut + extrait.length),
  );
  expect(boites, isNotEmpty);
  return boites.first;
}

/// Echoue si [suivant] ne s'affiche pas a droite de [precedent] dans le
/// paragraphe qui contient [marque] : une phrase francaise se lit de gauche
/// a droite, quelle que soit la langue de l'interface.
void _aDroiteDe(
  WidgetTester tester, {
  required String marque,
  required String precedent,
  required String suivant,
}) {
  final RenderParagraph p = _paragraphe(tester, marque);
  final TextBox avant = _boite(p, precedent);
  final TextBox apres = _boite(p, suivant);
  final double milieuAvant = (avant.top + avant.bottom) / 2;
  final bool memeLigne =
      milieuAvant >= apres.top && milieuAvant <= apres.bottom;
  expect(
    memeLigne ? apres.left >= avant.right - 1 : apres.top >= avant.bottom - 1,
    isTrue,
    reason:
        '« $suivant » doit suivre « $precedent » dans '
        '« ${p.text.toPlainText()} » (gauche a droite)',
  );
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  test('isolerSiAutreSens : seul un texte de l autre sens est isole', () {
    expect(sensDuTexte('Chapitre 1 · 60 %'), TextDirection.ltr);
    expect(sensDuTexte('60 % الفصل'), TextDirection.rtl);
    expect(sensDuTexte('60 %'), isNull);
    expect(
      isolerSiAutreSens('Chapitre 1 · 60 %', TextDirection.rtl),
      '\u2068Chapitre 1 · 60 %\u2069',
    );
    expect(
      isolerSiAutreSens('Chapitre 1 · 60 %', TextDirection.ltr),
      'Chapitre 1 · 60 %',
    );
    expect(isolerSiAutreSens('الفصل 1', TextDirection.rtl), 'الفصل 1');
    expect(isolerSiAutreSens('60 %', TextDirection.rtl), '60 %');
  });

  for (final AppLocale langue in AppLocale.values) {
    final String cas = '320 px x2, ${langue.languageCode}';

    testWidgets(
      'Espace Classe enseignant : une taille brute est liee a l ecran ($cas)',
      (WidgetTester tester) async {
        final List<LibraryResource> brutes = _ressourcesBrutes();
        // La donnee n'a aucune espace insecable : seul l'ecran peut la lier.
        for (final LibraryResource r in brutes) {
          expect(r.shortTitle, isNot(contains(' ')));
        }
        const String id = DonneesClasseDemo.groupeId;
        await _monter(
          tester,
          langue,
          () => ProviderScope(
            overrides: surchargesEnseignantDemo(EtatDemoClasse.aVenir),
            child: ProviderScope(
              overrides: <Override>[
                portCatalogueProvider.overrideWithValue(
                  CatalogueLocal(
                    ressources: brutes,
                    assignationsParGroupe: <String, List<String>>{
                      id: <String>[
                        for (final LibraryResource r in brutes) r.id,
                      ],
                    },
                  ),
                ),
              ],
              child: const FicheGroupePage(groupeId: id),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final Finder bloc = find.byType(BlocBibliotheque);
        expect(bloc, findsOneWidget);
        final ({List<String> mesurees, List<String> coupees}) r =
            mesurerTailles(tester, bloc);
        expect(r.mesurees, hasLength(3), reason: 'Trois tailles rendues');
        for (final String fiche in r.mesurees) {
          final String taille = fiche.substring(fiche.lastIndexOf(' : ') + 3);
          expect(
            taille,
            contains(' '),
            reason: 'Taille sans espace insecable a l ecran : $fiche',
          );
        }
        expect(r.coupees, isEmpty, reason: 'Une taille scindee');
      },
    );

    testWidgets(
      'Espace Classe enseignant : le texte francais se lit dans l ordre '
      '($cas)',
      (WidgetTester tester) async {
        await _monterDemo(tester, langue, RoleEntree.enseignant);
        _aDroiteDe(
          tester,
          marque: 'élèves sur',
          precedent: '3',
          suivant: 'élèves',
        );
        _aDroiteDe(tester, marque: 'Chapitre 1', precedent: '60', suivant: '%');
        _aDroiteDe(
          tester,
          marque: 'Chapitre 1',
          precedent: 'Chapitre',
          suivant: '60',
        );
      },
    );

    testWidgets(
      'Espace Classe eleve : le texte francais se lit dans l ordre ($cas)',
      (WidgetTester tester) async {
        await _monterDemo(tester, langue, RoleEntree.eleve);
        _aDroiteDe(
          tester,
          marque: 'Chapitre 1 ·',
          precedent: '60',
          suivant: '%',
        );
        // La capacite et le conseil d'appareil, libelles encore sans
        // traduction arabe.
        _aDroiteDe(
          tester,
          marque: 'élèves sur',
          precedent: '3',
          suivant: 'élèves',
        );
        _aDroiteDe(
          tester,
          marque: 'Tablette',
          precedent: 'charge',
          suivant: '.',
        );
      },
    );

    testWidgets('Observation : le recapitulatif se lit dans l ordre ($cas)', (
      WidgetTester tester,
    ) async {
      await _jusquAuRecapitulatif(tester, langue);
      final String question = t.controleur.observation.questionRecap;
      final String notice = t.controleur.compteRendu.notice;
      // Les libelles du Controleur n'ont pas encore de traduction arabe : le
      // test ne porte que sur ces phrases francaises.
      expect(question, endsWith('.'));
      expect(notice, endsWith('.'));
      _aDroiteDe(tester, marque: 'avant l', precedent: 'envoi', suivant: '.');
      _aDroiteDe(
        tester,
        marque: 'administration',
        precedent: 'administration',
        suivant: '.',
      );
      _aDroiteDe(tester, marque: 'Mariam', precedent: 'précis', suivant: '·');
      _aDroiteDe(tester, marque: 'Mariam', precedent: '·', suivant: 'Mariam');
      verifierEcranSansMotCoupe(tester);
    });
  }
}
