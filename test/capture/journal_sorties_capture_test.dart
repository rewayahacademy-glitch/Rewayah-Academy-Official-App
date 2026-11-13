// Captures de recette HORS-SALLE-2 (directeur, 12/11/2026 au soir) : captures
// de TEST, les vrais ecrans sur un faux journal des sorties (aucun serveur).
// (a) la page de l'accord du parent, deux enfants (l'un sans accord, l'autre
// avec) : 390 clair, sombre, arabe ; (b) le detail d'une seance du parent
// avec trois sorties : 390 et 1440 ; (c) la ligne de l'enseignant dans le
// cahier : 390. Saute sans CAPTURE_DIR. Nommage : journal_sorties_<cas>_<l>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

import '../features/cahier/sorties_cahier_test.dart';
import '../features/journal_sorties/accord_sorties_page_test.dart';
import '../features/suivi_foyer/sorties_detail_seance_test.dart';
import '../fixtures/tuteur/foyers.dart';
import '../support/faux_journal_sorties.dart';
import 'outil_capture.dart';

Future<void> _accord(
  WidgetTester tester,
  ThemeMode mode,
  String nom, {
  bool arabe = false,
  bool bas = false,
}) async {
  if (arabe) {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
  }
  await monterAccordSorties(
    tester,
    FauxJournalSorties(etat: etatDeuxEnfants()),
    densite: 3,
    mode: mode,
  );
  if (bas) {
    // Les cartes des enfants, sous le texte.
    await tester.ensureVisible(
      find.text(t.journalSorties.accord.enregistrer).last,
    );
    await stabiliser(tester);
  }
  debugPrint('PNG ${await capturer(tester, nom)}');
}

Future<void> _detail(WidgetTester tester, Size taille, String nom) async {
  fixerVueCapture(tester, taille, taille.width < 600 ? 3 : 1);
  await monterDetailAvecSorties(
    tester,
    troisSorties(FoyersFictifs.a1.id),
    taille: null,
    cadre: cadreCapture,
  );
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('section-sorties-seance')),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : HORS-SALLE-2', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(neutraliserStockageAppareil);

    testWidgets('journal_sorties_accord_390_light', (
      WidgetTester tester,
    ) async {
      await _accord(
        tester,
        ThemeMode.light,
        'journal_sorties_accord_390_light',
      );
    });

    testWidgets('journal_sorties_accord_cartes_390_light', (
      WidgetTester tester,
    ) async {
      await _accord(
        tester,
        ThemeMode.light,
        'journal_sorties_accord_cartes_390_light',
        bas: true,
      );
    });

    testWidgets('journal_sorties_accord_cartes_390_arabe', (
      WidgetTester tester,
    ) async {
      await _accord(
        tester,
        ThemeMode.dark,
        'journal_sorties_accord_cartes_390_dark_arabe',
        arabe: true,
        bas: true,
      );
    });

    testWidgets('journal_sorties_accord_390_dark', (WidgetTester tester) async {
      await _accord(tester, ThemeMode.dark, 'journal_sorties_accord_390_dark');
    });

    testWidgets('journal_sorties_accord_390_arabe', (
      WidgetTester tester,
    ) async {
      await _accord(
        tester,
        ThemeMode.light,
        'journal_sorties_accord_390_arabe',
        arabe: true,
      );
    });

    testWidgets('journal_sorties_detail_390_light', (
      WidgetTester tester,
    ) async {
      await _detail(
        tester,
        const Size(390, 844),
        'journal_sorties_detail_390_light',
      );
    });

    testWidgets('journal_sorties_detail_1440_light', (
      WidgetTester tester,
    ) async {
      await _detail(
        tester,
        const Size(1440, 900),
        'journal_sorties_detail_1440_light',
      );
    });

    testWidgets('journal_sorties_cahier_390_light', (
      WidgetTester tester,
    ) async {
      await monterCahierAvecSorties(
        tester,
        troisSorties('e1'),
        densite: 3,
        cadreCapture: true,
      );
      await tester.ensureVisible(
        find.textContaining(t.journalSorties.rapport.titre),
      );
      await stabiliser(tester);
      debugPrint(
        'PNG ${await capturer(tester, 'journal_sorties_cahier_390_light')}',
      );
    });
  });
}
