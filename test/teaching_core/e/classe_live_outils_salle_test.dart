// TB-RC m21 (verification non auteur du 11/10) : les outils d'une salle sont
// ceux de CETTE salle, sur le chemin REEL de la salle (Classe Live).
//
// Ecrire (`etatOutilsProvider`), l'historique d'Annuler
// (`historiquePersonnelProvider`) et la marque « non partage »
// (`traitsNonPartagesProvider`) sont des providers de la racine. La Classe
// Live les enveloppe dans `PorteeOutilsSalle` : la salle lit des instances
// neuves, la racine ne voit rien. Sans cette portee, une salle neuve s'ouvrirait
// avec Ecrire arme par la salle d'avant et « Annuler » rejouerait une
// operation d'une autre salle. Contre-epreuve : retirer `PorteeOutilsSalle` de
// `classe_live_page.dart` fait echouer ce test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_classe/session_live_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/operations_personnelles.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/features/salle_seance/notes_deposees.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/tc_classe_live/classe_live_page.dart';

import 'faux/faux_classe.dart';
import 'support/hote_classe.dart';

void main() {
  const ContexteClasseLive contexte = ContexteClasseLive(
    sessionId: 's1',
    groupeId: 'g1',
    libelleGroupe: 'Classe Al-Fatiha',
    enseignant: EnseignantDeClasse(
      nomAffichage: 'Youssouf',
      titre: TitreEnseignant.sayyid,
    ),
  );

  Future<void> monter(WidgetTester tester) async {
    final List<String> journal = <String>[];
    await monterClasse(
      tester,
      contexte: contexte,
      surcharges: surchargesClasse(
        moteur: FauxMoteurClasse(journal: journal),
        video: FauxServiceVideoClasse(
          acces0: accesDe('teacher'),
          journal: journal,
        ),
        preVol: FauxPreVolClasse(),
      ),
      ecran: LargeurEcran.desktop,
    );
  }

  ProviderContainer salle(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));
  ProviderContainer racine(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ClasseLivePage)));

  testWidgets('la Classe Live lit des outils neufs, la racine ne voit rien', (
    WidgetTester tester,
  ) async {
    await monter(tester);
    // La salle a son propre conteneur : ce n'est pas celui de la racine.
    expect(identical(salle(tester), racine(tester)), isFalse);

    salle(tester)
        .read(etatOutilsProvider.notifier)
        .choisirOutil(OutilDock.stylet);
    expect(salle(tester).read(etatOutilsProvider).outilActif, OutilDock.stylet);
    // La racine (l'appareil) n'a rien vu : Ecrire n'est pas arme pour la
    // salle suivante.
    expect(racine(tester).read(etatOutilsProvider).outilActif, isNull);
  });

  testWidgets('deux montages successifs : Ecrire n est pas arme dans le '
      'second', (WidgetTester tester) async {
    await monter(tester);
    salle(tester)
        .read(etatOutilsProvider.notifier)
        .choisirOutil(OutilDock.stylet);
    expect(salle(tester).read(etatOutilsProvider).outilActif, OutilDock.stylet);

    await tester.pumpWidget(const SizedBox.shrink());
    await monter(tester);
    expect(salle(tester).read(etatOutilsProvider).outilActif, isNull);
  });

  testWidgets('l historique d Annuler et la marque non partage sont aussi '
      'ceux de la salle', (WidgetTester tester) async {
    await monter(tester);
    // Ils ne sont pas lus par la racine : un conteneur distinct les porte.
    final ProviderContainer s = salle(tester);
    final ProviderContainer r = racine(tester);
    expect(identical(s, r), isFalse);
    expect(
      identical(
        s.read(historiquePersonnelProvider.notifier),
        r.read(historiquePersonnelProvider.notifier),
      ),
      isFalse,
    );
    expect(
      identical(
        s.read(traitsNonPartagesProvider.notifier),
        r.read(traitsNonPartagesProvider.notifier),
      ),
      isFalse,
    );
  });
}
