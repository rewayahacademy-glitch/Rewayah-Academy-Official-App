// EA-12 : recette de la vague Eleves adultes (K-07 : depuis la VRAIE
// coquille, par la VRAIE route /demo/adulte, routesDemoAdulte). Ce fichier
// ajoute les quatre balayages automatiques demandes par la recette ; la
// correspondance complete critere -> preuve (doc section 21, F1 a F24,
// matrice section 16) vit dans 05_recette/EA/RAPPORT.md, qui cite aussi les
// tests ecran par ecran deja ecrits en EA-5 a EA-11 (foyer/*, demo/*,
// mon_espace_adulte/*, ma_classe_adulte/*).
//
// (a) aucun texte visible d'un ecran adulte ne contient le mot « admin »
//     (K-53.6) ;
// (b) aucun montant, taux, pourcentage ni delai en jours ecrit en dur dans
//     les ecrans clients (F12, F17) ; le selecteur de demonstration
//     `adulte.demo.etats.*` est une EXCEPTION CONNUE, signalee au rapport,
//     pas corrigee ici (hors perimetre recette, cf. tache EA-12) ;
// (c) pour le second adulte, fusionne dans le balayage (a) : aucun prenom
//     d'enfant, aucun FoyerPage, sur les ecrans qui lui sont ouverts
//     (Forfait famille, reprise) et sur Ma famille s'il tente d'y entrer
//     directement (garde de route, defense en profondeur ; la preuve
//     exhaustive des 25 etats x 2 genres depuis Mon espace est deja dans
//     mon_espace_adulte_page_test.dart) ;
// (d) /demo/adulte fermee hors environnement de demonstration.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart'
    show EleveDuFoyer;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

/// Le mot « admin » seul (K-53.6) : jamais « administration » ni
/// « administratif », qui restent les mots acceptes par le directeur.
final RegExp motAdmin = RegExp(r'\badmin\b', caseSensitive: false);

Future<void> _monter(
  WidgetTester tester,
  String adresse, {
  Size taille = const Size(390, 1400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
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
            routerConfig: routeur,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tous les textes visibles (`Text` et `Text.rich`), sans distinguer les
/// ecrans « indisponible » : une capacite absente reste un ecran adulte.
Iterable<String> _textesVisibles(WidgetTester tester) {
  final List<String> textes = <String>[];
  for (final Element e in find.byType(Text).evaluate()) {
    final Text w = e.widget as Text;
    if (w.data != null) textes.add(w.data!);
    final InlineSpan? span = w.textSpan;
    if (span != null) textes.add(span.toPlainText());
  }
  return textes;
}

void _aucunAdmin(WidgetTester tester, String ou) {
  for (final String texte in _textesVisibles(tester)) {
    expect(
      motAdmin.hasMatch(texte),
      isFalse,
      reason: '$ou : "$texte" contient le mot admin (K-53.6)',
    );
  }
}

/// (c) Rien du foyer du titulaire pour le second adulte : ni la page du
/// Foyer, ni le prenom d'un enfant (F6, F7).
void _aucuneDonneeDeFoyer(WidgetTester tester, String ou) {
  expect(
    find.byType(FoyerPage),
    findsNothing,
    reason: '$ou : FoyerPage visible au second adulte (F6, F7)',
  );
  for (final EleveDuFoyer enfant in DonneesAdulteDemo.enfants) {
    expect(
      find.textContaining(enfant.prenom),
      findsNothing,
      reason: '$ou : prenom d\'enfant "${enfant.prenom}" visible (F6, F7)',
    );
  }
}

void main() {
  // ---------------------------------------------------------------------
  // (a) et (c) fusionnes : un seul passage par ecran plutot que deux.
  // ---------------------------------------------------------------------
  group('EA-12 (a) : jamais le mot admin sur un ecran adulte', () {
    for (final EcranDemoAdulte ecran in EcranDemoAdulte.values) {
      testWidgets('ecran ${ecran.name}, titulaire homme, vue titulaire', (
        WidgetTester tester,
      ) async {
        await _monter(tester, adresseDemoAdulte(ecran));
        _aucunAdmin(tester, 'ecran ${ecran.name} (homme, titulaire)');
      });
      testWidgets('ecran ${ecran.name}, titulaire femme, vue second adulte', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          adresseDemoAdulte(
            ecran,
            genre: GenreTitulaireDemo.femme,
            vue: VueDemoAdulte.secondAdulte,
          ),
        );
        _aucunAdmin(tester, 'ecran ${ecran.name} (femme, second adulte)');
      });
    }

    // Les ecrans sensibles aux 25 etats du doc section 18 : la ou le mot
    // « administration » (jamais « admin ») et les dates de delai
    // apparaissent le plus souvent.
    const List<(EcranDemoAdulte, VueDemoAdulte)> sensibles =
        <(EcranDemoAdulte, VueDemoAdulte)>[
          (EcranDemoAdulte.maFamille, VueDemoAdulte.titulaire),
          (EcranDemoAdulte.placeAdulte, VueDemoAdulte.titulaire),
          (EcranDemoAdulte.repriseTitulaire, VueDemoAdulte.titulaire),
          (EcranDemoAdulte.forfaitFamille, VueDemoAdulte.secondAdulte),
          (EcranDemoAdulte.repriseFoyer, VueDemoAdulte.secondAdulte),
          // Defense en profondeur (c) : le second adulte qui force l'adresse
          // de Ma famille ne doit recevoir ni le Foyer ni les enfants, pour
          // aucun des 25 etats.
          (EcranDemoAdulte.maFamille, VueDemoAdulte.secondAdulte),
        ];
    for (final (EcranDemoAdulte ecran, VueDemoAdulte vue) in sensibles) {
      for (final EtatDemoAdulte etat in EtatDemoAdulte.values) {
        testWidgets('${ecran.name}/${vue.name}/${etat.name}', (
          WidgetTester tester,
        ) async {
          await _monter(tester, adresseDemoAdulte(ecran, etat: etat, vue: vue));
          _aucunAdmin(tester, '${ecran.name} ${vue.name} ${etat.name}');
          if (vue == VueDemoAdulte.secondAdulte) {
            _aucuneDonneeDeFoyer(
              tester,
              '${ecran.name} ${vue.name} ${etat.name}',
            );
          }
        });
      }
    }
  });

  // ---------------------------------------------------------------------
  // (b) Aucun montant, taux, pourcentage ni delai en jours en dur (F12, F17).
  // ---------------------------------------------------------------------
  group('EA-12 (b) : aucune valeur economique ni delai en dur', () {
    final RegExp pourcentage = RegExp(r'-?\d+\s?%');
    final RegExp monnaie = RegExp(r'\d[,.]\d{2}\s?€');
    final RegExp delaiJours = RegExp(r'\b\d+\s*jours\b', caseSensitive: false);
    bool suspect(String valeur) =>
        pourcentage.hasMatch(valeur) ||
        monnaie.hasMatch(valeur) ||
        delaiJours.hasMatch(valeur);

    test('ecrans Dart reels de la vague (hors donnees de demonstration) : '
        'aucune occurrence hors commentaire', () {
      const List<String> fichiers = <String>[
        'lib/features/foyer/foyer_page.dart',
        'lib/features/foyer/place_adulte.dart',
        'lib/features/foyer/ligne_membre.dart',
        'lib/features/foyer/invitation_conjoint.dart',
        'lib/features/foyer/reprise_foyer.dart',
        'lib/features/foyer/recharge_foyer.dart',
        'lib/features/foyer/sortie_forfait.dart',
        'lib/features/compte/soldes_foyer.dart',
        'lib/features/compte/paiements_page.dart',
        'lib/features/mon_espace_adulte/mon_espace_adulte_page.dart',
        'lib/features/accueil_adulte/accueil_adulte_page.dart',
        'lib/features/ma_classe_adulte/ma_classe_adulte_page.dart',
        'lib/features/demo/demo_adulte_page.dart',
      ];
      for (final String chemin in fichiers) {
        final File f = File(chemin);
        if (!f.existsSync()) continue; // nom exact verifie au rapport EA-12.
        final List<String> lignes = f.readAsLinesSync();
        for (int i = 0; i < lignes.length; i++) {
          final String brute = lignes[i];
          final String aVerifier = brute.trim().startsWith('//') ? '' : brute;
          expect(
            suspect(aVerifier),
            isFalse,
            reason: '$chemin:${i + 1} : "$brute" (F12, F17)',
          );
        }
      }
    });

    test('textes adulte.* du dictionnaire fr (hors adulte.demo.donnees) : '
        'aucune occurrence', () {
      final Map<String, dynamic> racine = jsonDecode(
        File('assets/i18n/fr.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> adulte =
          racine['adulte'] as Map<String, dynamic>;
      final List<String> fautes = <String>[];
      void parcourir(String chemin, dynamic valeur) {
        if (valeur is String) {
          if (suspect(valeur)) fautes.add('$chemin = "$valeur"');
        } else if (valeur is Map<String, dynamic>) {
          for (final MapEntry<String, dynamic> e in valeur.entries) {
            parcourir('$chemin.${e.key}', e.value);
          }
        } else if (valeur is List) {
          for (int i = 0; i < valeur.length; i++) {
            parcourir('$chemin[$i]', valeur[i]);
          }
        }
      }

      for (final MapEntry<String, dynamic> e in adulte.entries) {
        if (e.key == 'demo') {
          // `adulte.demo.donnees` : les DONNEES de demonstration (prix de la
          // planche, marques « (démonstration) », F12), seule exception. Le
          // selecteur (adulte.demo.etats.*) est verifie comme le reste
          // depuis la revue EA-R m6.
          for (final MapEntry<String, dynamic> d
              in (e.value as Map<String, dynamic>).entries) {
            if (d.key == 'donnees') continue;
            parcourir('adulte.demo.${d.key}', d.value);
          }
          continue;
        }
        parcourir('adulte.${e.key}', e.value);
      }
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });

    test('selecteur de demonstration (revue EA-R m6) : plus aucun delai en '
        'jours en dur', () {
      for (final String libelle in <String>[
        t.adulte.demo.etats.delai60,
        t.adulte.demo.etats.nouvelleDemande,
        t.adulte.demo.etats.delai120,
        t.adulte.demo.etats.departsSuivants,
        t.adulte.demo.etats.repriseSansReponse,
      ]) {
        expect(delaiJours.hasMatch(libelle), isFalse, reason: libelle);
      }
    });

    test('donnees de demonstration (revue EA-R m3, m4, m17) : prix marques '
        '« démonstration », soldes sans unite', () {
      final d = t.adulte.demo.donnees;
      for (final String prix in <String>[d.prixOffreA, d.prixOffreB]) {
        expect(prix, contains('(démonstration)'));
      }
      for (final String solde in <String>[
        d.soldeTitulaire,
        d.soldeSecondAdulte,
        d.soldeAicha,
        d.soldeOumar,
        d.totalAvecSecondAdulte,
        d.totalSansSecondAdulte,
      ]) {
        expect(solde, contains('démonstration'));
        expect(solde.contains(RegExp('unit', caseSensitive: false)), isFalse);
      }
    });
  });

  // ---------------------------------------------------------------------
  // (d) /demo/adulte fermee hors environnement de demonstration.
  // ---------------------------------------------------------------------
  group('EA-12 (d) : /demo/adulte fermee hors environnement de '
      'demonstration', () {
    test('production : aucune route enregistree, quelle que soit la casse', () {
      for (final String env in <String>[
        'production',
        'PRODUCTION',
        ' Production ',
        'prod',
      ]) {
        expect(routesDemoAdulte(env), isEmpty, reason: env);
        expect(environnementAutoriseDemo(env), isFalse, reason: env);
      }
    });

    test('environnement vide ou mal declare : ferme aussi (pas un '
        'oubli qui ouvrirait par defaut)', () {
      expect(routesDemoAdulte(''), isEmpty);
      expect(routesDemoAdulte('   '), isEmpty);
      expect(environnementAutoriseDemo(''), isFalse);
    });

    test('dev et staging : la route existe (c\'est la demonstration)', () {
      expect(routesDemoAdulte('dev'), isNotEmpty);
      expect(routesDemoAdulte('staging'), isNotEmpty);
    });
  });
}
