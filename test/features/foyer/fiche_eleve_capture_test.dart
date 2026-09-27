// Captures de recette de la fiche eleve (lot B, sous-paquet 3), sur le VRAI
// routeur : 390x844 et 1440x900, clair et sombre, la fiche, ses cinq
// sous-pages et leurs etats, et les planches maquette | rendu.
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Planches :
// CAPTURE_MAQUETTE_PROFIL (ancienne capture « Profil », fiche de l'eleve,
// contenu seulement), CAPTURE_MAQUETTE_COMPTE_MOBILE et
// CAPTURE_MAQUETTE_COMPTE_BUREAU (high-fi « Mon compte », reference de rendu
// des groupes a filets, manifeste section 2). Donnees : fixtures de test
// uniquement.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../router/support_routeur.dart' hide stabiliser;
import '../../support/harnais.dart';

final String? _maquetteProfil = Platform.environment['CAPTURE_MAQUETTE_PROFIL'];
final String? _maquetteCompteMobile =
    Platform.environment['CAPTURE_MAQUETTE_COMPTE_MOBILE'];
final String? _maquetteCompteBureau =
    Platform.environment['CAPTURE_MAQUETTE_COMPTE_BUREAU'];

final DateTime _maintenant = DateTime(2026, 9, 24, 12);

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

const String _id = 'foyer-a-eleve-1';

/// Une image PNG valide d'un pixel, pour l'apercu.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Un eleve fictif, echeance passee pour montrer « Expire ».
final List<EleveDuFoyer> _eleves = <EleveDuFoyer>[
  EleveDuFoyer(
    id: _id,
    prenom: 'Eleve A1',
    identifiantImmuable: 'STUD-FA-000001',
    mode: InterfaceMode.enfant,
    camera: CameraPolicy.forbidden,
    finAcces: DateTime(2026, 9, 1, 12),
  ),
];

final FauxClassesFoyer _classes = FauxClassesFoyer(
  classes: <ClasseFoyer>[ClasseFoyer(eleveId: _id, classe: classeFictive())],
);

class _Appairage extends FauxServiceAppairage {
  bool echoue = false;
  bool attend = false;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    if (attend) {
      await Completer<void>().future;
    }
    if (echoue) {
      throw Exception('lecture refusee');
    }
    return elevesRendus;
  }
}

Future<void> _monter(
  WidgetTester tester,
  String depart, {
  ThemeMode mode = ThemeMode.light,
  _Appairage? appairage,
  bool avecClasses = true,
  bool horsLigne = false,
}) async {
  late GoRouter routeur;
  final _Appairage service =
      appairage ?? (_Appairage()..elevesRendus = _eleves);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: service,
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        selecteurPhotoProvider.overrideWithValue(
          FauxSelecteurPhoto(PhotoEnfant(octets: _png, nomFichier: 'a.png')),
        ),
        if (avecClasses) portClassesFoyerProvider.overrideWithValue(_classes),
        if (horsLigne)
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
  routeur.go(depart);
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
  required double largeurLogique,
  EdgeInsets zoneSure = EdgeInsets.zero,
  ThemeMode mode = ThemeMode.light,
}) async {
  final (int l, int h) = await _taillePx(tester, maquette);
  fixerVueMaquette(
    tester,
    largeurPx: l,
    hauteurPx: h,
    largeurLogique: largeurLogique,
    zoneSure: zoneSure,
  );
  await _monter(tester, Routes.ficheElevePour(_id), mode: mode);
  debugPrint('PNG ${await capturerEtComparer(tester, nom, maquette)}');
}

void main() {
  group('Capture : fiche eleve', skip: sautSansCapture, () {
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

    final Map<String, String> pages = <String, String>{
      'fiche': Routes.ficheElevePour(_id),
      'informations': Routes.ficheEleveSousPage(_id, 'informations'),
      'inscription': Routes.ficheEleveSousPage(_id, 'inscription'),
      'interface': Routes.ficheEleveSousPage(_id, 'interface'),
      'camera': Routes.ficheEleveSousPage(_id, 'camera'),
      'acces': Routes.ficheEleveSousPage(_id, 'acces'),
    };

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size taille, double densite) format
          in <(String, Size, double)>[
            ('390x844@3', const Size(390, 844), 3),
            ('1440x900@1', const Size(1440, 900), 1),
          ]) {
        final EdgeInsets zone = format.$3 == 3 ? _zoneSure : EdgeInsets.zero;

        testWidgets('${format.$1}, pages, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, format.$2, format.$3, zoneSure: zone);
          for (final MapEntry<String, String> page in pages.entries) {
            await _monter(tester, page.value, mode: mode);
            debugPrint(
              'PNG ${await capturer(tester, 'fiche_${page.key}_${format.$1}_${mode.name}')}',
            );
          }
          // La photo choisie, en apercu avant envoi.
          await _monter(tester, pages['informations']!, mode: mode);
          await tester.tap(find.byKey(EditeurPhotoEleve.choisirKey));
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_informations_apercu_${format.$1}_${mode.name}')}',
          );
          // Production : classes sans service.
          await _monter(
            tester,
            pages['inscription']!,
            mode: mode,
            avecClasses: false,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_inscription_classes_indisponibles_${format.$1}_${mode.name}')}',
          );
        });

        testWidgets('${format.$1}, etats, ${mode.name}', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, format.$2, format.$3, zoneSure: zone);
          final Map<String, _Appairage Function()> etats =
              <String, _Appairage Function()>{
                'erreur': () => _Appairage()..echoue = true,
                'chargement': () => _Appairage()..attend = true,
              };
          for (final MapEntry<String, _Appairage Function()> e
              in etats.entries) {
            await _monter(
              tester,
              pages['fiche']!,
              mode: mode,
              appairage: e.value(),
            );
            debugPrint(
              'PNG ${await capturer(tester, 'fiche_${e.key}_${format.$1}_${mode.name}')}',
            );
          }
          await _monter(
            tester,
            pages['fiche']!,
            mode: mode,
            appairage: _Appairage()..echoue = true,
            horsLigne: true,
          );
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_hors_ligne_${format.$1}_${mode.name}')}',
          );
          await _monter(tester, Routes.ficheElevePour('inconnu'), mode: mode);
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_introuvable_${format.$1}_${mode.name}')}',
          );
        });
      }
    }

    testWidgets(
      'planche : fiche mobile contre l ancienne capture « Profil » (contenu)',
      skip: _maquetteProfil == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'fiche_mobile_contre_profil',
          maquette: _maquetteProfil!,
          largeurLogique: 390,
          zoneSure: _zoneSure,
          // L'ancienne capture est en sombre.
          mode: ThemeMode.dark,
        );
      },
    );

    testWidgets(
      'planche : fiche mobile contre Mon compte mobile (rendu des groupes)',
      skip: _maquetteCompteMobile == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'fiche_mobile_contre_compte_mobile',
          maquette: _maquetteCompteMobile!,
          largeurLogique: 390,
          zoneSure: _zoneSure,
        );
      },
    );

    testWidgets(
      'planche : fiche bureau contre Mon compte bureau (colonnes)',
      skip: _maquetteCompteBureau == null,
      (WidgetTester tester) async {
        await _planche(
          tester,
          nom: 'fiche_bureau_contre_compte_bureau',
          maquette: _maquetteCompteBureau!,
          largeurLogique: 1440,
        );
      },
    );
  });
}
