import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';

/// Un hote de dock pilotable depuis un test.
///
/// Ecrit ici plutot que dans `test/support/harnais.dart` : la decision D-06
/// reserve ce fichier partage a Agent Z, et chaque agent pose ses faux sous
/// `test/teaching_core/<lettre>/faux/`.
class FauxDockHote implements PortDockHote {
  /// Cree un hote de test.
  FauxDockHote({
    this.support,
    this.selection,
    this.capacitesRendues = const CapacitesPedagogiques(
      peutPiloterSupport: true,
      peutAnnoter: true,
      peutEmettreNudge: true,
      estObservateurSilencieux: false,
    ),
    this.contexteRendu = const ContexteDock(
      groupeId: 'groupe-1',
      sessionId: 'seance-1',
      profilId: 'prof-1',
    ),
  });

  /// Le support declare.
  SupportPresente? support;

  /// La selection declaree.
  SelectionSupport? selection;

  /// Les capacites declarees. `null` simule une lecture hors seance.
  CapacitesPedagogiques? capacitesRendues;

  /// Le contexte declare.
  ContexteDock contexteRendu;

  /// Le nombre d'ouvertures de la Bibliotheque demandees au dock.
  int ouverturesBibliotheque = 0;

  @override
  ContexteDock contexte() => contexteRendu;

  @override
  SupportPresente? supportActif() => support;

  @override
  SelectionSupport? selectionCourante() => selection;

  @override
  CapacitesPedagogiques? capacites() => capacitesRendues;

  @override
  Future<void> ouvrirBibliotheque() async => ouverturesBibliotheque++;
}
