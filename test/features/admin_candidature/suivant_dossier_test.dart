// BE-SUIVANT (lot BE-1b, directeur, 16/11/2026) : « Je traite les dossiers en
// examen a la suite, sans revenir a la liste. » Un test par ligne du cahier.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/feuille_geste.dart';
import 'package:rewayah_academy/features/admin_candidature/navigation_dossier.dart';
import 'package:rewayah_academy/features/admin_candidature/suivant_dossier.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/monter_recrutement.dart';
import 'hote_candidature.dart';

/// Un port dont les voisins suivent une file de references, comme le serveur.
class PortFileVoisins extends FauxCandidaturesDirection {
  PortFileVoisins(
    this.file, {
    super.details,
    super.effetGeste,
    super.capacitesRendues,
  });

  final List<String> file;

  @override
  Future<VoisinsCandidature> voisins(
    String reference, {
    required FiltreCandidatures filtre,
    required TriCandidatures tri,
  }) async {
    appelsVoisins.add(reference);
    final int i = file.indexOf(reference);
    if (i < 0) return const VoisinsCandidature();
    return VoisinsCandidature(
      precedent: i > 0 ? file[i - 1] : null,
      suivant: i < file.length - 1 ? file[i + 1] : null,
      rang: i + 1,
      total: 176,
    );
  }
}

const List<String> _refs = <String>[
  'CAND-0000C1',
  'CAND-0000C2',
  'CAND-0000C3',
];

PortFileVoisins portFileTest({List<String> file = _refs}) => PortFileVoisins(
  file,
  capacitesRendues: capacitesGestes,
  details: <DetailCandidature>[
    for (final String id in <String>['c1', 'c2', 'c3'])
      detailTest(id: id, paiement: EtatVersement.compatible),
  ],
  effetGeste: (DemandeGeste d, DetailCandidature a) => a,
);

const String _adresseListe = '?depuis=liste&etat=enExamen';

Future<void> monterFileTest(
  WidgetTester tester,
  FauxCandidaturesDirection port, {
  String ouvert = 'c1',
  String requete = _adresseListe,
  double largeur = 390,
  TextDirection? direction,
  Map<String, String>? preferences,
  StockagePreferencesMemoire? stockage,
  List<Override> surcharges = const <Override>[],
}) async {
  await monterRecrutement(
    tester,
    chemin: Routes.adminPersonnesCandidature,
    depart:
        '${Routes.adminPersonnesCandidaturePour('CAND-0000${ouvert.toUpperCase()}')}$requete',
    ecran: (GoRouterState etat) {
      final String reference = etat.pathParameters['reference']!;
      return CandidatureDirectionPage(
        reference: reference,
        identifiant: reference.substring(reference.length - 2).toLowerCase(),
        requete: etat.uri.queryParameters,
      );
    },
    autres: const <String>[Routes.adminPersonnesCandidatures],
    surcharges: <Override>[
      portCandidaturesDirectionProvider.overrideWithValue(port),
      horlogeFormulairesProvider.overrideWithValue(() => jourDuTest),
      stockagePreferencesProvider.overrideWithValue(
        stockage ?? StockagePreferencesMemoire(preferences),
      ),
      ...surcharges,
    ],
    largeur: largeur,
    hauteur: 3000,
    direction: direction,
  );
}

Future<void> tapperFileTest(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await laisser(tester, fois: 2);
  await tester.tap(f, warnIfMissed: false);
  await laisser(tester);
}

Future<void> accepterFileTest(WidgetTester tester) async {
  await tapperFileTest(
    tester,
    find.byKey(
      BarreDecisionDossier.cleBouton(GesteCandidature.admettreVerifications),
    ),
  );
  await tapperFileTest(tester, find.byKey(FeuilleGeste.cleValider));
}

String _position(WidgetTester tester) =>
    t.recrutement.suivant.position(rang: 1, total: 176);

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.en);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('voisins dans l\'etage 1', () {
    testWidgets('au debut : « 1 sur 176 », seule la fleche suivante', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest());
      expect(find.byKey(NavigationFileDossier.cle), findsOneWidget);
      expect(find.text(_position(tester)), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-precedent')), findsNothing);
      expect(find.byKey(const ValueKey<String>('nav-suivant')), findsOneWidget);
    });

    // GESTES-RAISON (directeur, 16/11/2026, capture de production en arabe) :
    // chaque fleche sur son bord de la carte de profil, le compteur au centre.
    for (final (String nom, AppLocale langue, TextDirection? sens)
        in <(String, AppLocale, TextDirection?)>[
          ('fr', AppLocale.fr, null),
          ('ar', AppLocale.ar, TextDirection.rtl),
        ]) {
      testWidgets('360 $nom : fleches aux deux bords, compteur au centre', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        await monterFileTest(
          tester,
          portFileTest(),
          ouvert: 'c2',
          largeur: 360,
          direction: sens,
        );
        final Rect nav = tester.getRect(find.byKey(NavigationFileDossier.cle));
        final Rect avant = tester.getRect(
          find.byKey(const ValueKey<String>('nav-precedent')),
        );
        final Rect apres = tester.getRect(
          find.byKey(const ValueKey<String>('nav-suivant')),
        );
        final Rect position = tester.getRect(
          find.byKey(const ValueKey<String>('nav-position')),
        );
        // Les deux fleches touchent les bords de la barre, une de chaque cote.
        final bool arabe = sens == TextDirection.rtl;
        final Rect debut = arabe ? apres : avant;
        final Rect fin = arabe ? avant : apres;
        expect(
          <double>[avant.left, apres.left].reduce((a, b) => a < b ? a : b),
          closeTo(nav.left, 1),
        );
        expect(
          <double>[avant.right, apres.right].reduce((a, b) => a > b ? a : b),
          closeTo(nav.right, 1),
        );
        expect(debut.left, lessThan(position.left));
        expect(fin.right, greaterThan(position.right));
        // Le compteur est au milieu de la barre.
        expect(position.center.dx, closeTo(nav.center.dx, 1));
        // La cible reste de 48 au moins.
        expect(avant.width, greaterThanOrEqualTo(48));
        expect(apres.width, greaterThanOrEqualTo(48));
        // Et elles ne sont plus rapprochees : plus de 150 points entre elles.
        expect((apres.center.dx - avant.center.dx).abs(), greaterThan(150));
      });
    }

    testWidgets('au milieu : les deux fleches', (WidgetTester tester) async {
      await monterFileTest(tester, portFileTest(), ouvert: 'c2');
      expect(
        find.text(t.recrutement.suivant.position(rang: 2, total: 176)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('nav-precedent')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('nav-suivant')), findsOneWidget);
    });

    testWidgets('a la fin : seule la fleche precedente', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest(), ouvert: 'c3');
      expect(
        find.byKey(const ValueKey<String>('nav-precedent')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('nav-suivant')), findsNothing);
    });

    testWidgets('sans file (dossier ouvert d\'ailleurs) : rien', (
      WidgetTester tester,
    ) async {
      final PortFileVoisins port = portFileTest();
      await monterFileTest(tester, port, requete: '');
      expect(find.byType(BarrePrecedentSuivant), findsNothing);
      expect(find.byKey(ReglagePasserAuSuivant.cleInterrupteur), findsNothing);
      expect(port.appelsVoisins, isEmpty);
    });

    testWidgets(
      '« suivant » remplace le dossier : « retour » mene a la liste',
      (WidgetTester tester) async {
        await monterFileTest(tester, portFileTest());
        await tapperFileTest(
          tester,
          find.byKey(const ValueKey<String>('nav-suivant')),
        );
        expect(
          find.text(t.recrutement.suivant.position(rang: 2, total: 176)),
          findsOneWidget,
        );
        final GoRouter routeur = GoRouter.of(
          tester.element(find.byType(CandidatureDirectionPage)),
        );
        // Remplace, n'empile pas : rien a depiler sous le dossier ouvert.
        expect(routeur.canPop(), isFalse);
      },
    );
  });

  group('apres une decision', () {
    testWidgets('la phrase, puis le dossier suivant s\'ouvre seul', (
      WidgetTester tester,
    ) async {
      final PortFileVoisins port = portFileTest();
      await monterFileTest(tester, port);
      await accepterFileTest(tester);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsOneWidget);
      expect(
        find.text(t.recrutement.suivant.decisionEnregistree),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
      await laisser(tester);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsNothing);
      expect(
        find.text(t.recrutement.suivant.position(rang: 2, total: 176)),
        findsOneWidget,
      );
    });

    testWidgets('« Rester sur ce dossier » : le suivant ne s\'ouvre pas', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest());
      await accepterFileTest(tester);
      await tapperFileTest(tester, find.byKey(PassageAuSuivant.cleRester));
      await tester.pump(const Duration(seconds: 5));
      await laisser(tester);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsNothing);
      expect(find.text(_position(tester)), findsOneWidget);
    });

    testWidgets('reglage coupe : aucun passage, et il est retenu', (
      WidgetTester tester,
    ) async {
      final StockagePreferencesMemoire stock = StockagePreferencesMemoire();
      await monterFileTest(tester, portFileTest(), stockage: stock);
      await tapperFileTest(
        tester,
        find.byKey(ReglagePasserAuSuivant.cleInterrupteur),
      );
      expect(await stock.lire(clefPasserAuSuivant), 'false');
      await accepterFileTest(tester);
      await tester.pump(const Duration(seconds: 5));
      await laisser(tester);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsNothing);
      expect(find.text(_position(tester)), findsOneWidget);
    });

    testWidgets('reglage deja coupe sur l\'appareil : restaure', (
      WidgetTester tester,
    ) async {
      await monterFileTest(
        tester,
        portFileTest(),
        preferences: <String, String>{clefPasserAuSuivant: 'false'},
      );
      await laisser(tester);
      final Switch s = tester.widget<Switch>(
        find.byKey(ReglagePasserAuSuivant.cleInterrupteur),
      );
      expect(s.value, isFalse);
    });

    testWidgets('dernier dossier : la phrase de fin et le chemin de la liste', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest(), ouvert: 'c3');
      await accepterFileTest(tester);
      expect(find.byKey(PassageAuSuivant.cleFin), findsOneWidget);
      expect(find.text(t.recrutement.suivant.fin), findsOneWidget);
      await tapperFileTest(tester, find.byKey(PassageAuSuivant.cleListe));
      expect(find.byKey(PassageAuSuivant.cleFin), findsNothing);
    });

    testWidgets('sans file : aucune phrase de passage apres une decision', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest(), requete: '');
      await accepterFileTest(tester);
      expect(find.byKey(PassageAuSuivant.cleEnCours), findsNothing);
      expect(find.byKey(PassageAuSuivant.cleFin), findsNothing);
    });
  });

  group('clavier (ordinateur)', () {
    testWidgets('→ ouvre le suivant, ← le precedent', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest(), largeur: 1366);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await laisser(tester);
      expect(
        find.text(t.recrutement.suivant.position(rang: 2, total: 176)),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await laisser(tester);
      expect(find.text(_position(tester)), findsOneWidget);
    });

    testWidgets('en arabe, les fleches suivent le sens de la lecture', (
      WidgetTester tester,
    ) async {
      await LocaleSettings.setLocale(AppLocale.ar);
      await monterFileTest(
        tester,
        portFileTest(),
        largeur: 1366,
        direction: TextDirection.rtl,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await laisser(tester);
      expect(
        find.text(t.recrutement.suivant.position(rang: 2, total: 176)),
        findsOneWidget,
      );
    });

    testWidgets('jamais quand le curseur est dans un champ de texte', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest(), largeur: 1366);
      // Un vrai champ pose dans la page (le dossier replie n'en a pas).
      Overlay.of(tester.element(find.byType(CandidatureDirectionPage))).insert(
        OverlayEntry(
          builder: (BuildContext _) =>
              const Material(child: TextField(key: ValueKey<String>('champ'))),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('champ')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await laisser(tester);
      expect(find.text(_position(tester)), findsOneWidget);
    });

    testWidgets('au telephone : pas de raccourci clavier', (
      WidgetTester tester,
    ) async {
      await monterFileTest(tester, portFileTest());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await laisser(tester);
      expect(find.text(_position(tester)), findsOneWidget);
    });
  });
}
