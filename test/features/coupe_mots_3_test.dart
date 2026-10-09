// COUPE-MOTS-3 (revues BLOC-BIB-1b-R, observations 2 et 3, et
// CTRL-ROSTER-C7-1b-R, reserve 1) : trois mots coupes a 320 px, texte x2.
//
// 1. « Chapit / re 1 » dans la ligne « Progression de la Classe » de
//    l'Espace Classe enseignant (Interface guidee) : le texte n'avait que la
//    moitie de la ligne, la barre prenant l'autre. Quand son mot le plus long
//    n'y tient pas, la barre passe dessous et le texte prend toute la ligne.
// 2. « 8,1 / Mo » : le nombre et l'unite d'une taille de fichier sont lies
//    par une espace insecable, au point de formatage partage
//    (`lib/core/i18n/taille_fichier.dart`).
// 3. « Vérifiez votre obse / rvation avant l'envoi. » : la question d'une
//    page de parcours (`PageParcours`) passe a la ligne entre les mots
//    (`TexteSansCoupure`).
//
// Chaque cas : 320 px, texte x2, francais (LTR) et arabe (RTL), Interface
// standard et Interface guidee. Contre-epreuve : sur l'ancien code
// (4207c357), les tests 1, 2 et 3 echouent en nommant le mot ou la taille.

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
import 'package:rewayah_academy/core/i18n/taille_fichier.dart';
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart'
    show EtatDemoClasse;
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/emplacements_groupe.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';

const List<InterfaceMode> _interfaces = <InterfaceMode>[
  InterfaceMode.standard,
  InterfaceMode.enfant,
];

String _nomInterface(InterfaceMode i) =>
    i == InterfaceMode.enfant ? 'guidee' : 'standard';

/// L'Espace Classe enseignant de demonstration, a [largeur] px et texte x2,
/// dans la vraie locale [langue] (l'arabe donne le sens RTL).
Future<void> _monterEspaceClasse(
  WidgetTester tester,
  AppLocale langue,
  InterfaceMode interface,
) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  fixerVueCapture(tester, const Size(320, 6000), 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoClasse(
      RoleEntree.enseignant,
      EtatDemoClasse.aVenir,
    ),
    routes: routesDemoClasse('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.pour(interface, Brightness.light),
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

/// L'observation du Controleur jusqu'au recapitulatif (etape 5), a 320 px
/// et texte x2, dans la locale [langue].
Future<void> _jusquAuRecapitulatif(
  WidgetTester tester,
  AppLocale langue,
  InterfaceMode interface,
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
      interfaceMode: interface,
      surcharges: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            visite.seanceId: visite,
          }),
        ),
        rosterControleProvider.overrideWith(
          (Ref _) async => const <EleveRoster>[
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
  // Texte facultatif pour « A suivre ».
  await _toucher(tester, find.text(t.commun.continuer).last);
}

/// Les pourcentages (« 60 % ») des paragraphes contenant [dans] qui
/// occupent plus d'une ligne. Echoue si aucun n'est rendu.
List<String> _pourcentagesCoupes(WidgetTester tester, String dans) {
  final RegExp motif = RegExp(r'\d+[ \u00A0\u202F]*%');
  final List<String> coupes = <String>[];
  int mesures = 0;
  for (final RenderParagraph p
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final String texte = p.text.toPlainText();
    if (!texte.contains(dans)) continue;
    for (final RegExpMatch m in motif.allMatches(texte)) {
      mesures++;
      final Set<double> lignes = <double>{
        for (final TextBox b in p.getBoxesForSelection(
          TextSelection(baseOffset: m.start, extentOffset: m.end),
        ))
          ((b.top + b.bottom) / 2).roundToDouble(),
      };
      if (lignes.length > 1) coupes.add('$texte : ${m.group(0)}');
    }
  }
  expect(mesures, greaterThan(0), reason: 'Aucun pourcentage rendu');
  return coupes;
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // La traduction arabe est differee : chargee hors du temps simule.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('taille de fichier : nombre et unite insecables', () {
    test('tailleFichier lie le nombre a l unite', () {
      expect(tailleFichier('8,1', 'Mo'), '8,1\u00A0Mo');
      expect(tailleFichier('640', 'Ko'), '640\u00A0Ko');
    });

    test('lierTaillesFichier : seules les tailles sont liees', () {
      expect(
        lierTaillesFichier('Récitation, chapitre 1, Audio, 8,1 Mo'),
        'Récitation, chapitre 1, Audio, 8,1\u00A0Mo',
      );
      expect(lierTaillesFichier('PDF, 640 Ko'), 'PDF, 640\u00A0Ko');
      expect(lierTaillesFichier('Fichier de 3 MB'), 'Fichier de 3\u00A0MB');
      // Ni un mot qui commence par une unite, ni un texte sans taille.
      expect(lierTaillesFichier('Chapitre 1 Moise'), 'Chapitre 1 Moise');
      expect(lierTaillesFichier('Groupe 2 · 60 %'), 'Groupe 2 · 60 %');
      expect(lierTaillesFichier(''), '');
    });

    test('messages de refus de photo : « {taille} Mo » insecable', () {
      expect(t.kyc.tropVolumineux(taille: '8'), contains('8\u00A0Mo'));
      expect(
        t.ficheEleve.informations.tropLourde(taille: '4'),
        contains('4\u00A0Mo'),
      );
      expect(
        t.tuteur.reglages.photoTropLourde(taille: '4'),
        contains('4\u00A0Mo'),
      );
    });
  });

  for (final AppLocale langue in AppLocale.values) {
    for (final InterfaceMode interface in _interfaces) {
      final String cas =
          '320 px x2, ${langue.languageCode}, ${_nomInterface(interface)}';

      testWidgets('Espace Classe enseignant : aucun mot coupe ($cas)', (
        WidgetTester tester,
      ) async {
        await _monterEspaceClasse(tester, langue, interface);
        expect(tester.takeException(), isNull);
        // La ligne de progression est montee et mesuree.
        expect(find.textContaining('Chapitre 1'), findsWidgets);
        expect(
          motsCoupes(
            tester,
            find.byType(Scaffold),
            // Les cartes de la classe (CARTES-PERSO-1b) montrent a
            // l'enseignant l'adresse d'une carte : un seul « mot » sans
            // espace, plus large que la colonne a 320 px et texte x2, qui
            // passe forcement a la ligne et se lit en entier (meme exception
            // que cartes_classe_test.dart).
            exceptions: <String>{
              isolerSens('https://rewayah.academy/demo/recitation'),
            },
          ),
          isEmpty,
          reason: 'Un mot coupe ou tronque',
        );
        // Le pourcentage reste entier : « 60 / % » n'est pas plus lisible
        // que « Chapit / re » (le texte, desormais sur toute la ligne, ne
        // doit pas le scinder).
        expect(
          _pourcentagesCoupes(tester, 'Chapitre 1'),
          isEmpty,
          reason: 'Un pourcentage scinde',
        );
      });

      testWidgets('Espace Classe enseignant : tailles sur une ligne ($cas)', (
        WidgetTester tester,
      ) async {
        await _monterEspaceClasse(tester, langue, interface);
        final ({List<String> mesurees, List<String> coupees}) r =
            mesurerTailles(tester, find.byType(BlocBibliotheque));
        expect(r.mesurees, hasLength(3), reason: 'Trois tailles rendues');
        expect(r.coupees, isEmpty, reason: 'Une taille scindee');
      });

      testWidgets('Observation : le titre du recapitulatif ($cas)', (
        WidgetTester tester,
      ) async {
        await _jusquAuRecapitulatif(tester, langue, interface);
        // En arabe, la phrase francaise est isolee (COUPE-MOTS-3b).
        expect(
          find.textContaining(t.controleur.observation.questionRecap),
          findsOneWidget,
        );
        verifierEcranSansMotCoupe(tester);
      });
    }
  }
}
