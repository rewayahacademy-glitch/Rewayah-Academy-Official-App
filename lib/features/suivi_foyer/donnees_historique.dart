import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/suivi/groupes_seances.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import 'filtres_historique.dart';

// Les lectures de l'Historique du tuteur (lot E). Aucune n'invente : une
// classe qui ne se nomme pas reste « Classe non disponible », un enseignant
// sans titre connu garde son prenom seul.

/// Les classes COURANTES du foyer, par identifiant (`mes_groupes_famille_v`).
/// Vide si la lecture echoue : la classe est un complement de la ligne.
final Provider<Map<String, GroupSummaryVM>> classesCourantesProvider =
    Provider<Map<String, GroupSummaryVM>>((Ref ref) {
      final AsyncValue<List<GroupSummaryVM>> v = ref.watch(mesGroupesProvider);
      if (!v.hasValue || v.hasError) {
        return const <String, GroupSummaryVM>{};
      }
      return <String, GroupSummaryVM>{
        for (final GroupSummaryVM g in v.requireValue) g.groupeId: g,
      };
    });

/// Seance vers classe (`sessions.groupe_id`, DB-CRS-13). Vide si indisponible.
final Provider<Map<String, String>> classeDesSeancesProvider =
    Provider<Map<String, String>>((Ref ref) {
      final AsyncValue<Map<String, String>?> v = ref.watch(
        groupesDesSeancesProvider,
      );
      if (!v.hasValue || v.hasError) {
        return const <String, String>{};
      }
      return v.requireValue ?? const <String, String>{};
    });

/// Le nom de la classe [groupeId], ou « Classe non disponible ».
String nomClasse(String? groupeId, Map<String, GroupSummaryVM> classes) {
  final GroupSummaryVM? g = groupeId == null ? null : classes[groupeId];
  return g?.libelle ?? t.historique.classeInconnue;
}

/// L'enseignant d'une seance : « Sayyida Amina » quand la classe courante
/// nomme ce meme enseignant, sinon son prenom tel que la seance le porte.
String enseignantAffiche(Seance seance, GroupSummaryVM? classe) {
  final EnseignantVM? e = classe?.enseignant;
  if (e != null && e.enseignantId == seance.enseignantId) {
    return LibellesGroupe.enseignantNomme(e);
  }
  return seance.enseignantPrenom;
}

/// Le prenom d'un profil eleve du foyer, ou « Eleve ».
String prenomEleve(String? eleveId, List<ProfilEleveFoyer> profils) {
  for (final ProfilEleveFoyer p in profils) {
    if (p.eleveId == eleveId) {
      return p.prenom;
    }
  }
  return t.historique.observations.eleveInconnu;
}

/// Les filtres d'un segment de l'Historique, en memoire de session : ils
/// survivent a l'ouverture d'un detail et au changement d'onglet, jamais au
/// redemarrage (rien sur le disque d'un appareil partage).
class FiltresControleur<S> extends Notifier<FiltresHistorique<S>> {
  @override
  FiltresHistorique<S> build() => FiltresHistorique<S>();

  /// Pose de nouveaux filtres.
  void poser(FiltresHistorique<S> filtres) => state = filtres;
}

/// Les filtres du segment Seances.
final NotifierProvider<
  FiltresControleur<StatutHistorique>,
  FiltresHistorique<StatutHistorique>
>
filtresSeancesProvider =
    NotifierProvider<
      FiltresControleur<StatutHistorique>,
      FiltresHistorique<StatutHistorique>
    >(FiltresControleur<StatutHistorique>.new);

/// Les filtres du segment Observations.
final NotifierProvider<
  FiltresControleur<StatutObservation>,
  FiltresHistorique<StatutObservation>
>
filtresObservationsProvider =
    NotifierProvider<
      FiltresControleur<StatutObservation>,
      FiltresHistorique<StatutObservation>
    >(FiltresControleur<StatutObservation>.new);

/// Les visites de l'observateur connecte pour un eleve (port K4).
final FutureProviderFamily<List<ObservationsSeance>, String?>
mesObservationsProvider =
    FutureProvider.family<List<ObservationsSeance>, String?>(
      (Ref ref, String? enfantId) => ref
          .watch(portHistoriqueObservationsProvider)
          .mesObservations(enfantId: enfantId),
    );

/// Les visites d'une seance pour un eleve (port K4).
final FutureProviderFamily<ObservationsSeance?, (String, String?)>
detailObservationsProvider =
    FutureProvider.family<ObservationsSeance?, (String, String?)>(
      (Ref ref, (String, String?) cle) => ref
          .watch(portHistoriqueObservationsProvider)
          .detail(seanceId: cle.$1, enfantId: cle.$2),
    );
