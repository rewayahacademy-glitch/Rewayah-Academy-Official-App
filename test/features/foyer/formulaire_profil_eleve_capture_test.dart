// Captures de recette de l'ajout d'un profil eleve (lot B, sous-paquet 2),
// sur le VRAI routeur : 390x844 et 1440x900, clair et sombre, chaque etat,
// et les planches maquette | rendu contre le gabarit d'etape V6 (#12 E1
// « pour qui », #14 E3 « age »).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Planches :
// CAPTURE_MAQUETTE_E1 et CAPTURE_MAQUETTE_E3 (panneaux decoupes de
// « onboarding mobile 1.png », x 150 et 1195, y 55, 462 x 784 px).
// Donnees : fixtures de test uniquement.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/faux_creation_profil_eleve.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';
import '../../support/pressable_de.dart';

final String? _maquetteE1 = Platform.environment['CAPTURE_MAQUETTE_E1'];
final String? _maquetteE3 = Platform.environment['CAPTURE_MAQUETTE_E3'];

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

/// Ce que chaque capture met en place avant la prise de vue.
enum _Etat {
  pourQuiVierge,
  pourQuiChoisi,
  porteAttente,
  identiteVierge,
  identiteErreurs,
  identiteRemplie,
  envoiEnCours,
  refusDossier,
  reponsePerdue,
  horsLigne,
}

Future<void> _monter(
  WidgetTester tester,
  _Etat etat, {
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  final FauxCreationProfilEleve port = FauxCreationProfilEleve(
    resultat: switch (etat) {
      _Etat.refusDossier => const CreationRefusee(
        MotifRefusCreation.compteNonValide,
      ),
      _Etat.reponsePerdue => const CreationIncertaine(),
      _ => const ProfilCree(),
    },
  );
  if (etat == _Etat.envoiEnCours) {
    port.attente = Completer<void>();
  }
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: FauxServiceAppairage()
            ..elevesRendus = FoyersFictifs.foyerA,
        ),
        horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
        portCreationProfilEleveProvider.overrideWithValue(port),
        if (etat == _Etat.porteAttente)
          porteAjoutProfilProvider.overrideWithValue(PorteAcces.attente),
        if (etat == _Etat.horsLigne)
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
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
  routeur.go(Routes.tuteurAjouterEnfant);
  await stabiliser(tester);

  Future<void> toucher(Key cle) async {
    await tester.tap(pressableDe(find.byKey(cle)));
    await stabiliser(tester);
  }

  if (etat == _Etat.pourQuiVierge || etat == _Etat.porteAttente) {
    return;
  }
  await tester.tap(find.text(t.foyer.ajout.pourQui.enfantTitre));
  await stabiliser(tester);
  if (etat == _Etat.pourQuiChoisi) {
    return;
  }
  await toucher(FormulaireProfilEleve.actionKey);
  if (etat == _Etat.identiteVierge) {
    return;
  }
  if (etat == _Etat.identiteErreurs) {
    await tester.enterText(find.byKey(FormulaireProfilEleve.ageKey), '25');
    await toucher(FormulaireProfilEleve.actionKey);
    return;
  }
  await tester.enterText(
    find.byKey(FormulaireProfilEleve.prenomKey),
    'Eleve A3',
  );
  await tester.enterText(find.byKey(FormulaireProfilEleve.nomKey), 'Fictif');
  await tester.enterText(find.byKey(FormulaireProfilEleve.ageKey), '9');
  // Le clavier ne reste pas ouvert sur la capture.
  FocusManager.instance.primaryFocus?.unfocus();
  await stabiliser(tester);
  if (etat == _Etat.identiteRemplie || etat == _Etat.horsLigne) {
    return;
  }
  await tester.tap(pressableDe(find.byKey(FormulaireProfilEleve.actionKey)));
  if (etat == _Etat.envoiEnCours) {
    await tester.pump();
    return;
  }
  await stabiliser(tester);
}

Future<(int, int)> _taillePx(WidgetTester tester, String chemin) async {
  late int l;
  late int h;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      await File(chemin).readAsBytes(),
    );
    final ui.Image image = (await codec.getNextFrame()).image;
    l = image.width;
    h = image.height;
    image.dispose();
  });
  return (l, h);
}

Future<void> _planche(
  WidgetTester tester, {
  required String nom,
  required String maquette,
  required _Etat etat,
}) async {
  final (int l, int h) = await _taillePx(tester, maquette);
  fixerVueMaquette(
    tester,
    largeurPx: l,
    hauteurPx: h,
    largeurLogique: 390,
    zoneSure: _zoneSure,
  );
  // La maquette est sombre : le rendu aussi.
  await _monter(tester, etat, mode: ThemeMode.dark);
  debugPrint('PNG ${await capturerEtComparer(tester, nom, maquette)}');
}

void main() {
  group('Capture : ajout d un profil eleve', skip: sautSansCapture, () {
    setUpAll(() async {
      final List<String> familles = await chargerPolicesDuDepot();
      debugPrint('FAMILLES chargees : ${familles.join(', ')}');
    });

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille, double densite) format
          in <(String, Size, double)>[
            ('390x844@3', const Size(390, 844), 3),
            ('1440x900@1', const Size(1440, 900), 1),
          ]) {
        testWidgets('${format.$1}, tous les etats, ${mode.name}', (
          WidgetTester tester,
        ) async {
          final EdgeInsets zone = format.$3 == 3 ? _zoneSure : EdgeInsets.zero;
          fixerVueCapture(tester, format.$2, format.$3, zoneSure: zone);
          for (final _Etat etat in _Etat.values) {
            await _monter(tester, etat, mode: mode);
            debugPrint(
              'PNG ${await capturer(tester, 'ajout_${etat.name}_${format.$1}_${mode.name}')}',
            );
          }
        });
      }
    }

    testWidgets(
      'planche : pour qui contre E1 (#12)',
      skip: _maquetteE1 == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'ajout_pour_qui_contre_E1',
          maquette: _maquetteE1!,
          etat: _Etat.pourQuiChoisi,
        );
      },
    );

    testWidgets(
      'planche : identite contre E3 (#14)',
      skip: _maquetteE3 == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'ajout_identite_contre_E3',
          maquette: _maquetteE3!,
          etat: _Etat.identiteRemplie,
        );
      },
    );
  });
}
