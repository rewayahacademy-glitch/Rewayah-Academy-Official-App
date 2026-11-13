// HORS-SALLE-2 (directeur, 12/11/2026 au soir : « Toutes ses sorties de l'app
// doivent etre consignees sur le rapport : leur nombre total, frequence, de
// quand jusqu'a quand ») : la section « Sorties de l'application » du detail
// d'une seance vu par le parent, sur le vrai routeur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal_sorties/libelles_sorties.dart';
import 'package:rewayah_academy/core/journal_sorties/port_journal_sorties.dart';
import 'package:rewayah_academy/core/router/routes.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../support/faux_journal_sorties.dart';
import '../historique/support_historique.dart';

/// Ouvre le detail de `s-coupure` (eleve A1) avec [sorties].
Future<void> monterDetailAvecSorties(
  WidgetTester tester,
  List<SortieApp> sorties, {
  Size? taille = const Size(390, 844),
  ThemeMode mode = ThemeMode.light,
  Key? cadre,
}) async {
  await monterHistorique(
    tester,
    depart: Routes.seancePour('s-coupure'),
    taille: taille,
    mode: mode,
    cadre: cadre,
    autres: <Override>[
      portJournalSortiesProvider.overrideWithValue(
        FauxJournalSorties(sorties: sorties),
      ),
    ],
  );
}

void main() {
  testWidgets('trois sorties : le nombre, la duree totale, chaque sortie de '
      'quand a quand, la sortie de la salle dite en mots', (
    WidgetTester tester,
  ) async {
    final List<SortieApp> trois = troisSorties(FoyersFictifs.a1.id);
    await monterDetailAvecSorties(tester, <SortieApp>[
      ...trois,
      // Une ligne d'un autre enfant de la meme seance n'est pas la sienne.
      ...troisSorties(FoyersFictifs.a2.id).take(1),
    ]);
    final Traductions$journalSorties$rapport$fr r = t.journalSorties.rapport;
    final Finder section = find.byKey(
      const ValueKey<String>('section-sorties-seance'),
    );
    await tester.ensureVisible(section);
    expect(find.text(r.titre), findsOneWidget);
    expect(find.text(LibellesSorties.nombre(3)), findsOneWidget);
    expect(find.text(LibellesSorties.dureeSeule(255)), findsOneWidget);
    for (final SortieApp s in trois) {
      expect(find.text(LibellesSorties.plage(s)), findsOneWidget);
    }
    expect(find.text(r.sortieSalle), findsOneWidget);
    // Sous le temps de presence.
    expect(
      tester.getTopLeft(find.text(r.titre)).dy,
      greaterThan(
        tester.getTopLeft(find.text(t.historique.seance.presence)).dy,
      ),
    );
  });

  testWidgets('aucune ligne lisible : rien, pas meme un titre', (
    WidgetTester tester,
  ) async {
    await monterDetailAvecSorties(tester, const <SortieApp>[]);
    expect(find.text(t.journalSorties.rapport.titre), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('section-sorties-seance')),
      findsNothing,
    );
  });
}
