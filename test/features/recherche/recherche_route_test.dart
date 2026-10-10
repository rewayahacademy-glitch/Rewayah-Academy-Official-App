// RECH-1 : la route unique `/recherche`, sur le VRAI routeur, pour chaque
// role, avec le port de demonstration (spec RECH-03 §1, §2, §4.1, §5, §10.3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/moteur_recherche_demo.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

const String _nb = ' ';

Future<GoRouter> _monter(
  WidgetTester tester, {
  AppRole role = AppRole.guardian,
  String depart = Routes.recherche,
  List<MoteurRechercheDomaine>? moteurs,
  bool avecMoteurs = true,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
  ThemeMode theme = ThemeMode.light,
  List<Override> surcharges = const <Override>[],
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  taille: taille,
  echelle: echelle,
  direction: direction,
  themeMode: theme,
  surcharges: <Override>[
    if (avecMoteurs)
      moteursRechercheProvider.overrideWithValue(
        moteurs ?? moteursDemoRecherche(),
      ),
    ...surcharges,
  ],
);

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byType(TextField), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('une route, tous les roles', () {
    for (final AppRole role in AppRole.values) {
      testWidgets('${role.name} ouvre /recherche et y reste', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _monter(tester, role: role);
        expect(lieu(routeur), Routes.recherche);
        expect(find.text('Rechercher'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sans session : la connexion, jamais la recherche', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.recherche,
        source: FausseSourceSession(),
      );
      expect(lieu(routeur), startsWith(Routes.connexion));
    });

    testWidgets('l\'espace de la session decide, pas l\'adresse', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        role: AppRole.guardian,
        depart: Routes.rechercheAvec(espace: 'administration'),
      );
      expect(find.text('Dans votre espace Tuteur'), findsOneWidget);
      expect(find.text('Dans votre espace Administration'), findsNothing);
    });
  });

  group('rien ne part sans texte', () {
    testWidgets('champ vide : l\'invitation, aucune requete', (
      WidgetTester tester,
    ) async {
      final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
      await _monter(tester, moteurs: moteurs);
      expect(find.text('Rechercher dans votre espace'), findsWidgets);
      expect(
        moteurs.every(
          (MoteurRechercheDomaine m) => (m as MoteurRechercheDemo).appels == 0,
        ),
        isTrue,
      );
      await _chercher(tester, 'al');
      expect(find.text('Saisissez au moins 3 caractères.'), findsOneWidget);
      expect(
        moteurs.every(
          (MoteurRechercheDomaine m) => (m as MoteurRechercheDemo).appels == 0,
        ),
        isTrue,
      );
    });
  });

  group('resultats', () {
    testWidgets('la famille voit Classes puis Supports, 5 au plus, sans '
        'total ni Eleves', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _chercher(tester, 'fatiha');
      expect(find.text('Résultats pour «${_nb}fatiha$_nb»'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      // Le domaine reserve a l'enseignant n'existe pas pour la famille.
      expect(find.widgetWithText(SectionHeader, 'Élèves'), findsNothing);
      expect(find.byType(SettingRow), findsNWidgets(10));
      expect(find.text('Voir davantage'), findsNWidgets(2));
      // La requete ne passe jamais par l'adresse.
      expect(lieu(routeur), Routes.recherche);
    });

    testWidgets('l\'enseignant voit en plus la projection pedagogique', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role: AppRole.teacher, depart: Routes.recherche);
      await _chercher(tester, 'mariam');
      expect(find.widgetWithText(SectionHeader, 'Élèves'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsNothing);
    });

    testWidgets('un resultat sans route reelle n\'est pas un bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role: AppRole.teacher);
      await _chercher(tester, 'fatiha');
      final Iterable<SettingRow> lignes = tester.widgetList<SettingRow>(
        find.byType(SettingRow),
      );
      // Classes de l'enseignant : sa liste existe ; supports et eleves :
      // aucune route ouverte a son espace.
      final Iterable<SettingRow> cliquables = lignes.where(
        (SettingRow l) => l.onPress != null,
      );
      expect(cliquables.length, 5);
      expect(lignes.length, 10);
    });

    testWidgets('« Voir davantage » charge la page suivante sans doublon', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _chercher(tester, 'fatiha');
      await tester.ensureVisible(find.text('Voir davantage').first);
      await tester.tap(find.text('Voir davantage').first);
      await tester.pump();
      await tester.pump();
      expect(
        tester.widgetList<SettingRow>(find.byType(SettingRow)).length,
        greaterThan(10),
      );
    });

    testWidgets('un resultat ouvre sa route canonique, retour aux resultats', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester);
      await _chercher(tester, 'fatiha');
      await tester.tap(find.byType(SettingRow).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // Poussee au-dessus de la recherche : le retour la retrouve intacte.
      expect(
        routeur
            .routerDelegate
            .currentConfiguration
            .matches
            .last
            .matchedLocation,
        startsWith('/tuteur/classes/classe-demo-'),
      );
      routeur.pop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(lieu(routeur), Routes.recherche);
      expect(find.text('Résultats pour «${_nb}fatiha$_nb»'), findsOneWidget);
    });
  });

  group('etats', () {
    testWidgets('aucun moteur : « Recherche indisponible pour le moment. »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, avecMoteurs: false);
      await _chercher(tester, 'fatiha');
      expect(
        find.text('Recherche indisponible pour le moment.'),
        findsOneWidget,
      );
      expect(find.text('Aucun résultat pour cette recherche.'), findsNothing);
    });

    testWidgets('vide confirme : « Aucun résultat » et « Modifier »', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _chercher(tester, 'zzzzzz');
      expect(find.text('Aucun résultat pour cette recherche.'), findsOneWidget);
      expect(find.text('Modifier la recherche'), findsOneWidget);
    });

    testWidgets('domaines en panne : jamais « Aucun résultat »', (
      WidgetTester tester,
    ) async {
      final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
      for (final MoteurRechercheDomaine m in moteurs) {
        (m as MoteurRechercheDemo).comportement = ComportementDemo.indisponible;
      }
      await _monter(tester, moteurs: moteurs);
      await _chercher(tester, 'fatiha');
      expect(
        find.text('Impossible d\'effectuer la recherche.'),
        findsOneWidget,
      );
      expect(find.text('Aucun résultat pour cette recherche.'), findsNothing);
    });

    testWidgets('un domaine en panne, l\'autre repond : partiel', (
      WidgetTester tester,
    ) async {
      final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
      (moteurs.last as MoteurRechercheDemo).comportement =
          ComportementDemo.indisponible;
      (moteurs[1] as MoteurRechercheDemo).comportement =
          ComportementDemo.indisponible;
      await _monter(tester, moteurs: moteurs);
      await _chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsOneWidget);
      expect(
        find.text('La recherche dans ce domaine est indisponible.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer ce domaine'), findsOneWidget);
    });

    testWidgets('hors ligne : aucune requete, le bloc le dit sans « hors '
        'ligne » redit', (WidgetTester tester) async {
      final List<MoteurRechercheDomaine> moteurs = moteursDemoRecherche();
      await monterRouteur(
        tester,
        Routes.recherche,
        surcharges: <Override>[
          moteursRechercheProvider.overrideWithValue(moteurs),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ],
      );
      await _chercher(tester, 'fatiha');
      expect(
        find.text('La recherche en ligne est indisponible.'),
        findsOneWidget,
      );
      expect(
        moteurs.every(
          (MoteurRechercheDomaine m) => (m as MoteurRechercheDemo).appels == 0,
        ),
        isTrue,
      );
    });
  });
}
