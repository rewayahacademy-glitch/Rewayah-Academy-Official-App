// CHIFFRES-ACADEMIE : les chiffres de la demonstration. Des nombres fictifs,
// fixes, sans serveur.

import '../../core/admin/port_chiffres_academie.dart';

/// Les chiffres fictifs de la demonstration.
class ChiffresAcademieDemo implements PortChiffresAcademie {
  /// Cree le port de demonstration.
  const ChiffresAcademieDemo({required this.maintenant});

  /// L'horloge de la demonstration.
  final DateTime Function() maintenant;

  @override
  Future<ChiffresAcademie> lire() async => ChiffresAcademie(
    genereLe: maintenant(),
    candidatsRecus: 412,
    candidatsAujourdhui: 9,
    candidatsSeptJours: 64,
    candidatsSeptPleins: 62,
    candidatsSeptPleinsAvant: 51,
    candidatsParJour: const <int>[6, 11, 8, 12, 7, 11, 9],
    pays: 27,
    hommes: 301,
    femmes: 111,
    repondants: 380,
    coranEntier: 262,
    juzMin: 8540,
    ijaza: 171,
    riwayat: 14,
    langues: 12,
    enseignants: 18,
    eleves: 96,
    elevesEnClasse: 71,
    familles: 52,
    classes: 21,
    languesCours: 6,
    seancesTenues: 340,
    seancesMinutes: 19980,
    seancesSeptJours: 38,
    seancesSeptPleins: 37,
    seancesSeptPleinsAvant: 34,
  );
}
