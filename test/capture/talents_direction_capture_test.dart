// Captures du cote direction de CAND-07 (« Vos autres talents »), sur la VRAIE
// application et le vrai routeur en demonstration d'administration :
// - la ligne « Autres competences » de la fiche d'une candidature (`ADM-21`),
//   avec et sans reponse ; 390x844 et 1440x900, clair ; le sombre ; l'arabe de
//   droite a gauche ;
// - les quatre menus de la liste des candidatures (`ADM-20`), sous « Plus » :
//   la feuille, le menu du domaine, le filtre pose.
//
// Les donnees sont fictives, posees par les doubles des ports : aucune personne
// reelle. Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/bloc_autres_competences.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_autres_competences.dart';
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/rangee_plus.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Les reponses d'une personne qui a rempli « Vos autres talents ».
ReponsesAutresCompetences _reponses({String? autreTexte}) =>
    ReponsesAutresCompetences.depuisJson(
      reponsesJsonDeTest(
        domaines: const <String, String>{
          'reseaux_sociaux': 'experience',
          'design_graphique': 'metier',
          'comptabilite': 'metier',
          'assistanat': 'debutant',
          'autre': 'experience',
        },
        autreTexte: autreTexte ?? 'Secrétariat médical',
        disponibilite: 'mi_temps',
      ),
    )!;

FauxCandidaturesDirection _port({ReponsesAutresCompetences? reponses}) =>
    FauxCandidaturesDirection(
      capacitesRendues: capacitesQuiDecide,
      lignes: <LigneCandidature>[
        ligneTest(id: 'a1', nom: 'Amina Diallo'),
        ligneTest(
          id: 'b2',
          nom: 'Bilal Haddad',
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
          paysResidence: 'FR',
        ),
        ligneTest(
          id: 'c3',
          nom: 'Carla Mendes',
          etape: EtapeCandidature.confirmee,
          etat: null,
          paysResidence: 'PT',
        ),
      ],
      details: <DetailCandidature>[detailTest(autresCompetences: reponses)],
    );

/// Monte la VRAIE application en demonstration d'administration, puis ouvre
/// [route] (avec [extra] : l'identifiant d'une candidature).
Future<void> _monter(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  required String route,
  Object? extra,
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        portCatalogueCompetencesProvider.overrideWithValue(
          FauxCatalogueCompetences(),
        ),
        horlogeFormulairesProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 22, 12),
        ),
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
  unawaited(routeur.push<void>(route, extra: extra));
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _photoSur(WidgetTester tester, Key cle, String nom) async {
  final Finder f = find.byKey(cle);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.02);
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('CAND-07 : captures du cote direction', skip: sautSansCapture, () {
    final String fiche = Routes.adminPersonnesCandidaturePour('CAND-0000C1');

    for (final (String nom, Size taille) in <(String, Size)>[
      ('390', _telephone),
      ('1440', _bureau),
    ]) {
      final bool tel = taille == _telephone;
      final EdgeInsets zone = tel ? _zoneSure : EdgeInsets.zero;

      testWidgets('fiche avec reponses $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          _port(reponses: _reponses()),
          route: fiche,
          extra: 'c1',
        );
        await _photoSur(
          tester,
          BlocAutresCompetences.cle,
          'direction-fiche_${nom}_clair',
        );
      });

      testWidgets('fiche sans reponse $nom clair', (WidgetTester tester) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(tester, _port(), route: fiche, extra: 'c1');
        await _photoSur(
          tester,
          BlocAutresCompetences.cle,
          'direction-fiche-sans-reponse_${nom}_clair',
        );
      });

      testWidgets('liste, filtres sous « Plus » $nom clair', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, taille, 1, zoneSure: zone);
        await _monter(
          tester,
          _port(),
          route: Routes.adminPersonnesCandidatures,
        );
        await ouvrirPlus(tester);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'direction-filtres_${nom}_clair')}',
        );
        await tester.ensureVisible(
          find
              .byKey(const ValueKey<String>('candidatures-filtre-competence'))
              .last,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .byKey(const ValueKey<String>('candidatures-filtre-competence'))
              .last,
        );
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'direction-filtre-domaine_${nom}_clair')}',
        );
      });
    }

    testWidgets('fiche avec reponses 390 sombre', (WidgetTester tester) async {
      fixerVueCapture(tester, _telephone, 1, zoneSure: _zoneSure);
      await _monter(
        tester,
        _port(reponses: _reponses()),
        route: fiche,
        extra: 'c1',
        mode: ThemeMode.dark,
      );
      await _photoSur(
        tester,
        BlocAutresCompetences.cle,
        'direction-fiche_390_sombre',
      );
    });

    testWidgets('fiche avec reponses 390 arabe', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, _telephone, 1, zoneSure: _zoneSure);
      await _monter(
        tester,
        _port(reponses: _reponses(autreTexte: 'سكرتارية طبية')),
        route: fiche,
        extra: 'c1',
      );
      await _photoSur(
        tester,
        BlocAutresCompetences.cle,
        'direction-fiche_390_arabe',
      );
    });

    testWidgets('filtres sous « Plus » 390 arabe', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      fixerVueCapture(tester, _telephone, 1, zoneSure: _zoneSure);
      await _monter(tester, _port(), route: Routes.adminPersonnesCandidatures);
      await ouvrirPlus(tester);
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'direction-filtres_390_arabe')}',
      );
    });
  });
}
