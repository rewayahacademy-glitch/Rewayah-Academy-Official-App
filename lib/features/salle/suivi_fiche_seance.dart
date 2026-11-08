// RELEVE-SUIVI (08/11/2026, feu vert du pilote, point 4) : la fiche d'un
// eleve dans la salle, remplie par le suivi deja branche ailleurs.
//
// En production, le roster de la salle (`teacher_roster_v`) ne porte que le
// niveau : objectif actuel, « a reprendre » et derniere seance restaient
// vides. Trois lectures existent deja pour la Classe, sous la meme garde
// (`cahier_c1_peut_lire_classe` : direction, titulaire, ou enseignant
// effectif d'une seance de la Classe, remplacant compris) :
//   - `etapes_eleves_classe` : l'etape du programme de chaque eleve ;
//   - `observations_classe` : ce que le dernier cahier a note (points a
//     renforcer) ;
//   - `position_reprise_classe` : la derniere page presentee dans la Classe.
//
// Regles : un fait deja projete par le roster n'est jamais remplace ; une
// lecture en cours laisse le fait vide (la carte ne le montre pas) ; une
// lecture en echec dit « Non disponible » pour ce seul fait, sans effacer
// les autres. Aucun calcul de rythme ici (le serveur seul le calcule).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../fiche_groupe/etape_eleve.dart';
import '../fiche_groupe/observations_eleve.dart';
import '../salle_seance/vue_seance.dart';

/// Les trois lectures du suivi d'une Classe, telles que la salle les tient.
typedef SuiviClasseSalle = ({
  AsyncValue<Map<String, EtapeEleve>> etapes,
  AsyncValue<Map<String, ObservationsEleve>> observations,
  AsyncValue<int?> pageClasse,
});

/// La fiche [base] completee pour l'eleve [profilId] par le [suivi] de sa
/// Classe. Pure, pour les tests.
FicheEleveSeance ficheAvecSuivi(
  FicheEleveSeance base, {
  required String? profilId,
  required SuiviClasseSalle suivi,
}) {
  final String nonDisponible = t.compte.nonDisponible;

  String objectif() {
    if (base.objectifActuel.isNotEmpty) return base.objectifActuel;
    final AsyncValue<Map<String, EtapeEleve>> e = suivi.etapes;
    if (e.hasError && !e.hasValue) return nonDisponible;
    final EtapeEleve? etape = profilId == null ? null : e.value?[profilId];
    return etape?.nom ?? '';
  }

  String aReprendre() {
    if (base.aReprendre.isNotEmpty) return base.aReprendre;
    final AsyncValue<Map<String, ObservationsEleve>> o = suivi.observations;
    if (o.hasError && !o.hasValue) return nonDisponible;
    final ObservationsEleve? obs = profilId == null ? null : o.value?[profilId];
    return obs == null ? '' : obs.aRenforcer.join(', ');
  }

  String derniereSeance() {
    if (base.derniereSeance.isNotEmpty) return base.derniereSeance;
    final AsyncValue<int?> p = suivi.pageClasse;
    if (p.hasError && !p.hasValue) return nonDisponible;
    final int? page = p.value;
    return page == null ? '' : t.tc.classe.fiche.page(page: page);
  }

  return FicheEleveSeance(
    niveau: base.niveau,
    objectifActuel: objectif(),
    derniereSeance: derniereSeance(),
    aReprendre: aReprendre(),
    presenceRecente: base.presenceRecente,
    travailActuel: base.travailActuel,
  );
}
