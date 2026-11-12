// MA-PROGRESSION-ECRAN (12/11/2026) : la progression du titulaire de la
// demonstration de Ma classe, telle que `ma_progression` la rendrait : une
// donnee d'essai, jamais celle d'un vrai eleve. Elle remplace l'ancienne ligne
// de progression de la demonstration.

import 'dart:async';

import '../../core/suivi/ma_progression.dart';
import '../../core/suivi/port_suivi_pedagogique.dart';

/// La progression d'essai du titulaire dans la Classe An-Nour.
class MaProgressionDemo implements PortMaProgression {
  /// Cree la progression d'essai.
  const MaProgressionDemo();

  @override
  Future<MaProgression?> pourEleve(String eleveId) async => MaProgression(
    suivi: const SuiviPedagogique(
      etapeNom: 'Lire avec les voyelles',
      etapeOrdre: 2,
      objectifs: <String>['Lit les voyelles courtes', 'Enchaine deux syllabes'],
      dureePrevueSemaines: 14,
      semainesEcoulees: 5,
      rythme: Rythme.dansLesTemps,
      pageReprise: 24,
    ),
    cycle: <EtapeDuCycle>[
      EtapeDuCycle(
        ordre: 1,
        nom: 'Les lettres',
        statut: StatutEtape.franchie,
        atteinteLe: DateTime(2026, 9, 7),
      ),
      const EtapeDuCycle(
        ordre: 2,
        nom: 'Lire avec les voyelles',
        statut: StatutEtape.enCours,
      ),
      const EtapeDuCycle(
        ordre: 3,
        nom: 'Lire sans voyelles',
        statut: StatutEtape.aVenir,
      ),
    ],
    sourates: const SouratesValidees(validees: 3, total: 17),
  );
}
