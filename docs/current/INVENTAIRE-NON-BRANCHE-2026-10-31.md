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


## E. Tri des quatre rôles (agent de construction, 31/10/2026)

Demande du pilote du 31/10 : pour chaque rôle, chaque fonction présente dans le code, classée
**branchée en production** / **branchable sur un serveur existant** / **serveur à finir** /
**démonstration**, avec sa preuve. Relevé fait par lecture du code et des migrations, sur `main`
du 31/10 (`31e382f`) ; chemins Flutter sous `lib/`, migrations sous `supabase/migrations/`.
« Branchée en production » veut dire raccordée dans le code (route, entrée, adaptateur réel posé
dans `lib/main.dart` ou lecture Supabase directe) : **rien n'y est prouvé par le directeur en
production**, et l'installation sur la base distante des migrations datées du 01 et du 02/11
n'est pas vérifiée. Les numéros de ligne ont été relus par échantillon ; un écart d'une ligne
reste possible.

### Ce qui est faux ou bloqué, d'abord

- **L'élève adulte réel n'a pas de bouton Rejoindre.** C'est un compte tuteur avec la capacité
  « élève autonome » : `/eleve` le renvoie toujours vers `/eleve/adulte`
  (`lib/core/router/redirection.dart:325`), dont la lecture rend toujours « indisponible »
  (`lib/features/accueil_adulte/accueil_adulte_page.dart:125`). Son onglet Profil ouvre le compte
  du tuteur (`redirection.dart:264`). **En cours, autre lot** (pilote, 31/10) : les écrans de
  l'élève adulte (`accueilAdulteProvider`, `maClasseAdulteProvider`,
  `historiqueSeancesAdulteProvider`) et l'ouverture de la séance au jeton sont pris par un autre
  agent ; ce tri n'y touche pas.
- **La famille ne peut pas écrire de message** : elle lit, mais la capacité « écrire » n'a aucune
  source serveur (`lib/core/communications/capacites_communication.dart:113`).
- **Réaffecter une classe qui a déjà un enseignant** : aucune RPC (`affecter_enseignant_classe_c11bis`
  rend `deja_affecte`).
- **Corrections d'écrits antérieurs** : `/tc/groupes` n'est pas en démonstration pour l'élève et le
  tuteur, la production lit `mes_groupes_famille_v` (`lib/core/tc_groupe/port_groupes.dart:41`) ;
  il est refusé à l'enseignant (`redirection.dart:430`). `portObligationsPayablesProvider` (§C) est
  branché (`lib/main.dart:395`). La barre de l'enseignant a quatre destinations (Journée, Classes,
  Créneaux, Profil : `lib/core/widgets/nav_shell.dart:192`).

### Enseignant

Barre : quatre destinations, Journée, Classes, Créneaux, Profil (`lib/core/widgets/nav_shell.dart:192`). `/tc/groupes` est refusé à l'enseignant (`lib/core/router/redirection.dart:430-432`).

| Fonction | Classement | Preuve Flutter | Preuve serveur | Ce qui manque / taille |
|---|---|---|---|---|
| Voir ma journée (séances du jour, prochaine séance) | branchée en production | `features/journee/journee_page.dart:122` ; `core/router/app_router.dart:1382` ; lecture directe `core/enseignant/service_enseignant.dart:206` | `0025_role_enseignant.sql:62` | rien |
| Rejoindre la salle | branchée en production | `features/journee/journee_page.dart:1692` ; `features/fiche_groupe/fiche_groupe_page.dart:620` | `20261025010000_seances_concierge.sql:30` | rien (intérieur de la salle : autre lot) |
| Présents et « Alertes utiles » de la Journée | branchée en production | `features/journee/journee_page.dart:1219` ; `core/presence/service_presence.dart:249` | `0007_coran_structure_position_presence.sql:281` | rien |
| Cahiers « À terminer » | branchée en production | `features/journee/journee_page.dart:1136` ; `core/enseignant/service_enseignant.dart:241` | `0025_role_enseignant.sql:376` | rien |
| Remplir le cahier de transmission | branchée en production | `features/cahier/cahier_page.dart:70` ; `core/enseignant/depot_cahiers.dart:181` | `0025_role_enseignant.sql:243` | rien |
| Déclarer une absence sur une séance | branchée en production | `features/journee/journee_page.dart:695` ; `main.dart:422` | `20261011185954_b09_remplacements_seance.sql:107` | rien |
| Voir et prendre un remplacement | branchée en production | `features/remplacements/remplacements_page.dart:75` ; `main.dart:425` | `20261016100800_remplacements_offres_ouvertes.sql:27` ; `20261011185954_b09_remplacements_seance.sql:152` | rien |
| Notifications (cloche) | branchée en production | `features/notifications/notifications_page.dart:73` ; `features/notifications/notifications_supabase_provider.dart:10` | `0063_notifications_privatives.sql:4` | rien |
| Mes classes | branchée en production | `features/enseignant_classes/mes_classes_page.dart:151` ; `nav_shell.dart:201` | `0025_role_enseignant.sql:102` | rien |
| Fiche d'une classe (élèves, carte de séance) | branchée en production | `features/fiche_groupe/fiche_groupe_page.dart:80` | `0025_role_enseignant.sql:133` ; `20261025040000_horloge_classe_et_concierge_tuteur.sql:27` | rien |
| Annonces de la classe, publier une annonce | branchée en production | `features/com_annonces/publier_annonce_classe_page.dart:36` ; `main.dart:496` | `20261016090100_com_back_1_annonces_classe.sql:131` | rien |
| Messages | branchée en production | `features/enseignant_classes/mes_classes_page.dart:280` ; `main.dart:490` | `20261016090000_com_back_1_messages_metier.sql:401` | rien |
| Mes disponibilités (Créneaux) | branchée en production | `features/creneaux/creneaux_page.dart:43` ; `core/planning/service_planning.dart:319` | `0005_dashboards_affectation_regles.sql:380` | rien |
| Profil : pays et langues | branchée en production | `features/profil_enseignant/profil_enseignant_page.dart:416` ; `core/profil/service_declaration.dart:46` | `20261021220000_cand_l1b_forme_compte_candidat.sql:533` | rien |
| Profil : contrat et accusés | branchée en production | `features/profil_enseignant/profil_enseignant_page.dart:624` | `0004_inscription_kyc_appairage.sql:221` | rien |
| Signer la nouvelle version du contrat | branchée en production | `core/router/redirection.dart:203` ; `main.dart:279` | `0086_signature_contrat_versionnee.sql:125` | rien |
| Bienvenue (prérequis avant activation) | branchée en production | `features/bienvenue_enseignant/bienvenue_page.dart:82` | `20261016100500_contrats_travail_prerequis.sql:49` | rien |
| Mes revenus | branchée en production | `features/revenus_enseignant/revenus_enseignant_page.dart:120` ; `main.dart:347` | `20261018130000_fac_e_02_paie_par_eleve_present.sql:170` | rien |
| Signaler un besoin sur un élève (hors séance) | **raccordée par cette PR** (avant : branchable, simple) | `features/fiche_groupe/fiche_eleve_enseignant.dart:84` (`SignalerBesoin` sans `envoi`) ; adaptateur posé `main.dart:468` | `0059_student_concern_rpc.sql:30` | passer `envoi` ; simple |
| Nom public avec Sayyid ou Sayyida dans l'en-tête du Profil | **raccordée par cette PR** (avant : branchable, simple) | `features/profil_enseignant/profil_enseignant_page.dart:48` (toujours nul) ; titre déjà lu `core/profil/service_profil_enseignant.dart:158` | `0030_tc_socle.sql:182` | simple |
| « Séance annulée » sur la fiche de classe | branchable sur un serveur existant | `features/tc_espace_groupe/emplacements_groupe.dart:297` (toujours faux) | `0025_role_enseignant.sql:67` (statut exposé) | **plus, pas simple** : la carte montre la séance rendue par `horloge_classe`, qui ignore les séances annulées (`20261025040000_horloge_classe_et_concierge_tuteur.sql:87`) ; poser « annulée » sur cette carte serait faux. Il faut d'abord dire quelle séance annulée montrer |
| Pause programmée de la classe | branchable sur un serveur existant | `core/pause_seance/port_pause_seance.dart:285` | `20261012061517_x2_22_pause_seance.sql:61` | adaptateur à écrire ; plus |
| Photo publique | branchable sur un serveur existant | `features/profil_enseignant/photo_publique.dart:81` | `0032_tc_catalogue.sql:632` | adaptateur d'envoi ; plus |
| Objectif et page de reprise de chaque élève | branchable sur un serveur existant | `features/fiche_groupe/preparation_seance.dart:78` | `0033_tc_vues_rpc.sql:787` | adaptateur ; plus |
| Ressources récentes de la classe | branchable sur un serveur existant | `core/tc_bibliotheque/donnees_catalogue.dart:32` | `0032_tc_catalogue.sql:29` | adaptateur ; plus |
| Préparation de la prochaine séance | serveur à finir | `features/fiche_groupe/preparation_seance.dart:71` | absente | |
| Cartes de classe | serveur à finir | `core/tc_groupe/cartes_classe.dart:281` | absente | |
| Progression de la classe | serveur à finir | `features/tc_espace_groupe/emplacements_groupe.dart:291` | absente pour l'enseignant | |
| Anomalies de la revue courte | serveur à finir | `features/revue_groupe/anomalies_revue.dart:104` | `0024_qualite_pedagogique.sql:107` réservée à la direction | |
| « Classes disponibles » dans Créneaux | serveur à finir | `features/creneaux/creneaux_page.dart:27` | absente | contraire à DECISION-OFFRES du 09/10 : à retirer plutôt qu'à brancher, décision du directeur |
| Moyen de paiement de l'enseignant | serveur à finir | `core/capacites/port_mes_moyens_paiement.dart:201` | absente | |
| Communauté enseignants | serveur à finir | `features/com_communaute/port_communaute.dart:532` | absente | hors Boucles 1 à 4 |
| Groupes de démonstration, `/demo/enseignant` | démonstration | `core/tc_groupe/port_groupes.dart:39` | sans objet | |

### Élève (enfant en Interface guidée et élève adulte)

**Blocage :** l'élève adulte réel est un compte tuteur (`guardian`) avec la capacité « élève autonome ». `/eleve` le redirige toujours vers `/eleve/adulte` (`lib/core/router/redirection.dart:325`), dont la lecture rend toujours « indisponible » (`lib/features/accueil_adulte/accueil_adulte_page.dart:125`). Son « Aujourd'hui » n'a que la carte Paiements et **aucun bouton Rejoindre**. Son onglet Profil (`/compte`) part vers `/tuteur/compte` (`redirection.dart:264`). Correction de CLAUDE.md : `/tc/groupes` lit la production (`lib/core/tc_groupe/port_groupes.dart:41`, `mes_groupes_famille_v`).

| Fonction | Classement | Preuve Flutter | Preuve serveur | Ce qui manque / taille |
|---|---|---|---|---|
| Barre de l'enfant (Accueil, Ma classe, Coran, Mon espace) | branchée en production | `core/widgets/nav_shell.dart:132` | sans objet | |
| Barre de l'adulte (Aujourd'hui, Apprendre, Suivi, Profil) | branchée (barre seule) | `core/widgets/nav_shell.dart:107` | sans objet | Aujourd'hui et Profil ne servent pas l'adulte |
| Appairage de l'appareil de l'enfant | branchée en production | `core/appairage/service_enfant.dart:263` | `0004_inscription_kyc_appairage.sql:651` | |
| Cours du jour et prochain cours (Accueil standard) | branchée en production | `features/accueil_eleve/accueil_eleve_page.dart:179` ; `core/planning/service_planning.dart:321` | `20261017100400_af_l1_04_mes_seances_v_par_role.sql:9` | |
| Cours d'une classe sans séance encore | branchée en production | `core/planning/cours_du_moment.dart:25` | `20261101100100_cours_du_moment_par_classe.sql:34` | installation inconnue |
| Pauses de prière | branchée en production | `features/accueil_eleve/accueil_eleve_page.dart:233` | `0005_dashboards_affectation_regles.sql:811` | |
| Rejoindre la salle | branchée pour l'enfant ; aucune entrée pour l'adulte | `features/accueil_eleve/accueil_eleve_page.dart:520` | `20261025010000_seances_concierge.sql:30` | adulte : voir plus haut |
| Salle fermée si l'accès est suspendu | branchée en production | `features/acces_finance/acces_finance.dart:124` ; `main.dart:361` | `20261018170000_fac_f_relances_suspension.sql:433` | |
| Accueil en Interface guidée | branchée en production | `features/accueil_eleve/accueil_eleve_selon_presentation.dart:40` ; `main.dart:482` | `20261016102000_raccordement_prochaine_seance_groupe.sql:26` | |
| Travail à préparer (Interface guidée) | branchée en production | `features/accueil_eleve/accueil_accessibilite.dart:436` ; `main.dart:476` | `20261016100500_contrats_travail_prerequis.sql:24` | toucher une tâche ouvre `/eleve/suivi`, qui ne la montre pas |
| Besoin d'aide | branchée en Interface guidée | `features/accueil_eleve/accueil_eleve_selon_presentation.dart:46` ; `main.dart:415` | `0062_canal_support.sql:5` | Accueil standard sans entrée ; simple |
| Mon suivi (séances passées, présence) | branchée en production | `core/suivi/service_suivi.dart:111` | `0033_tc_vues_rpc.sql:47` | |
| Lire le Coran, reprendre où on s'est arrêté | branchée en production | `core/coran/service_coran.dart:473` ; `features/tc_mushaf/mushaf_page.dart:192` | `0007_coran_structure_position_presence.sql:58`, `:98` | glissement de page à faire (relevé du 31/10) |
| Coran en Interface guidée (« Reprendre ») | branchable sur un serveur existant | `features/accueil_eleve/coran_accessibilite.dart:49` (non importé) | `0007_coran_structure_position_presence.sql:98` | choisir la page selon l'interface ; simple |
| Mon espace : compte, matricule, langue, données, déconnexion | branchée en production | `features/compte/compte_page.dart:71` ; `main.dart:313`, `:337`, `:323` | `20261012181821_imm_back_1_person_registrations.sql:55` ; `20261023140000_courriels_langues.sql:102` | adulte envoyé vers `/tuteur/compte` |
| Confidentialité | serveur à finir | `features/compte/compte_page.dart:125` (ligne inerte) | absente | |
| Bibliothèque de ma classe | branchable sur un serveur existant | `core/tc_bibliotheque/donnees_catalogue.dart:33` (catalogue local vide) | `0035_ressources_du_groupe_rejoue_visibilite.sql:58` | adaptateur ; plus |
| Mes classes et l'espace de ma classe (`/tc/groupes`) | branchable sur un serveur existant (lecture déjà réelle) | `features/tc_mes_groupes/routes_tc_a.dart:40` ; seule entrée `features/salle/salle_page.dart:906` | `0033_tc_vues_rpc.sql:140` | entrée de menu absente ; simple |
| Cartes de la classe | serveur à finir | `core/tc_groupe/cartes_classe.dart:281` | absente | |
| Notifications (adulte) | branchée en production | `features/notifications/notifications_supabase_provider.dart:15` | `0063_notifications_privatives.sql:4` | l'enfant n'en a pas (décision Q5) |
| Paiements, historique, nos prix, recharger (adulte) | branchée en production | `features/accueil_adulte/routes_accueil_adulte.dart:84`, `:104`, `:110`, `:96` ; `main.dart:350`, `:373`, `:381` | `20261017160100_bf1_02_finances_profil.sql:285` ; `20261031100000_politique_commerciale_famille.sql:116` ; `20261018120000_fac_e_01_tarifs_v2.sql:879` | |
| Accueil de l'élève adulte (Rejoindre, avant le prochain cours, dernières séances) | branchable sur un serveur existant | `features/accueil_adulte/accueil_adulte_page.dart:125` | sources existantes, pas de RPC unique (`0033_tc_vues_rpc.sql:140` et voisines) | adaptateur composite ; plus. Repli : montrer l'Accueil standard, choix de produit du directeur |
| Toutes mes séances passées (adulte) | branchable sur un serveur existant | `features/accueil_adulte/historique_seances_adulte_page.dart:35` | `20261017100400_af_l1_04_mes_seances_v_par_role.sql:9` | double l'onglet Suivi ; plus |
| Ma classe adulte | branchable sur un serveur existant | `features/ma_classe_adulte/ma_classe_adulte_page.dart:109` (sans route) | `0033_tc_vues_rpc.sql:140` | plus |
| Annonces de ma classe | branchable sur un serveur existant | `features/ma_classe_adulte/ma_classe_adulte_page.dart:316` ; `main.dart:496` | `20261016090100_com_back_1_annonces_classe.sql:131` | simple |
| Écrire à l'école | branchable sur un serveur existant | `main.dart:490`, aucune route élève | `20261016090000_com_back_1_messages_metier.sql:401` | plus |
| Ma progression | branchable sur un serveur existant | `main.dart:436` (port de la famille) | `20261012060429_x2_20_ped_apres_partage.sql:237` | plus |
| Suivre mes demandes (adulte) | branchable sur un serveur existant | `features/accueil_adulte/routes_accueil_adulte.dart:69` ; `main.dart:254` | `20261012061244_c04_suivi_teacher_title_public.sql:7` | aucune entrée de menu ; simple |
| Mon espace adulte | serveur à finir | `features/mon_espace_adulte/mon_espace_adulte_page.dart:155` | absente | |
| Mon espace en Interface guidée, demander l'interface standard | branchable sur un serveur existant | `features/accueil_eleve/mon_espace_accessibilite.dart:45` ; `core/accessibilite/port_demande_presentation.dart:12` | `0080_age_presentation_requests.sql:106` | simple |
| Quitter le forfait famille | serveur à finir | `features/foyer/sortie_forfait.dart:76` | absente | |
| Démonstrations adulte et Interface guidée | démonstration | `features/demo/demo_adulte_page.dart:409` ; `features/demo/demo_accessibilite_page.dart:62` | sans objet | |

### Tuteur, famille

**Impasse en production :** « Voir les classes » d'un enfant sans classe (`features/accueil_famille/accueil_famille_page.dart:260`), « Faire une demande » du suivi (`suivi_famille_page.dart:74`) et la ligne Classe de la fiche enfant (`inscription_page.dart:116`) mènent au catalogue `/tuteur/classes/catalogue`, indisponible en production (`port_catalogue_classes.dart:163`). Le vrai chemin (parcours, offre, horaire) est branché. **Messages :** la famille lit, mais ne peut ni écrire ni ouvrir une conversation (`capacites_communication.dart:113`). **Second adulte :** écrans atteints seulement en démonstration (`features/demo/demo_adulte_page.dart:1214`).

| Fonction | Classement | Preuve Flutter | Preuve serveur | Ce qui manque / taille |
|---|---|---|---|---|
| Chaque enfant, sa classe, sa prochaine séance | branchée en production | `features/accueil_famille/accueil_famille_page.dart:320` ; `main.dart:174` | `0017_groupes_pedagogiques.sql:62` ; `0005_dashboards_affectation_regles.sql:734` | |
| Qui est en ligne pendant la séance | branchée en production | `core/presence/service_presence.dart:249` | `0007_coran_structure_position_presence.sql:281` | |
| Travail à faire avant le prochain cours | branchée en production | `features/accueil_famille/accueil_famille_page.dart:357` ; `main.dart:476` | `0032_tc_catalogue.sql:354` | |
| Suivre ses demandes, changements de classe | branchée en production | `main.dart:254`, `:260` | `0076_suivi_demandes_horaires_foyer.sql:24` ; `20261016100100_contrats_fusion_classes.sql:341` | |
| Questionnaire, offre, horaire ; aucun horaire ne convient ; renoncer | branchée en production | `features/parcours_offres/parcours_offres_page.dart:239` | `0043_offres_horaires_et_intentions.sql:682`, `:769` ; `20261012130000_f86_schedule_withdraw_positive_guards.sql:130` | |
| Choisir une classe déjà créée (catalogue) | serveur à finir (remplacé par DECISION-OFFRES du 09/10) | `core/capacites/port_catalogue_classes.dart:163` | absente | **les trois entrées sont raccordées par cette PR** : catalogue fermé, elles mènent au parcours (accueil, fiche) ou à l'accueil qui le porte (suivi) ; catalogue ouvert (démonstration), inchangées |
| Demande de présentation de l'enfant | branchée en production | `main.dart:257` | `0080_age_presentation_requests.sql:205` | |
| Accord aux visites d'observation | branchée en production | `features/compte_tuteur/compte_tuteur_page.dart:146` | `0004_inscription_kyc_appairage.sql:221` | |
| Notifications, annonces | branchée en production | `features/notifications/notifications_supabase_provider.dart:10` ; `main.dart:496` | `0063_notifications_privatives.sql:4` ; `20261016090100_com_back_1_annonces_classe.sql:147` | |
| Lire les messages d'une classe | branchée en production | `main.dart:490` | `20261016090000_com_back_1_messages_metier.sql:401` | |
| Écrire un message, ouvrir une conversation | serveur à finir | `core/communications/capacites_communication.dart:113` | envoi présent (`20261016090000_com_back_1_messages_metier.sql:568`), capacité « écrire » absente | petite fonction serveur ; plus |
| Accueil d'une famille déjà inscrite | branchée en production | `main.dart:457` | `20261012185327_imm_accueil_reclamation_apres_preuve_email.sql:11` | |
| Classe de l'enfant : planning, travail, progression | branchée en production | `main.dart:174`, `:268`, `:436` | `0054_seance_resumes_famille.sql:199` | |
| Ressources de la classe, Bibliothèque | branchable sur un serveur existant | `core/tc_bibliotheque/donnees_catalogue.dart:32` | `0035_ressources_du_groupe_rejoue_visibilite.sql:58` | un adaptateur catalogue ; plus |
| Accompagner l'enfant dans la salle | branchée en production | `features/classe_tuteur/rejoindre_avec_eleve.dart:115` | `20261025010000_seances_concierge.sql:30` | |
| Observer la séance | branchable sur un serveur existant | `core/config/env.dart:83` (forcé à faux en production) | `0033_tc_vues_rpc.sql:1086` | recette et décision du directeur |
| Profils enfants, ajouter un profil enfant | branchée en production | `core/appairage/service_appairage.dart:291` ; `core/capacites/port_creation_profil_eleve.dart:182` | `0004_inscription_kyc_appairage.sql:910`, `:828` | |
| Créer mon propre profil élève | branchable sur un serveur existant | `features/compte_tuteur/compte_tuteur_page.dart:210` ; adaptateur `main.dart:446` | `0052_profil_eleve_titulaire.sql:72` | écran de confirmation ; plus |
| Fiche enfant : identité, photo, Interface guidée, caméra, accès | branchée en production | `main.dart:358` | `0005_dashboards_affectation_regles.sql:535` | corriger le prénom n'existe pas |
| Couleur du profil | serveur à finir | `core/capacites/port_accents_profils.dart:64` | absente | |
| Appareils, connecter l'appareil d'un enfant | branchée en production | `features/foyer/foyer_page.dart:314` | `0004_inscription_kyc_appairage.sql:731` ; `20261012111500_f86_pairing_code_guard.sql:34` | |
| Nos prix, soldes, mouvements, recharger, résultat d'un paiement, historique | branchée en production | `main.dart:373`, `:353`, `:381` | `20261017160100_bf1_02_finances_profil.sql:322` ; `20261018100000_fi_br06_01_recharge_stripe.sql:188` | paiement Stripe réel non vérifié |
| Télécharger un reçu ou une facture | serveur à finir | `core/capacites/port_recus.dart:32` | absente pour la famille | |
| Historique des séances, détail et compte rendu, visites | branchée en production | `main.dart:443`, `:403` | `20261018190000_ped_cahier_partage.sql:651` | |
| Compte : informations, matricule, apparence, langue, aide, textes légaux, données | branchée en production | `main.dart:307`, `:313`, `:337`, `:415`, `:323` | `0062_canal_support.sql:5` ; `20261018150000_cpt_suppression_export.sql:174` | |
| Rechercher | branchable sur un serveur existant | `core/recherche/port_recherche.dart:120` | `20261012130003_rech_back_2_d1_search.sql:111` | plus |
| Second adulte : inviter, état de la place, accepter, reprise du foyer | branchable sur un serveur existant | `features/foyer/invitation_conjoint.dart:211` ; `place_adulte.dart:135` ; `acceptation_invitation.dart:152` ; `reprise_foyer.dart:149` | `0053_invitations_foyer.sql:73`, `:312` ; `0099_b04_titulaire_refusal_terminal.sql:10` | routes et adaptateurs ; plus (un lot cohérent) |
| Quitter le forfait famille | serveur à finir | `features/foyer/sortie_forfait.dart:76` | absente | |
| Donner son avis (lien) | branchée en production | `main.dart:331` | `20261019120000_avis_publics.sql:171` | pas de menu, voulu |
| Démonstrations famille | démonstration | `main.dart:550` | sans objet | |

N'existent nulle part : prévenir d'une absence de l'enfant, demander une pause d'un mois, corriger le prénom ou l'âge d'un enfant. Demander un créneau personnalisé : serveur présent (`0049_creneau_personnalise_ouvert_au_quota.sql:168`), aucun écran.

### Direction (et comptable)

Toutes les routes de la direction ont une entrée (onglet, tuile ou lien), sauf l'onglet caché de la politique de relecture des pièces. Le rôle direction n'entre pas dans `/comptable` (`lib/core/router/redirection.dart:315`). Correction du relevé du 31/10 §C : `portObligationsPayablesProvider` est branché (`lib/main.dart:395`).

| Fonction | Classement | Preuve Flutter | Preuve serveur | Ce qui manque / taille |
|---|---|---|---|---|
| Accueil, compteurs du jour | branchée en production | `core/admin/service_admin.dart:121` | `20261021220000_cand_l1b_forme_compte_candidat.sql:754` | |
| Activité récente | branchée en production | `core/journal/service_journal.dart:311` | `20261022000000_cand_l2a1_moteur_salle_examen.sql:2465` | |
| Alertes urgentes | serveur à finir | `core/alertes/port_alertes.dart:40` | absente | |
| Espace de traitement | branchée en production | `core/admin/service_admin.dart:121` | `20261021220000_cand_l1b_forme_compte_candidat.sql:681` | |
| Liste des classes | branchée en production | `main.dart:218` | `20261016100000_contrats_classes_admin.sql:102` | |
| Créer une classe, ses créneaux, son genre | branchée en production | `features/admin_groupes/groupes_page.dart:1240` ; `features/admin_groupes/feuille_creneau.dart:101` | `20261030100000_classe_plusieurs_creneaux.sql:336` | |
| Ajouter un élève, clôturer une classe | branchée en production | `core/admin/service_groupes.dart:359` | `20261031200000_d5_titulaire_adulte_en_classe.sql:28` ; `20261024150000_cloture_annule_seances.sql:21` | |
| Fusionner, transférer | branchée en production | `main.dart:221` | `20261016100100_contrats_fusion_classes.sql:341` | |
| Lire le cahier d'une classe, régler le partage | branchée en production | `main.dart:443` | `20261012061025_x2_21_adm_cahier_lecture.sql:77` ; `20261018190000_ped_cahier_partage.sql:612` | |
| Régler l'observation par les familles | branchée en production | `core/tc_observation/port_politique_observation.dart:315` | `0036_observation_defauts_academie_et_plafond_visite_groupe.sql:206` | |
| Pilotage par horaire | branchée en production | `main.dart:224` | `20261016100200_contrats_pilotage.sql:50` | |
| Planning de la semaine | branchée en production | `main.dart:187` | `20261011201001_x2_16_planning_rpc.sql:3` | |
| Désigner un remplaçant, bilan des remplacements | présent dans le code (PR claude/finir-remplacement) | `features/admin_planning/feuille_remplacant.dart` | `20261102400000_remplacements_direction.sql` | fusion et migration à installer |
| Demandes : réaffecter, accepter, refuser | branchée en production | `features/admin_tableau/tableau_de_bord_page.dart:447` | `20261012100400_f86_admin_mutation_guards.sql:104` | |
| Regroupements, « Créer la classe », affecter l'enseignant | branchée en production | `main.dart:198` ; `features/admin_regroupements/feuille_classe_regroupement.dart:147` | `20261021210100_c11bis_affectation_verifiee.sql:86` | |
| Confier une classe qui a déjà un enseignant à un autre | serveur à finir | aucun écran | absente (`affecter_enseignant_classe_c11bis` rend `deja_affecte`) | décision du directeur |
| Offres | branchée en production | `main.dart:202` | `0043_offres_horaires_et_intentions.sql:1050` | |
| Avis | branchée en production | `main.dart:331` | `20261019120000_avis_publics.sql:68` | |
| Courriels | branchée en production | `main.dart:333` | `20261023120000_courriels_sortants.sql:243` | |
| Annonces, messages | branchée en production | `main.dart:495` ; `main.dart:489` | `20261016090100_com_back_1_annonces_classe.sql:206` | |
| Modération, Studio | serveur à finir | `core/communications/moderation.dart:217` ; `features/com_studio/port_studio.dart:376` | absente | |
| Dossiers à valider, voir une pièce | branchée en production | `main.dart:181` ; `main.dart:273` | `20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:9` | |
| Comptes par rôle | branchée en production | `core/admin/service_comptes.dart:312` | `20261101100000_listes_comptes_par_role.sql:37` | |
| Candidatures, invitations | branchée en production | `main.dart:301` ; `main.dart:232` | `20261022000100_cand_l2a2_gestes_direction.sql:959` | |
| Reprises de foyer, import des inscrits, suppressions, admissions | branchée en production | `main.dart:190` ; `main.dart:195` ; `main.dart:327` | `0099_b04_titulaire_refusal_terminal.sql:116` ; `20261030140000_admission_lot_c.sql:391` | |
| Pédagogie (diagnostics, progression, évaluations, programmes, qualité) | branchée en production | `core/admin/service_diagnostics.dart:114` et voisins | `0021` à `0024` | |
| Bibliothèque | branchée en production | `main.dart:212` | `20261016100700_cap29_bibliotheque_ecritures.sql:104` | |
| Configuration, protection des enfants | branchée en production | `core/admin/service_configuration.dart:93` | `0001_fondations.sql:326` | |
| Politique de relecture des pièces selon le genre | serveur à finir | `core/capacites/port_politique_revue_kyc.dart:58` | absente | |
| Journal, incidents, agents, observations, tirage | branchée en production | `main.dart:184` ; `main.dart:249` ; `main.dart:406` | `0009_journal_audit.sql:243` ; `20261011200001_x2_15_incidents_rpc.sql:3` | |
| Finance : politiques commerciales, à valider, paiements, paie | branchée en production | `main.dart:367` ; `main.dart:400` ; `main.dart:390` ; `main.dart:395` | `20261017170000_fac_a_01_politiques_commerciales.sql:467` ; `20261102200000_releve_paie_direction.sql:87` | |
| Finance : vue globale, réserve, délégation | serveur à finir | `core/capacites/port_finance_direction.dart:312` ; `core/capacites/port_politique_reserve.dart:223` ; `core/capacites/port_delegation_finance.dart:322` | absente | |
| Recherche : retrouver une personne par matricule | branchable sur un serveur existant | `features/recherche/domaines/familles_eleves/port_resolution_ra.dart:53` | `20261012181821_imm_back_1_person_registrations.sql:340` | adaptateur et moteur ; plus |
| Recherche : classes et supports | branchable sur un serveur existant | `features/recherche/domaines/classes_supports/moteurs_classes_supports.dart:15` | `20261012130003_rech_back_2_d1_search.sql:111` | moteurs à réécrire ; plus |
| Recherche : référence de paiement | serveur à finir | `features/recherche/domaines/finance_communications/moteurs_finance_communications.dart:17` | `20261012130009_rech_back_5_finance_reference.sql:9`, mais dépend des encaissements sans serveur | |
| Comptable : paie à verser, paiements des familles, graphiques | branchée en production | `main.dart:395` ; `main.dart:390` ; `main.dart:340` | `20261102200000_releve_paie_direction.sql:87` ; `20261011203607_codex2_cpt_br_18_series.sql:87` | |
| Comptable : Aujourd'hui, virements, contractuels, bénéficiaires, trésorerie, encaissements, rapprochement, export | serveur à finir | `core/capacites/port_aujourdhui_comptable.dart:231` et voisins | absente | |
| Démonstrations (`?demo=admin`, finance, recherche) | démonstration | `main.dart:570` ; `features/demo/mode_demonstration.dart:378` | sans objet | |

Branchables simples côté direction : aucune.

### Raccordé dans la PR de ce tri (branche `claude/tri-quatre-roles`)

Les seules fonctions « branchables sur un serveur existant » qui étaient simples, en commençant
par celles d'usage quotidien :

1. **Famille, premier geste d'une famille sans classe** : « Voir les classes » (accueil),
   « Faire une demande » (suivi) et la ligne Classe de la fiche menaient au catalogue, fermé en
   production. Elles lisent la capacité `catalogueClassesOuvert` : fermé, elles mènent au parcours
   (offre puis horaire) ; ouvert (démonstration), rien ne change.
2. **Enseignant, « Signaler un besoin »** sur la fiche d'un élève : le signalement part par
   `portSignalementProvider` (`deposer_student_concern`, 0059), quand la fiche connaît la Classe.
3. **Enseignant, nom public avec Sayyid ou Sayyida** dans l'en-tête du Profil, lu dans
   `teacher_profiles.titre`.

### Ce qui reste listé, pas fait (serveur à écrire, plus d'une journée, ou décision)

- **En cours, autre lot** : accueil de l'élève adulte, Ma classe adulte, Mes séances passées de
  l'adulte, et l'ouverture de la séance au jeton. Mon espace adulte reste à écrire (serveur absent).
- Second adulte du foyer (inviter, état de la place, accepter, reprise du foyer) : un lot cohérent
  sur 0053, 0098 et 0099, routes et adaptateurs à écrire.
- Écrire un message côté famille (une petite fonction serveur de capacités).
- Ressources de la classe et Bibliothèque (un adaptateur catalogue sur `ressources_du_groupe`).
- Observer la séance (`Env.observationTuteurReelleActive` à faux en production) : recette et
  décision du directeur.
- Entrées de navigation de l'élève (`/tc/groupes`, « Besoin d'aide » sur l'Accueil standard,
  « Mes demandes » de l'adulte, Coran et Mon espace en Interface guidée) : la barre de chaque rôle
  est fixée par `mots-rewayah` ; ajouter une entrée est un choix du directeur.
- « Séance annulée » sur la fiche de classe de l'enseignant (voir la ligne ci-dessus).
- Finances de la direction et du comptable, alertes urgentes, modération, Studio, recherche :
  serveur à écrire.
