// Fixtures d'etat partage : une suite de revisions comportant volontairement
// un paquet hors ordre et un paquet duplique.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.

import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';

/// La seance de reference des fixtures d'etat partage.
const String seancePartagee = 'seance-1';

/// L'instant de reference.
final DateTime originePartage = DateTime.utc(2026, 10, 19, 16, 5);

/// Une page du Coran, comme position partagee.
ContentPosition pagePartagee(int page) => ContentPosition.page(
  resourceId: 'res-coran',
  page: page,
  resourceVersionId: 'ver-coran-1',
);

/// Construit un etat partage.
SharedContentState etatPartage({
  required int revision,
  required ContentPosition position,
  ModeAffichagePartage mode = ModeAffichagePartage.page,
  String sessionId = seancePartagee,
  String resourceId = 'res-coran',
  String? resourceVersionId = 'ver-coran-1',
  String updatedBy = 'ens-001',
  DateTime? updatedAtUtc,
  List<ContentRange> plagesMasquees = const <ContentRange>[],
  List<MarqueurSemantique> marqueurs = const <MarqueurSemantique>[],
}) => SharedContentState(
  sessionId: sessionId,
  resourceId: resourceId,
  resourceVersionId: resourceVersionId,
  contentPosition: position,
  displayMode: mode,
  hiddenRanges: plagesMasquees,
  semanticMarkers: marqueurs,
  revision: revision,
  updatedBy: updatedBy,
  updatedAtUtc: updatedAtUtc ?? originePartage.add(Duration(minutes: revision)),
);

/// La suite des revisions telles que le reseau les livre.
///
/// Elle est **volontairement sale** : la revision 2 repasse apres la 3 (hors
/// ordre), et la 3 repasse une seconde fois (duplique). C'est le scenario
/// exact que l'invariant « revision strictement croissante » doit absorber
/// sans qu'aucune page ne recule sous les yeux d'un enfant.
List<SharedContentState> suiteRevisionsSale() => <SharedContentState>[
  etatPartage(revision: 1, position: pagePartagee(1)),
  etatPartage(revision: 2, position: pagePartagee(2)),
  etatPartage(revision: 3, position: pagePartagee(3)),
  // Hors ordre : arrive en retard, porte une position perimee.
  etatPartage(revision: 2, position: pagePartagee(2)),
  // Duplique : le meme paquet livre deux fois.
  etatPartage(revision: 3, position: pagePartagee(3)),
  etatPartage(revision: 4, position: pagePartagee(4)),
];

/// L'etat durable, tel qu'un late joiner doit le retrouver **sans historique**.
SharedContentState etatDurablePourLateJoiner() =>
    etatPartage(revision: 7, position: pagePartagee(42));

/// Applique un paquet entrant a l'etat courant.
///
/// **Un paquet dont la revision est inferieure ou egale a l'etat courant est
/// ignore.** La meme regle couvre le duplique et le hors ordre : c'est
/// l'invariant 1 de CONTRACTS section 9, et c'est pour cela qu'il n'y a pas
/// deux regles a ecrire.
SharedContentState appliquerRevision(
  SharedContentState? courant,
  SharedContentState entrant,
) {
  if (courant == null) return entrant;
  if (entrant.sessionId != courant.sessionId) return courant;
  if (entrant.revision <= courant.revision) return courant;
  return entrant;
}
