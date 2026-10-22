// Captures de CAND-06 (la carte a partager, redessinee le 22/10/2026) : la carte
// seule (l'export de 1080 x 1920 puis sa reduction de 540 x 960) dans chaque
// variante (hommes, femmes) et chaque langue (francais, anglais, portugais,
// arabe) ; la page de partage a 390x844 et 1440x900, en francais et en arabe de
// droite a gauche, pour chaque variante ; la tuile dans le portail ; puis les
// etats (pas de lien, image non preparee, appareil sans menu de partage, texte
// agrandi). Tout sort dans `PARTAGE-v2/`.
//
// Saute sans CAPTURE_DIR (voir test/capture/LISEZ-MOI.md).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/partage_offre/personnalisation_carte.dart';
import 'package:rewayah_academy/core/partage_offre/port_partage_offre.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/partage_offre/carte_partage.dart';
import 'package:rewayah_academy/features/partage_offre/rendu_carte.dart';

import '../features/candidature/hote_candidature.dart';
import '../features/partage_offre/hote_partage.dart';
import '../fixtures/partage_offre/faux_partage_offre.dart';
import '../support/harnais.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Monte la page ou le portail sous le vrai theme, dans le cadre de capture.
Future<MontagePartage> _monter(
  WidgetTester tester, {
  String depart = Routes.attentePartage,
  Size taille = _telephone,
  ThemeMode mode = ThemeMode.light,
  NiveauPartage niveau = NiveauPartage.image,
  bool sansLien = false,
  FauxRenduCarte? rendu,
  CandidatureDossier? candidature,
  double echelle = 1,
  Genre? genre,
  List<String> langues = const <String>[],
}) async {
  fixerVueCapture(tester, taille, 1);
  final FauxPartageOffre menu = FauxPartageOffre(niveau: niveau);
  final FauxEnregistrementImage enregistrement = FauxEnregistrementImage();
  final FauxRenduCarte faux = rendu ?? FauxRenduCarte();
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(candidature: candidature ?? candidatureAFaire());
  final GoRouter routeur = GoRouter(
    initialLocation: depart,
    routes: routesPartage(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesPartage(
        partage: menu,
        enregistrement: enregistrement,
        rendu: faux,
        dossier: dossier,
        lien: sansLien ? null : lienDeTest,
        genre: FauxGenrePartageur(genre: genre),
        langues: langues,
      ),
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
  await tester.pumpAndSettle();
  return MontagePartage(
    partage: menu,
    enregistrement: enregistrement,
    rendu: faux,
    dossier: dossier,
  );
}

/// Remonte les listes verticales en haut.
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

/// Descend les listes verticales jusqu'en bas : les gestes et leurs retours.
Future<void> _enBas(WidgetTester tester) async {
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState etat =
        (e as StatefulElement).state as ScrollableState;
    if (etat.position.axis == Axis.vertical) {
      etat.position.jumpTo(etat.position.maxScrollExtent);
    }
  }
  await tester.pump();
}

Future<void> _photo(WidgetTester tester, String nom) async {
  await _enHaut(tester);
  await capturer(tester, 'PARTAGE-v2/$nom');
}

/// La carte seule, a l'echelle 1,5 (540 x 960), puis l'export reel de 1080 x
/// 1920 pixels ecrit tel qu'il part au menu de partage.
Future<void> _carte(
  WidgetTester tester,
  LangueCarte langue,
  VarianteCarte variante,
) async {
  final GlobalKey cle = GlobalKey();
  fixerVueCapture(tester, const Size(360, 640), 1.5);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: RepaintBoundary(
                key: cle,
                child: CartePartage(
                  lien: lienDeTest,
                  langue: langue,
                  variante: variante,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final String nom = '${variante.name}_${langue.code}';
  await capturer(tester, 'PARTAGE-v2/carte_${nom}_540x960');
  final Uint8List png = (await tester.runAsync(() => rendreCarteEnPng(cle)))!;
  await tester.runAsync(
    () =>
        File(cheminSortie('PARTAGE-v2/carte_export_${nom}_1080x1920'))
            .writeAsBytes(png),
  );
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CAND-06 : captures', skip: sautSansCapture, () {
    for (final VarianteCarte v in VarianteCarte.values) {
      for (final LangueCarte l in LangueCarte.values) {
        testWidgets('la carte, ${v.name}, ${l.code}', (
          WidgetTester tester,
        ) async {
          await _carte(tester, l, v);
        });
      }
    }

    for (final (VarianteCarte, Genre?) v in <(VarianteCarte, Genre?)>[
      (VarianteCarte.hommes, Genre.homme),
      (VarianteCarte.femmes, Genre.femme),
    ]) {
      final String nom = v.$1.name;
      for (final (String, Size) taille in <(String, Size)>[
        ('390', _telephone),
        ('1440', _bureau),
      ]) {
        testWidgets('page $nom ${taille.$1} fr', (WidgetTester tester) async {
          await _monter(tester, taille: taille.$2, genre: v.$2);
          await _photo(tester, 'page_${nom}_${taille.$1}_fr');
        });

        testWidgets('page $nom ${taille.$1} ar', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _monter(tester, taille: taille.$2, genre: v.$2);
          await _photo(tester, 'page_${nom}_${taille.$1}_ar');
        });

        testWidgets('portail $nom ${taille.$1} fr', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            depart: Routes.attente,
            taille: taille.$2,
            genre: v.$2,
          );
          await _photo(tester, 'portail-tuile_${nom}_${taille.$1}_fr');
        });

        testWidgets('portail $nom ${taille.$1} ar', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _monter(
            tester,
            depart: Routes.attente,
            taille: taille.$2,
            genre: v.$2,
          );
          await _photo(tester, 'portail-tuile_${nom}_${taille.$1}_ar');
        });
      }

      testWidgets('page $nom 390 fr, les gestes', (WidgetTester tester) async {
        await _monter(tester, genre: v.$2);
        await _enBas(tester);
        await capturer(tester, 'PARTAGE-v2/page-gestes_${nom}_390_fr');
      });

      testWidgets('page $nom 390 sombre fr', (WidgetTester tester) async {
        await _monter(tester, mode: ThemeMode.dark, genre: v.$2);
        await _photo(tester, 'page_${nom}_390_sombre_fr');
      });

      testWidgets('page $nom 390 fr, la carte en portugais', (
        WidgetTester tester,
      ) async {
        await _monter(tester, genre: v.$2, langues: <String>['poular', 'pt']);
        await _photo(tester, 'page_${nom}_390_fr_langue-par-defaut-pt');
      });

      testWidgets('page $nom 390 fr, apres le choix de English', (
        WidgetTester tester,
      ) async {
        await _monter(tester, genre: v.$2);
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        await _photo(tester, 'page_${nom}_390_fr_choix-en');
      });
    }

    testWidgets('portail en examen, la tuile sous l\'etat', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: Routes.attente,
        candidature: const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
          version: 4,
        ),
        genre: Genre.femme,
      );
      await _photo(tester, 'portail-tuile-en-examen_femmes_390_fr');
    });

    testWidgets('etat : pas de lien d\'offre', (WidgetTester tester) async {
      await _monter(tester, sansLien: true);
      await _photo(tester, 'etat-pas-de-lien_390_fr');
    });

    testWidgets('etat : image non preparee', (WidgetTester tester) async {
      final FauxRenduCarte casse = FauxRenduCarte()
        ..erreur = StateError('pas peinte');
      await _monter(tester, rendu: casse, genre: Genre.femme);
      await _enBas(tester);
      await capturer(tester, 'PARTAGE-v2/etat-image-non-preparee_390_fr');
    });

    testWidgets('etat : appareil sans menu de partage', (
      WidgetTester tester,
    ) async {
      await _monter(tester, niveau: NiveauPartage.aucun, genre: Genre.femme);
      await _enBas(tester);
      await capturer(tester, 'PARTAGE-v2/etat-sans-menu_femmes_390_fr');
    });

    testWidgets('etat : apres « Copier le lien »', (WidgetTester tester) async {
      await _monter(tester, genre: Genre.femme);
      PressePapiersDeTest(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('partage-copier')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('partage-copier')));
      await tester.pumpAndSettle();
      await _enBas(tester);
      await capturer(tester, 'PARTAGE-v2/etat-lien-copie_femmes_390_fr');
    });

    testWidgets('texte agrandi 320 x2', (WidgetTester tester) async {
      await _monter(
        tester,
        taille: const Size(320, 640),
        echelle: 2,
        genre: Genre.femme,
      );
      await _photo(tester, 'page_femmes_320_x2_fr');
    });
  });
}
