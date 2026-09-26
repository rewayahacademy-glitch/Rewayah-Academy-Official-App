// Captures de recette AD-10 (P-ADM-08, 09, 11), sur la VRAIE application et
// le vrai routeur, en demonstration : coque admin (`?demo=admin`) et portail
// de la personne (`?demo=tuteur&dossier=...`). Modele :
// `ad9_politique_capture_test.dart`. Chaque etat est ouvert par des tap reels
// (K-07) ; seule la decision de l'administration vue par la personne est
// posee directement dans l'etat partage (le geste admin est prouve par
// `parcours_ad10_test.dart`).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ad10_<etat>_<taille>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import 'outil_capture.dart';

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

late GoRouter _routeur;

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  List<Override> surcharges,
  String depart,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: surcharges,
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              _routeur = ref.read(routeurProvider);
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
                routerConfig: _routeur,
                builder: (BuildContext context, Widget? child) =>
                    RepereDemonstration(child: child),
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  _routeur.go(depart);
  await _stabiliser(tester);
}

List<Override> _admin(EtatRevueDemo e) =>
    surchargesDemoAdmin(environnement: 'staging', etat: e);

List<Override> _personne(EtatRevueDemo e, String id) =>
    surchargesDemoTuteur(environnement: 'staging', dossiers: e, titulaire: id);

/// Personnes depuis la coque : rail, barre laterale ou tiroir mobile.
Future<void> _personnes(WidgetTester tester) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
  const AdminDomaine domaine = AdminDomaine.personnes;
  if (rail.evaluate().isNotEmpty) {
    await tester.tap(
      find
          .descendant(
            of: rail,
            matching: find.bySemanticsLabel(RegExp(domaine.libelle)),
          )
          .first,
    );
  } else {
    final bool mobile = barre.evaluate().isEmpty;
    if (mobile) {
      await tester.tap(find.bySemanticsLabel(t.nav.admin.menu));
      await _stabiliser(tester);
    }
    await tester.tap(
      find.descendant(
        of: mobile ? find.byKey(AdminShell.tiroirKey) : barre,
        matching: find.text(domaine.libelle),
      ),
    );
  }
  await _stabiliser(tester);
}

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

Future<void> _ouvrir(WidgetTester tester, String prenom) async {
  await _personnes(tester);
  await tester.ensureVisible(_ligne(prenom));
  await _stabiliser(tester);
  await tester.tap(_ligne(prenom));
  await _stabiliser(tester);
}

/// Descend jusqu'aux actions de la revue (la raison est dessous).
Future<void> _versActions(WidgetTester tester) async {
  await tester.ensureVisible(find.text(t.dossiers.approuver).first);
  await _stabiliser(tester);
}

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

EtatRevueDemo _etat() =>
    EtatRevueDemo.initial(maintenant: DateTime.utc(2026, 9, 26, 12));

const String _amina = DonneesDossiersDemo.tuteurDocumentaire;
const String _hana = DonneesDossiersDemo.familleDispensee;
const String _motif = 'Motif fictif : la photo de la pièce est floue.';

/// Refus d'Amina pose dans l'etat partage (le geste admin est teste ailleurs).
Future<void> _refuserAmina(EtatRevueDemo e) => RevueDossiersDemo(e).decider(
  dossierId: _amina,
  revisionAttendue: e.dossiers[_amina]!.revision,
  decision: DecisionDossier.refuser,
  commandeId: 'capture-refus',
  verificationsFaites: const <String>{},
  motif: _motif,
);

void main() {
  group('Capture : AD-10 parcours', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, String nom) in _tailles) {
        String fichier(String etat) => 'ad10_${etat}_${nom}_${mode.name}';

        testWidgets('$nom, admin, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, mode, _admin(_etat()), Routes.admin);

          // 3 : la file et ses pastilles.
          await _personnes(tester);
          await tester.ensureVisible(_ligne('Yanis'));
          await _stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, fichier('3_file_pastilles'))}',
          );

          // 1 : famille dispensee.
          await tester.ensureVisible(_ligne('Hana'));
          await _stabiliser(tester);
          await tester.tap(_ligne('Hana'));
          await _stabiliser(tester);
          expect(find.text(t.dossiers.revue.pieceNonRequise), findsOneWidget);
          await _versActions(tester);
          debugPrint(
            'PNG ${await capturer(tester, fichier('1_famille_dispensee'))}',
          );
        });

        testWidgets('$nom, piece absente, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, mode, _admin(_etat()), Routes.admin);
          await _ouvrir(tester, 'Yanis');
          await _versActions(tester);
          expect(
            find.text(t.dossiers.revue.pieceNonTransmise),
            findsNWidgets(2),
          );
          debugPrint(
            'PNG ${await capturer(tester, fichier('2_piece_absente'))}',
          );
        });

        testWidgets('$nom, resoumission cote admin, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo e = _etat();
          await _refuserAmina(e);
          e.resoumettre(_amina);
          await _monter(tester, mode, _admin(e), Routes.admin);
          await _ouvrir(tester, 'Amina');
          await _versActions(tester);
          debugPrint(
            'PNG ${await capturer(tester, fichier('7_file_resoumission'))}',
          );
        });

        testWidgets('$nom, personne, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo e = _etat();
          await _refuserAmina(e);

          // 4 : refus, motif, Corriger.
          await _monter(tester, mode, _personne(e, _amina), Routes.attente);
          expect(find.text(t.attente.refuse), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('4_attente_refus'))}',
          );

          // 6 : Corriger, depot fictif, retour en verification.
          await tester.tap(find.text(t.attente.corriger));
          await _stabiliser(tester);
          await tester.tap(find.text(t.kyc.passeport));
          await _stabiliser(tester);
          await tester.tap(find.text(t.kyc.choisirFichier));
          await _stabiliser(tester);
          await tester.tap(find.text(t.kyc.envoyer));
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(find.text(t.attente.actualiser), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('6_attente_resoumise'))}',
          );
        });

        testWidgets('$nom, correction impossible, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          // Le point d'entree de la demonstration en ligne (AD-BR-28) :
          // ?demo=tuteur&dossier=refuse-fige.
          final ({EtatRevueDemo dossiers, String titulaire}) fige =
              dossierTitulaireDemoPour(
                Uri.parse('/?demo=tuteur&dossier=refuse-fige'),
                maintenant: DateTime.utc(2026, 9, 26, 12),
              )!;
          await _monter(
            tester,
            mode,
            _personne(fige.dossiers, fige.titulaire),
            Routes.attente,
          );
          expect(find.text(t.attente.corriger), findsNothing);
          expect(find.text(t.attente.correctionImpossible), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('5_attente_correction_impossible'))}',
          );
        });

        testWidgets('$nom, retour apres validation, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo e = _etat();
          await _monter(tester, mode, _personne(e, _hana), Routes.attente);
          await RevueDossiersDemo(e).decider(
            dossierId: _hana,
            revisionAttendue: e.dossiers[_hana]!.revision,
            decision: DecisionDossier.valider,
            commandeId: 'capture-validation',
            verificationsFaites: const <String>{},
          );
          for (final AppLifecycleState s in <AppLifecycleState>[
            AppLifecycleState.inactive,
            AppLifecycleState.hidden,
            AppLifecycleState.paused,
            AppLifecycleState.hidden,
            AppLifecycleState.inactive,
            AppLifecycleState.resumed,
          ]) {
            tester.binding.handleAppLifecycleStateChanged(s);
          }
          await _stabiliser(tester);
          await _stabiliser(tester);
          expect(
            _routeur.routerDelegate.currentConfiguration.uri.path,
            startsWith(Routes.tuteurAccueil),
          );
          // Aucune donnee deduite de la decision (P-ADM-11.3).
          expect(find.textContaining('Aïcha'), findsNothing);
          expect(find.textContaining('Yusuf'), findsNothing);
          debugPrint(
            'PNG ${await capturer(tester, fichier('8_retour_valide'))}',
          );
        });
      }
    }

    // 200 % a 390 : les raisons s'empilent sans troncature.
    testWidgets('390, piece absente a 200 %', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(tester, ThemeMode.light, _admin(_etat()), Routes.admin);
      await _ouvrir(tester, 'Yanis');
      await _versActions(tester);
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'ad10_2_piece_absente_200_390x844@3_light')}',
      );
    });

    testWidgets('390, refus a 200 %', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final EtatRevueDemo e = _etat();
      await _refuserAmina(e);
      await _monter(
        tester,
        ThemeMode.light,
        _personne(e, _amina),
        Routes.attente,
      );
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'ad10_4_attente_refus_200_390x844@3_light')}',
      );
    });
  });
}
