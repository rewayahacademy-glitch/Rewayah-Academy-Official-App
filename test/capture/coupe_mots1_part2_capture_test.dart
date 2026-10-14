// Captures de recette de COUPE-MOTS-1 (part 2/2) : vraies polices, vrai
// theme, ecrans reels ou coquilles de demonstration.
//
// - point 3 : la photo publique (ENS-05A), dans sa feuille, depuis le Profil
//   de la demonstration enseignant ;
// - point 4 : Reglages (carte Accessibilite, ligne Fuseau horaire), Profil
//   (ligne Fuseau horaire) et Apparence ;
// - point 5 : la carte « Remplacement » d'Aujourd'hui ;
// - point 7 : le detail d'un rapport du controleur et sa section « Echanges
//   avec l'administration », a 320 et a 390 ;
// - point 1 (constat seulement, fichier de la voie Bento) : Aujourd'hui de
//   l'enseignant a 320 x2.
//
// 320 px, texte x1 et x2, clair et sombre. Chaque capture mesure, en vraies
// polices, qu'aucun mot de l'ecran corrige n'est coupe ni tronque.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Sortie versionnee
// dans `docs/current/captures/COUPE-MOTS-1/`. Donnees : fixtures synthetiques
// de la demonstration uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/compte/apparence_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur_page.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/journee/absence_remplacement_vue.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Monte [routeur] dans le cadre de capture, a l'echelle donnee.
Future<void> _monterRouteur(
  WidgetTester tester, {
  required GoRouter routeur,
  required ThemeMode mode,
  required double echelle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

String _x(double echelle) => 'x${echelle.round()}';

/// Echoue en nommant chaque mot coupe sous [ou] ; les fautes sont aussi
/// ecrites dans le journal, pour la recette.
void _mesurer(
  WidgetTester tester,
  Finder ou, {
  bool traitDUnionPermis = false,
}) {
  expect(ou, findsWidgets);
  final List<String> fautes = motsCoupes(
    tester,
    ou,
    traitDUnionPermis: traitDUnionPermis,
  );
  if (fautes.isNotEmpty) debugPrint('FAUTES ${fautes.join(' | ')}');
  expect(fautes, isEmpty, reason: 'Un mot coupe ou tronque');
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

final OffreRemplacement _offre = OffreRemplacement(
  seanceId: 'demo-seance-al-fatiha-2909',
  classe: 'Al-Fatiha',
  debut: DateTime(2026, 9, 29, 17),
  fin: DateTime(2026, 9, 29, 17, 45),
  nbEleves: 4,
  groupeId: 'demo-classe-al-fatiha',
);

void main() {
  group('Capture : COUPE-MOTS-1 (part 2/2)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final double echelle in <double>[1, 2]) {
        final String suffixe = '320_${_x(echelle)}_${mode.name}';

        testWidgets('photo publique $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 900), 2);
          await tester.pumpWidget(
            hoteCapture(
              const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.profil),
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          await _toucher(tester, find.text(t.enseignant.photo.choisir).first);
          // Toute la feuille : son titre « Photo professionnelle » compris.
          expect(find.byType(EditeurPhotoPublique), findsOneWidget);
          _mesurer(tester, find.byType(AppBottomSheet));
          debugPrint(
            'PNG ${await capturer(tester, 'photo_publique_$suffixe')}',
          );
        });

        testWidgets('reglages $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 1800), 2);
          await tester.pumpWidget(
            hoteCapture(
              const ReglagesComptePage(),
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(FausseSourceSession()),
              ],
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          _mesurer(tester, find.byType(ReglagesComptePage));
          debugPrint('PNG ${await capturer(tester, 'reglages_$suffixe')}');
        });

        testWidgets('apparence $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 1100), 2);
          await tester.pumpWidget(
            hoteCapture(
              const ApparenceComptePage(),
              surcharges: <Override>[
                sourceSessionProvider.overrideWithValue(FausseSourceSession()),
              ],
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          _mesurer(tester, find.byType(ApparenceComptePage));
          debugPrint('PNG ${await capturer(tester, 'apparence_$suffixe')}');
        });

        testWidgets('profil controleur $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 1400), 2);
          await _monterRouteur(
            tester,
            routeur: GoRouter(
              initialLocation: adresseDemoControleur(
                EcranDemoControleur.compte,
              ),
              routes: routesDemoControleur('dev'),
            ),
            mode: mode,
            echelle: echelle,
          );
          _mesurer(tester, find.byType(ComptePage));
          debugPrint('PNG ${await capturer(tester, 'profil_$suffixe')}');
        });

        testWidgets('carte remplacement $suffixe', (WidgetTester tester) async {
          fixerVueCapture(tester, const Size(320, 900), 2);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: CarteRemplacement(
                        offre: _offre,
                        date: 'mardi 29 septembre',
                      ),
                    ),
                  ),
                ),
              ),
              themeMode: mode,
              echelleTexte: echelle,
            ),
          );
          await stabiliser(tester);
          _mesurer(tester, find.byType(CarteRemplacement));
          debugPrint(
            'PNG ${await capturer(tester, 'carte_remplacement_$suffixe')}',
          );
        });
      }
    }

    for (final (double largeur, double echelle, ThemeMode mode) cas
        in <(double, double, ThemeMode)>[
          for (final double l in <double>[320, 390])
            for (final double e in <double>[1, 2])
              for (final ThemeMode m in <ThemeMode>[
                ThemeMode.light,
                ThemeMode.dark,
              ])
                (l, e, m),
        ]) {
      {
        final double largeur = cas.$1;
        final double echelle = cas.$2;
        final ThemeMode mode = cas.$3;
        final String suffixe = '${largeur.round()}_${_x(echelle)}_${mode.name}';
        testWidgets('controleur detail echanges $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, Size(largeur, 844), 2);
          await _monterRouteur(
            tester,
            routeur: GoRouter(
              initialLocation: adresseDemoControleur(
                EcranDemoControleur.historique,
              ),
              routes: routesDemoControleur('dev'),
            ),
            mode: mode,
            echelle: echelle,
          );
          await _toucher(
            tester,
            find.byKey(HistoriqueControleurPage.ligneKey('demo-rapport-0924')),
          );
          await tester.ensureVisible(
            find.byKey(HistoriqueControleurPage.ecrireAdminKey),
          );
          await stabiliser(tester);
          // Le titre « Classe Al-Badr · Jeudi 24 septembre » peut passer a
          // la ligne apres le trait d'union du nom (voir le resultat).
          _mesurer(
            tester,
            find.byType(HistoriqueControleurPage),
            traitDUnionPermis: true,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'controleur_detail_$suffixe')}',
          );
        });
      }
    }

    // Point 1, constat : `journee_page.dart` appartient a la voie Bento.
    // L'offre de remplacement (« Assurer ce remplacement ? ») y est une
    // ligne de `GroupeReglages`, composant partage corrige ici : elle est
    // mesuree strictement ; le reste de l'ecran est seulement releve.
    for (final double echelle in <double>[1, 2]) {
      testWidgets('journee 320 ${_x(echelle)} (offre mesuree, reste releve)', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(320, 1600), 2);
        await _monterRouteur(
          tester,
          routeur: GoRouter(
            initialLocation: adresseDemoEnseignant(
              EcranDemoEnseignant.aujourdhui,
            ),
            routes: routesDemoEnseignant('dev'),
          ),
          mode: ThemeMode.light,
          echelle: echelle,
        );
        _mesurer(tester, find.byType(GroupeReglages));
        debugPrint(
          'CONSTAT journee 320 ${_x(echelle)} : '
          '${motsCoupes(tester, find.byType(NavShell)).join(' | ')}',
        );
        // Pas de PNG ici : la capture (runAsync) laisse la base locale de
        // l'appareil s'ouvrir, sans path_provider en test.
      });
    }
  });
}
