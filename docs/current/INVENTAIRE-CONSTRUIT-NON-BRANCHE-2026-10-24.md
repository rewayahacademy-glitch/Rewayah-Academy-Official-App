# Inventaire : construit mais non branché (24/10/2026, soir)

Question du directeur : « la recherche de la console admin ne marche pas ; elle avait été créée,
comme le Teaching Core et la salle. Est-elle perdue dans les branches ? »

## Réponse courte

Rien n'est perdu. Le dépôt et la production sont au même niveau (262 migrations dans le dépôt,
262 appliquées en production). Le défaut est toujours le même : **construit, testé, jamais
branché sur le serveur**. Un port a une valeur par défaut « vide », « indisponible » ou
« mémoire », et personne n'a écrit l'adaptateur Supabase ou ne l'a monté dans `main.dart`.

## La recherche (RECH-1)

- Écran : `lib/features/recherche/` (page, entrée, quatre domaines), route `/recherche`, **dans main**.
- Serveur : `rech_d1_rechercher_classes`, `rech_d1_rechercher_supports`,
  `rech_d4_rechercher_reference_finance`, `rechercher_personne_par_matricule`, curseurs et quota :
  **présents en production** (vérifié par SELECT le 24/10).
- Cause : `moteursRechercheProvider` (`lib/core/recherche/port_recherche.dart`) vaut la liste vide
  en production ; seuls le mode démonstration monte des moteurs. Aucun adaptateur Flutter n'appelle
  les fonctions `rech_*` (seul `matricule_supabase.dart` appelle la recherche par matricule).
  Les journaux de production ne montrent aucun appel `rech_*` sur 24 h.
- Coût pour brancher : un adaptateur par domaine sur les fonctions existantes, puis la liste
  dans `main.dart`. Environ 1 jour. **Après la Boucle 1** (reliquat R11).

## Le même motif ailleurs (grep du 24/10, hors tests et démo)

Fichiers où un port reste « vide en production », « indisponible », « mémoire » ou « avant BR-x » :

| Zone | Fichiers |
| :--- | :--- |
| Teaching Core | `tc_dock/teaching_dock.dart`, `tc_realtime/transport_indisponible.dart`, `tc_realtime/providers_tc_realtime.dart`, `tc_parcours/port_travail_a_venir.dart`, `tc_parcours/port_signalement.dart`, `tc_observation/port_historique_observations.dart`, `tc_flux_academique/bloc_avant_prochain_cours.dart`, `tc_flux_academique/feuille_signalement.dart`, `tc_espace_groupe/emplacements_groupe.dart`, `salle_seance/vue_seance.dart` |
| Communication | `com_vocal/port_enregistreur_vocal.dart`, `com_vocal/envoi_vocal.dart`, `com_communaute/port_communaute.dart`, `com_communaute/port_garde_promotion.dart`, `com_studio/port_studio.dart`, `com_studio/port_activite_studio.dart` |
| Foyer, capacités | `capacites/port_delegation_finance.dart`, `capacites/port_acces_foyer.dart`, `foyer/ligne_membre.dart`, `foyer/sortie_forfait.dart`, `foyer/reprise_foyer.dart`, `foyer/invitation_conjoint.dart`, `foyer/acceptation_invitation.dart` |
| Divers | `recherche/domaines/familles_eleves/port_resolution_ra.dart`, `partage_offre/port_genre_partageur.dart`, `identite/port_matricule.dart`, `enseignant/absence_remplacement.dart`, `accessibilite/port_accueil_accessibilite.dart`, `profil_enseignant/photo_publique.dart`, `parcours_offres/bloc_parcours.dart`, `controleur/historique_controleur.dart`, `controleur/compte_rendu_controle.dart`, `classe_tuteur/contexte_classe.dart`, `admin_groupes/reglage_partage.dart`, `admin_groupes/apercu_familial.dart`, `admin_dossiers/surfaces_decision.dart`, `accueil_famille/liste_preparation.dart` |

Ce tableau est un repérage par motif, pas une preuve pièce par pièce : chaque ligne demande
une lecture avant de dire « non branché » ou « branché ailleurs ». Il sert à ne plus recréer.

## Les branches non fusionnées

586 branches distantes, environ 170 non fusionnées dans `main`. Presque toutes datent d'avant la
passation du 17/10 (Codex backend des 10 au 13/10, archives du 13/10, lots de septembre). Les
fouiller une à une, c'est sortir de la Boucle 1. Le travail jamais committé n'existe que sur le
poste du directeur : une session cloud ne peut pas le voir.

## Décision du pilote

Boucle 1 d'abord (salle). Ensuite, un lot « brancher l'existant » par zone, en commençant par la
recherche, avec ce tableau comme liste de départ. Aucune recréation tant qu'une ligne de ce
tableau peut répondre au besoin.
