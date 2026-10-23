// Captures de la refonte de la file des candidatures (LISTES-1, lot 2,
// 23/10/2026), sur la VRAIE application et le vrai routeur en demonstration
// d'administration : la coque est dans chaque PNG. Memes quatorze candidatures
// fictives que les captures « avant » (`listes1_capture_test.dart`).
//
// Scenes : la file (1440 et 390, clair et sombre, arabe), le menu d'une ligne,
// trois lignes retenues avec la barre groupee, la feuille du traitement groupe
// (apercu avec un exclu, puis le rapport), les filtres en cours, les etats.
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Aucune personne
// reelle.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart'
    show cleCase;
import 'package:rewayah_academy/features/admin_candidatures/lot_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/menu_ligne_candidature.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/lignes_candidatures_capture.dart';
import 'outil_capture.dart';

const Size _bureau = Size(1440, 900);
const Size _telephone = Size(390, 844);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

FauxCandidaturesDirection _port({
  List<LigneCandidature>? lignes,
  Object? Function(int)? erreurLister,
}) => FauxCandidaturesDirection(
  lignes: lignes ?? lignesCandidaturesCapture(),
  capacitesRendues: capacitesGestes,
  erreurLister: erreurLister,
  details: <DetailCandidature>[
    detailTest(
      id: 'a1',
      nom: 'Amina Diallo',
      paiement: EtatVersement.aVerifier,
    ),
  ],
);

Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  ThemeMode mode = ThemeMode.light,
  bool horsLigne = false,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.adminPersonnesCandidatures);
  await stabiliser(tester);
  await stabiliser(tester);
}

/// Laisse le decodage des images (les drapeaux) se terminer : il tourne hors
/// du `FakeAsync` du test.
Future<void> _chargerImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Element e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

Future<void> _enHaut(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.minScrollExtent);
    }
  }
  await tester.pump();
}

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  await _chargerImages(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

Future<void> _cocher(WidgetTester tester, String nom) async {
  // Les cartes (telephone) ont une cle ; une carte hors de l'ecran n'est pas
  // dans l'arbre de semantique : on l'amene a l'ecran par sa cle. Le tableau
  // n'a pas de cle de case : on la retrouve par son libelle.
  const Map<String, String> ids = <String, String>{
    'Amina Diallo': 'a1',
    'Bilal Haddad': 'b2',
    'Emna Gharbi': 'e5',
  };
  final Finder carte = find.byKey(cleCase(ids[nom]!));
  if (carte.evaluate().isNotEmpty) {
    await tester.ensureVisible(carte);
    await tester.pump();
    await tester.tap(carte);
    await stabiliser(tester);
    return;
  }
  final Finder f = find.bySemanticsLabel(
    t.commun.listes.cocherLigne(objet: nom),
  );
  await tester.tap(f.first);
  await stabiliser(tester);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('LISTES-1 lot 2 : captures des candidatures', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final (String nom, Size taille) in <(String, Size)>[
      ('1440', _bureau),
      ('390', _telephone),
    ]) {
      final EdgeInsets zone = taille == _telephone
          ? _zoneSure
          : EdgeInsets.zero;
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        testWidgets('file $nom ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, 1, zoneSure: zone);
          await _monter(tester, _port(), mode: mode);
          await _photo(tester, 'file_${nom}_${mode.name}');
        });

        testWidgets('menu de ligne $nom ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, 1, zoneSure: zone);
          await _monter(tester, _port(), mode: mode);
          final Finder menu = find.byKey(MenuLigneCandidature.cle('b2')).first;
          await tester.ensureVisible(menu);
          await tester.pump();
          await tester.tap(menu);
          await stabiliser(tester);
          await _chargerImages(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'menu_ligne_${nom}_${mode.name}')}',
          );
        });
      }

      testWidgets('trois lignes retenues $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        await _cocher(tester, 'Amina Diallo');
        await _cocher(tester, 'Bilal Haddad');
        await _cocher(tester, 'Emna Gharbi');
        await _photo(tester, 'selection_${nom}_clair');
      });

      testWidgets('feuille du lot $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port());
        // Emna Gharbi est deja en pause : elle sera exclue de la mise en pause.
        await _cocher(tester, 'Amina Diallo');
        await _cocher(tester, 'Bilal Haddad');
        await _cocher(tester, 'Emna Gharbi');
        final Finder pause = find.byKey(
          CandidaturesPage.cleOperationLot(GesteLot.mettreEnPause),
        );
        await tester.ensureVisible(pause);
        await tester.pump();
        await tester.tap(pause);
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'lot_apercu_${nom}_clair')}');
        final Finder modele = find.byKey(
          const ValueKey<String>('modele-pause_general'),
        );
        await tester.ensureVisible(modele);
        await tester.pump();
        await tester.tap(modele);
        await stabiliser(tester);
        await tester.enterText(
          find.byKey(FeuilleLot.cleMotif),
          'Attente des pieces demandees.',
        );
        await tester.enterText(find.byKey(FeuilleLot.cleNombre), '2');
        await stabiliser(tester);
        await tester.ensureVisible(find.byKey(FeuilleLot.cleNombre));
        await tester.pump();
        debugPrint('PNG ${await capturer(tester, 'lot_saisie_${nom}_clair')}');
        await tester.ensureVisible(find.byKey(FeuilleLot.cleValider));
        await tester.pump();
        await tester.tap(find.byKey(FeuilleLot.cleValider));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, 'lot_rapport_${nom}_clair')}');
      });
    }

    testWidgets('filtres en cours 1440 clair', (WidgetTester tester) async {
      fixerVueCapture(tester, _bureau, 1);
      await _monter(tester, _port());
      await tester.tap(
        find.byKey(const ValueKey<String>('candidatures-filtre-salle')),
      );
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'filtre_salle_1440_clair')}');
      await tester.tap(find.textContaining(t.recrutement.salles.examen).last);
      await stabiliser(tester);
      await _photo(tester, 'filtres_actifs_1440_clair');
    });

    testWidgets('arabe 1440 clair', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, _bureau, 1);
      await _monter(tester, _port());
      await _photo(tester, 'file_ar_1440_clair');
      await tester.tap(find.byKey(MenuLigneCandidature.cle('b2')).first);
      await stabiliser(tester);
      debugPrint('PNG ${await capturer(tester, 'menu_ligne_ar_1440_clair')}');
    });

    testWidgets('etats 1440 clair', (WidgetTester tester) async {
      fixerVueCapture(tester, _bureau, 1);
      await _monter(
        tester,
        _port(erreurLister: (int _) => StateError('panne')),
      );
      await _photo(tester, 'etat_erreur_1440_clair');
    });

    testWidgets('aucun resultat 1440 clair', (WidgetTester tester) async {
      fixerVueCapture(tester, _bureau, 1);
      await _monter(tester, _port());
      await tester.enterText(
        find.byKey(const ValueKey<String>('candidatures-recherche')),
        'zzz',
      );
      await stabiliser(tester);
      await stabiliser(tester);
      await _photo(tester, 'etat_aucun_resultat_1440_clair');
    });
  });
}
