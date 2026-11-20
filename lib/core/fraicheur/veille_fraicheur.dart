// La veille de fraicheur (fiche du 27/10/2026, lignes 1 a 9) : un seul
// service, ouvert des qu'une personne est connectee, ferme a la deconnexion,
// qui invalide les lectures Riverpod de la famille concernee a chaque signal
// du serveur. Au retour du reseau, il se reabonne et relit tout (ligne 2).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accueil_famille/accueil_famille_page.dart'
    show classeDeLEleveProvider;
import '../../features/accueil_famille/carte_horaire.dart'
    show demandesHoraireProvider;
import '../../features/classe_tuteur/contexte_classe.dart'
    show contexteClasseProvider;
import '../../features/classe_tuteur/planning_classe_page.dart'
    show planningClasseProvider;
import '../../features/com_annonces/port_annonces_direction.dart'
    show mesAnnoncesProvider;
import '../../features/com_messages/non_lus_messages.dart'
    show nonLusMessagesProvider;
import '../../features/compte/donnees_compte.dart' show accesFoyerProvider;
import '../../features/dossier/apprenants_demande.dart'
    show apprenantsDemandeProvider, demandeFamilleProvider;
import '../../features/foyer/foyer_page.dart' show classesMembreProvider;
import '../../features/foyer/invitation_conjoint.dart'
    show invitationRecueProvider;
import '../../features/ma_classe_adulte/ma_classe_adulte_page.dart'
    show maClasseAdulteProvider;
import '../../features/notifications/notifications_page.dart'
    show notificationsTuteurProvider;
import '../accessibilite/port_reponse_presentation.dart'
    show demandesPresentationProvider;
import '../appairage/service_appairage.dart'
    show appareilsDuFoyerProvider, elevesDuFoyerProvider;
import '../candidature/entretien_candidat.dart' show monEntretienProvider;
import '../capacites/consentements_supabase.dart' show accordsTitulaireProvider;
import '../dossier/service_dossier.dart' show etatDossierProvider;
import '../enseignant/port_remplacements.dart' show offresCommunesProvider;
import '../enseignant/service_enseignant.dart';
import '../foyer/selection_eleve.dart' show profilsElevesFoyerProvider;
import '../observabilite/journal_dev.dart';
import '../observabilite/supervision.dart';
import '../offres/service_offres.dart'
    show parcoursFoyerProvider, reglesAcademieProvider;
import '../planning/service_planning.dart' show seancesProvider;
import '../priere/service_priere.dart' show pausePrevueProvider;
import '../reseau/service_reseau.dart';
import '../seance_famille/port_seances_famille.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../suivi/groupes_seances.dart';
import '../suivi/service_suivi.dart';
import '../tc_groupe/port_groupes.dart';
import '../theme/app_delais.dart';
import 'generation_veille.dart';
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
        // D2 (08/11/2026) : les eleves du foyer. Un profil retire par la
        // direction quitte ses classes ; une session deja ouverte le montrait
        // jusqu'a la reconnexion. Relus aussi au retour sur un onglet ou dans
        // l'application, et a « tirer pour rafraichir » (relecture generale).
        (Ref ref) => ref.invalidate(elevesDuFoyerProvider),
        // L'accueil de l'eleve en Interface guidee (classe et prochaine
        // seance), sur l'appareil appaire comme ailleurs (29/10/2026) : une
        // lecture a portee, qui suit le rang de la veille.
        (Ref ref) => ref.read(generationVeilleProvider.notifier).avancer(),
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
        (Ref ref) => ref.read(generationVeilleProvider.notifier).avancer(),
      ],
      // Lignes 12 et 14 : la liste du centre de notifications porte aussi le
      // point de non-lus de la cloche (`nonLuesProvider`) ; une insertion ou
      // une lecture sur l'autre appareil la fait relire.
      FamilleLecture.notifications: <void Function(Ref)>[
        (Ref ref) => ref.invalidate(notificationsTuteurProvider),
        // REMPL-1 (31/10/2026) : une offre proposee ou prise arrive par une
        // notification (`remplacement_propose`, `remplacement_pris`, posee
        // par le declencheur de remplacements_seance) ; le tableau commun se
        // relit aussitot au lieu d'attendre sa relecture de 30 s. Le signal ne
        // dit pas quel evenement est arrive : toute notification le relit.
        // Sans ecran qui l'ecoute, l'invalidation ne lit rien.
        (Ref ref) => ref.invalidate(offresCommunesProvider),
      ],
    };

/// PE-D12 (directeur, 19/11/2026 ; pilote, 20/11/2026 : « un geste qui
/// montre une attente sans rien relire trompe la personne ») : ce que la
/// relecture generale relit EN PLUS des familles veillees, quand on tire une
/// page vers le bas (et au retour sur un onglet ou dans l'application, au
/// plus toutes les 10 s). **Jamais sur un signal du serveur** : la veille
/// garde exactement ses familles et ses delais. Une lecture d'accueil qui
/// doit suivre le geste s'ajoute ICI. Sans ecran qui l'ecoute,
/// l'invalidation ne lit rien.
final List<void Function(Ref)> lecturesDuGeste = <void Function(Ref)>[
  // L'accueil du candidat (`/attente`) : son dossier et sa candidature, la
  // demande d'une famille et ses apprenants (comme « Actualiser l'etat du
  // dossier »), son entretien, les annonces de l'academie.
  (Ref ref) => ref.invalidate(etatDossierProvider),
  (Ref ref) => ref.invalidate(demandeFamilleProvider),
  (Ref ref) => ref.invalidate(apprenantsDemandeProvider),
  (Ref ref) => ref.invalidate(monEntretienProvider),
  (Ref ref) => ref.invalidate(mesAnnoncesProvider),
  // Toutes les coquilles : les conversations non lues (icone des messages).
  (Ref ref) => ref.invalidate(nonLusMessagesProvider),
  // L'accueil de la famille : profils, parcours, demandes d'horaire et de
  // presentation, invitation, appareils, accords, acces, regles.
  (Ref ref) => ref.invalidate(profilsElevesFoyerProvider),
  (Ref ref) => ref.invalidate(parcoursFoyerProvider),
  (Ref ref) => ref.invalidate(demandesHoraireProvider),
  (Ref ref) => ref.invalidate(demandesPresentationProvider),
  (Ref ref) => ref.invalidate(invitationRecueProvider),
  (Ref ref) => ref.invalidate(appareilsDuFoyerProvider),
  (Ref ref) => ref.invalidate(accordsTitulaireProvider),
  (Ref ref) => ref.invalidate(accesFoyerProvider),
  (Ref ref) => ref.invalidate(reglesAcademieProvider),
  // La Journee de l'enseignant : la pause de priere prevue d'une seance.
  (Ref ref) => ref.invalidate(pausePrevueProvider),
];

/// Invalide les lectures du geste ([lecturesDuGeste]).
void invaliderLecturesDuGeste(Ref ref) {
  for (final void Function(Ref) invalider in lecturesDuGeste) {
    invalider(ref);
  }
}

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
  Timer? nonRejointe;

  void ouvrir() {
    unawaited(abonnement?.cancel());
    // Appareil de Hakim (27/10/2026) : le temps reel ne l'a pas prevenu, sans
    // trace. Un canal qui ne se rejoint pas se dit desormais a la
    // supervision, avec le role seulement (jamais une personne).
    // Sans supervision demarree (tests, poste sans DSN), rien a prevenir.
    nonRejointe?.cancel();
    nonRejointe = !Supervision.demarree
        ? null
        : Timer(AppDelais.veilleNonRejointe, () {
            Supervision.signaler(
              categorie: 'veille',
              message: 'Veille temps reel : canal non rejoint',
              donnees: <String, Object?>{
                'role': ref.read(sessionProvider).role?.name ?? 'inconnu',
              },
            );
          });
    abonnement = port.ecouter().listen(
      (SignalVeille signal) {
        if (signal is CanalRejoint) {
          nonRejointe?.cancel();
        }
        for (final FamilleLecture famille in famillesPourSignal(signal)) {
          invaliderFamille(ref, famille);
        }
      },
      onError: (Object erreur) {
        journalDev('Veille de fraicheur en erreur : ${erreur.runtimeType}');
        if (erreur is ErreurCanalVeille) {
          Supervision.signaler(
            categorie: 'veille',
            message: 'Veille temps reel : canal en erreur',
            donnees: <String, Object?>{
              'statut': erreur.statut,
              'role': ref.read(sessionProvider).role?.name ?? 'inconnu',
            },
          );
        }
      },
    );
  }

  ouvrir();
  ref.onDispose(() {
    nonRejointe?.cancel();
    unawaited(abonnement?.cancel());
  });

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
