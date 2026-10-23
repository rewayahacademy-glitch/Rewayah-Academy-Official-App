// Spec §49 (COMPTA-RECON-1 §3.2) : « erreur partielle » et « permission
// insuffisante » ont leur rendu.
//
// - une partie de la Tresorerie lue, une autre non : les blocs lus restent
//   affiches, une bande le dit et propose de relire (jamais un ecran vide
//   pour un seul bloc en echec) ;
// - tout en echec : pas de bande (l'echec porte sur la page entiere) ;
// - une permission refusee n'est ni un echec reseau ni une capacite
//   absente : l'etat « permission refusee », sans « Reessayer ».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_tresorerie.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';

import 'faux_tresorerie.dart';

class _HistoriqueEnEchec extends FausseTresorerie {
  @override
  Future<List<EntreeJournal>> historique(FiltreHistoriqueTresorerie filtre) =>
      Future<List<EntreeJournal>>.error(StateError('reseau'));
}

class _PrevisionRefusee extends FausseTresorerie {
  @override
  Future<List<LignePrevision>> prevision() =>
      Future<List<LignePrevision>>.error(
        const PermissionInsuffisante('lire-prevision'),
      );
}

void main() {
  final tr = t.comptable.tresorerie;
  const Key bande = ValueKey<String>('tresorerie-erreur-partielle');

  testWidgets('erreur partielle : le reste reste affiche, la bande le dit', (
    WidgetTester tester,
  ) async {
    await monterTresorerie(tester, tresorerie: _HistoriqueEnEchec());
    expect(find.byKey(bande), findsOneWidget);
    expect(find.text(tr.erreurPartielle), findsOneWidget);
    // Les autres blocs sont la : les sept coffres se lisent encore.
    expect(find.text(tr.coffreProtege), findsNWidgets(5));
  });

  testWidgets('tout se lit : aucune bande', (WidgetTester tester) async {
    await monterTresorerie(tester, tresorerie: FausseTresorerie());
    expect(find.byKey(bande), findsNothing);
  });

  testWidgets('permission insuffisante : son etat, sans « Reessayer »', (
    WidgetTester tester,
  ) async {
    await monterTresorerie(tester, tresorerie: _PrevisionRefusee());
    final Iterable<EtatSysteme> refus = tester
        .widgetList<EtatSysteme>(find.byType(EtatSysteme))
        .where((EtatSysteme e) => e.nature == NatureEtat.permissionRefusee);
    expect(refus, hasLength(1));
    expect(refus.single.onAction, isNull);
    // Une permission refusee n'est pas une erreur partielle a relire.
    expect(find.byKey(bande), findsNothing);
  });
}
