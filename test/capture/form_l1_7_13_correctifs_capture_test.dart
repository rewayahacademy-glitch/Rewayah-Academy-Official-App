// Captures de recette des corrections du 08/10 de FORM-L1-7-13 : le refus de
// dossier (02D, focus dans la zone du motif apres « Refuser » a vide) et les
// deux signalements L7 passes en categorie « Autre » apres une phrase-type
// (champ libre seul). 320 a texte x2, clair et sombre (K-61).
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_parcours/libelles_parcours.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/tc_flux_academique/feuille_signalement.dart';

import 'outil_capture.dart';

const Size _taille = Size(320, 1400);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// 02D sur la vraie coque admin, en demonstration ; le texte passe a x2 une
/// fois le dossier ouvert (le tiroir a 200 % n'est pas l'objet).
Future<void> _refus(WidgetTester tester, ThemeMode mode) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesDemoAdmin(environnement: 'staging'),
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
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.admin);
  await stabiliser(tester);
  await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
  await stabiliser(tester);
  await tester.tap(
    find.descendant(
      of: find.byKey(AdminShell.tiroirKey),
      matching: find.text(AdminDomaine.personnes.libelle),
    ),
  );
  await stabiliser(tester);
  final Finder ligne = find.bySemanticsLabel(
    RegExp("^Ouvrir le dossier d(e |')Omar"),
  );
  await _toucher(tester, ligne);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await stabiliser(tester);
  await _toucher(tester, find.text(t.dossiers.refuser).first);
  // « Refuser » a vide : l'erreur, et le focus sur la premiere puce.
  await _toucher(tester, find.text(t.dossiers.refuser).last);
  expect(find.text(t.dossiers.refus.erreurVide), findsOneWidget);
  expect(
    FocusManager.instance.primaryFocus?.debugLabel,
    SelecteurMotif.focusPremierePuce,
  );
  await tester.ensureVisible(find.byKey(SelecteurMotif.clePuce(0)));
  await stabiliser(tester);
}

class _Ouvreur extends StatelessWidget {
  const _Ouvreur();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => FeuilleSignalement.ouvrir(
          context,
          groupeId: 'g1',
          academyId: 'RA-AB0012',
          prenomEleve: 'Amina',
          sessionId: 's1',
        ),
        child: const Text('ouvrir'),
      ),
    ),
  );
}

/// Le signalement du Teaching Core : une phrase-type, puis « Autre ».
Future<void> _signalementTc(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    hoteCapture(
      const _Ouvreur(),
      surcharges: <Override>[
        portSignalementProvider.overrideWithValue(SignalementMemoire('ens-1')),
      ],
      themeMode: mode,
      echelleTexte: 2,
    ),
  );
  await stabiliser(tester);
  await _toucher(tester, find.text('ouvrir'));
  await _toucher(
    tester,
    find.text(t.motifs.signalement.pedagogique.renforcement),
  );
  await _toucher(
    tester,
    find.text(libelleCategorieSignalement(CategorieSignalement.autre)).first,
  );
  expect(find.byKey(SelecteurMotif.cleAutre), findsNothing);
  expect(find.byType(TextField), findsNWidgets(2));
  await tester.ensureVisible(find.byType(TextField).last);
  await stabiliser(tester);
}

/// Le signalement de la fiche eleve (« Resume partageable »).
Future<void> _signalementFiche(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    hoteCapture(
      const EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte),
      themeMode: mode,
      echelleTexte: 2,
    ),
  );
  await stabiliser(tester);
  await _toucher(tester, find.text('Mariam').last);
  await _toucher(tester, find.byKey(FicheEleveEnseignant.signalerKey));
  Future<void> radio(CategorieBesoin c) => _toucher(
    tester,
    find.byWidgetPredicate(
      (Widget w) => w is Radio<CategorieBesoin> && w.value == c,
    ),
  );
  await radio(CategorieBesoin.pedagogique);
  await _toucher(
    tester,
    find.text(t.motifs.signalement.pedagogique.renforcement),
  );
  await radio(CategorieBesoin.autre);
  expect(find.byKey(SignalerBesoin.resumeKey), findsOneWidget);
  await tester.ensureVisible(find.byKey(SignalerBesoin.resumeKey));
  await stabiliser(tester);
}

void main() {
  group('Capture : FORM-L1-7-13, corrections du 08/10', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Future<void> Function(WidgetTester, ThemeMode) f)
          in <(String, Future<void> Function(WidgetTester, ThemeMode))>[
            ('refus_dossier', _refus),
            ('signalement_tc_autre', _signalementTc),
            ('signalement_fiche_autre', _signalementFiche),
          ]) {
        testWidgets('320x1400 @2 texte x2, $nom, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, _taille, 2);
          await f(tester, mode);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 'form_l1_7_13_fix_${nom}_320x1400@2_x2_${mode.name}')}',
          );
        });
      }
    }
  });
}
