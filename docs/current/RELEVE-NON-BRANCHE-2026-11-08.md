# Relevé du code sans effet en production (lecture seule, `main` dbacab482, 08/11/2026)

**Incertain ou non vérifié, d'abord.** Je n'ai lancé ni `dart analyze` ni `verifier_branchement`. Je n'ai rien vérifié sur la base distante : « une migration du dépôt crée X » ne veut pas dire « X est en production », et les migrations nommées `202611080…` à `202611150…` ne sont peut-être pas installées. Les signatures des RPC n'ont pas été comparées aux appels Flutter.
**Deux faux dans les sources à corriger.** Le relevé du 31/10 (§A) date d'avant la PR #204 : `session_persistante`, `portee_outils_salle`, la Bibliothèque de la classe et l'observation sont branchés depuis ; `tc_dock/teaching_dock`, `tc_flux_academique` (sauf un fichier) et `support_actif` ont été supprimés. Et « aucun usage » n'est vrai qu'au sens de la production : sur les 19 lignes marquées « supprimé le 08/11 », 8 sont importées par un autre fichier de `lib/` (démonstration, galerie, fichier toléré ou recherche) et 18 sont citées par des tests ou par ce code ; seul `ecran_a_construire.dart` n'a aucune référence (voir §4).

Méthode : graphe des surcharges de `lib/main.dart` (`_surchargesAppReelle`, lignes 255 à 850, plus `surchargeRevueDossiersProduction` et `surchargePrerequisEnseignant()`) ; lecture du corps par défaut des 184 fournisseurs `port*/moteurs*/envoi*/fabrique*` hors `lib/features/demo/` (76 ne sont pas surchargés) ; liste des 376 fonctions `grant execute … to authenticated` des migrations comparée aux chaînes de `lib/` (120 ne sont citées nulle part).


> **Correction du 08/11/2026 (vers 05:30 UTC), après vérification avant code, décisions du pilote :**
> - **2** (`groupe_roster_enseignant` vers `projectionElevesProvider`) : **mis de côté, doublon pour l'instant**. La fonction ne rend rien qu'au titulaire (`g.teacher_id = auth.uid()` et rôle `teacher`) : le remplaçant et la direction ne lisent rien, contrairement à ce que disait ce relevé. La page de reprise et les objectifs de l'étape sont déjà branchés (CAHIER-C1, CAHIER-C2). La fraîcheur de `learning_assignment` et `student_reading_position` en production reste à lire.
> - **3** (`mes_evaluations_publiees`, `publier_evaluation`) : **reclassé (c)**. Une publication ne porte qu'un titre, une classe et un code EV par élève : aucun résultat n'est stocké. Le serveur des résultats manque.
> - **6** (`maj_eleve_pedagogie`) : **non branché, décision produit**. Le niveau en texte libre risque une seconde vérité à côté du programme publié (CAHIER-C2) ; la décision revient au directeur.
> - Restent réels : **1** (PR 348), puis **5** (Retour éclair), feu vert du pilote ; **4** après vérification du doublon.

## 1. État des exemples nommés

| Élément | Ce qui est vrai sur `main` aujourd'hui |
|---|---|
| `/tc/groupes`, `lib/core/tc_groupe/port_groupes.dart` | **Pas une démonstration.** En production, `portGroupesSelon(demo: Env.playgroundActif)` rend `GroupesSupabase`, qui lit `mes_groupes_famille_v` (créée par `supabase/migrations/0033_tc_vues_rpc.sql:140`, remplacée par `20261109400000_drapeaux_pays_enseignant.sql:61`). Le double de démonstration ne sort que sous `PLAYGROUND=true`. Le tuteur est renvoyé vers son Accueil (`redirection.dart:464`) ; l'élève y entre seulement depuis la salle (`salle_page.dart:1083`) ; l'enseignant est refusé (`redirection.dart:492`). La phrase de `CLAUDE.md` (« classes de démonstration ») est fausse |
| `session_persistante` | **Branché** : `BarreSeanceEnDirect` est montée dans `lib/app.dart:130` et lue par `salle_page.dart` |
| `portee_outils_salle` | **Branché** : `PorteeOutilsSalle` enveloppe la salle (`app_router.dart:2889`) |
| `tc_dock` | `teaching_dock.dart` et `puce_intention.dart` ont été supprimés (#204). Les trois fichiers restants servent la salle (`barre_stylet` vers `ecriture_seance.dart`, `couche_annotation` vers `surface_page_fixe.dart`) |
| `tc_flux_academique` | Il ne reste que `carte_feedback_seance.dart`, toléré et non atteint (voir §2) |
| `tc_etat_partage` | **Raccord vide** : `portEtatPartageProvider` n'a **aucun lecteur** hors de son propre fichier. Son adaptateur `EtatPartageSupabase` (`session_shared_content`) est pourtant monté (`main.dart:680`), et il ne nourrit que ce service mort |

## 2. Inventaire

Catégories : (a) branchable, serveur déjà dans le dépôt et adaptateur client présent ; (b) il manque seulement l'adaptateur client sur une RPC, une table ou une vue existante ; (c) serveur manquant ; (d) doublon d'un module déjà branché ; H = hors zone (recherche, autre agent).

### 2.1 Suivi pédagogique et séance

| Fichier(s) | Ce que ça ferait pour l'école | Cat. | Serveur (migration du dépôt) |
|---|---|---|---|
| aucun client ; table `cahier_observations` | Montrer, pour chaque élève de la classe, les points à renforcer et « prêt pour le petit bilan » que l'enseignant écrit déjà dans le cahier | (b) | `observations_classe` : `supabase/migrations/20261110610000_cahier_c3_confirmation.sql:117` (table `:27`) |
| `lib/features/fiche_groupe/preparation_seance.dart:95` (`projectionElevesProvider` rend toujours `{}`), lu par `cahier_page.dart:252`, `fiche_groupe_page.dart:301`, `revue_groupe_page.dart:240` | Donner à l'enseignant et au remplaçant l'objectif, l'unité en cours et la page de reprise de chaque élève, dans la fiche de la classe, le cahier et la revue | (b) | `groupe_roster_enseignant` : `0033_tc_vues_rpc.sql:787` (aucun appel dans `lib/`). Peut recouper `etapes_eleves_classe`, déjà branchée |
| aucun client | La famille et l'élève voient les évaluations publiées qui les concernent, avec leur code | (b) | `mes_evaluations_publiees` : `20261108200000_n4_lectures_bibliotheque_evaluations.sql:242` |
| aucun client côté direction | La direction publie une évaluation avec des codes EV et choisit l'affichage (code, nom ou les deux) | (b) | `publier_evaluation` `20261013010000_imm_back_2_evaluation_codes.sql:122` ; `changer_affichage_evaluation` `:171` ; `evaluation_publiee_lignes` `:204` |
| `lib/features/tc_espace_groupe/emplacements_groupe.dart:292` (`progressionGroupeProvider` rend toujours `null`) | Barre de progression de la classe (chapitre, part faite) dans l'espace de la classe | (a), à juger | `suivi_pedagogique_eleve` `20261115000000_suivi_eleve_pedagogique.sql:166` et `etapes_eleves_classe` `:131`, déjà lues par `carte_suivi_pedagogique` et `etape_eleve`. Risque de doublon (d) |
| `lib/features/tc_flux_academique/carte_feedback_seance.dart` (toléré, non atteint) ; `tendanceFeedbackProvider` (`core/tc_parcours/port_feedback.dart:147`, aucun lecteur) | Après la séance, l'élève dit s'il a compris ; l'enseignant voit la tendance de compréhension de sa classe | (a) | `FeedbackSupabase` déjà monté (`main.dart:784`) ; `question_feedback_pour` `0065_feedback_questions_and_private_aggregate.sql:51`, `soumettre_feedback` `:144`, `tendance_feedback_comprehension` `:191` ; `doit_demander_feedback` `0033_tc_vues_rpc.sql:1355` (non appelée) |
| aucun client | La direction corrige le niveau ou la riwaya d'un élève (le point de départ) | (b) | `maj_eleve_pedagogie` : `0005_dashboards_affectation_regles.sql:570` |
| `lib/features/salle_seance/signalement_seance.dart` (toléré) | « Signaler un besoin » depuis la salle, déjà rempli avec la séance | (a) | `SignalementSupabase` monté (`main.dart:787`) ; `deposer_student_concern` `20261018160000_pe_protection_enfants.sql:71`. Enveloppe `ouvrirSignalement`, déjà branché ailleurs |
| `emplacements_groupe.dart:298` (`seanceAnnuleeProvider` rend toujours `false`) | Afficher « Séance annulée » sur la carte de la classe | (a), réserve | statut exposé par `0025_role_enseignant.sql:67`. Réserve du 31/10 : `horloge_classe` ignore les séances annulées, il faut d'abord choisir quelle séance montrer |
| `lib/core/tc_groupe/cartes_classe.dart:281` (`PortCartesClasseIndisponible`) | Les cartes de la classe | (c) | aucune trouvée |
| `lib/core/accessibilite/age_eleve.dart:44` (`AgeEleveInconnu`), lu par `salle_page.dart:1863`, `:2070` | La salle tutoie un enfant et vouvoie un adulte | (c), non vérifié | aucune lecture d'âge trouvée pour l'élève connecté |
| `lib/core/tc_etat_partage/*` (`portEtatPartageProvider`) ; `lib/core/tc_realtime/providers_tc_realtime.dart:25` (`TransportIndisponible`) | État partagé de la séance, rejoué après une coupure | (d) | la salle a son propre adaptateur LiveKit ; `session_shared_content` `0032_tc_catalogue.sql:404` |
| `lib/core/tc_coran/navigation_coran.dart:173` (`portEtatPartageCoranProvider` rend `null`) | Synchroniser la page du Coran par l'état partagé | (d) | même cause |
| aucun client | Suivre le support présenté | (d) | `presenter_support` / `support_actif` `20261016100400_contrats_support_actif.sql:102`, `:190` ; le client a été supprimé en #204 comme doublon |
| `lib/core/capacites/port_resume_seance_famille.dart` (toléré) | Résumé de séance pour la famille | (d) | `resume_seance_famille` `20261018190000_ped_cahier_partage.sql:247` existe, mais la famille lit déjà `compte_rendu_famille` (`partage_pedagogique_supabase.dart`). `enregistrer_resume_seance` (`20261011190000_b08_published_summary_guard.sql:4`) : même doublon |
| `lib/core/tc_outils/etat_outils.dart:77` (`PositionDockMemoire`) | Garder la position de la barre d'outils | sans serveur | la position est oubliée au redémarrage ; mineur |

### 2.2 Élève, famille

| Fichier(s) | Ce que ça ferait | Cat. | Serveur |
|---|---|---|---|
| `lib/features/accueil_eleve/mon_espace_accessibilite.dart` (toléré, échéance 15/11), avec `core/accessibilite/port_demande_presentation.dart` | L'élève en Interface guidée demande l'interface standard | (b) | `demander_presentation_standard` : `0080_age_presentation_requests.sql:106` (non appelée) |
| `lib/features/mon_espace_adulte/mon_espace_adulte_page.dart` (toléré, échéance 15/11) | Espace personnel de l'élève adulte | (c) selon le 31/10 ; non revérifié depuis que `portEspaceAdulteProvider` est monté (`main.dart:269`) | |
| aucun écran | La famille demande un créneau personnalisé | (b), décision du directeur (DECISION-OFFRES) | `demander_creneau_personnalise` `0050_demandes_horaires_privees_admin.sql:106` ; `mes_demandes_horaires` `:70` |
| `lib/core/capacites/port_catalogue_classes.dart:163` | Catalogue des classes | (c), écarté par DECISION-OFFRES du 09/10 | |
| `lib/features/foyer/sortie_forfait.dart:76` | Quitter le forfait famille | (c) | |
| `lib/core/capacites/port_recus.dart:32` | Télécharger un reçu | (c) | |

### 2.3 Direction, comptable, communication (hors priorité pédagogique)

| Fichier(s) | Cat. |
|---|---|
| `port_tresorerie`, `port_encaissements`, `port_rapprochement`, `port_finance_direction`, `port_politique_reserve`, `port_delegation_finance` (deux ports), `port_export_rapports`, `port_payout`, `port_beneficiaires_paiement`, `port_aujourdhui_comptable`, `port_politique_revue_kyc` (tous sous `lib/core/capacites/`, par défaut `*Indisponible`) | (c) selon le 31/10, non revérifié un par un |
| `com_studio` (2 ports), `com_communaute` (2), `com_vocal` (3), `communications/moderation.dart`, `port_elements_enregistres.dart`, `port_pieces_jointes.dart` (politique), `port_brouillons.dart` (mémoire) | (c), hors Boucles 1 à 4 |
| `eleves_sans_enseignant` (`0008_attribution_manuelle.sql:55`), `classes_a_confirmer_admin` (`0071_classes_en_attente_visibles.sql:4`) | (d), probablement remplacées par les regroupements ; non vérifié |
| `lib/features/recherche/**`, `moteursRechercheProvider`, `portResolutionRaProvider`, `rech_*`, `rechercher_personne_par_matricule` | **H, hors zone** |

## 3. Classement des (a) et (b) par utilité pour l'école (VISION-ECOLE)

1. **`observations_classe`** (b) : l'enseignant écrit déjà ces données et personne ne les lit. La vision exige qu'une donnée saisie serve, et c'est le point 5 (« ce qui le freine »), utile au remplaçant.
2. **`groupe_roster_enseignant` vers `projectionElevesProvider`** (b) : « où il en est » élève par élève (objectif, unité, page), dans trois écrans déjà atteints. Le remplaçant y trouve où continuer.
3. **`mes_evaluations_publiees` et `publier_evaluation`** (b) : « comment on le mesure ». La famille et l'élève voient les évaluations, aujourd'hui saisies par la direction seule.
4. **`progressionGroupeProvider`** (a, à juger) : « à quelle vitesse » au niveau de la classe, sur le calcul serveur déjà écrit. Il faut d'abord écarter le doublon avec `carte_suivi_pedagogique`.
5. **Retour éclair (`carte_feedback_seance`, `tendanceFeedbackProvider`)** (a) : mesure la compréhension sans travail pour l'enseignant. Serveur et adaptateur sont prêts, il manque l'écran.
6. **`maj_eleve_pedagogie`** (b) : corriger le point de départ (niveau, riwaya), sur lequel reposent l'étape et la date limite.
7. **`signalement_seance`** (a) : remonter une difficulté pendant la séance, déjà remplie, sans corvée.
8. **`seanceAnnuleeProvider`** (a, réserve) : information juste pour la famille et l'enseignant ; une règle reste à trancher.
9. **`demander_presentation_standard`** (b) : confort de l'élève, pas de suivi.
10. **`demander_creneau_personnalise`** (b) : inscription, et suspendu à DECISION-OFFRES.

## 4. Lignes « supprimé le 08/11 » de `tool/branchement_tolere.txt` (19 lignes ; rien n'a été supprimé)

Commande par ligne : `grep -rln "<nom_du_fichier>.dart" lib test tool --include=*.dart` (le fichier lui-même est exclu), puis lecture de chaque importeur trouvé dans `lib/`. `lib/features/demo/` et `lib/features/_dev/` sont exclus du graphe (`tool/verifier_branchement.dart:38-39`).

| Fichier | Importeurs dans `lib/` | test/tool | « Aucun usage en production » |
|---|---|---|---|
| `core/accessibilite/port_demande_presentation.dart` | `features/accueil_eleve/mon_espace_accessibilite.dart` (toléré « branché à l'étape 3, 15/11 »), `features/demo/demo_accessibilite_page.dart` ; `port_reponse_presentation.dart` le cite en commentaire | 2 | vrai en production, mais **contradiction** : supprimer ce fichier casse le fichier qu'on doit brancher le 15/11 |
| `core/capacites/acces_foyer_depuis_eleves.dart` | 0 (seulement un commentaire dans `port_acces_foyer.dart:148`) | 2 | vrai ; 2 tests à retirer avec lui |
| `core/capacites/avis_demonstration.dart` | 0 | 2 | vrai ; 2 tests en dépendent |
| `core/capacites/courriels_demonstration.dart` | 0 | 1 | vrai ; 1 test |
| `core/capacites/langues_communication_demonstration.dart` | 0 | 2 | vrai ; 2 tests |
| `core/capacites/port_capacite_payout.dart` | `features/demo/comptable/paiements_demo.dart` | 3 | vrai en production ; **la démonstration l'importe** |
| `core/capacites/port_preferences_persistantes.dart` | 0 | 2 | vrai ; 2 tests |
| `core/capacites/port_resume_seance_famille.dart` | 0 | 2 | vrai ; serveur présent mais doublon (§2.1) |
| `core/identite/matricule_demo.dart` | `features/demo/mode_demonstration.dart:49` | 2 | vrai en production ; **à déplacer, pas à supprimer** : la démonstration casserait |
| `core/recherche/corpus_demo_recherche.dart` | `core/recherche/moteurs_demo_recherche.dart` | 1 | H |
| `core/recherche/moteur_recherche_demo.dart` | `corpus_demo_recherche.dart`, `moteurs_demo_recherche.dart` | 4 | H |
| `core/recherche/moteurs_demo_recherche.dart` | `features/demo/mode_demonstration.dart:59` | 7 | H |
| `core/router/ecran_a_construire.dart` | 0 | 0 | **vrai, aucune référence nulle part** |
| `core/tc_horloge/duree_academique.dart` | 0 | 1 | vrai ; 1 test |
| `core/tc_observation/capacites_observateur.dart` | 0 | 1 | vrai ; 1 test |
| `core/tc_realtime/transport_memoire.dart` | 0 | 4 | vrai ; 4 tests (dont ceux de `tc_etat_partage`) |
| `core/widgets/child_card.dart` | `features/_dev/galerie/catalogue_galerie.dart:56` | 2 | vrai en production ; **la galerie l'importe** |
| `features/compte/soldes_foyer.dart` | 0 | 3 | vrai ; 3 tests |
| `features/recherche/domaines/familles_eleves/resolution_ra_demo.dart` | `features/demo/mode_demonstration.dart:82` | 5 | H |

Bilan : 19 lignes, dont 4 de recherche (H). Sur les 15 autres, une seule n'a aucune référence nulle part (`ecran_a_construire.dart`). Treize sont lues par des tests, qu'il faudrait retirer en même temps. Trois sont importées par la démonstration ou la galerie (`port_capacite_payout`, `matricule_demo`, `child_card`). Une contredit l'échéance du 15/11 (`port_demande_presentation`).

## 5. Mot « groupe » visible

`assets/i18n/fr.i18n.json` : aucune valeur ne dit « groupe » à une personne. La seule occurrence est le lien `admin.politiqueRevueKyc.echecEnregistrement` → `@:admin.groupes.observationErreur`, une clé dont le texte est « Le réglage n'a pas pu être enregistré. ». La recherche `grep` des `Text(`, `label:`, `title:`, `tooltip:`, `hintText:` et `semanticsLabel:` en dur avec « groupe » sous `lib/` (hors démonstration et `_dev`) ne rend rien. « groupe » ne reste que dans des identifiants, des chemins et des commentaires (par exemple les en-têtes de `preparation_seance.dart` et `emplacements_groupe.dart`), que personne ne voit.
