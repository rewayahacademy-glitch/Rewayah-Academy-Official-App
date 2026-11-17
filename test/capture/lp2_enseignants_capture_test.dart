// Captures R3 de LP-2 (16/11/2026, SPEC-LISTE-PERSONNES §2 et §3) : la liste des
// enseignants. Donnees de test uniquement, aucune personne reelle.
//
// Scenes, a 360 et 1440 en francais et en arabe :
// 1. la liste : phases, resume propre a la phase, badge « Nouveau » ;
// 2. le menu « Phase » ouvert ;
// 3. le menu « ... » d'une ligne (gestes servis par le serveur) ;
// 4. la selection avec la barre des gestes groupables.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_enseignants/enseignants_page.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

LigneEnseignant _ligne(
  String id,
  String nom,
  PhaseEnseignant phase, {
  bool nouveau = false,
  List<String> manque = const <String>[],
  String? quiAttend,
  List<String> gestes = const <String>[],
  List<String> groupables = const <String>[],
  ClassesEnseignant classes = const ClassesEnseignant(
    nombre: 0,
    heuresSemaine: 0,
  ),
  DateTime? seance,
}) => LigneEnseignant(
  dossier: ligneTest(id: id, nom: nom, nouveau: nouveau),
  phase: phase,
  manque: manque,
  quiAttend: quiAttend,
  gestes: gestes,
  gestesGroupables: groupables,
  classes: classes,
  prochaineSeance: seance,
  remplacements: phase == PhaseEnseignant.enPoste
      ? const RemplacementsEnseignant(donnes: 1, recus: 0)
      : const RemplacementsEnseignant(donnes: 0, recus: 0),
);

class _Enseignants implements PortEnseignants {
  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => PageEnseignants(
    lignes: <LigneEnseignant>[
      _ligne(
        'a1',
        'Amina Diallo',
        PhaseEnseignant.candidat,
        nouveau: true,
        quiAttend: 'direction',
        gestes: <String>['refuser', 'mettre_en_pause', 'valider_piece'],
        groupables: <String>['refuser', 'mettre_en_pause'],
      ),
      _ligne(
        'b2',
        'Bilal Haddad',
        PhaseEnseignant.accueil,
        manque: <String>['photo_absente', 'langues_absentes'],
        quiAttend: 'enseignant',
        gestes: <String>['mettre_en_pause'],
        groupables: <String>['mettre_en_pause'],
      ),
      _ligne(
        'c3',
        'Farah Nasser',
        PhaseEnseignant.enPoste,
        classes: const ClassesEnseignant(nombre: 2, heuresSemaine: 3),
        seance: DateTime.utc(2026, 11, 20, 18),
        gestes: <String>['mettre_en_pause'],
        groupables: <String>['mettre_en_pause'],
      ),
      _ligne(
        'd4',
        'Omar Sy',
        PhaseEnseignant.disponible,
        quiAttend: 'direction',
      ),
    ],
    total: 87,
    page: 1,
    taillePage: 50,
    compteurs: const CompteursEnseignants(
      parPhase: <PhaseEnseignant, int>{
        PhaseEnseignant.candidat: 41,
        PhaseEnseignant.accueil: 9,
        PhaseEnseignant.disponible: 6,
        PhaseEnseignant.enPoste: 31,
      },
      nouveaux: 12,
      sansDossier: 2,
    ),
  );
}

Future<void> _monter(WidgetTester tester, Size taille, double densite) async {
  fixerVueCapture(tester, taille, densite);
  final GoRouter routeur = GoRouter(
    initialLocation: Routes.adminPersonnesEnseignants,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.adminPersonnesEnseignants,
        builder: (BuildContext _, GoRouterState _) =>
            EnseignantsPage(ouvrirCandidature: (LigneCandidature _) {}),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        portEnseignantsProvider.overrideWithValue(_Enseignants()),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            lignes: const <LigneCandidature>[],
            capacitesRendues: capacitesGestes,
          ),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              themeMode: ThemeMode.light,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('Capture LP-2', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.en);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final (String, Size, double, AppLocale) g
        in <(String, Size, double, AppLocale)>[
          ('fr_360', const Size(360, 800), 2, AppLocale.fr),
          ('fr_1440', const Size(1440, 900), 1, AppLocale.fr),
          ('ar_360', const Size(360, 800), 2, AppLocale.ar),
          ('ar_1440', const Size(1440, 900), 1, AppLocale.ar),
        ]) {
      testWidgets('LP-2 ${g.$1}', (WidgetTester tester) async {
        LocaleSettings.setLocaleSync(g.$4);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(tester, g.$2, g.$3);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, '1_liste_${g.$1}')}');
        debugPrint(
          'MESURE ${g.$1} : haut de la premiere ligne a '
          '${tester.getTopLeft(find.byKey(cleEnseignant('a1'))).dy}',
        );
        await tester.tap(find.byKey(EnseignantsPage.clePhase));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '2_menu_phase_${g.$1}')}');
        await tester.tapAt(const Offset(2, 2));
        await stabiliser(tester);
        await tester.tap(find.byKey(EnseignantsPage.cleMenu('a1')));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '3_menu_ligne_${g.$1}')}');
        await tester.tapAt(const Offset(2, 2));
        await stabiliser(tester);
        await tester.tap(find.byKey(EnseignantsPage.cleSelectionner));
        await stabiliser(tester);
        await tester.tap(find.byKey(cleEnseignant('a1')));
        await stabiliser(tester);
        await tester.tap(find.byKey(cleEnseignant('b2')));
        await stabiliser(tester);
        debugPrint('PNG ${await capturer(tester, '4_selection_${g.$1}')}');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
