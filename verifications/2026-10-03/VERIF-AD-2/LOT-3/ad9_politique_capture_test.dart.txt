// Captures de recette AD-9 (politique de genre pour la revue KYC), sur la
// VRAIE coque admin et le vrai routeur, en demonstration (`?demo=admin`).
// Modele : `ad8_decisions_capture_test.dart`. Chaque etat est ouvert par des
// tap reels : barre laterale (ou tiroir), onglet, interrupteur (K-07).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// ad9_<etat>_<taille>_<mode>.png.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_dossiers/visionneuse_piece.dart';
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

/// Retient `modifier` (envoi en cours) ou fait echouer `lire` une fois.
class _PortCapture implements PortPolitiqueRevueKyc {
  _PortCapture(this._base);

  final PortPolitiqueRevueKyc _base;
  bool echecLecture = false;
  final Completer<void> porte = Completer<void>();
  bool retenir = false;
  Completer<void>? porteLecture;

  @override
  Future<PolitiqueRevueKyc> lire() async {
    if (echecLecture) {
      throw Exception('panne');
    }
    await porteLecture?.future;
    return _base.lire();
  }

  @override
  Future<PolitiqueRevueKyc> modifier({
    required bool genreRelecteurApplique,
    required int versionAttendue,
  }) async {
    if (retenir) {
      await porte.future;
    }
    return _base.modifier(
      genreRelecteurApplique: genreRelecteurApplique,
      versionAttendue: versionAttendue,
    );
  }
}

Future<void> _monter(
  WidgetTester tester,
  ThemeMode mode,
  EtatRevueDemo etat, {
  PortPolitiqueRevueKyc? port,
  Locale? langue,
  TextDirection? direction,
}) async {
  final List<Override> demo = surchargesDemoAdmin(
    environnement: 'staging',
    etat: etat,
  );
  if (port != null) {
    demo[2] = portPolitiqueRevueKycProvider.overrideWithValue(port);
  }
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: demo,
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
                locale: langue ?? TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: _routeur,
                builder: (BuildContext context, Widget? child) {
                  final Widget repere = RepereDemonstration(child: child);
                  // Miroir RTL sans changer la langue (memes clefs fr : ar
                  // n'a pas encore la section dossiers, K-10 reprend le
                  // motif deja prouve par tuteur_k_echelle_texte_test.dart
                  // et nav_shell_adaptatif_test.dart plutot que de charger
                  // une vraie locale arabe dans le test).
                  return direction == null
                      ? repere
                      : Directionality(textDirection: direction, child: repere);
                },
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  _routeur.go(Routes.admin);
  await _stabiliser(tester);
}

/// Un domaine depuis la coque : barre laterale, rail ou tiroir mobile.
Future<void> _domaine(WidgetTester tester, AdminDomaine domaine) async {
  final Finder barre = find.byKey(AdminShell.barreLateraleKey);
  final Finder rail = find.byKey(AdminShell.railKey);
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

Future<void> _ouvrirReglage(WidgetTester tester) async {
  await _domaine(tester, AdminDomaine.configuration);
  await tester.ensureVisible(find.text(t.admin.politiqueRevueKyc.titre));
  await _stabiliser(tester);
  await tester.tap(find.text(t.admin.politiqueRevueKyc.titre));
  await _stabiliser(tester);
}

Finder _ligne(String prenom) =>
    find.bySemanticsLabel(RegExp("^Ouvrir le dossier d(e |')$prenom"));

const List<(Size, String)> _tailles = <(Size, String)>[
  (Size(390, 844), '390x844@3'),
  (Size(768, 1024), '768x1024@1'),
  (Size(1440, 900), '1440x900@1'),
];

double _densite(String nom) => nom.contains('@3') ? 3 : 1;

EtatRevueDemo _etat({bool superAdmin = true, bool genre = true}) =>
    EtatRevueDemo.initial(
      maintenant: DateTime.utc(2026, 9, 26, 12),
      superAdmin: superAdmin,
      genreRelecteurRenseigne: genre,
    );

void main() {
  group('Capture : AD-9 politique de genre', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, String nom) in _tailles) {
        String fichier(String etat) => 'ad9_${etat}_${nom}_${mode.name}';

        // 1, 2, 10, 11 : reglage active, bascule, puis file et 02C.
        testWidgets('$nom, reglage puis file, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, mode, _etat());
          await _ouvrirReglage(tester);
          expect(find.byType(Switch), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('1_active'))}');
          await tester.tap(find.byType(Switch));
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('2_desactive'))}');
          await _domaine(tester, AdminDomaine.personnes);
          await tester.scrollUntilVisible(
            _ligne('Adam'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('10_file'))}');
          await tester.tap(_ligne('Adam'));
          await _stabiliser(tester);
          await tester.ensureVisible(find.text('Voir la pièce'));
          await _stabiliser(tester);
          await tester.tap(find.text('Voir la pièce'));
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('11_piece'))}');

          // 12, 13 : la decision sur Adam (06) n'est plus bloquee.
          await tester.tap(
            find.descendant(
              of: find.byType(VisionneusePiece),
              matching: find.text(t.commun.fermer),
            ),
          );
          await _stabiliser(tester);
          for (final String point in <String>[
            t.dossiers.pointLisible,
            t.dossiers.pointNom,
            t.dossiers.pointValidite,
          ]) {
            await tester.ensureVisible(find.text(point).first);
            await _stabiliser(tester);
            await tester.tap(find.text(point).first);
            await _stabiliser(tester);
          }
          await tester.ensureVisible(find.text(t.dossiers.approuver).first);
          await _stabiliser(tester);
          await tester.tap(find.text(t.dossiers.approuver).first);
          await _stabiliser(tester);
          expect(find.text(t.dossiers.validation.titre), findsOneWidget);
          debugPrint('PNG ${await capturer(tester, fichier('12_decision'))}');
          await tester.tap(find.text(t.dossiers.approuver).last);
          await _stabiliser(tester);
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('13_valide'))}');
        });

        // 6 : chargement (squelette partage).
        testWidgets('$nom, chargement, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo etat = _etat();
          final _PortCapture port = _PortCapture(PolitiqueRevueKycDemo(etat))
            ..porteLecture = Completer<void>();
          await _monter(tester, mode, etat, port: port);
          _routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
          await _stabiliser(tester);
          expect(find.byType(Skeleton), findsWidgets);
          debugPrint('PNG ${await capturer(tester, fichier('6_chargement'))}');
          port.porteLecture!.complete();
          await _stabiliser(tester);
        });

        // 14 : port de production, « Pas encore disponible ».
        testWidgets('$nom, indisponible, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(
            tester,
            mode,
            _etat(),
            port: const PolitiqueRevueKycIndisponible(),
          );
          _routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
          await _stabiliser(tester);
          expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, fichier('14_indisponible'))}',
          );
        });

        // 3 : envoi en cours.
        testWidgets('$nom, envoi, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo etat = _etat();
          final _PortCapture port = _PortCapture(PolitiqueRevueKycDemo(etat))
            ..retenir = true;
          await _monter(tester, mode, etat, port: port);
          await _ouvrirReglage(tester);
          await tester.tap(find.byType(Switch));
          await tester.pump();
          debugPrint('PNG ${await capturer(tester, fichier('3_envoi'))}');
          port.porte.complete();
          await _stabiliser(tester);
        });

        // 4 : conflit de version.
        testWidgets('$nom, conflit, ${mode.name}', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo etat = _etat();
          await _monter(tester, mode, etat);
          await _ouvrirReglage(tester);
          etat.versionPolitique += 1;
          await tester.tap(find.byType(Switch));
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('4_conflit'))}');
        });

        // 5 : echec de lecture (route ouverte depuis l'onglet, puis panne).
        testWidgets('$nom, echec lecture, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          final EtatRevueDemo etat = _etat();
          final _PortCapture port = _PortCapture(PolitiqueRevueKycDemo(etat));
          await _monter(tester, mode, etat, port: port);
          port.echecLecture = true;
          _routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('5_echec'))}');
        });

        // 7, 8 : sans Super Admin.
        testWidgets('$nom, sans Super Admin, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, mode, _etat(superAdmin: false));
          await _domaine(tester, AdminDomaine.configuration);
          expect(find.text(t.admin.politiqueRevueKyc.titre), findsNothing);
          debugPrint(
            'PNG ${await capturer(tester, fichier('7_trois_onglets'))}',
          );
          _routeur.go(Routes.adminConfigurationPolitiqueRevueKyc);
          await _stabiliser(tester);
          debugPrint('PNG ${await capturer(tester, fichier('8_refuse'))}');
        });

        // 9 : Profil a completer.
        testWidgets('$nom, profil a completer, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, _densite(nom));
          await _monter(tester, mode, _etat(genre: false));
          await _domaine(tester, AdminDomaine.personnes);
          expect(find.text(t.dossiers.profilACompleter.titre), findsWidgets);
          debugPrint('PNG ${await capturer(tester, fichier('9_profil'))}');
        });
      }
    }

    // RTL (miroir, meme texte francais) 390 clair, et 200 % en 390, etat 1.
    testWidgets('390, etat 1 en RTL', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await _monter(
        tester,
        ThemeMode.light,
        _etat(),
        direction: TextDirection.rtl,
      );
      await _ouvrirReglage(tester);
      final Rect interrupteur = tester.getRect(find.byType(Switch));
      expect(interrupteur.center.dx, lessThan(195));
      debugPrint(
        'PNG ${await capturer(tester, 'ad9_1_active_rtl_390x844@3_light')}',
      );
    });

    testWidgets('390, etat 1 a 200 %', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _monter(tester, ThemeMode.light, _etat());
      await _ouvrirReglage(tester);
      expect(tester.takeException(), isNull);
      debugPrint(
        'PNG ${await capturer(tester, 'ad9_1_active_200_390x844@3_light')}',
      );
    });
  });
}
