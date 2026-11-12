// FUSEAU-IDENTITE-PRO (garde-cap, 12/11/2026, voie A) : la feuille du
// fuseau. Les fuseaux du pays d'abord, puis ceux que l'application propose ;
// sous les choix, le nom international en champ d'expert (exemple
// « Asia/Riyadh ») ; un nom refuse par le serveur est dit, jamais avale ;
// aucun decalage invente. Donnees fictives.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/core/profil/service_declaration.dart';
import 'package:rewayah_academy/core/tc_horloge/fuseaux_interlocuteurs.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/features/profil_enseignant/feuille_fuseau.dart';

import '../../capture/outil_capture.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Ouvre la feuille et rend ce que sa fermeture renvoie.
Future<bool? Function()> _ouvrir(
  WidgetTester tester, {
  required Future<void> Function(String) ecrire,
  String? actuel,
  String? pays,
  ThemeMode theme = ThemeMode.light,
}) async {
  bool? rendu;
  await tester.pumpWidget(
    hoteCapture(
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: () async {
                rendu = await AppBottomSheet.ouvrir<bool>(
                  context,
                  titre: t.enseignant.profil.modifierFuseau,
                  constructeur: (BuildContext _) =>
                      FeuilleFuseau(actuel: actuel, pays: pays, ecrire: ecrire),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
      themeMode: theme,
    ),
  );
  await _toucher(tester, find.text('ouvrir'));
  return () => rendu;
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('les choix', () {
    test('le fuseau actuel, puis ceux du pays, puis les proposes', () {
      final List<String> liste = fuseauxAProposer(
        actuel: 'Asia/Riyadh',
        pays: 'Canada',
      );
      expect(liste.first, 'Asia/Riyadh');
      expect(liste.sublist(1, 3).toSet(), <String>{
        'America/Toronto',
        'America/Los_Angeles',
      });
      expect(liste, contains('Europe/Paris'));
      expect(liste.toSet().length, liste.length, reason: 'aucun doublon');
    });

    test('sans pays ni fuseau : les fuseaux proposes, dans leur ordre', () {
      expect(fuseauxAProposer().first, 'Europe/Paris');
    });

    test('le decalage : +3, +5:30, -4, +0', () {
      expect(decalageCourt(const Duration(hours: 3)), '+3');
      expect(decalageCourt(const Duration(hours: 5, minutes: 30)), '+5:30');
      expect(decalageCourt(const Duration(hours: -4)), '-4');
      expect(decalageCourt(Duration.zero), '+0');
    });

    test('le fuseau du profil : la ville et le decalage du serveur ; sans '
        'fuseau, rien', () {
      expect(
        fuseauDuProfilAffiche(
          MonHorloge(
            maintenantServeur: DateTime.utc(2026, 11, 12),
            moi: const FuseauVu(
              fuseau: 'Asia/Riyadh',
              decalage: Duration(hours: 3),
            ),
          ),
        ),
        t.enseignant.profil.fuseauValeur(
          ville: villeDuFuseauLibelle('Asia/Riyadh'),
          decalage: '+3',
        ),
      );
      expect(
        fuseauDuProfilAffiche(
          MonHorloge(maintenantServeur: DateTime.utc(2026, 11, 12)),
        ),
        isNull,
      );
      expect(fuseauDuProfilAffiche(null), isNull);
    });
  });

  group('la feuille', () {
    testWidgets('une carte : le fuseau part au serveur, la feuille se ferme', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      final List<String> ecrits = <String>[];
      final bool? Function() rendu = await _ouvrir(
        tester,
        pays: 'Guinée',
        ecrire: (String f) async => ecrits.add(f),
      );
      // Le fuseau du pays est nomme comme tel ; chaque choix montre sa ville
      // seule, sans decalage invente.
      expect(find.text(t.enseignant.profil.fuseauDuPays), findsOneWidget);
      expect(find.textContaining('UTC'), findsNothing);
      await _toucher(
        tester,
        find.byKey(FeuilleFuseau.carteKey('Africa/Conakry')),
      );
      await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
      expect(ecrits, <String>['Africa/Conakry']);
      expect(rendu(), isTrue);
      expect(find.byType(FeuilleFuseau), findsNothing);
    });

    testWidgets('le champ d expert : son nom passe avant la carte', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      final List<String> ecrits = <String>[];
      await _ouvrir(
        tester,
        actuel: 'Europe/Paris',
        ecrire: (String f) async => ecrits.add(f),
      );
      expect(find.textContaining('Asia/Riyadh'), findsWidgets);
      await tester.enterText(
        find.descendant(
          of: find.byKey(FeuilleFuseau.expertKey),
          matching: find.byType(EditableText),
        ),
        '  Asia/Riyadh  ',
      );
      await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
      expect(ecrits, <String>['Asia/Riyadh']);
    });

    testWidgets('rien de choisi : la phrase le dit, rien ne part', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      final List<String> ecrits = <String>[];
      await _ouvrir(tester, ecrire: (String f) async => ecrits.add(f));
      await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
      expect(find.text(t.enseignant.profil.fuseauRequis), findsOneWidget);
      expect(ecrits, isEmpty);
    });

    testWidgets('nom refuse par le serveur : dit en clair, la feuille reste', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      final bool? Function() rendu = await _ouvrir(
        tester,
        ecrire: (String _) async => throw const FuseauInconnu(),
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(FeuilleFuseau.expertKey),
          matching: find.byType(EditableText),
        ),
        'Asia/Riad',
      );
      await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
      expect(find.text(t.enseignant.profil.fuseauInconnu), findsOneWidget);
      expect(find.byType(FeuilleFuseau), findsOneWidget);
      expect(rendu(), isNull);
    });

    testWidgets('autre echec : dit, on peut reessayer', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      await _ouvrir(
        tester,
        actuel: 'Europe/Paris',
        ecrire: (String _) async => throw Exception('reseau'),
      );
      await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
      expect(find.text(t.enseignant.profil.fuseauErreur), findsOneWidget);
      expect(find.byKey(FeuilleFuseau.enregistrerKey), findsOneWidget);
    });
  });

  // R3 : la feuille, 390, clair, sombre et arabe ; puis le refus. Donnees
  // fictives. Jamais sans CAPTURE_DIR.
  group('Capture : feuille du fuseau', skip: sautSansCapture, () {
    for (final (String nom, AppLocale langue, ThemeMode theme)
        in <(String, AppLocale, ThemeMode)>[
          ('clair', AppLocale.fr, ThemeMode.light),
          ('sombre', AppLocale.fr, ThemeMode.dark),
          ('arabe', AppLocale.ar, ThemeMode.light),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, const Size(390, 1400), 1);
        await _ouvrir(
          tester,
          pays: 'Guinée',
          theme: theme,
          ecrire: (String _) async => throw const FuseauInconnu(),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, 'feuille_390_$nom')}');
        await tester.enterText(
          find.descendant(
            of: find.byKey(FeuilleFuseau.expertKey),
            matching: find.byType(EditableText),
          ),
          'Asia/Riad',
        );
        await _toucher(tester, find.byKey(FeuilleFuseau.enregistrerKey));
        await tester.ensureVisible(find.byKey(FeuilleFuseau.issueKey));
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturerVue(tester, 'refus_390_$nom')}');
      });
    }
  });
}
