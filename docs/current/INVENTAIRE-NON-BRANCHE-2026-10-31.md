# Code présent mais non branché, relevé du pilote du 31/10/2026

Relevé fait sur `main` (3194965b6) par graphe d'imports depuis `lib/main.dart` (démo et
`_dev` exclus), plus les fournisseurs dont la valeur de production est un bouchon jamais
surchargé hors démonstration. Lecture seule. Aucun analyseur lancé sur ces fichiers : un
module « présent » n'est pas un module qui compile encore. Les points marqués *vérifié* ont
été relus dans le code par le pilote.

**Règle (directeur, 31/10/2026)** : avant de coder, chercher ce qui existe ; brancher ce qui
sert le besoin du lot ; ne rien dupliquer. On branche au besoin, lot par lot, jamais en bloc.

## A. Pendant la séance (`/salle`)

| Module | Rôle | Décision |
|---|---|---|
| `lib/core/tc_classe/session_persistante.dart`, `port_session_persistante.dart` (*vérifié*) | La séance vit hors de l'écran de la salle ; barre compacte sur tous les écrans | **Lot suivant** (séance en arrière-plan). Remplace la question de `core/router/garde_sortie_salle.dart`. Ses commentaires emploient « Cours en cours », mot interdit (`mots-rewayah`) : à renommer |
| `lib/features/salle_seance/portee_outils_salle.dart` | Portée des outils par salle : sans elle, l'état des outils peut passer d'une séance à l'autre | Même lot |
| `lib/features/salle_seance/signalement_seance.dart` | « Signaler un besoin » depuis la salle | À juger avec le lot ; doublon possible de `ouvrirSignalement` (`fiche_groupe/fiche_eleve_enseignant.dart`) |
| `portLayoutMushafProvider` (`lib/core/tc_coran/layout_lignes_indisponible.dart`, *vérifié*) | Page de Médine en 15 lignes | **Déjà branchée** : `Env.mushaf15L` vaut vrai par défaut depuis le 16/10/2026 (`lib/core/config/env.dart`). Ligne corrigée le 31/10 : le premier relevé la disait inactive en production, c'était faux |
| `portCartesClasseProvider` (`tc_espace_groupe/feuille_carte_classe`) | Cartes de Classe | Bouchon en production |
| `tc_etat_partage` (service, réducteur, `portEtatPartageProvider`) | État partagé persistant | La salle a son propre adaptateur LiveKit ; seuls types et codec servent. À ne pas rebrancher sans besoin |
| `tc_flux_academique/`, `tc_parcours/port_post_cours.dart` et voisins | Après-cours, retour éclair, fiche élève | Doublon du cahier de transmission (`features/cahier`). Ne pas brancher ; suppression à proposer au directeur |
| `features/tc_dock/teaching_dock.dart`, `puce_intention.dart` | Ancien dock à sept outils | Doublon de `salle_seance/barre_outils_salle.dart`. Idem |
| `features/tc_catalogue/support_actif/`, `class_library_picker.dart` | Suivi du support présenté, sélecteur de bibliothèque | Doublon de `bibliotheque_seance` / `panneau_bibliotheque_salle`. Idem |
| `core/tc_horloge/duree_academique.dart`, `tc_observation/capacites_observateur.dart` | Règle de durée créditée, capacités d'observateur | Spécification exécutable, non utilisée |

## B. Familles, tuteurs, adultes

| Module | État |
|---|---|
| `accueilAdulteProvider`, `maClasseAdulteProvider`, `historiqueSeancesAdulteProvider` (*vérifié*) | Aucune source serveur : `CapaciteIndisponible` hors démonstration. À traiter avant d'accueillir des adultes |
| `portRepriseFoyerProvider`, `portReponseInvitationProvider`, `invitationRecueProvider`, `foyerTitulaireProvider`, `portSortieForfaitProvider` | Bouchons en production |
| `portAlertesProvider` | Bouchon : la section des alertes est toujours indisponible |
| `mon_espace_adulte_page.dart`, `mon_espace_accessibilite.dart`, `soldes_foyer.dart`, `child_card.dart`, `port_resume_seance_famille.dart` | Non importés en production |
| `core/offres/port_demandes_horaires.dart` | Interfaces seules ; recouvre `admin_regroupements`, branché |

## C. Direction, comptabilité

- Bouchons en production : `portTresorerieProvider`, `portEncaissementsProvider`,
  `portRapprochementProvider`, `portObligationsPayablesProvider`,
  `portObligationsContractuelsProvider`, `portDelegationFinanceProvider`,
  `portControleDelegationProvider`, `portExportRapportsProvider`,
  `portFinanceDirectionProvider`, `portPayoutProvider`, `portBeneficiairesPaiementProvider`,
  `portMesMoyensPaiementProvider`, `portAujourdhuiComptableProvider`,
  `portRevueDossiersProvider`, `portPolitiqueReserveProvider`, `portPolitiqueRevueKycProvider`,
  `portCatalogueClassesProvider`, `portRecusProvider`, `port_capacite_payout.dart`.
- Recherche globale : `moteursRechercheProvider` est vide en production
  (`features/recherche/domaines/**`, non importés) ; la recherche ne rend aucun domaine.

## D. Sans besoin dans les Boucles 1 à 4

Communauté, studio, messages vocaux, `portGardePromotionProvider`, `portModerationProvider`,
`envoiPhotoPubliqueProvider`, `fabriqueLecteurQrProvider`, `ecran_a_construire.dart`, doubles de
démonstration et de test. On n'y touche pas.

## Ordre retenu par le pilote

1. Séance en arrière-plan (`session_persistante`, `portee_outils_salle`).
2. Écrans de l'élève adulte.
3. Le reste au besoin, lot par lot.

## Lacunes signalées par le directeur, à traiter après (31/10/2026)

- Coran (Mushaf) : impossible de changer de page en glissant le doigt ; d'autres lacunes non
  encore listées. Le Coran marche ; ce n'est pas urgent. Le lot qui s'en chargera part de
  l'existant (`lib/core/tc_coran/`, `BarrePrecedentSuivant`) et n'en recrée rien.
