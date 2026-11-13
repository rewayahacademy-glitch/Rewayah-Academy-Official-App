// HORS-SALLE-2 (directeur, 12/11/2026 au soir ; regle du 11/11 : accord du
// parent pour un mineur) : la page de l'accord du journal des sorties, une
// carte par enfant, la case jamais precochee, le retrait au meme endroit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal_sorties/port_journal_sorties.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/journal_sorties/accord_sorties_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_journal_sorties.dart';
import '../../support/garde_interface.dart';

/// Deux enfants : Yasmine sans accord, Bilal avec.
EtatAccordsSorties etatDeuxEnfants({bool journalActif = true}) =>
    EtatAccordsSorties(
      journalActif: journalActif,
      versionCourante: 'sorties-2026-11-v1',
      eleves: <AccordSortiesEleve>[
        const AccordSortiesEleve(
          eleveId: 'e-yasmine',
          prenom: 'Yasmine',
          autonome: false,
          enCours: false,
        ),
        AccordSortiesEleve(
          eleveId: 'e-bilal',
          prenom: 'Bilal',
          autonome: false,
          enCours: true,
          accepteLe: DateTime.utc(2026, 11, 12, 18),
        ),
      ],
    );

/// L'eleve adulte, pour lui-meme, sans accord.
const EtatAccordsSorties etatAdulte = EtatAccordsSorties(
  journalActif: true,
  versionCourante: 'sorties-2026-11-v1',
  eleves: <AccordSortiesEleve>[
    AccordSortiesEleve(
      eleveId: 'moi',
      prenom: 'Karim',
      autonome: true,
      enCours: false,
    ),
  ],
);

/// Monte la page sur [faux].
Future<void> monterAccordSorties(
  WidgetTester tester,
  FauxJournalSorties faux, {
  Size taille = const Size(390, 844),
  double densite = 1,
  ThemeMode mode = ThemeMode.light,
  double echelleTexte = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(
    hoteCapture(
      AccordSortiesPage(onRetour: () {}),
      themeMode: mode,
      echelleTexte: echelleTexte,
      surcharges: <Override>[
        portJournalSortiesProvider.overrideWithValue(faux),
      ],
    ),
  );
  await stabiliser(tester);
}

Finder _bouton() =>
    find.widgetWithText(ActionPrincipale, t.journalSorties.accord.enregistrer);

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('le parent : le texte, une carte par enfant, la case jamais '
      'precochee, « Accepte le » et le retrait', (WidgetTester tester) async {
    final FauxJournalSorties faux = FauxJournalSorties(etat: etatDeuxEnfants());
    await monterAccordSorties(tester, faux);
    expect(find.text(t.journalSorties.texte.parent.quoi), findsOneWidget);
    expect(find.text(t.journalSorties.texte.parent.sansAccord), findsOneWidget);
    final Finder caseYasmine = find.text(
      t.journalSorties.texte.parent.caseAccord(prenom: 'Yasmine'),
    );
    expect(caseYasmine, findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox)).value,
      isFalse,
      reason: 'jamais precochee',
    );
    expect(find.text('Bilal'), findsOneWidget);
    expect(find.textContaining('Accepté le'), findsOneWidget);
    expect(
      find.text(t.journalSorties.accord.retirerPour(prenom: 'Bilal')),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('sans case cochee : l appui dit ce qui manque, rien ne part', (
    WidgetTester tester,
  ) async {
    final FauxJournalSorties faux = FauxJournalSorties(etat: etatDeuxEnfants());
    await monterAccordSorties(tester, faux);
    await _toucher(tester, _bouton());
    expect(find.text(t.journalSorties.accord.manque), findsOneWidget);
    expect(faux.acceptes, isEmpty);
  });

  testWidgets('cocher puis enregistrer : l accord part a la version lue', (
    WidgetTester tester,
  ) async {
    final FauxJournalSorties faux = FauxJournalSorties(etat: etatDeuxEnfants());
    await monterAccordSorties(tester, faux);
    await _toucher(
      tester,
      find.text(t.journalSorties.texte.parent.caseAccord(prenom: 'Yasmine')),
    );
    await _toucher(tester, _bouton());
    expect(faux.acceptes, <(String, String)>[
      ('e-yasmine', 'sorties-2026-11-v1'),
    ]);
    expect(find.text(t.journalSorties.accord.merci), findsOneWidget);
    // Plus aucune case : le bouton plein disparait.
    expect(_bouton(), findsNothing);
  });

  testWidgets('retirer : le retrait part, la case revient', (
    WidgetTester tester,
  ) async {
    final FauxJournalSorties faux = FauxJournalSorties(etat: etatDeuxEnfants());
    await monterAccordSorties(tester, faux);
    await _toucher(
      tester,
      find.text(t.journalSorties.accord.retirerPour(prenom: 'Bilal')),
    );
    expect(faux.retires, <String>['e-bilal']);
    expect(find.text(t.journalSorties.accord.retire), findsOneWidget);
    expect(
      find.text(t.journalSorties.texte.parent.caseAccord(prenom: 'Bilal')),
      findsOneWidget,
    );
  });

  testWidgets('le texte a change entre-temps : on le dit, on relit', (
    WidgetTester tester,
  ) async {
    final FauxJournalSorties faux = FauxJournalSorties(
      etat: etatDeuxEnfants(),
      refus: const AccordSortiesRefuse(MotifRefusAccord.versionPerimee),
    );
    await monterAccordSorties(tester, faux);
    await _toucher(
      tester,
      find.text(t.journalSorties.texte.parent.caseAccord(prenom: 'Yasmine')),
    );
    await _toucher(tester, _bouton());
    expect(find.text(t.journalSorties.accord.versionPerimee), findsOneWidget);
  });

  testWidgets('l eleve adulte : la version pour lui-meme', (
    WidgetTester tester,
  ) async {
    await monterAccordSorties(tester, FauxJournalSorties(etat: etatAdulte));
    expect(find.text(t.journalSorties.texte.adulte.quoi), findsOneWidget);
    expect(find.text(t.journalSorties.texte.adulte.caseAccord), findsOneWidget);
    expect(find.text(t.journalSorties.texte.parent.quoi), findsNothing);
  });

  testWidgets('journal eteint ou serveur ancien : aucune case, la page le '
      'dit', (WidgetTester tester) async {
    for (final EtatAccordsSorties? etat in <EtatAccordsSorties?>[
      etatDeuxEnfants(journalActif: false),
      null,
    ]) {
      await monterAccordSorties(tester, FauxJournalSorties(etat: etat));
      expect(find.text(t.journalSorties.accord.horsService), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text(t.journalSorties.texte.parent.quoi), findsNothing);
    }
  });

  for (final (Size taille, double echelle) in <(Size, double)>[
    (const Size(320, 690), 2),
    (const Size(1440, 900), 1),
  ]) {
    testWidgets('${taille.width.toInt()} en texte x$echelle, clair et '
        'sombre : rien ne deborde', (WidgetTester tester) async {
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        await monterAccordSorties(
          tester,
          FauxJournalSorties(etat: etatDeuxEnfants()),
          taille: taille,
          echelleTexte: echelle,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('arabe : la page se lit de droite a gauche', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await monterAccordSorties(
      tester,
      FauxJournalSorties(etat: etatDeuxEnfants()),
    );
    expect(find.text(t.journalSorties.texte.parent.quoi), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
