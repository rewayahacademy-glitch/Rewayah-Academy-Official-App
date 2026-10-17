// EA-HL-DOUBLE-1 : captures de preuve de « hors ligne dit une seule fois ».
// Le bandeau de PageShell est le seul signal ; sans donnees, le bloc dit ce
// qui manque (Accueil, Ma classe, Mon espace) ; avec donnees, aucun bloc.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Chaque capture verifie aussi qu'aucun mot n'est coupe ni tronque, et que
// « hors ligne » n'est ecrit qu'une fois.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/offline_banner.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../router/support_routeur.dart' show sessionActive;
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';
import 'outil_capture.dart';

Future<void> _verifier(WidgetTester tester, {required bool sansDonnees}) async {
  expect(tester.takeException(), isNull);
  expectHorsLigneUneFois();
  expect(
    find.byType(EtatSansDonnees),
    sansDonnees ? findsOneWidget : findsNothing,
  );
  verifierAucunMotCoupe(tester, find.byType(OfflineBanner));
  if (sansDonnees) {
    verifierAucunMotCoupe(tester, find.byType(EtatSansDonnees));
  }
}

Future<void> _route(
  WidgetTester tester,
  String nom,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  InterfaceMode interface = InterfaceMode.standard,
  required bool sansDonnees,
}) async {
  fixerVueCapture(tester, taille, 1);
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('dev'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(interface, Brightness.light),
              darkTheme: AppTheme.pour(interface, Brightness.dark),
              themeMode: mode,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? app) => Directionality(
                textDirection: sens,
                child: MediaQuery(
                  data: MediaQuery.of(contexte)
                      .copyWith(textScaler: TextScaler.linear(echelle)),
                  child: app!,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  await _verifier(tester, sansDonnees: sansDonnees);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final String accueilCoupe = adresseDemoAdulte(
      EcranDemoAdulte.accueil,
      reseauCoupe: true,
    );
    final String maClasseCoupe = adresseDemoAdulte(
      EcranDemoAdulte.maClasse,
      reseauCoupe: true,
    );
    final String accueilHorsLigne = adresseDemoAdulte(
      EcranDemoAdulte.accueil,
      seance: EtatDemoClasse.horsLigne,
    );
    final String maClasseHorsLigne = adresseDemoAdulte(
      EcranDemoAdulte.maClasse,
      seance: EtatDemoClasse.horsLigne,
    );

    // Sans donnees : le bandeau, puis le bloc qui dit ce qui manque.
    for (final (String, String, Size, ThemeMode, double, TextDirection) cas
        in <(String, String, Size, ThemeMode, double, TextDirection)>[
          (
            'accueil_sans_donnees_390_clair',
            accueilCoupe,
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'accueil_sans_donnees_390_sombre',
            accueilCoupe,
            const Size(390, 844),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
          ),
          (
            'accueil_sans_donnees_320x2_clair',
            accueilCoupe,
            const Size(320, 900),
            ThemeMode.light,
            2,
            TextDirection.ltr,
          ),
          (
            'accueil_sans_donnees_320x2_rtl_clair',
            accueilCoupe,
            const Size(320, 900),
            ThemeMode.light,
            2,
            TextDirection.rtl,
          ),
          (
            'accueil_sans_donnees_1440_clair',
            accueilCoupe,
            const Size(1440, 900),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'ma_classe_sans_donnees_390_clair',
            maClasseCoupe,
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            'ma_classe_sans_donnees_320x2_clair',
            maClasseCoupe,
            const Size(320, 900),
            ThemeMode.light,
            2,
            TextDirection.ltr,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _route(
          tester,
          'ea_hl_double1_${cas.$1}',
          cas.$2,
          cas.$3,
          mode: cas.$4,
          echelle: cas.$5,
          sens: cas.$6,
          sansDonnees: true,
        );
      });
    }

    // Avec donnees : le bandeau seul ; la ligne d'entree dit quand entrer.
    for (final (String, String, Size, double, TextDirection) cas
        in <(String, String, Size, double, TextDirection)>[
          (
            'accueil_avec_donnees_390_clair',
            accueilHorsLigne,
            const Size(390, 844),
            1,
            TextDirection.ltr,
          ),
          (
            'accueil_avec_donnees_320x2_clair',
            accueilHorsLigne,
            const Size(320, 900),
            2,
            TextDirection.ltr,
          ),
          (
            'ma_classe_avec_donnees_390_clair',
            maClasseHorsLigne,
            const Size(390, 844),
            1,
            TextDirection.ltr,
          ),
          (
            'ma_classe_avec_donnees_320x2_rtl_clair',
            maClasseHorsLigne,
            const Size(320, 900),
            2,
            TextDirection.rtl,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _route(
          tester,
          'ea_hl_double1_${cas.$1}',
          cas.$2,
          cas.$3,
          echelle: cas.$4,
          sens: cas.$5,
          sansDonnees: false,
        );
      });
    }

    // Reprise apres revue adverse (m2) : sombre, 1440 et Interface guidee
    // pour l'Accueil et Ma classe, avec et sans donnees.
    for (final (String, String, Size, ThemeMode, InterfaceMode, bool) cas
        in <(String, String, Size, ThemeMode, InterfaceMode, bool)>[
          (
            'accueil_avec_donnees_390_sombre',
            accueilHorsLigne,
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            false,
          ),
          (
            'accueil_avec_donnees_1440_clair',
            accueilHorsLigne,
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            false,
          ),
          (
            'accueil_avec_donnees_390_guidee',
            accueilHorsLigne,
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            false,
          ),
          (
            'accueil_sans_donnees_390_guidee',
            accueilCoupe,
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            true,
          ),
          (
            'ma_classe_avec_donnees_390_sombre',
            maClasseHorsLigne,
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            false,
          ),
          (
            'ma_classe_avec_donnees_1440_clair',
            maClasseHorsLigne,
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            false,
          ),
          (
            'ma_classe_avec_donnees_390_guidee',
            maClasseHorsLigne,
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
            false,
          ),
          (
            'ma_classe_sans_donnees_390_sombre',
            maClasseCoupe,
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
            true,
          ),
          (
            'ma_classe_sans_donnees_1440_clair',
            maClasseCoupe,
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
            true,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        await _route(
          tester,
          'ea_hl_double1_${cas.$1}',
          cas.$2,
          cas.$3,
          mode: cas.$4,
          interface: cas.$5,
          sansDonnees: cas.$6,
        );
      });
    }

    // Mon espace avec donnees : identite et famille lues, le bandeau seul.
    for (final (String, Size, ThemeMode, InterfaceMode) cas
        in <(String, Size, ThemeMode, InterfaceMode)>[
          (
            'mon_espace_avec_donnees_390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            InterfaceMode.standard,
          ),
          (
            'mon_espace_avec_donnees_1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            InterfaceMode.standard,
          ),
          (
            'mon_espace_avec_donnees_390_guidee',
            const Size(390, 844),
            ThemeMode.light,
            InterfaceMode.enfant,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            const MonEspaceAdultePage(),
            surcharges: <Override>[
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(true),
              ),
              // L11 : la session lue en memoire, jamais le vrai client.
              sourceSessionProvider.overrideWithValue(
                FausseSourceSession(sessionActive(AppRole.guardian)),
              ),
              identiteTitulaireProvider.overrideWith(
                (Ref _) async => DonneesAdulteDemo.identite(
                  GenreTitulaireDemo.homme,
                  VueDemoAdulte.titulaire,
                ),
              ),
              monEspaceAdulteProvider.overrideWith(
                (Ref _) async => const MonEspaceAdulteVM(
                  ligneFamille: LigneFamilleAdulte.maFamille,
                ),
              ),
            ],
            themeMode: cas.$3,
            interfaceMode: cas.$4,
          ),
        );
        await stabiliser(tester);
        await _verifier(tester, sansDonnees: false);
        // L'adresse ne se coupe pas, meme en Interface guidee.
        verifierAucunMotCoupe(tester, find.byType(MonEspaceAdultePage));
        debugPrint('PNG ${await capturer(tester, 'ea_hl_double1_${cas.$1}')}');
      });
    }

    // Mon espace : l'identite et la ligne famille en echec, un seul bloc.
    for (final (String, Size, double) cas in <(String, Size, double)>[
      ('mon_espace_sans_donnees_390_clair', const Size(390, 844), 1),
      ('mon_espace_sans_donnees_320x2_clair', const Size(320, 900), 2),
    ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await tester.pumpWidget(
          hoteCapture(
            const MonEspaceAdultePage(),
            surcharges: <Override>[
              horsLigneProvider.overrideWith(
                (Ref _) => Stream<bool>.value(true),
              ),
              // L11 : la session lue en memoire, jamais le vrai client.
              sourceSessionProvider.overrideWithValue(
                FausseSourceSession(sessionActive(AppRole.guardian)),
              ),
              identiteTitulaireProvider.overrideWith(
                (Ref _) => Future<IdentiteTitulaire>.error(StateError('x')),
              ),
              monEspaceAdulteProvider.overrideWith(
                (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('x')),
              ),
            ],
            echelleTexte: cas.$3,
          ),
        );
        await stabiliser(tester);
        await _verifier(tester, sansDonnees: true);
        expect(find.text(t.adulte.monEspace.sansDonneesCompte), findsOneWidget);
        debugPrint('PNG ${await capturer(tester, 'ea_hl_double1_${cas.$1}')}');
      });
    }
  });
}
