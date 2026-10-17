// RECH-2 : l'ecran de recherche dans tous ses formats, sur le port de
// demonstration : mobile, tablette, bureau, texte x2 a 320, arabe et RTL,
// Interface guidee, puces de domaine (spec RECH-03 §4.2 a 4.6, §10.3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/moteurs_demo_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart' as mc;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/rangee_plus.dart';

/// Les libelles du rail replie de la coque admin a 768 et 1024 : poses hors du
/// perimetre de cet ecran (la coque est a RECH-D5), tronques par conception
/// (rail de 80, libelles masques).
const Set<String> _chromeCoqueAdmin = <String>{
  'Accueil',
  'Opérations',
  'Personnes',
  'Pédagogie',
  'Finance',
  'Configuration',
  'Sécurité et audit',
};

Future<GoRouter> _monter(
  WidgetTester tester, {
  AppRole role = AppRole.guardian,
  InterfaceMode mode = InterfaceMode.standard,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
  ThemeMode theme = ThemeMode.light,
}) => monterRouteur(
  tester,
  Routes.recherche,
  source: FausseSourceSession(sessionActive(role, mode: mode)),
  taille: taille,
  echelle: echelle,
  direction: direction,
  themeMode: theme,
  interface: mode,
  surcharges: <Override>[
    moteursRechercheProvider.overrideWithValue(moteursDemoRecherche()),
  ],
);

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

double _x(WidgetTester t, String titre) =>
    t.getTopLeft(find.widgetWithText(SectionHeader, titre)).dx;

void main() {
  // Les vraies polices : sans elles, la police de test (glyphes carres)
  // fausse la mesure des mots coupes a 320 px, texte x2.
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('formats', () {
    const List<(String, Size, double)> formats = <(String, Size, double)>[
      ('320 texte x2', Size(320, 640), 2),
      ('390 mobile', Size(390, 844), 1),
      ('768 tablette', Size(768, 1024), 1),
      ('1024 paysage', Size(1024, 768), 1),
      ('1440 bureau', Size(1440, 900), 1),
    ];
    for (final (String nom, Size taille, double echelle) in formats) {
      for (final AppRole role in <AppRole>[
        AppRole.guardian,
        AppRole.teacher,
        AppRole.admin,
      ]) {
        testWidgets('$nom, ${role.name} : resultats sans debordement ni mot '
            'coupe', (WidgetTester tester) async {
          await _monter(tester, role: role, taille: taille, echelle: echelle);
          await _chercher(
            tester,
            role == AppRole.teacher ? 'mariam' : 'fatiha',
          );
          expect(find.byType(SettingRow), findsWidgets);
          expect(tester.takeException(), isNull);
          verifierUnSeulBoutonPlein(tester);
          expect(
            mc.motsCoupes(
              tester,
              find.byType(Scaffold),
              traitDUnionPermis: true,
              exceptions: _chromeCoqueAdmin,
            ),
            isEmpty,
          );
        });
      }
    }

    testWidgets('1440 : deux colonnes de sections ; 390 : une seule', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));
      await _chercher(tester, 'fatiha');
      expect(_x(tester, 'Classes'), isNot(_x(tester, 'Supports')));
      await _monter(tester, taille: const Size(390, 844));
      await _chercher(tester, 'fatiha');
      expect(_x(tester, 'Classes'), _x(tester, 'Supports'));
    });

    testWidgets('texte x2 : une colonne, jamais de colonnes ecrasees', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1024, 768), echelle: 2);
      await _chercher(tester, 'fatiha');
      expect(_x(tester, 'Classes'), _x(tester, 'Supports'));
    });
  });

  group('puces de domaine', () {
    testWidgets('l\'enseignant : Tout, Classes, Supports, Eleves ; une puce '
        'restreint a ce domaine, 20 par page', (WidgetTester tester) async {
      await _monter(tester, role: AppRole.teacher);
      expect(find.widgetWithText(FilterPill, 'Tout'), findsOneWidget);
      expect(find.widgetWithText(FilterPill, 'Classes'), findsOneWidget);
      expect(find.widgetWithText(FilterPill, 'Supports'), findsOneWidget);
      expect(find.widgetWithText(FilterPill, 'Élèves'), findsOneWidget);
      await _chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      // L4-07 : trois puces au plus dans la rangee, les autres sous « Plus ».
      await toucherFiltre(tester, find.widgetWithText(FilterPill, 'Classes'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsNothing);
      expect(find.byType(SettingRow), findsNWidgets(20));
      // « Tout » rend la fenetre commune.
      await toucherFiltre(tester, find.widgetWithText(FilterPill, 'Tout'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      expect(find.byType(SettingRow), findsNWidgets(10));
    });

    testWidgets('une puce choisie avant la saisie reste choisie', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role: AppRole.teacher);
      await toucherFiltre(tester, find.widgetWithText(FilterPill, 'Supports'));
      await _chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsNothing);
      expect(find.byType(SettingRow), findsNWidgets(20));
    });

    testWidgets('la famille : deux domaines servis, deux puces + Tout', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      // Les trois puces de la famille, sans « Plus » (la variante masquee de
      // la puce « Plus » n'est pas une puce de domaine).
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is FilterPill &&
              !(w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'rangee-filtres-plus-',
                  )),
        ),
        findsNWidgets(3),
      );
      expect(find.widgetWithText(FilterPill, 'Élèves'), findsNothing);
    });
  });

  group('Interface guidee (§4.5)', () {
    testWidgets('« Trouver un support » : un domaine, aucune puce, aucune '
        'finance ni annuaire', (WidgetTester tester) async {
      await _monter(tester, role: AppRole.student, mode: InterfaceMode.enfant);
      expect(find.text('Trouver un support'), findsWidgets);
      expect(find.byType(FilterPill), findsNothing);
      await _chercher(tester, 'fatiha');
      expect(find.widgetWithText(SectionHeader, 'Supports'), findsOneWidget);
      expect(find.widgetWithText(SectionHeader, 'Classes'), findsNothing);
      expect(
        find.text('Seulement tes supports et tes leçons.'),
        findsOneWidget,
      );
      // Un seul domaine, donc des pages de 20 : a l'eleve de choisir.
      expect(find.byType(SettingRow), findsNWidgets(20));
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 texte x2 : sans mot coupe', (WidgetTester tester) async {
      await _monter(
        tester,
        role: AppRole.student,
        mode: InterfaceMode.enfant,
        taille: const Size(320, 640),
        echelle: 2,
      );
      await _chercher(tester, 'fatiha');
      expect(
        mc.motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
        isEmpty,
      );
    });
  });

  group('arabe et RTL', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    for (final (String nom, Size taille, double echelle)
        in <(String, Size, double)>[
          ('390', const Size(390, 844), 1),
          ('320 texte x2', const Size(320, 640), 2),
          ('1440', const Size(1440, 900), 1),
        ]) {
      testWidgets('$nom : titres arabes, sens inverse, rien ne deborde', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          taille: taille,
          echelle: echelle,
          direction: TextDirection.rtl,
        );
        expect(find.text('بحث'), findsWidgets);
        await _chercher(tester, 'fatiha');
        expect(find.widgetWithText(SectionHeader, 'الفصول'), findsOneWidget);
        expect(find.widgetWithText(SectionHeader, 'المواد'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          mc.motsCoupes(tester, find.byType(Scaffold), traitDUnionPermis: true),
          isEmpty,
        );
      });
    }

    testWidgets('1440 RTL : les deux colonnes se lisent de droite a gauche', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(1440, 900),
        direction: TextDirection.rtl,
      );
      await _chercher(tester, 'fatiha');
      // Premier bloc (classes) a droite du second (supports).
      expect(_x(tester, 'الفصول'), greaterThan(_x(tester, 'المواد')));
    });
  });

  group('clavier et themes', () {
    testWidgets('Entree lance sans attendre le delai de saisie', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.enterText(find.byKey(cleChampRecherche), 'fatiha');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(SettingRow), findsWidgets);
    });

    testWidgets('« Modifier la recherche » ramene le focus au champ', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await _chercher(tester, 'zzzzzz');
      await tester.tap(find.text('Modifier la recherche'));
      await tester.pump();
      final EditableText champ = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(champ.focusNode.hasFocus, isTrue);
    });

    testWidgets('sombre : les resultats se rendent sans exception', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        theme: ThemeMode.dark,
        taille: const Size(1440, 900),
      );
      await _chercher(tester, 'fatiha');
      expect(find.byType(SettingRow), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
