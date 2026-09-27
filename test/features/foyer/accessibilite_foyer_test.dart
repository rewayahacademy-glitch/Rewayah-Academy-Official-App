// Accessibilite des ecrans du lot B (Foyer et fiche eleve), sur le VRAI
// routeur : 200 % de taille de texte et lecture de droite a gauche (RTL) a
// 390 sur 844, sans aucune exception de debordement ; cibles tactiles de 48
// et contraste du texte sur le Foyer et la fiche.
//
// Revue du lot B (lentille « preuve ») : seul `AjouterEnfantPage` etait
// mesure par `test/accessibilite/rtl_echelle_texte_ecrans_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart'
    show TranslationProvider;
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Un eleve au prenom long, avec une echeance d'acces : les legendes les plus
/// longues du lot (« Pas encore de classe · Acces jusqu'au 30 octobre 2026 »).
final List<EleveDuFoyer> _foyer = <EleveDuFoyer>[
  ...FoyersFictifs.foyerA,
  EleveDuFoyer(
    id: 'foyer-a-eleve-long',
    prenom: 'Abderrahmane-Mohamed',
    identifiantImmuable: 'STUD-FA-000099',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.allowed,
    finAcces: DateTime(2026, 10, 30, 12),
  ),
];

Future<GoRouter> _monter(
  WidgetTester tester, {
  required String depart,
  TextDirection direction = TextDirection.ltr,
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = _foyer;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        horlogeFoyerProvider.overrideWithValue(() => DateTime(2026, 9, 24, 12)),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, luminosite),
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(contexte).copyWith(
                  textScaler: TextScaler.linear(echelle),
                  disableAnimations: true,
                ),
                child: Directionality(
                  textDirection: direction,
                  child: enfant ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

void main() {
  final String a1 = FoyersFictifs.a1.id;
  const String long = 'foyer-a-eleve-long';

  final Map<String, String> ecrans = <String, String>{
    'Foyer': Routes.tuteurFoyer,
    'Creer mon profil eleve': Routes.tuteurAjouterPourMoi,
    'Ajout de profil': Routes.tuteurAjouterEnfant,
    'Fiche': Routes.ficheElevePour(long),
    'Fiche A1': Routes.ficheElevePour(a1),
    'Informations': Routes.ficheEleveSousPage(long, 'informations'),
    'Parcours et inscription': Routes.ficheEleveSousPage(long, 'inscription'),
    'Interface': Routes.ficheEleveSousPage(long, 'interface'),
    'Camera': Routes.ficheEleveSousPage(long, 'camera'),
    'Acces': Routes.ficheEleveSousPage(long, 'acces'),
  };

  group('200 % et RTL a 390 sur 844 : aucun debordement', () {
    for (final MapEntry<String, String> ecran in ecrans.entries) {
      for (final (String nom, TextDirection direction, double echelle)
          in <(String, TextDirection, double)>[
            ('200 %', TextDirection.ltr, 2),
            ('RTL', TextDirection.rtl, 1),
            ('RTL a 200 %', TextDirection.rtl, 2),
          ]) {
        testWidgets('${ecran.key} : $nom', (WidgetTester tester) async {
          final GoRouter routeur = await _monter(
            tester,
            depart: ecran.value,
            direction: direction,
            echelle: echelle,
          );
          expect(lieu(routeur), ecran.value);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Cibles tactiles et contraste', () {
    for (final (String nom, String Function() chemin)
        in <(String, String Function())>[
          ('Foyer', () => Routes.tuteurFoyer),
          ('Fiche', () => Routes.ficheElevePour(a1)),
        ]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets('$nom (${luminosite.name}) : cibles de 48 et contraste '
            'du texte', (WidgetTester tester) async {
          final SemanticsHandle semantique = tester.ensureSemantics();
          await _monter(tester, depart: chemin(), luminosite: luminosite);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantique.dispose();
        });
      }
    }
  });
}
