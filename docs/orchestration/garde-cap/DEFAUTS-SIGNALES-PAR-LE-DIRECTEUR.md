# Défauts signalés par le directeur : registre du garde-cap

Règle (garde-cap, 07/11/2026, après la perte de la trace du défaut photo) : tout défaut signalé par
le directeur est écrit ici **le jour même**, avec ses preuves, sa cause, son responsable et son
train. Une ligne ne se ferme que quand le directeur l'a prouvé lui-même en production.

| Signalé | Défaut | État |
| :--- | :--- | :--- |
| 07/11/2026 | Un tuteur ne peut changer ni sa photo ni celle de son deuxième enfant (production) | **OUVERT** : cause prouvée ; correction PR 326 (E, PHOTO-FOYER, sans child_of) installée avec le train g5 le 08/11 à 01:45 UTC (base relue par le garde-cap à 01:49 : règle, 3 policies, photo du tuteur recopiée) ; preuve du directeur attendue (changer sa photo depuis son profil élève, version 709) |
| 07/11/2026 (23:5x) | D1. Le tuteur ne peut pas retirer son deuxième enfant (adulte du foyer) depuis son profil | **CLOS par décision du directeur (08/11 00:58)** : un tuteur ne peut plus créer de profil adulte (mineur_fantome refuse 18 ans et plus) ; le seul cas, supprimé ; reste l'invitation du conjoint adulte qui gère son profil seul (PR 275, en production) |
| 07/11/2026 (23:59, relayé par le pilote) | D3. « Paramètres → Préférences → Notifications NE MARCHE PAS » ; notifications actives par défaut demandées | **OUVERT** : PR 328 (H, NOTIF-DEFAUT) livrée avec le train g5 (08/11, main 225a957d) ; preuve de la cause à joindre au bilan de H |
| 08/11/2026 (~01:00) | D4. Plus aucun profil enfant ne se crée (creer-profil-enfant 500 depuis au moins 00:56) | **CLOS, prouvé par le directeur en production le 08/11 vers 01:37** : PR 331 (mot de passe conforme), creer-profil-enfant v59 ; journal POST 200 à 01:37:25 |
| 07/11/2026 (23:5x) | D2. Dans l'admin, un profil retiré reste affiché jusqu'à la déconnexion | **OUVERT** : cause non relevée ; responsable et train à fixer après le g4 |

## 07/11/2026 : photo du tuteur et de son deuxième enfant

Preuves (production, lecture seule, journaux du 07/11, foyer de test du directeur `972a8054`) :

- l'envoi du fichier dans le seau `avatars` réussit (200), puis l'enregistrement par
  `poser_photo_eleve` échoue (400, « enfant introuvable dans votre foyer », ligne 12) :
  07:42 (×6), 07:45, 11:50 (×3), 13:16, 22:51 ; contre-épreuve : un enfant mineur du même foyer
  passe (07:41, 200) ;
- aucun appel à `poser_ma_photo` de la journée ;
- le 401 sur `photo_adulte_moi` à 11:34:57 est un jeton expiré, pas la cause.

Causes :

1. **Deuxième enfant** (`913e7d6d`) : créé à 07:27 par `creer_profil_enfant` (`minor`), mais il a
   18 ans ou plus (cohorte `adulte_18_plus`) ; à 07:29 `profil_apprentissage_enregistre` l'a passé en
   `autonomous`. `poser_photo_eleve` exige `student_type = 'minor'`.
2. **Tuteur qui étudie** (`47c14844`, ligne `student_profiles` `autonomous` depuis PROFIL-TITULAIRE) :
   l'application envoie sa photo par `poser_photo_eleve` (refusée).
3. **Photo masquée** (vu par l'ancien garde-cap) : `private.photo_source` lit
   `student_profiles.avatar_storage_key` dès qu'une ligne `student_profiles` existe ; la photo déjà
   posée du tuteur est dans `profiles.photo_storage_key` et n'est plus lue (1 tuteur en production).

Correction confiée à E, lot PHOTO-FOYER, plage 20261120400000 à 20261120499999, train séparé après le
g4 : `poser_photo_eleve` accepte un mineur du foyer, le tuteur lui-même et un compte enfant géré par
lui (un adulte qui a son propre compte reste refusé) ; une seule clé par personne
(`student_profiles.avatar_storage_key`), reprise sans effacement depuis `profiles.photo_storage_key` ;
le client envoie la photo du tuteur par `poser_ma_photo` ; scénario rouge sans la migration.
Fichiers orphelins dans le seau : 3 sous `913e7d6d/`, 3 sous `47c14844/` (dont la photo actuelle).

## 07/11/2026 (23:5x) : D1, retrait d'un adulte du foyer par le tuteur

Relevé par le pilote en production : le deuxième enfant (`913e7d6d`, le même que pour la photo) était
`student_type = 'autonomous'` dans le foyer ; `tuteur_supprimer_profil_enfant` (20261108600000) refuse
`autonomous` par conception (`profil_hors_foyer`). Même famille que le défaut photo : un adulte créé
par le tuteur dans son foyer, sans connexion propre. Retiré par l'administration à 23:51:53
(`deleted_at` vérifié par le garde-cap). **Règle à trancher par le directeur** : un tuteur peut-il
retirer, et poser la photo de, un adulte de son foyer qu'il a créé lui-même ?

## 07/11/2026 (23:5x) : D2, liste de l'admin pas rafraîchie après un retrait

Après `direction_supprimer_comptes`, le profil retiré reste affiché jusqu'à la déconnexion du
directeur. Cause non relevée (probablement un cache ou un provider non invalidé). Responsable et
train à fixer après le g4.

## Test qui dépend de l'heure (relevé du garde-cap, 08/11/2026 00:11 UTC)

`test/features/notifications/notifs_l6_test.dart` (« trois répétitions du même jour ») place trois
notifications à 10, 11 et 12 minutes de l'heure courante : entre 00:00 et ~00:12 UTC, elles tombent sur
deux jours et le test échoue (vu sur la PR 323). Dette : fixer l'heure dans le test. Porteur à désigner.

## Migration de main jamais installée (relevé du garde-cap, 08/11/2026 00:45 UTC)

`20261110620000_cahier_c3_paie_par_seance.sql` est dans `main` mais n'a jamais été installée en
production : `private.cahier_c3_coupure` était absente, et la PR 276 en dépend. Le garde-cap avait
vérifié seulement le sens production → dépôt ; il a ensuite vérifié le sens dépôt → production
pour les 30 fichiers de `main` depuis le 01/11 sans version à leur nom : les 29 autres ont leur
effet en production (collés dans l'éditeur). Feu vert donné au pilote : installer 620 sans ses lignes
`BEGIN;` (l. 27) et `COMMIT;` (l. 132), puis 276. **Dette** : aligner le fichier de `main` (retirer ces
deux lignes) au train suivant.

## Lots sans PR à ne pas perdre (relevé du garde-cap, 08/11/2026)

- **HARMONISER-ARGENT** (dette obligatoire, `docs/current/A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) :
  branche `claude/harmoniser-argent` @ 9cf1b12f (07/11 11:51, « relevé et proposition, phase 1 »,
  docs), **aucune PR**. Le pilote lui donne un porteur après le train photo.

## Décision du directeur, 08/11/2026 00:58 UTC

« cette question ne se pose plus, parce qu'un tuteur ne peut plus créer un profil adulte, le seul cas
a été supprimé "Ibrahim", ce qui reste c'est de pouvoir inviter son conjoint qui est déjà adulte et
qui gère son profil seul. » Conséquence : PR 326, la ligne CHILD_OF est retirée, PF1 devient un refus.
« tu dois tout faire, tu ne reportes plus rien » : le report au réveil est annulé (620, 276, 316, g5).

## Installation du 08/11/2026 (01:01-01:04 UTC), relue par le garde-cap

620 installée (version 20261108010101) : texte installé = fichier de `main` moins les lignes 27 et 132,
**plus une ligne vide ajoutée par erreur dans l'en-tête de commentaires** (md5 103e361d au lieu de
a11701a1 ; aucun octet SQL différent, écart signalé par le pilote). 276 (20261108010142, md5 9bce6ca0)
et 316 (collée par le directeur, 20261120200100, md5 5581a42c, tâche cron « 23 3 * * * » active) :
effets vérifiés en production.

## Train g5 complet en production (08/11/2026 02:00 UTC), relu par le garde-cap

Migrations 200400, 200500, 400000, 300000, 300100 (01:40-01:46) puis 300200 après la version 709
(01:59) : effets vérifiés. Dette relevée : 4 tables du schéma `private` sans RLS (aucun accès client,
`authenticated` sans USAGE sur `private`) ; correctif réservé en 20261120500000.

## Dette d'argent : séance en panne technique (relevé du garde-cap, 08/11/2026 06:20 UTC)

Pas une question au directeur : il a interdit les questions d'argent (consigne du 08/11 vers 02:12 :
ce qui est sensible devient un réglage de l'administration). Arbitrage du pilote, 08/11 06:23.

- **Constat** : le serveur paie l'enseignant pour une séance `tech_failure` depuis X2-17
  (`20261012120101_x2_17_treasury_triggers.sql`, l. 399-400 ; `private.pai_due_seance`,
  `20261102900000_presence_minutes.sql`, l. 258), sans décision datée retrouvée dans `docs/current`.
  Relevé par E (REVENUS-2), comportement inchangé par la PR 353.
- **Dette** : un réglage de l'administration « payer une séance interrompue par une panne technique :
  oui / non », défaut = comportement actuel, dans un lot à part, après la nuit. Porteur à désigner par
  le pilote.
- Une branche (`claude/revenus`) attribuait une définition de « séance payable » à « garde-cap, 07/11 » :
  ce texte n'a aucune autorité et n'est pas repris.

## Dette : scénarios cand_* rouges sur main (relevé du garde-cap, 08/11/2026 07:10 UTC ; corrigé 07:32)

**Quatre** fichiers distincts (et non cinq, erreur du garde-cap : `scenarios_cand_l2a1` et
`scenarios_cand_l2a1_moteur_salle_examen.sql` sont le même fichier) échouent sur `main` seul, hors CI (pas
nommés dans `ci.yml`) : `scenarios_cand_autres_competences`, `scenarios_cand_l1_socle`,
`scenarios_cand_l2a1_moteur_salle_examen` (ligne 347, « aucune RPC du lot ne double etat_dossier() ») et
`scenarios_cand_l3_inscription_import`.

**Cause unique prouvée par E** (PG17 local, main 7abbe4b8) : `public.com_ma_candidature()` (MESSAGES-CANDIDAT,
20261119400100, PR 304) est attrapée par le contrôle de nom `LIKE '%candidature%'` des quatre fichiers ; la
fonction ne rend que l'uuid de la candidature de l'appelant, aucun état : la règle « etat_dossier() seule
lecture de l'état » n'est pas enfreinte. Tests périmés. Correctif proposé (tests seuls : liste blanche et
assertion « rend un uuid, sans argument, ni anon ni service_role »), en attente du feu vert du pilote.

## Données personnelles : deux faits relevés par H, à présenter au directeur (garde-cap, 08/11/2026 07:20 UTC)

Ils existent avant PHOTO-CANDIDATURE-FIGEE (PR 357), qui ne les aggrave pas. Non tranchés par le garde-cap
(données personnelles) ; à présenter au directeur en une ligne chacun, au réveil.

1. **Un compte administrateur lit tout objet du seau `photos_enseignants`, hors de son genre** :
   la politique `photos_enseignants_lecture` ne filtre pas le genre, alors que la lecture du dossier de
   candidature (`lire_candidature`) le fait. Scénario d5 de la PR 357.
2. **DETTE PRIORITAIRE de confidentialité (relevée par H par rejeu local, 08/11 vers 07:15)** : un élève
   d'une classe d'un enseignant actif peut lire **tout** objet du dossier de cet enseignant dans le seau
   `photos_enseignants`, anciens fichiers compris, donc aussi la photo figée de sa candidature une fois la
   PR 357 installée. La faille est dans `main` (politique `photos_enseignants_lecture`, empreinte
   baf72997… identique avec et sans la PR 357). Correction : lot PHOTO-LECTURE-COURANTE (H, 20261121400000), un `ALTER POLICY`
   sans mot d'effacement, installé avant la PR 357 (arbitrage du pilote, 08/11 07:16 et 07:19).

## Dette : RECHERCHE D4 (encaissements du comptable) non branchée (relevé de H, 08/11/2026 ~07:34)

Aucune source serveur lisible par le comptable : `commandes_recharge` est en `REVOKE ALL` ; le serveur ne
stocke ni frais, ni net, ni rapprochement ; l'écran `/comptable/encaissements/:id` n'a aucune source
(CPT-BR-07). Il faut un adaptateur, une lecture serveur et une source des frais : lot à part (ARGENT : aucune
valeur ni règle inventée ; ce qui manque devient un réglage de l'administration). H ne branche que la part
« fils » du comptable, si elle tient sans impasse.

## Audit des 28 gardes Codex sans équivalent (E, lecture seule, PG17 local, main 7abbe4b8, 08/11/2026 ~07:43)

**Aucun fichier Codex ne s'applique tel quel** : certains remettraient `main` en arrière, d'autres échouent.

À décider par le directeur au réveil (argent et sécurité), en tête de liste après le quota Vercel :

1. **ÉLEVÉ, argent : `payouts` et `payout_methods`** : politique FOR ALL pour tout admin ou comptable valide en
   aal1, sans déclencheur de garde. Prouvé : INSERT d'un versement directement « paid » de 10 000 000, UPDATE
   du montant après paiement, retour « paid » vers « requested », DELETE, coordonnées « ATTACKER » posées pour
   n'importe quel tuteur. Aucun code ne paie depuis `payouts` aujourd'hui : faux enregistrements, pas de sortie
   d'argent automatique. Lot GARDE-VERSEMENTS (20261121600000), deux options.
2. **ÉLEVÉ, sécurité : compte désactivé** : `partie_concernee()` admet un admin ou contrôleur sans
   `app_account_valid()` ; un compte désactivé lit les coordonnées de prière des enseignants (latitude,
   longitude), leurs disponibilités, exceptions et affectations ; `custom_access_token_hook` ne lit pas
   `account_status` (les droits survivent au rafraîchissement du jeton). Lot GARDE-COMPTE-DESACTIVE
   (20261121500000).

Défaut fonctionnel : la frise des demandes de la famille est très probablement cassée
(`demande_evenements_foyer_v.survenu_le_foyer` en timestamptz, refusé par `frise_demandes_supabase.dart:121-127`) ;
correctif client confié à E (arbitrage du pilote).

Points FAIBLES, en dette :
- la clé `kyc_exception_super_admin` (f69) est modifiable par tout admin valide en aal1 ;
- `agent_pre_request` ne lit pas `access_until` (accès agent expiré) ;
- la branche famille d'`autoriser_ecoute_archive` n'a pas de test de rôle (un comptable avec un `household_id`) ;
- lectures x2_08 sans `app_account_valid()` ;
- plusieurs versions de programme peuvent être « publiee » à la fois ;
- injection de formule possible dans l'export CSV Wise (non prouvée de bout en bout) ;
- `purge_at` de `completer_kyc_document` non borné.

## Liste de suppression PROPOSÉE, en attente du directeur (relevé de A, main 57ad4e61, 08/11/2026 ~08:21)

Règle : **rien n'est supprimé sans l'accord du directeur sur cette liste précise.** Relevé en lecture seule des
24 lignes de `tool/branchement_tolere.txt` ; arbitrages du pilote (08:20) : #1 gardé, #18 + #1 branchés dans une
seule PR, #20 en alerte, rien supprimé.

Proposés à la suppression (le doublon réel est nommé ; l'importeur est seulement des tests ou la démonstration) :

| # | Fichier | Pourquoi | Ce qui fait déjà la chose |
| :--- | :--- | :--- | :--- |
| 2 | `core/capacites/acces_foyer_depuis_eleves.dart` | doublon (b) | `AccesFoyerSupabase` (main.dart) |
| 8 | `core/capacites/port_resume_seance_famille.dart` | doublon (b), toujours « indisponible » | la famille lit `compte_rendu_famille` (20261018190000) |
| 19 | `features/compte/soldes_foyer.dart` | doublon (b) | `SyntheseSoldesFoyer` |
| 3 | `core/capacites/avis_demonstration.dart` | démonstration (c) | `AvisSupabase` |
| 4 | `core/capacites/courriels_demonstration.dart` | démonstration (c) | `CourrielsSupabase` |
| 5 | `core/capacites/langues_communication_demonstration.dart` | démonstration (c) | `LanguesCommunicationSupabase` |
| 6 | `core/capacites/port_capacite_payout.dart` | sans adaptateur (c) ; lié à la dette GARDE-VERSEMENTS : à trancher avec elle | aucun |
| 7 | `core/capacites/port_preferences_persistantes.dart` | toujours « indisponible » (c) | aucun |
| 13 | `core/router/ecran_a_construire.dart` | 0 référence (c) | aucun |
| 14 | `core/tc_horloge/duree_academique.dart` | le serveur fait foi (`etat_presence`) (c) | `etat_presence` (0007) |
| 15 | `core/tc_observation/capacites_observateur.dart` | double de test (c) | aucun |
| 16 | `core/tc_realtime/transport_memoire.dart` | double de test (c), 4 tests l'importent : à déplacer sous `test/` plutôt qu'à supprimer ? | aucun |
| 17 | `core/widgets/child_card.dart` | ancienne carte (c) | cartes de `foyer_page` |

À **déplacer**, pas à supprimer : #9 `core/identite/matricule_demo.dart` (vers `lib/features/demo/`).

**ALERTE, non branché** : #20 `features/mon_espace_adulte/mon_espace_adulte_page.dart` : aucune source serveur
pour la ligne famille et la photo, et il double en partie `ComptePage` ; ~22 tests l'importent.

À brancher (a) : #1 + #18 (« Demander l'interface standard », RPC `demander_presentation_standard` de 0080,
jamais appelée) dans une seule PR ; #24 fait par la PR 364. Lignes de la recherche (#10-12, #21-23) : lots de H.
Constat de A : aucune de ces lignes ne sert « où en est l'élève / comment on le mesure » (VISION-ECOLE).

## Décision Codex non documentée : C-28 (relevé de E, 08/11/2026 ~08:25)

`20261011183000_c20_utc_instants.sql` (11/10, « C-20/C-28: expose instants UTC and keep the household IANA zone
separate ») a fait de `demande_evenements_foyer_v.survenu_le_foyer` un instant (timestamptz) et ajouté
`fuseau_iana`, **sans adapter le client Dart** : cause de la panne de la frise des demandes de la famille.
Aucune trace de C-28 dans `docs/current`. Correctif client : PR 363 (jour seul). Colonne additive
`survenu_le_murale` (20261121700000) en préparation, amélioration non urgente, rien installé cette nuit.

## Dette : scénarios qui dépendent de l'heure (relevé du garde-cap, 08/11/2026 08:25)

Trois défauts de la même famille cette nuit : `notifs_l6_test` (corrigé, PR 334), `scenarios_eleve_adulte`
(corrigé, PR 344), `scenarios_fn025_motif_refus_salle` (PR 367 : la création d'une classe active avec enseignant
génère ses séances, que les séances posées à `now()+…` chevauchent ; rouge sur toute PR à certaines heures).
**D'autres scénarios qui créent une classe active avec enseignant et posent des séances à `now()+…` peuvent avoir
le même défaut** : relevé à confier (rejeu sous horloge simulée, libfaketime, comme H l'a fait).

## Question au directeur : l'élève lit-il sa page de reprise et sa vitesse ? (pilote et garde-cap, 08/11/2026 10:40)

« L'élève peut-il lire lui-même sa page de reprise et sa vitesse (aujourd'hui réservées à l'équipe) : oui ou non ? »
Faits relus en production (lecture seule, 08/11 10:40 UTC) :
- `position_reprise_classe` n'est ouverte que par `private.cahier_c1_peut_lire_classe` (admin, ou enseignant
  titulaire, ou enseignant effectif d'une séance finie depuis moins d'un jour, toujours avec `app_account_valid`) ;
  aucune branche élève ni famille.
- `rythme_classe` n'existe pas en production (PR 373 non installée).
- `progression_famille(uuid, integer)` : md5 prosrc `cf739d37224c8f38b2290d6f18d0d072`, identique à
  `20261018190000_ped_cahier_partage.sql` ; la branche adulte (`p.id = v_user AND sp.titulaire_profile_id = v_user`)
  reste derrière `app_role() = 'guardian'` : un adulte dont le jeton porte `student` est refusé.
Rien n'est codé tant que le directeur n'a pas répondu. Le point 7 d'A (ligne de progression par
`progression_famille(soi)`, sans migration) ne s'appuie que sur l'existant.
