// La veille de fraicheur (fiche du 27/10/2026, lignes 1 a 9) : un seul
// service, ouvert des qu'une personne est connectee, ferme a la deconnexion,
// qui invalide les lectures Riverpod de la famille concernee a chaque signal
// du serveur. Au retour du reseau, il se reabonne et relit tout (ligne 2).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accueil_famille/accueil_famille_page.dart'
    show classeDeLEleveProvider;
import '../../features/classe_tuteur/contexte_classe.dart'
    show contexteClasseProvider;
import '../../features/classe_tuteur/planning_classe_page.dart'
    show planningClasseProvider;
import '../../features/foyer/foyer_page.dart' show classesMembreProvider;
import '../../features/ma_classe_adulte/ma_classe_adulte_page.dart'
    show maClasseAdulteProvider;
import '../enseignant/service_enseignant.dart';
import '../observabilite/journal_dev.dart';
import '../planning/service_planning.dart' show seancesProvider;
import '../reseau/service_reseau.dart';
import '../seance_famille/port_seances_famille.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../suivi/groupes_seances.dart';
import '../suivi/service_suivi.dart';
import '../tc_groupe/port_groupes.dart';
import 'port_veille.dart';

/// Les lectures de chaque famille : ce que la veille invalide quand le
/// serveur signale un changement. **Toute nouvelle lecture des classes ou des
/// seances s'ajoute ICI**, comme `memoiresDeSalle` pour la memoire de la
/// salle : c'est la seule liste qui decide de ce qui se met a jour sans geste.
final Map<FamilleLecture, List<void Function(Ref)>> lecturesVeillees =
    <FamilleLecture, List<void Function(Ref)>>{
      FamilleLecture.classes: <void Function(Ref)>[
        (Ref ref) => ref.invalidate(mesGroupesProvider),
        (Ref ref) => ref.invalidate(groupeProvider),
        (Ref ref) => ref.invalidate(classesMembreProvider),
        (Ref ref) => ref.invalidate(classeDeLEleveProvider),
        (Ref ref) => ref.invalidate(contexteClasseProvider),
        (Ref ref) => ref.invalidate(maClasseAdulteProvider),
        (Ref ref) => ref.invalidate(groupesEnseignantProvider),
        (Ref ref) => ref.invalidate(membresGroupeEnseignantProvider),
        (Ref ref) => ref.invalidate(groupesDesSeancesProvider),
      ],
      FamilleLecture.seances: <void Function(Ref)>[
        (Ref ref) => ref.invalidate(seancesDeMonSuiviProvider),
        (Ref ref) => ref.invalidate(seancesDuSuiviProvider),
        (Ref ref) => ref.invalidate(presenceDuSuiviProvider),
        (Ref ref) => ref.invalidate(prochaineSeanceProvider),
        (Ref ref) => ref.invalidate(derniereSeanceProvider),
        (Ref ref) => ref.invalidate(planningClasseProvider),
        (Ref ref) => ref.invalidate(seancesProvider),
        (Ref ref) => ref.invalidate(seancesEnseignantProvider),
        (Ref ref) => ref.invalidate(rosterSeanceProvider),
        (Ref ref) => ref.invalidate(cahiersEnRetardProvider),
        (Ref ref) => ref.invalidate(groupesDesSeancesProvider),
      ],
    };

/// Les familles a relire pour un signal : la famille de la table, ou toutes
/// quand le canal vient d'etre (re)joint. Pure.
Set<FamilleLecture> famillesPourSignal(SignalVeille signal) => switch (signal) {
  ChangementTable(:final String table) => switch (familleDeLaTable(table)) {
    final FamilleLecture famille => <FamilleLecture>{famille},
    null => const <FamilleLecture>{},
  },
  CanalRejoint() => FamilleLecture.values.toSet(),
};

/// Invalide toutes les lectures d'une famille.
void invaliderFamille(Ref ref, FamilleLecture famille) {
  for (final void Function(Ref) invalider
      in lecturesVeillees[famille] ?? const <void Function(Ref)>[]) {
    invalider(ref);
  }
}

/// La veille de fraicheur. **Montee par `RewayahApp` seulement**, comme les
/// persistances : un ecran teste seul n'ouvre aucun canal.
///
/// Ouverte quand la session porte un profil, fermee (abonnement annule, canal
/// retire) quand il disparait : la veille suit la personne. Chaque signal
/// invalide les lectures de sa famille ; les ecrans qui les regardent relisent
/// sous RLS, et l'objectif mesurable de la fiche (a jour en moins de 3 s sur
/// l'autre appareil, sans geste) tient a la latence du serveur.
final Provider<void> veilleFraicheurProvider = Provider<void>((Ref ref) {
  final String? profil = ref.watch(
    sessionProvider.select((SessionState s) => s.profileId),
  );
  if (profil == null) {
    return;
  }
  final PortVeille port = ref.watch(portVeilleProvider);
  StreamSubscription<SignalVeille>? abonnement;

  void ouvrir() {
    unawaited(abonnement?.cancel());
    abonnement = port.ecouter().listen(
      (SignalVeille signal) {
        for (final FamilleLecture famille in famillesPourSignal(signal)) {
          invaliderFamille(ref, famille);
        }
      },
      onError: (Object erreur) =>
          journalDev('Veille de fraicheur en erreur : ${erreur.runtimeType}'),
    );
  }

  ouvrir();
  ref.onDispose(() => unawaited(abonnement?.cancel()));

  // Ligne 2 : au retour du reseau, re-souscription et relecture de tout, car
  // ce qui a change pendant la coupure n'a pas ete signale.
  ref.listen<AsyncValue<bool>>(horsLigneProvider, (
    AsyncValue<bool>? avant,
    AsyncValue<bool> apres,
  ) {
    final bool etaitHorsLigne = avant?.value ?? false;
    final bool estHorsLigne = apres.value ?? false;
    if (etaitHorsLigne && !estHorsLigne) {
      ouvrir();
      for (final FamilleLecture famille in FamilleLecture.values) {
        invaliderFamille(ref, famille);
      }
    }
  });
});
