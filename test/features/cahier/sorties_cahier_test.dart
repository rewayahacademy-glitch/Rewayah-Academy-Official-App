// HORS-SALLE-2 (directeur, 12/11/2026 au soir) : chez l'enseignant, dans le
// cahier de la seance, par eleve, « Sorties de l'application : 3 sorties,
// 4 min » ; une ligne lue, rien a saisir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart'
    show PositionLecture;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/journal_sorties/libelles_sorties.dart';
import 'package:rewayah_academy/core/journal_sorties/port_journal_sorties.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/faux_journal_sorties.dart';
import '../../support/harnais.dart';

final DateTime _debut = DateTime(2026, 11, 12, 18);

ParticipantBrouillon _participant(String id, String prenom) =>
    ParticipantBrouillon(
      membre: membreDeTest(
        studentId: id,
        identifiant: 'RA-$id',
        prenom: prenom,
      ),
      presence: EtatPresence.presente,
      suspensionPermise: true,
      entreLe: _debut,
      derniereTraceLe: _debut.add(const Duration(minutes: 55)),
      position: const PositionLecture(page: 2, sourate: 2, verset: 5),
    );

/// Le cahier de la seance `s1`, deux eleves, avec [sorties].
Future<void> monterCahierAvecSorties(
  WidgetTester tester,
  List<SortieApp> sorties, {
  Size taille = const Size(390, 844),
  double densite = 1,
  bool cadreCapture = false,
}) async {
  fixerVueCapture(tester, taille, densite);
  final FauxServiceEnseignant service = FauxServiceEnseignant()
    ..brouillonRendu = BrouillonCahier(
      seanceId: 's1',
      debut: _debut,
      fin: _debut.add(const Duration(minutes: 60)),
      statut: StatutSeance.terminee,
      dureeMinutes: 60,
      minutesInterruption: 0,
      dejaDepose: false,
      participants: <ParticipantBrouillon>[
        _participant('e1', 'Yasmine'),
        _participant('e2', 'Bilal'),
      ],
      evenements: const <EvenementSeance>[],
    );
  final List<Override> surcharges = <Override>[
    serviceEnseignantProvider.overrideWithValue(service),
    depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    portJournalSortiesProvider.overrideWithValue(
      FauxJournalSorties(sorties: sorties),
    ),
  ];
  await tester.pumpWidget(
    cadreCapture
        ? hoteCapture(const CahierPage(seanceId: 's1'), surcharges: surcharges)
        : hote(const CahierPage(seanceId: 's1'), surcharges: surcharges),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une ligne par eleve qui a des sorties, rien pour les autres', (
    WidgetTester tester,
  ) async {
    await monterCahierAvecSorties(tester, troisSorties('e1'));
    final String ligne = t.journalSorties.rapport.ligneEleve(
      resume: LibellesSorties.resume(
        const ResumeSorties(nombre: 3, totalSecondes: 255),
      ),
    );
    expect(find.textContaining(ligne), findsOneWidget);
    expect(find.textContaining(t.journalSorties.rapport.titre), findsOneWidget);
  });

  testWidgets('aucune sortie lisible : le cahier ne change pas', (
    WidgetTester tester,
  ) async {
    await monterCahierAvecSorties(tester, const <SortieApp>[]);
    expect(find.textContaining(t.journalSorties.rapport.titre), findsNothing);
  });
}
