// EA-HL-DOUBLE-1d : captures de preuve de l'Accueil eleve hors ligne, quand
// la lecture des cours echoue sans valeur (revue EA-HL-DOUBLE-1c-R, moyen) :
// le bandeau seul porte le « wifi barre » ; le bloc d'echec, dessous, prend
// le sablier et dit ce qui manque.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Chaque capture verifie aussi qu'aucun mot n'est coupe ni tronque, et que
// « hors ligne » n'est dit qu'une fois, en mots et en icone.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/espace_groupe_page.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';
import '../teaching_core/a/support/hote_tc_a.dart' show surchargesDemonstration;
import 'outil_capture.dart';

/// Un port de revue dont chaque lecture echoue comme une requete sans reseau.
class _PortSansReseau implements PortRevueDossiers {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('reseau'));
}

/// Les surcharges de la demonstration admin, hors ligne ; le port remplace
/// par [port] s'il est donne.
List<Override> _surchargesAdmin({PortRevueDossiers? port}) {
  final List<Override> base = surchargesDemoAdmin(environnement: 'staging');
  final String marque = '$portRevueDossiersProvider.override';
  return <Override>[
    for (final Override o in base)
      if (port == null || !o.toString().startsWith(marque)) o,
    if (port != null) portRevueDossiersProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
  ];
}

/// Monte la vraie application admin a [chemin], au format de [cas].
Future<void> _monterAdmin(
  WidgetTester tester,
  _Cas cas, {
  required String chemin,
  PortRevueDossiers? port,
}) async {
  fixerVueCapture(tester, cas.$2, 1);
  // `MaterialApp.router` sur le vrai routeur plutot que `RewayahApp` : la
  // persistance des preferences appelle `path_provider`, absent sous
  // `runAsync` (meme choix que `ad7_visionneuse_capture_test.dart`).
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surchargesAdmin(port: port),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(cas.$6, Brightness.light),
                darkTheme: AppTheme.pour(cas.$6, Brightness.dark),
                themeMode: cas.$3,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
                builder: (BuildContext contexte, Widget? child) =>
                    Directionality(
                      textDirection: cas.$5,
                      child: MediaQuery(
                        data: MediaQuery.of(contexte)
                            .copyWith(textScaler: TextScaler.linear(cas.$4)),
                        child: RepereDemonstration(child: child),
                      ),
                    ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(chemin);
  await stabiliser(tester);
}

/// Un cas de capture : nom, taille, theme, echelle, sens, interface.
typedef _Cas = (String, Size, ThemeMode, double, TextDirection, InterfaceMode);

const List<_Cas> _cas = <_Cas>[
  (
    '390_clair',
    Size(390, 844),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '390_sombre',
    Size(390, 844),
    ThemeMode.dark,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '390_guidee',
    Size(390, 844),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.enfant,
  ),
  (
    '320x2_clair',
    Size(320, 1800),
    ThemeMode.light,
    2,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '320x2_rtl_clair',
    Size(320, 1800),
    ThemeMode.light,
    2,
    TextDirection.rtl,
    InterfaceMode.standard,
  ),
  (
    '1440_clair',
    Size(1440, 900),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
];

void main() {
  group('Capture : EA-HL-DOUBLE-1d', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final _Cas cas in _cas) {
      testWidgets('accueil eleve, echec sans valeur ${cas.$1}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            Directionality(
              textDirection: cas.$5,
              child: AccueilElevePage(horloge: () => DateTime(2026, 9, 8, 17)),
            ),
            surcharges: <Override>[
              servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
              servicePriereProvider.overrideWithValue(FauxServicePriere()),
              serviceReseauProvider.overrideWithValue(
                FauxServiceReseau(horsLigneRendu: true),
              ),
              seancesProvider.overrideWith(
                (Ref _) => Future<List<Seance>>.error(StateError('reseau')),
              ),
            ],
            themeMode: cas.$3,
            echelleTexte: cas.$4,
            interfaceMode: cas.$6,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        final EtatSysteme bloc = tester.widget<EtatSysteme>(
          find.byKey(const ValueKey<String>('accueil-eleve-erreur')),
        );
        expect(bloc.nature, NatureEtat.horsLigne);
        expect(bloc.icone, AppIcons.attente);
        expect(find.text(t.eleve.accueil.erreurCours), findsOneWidget);
        expectHorsLigneUneFois();
        verifierAucunMotCoupe(tester, find.byType(PageShell));
        debugPrint(
          'PNG ${await capturer(tester, 'ea_hl_double1d_accueil_eleve_echec_${cas.$1}')}',
        );
      });
    }
  });
  // La carte de session d'une classe a T-20, hors ligne : la ligne d'etat
  // dit l'attente de l'entree avec le sablier ; le « wifi barre » reste
  // celui du bandeau (EA-HL-DOUBLE-1).
  group('Capture : EA-HL-DOUBLE-1d, carte de session', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final _Cas cas in _cas) {
      testWidgets('carte de session ${cas.$1}', (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            Directionality(
              textDirection: cas.$5,
              child: const EspaceGroupePage(
                groupeId: GroupesDemonstration.anNour,
                role: RoleEspaceGroupe.eleve,
              ),
            ),
            surcharges: surchargesDemonstration(horsLigne: true),
            themeMode: cas.$3,
            echelleTexte: cas.$4,
            interfaceMode: cas.$6,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        expectHorsLigneUneFois();
        expect(
          find.descendant(
            of: find.byType(CarteSession),
            matching: find.byIcon(AppIcons.attente.repos),
          ),
          findsOneWidget,
        );
        verifierAucunMotCoupe(tester, find.byType(PageShell));
        debugPrint(
          'PNG ${await capturer(tester, 'ea_hl_double1d_carte_session_${cas.$1}')}',
        );
      });
    }
  });

  group('Capture : EA-HL-DOUBLE-1d, admin', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    // La file des dossiers hors ligne, quand rien n'a pu etre lu : le bloc
    // dit ce qui manque, avec le sablier (EA-HL-DOUBLE-1).
    for (final _Cas cas in _cas) {
      if (cas.$6 == InterfaceMode.enfant) continue;
      testWidgets('file des dossiers ${cas.$1}', (WidgetTester tester) async {
        await _monterAdmin(
          tester,
          cas,
          chemin: Routes.adminPersonnesDossiers,
          port: _PortSansReseau(),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.dossiers.file.horsLigne), findsOneWidget);
        expectHorsLigneUneFois();
        verifierAucunMotCoupe(tester, find.byType(PageShell));
        debugPrint(
          'PNG ${await capturer(tester, 'ea_hl_double1d_dossiers_file_${cas.$1}')}',
        );
      });
    }

    // La piece d'un dossier hors ligne (EA-HL-DOUBLE-1d) : la feuille dit
    // la piece qui manque, avec le sablier.
    for (final _Cas cas in _cas) {
      if (cas.$2.width != 1440) continue;
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String nom = mode == ThemeMode.dark ? 'sombre' : 'clair';
        testWidgets('visionneuse 1440 $nom', (WidgetTester tester) async {
          await _monterAdmin(tester, (
            cas.$1,
            cas.$2,
            mode,
            cas.$4,
            cas.$5,
            cas.$6,
          ), chemin: Routes.adminPersonnesDossiers);
          await tester.tap(
            find.bySemanticsLabel(RegExp('^Ouvrir le dossier de Karim')),
          );
          await stabiliser(tester);
          final Finder bouton = find.text(t.dossiers.revue.voirPiece);
          await tester.ensureVisible(bouton);
          await stabiliser(tester);
          await tester.tap(bouton);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(find.text(t.dossiers.visionneuse.horsLigne), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(VisionneusePiece),
              matching: iconesHorsLigne(),
            ),
            findsNothing,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'ea_hl_double1d_visionneuse_1440_$nom')}',
          );
        });
      }
    }
  });
}
