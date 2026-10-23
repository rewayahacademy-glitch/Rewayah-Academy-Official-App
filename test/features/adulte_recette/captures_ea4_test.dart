// EA-4 : les captures de « Mon espace » de l'eleve adulte. Jamais sans
// `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Fichier propre a l'agent :
// ne pas confondre avec `captures_ea_test.dart` (poste B).
//
// Chaque capture d'ecran entier passe par la VRAIE route /demo/adulte
// (`adresseDemoAdulte`) sous un GoRouter, comme `captures_ea3_test.dart` :
// 390x844, 768x1024 et 1440x900, clair et sombre, plus le texte a 200 %.
//
// EA-4c (revue) : le titulaire, le second adulte rattache (« Forfait
// famille » et « Paiements du foyer », sa page d'arrivee), le second adulte
// detache (conjointQuitte), le cas 21 sans ligne (vue du second adulte) et
// avec « Ma famille » (vue du titulaire) ; puis les etats de la ligne
// famille, que la demonstration ne rend pas (chargement, erreur, hors ligne,
// indisponible) : la VRAIE page sur l'hote de capture, ses lectures
// surchargees.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../../capture/outil_capture.dart';

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// La vue grandit de ce qui reste a defiler, jusqu'a ce que plus rien ne
/// defile : la page entiere tient dans le PNG.
Future<void> _pleineHauteur(WidgetTester tester, Size taille) async {
  for (int i = 0; i < 4; i++) {
    double reste = 0;
    for (final ScrollableState s in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      if (s.position.axis == Axis.vertical &&
          s.position.maxScrollExtent > reste) {
        reste = s.position.maxScrollExtent;
      }
    }
    if (reste <= 0) break;
    fixerVueCapture(
      tester,
      Size(taille.width, tester.view.physicalSize.height + reste),
      1,
    );
    await stabiliser(tester);
  }
}

Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  String adresse,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool pleineHauteur = true,
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
  if (pleineHauteur) await _pleineHauteur(tester, taille);
  expect(tester.takeException(), isNull, reason: fichier);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

/// La VRAIE page Mon espace, seule, ses lectures surchargees : les etats de
/// la ligne famille que la demonstration ne rend pas.
Future<void> _capturerPage(
  WidgetTester tester,
  String fichier,
  List<Override> surcharges, {
  Size taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      const MonEspaceAdultePage(),
      surcharges: surcharges,
      themeMode: mode,
      echelleTexte: echelle,
    ),
  );
  await stabiliser(tester);
  await _pleineHauteur(tester, taille);
  expect(tester.takeException(), isNull, reason: fichier);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

void main() {
  group('Capture : EA-4', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    // Le titulaire, puis le second adulte rattache, aux trois largeurs. A
    // 1440, « Mon compte » et « Aide et support » partent a la meme hauteur.
    for (final (String qui, VueDemoAdulte vue) in <(String, VueDemoAdulte)>[
      ('titulaire', VueDemoAdulte.titulaire),
      ('conjoint', VueDemoAdulte.secondAdulte),
    ]) {
      for (final (String l, Size taille) in <(String, Size)>[
        ('390', const Size(390, 844)),
        ('768', const Size(768, 1024)),
        ('1440', const Size(1440, 900)),
      ]) {
        for (final ThemeMode mode in _modes) {
          final String fichier = 'ea4_mon_espace_${l}_${mode.name}_$qui';
          testWidgets(fichier, (WidgetTester tester) async {
            await _capturer(
              tester,
              fichier,
              adresseDemoAdulte(EcranDemoAdulte.monEspace, vue: vue),
              taille,
              mode: mode,
            );
          });
        }
      }
    }

    // Les autres situations de la ligne famille, en 390 clair et sombre.
    for (final (String nom, String adresse) in <(String, String)>[
      // « Ajouter ma famille » et sa phrase.
      (
        'adulte_seul',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.adulteSeul,
        ),
      ),
      // Le second adulte detache : « Ajouter ma famille ».
      (
        'conjoint_quitte',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.conjointQuitte,
          vue: VueDemoAdulte.secondAdulte,
        ),
      ),
      // Cas 21, l'invite : aucune ligne famille.
      (
        'deja_ailleurs_conjoint',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.dejaDansUnAutreFoyer,
          vue: VueDemoAdulte.secondAdulte,
        ),
      ),
      // Cas 21, le titulaire : « Ma famille ».
      (
        'deja_ailleurs_titulaire',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.dejaDansUnAutreFoyer,
        ),
      ),
      // Validation en attente, vue du second adulte : aucune ligne.
      (
        'validation_conjoint',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.validationEnAttente,
          vue: VueDemoAdulte.secondAdulte,
        ),
      ),
    ]) {
      for (final ThemeMode mode in _modes) {
        final String fichier = 'ea4_mon_espace_390_${mode.name}_$nom';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresse,
            const Size(390, 844),
            mode: mode,
          );
        });
      }
    }

    // Le texte a 200 % en 390 : le titulaire, l'adulte seul (la phrase la
    // plus longue) et le second adulte rattache (Paiements du foyer).
    for (final (String nom, String adresse) in <(String, String)>[
      ('titulaire', adresseDemoAdulte(EcranDemoAdulte.monEspace)),
      (
        'adulte_seul',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.adulteSeul,
        ),
      ),
      (
        'conjoint',
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          vue: VueDemoAdulte.secondAdulte,
        ),
      ),
    ]) {
      for (final ThemeMode mode in _modes) {
        final String fichier = 'ea4_mon_espace_390_${mode.name}_200pc_$nom';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturer(
            tester,
            fichier,
            adresse,
            const Size(390, 844),
            mode: mode,
            echelle: 2,
          );
        });
      }
    }

    // Les pages d'arrivee : « Paiements du foyer » du second adulte (titre
    // de la ligne tapee), « Paiements » du titulaire, « Mes accords » (sans
    // source) et « Preferences » (la vraie page du Compte).
    for (final ThemeMode mode in _modes) {
      final String fichier = 'ea4_paiements_foyer_390_${mode.name}_conjoint';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(
            EcranDemoAdulte.paiementsFoyer,
            vue: VueDemoAdulte.secondAdulte,
          ),
          const Size(390, 844),
          mode: mode,
        );
      });
    }
    for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
      EcranDemoAdulte.paiements,
      EcranDemoAdulte.accords,
      EcranDemoAdulte.preferences,
    ]) {
      final String fichier = 'ea4_${ecran.name}_390_light';
      testWidgets(fichier, (WidgetTester tester) async {
        await _capturer(
          tester,
          fichier,
          adresseDemoAdulte(ecran),
          const Size(390, 844),
        );
      });
    }
    // Cas 21, Ma famille du titulaire : l'invitation envoyee, neutre (F4).
    testWidgets('ea4_ma_famille_390_light_deja_ailleurs', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'ea4_ma_famille_390_light_deja_ailleurs',
        adresseDemoAdulte(
          EcranDemoAdulte.maFamille,
          etat: EtatDemoAdulte.dejaDansUnAutreFoyer,
        ),
        const Size(390, 844),
      );
    });

    // Les etats de la ligne famille, sur la vraie page.
    final Override identite = identiteTitulaireProvider.overrideWith(
      (Ref _) async => DonneesAdulteDemo.identite(
        GenreTitulaireDemo.homme,
        VueDemoAdulte.titulaire,
      ),
    );
    Override enLigne(bool horsLigne) => horsLigneProvider.overrideWith(
      (Ref _) => Stream<bool>.value(horsLigne),
    );
    final Map<String, List<Override> Function()> etats =
        <String, List<Override> Function()>{
          'famille_chargement': () => <Override>[
            enLigne(false),
            identite,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Completer<MonEspaceAdulteVM>().future,
            ),
          ],
          'famille_erreur': () => <Override>[
            enLigne(false),
            identite,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
            ),
          ],
          'famille_hors_ligne': () => <Override>[
            enLigne(true),
            identite,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
            ),
          ],
          'tout_hors_ligne': () => <Override>[
            enLigne(true),
            identiteTitulaireProvider.overrideWith(
              (Ref _) => Future<IdentiteTitulaire>.error(StateError('reseau')),
            ),
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Future<MonEspaceAdulteVM>.error(StateError('reseau')),
            ),
          ],
          // Les paiements et l'aide gardent leur fournisseur reel : « Non
          // disponible » a cote de leur legende, comme Cours et acces et Mes
          // accords.
          'famille_indisponible': () => <Override>[
            enLigne(false),
            identite,
            monEspaceAdulteProvider.overrideWith(
              (Ref _) => Future<MonEspaceAdulteVM>.error(
                const CapaciteIndisponible('mon_espace_eleve_adulte'),
              ),
            ),
          ],
        };
    for (final MapEntry<String, List<Override> Function()> e in etats.entries) {
      for (final ThemeMode mode in _modes) {
        final String fichier = 'ea4_mon_espace_390_${mode.name}_${e.key}';
        testWidgets(fichier, (WidgetTester tester) async {
          await _capturerPage(tester, fichier, e.value(), mode: mode);
        });
      }
    }
    // Les quatre « Non disponible » a cote des legendes, a 200 %.
    testWidgets('ea4_mon_espace_390_light_200pc_famille_indisponible', (
      WidgetTester tester,
    ) async {
      await _capturerPage(
        tester,
        'ea4_mon_espace_390_light_200pc_famille_indisponible',
        etats['famille_indisponible']!(),
        echelle: 2,
      );
    });
    // L'erreur de la ligne famille a 1440, dans la colonne de debut.
    testWidgets('ea4_mon_espace_1440_light_famille_erreur', (
      WidgetTester tester,
    ) async {
      await _capturerPage(
        tester,
        'ea4_mon_espace_1440_light_famille_erreur',
        etats['famille_erreur']!(),
        taille: const Size(1440, 900),
      );
    });
  });
}
