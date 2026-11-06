# Plan des lots et corrections aux règles, du garde-cap au pilote (02/11)

Ce que je ne sais pas, d'abord :
- Aucun parcours n'est « prouvé par le directeur » dans le dépôt : la colonne recette d'ETAT-OUVERTURE et le journal de PARCOURS-OUVERTURE sont vides.
- Quelle invitation a échoué le 01/11 : inconnu, non consigné.
- « Un bouton qui ouvre une session pour chaque personne » : la phrase n'apparaît nulle part dans le dépôt.
- Deux migrations sont en production d'après les commits de la PR 50, mais absentes de main : 20261024000000_cand_nom_latin et 20261024010000_cand_prevenir_par_courriel. L'écart dépôt / production n'est pas consigné.
- Installation distante des migrations du 02 au 04/11 : non vérifiée par les relevés, faute d'accès.

Sources :
- deux relevés en lecture seule sur main 58f6b7978 (annexes 1 et 2, envoyées juste après ce message) ;
- l'ordre du directeur de ce soir : « tu ne recrées pas la visio. tu branches celle qui existe partout où c'est nécessaire (entretien, studio, etc.) » ;
- son ordre précédent : « ne laisse pas les lots actuels ».

## 0. Règle nouvelle du directeur (02/11, ce soir) : aucune nouvelle visio

- La seule visio est `/salle`. Elle passe par create-room-token, `autoriser_jeton_video` et `session_participants.role` (teacher, student, guardian_observer, admin_masked, admin_visible).
- Un agent qui crée un nouveau module vidéo, un autre client LiveKit ou une autre page de visio est arrêté.
- Brancher une visio veut dire : un type de séance de plus, un rôle de participant, une garde dans `autoriser_jeton_video`, et un bouton qui ouvre `/salle` sur cette séance.
- **Précision du directeur (02/11, ce soir), pour l'entretien et la réunion du studio :** « les ressources de la salle ne sont pas nécessaires dans ces entretiens (pas de Coran, ni tableau blanc, encore moins de crayons, juste une visio normale qui permet l'interaction) ».
  - Pour une séance `entretien` ou `reunion`, `/salle` montre seulement : les vidéos, le micro, la caméra, le partage d'écran s'il existe déjà, et Quitter.
  - Elle ne montre pas : le Coran, le tableau, l'encre et les crayons, la bibliothèque, le chrono de cours, la présence, le cahier, ni la fiche de séance.
  - Le moyen : la portée des outils déjà branchée (`salle_seance/portee_outils_salle.dart`, `salle_page.dart:207`), lue depuis le type de séance. On n'écrit pas une seconde page.
  - R3 obligatoire : une capture de `/salle` en entretien, sans aucun de ces outils, sur téléphone et sur bureau.

## 1. Lots en cours, en tête (ne pas les lâcher)

| Lot | État | Suite |
|---|---|---|
| (A) PR 139 | Les 2 migrations sont en prod. Flutter (web) est encore en cours sur 9b032d64b, les autres vérifications sont vertes. | Tu fusionnes quand c'est vert. Si c'est rouge, je trouve la cause, je te la dis, puis je pousse. Ensuite, le directeur saisit les prix spéciaux et les accès offerts. |
| Agent « Fin de séance » | FN-115c, migration 20261105100000 | Puis **FN-109** (Bloquant, S : la paie envoie l'uuid composite `<enseignant>_2026-10-01`, même zone finance). Puis ONBOARDING-FIN avec le constat des consentements (« Suivant » actif, défilement jusqu'à la première case vide, case en rouge, phrase « il en manque une » retirée ; R3 téléphone et bureau). |
| PR 95 (B4, factures le 1er) | Elle attend la saisie des prix par le directeur. Sa migration 20261102600000 est antérieure d'environ 40 migrations à main. | Renuméroter en **20261105150000** avant de l'installer. Rejouer le scénario B4 après celui du lot A. |

## 2. Trois lots nouveaux, en parallèle des lots en cours (4 lots actifs au plus)

### Lot C1 : « Créer, clôturer, recréer une classe » (les blocages d'hier du directeur)

- **Zone :**
  - `lib/features/admin_groupes/**` ;
  - `lib/core/admin/creation_classe_refusee.dart` et `service_groupes.dart` ;
  - `lib/features/admin_groupes/refus_creation_classe_libelles.dart` ;
  - une migration.
- **Migration :** 20261105200000. 0 mot dangereux attendu, donc rien à coller par le directeur. Tu la poses.
- **Contenu :**
  1. **UX-003** : la feuille « Nouvelle classe » ouvre un seul créneau (`groupes_page.dart:1294`).
  2. **FN-103** : `cloturer_groupe` annule aussi les séances `planned` et `preflight` dont l'heure est passée et qui n'ont pas été lancées. Aujourd'hui, une classe close pendant sa séance garde l'enseignant bloqué par `sessions_no_teacher_overlap`. Le cas `in_progress` dépend de la décision D1 du §6. En attendant, on n'y touche pas.
  3. **UX-020** : le refus de chevauchement nomme la classe et l'heure en conflit (DETAIL côté SQL, affichage côté client). L'erreur 23P01 est rattachée à ce message, au lieu de la phrase générique (`creation_classe_refusee.dart:95-109`).
  4. **UX-019** : plus de message brut « P0001 » (`groupes_page.dart:1994-1998`).
  5. **UX-031** : Échap demande une confirmation avant de perdre la saisie. **UX-030** : la ville en clair au lieu du code IANA.
- **R3 attendu (banc local, E2E) :**
  - créer une classe avec un seul créneau ;
  - clôturer une classe pendant l'heure de sa séance, puis recréer une classe au même horaire avec le même enseignant : acceptée ;
  - un refus de chevauchement qui nomme la classe.
  - Captures téléphone et bureau sous `docs/current/captures/E2E/c1-classes/`.

### Lot I1 : « Inviter quelqu'un »

- **Zone :**
  - `lib/features/admin_invitations/**` ;
  - le chemin `invitation=1` de `lib/features/inscription/inscription_page.dart` ;
  - `supabase/functions/_shared/courriel/modeles*.ts` ;
  - la carte « Invitations à envoyer » de `lib/features/admin_import_inscriptions/import_inscriptions_page.dart:1071-1091` ;
  - la RPC `inviter_enseignant` ;
  - une nouvelle RPC d'envoi aux familles importées.
- **Migration :** 20261105300000. Le modèle d'e-mail change une fonction Edge : qui la déploie en prod, toi ou le directeur ? À dire dans le lot.
- **Contenu :**
  1. `inviter_enseignant` met en file un e-mail avec le code et le lien. Le texte « il n'est pas envoyé automatiquement » disparaît.
  2. **UX-015** : « Invitations » dans les sections de Personnes.
  3. **UX-016** : le code est normalisé (minuscules, espaces) côté RPC.
  4. **UX-013/017** : le code et `invitation=1` survivent au lien d'e-mail et au rechargement.
  5. **UX-018** : un lien déjà utilisé est expliqué.
  6. Familles importées : un bouton « Envoyer l'invitation » par foyer et un bouton « Envoyer à toutes ». Rien ne part tout seul (décision D2 du §6). Le lot code ces boutons maintenant. Seul l'envoi à toutes attend la réponse.
- **R3 attendu :**
  - la ligne `courriels_sortants` créée sur le banc pour un enseignant et pour un foyer importé ;
  - le parcours invitation enseignant, avec un rechargement au milieu, jusqu'au compte créé.

### Lot N1 : « Le code fait mais pas branché », priorité haute

Tout le code nécessaire existe déjà. Il manque un adaptateur ou une route.

- **Zone :**
  - `lib/core/communications/**` ;
  - `lib/features/com_messages/**` et `com_annonces/**` ;
  - `lib/core/alertes/**` et `lib/features/alertes/**` ;
  - une migration de capacités.
- **Migration :** 20261105400000.
- **Contenu, dans cet ordre :**
  1. **Écrire un message est impossible pour tous les rôles, et aucune annonce ne peut être publiée** (`capacites_communication.dart:113`, jamais surchargé). Le lot écrit une fonction SQL de capacités par rôle et par objet, plus l'adaptateur et la surcharge dans `main.dart`. `com_envoyer_message` reste la barrière (M).
  2. **D7, annonce d'académie** : `ReglesAudienceIndisponibles` → un adaptateur (M).
  3. **D1, signalements des enseignants, y compris la sécurité d'un enfant** : personne ne les lit. Le lot écrit un adaptateur des « Alertes urgentes » sur `signalements_ouverts_direction()`, qui existe et n'est jamais appelée (M).
- **R3 attendu :**
  - un tuteur et un enseignant écrivent dans un fil ;
  - la direction publie une annonce ;
  - un signalement déposé par un enseignant apparaît dans les alertes de la direction.

## 3. Suite, dans cet ordre, quand un lot se libère

1. **N2, foyer et élève adulte (le code est fait, il manque les routes) :**
   - E1 « Ma classe » de l'élève adulte : une route, recommandée sous « Apprendre ». L'adaptateur est déjà surchargé.
   - FA5 « Créer mon profil élève » : l'écran affiche « indisponible » **en dur** dans `app_router.dart:1007-1013`, alors que l'adaptateur est surchargé.
   - FA1-FA3, le second adulte du foyer :
     - inviter : le port est déjà surchargé ;
     - invitation reçue : adaptateur sur `mon_invitation_en_cours` et `repondre_invitation_conjoint` (0053) ;
     - reprise : `deposer_reprise_foyer`, `etat_reprise_foyer`, `refuser_reprise_foyer` (0098/0099).
   - Taille M chacun. Aucune migration.
2. **N3, enseignant et contrôleur :**
   - S2 pause programmée : adaptateur sur les 5 `pause_*` (contrat `CONTRAT_PORT_PAUSE_SEANCE.md`) ;
   - D3 mission du contrôleur : adaptateur sur `ma_mission_controle` et `demarrer_mission_controle`. L'envoi du compte rendu n'a pas de fonction : SQL à écrire ;
   - EN1 photo publique de l'enseignant : seau `photos_enseignants`. Vérifier la RLS de `photo_storage_key`.
   - Migration 20261105500000 si nécessaire.
3. **V1, visio d'entretien, partie serveur (règle §0) :**
   - `session_type` accepte `entretien` et `reunion` ;
   - les deux sont exclus de la paie, de la présence, de la clôture et des vues de classe ;
   - nouvelles RPC `planifier_entretien`, `consigner_entretien` et `mes_entretiens`, réservées à la direction (CAND-Q19) ;
   - le candidat convoqué devient participant, même avec un compte `pending_kyc`, et `autoriser_jeton_video` l'admet seulement pour sa séance ;
   - cloisonnement femmes / hommes ; rien d'enregistré (CAND-Q09) ;
   - les capacités `planifierEntretien` et `consignerEntretien` deviennent vraies (aujourd'hui `false`, `cand_l2a2:1611`).
   - Migration 20261105600000. Garde dans create-room-token.
   - R3 : un scénario SQL, puis un jeton refusé à un autre candidat.
4. **V2, visio d'entretien, partie écrans :**
   - fiche candidature direction (ADM-21) : « Planifier l'entretien » ;
   - `/attente` du candidat (CAND-02) : « Rejoindre l'entretien », qui ouvre `/salle` en visio simple, sans les outils de cours (§0) ;
   - compte rendu ADM-21R ;
   - **studio** `/admin/studio` (D6) : il n'a aucune visio aujourd'hui. On ajoute « Réunion » / « Rejoindre », qui ouvre `/salle` sur une séance `reunion` de la direction.
   - Autres usages de la salle existante à brancher : la mission du contrôleur, qui entre en `admin_masked` (déjà prévu par 0031/0033), et l'observation par le tuteur, FA9, coupée par `env.dart:74-112` (décision D9).
5. **Salle 3 :** valider la pièce fait passer la candidature à `confirmee` dans la même transaction (spec §2.2). Aujourd'hui `validerPiece` est faux et `decider_dossier` ne touche pas `candidatures`. Taille M.
6. **B3.3, les 568 candidats :**
   - porter depuis la PR 50 l'import ADM-23, la liste, la sélection, la marque « retenu » et « Prévenir » limité aux retenus, sur les listes de main ;
   - **versionner sur main les 2 migrations déjà en prod**, avec leurs numéros d'origine, après vérification dans `supabase_migrations` ;
   - puis fermer la PR 50. Taille L. Dépend de D4.
7. **FN-006** (Bloquant, aucun code) : à la fin plus la grâce, Aujourd'hui montre la séance suivante, et « Quitter et ouvrir le cahier » clôt la précédente. Taille M.
8. **B2.3** séance tenue sur Meet (décision D5), puis **B2.4** tableau de la direction (décision D6). A3-bis après le oui du directeur (ma tâche : pas d'écartement sans remplaçant prêt, e-mail à la direction à T+3, seuil pour une séance créée tard).
9. **Hors boucles, sur ordre seulement :**
   - S1 Bibliothèque pour les non-direction (L) ;
   - R1 coffre R2 de la pièce d'identité (secrets R2 inconnus) ;
   - finance comptable F1-F8 ;
   - recherche D2 ;
   - Communauté ;
   - noms de classe automatiques (la liste est à faire valider).

**Captures des trois salles, à faire dès maintenant :** ce n'est pas une construction, un petit modèle suffit. Le directeur les demande depuis longtemps et ne les a jamais vues.
- Ce qui existe déjà : CAND-01 `/attente/candidature`, ADM-20 liste, ADM-21 fiche, sur le banc local.
- Où les mettre : `docs/current/captures/E2E/trois-salles/`, une page par salle.
- Les manques à dire en face de chaque salle : salle 2 sans entretien, salle 3 non reliée.

**À ne pas brancher, ce sont des doublons d'un module branché (le dire au directeur, ne rien supprimer) :**
- `salle_seance/signalement_seance.dart` ;
- `tc_dock/*` ;
- `tc_flux_academique/*` et `tc_parcours/{port_post_cours,post_cours_vm,feedback_memoire,rotation_feedback}` ;
- `tc_catalogue/support_actif/*` et `class_library_picker` ;
- `providers_tc_etat_partage` et `TransportIndisponible` ;
- `port_resume_seance_famille` ;
- `port_demandes_horaires` ;
- `port_catalogue_classes` ;
- `offresClassesProvider` dans Créneaux (contraire à DECISION-OFFRES) ;
- `soldes_foyer`.

L'inventaire du 31/10 est périmé sur trois points, déjà branchés : la séance en arrière-plan, la portée des outils et la réaffectation / le remplaçant.

## 4. Corrections à DECISION-QUATRE-AGENTS

1. **Format :** `dart format` seulement sur les fichiers touchés. Un `dart format lib test` reformate 177 fichiers.
2. **Garde-fous des textes avant la PR :**
   - `flutter test --no-pub test/garde test/core/i18n test/tool/garde_fous_test.dart` ;
   - espaces insécables avant « : » et dans « » ;
   - élision avec `{dePrenom}` / `deDevant` ;
   - erreurs qui disent quoi faire (`erreur-sans-action`) ;
   - durées avec `LibellesGroupe.insecable`.
3. **Suite complète :** environ 55 minutes. `--no-pub`, une longue attente, et vérifier l'espace disque avant.
4. **E2E jamais sur un aperçu Vercel :** les aperçus parlent à la base de production. Le banc local seulement.
5. **Le garde refuse tout Bash qui contient l'identifiant de prod.** Écrire ces fichiers avec l'outil Write.
6. **Numéro de migration :** vérifier main **et** les branches ouvertes (collision NOTIFS-L6 / lot A). Plage réservée ci-dessus : 2026110510/15/20/30/40/50/60 0000.
7. **Avec le directeur :** toujours en français, mots simples, la vérité d'abord.
8. **Page à coller :** une seule page, faite par toi seul. J'en ai fait une en double pour le lot A ; ne plus le faire.
9. **Sur le banc, une facture émise ne s'efface pas** (`fac_facture_figee`) : on l'annule.
10. **Pas de visio nouvelle** (§0).
11. **`app_router.dart` est un fichier partagé.** Un lot ajoute ses routes dans son propre `routes_*.dart` et ne touche le routeur que d'une ligne d'inclusion. Sinon, conflits garantis entre les lots en parallèle.
12. **Avant d'écrire, chaque lot lit l'annexe 1** (relevé non branché, avec sa liste de doublons). Son bilan dit ce qu'il a réutilisé.
13. **Registre :**
    - ajouter FN-113 dans UX-CONSTATS ;
    - mettre à jour FN-028, UX-025, UX-044 et UX-045, codés mais notés « ouverts », en « codé, preuve du directeur à faire », et non en « fermé ».

## 5. Mon rôle

- Je relis ton plan avant le lancement, puis chaque PR à ta demande.
- Je ne construis rien, ne fusionne rien et ne migre rien. Exception : la PR 139 si sa CI est rouge, après t'avoir dit la cause.

## 6. Décisions à demander au directeur, une ligne chacune, avec ma recommandation

- D1. Clôturer une classe pendant sa séance en cours : on arrête la séance (tout le monde sort) ou on la laisse finir ? *Reco : la laisser finir. Les séances non lancées sont annulées de toute façon (C1).*
- D2. Familles déjà inscrites et importées : l'e-mail d'accueil part par un bouton (une famille ou toutes), jamais tout seul ? *Reco : oui.*
- D3. Le 01/11, vous vouliez inviter qui : un enseignant, une famille déjà inscrite ou un candidat ?
- D4. Pour les 568 : seuls les retenus reçoivent un lien à leur nom, et l'inscription publique des enseignants reste fermée ? *Reco : oui.*
- D5. Une séance « tenue sur Meet » est-elle payée à l'enseignant comme une séance dans l'application ?
- D6. « À jour de paiement » veut dire accès payé du mois (Stripe ou accès offert), et non plus une marque à la main ? *Reco : oui.*
- D7. « Un bouton qui ouvre une session pour chaque personne », c'est l'entretien de chaque candidat dans la salle existante ? *Reco : oui, lot V2.*
- D8. Les noms des trois salles (examen ; vérification et entretien ; prêts à enseigner) sont-ils validés ?
- D9. Le tuteur peut-il observer une séance en direct (le code existe, il est coupé en production) ?
- A3-bis : oui ou non (en attente).

## 7. Ordre unique de la file (garde-cap et pilote, 03/11/2026, 00:51 UTC)

Remplace tout ordre antérieur. Chaque agent libéré prend le premier lot de la liste dont la zone est libre.
Numéros de migration : table des réservations du garde-cap (2026110510 à 2026110650).

| # | Lot | Taille | Condition |
|---|---|---|---|
| 1 | TXT-1 : « Messages métier », « francais » brut, « État inconnu » (UX-001, 005, 012) | S | en cours |
| 2 | RECHARGE-1 : écran « hors ligne » qui ne revient jamais, « Réessayer » sans effet ; morceaux différés d'une ancienne version ; inventaire de tous les « Réessayer » ; FN-013 rattaché (directeur, 03/11) | S/M | en cours, C1, `claude/recharge-1` |
| 3 | SNT : séance non tenue à T+30, report et rattrapage (directeur, 03/11) | M | après la fusion d'A3-bis |
| 4 | D1-bis : traiter un signalement (examiner, transmettre, clore) | M | |
| 5 | D1-ter : la famille lit ce qui lui est transmis (carte dans la fiche de l'enfant, plus une notification) ; `concern_famille_v` n'est lue par aucun écran aujourd'hui. Emplacement « proposé » : l'Historique de la fiche de l'enfant (SM-51), modifiable ; jamais de résumé pour la sécurité d'un enfant | S/M | après D1-bis, zone foyer, à coordonner avec N2 |
| 6 | N2 : foyer et élève adulte (E1, FA5, FA1-FA3), puis NIV1 (niveau demandé une fois, UX-032), même agent | M + M | |
| 7 | ADM-UX (UX-006, 007, 014) | S | |
| 7 bis | DEFIL-FEUILLE : une boîte ou une feuille trop haute devient l'écran, une seule barre de défilement (fiche §10 ; constat de C1 au rejeu du 03/11) | S/M | prochain agent libre ; suite complète (lib/core) |
| 7 ter | RECHARGE-CARTE : pendant une commande en attente de paiement, la carte du profil affiche « 0 $ » alors que le récapitulatif du serveur dit 55 $ (`lib/features/foyer/recharge_foyer.dart:869`). La carte garde en lecture seule le montant retenu par le serveur, sans calcul côté Flutter. Constat du rejeu du 03/11, parcours 7 | S | premier agent libre après DEFIL-FEUILLE ; sans migration ; R3 : carte et récapitulatif concordants, 390 et 1440 |
| 7 quater | PHOTOS-1 : une seule photo par personne, tous les rôles (serveur) (fiche §11, demande du directeur du 03/11) | M | premier agent libre après RECHARGE-CARTE ; migration 20261107300000 |
| 7 quinquies | PHOTOS-2a : le fournisseur unique, l'envoi pour chaque rôle, la fermeture du droit client de 0005 sur `avatar_storage_key` (migration 20261107900000), les écrans de la preuve (tuteur, appareil de l'enfant, enseignant, camarade, direction) (fiche §11) | M-L | après PHOTOS-1 (en production) |
| 7 sexies | PHOTOS-2b : le reste des écrans (cahier, cartes, espace de classe, messages, communauté), plus deux défauts relevés en R3 : la vignette du camarade nommée « Participant » en salle, et le Compte de l'enfant qui affiche « Élève » au lieu de son prénom | M | après PHOTOS-2a |
| 7 septies | DEFIL-FEUILLE-bis : « Signaler un besoin » défile encore dans une boîte à 1440 (forme dialogue) ; R3 sur « Signaler un besoin » et les deux écrans de la PR 177 | S | Fin de séance |
| 7 bis-a | ADM-UX-bis : Échap ne fermait plus la boîte de Personnes > Demandes après « Accepter » (focus perdu quand le bouton disparaît) ; focus sur la phrase « … est acceptée » (constat du rejeu du 03/11) | S | C1, PR 179 ; sans migration |
| 8 | N3 : pause programmée, mission du contrôleur (la photo de l'enseignant passe dans PHOTOS, 03/11) | M | C1, migration 20261107800000 (renumérotée : toute migration nouvelle prend un numéro au-dessus de la dernière installée) |
| 9 | CAHIER-UX (UX-028, 041 ; UX-029 vérifié d'abord en lecture) | S | |
| 10 | N4 : Bibliothèque, coffre R2 de la pièce, publication des évaluations, interface standard, Interface guidée | L | r2-selftest lu avant |
| 11 | FN-SERVEUR (FN-106 et 107 d'abord, puis FN-003, 019, 104) | M | |
| 12 | Double vérification à la publication de la politique commerciale (aal2) | M | après REMB-14 |
| 13 | A11Y-1 (UX-004, 010, 021, 027) | S/M | |
| 14 | Captures des trois salles (noms côté candidat du 02/11) | S | |
| 15 | SALLE-UX (UX-011, 033, 034, 038 à 040, 042, 043) | M | après O1 |
| 16 | FOYER-UX (UX-009, 023, 024), plus le numéro de version en bas du Profil (directeur, 03/11, registre 08) | S/M | après N2 et NIV1 |
| 17 | M1 : liste des doublons (PR 184), « oui » du directeur le 03/11 (registre 08) ; puis M1-SUPPR (`lib/` : 7 cas de protection des enfants portés sur « Signaler un besoin » d'abord, puis 13 fichiers et leurs tests retirés, B1 et B2 gardés) et M1-A8 (serveur du support actif retiré seulement sans autre lecteur, B5 20261107600000 collé par le directeur) | S, puis M + S | N1 ; file `lib/` pour M1-SUPPR |
| 18 | COURRIELS-UX (UX-026, FN-108) | M | après A3-bis et SNT |
| 19 | Scénarios SQL rouges (FN-004, 005, 020, 021, bf1_finance_backend ; `scenarios_af_liste_blanche_volatiles.sql`, rouge sur main pour `accorder_tarif_particulier`, `ajouter_creneau_classe_admin`, `remboursement_confirmer`, `seance_a_rejoindre`, plus les 3 lignes de D1-bis) ; `test/features/finance_recette/recette_fi_test.dart:1871` rouge dans un clone peu profond (`git merge-base` sur 65cf51d2), à faire sauter aussi quand `git rev-parse --is-shallow-repository` vaut true (CI verte, pas un rouge de main) ; `scenarios_fn115c_rembourser.sql` dépendait de l'heure le mardi (corrigé dans la PR 172) | M | |
| 20 | V1 puis V2 : entretien et réunion dans `/salle`, sans les outils de cours | L + L | |
| 21 | FN-DIVERS, un point par lot : FN-102, FN-101, FN-018, puis FN-111, FN-027 (FN-013 rattaché à RECHARGE-1) | S, puis M | |
| 22 | **Arbitrage du garde-cap, 05/11/2026 vers 22:40 UTC, sur demandes du directeur du même soir.** Ces lots passent avant les rangs restants de la file (9, 13, 15, 16, 21), après le train photos, dans l'ordre 22 0, 22 a, 22 b | | |
| 22 0 | ENTREE-ORDRE (régression d'une règle du directeur, en tête des nouveaux lots) : **pour un nouveau profil, le questionnaire vient avant l'adresse e-mail et la connexion**. Constat en production (build 574, 05/11 22:50 UTC) : l'application ouvre sur « Se connecter » (champ e-mail d'abord), et les boutons « S'inscrire » et « Commencer mon inscription » du site mènent à `/connexion`, donc au même écran ; le questionnaire (`/#/commencer`, « Pour qui créez-vous ce compte ? », 10 étapes puis « Dernière étape : votre accès ») n'est atteint que par l'onglet « Créer un compte ». Le directeur dit que l'ordre était bon avant la dernière refonte de l'entrée (CONNEXION-UX, fbbdced4, 04/11, à confirmer par l'agent dans l'historique). Exige : un visiteur sans compte connu sur l'appareil arrive sur le questionnaire ; « J'ai déjà un compte » mène à la connexion ; un lien de connexion reçu par e-mail et l'adresse `/connexion` tapée par quelqu'un qui revient gardent la connexion. Les boutons du site sont dans la zone du directeur : leur cible ne change que si l'application seule ne suffit pas, et alors par un geste du directeur | S/M | premier agent libre après le train photos ; `lib/core/router` et `lib/features/connexion` ; R3 : nouveau visiteur, visiteur qui revient, lien reçu, **un tuteur qui inscrit deux enfants dans le questionnaire avant l'e-mail** (le moyen existe : « Vous pourrez inscrire d'autres enfants à la fin », puis « Ajouter un autre profil élève » au récapitulatif, 6 apprenants au plus, `recapitulatif_etape.dart:305-345` ; arbitrage du garde-cap du 05/11 : on le garde, le tuteur n'attend pas les Réglages ; jamais prouvé en production), 390 et 1440, FR et AR |
| 22 a | PREFERENCES-WEB : (1) **le thème choisi est mémorisé** : aujourd'hui, au rechargement, l'application revient à « Système ». Cause lue sur main 7ee028f7 : `stockagePreferencesProvider` (`lib/core/preferences/preferences_locales.dart:267-272`) prend `StockagePreferencesMemoire()` sur le web, perdue à chaque rechargement. « Système » reste le défaut ; un autre choix est gardé sur l'appareil (stockage du navigateur). (2) **lot LANGUES : le choix de la langue de l'application**. L'arabe existe (`assets/i18n/ar.i18n.json`), mais la langue suit seulement celle de l'appareil (`lib/core/i18n/langue_demarrage.dart`) : en production, rien ne permet de passer en arabe. Un choix « Système / Français / العربية » dans les Réglages, mémorisé par le même stockage. Mots : skill `mots-rewayah` ; aucune autre langue ajoutée dans ce lot. **Règle de performance (directeur, 05/11 au soir)** : l'application ne charge que la langue de la personne. Constat sur le build 574 : le français (langue de base, toujours chargée) est dans `main.dart.js`, l'arabe dans un morceau différé (`main.dart.js_1.part.js`), donc déjà chargé à la demande. À garder : chaque langue ajoutée plus tard (anglais, espagnol, portugais, K-41) reste un morceau différé ; la langue mémorisée est chargée avant le premier écran, sans passer par une autre ; la police arabe n'est chargée qu'en arabe. Preuve : taille de `main.dart.js` avant et après, et requêtes réseau d'une ouverture en français (aucun morceau d'une autre langue) | M | un seul agent, zone `lib/core/preferences` et `lib/core/i18n` ; sans migration ; si une dépendance nouvelle est nécessaire, `pubspec.yaml` est un geste du directeur (préférer `dart:js_interop`) ; R3 : choix, rechargement, choix gardé, 390 et 1440, FR et AR |
| 22 b | FINITION : libellé « Connecter l'appareil d'un élève » sur 2 lignes à 1280 (page de connexion) ; « cette Classe » majuscule (1440 FR) ; note du planning mal placée (1440 AR) ; DRAPEAUX-bis : nom du pays dans la langue de l'écran ; nom de l'académie en arabe : l'application écrit encore « أكاديمية رواية » à 9 endroits de `assets/i18n/ar.i18n.json`, alors que le registre de marque M-27 (20/10) décide « أكاديمية الرواية » ; page de la Classe de l'enseignant au téléphone : une barre de défilement intérieure semble visible à droite (capture PHOTOS-SYNC 14, 06/11), à vérifier contre `DECISION-DEFILEMENT-2026-11-01.md` ; compteur du questionnaire incohérent (« 1 sur 6 » à « Pour qui », puis « 2 sur 10 » après « J'inscris mon enfant », vu en production le 05/11) | S | après 22 a, ou en parallèle si les zones sont libres |
| 22 c | SITE-LANGUES : le site public dans les langues de K-41 (français, arabe, anglais, espagnol, portugais), dans cet ordre : arabe, anglais, puis espagnol et portugais. Demandé par le directeur le 05/11 au soir, confié à la session du site public (`session_0163KjrxSa9pANwwSgjNENEv`), hors de la file des agents de l'application. Aujourd'hui, `rewayahacademy.com/ar/` (et /en/, /es/, /pt/) renvoie vers la connexion de l'application. Aucune langue de plus pour l'instant (arbitrage du garde-cap) | L | zone du directeur (`site-public/`) ; consignes envoyées le 05/11 |
| 22 d | ETUDE-CAHIER (étude seule, aucun code ; **faite le 05/11, PR 243**) : revoir la stratégie du cahier de l'enseignant d'après `VISION-ECOLE-2026-11-05.md` §3 à §5. Références du marché, soulager l'enseignant, suivi de l'avancement pour les familles, la direction et l'enseignant. Lancée le 05/11 au soir dans une session d'étude dédiée. Ses conclusions deviennent un lot, arbitré par le garde-cap ; le directeur reçoit une synthèse simple | M | aucune modification du cahier avant les conclusions |
| 22 e | CAHIER-C1, position automatique (`ETUDE-CAHIER-2026-11.md` §5, PR 243) : la salle enregistre au serveur la dernière page présentée par classe ; la préparation de séance la lit (aujourd'hui `preparationSeanceProvider` rend toujours null, `lib/features/fiche_groupe/preparation_seance.dart:71`) ; le remplaçant voit « On reprend page X » | M | **premier lot après le train photos, en parallèle d'ENTREE-ORDRE** (zones séparées : salle et fiche_groupe, contre router et connexion) ; arbitrage du garde-cap du 05/11, la vision fait du suivi pédagogique la priorité n° 1 |
| 22 f | CAHIER-C2 à C8 (programme en données, cahier de confirmation en moins de 20 s, indicateurs au serveur, vues direction, famille et élève, examen proposé, emploi du temps de révision), dans l'ordre de l'étude | L | **réponses reçues le 05/11 (registre 08)** : paie libérée par la confirmation, objectifs rédigés par un agent puis validés par le directeur, livre pas encore numéroté ; confirmation après chaque séance (remplace l'hebdomadaire) ; le gel K-45 est levé |
| 22 g | ACCUEIL-HORAIRE (constat du directeur du 05/11, capture) : à l'Accueil du tuteur, la carte « Horaire à choisir » de l'enfant sans classe mène à « Aucun horaire ouvert ne correspond encore » ; revenu à l'Accueil, la carte ne disparaît jamais, et une seconde carte « Aucune classe pour Hakim » dit la même chose. Exige : une seule carte ; si aucun horaire ouvert ne correspond, elle le dit sans envoyer vers une impasse ; une fois « Me prévenir si de nouveaux horaires ouvrent » touché, elle passe à l'état « Demande enregistrée : nous vous prévenons dès qu'un horaire ouvre » (`DECISION-OFFRES-GROUPES-2026-10-09.md` : suivi de la famille à chaque étape) ; elle disparaît quand l'enfant a une classe | S | même agent qu'ENTREE-ORDRE ou le suivant ; R3 390 et 1440, FR et AR : avant la demande, après la demande, retour à l'Accueil |
| 22 h | FINANCE-ENSEIGNANT (directeur, 05/11 : « finir toute la finance, les infos bancaires de l'enseignant, où les renseigner ») : les paiements de l'enseignant sont branchés ; les coordonnées de versement ne le sont pas. Constat sur main : l'écran « Recevoir mes paiements » existe (`lib/features/paiements_recus/`), mais `portMesMoyensPaiementProvider` n'a que `MesMoyensPaiementIndisponibles` en production et une version de démonstration ; aucun adaptateur serveur. Règle déjà écrite dans ce port : **la saisie des coordonnées se fait chez le prestataire, jamais conservée par l'app** (seul un jeton). Le lot : inventaire de ce qui existe (écran, ports `port_payout`, `port_beneficiaires_paiement`, tables), choix du prestataire de versement selon les pays des enseignants (A12 : solution toute prête, par exemple Stripe Connect), branchement de bout en bout, vue du comptable. Le choix du prestataire et ses frais sont une seule question au directeur, avec la recommandation chiffrée | M-L | après le train photos ; zone finance ; aucune coordonnée bancaire dans la base ni les journaux |
| 22 i | COULEUR-PROFIL (directeur, 05/11 : « active aussi les couleurs de profil, l'écran existe mais pas branché ») : l'écran existe (`lib/features/foyer/fiche/couleur_page.dart`, `selecteur_couleur_profil.dart`), mais `portAccentsProfilsProvider` n'a en production que `AccentsProfilsIndisponibles` (« Pas encore disponible ») : **aucune source serveur** (`port_accents_profils.dart` l. 4 : « la colonne arrive en BR-1 », jamais faite). Le lot : une colonne de clé d'accent par profil (jamais une couleur libre, K-62), écrite par le tuteur pour les profils de son foyer et par l'adulte pour le sien, lue par les écrans qui l'utilisent déjà ; l'adaptateur Supabase ; migration au numéro suivant de la table du garde-cap | S/M | après le train photos ; R3 : le tuteur choisit une couleur, la voit à l'Accueil, au Foyer et sur l'appareil de l'enfant, sans recharger, 390 et 1440 |
| 22 j | **REVENUS-VERITE, priorité haute** (directeur, 06/11, capture du Profil de l'enseignant, « Revenus estimés ») : l'écran affiche des règles de paie **fausses**, venues du modèle du 17/10 abandonné le 18-19/10 : « 1. Base garantie : 4,71 $ par heure assurée, quelle que soit l'occupation de la Classe », « 2. Composante d'occupation : un élève financé absent compte, une absence ne vous fait rien perdre », « 3. Plafond horaire », et « Sièges éligibles : élèves financés, présents ou absents » (`assets/i18n/fr.i18n.json` `revenus.*` l. 8259-8310, et l'arabe). La règle en vigueur (`DECISION-TARIFS-2026-10-18.md`, 19/10, redite le 06/11) : **l'enseignant est payé par séance, par élève présent et par heure (1,99 $ enfant, 1,57 $ adulte, 47 % du prix) ; un élève absent n'est jamais payé ; aucun montant minimum garanti** ; le serveur calcule déjà ainsi (`private.pai_due_seance`, migrations `20261018130000` et `20261102300000`) : c'est l'écran qui ment. Exige : (1) retirer base garantie, composante d'occupation, plafond et « sièges éligibles », dire la vraie règle en une phrase ; (2) un titre clair et le **total des heures assurées** du mois ; (3) **ce qu'a rapporté chaque élève après chaque séance** (séance, élève présent ou absent, durée, montant), lu au serveur ; (4) le **jour de paie**, en fenêtre large pour absorber les imprévus : arbitrage du garde-cap, réglage `paie.fenetre_versement` par défaut **du 1er au 10 du mois suivant** (le 18/10 disait « avant le 5 ») ; (5) une partie **« Autres revenus »** : l'aide Internet (existe) et les **primes ou missions** que la direction attribue à un enseignant, avec libellé et montant, payables à la fin du mois. Le (5) demande une table et un écran de la direction (aucun support serveur aujourd'hui) ; le reste est surtout de l'affichage. **Point (1) fait** (C1, 9e9e9e27, 06/11). Restent aussi, relevés par C1 : `mes_revenus_enseignant` rend encore `base`, `plafond` et des `siegesEligibles` qui comptent les absents (non affichés, montants justes car lus de `pai_due_seance`), à retirer du serveur et du modèle Flutter avec les points 2 à 5 ; et l'écran des revenus en arabe reste presque tout en français (39 clés figées dans `tool/ar_socle_non_traduites.txt`), à traduire dans le même lot. **(6), relevé par le garde-cap en production le 06/11 (build 582)** : la page de la direction « Politique commerciale », section « Rémunération des enseignants », décrit encore le modèle abandonné (`fr.i18n.json` l. 5450-5458 « entre une base garantie et un plafond », « Base horaire garantie », « un élève financé absent compte toujours », et l'aperçu l. 5558-5567 « Sièges éligibles … même si l'élève est absent », « Base garantie », « Plafond ») : à aligner sur la règle par élève présent (taux enfant et adulte), avec les mêmes textes que l'écran de l'enseignant | S puis M | (1) à (4) d'abord, **juste après le train photos, en parallèle de C1 et ENTREE-ORDRE** ; (5) ensuite ; migration au numéro suivant de la table du garde-cap ; R3 : Profil de l'enseignant, 390 et 1440, FR et AR, avec un élève présent et un absent |
| 22 k | **CANDIDATS-FLUX, échéance datée** (demande du directeur du 06/11, transmise par le garde-cap sortant ; arbitrage du garde-cap successeur, 06/11 vers 10:00 UTC). Constat : plus de 1 000 réponses aux deux formulaires Google, qui restent ouverts alors que `CAND-Q17` (21/10) décidait qu'après un import unique les candidatures arrivent par le lien public de l'application. Les envois « par lots, à la main » étaient des pages de collage SQL : 656 messages d'attente partis par la file de l'application du 25 au 29/10 (653 adresses, 0 échec, 2 désinscrits, relevé en production le 06/11). Ce message promet « d'ici trois semaines […] un courriel personnel, dans tous les cas » : **échéance du 15/11**. En production : 0 réponse importée ; l'import (ADM-23), « Prévenir par e-mail » et l'inscription candidat sans code (CAND-04) n'existent que sur la PR 50 (serveur déjà installé) ; la file n'a aucun plafond par jour (lots de 20 chaque minute) ; DKIM posé, DMARC en `p=none`, SPF correct. **Pistes du directeur, jugées** : (1) « tout le monde d'un coup à l'ouverture » : attendre casse la promesse du 15/11, et 1 000 envois en une heure depuis Workspace exposent au dossier indésirable ; on garde son idée d'écrire à tous, anciens compris, car l'invitation est un message nouveau (S3 respectée), mais étalée. (2) « script Google Sheets à chaque inscription » : **refusée comme outil d'envoi**. Il enverrait depuis le compte du directeur, hors de la file : il ignore les 2 désinscrits (envoi illégal après désinscription), ne sait pas qui a déjà reçu quoi (S3), n'écrit pas dans la langue du candidat, ne laisse aucune trace dans l'application, et refait ce qui existe (D6, A12). Il garderait aussi le formulaire comme porte d'entrée, contre `CAND-Q17`. **Exige, un seul lot** : (a) porter de la PR 50, sans réécrire, l'inscription candidat sans code (CAND-04, avec courriel confirmé et le contrôle ANTI-ROBOT du §13), l'import des deux formulaires (ADM-23, rejouable sans doublon) et « Prévenir par e-mail » ; (b) un réglage de la direction `courriels.non_essentiels_par_jour` (proposé : 300, modifiable, A5) : la file étale d'elle-même tout envoi non essentiel sur les jours suivants, et ne retarde jamais un message essentiel ; (c) une invitation par adresse, jamais deux (clé `lien_inscription:<adresse>`), désinscrits exclus, dans la langue du candidat (règles du modèle `lien_inscription`, `DECISION-CANDIDATURES-2026-10-21.md` l. 156-178) ; (d) une fois le lien public en production, le directeur ferme les deux formulaires avec un message qui renvoie vers ce lien (son seul geste, 2 minutes, page pas à pas du pilote) ; plus aucun import ensuite. Aucun service payant : environ 1 100 envois à 300 par jour tiennent sous la limite de Workspace (environ 2 000 par jour). Pas de question au directeur. Preuve : sur la pile locale, import d'un échantillon avec doublons et un désinscrit, réglage à 15 par jour, la file étale sur deux jours sans double ; en production, le premier jour, envois au plus égaux au réglage, 0 échec, 0 double | M | **lancement au plus tard le 10/11, premières invitations au plus tard le 15/11** ; premier agent libre, avant ACCUEIL-HORAIRE ; zones `lib/features/candidature`, `admin_candidatures`, import, et la file des courriels (`supabase/`) ; migration au numéro suivant de `garde-cap/RESERVATIONS-MIGRATIONS.md` ; R3 390 et 1440, FR et AR |
| 23 | Harmonisation UI transversale, en une seule passe (`DESIGN-GOV-2026-09-26.md`, l. 274-279) | L | quand les rangs 9, 13, 15, 16, 21 et 22 sont faits |

En cours hors de cette liste : O1 (secrets du directeur avant ouverture), PAY-UX puis REMB-14, A3-bis.
CI : 4 lots de tests en parallèle, environ 15 minutes au lieu de 55, depuis main c4aee81c (PR 155, fusionnée par le directeur le 03/11 à 01:32 UTC) ; preuve du rouge en cours (PR 159, branche jetable, jamais fusionnée).
Estimation : environ 14 jours-agent, soit 3 jours et demi à 4 agents ; avec la fusion une à une comme goulot, 4 à 5 jours.

## 8. Règles de vitesse (garde-cap et pilote, 03/11/2026 ; directeur informé, sauf contre-ordre)

- **4 agents.** Une hausse seulement si le débit de fusion mesuré sur 24 h dépasse la production des agents, et si aucun signal d'arrêt ne s'est allumé : dérapage confirmé, deux CI rouges de suite sur main, moins de lots fusionnés que lancés, code non branché ou module en double livré.
- **Questions :** aucune question bloquante pour ce qui est réversible ; on cherche d'abord dans les décisions écrites (G12), sinon un réglage « proposé », modifiable par la direction. L'argent, la sécurité, les données personnelles et la loi : une seule question groupée au directeur.
- **Tests :** l'agent lance les tests de son domaine et G3 ; la CI à 4 lots fait le reste. Exception : un lot qui touche `lib/core/`, le routeur ou les fournisseurs partagés lance la suite complète avant de pousser.
- **Lots S** d'une même zone groupés en une seule PR.
- **R3 :** deux captures du geste qui compte (téléphone, bureau), prises dans la vraie application ; le verdict du robot reste obligatoire.
- **En-cours :** au plus une PR ouverte non fusionnée par agent.
- **Fusion :** un lot sans texte nouveau passe dès qu'il est vert ; les lots avec texte passent un par un.
- **À faire avant toute hausse :** `verifier_branchement` et la présence des captures R3 dans `ci.yml` (collage du directeur, page du pilote) ; lot outil `libelles_sources.json` sans conflit (S).
- **Fiche tenue (03/11, 19:45) :** une fiche du garde-cap avec un « exige » non tenu bloque la fusion. Le garde-cap relit chaque PR serveur contre sa fiche avant le feu vert.
- **Numéros plus bas (03/11, 19:23, corrigé à 20:05) :** un numéro réservé plus bas que la dernière migration de main est accepté si la CI est verte et si aucun objet n'est commun avec les migrations installées après lui. Cela se vérifie contre la **production** au moment de l'installation, pas contre main. Sinon, on renumérote.
- **Fonction déjà retouchée (pilote, 03/11, 20:04) :** une migration qui remplace une fonction déjà retouchée par un autre lot le fait par ancres, ou elle est préflightée contre le prosrc de production. Une CI verte ne le prouve pas, car l'ordre des fichiers diffère de l'ordre d'installation. Cas réel : V1-a recopiait `capacites_candidatures` et aurait éteint « Valider la pièce » posé par salle 3. Le préflight l'a arrêtée. La relecture du garde-cap compte chaque `CREATE OR REPLACE` d'une fonction existante.
- **Les 17 chantiers sans serveur** (finance du comptable, communauté, recherche, B3.3, salle 3, CAND-04, B2.4, etc.) commencent après la file du §7, pas en parallèle.

## 9. Fiche NIV1 : le niveau demandé une seule fois (garde-cap, 02/11/2026 vers 18:15 UTC ; acceptée par le pilote à 18:19)

**Constat du directeur** (02/11, chat, sans capture) : « quand on ajoute un profil (en tant que tuteur) il y a des questions pour déterminer le niveau mais qui ne mènent nulle part (deux types de questionnaires je pense)… c'est lorsque tu rentres dans les paramètres que tu les trouves, et tu peux les zapper ».

**Code relevé** (main 8da94f560) : questionnaire 1, `/commencer` (`inscrire_titulaire` → `candidature_apprenants`, puis `lier_apprenant_profil` copie le niveau dans `student_profiles.niveau_declare`, `admission_lot_c.sql:562-565`) ; questionnaire 2, le « Questionnaire » de `ParcoursOffresPage` (`/tuteur/parcours/:eleveId`), qui repose tout parce que `lier_apprenant_profil` ne pose pas `onboarding_fait_le`.

**Règles écrites** : `programme-rewayah/SKILL.md:21` (le profil répond une fois, à l'inscription) ; `FICHE-ONBOARDING-2026-10-29.md:53` (le Parcours s'ouvre sur les horaires) ; `DECISION-CLASSES-SIMULTANEES-2026-10-10.md:14` (niveau dans la clé de regroupement) ; REGISTRE D0 (diagnostic oral choisi par la direction, 03/11).

**Lot**, sans toucher la zone gardée `parcours_offres` :
1. `lier_apprenant_profil` pose `onboarding_fait_le` quand niveau, objectif et langue sont repris (le Parcours saute alors les questions sans être modifié ; à vérifier en lecture).
2. Ajout d'un profil (zone foyer, après N2) : l'enfant sans niveau répond aux mêmes questions dans l'ajout ; enregistrement par `enregistrer_profil_apprentissage` et `onboarding_fait_le` posé.
3. Le niveau d'un adulte (« pour moi », parent qui suit des cours) quitte la demande vers `student_profiles`.
4. UX-032 (« 5 ans » accepté), même zone.
5. Rien à changer dans `parcours_offres` ; sinon, modification de zone gardée portée au directeur.
6. Migration `20261106800000` (renumérotée par le pilote le 03/11, après N2 `20261106700000` ; `20261106000000` est libéré). R3 : enfant venu de la demande → Parcours sur les horaires ; enfant ajouté → questions dans l'ajout, puis horaires.

## 10. Fiche DEFIL-FEUILLE : une boîte trop haute devient l'écran (garde-cap, 03/11/2026, 11:00 UTC)

Constat (C1, rejeu du 03/11, lu dans le code) : `AppBottomSheet` (`lib/core/widgets/app_bottom_sheet.dart`) met tout contenu long dans un `Flexible(SingleChildScrollView)`. Le contenu défile alors **dans** la feuille ou la boîte de dialogue, bornée par l'écran. Preuve : « Ajouter un élève » (`groupes_page.dart:1665` et `:2111`), capture `rejeu-2026-11-03/parcours-4/1440/02`, la 5e carte est coupée. Le composant est le seul point d'entrée des surfaces modales (environ 110 appels).

Règle appliquée, sans arbitrage : `DECISION-DEFILEMENT-2026-11-01.md` règles 1 à 3 (aucun contenu ne défile dans un cadre ; une seule barre de défilement par écran ; rien de gros ne reste collé).

Correctif, comme les grands systèmes (feuille « grande » d'Apple, boîte plein écran de Material sur petit écran), dans le composant seul :
1. Le contenu tient dans l'écran : la feuille ou la boîte prend la hauteur de son contenu, rien ne défile. C'est le cas courant, inchangé.
2. Le contenu ne tient pas : la surface prend **toute la hauteur** de l'écran (téléphone : feuille plein écran ; tablette : feuille bornée en largeur, pleine hauteur ; bureau : boîte pleine hauteur de la fenêtre, marges du gabarit). Elle **est** alors l'écran : le voile cache la page dessous, qui ne défile pas, et le corps de la surface porte la seule barre de défilement.
3. Le titre et les phrases d'aide défilent avec le corps. Seule une barre fine reste en haut, avec la croix « Fermer » quand elle existe, sans cacher une ligne. Les boutons d'action restent au pied du contenu, sauf s'ils sont déjà collés au pied aujourd'hui (on ne change pas leur place).
4. Aucun appel n'est modifié, sauf celui qui fixe lui-même une hauteur autour d'une liste : l'agent en fait l'inventaire (`grep` des hauteurs fixes dans les contenus passés à `AppBottomSheet`) et le joint à la PR.
5. La garde `cadre-defilant` de `tool/verifier_revue.dart` existe déjà ; l'agent dit dans la PR si elle peut reconnaître ce cas (feuille modale dont le corps défile sans être pleine hauteur), et l'ajoute si c'est une règle simple. Sinon, un test de widget suffit.

Hors du lot (pas de dispersion) : `SelecteurPersonne` (`selecteur_personne.dart:235`, 6 personnes montrées puis « N autres… » et la recherche). Rien n'y défile dans un cadre, donc la règle du défilement n'est pas touchée ; c'est la ligne 29 de `DECISION-LISTES-2026-10-23.md` (« à suivre avec Comptes »), qui reste à sa place.

Preuves (R3) : « Ajouter un élève » à 1440 et 390, avant et après, avec cinq cartes ou plus visibles en faisant défiler la seule barre de l'écran ; une boîte courte (une confirmation) inchangée à 1440 et 390. Suite complète avant de pousser (`lib/core`). Sans migration. Le bilan de la PR dit « une seule barre de défilement, celle de l'écran ».

## 11. Fiche PHOTOS : une seule photo par personne, la même partout (garde-cap, 03/11/2026, 13:45 UTC)

Demande du directeur (03/11) : « pour les photos il faut penser à les synchroniser partout où elles doivent être, et c'est pour tous les rôles. Actuellement pour un enfant comme Hakim j'ai ajouté sa photo mais qui ne s'affiche pas partout, le parent et l'élève adulte n'ont pas encore de photo qui marche et qui est synchro. »

### Constat (relevé en lecture sur main 2b820d74)

- **Élève (posée par le tuteur)** : seau privé `avatars` et `student_profiles.avatar_storage_key`. Elle s'affiche seulement côté tuteur : accueil famille, Foyer, fiche élève, finances, recharge. Partout ailleurs, on ne voit que les initiales :
  - sur l'appareil de l'enfant (choix de profil, espaces de l'enfant) ;
  - dans le compte du tuteur (`compte_tuteur_page.dart:99,516`, `compte_page.dart:592,638,675`) ;
  - chez l'enseignant (`projectionElevesProvider` vide en production, `preparation_seance.dart:78-82`) ;
  - dans la salle (`EleveSeance` sans clé, `depuis_salle.dart:114-130`) ;
  - dans les écrans de la direction.
- **Élève adulte** : aucun écran d'envoi. La politique du seau exige le rôle tuteur. « Mon espace » lève `CapaciteIndisponible`.
- **Tuteur, direction** : ni colonne, ni seau, ni écran.
- **Enseignant** : écran présent (`photo_publique.dart`), mais l'envoi n'est pas branché (`_EnvoiNonBranche`, aucune surcharge dans `main.dart`). Aucun droit client n'écrit `teacher_profiles.photo_storage_key`. La photo s'affiche dans la salle quand la clé existe. Elle ne s'affiche jamais sur la carte de la classe ni dans l'espace de classe.
- **Cache** : l'URL signée vit 600 s, mais `avatarUrlProvider` et `photoEnseignantUrlProvider` la gardent sans fin (pas d'`autoDispose`). Après un envoi, seuls deux fournisseurs sont relus, si bien que l'ancienne photo reste à certains endroits.

### Règles de lecture appliquées (écrites, aucune question au directeur, G12)

- **Photo d'un élève, mineur ou adulte** : son foyer, ses enseignants, la direction et ses camarades de classe (K-44, tableau du directeur du 09/10, « elle s'affiche chez son enseignant, à l'administration et chez ses camarades de Classe » ; `02_ARCHITECTURE_ET_SECURITE.md` §6, « portraits visibles en classe ; accès restreint »). Jamais une autre famille hors de la classe. L'ADR-012, archivé, est caduc sur ce point. La photo n'est jamais montrée au public.
- **Précision du 03/11 (garde-cap, à la relecture de PHOTOS-1)** : « camarades » veut dire l'élève camarade dans sa propre session, jamais les adultes de son foyer (moindre accès pour un mineur ; scénario : le parent d'un camarade ne voit pas la photo).
- **Photo d'un enseignant** : inchangée (ses élèves et leurs foyers, la direction : `0032_tc_catalogue.sql:642-655`).
- **Photo d'un adulte du foyer** (titulaire et second adulte) : lui-même, son foyer, la direction et les enseignants des enfants du foyer. Réglage « proposé ». La demande du 03/11 (« tous les rôles », « le parent ») remplace la règle Q4 (« le second adulte : ses initiales, jamais sa photo ») ; le directeur en est informé et peut la rétablir d'un mot.
- **Photo d'un membre de la direction** : visible des comptes qui voient son nom (messages, annonces, alertes). Réglage « proposé ».
- **Qui pose la photo** : chaque adulte la sienne, le tuteur celle de ses enfants mineurs, l'élève adulte la sienne. L'enfant en Interface guidée ne la change pas.

### PHOTOS-1 (serveur, M, migration 20261107300000)

1. **Une seule source par personne** : une clé de photo lue par une seule fonction, `photos_personnes(ids uuid[])`. Elle rend, pour chaque personne que l'appelant a le droit de voir selon les règles ci-dessus, la clé et le seau, et rien pour les autres.
   - Les colonnes existantes (`student_profiles.avatar_storage_key`, `teacher_profiles.photo_storage_key`) restent la vérité pour leur rôle.
   - Une seule colonne nouvelle pour les comptes qui n'en ont pas (tuteur, direction).
   - Aucune copie en double d'une même photo.
2. **Écrire sa photo** : `poser_ma_photo(cle)` pour tout adulte connecté (dont l'élève adulte et l'enseignant, qui remplace l'envoi non branché), et `poser_photo_eleve(eleve, cle)` pour le tuteur. Droit d'écriture du seau dans son propre dossier pour tous les rôles adultes.
3. **Lecture du seau** : une politique pour les camarades d'une même classe active, en plus de celles du foyer et de la classe (`avatar_lecture_classe`).
4. **Ordre de la base** :
   - Si une politique existante doit être remplacée (DROP POLICY), elle part dans un fichier B5, **20261107300001**, collé par le directeur avant 300000.
   - Sinon, aucun fichier à coller.
5. **Scénario SQL**, en authenticated :
   - le camarade voit la photo, une autre famille ne la voit pas ;
   - l'enseignant voit celles de ses élèves ;
   - l'élève adulte pose la sienne ;
   - le tuteur ne pose pas celle d'un autre foyer ;
   - l'enfant en Interface guidée ne pose rien.

### PHOTOS-2 (écrans, L)

1. **Un seul fournisseur**, `photoPersonneProvider(id)`, lu par `AvatarTile` sur **tous** les écrans du relevé, sans initiales imposées : accueil et appareil de l'enfant, compte du tuteur, Foyer, salle (panneau des élèves, vignettes, capsule), fiche de classe, fiche élève, cahier, cartes de classe, espace de classe, écrans de la direction, messages.
   - Les initiales restent seulement quand la personne n'a pas de photo, ou quand l'appelant n'a pas le droit de la voir.
   - Aucun nouveau composant : `AvatarTile`, `PhotoEleve` et `PhotoEnseignant` sont réunis derrière ce fournisseur.
2. **Fermer la seconde porte d'écriture** : le droit client de `0005` sur `student_profiles.avatar_storage_key` est retiré en même temps que le client passe à `poser_photo_eleve` (PHOTOS-2a, migration 20261107400000), jamais avant.
3. **Envoi pour chaque rôle** :
   - le tuteur depuis son Compte ;
   - l'élève adulte depuis son Profil ;
   - l'enseignant depuis `photo_publique.dart`, branché ;
   - la direction depuis son compte ;
   - le tuteur pour un enfant, depuis la fiche élève (déjà là).
4. **Synchronisation** : après un envoi, toutes les vues de cette personne sont relues. L'URL signée est rafraîchie avant son expiration (`autoDispose` et délai), jamais gardée au-delà de 600 s.
5. **R3** : Hakim visible avec sa photo :
   - chez le tuteur ;
   - sur l'appareil de Hakim ;
   - chez son enseignant (fiche de classe, salle) ;
   - chez un camarade ;
   - chez la direction.

   Et invisible chez une autre famille. Plus la photo du tuteur et de l'élève adulte posée, puis vue à deux endroits. À 1440 et à 390.
6. **Hors du lot** :
   - la compression côté serveur (question ouverte de l'ADR-012, archivée) ;
   - la suppression des anciens fichiers, qui suit M1 et le « oui » du directeur.

## 12. Fiches DRAPEAUX, FUSEAUX et SUPPRIMER (demandes du directeur, 03/11/2026 vers 17:50 UTC)

Mots du directeur : « ajoute aussi les drapeau des pays des enseignants (demandé depuis le début, mais pas appliqué, c'est été codé en plus, je le sais). et aussi le fuseau horaire qui est une pagaille pas possible actuellement (et pourtant j'avais demandé que chacun voit son fuseau et celui de son interlocuteur: exemple, 08h chez vous (paris), et 06h chez "Sayyid/sayda" (C.Ivoire) et vice versa; avec de belles animations en directs si possible, et que cela soit syncronisé partout où nécessaire. il est actuellement impossible de supprimer quelque chose surtout un profil, et pourtant on devra supprimer la plupart des profils de tests actuellement, mais y'a pas moins depuis l'interface. »

Pour chaque lot, l'agent cherche d'abord dans le dépôt ce qui fait déjà la chose (INVENTAIRE-NON-BRANCHE), réutilise, et dit dans son bilan ce qui a été repris ou écarté.

### DRAPEAUX (S, `lib/`, groupé avec FOYER-UX, rang 16)

- Le drapeau du pays de l'enseignant s'affiche à côté de son nom partout où une famille ou un élève le voit : cartes de classe, Accueil, fiche de la classe, salle.
- Il reprend le composant de drapeau qui existe déjà (cité par le directeur comme « codé ») et la donnée du pays de l'enseignant déjà lue par la direction (`comptes_admin_par_role`, pays d'un enseignant). Aucun drapeau nouveau dessiné.
- Le pays seul, jamais une adresse ni une ville.

### FUSEAUX (M-L, `lib/` et serveur si besoin)

- Partout où une heure concerne deux personnes (famille et enseignant, enseignant et classe, direction et personne), on affiche les deux heures, la sienne d'abord : « 08:00 chez vous (Paris) · 06:00 chez Sayyid Nom (Côte d'Ivoire) », et l'inverse pour l'autre. « Sayyid » ou « Sayyida », selon le profil enregistré, jamais déduit du nom.
- **Un seul composant** d'heure double, lu partout : séance du jour, cartes, planning, salle, notifications à l'écran, e-mails (avec COURRIELS-UX, même règle de ville qu'UX-030). Plus aucun calcul de fuseau dispersé.
- Les sources :
  - `timezone_iana` du profil (`0005:401`) pour chaque personne ;
  - le fuseau de la classe pour la séance ;
  - le stockage reste en IANA et en UTC (`02_ARCHITECTURE` §7) ;
  - la ville en clair, comme UX-030 ;
  - le pays par le drapeau (DRAPEAUX).
- Animation en direct (l'horloge avance), sobre, et coupée si l'appareil demande moins d'animations (`DESIGN-GOV`, `03_DESIGN_SYSTEM`).
- Le relevé d'abord : la liste de chaque écran qui affiche une heure, avec sa source actuelle. C'est la « pagaille » à corriger, jointe à la PR.
- R3 : la même séance vue par un tuteur à Paris et par un enseignant à Abidjan, à 390 et à 1440, plus un changement d'heure d'été.

### SUPPRIMER (M, serveur puis `lib/`)

- **La direction** supprime un compte ou un profil depuis Personnes, un à un ou **par sélection** (DECISION-LISTES, sélection et actions de masse) : c'est le moyen de retirer les profils de test.
- **Le tuteur** supprime le profil d'un enfant de son foyer, ou demande la suppression de son propre compte (`demander_suppression_compte`, `20261018150000`, déjà là).
- **Côté serveur :**
  - une suppression est d'abord un **retrait** : accès coupé, profil masqué partout, journal sensible ;
  - puis une anonymisation au délai de conservation réglable (CAND-Q21, modèle existant) ;
  - un profil qui porte des paiements ou des factures n'est jamais effacé : il est retiré et anonymisé, et les écritures comptables restent (obligation légale) ;
  - confirmation à l'écran, avec le nombre de profils touchés ;
  - réversible pendant le délai de conservation.
- Pas de bouton « tout supprimer ».
- Les migrations prennent des numéros au-dessus de la dernière installée. Une migration dont le texte contient DELETE suit la règle du collage par le directeur.

### Relevé « déjà codé » (garde-cap, 03/11/2026 vers 19:00 UTC, lecture seule sur main 222c763d8)

Le directeur avait raison : l'essentiel existe, il manque la donnée ou le branchement. Chaque agent part de ce relevé.

**DRAPEAUX : le client est prêt, le serveur ne donne pas le pays aux familles.**
- Existe : le composant `PaysEnseignant` (`lib/core/widgets/pays_enseignant.dart:45`, images `assets/flags/`, `.parCode`, `codesIsoDesPays`), repris par `AvatarNom(pays:)` (`avatar_nom.dart:168-175`). Les cartes famille passent déjà `pays:`. Les modèles lisent déjà `teacher_country` (`groupes_supabase.dart:55`, `service_planning.dart:139`, `service_groupes.dart:76`).
- Manque : `mes_groupes_famille_v` (`0033:140-170`) et `mes_seances_v` (`20261107500000:193`) n'ont pas `teacher_country`. Le drapeau ne se voit aujourd'hui que dans Personnes > Comptes. La migration est déjà décrite dans `ENS-PAYS-1_BR.md:15-26` (masquée comme le prénom). Numéro : **20261108700000**.
- Puis : passer `pays` aux deux `AvatarNom` de la salle (`capsule_seance.dart:65,230`, `chrome_seance.dart:813`).
- Défaut joint : `historique_controleur_supabase.dart:72` lit `pays_enseignant`, colonne qui n'existe dans aucune migration.

**FUSEAUX : deux heures déjà calculées par le serveur, mais la seconde ne correspond pas à son libellé.**
- Existe : `SessionClockVM` (`lib/core/tc_horloge/session_clock_vm.dart:107-125`), `horloge_classe` (`20261025040000:27-45`), `horloge_seance` (`0033:463`), `mon_fuseau()` (`0005:407-417`), la ligne « Chez Sayyid X » (`carte_session.dart:300-345, 686-695`), la mise à jour par bascules (`horloge_vivante.dart`, `ancre_horloge_serveur.dart`), la ville traduite `villeDuFuseauLibelle` (`lib/core/i18n/villes_fuseau.dart:39`).
- Défaut central : « Chez Sayyid X » affiche le fuseau de la **classe** (`groupes.timezone_iana`), pas celui de l'enseignant (`teacher_profiles.timezone_iana`). Il tombe juste seulement si la classe a été créée au fuseau de l'enseignant.
- La « pagaille » relevée :
  - Accueil famille et planning : heure du foyer, puis « Heure de la classe » (`bloc_seance.dart:52-90`).
  - Mes classes : une seule heure (`carte_groupe.dart:400-427`).
  - Heure de l'appareil (`toLocal`) : accueil élève, historique tuteur, journée et classes de l'enseignant, salle, notifications, rejoindre avec l'élève.
  - Historique adulte : l'heure vient de l'appareil et la date du serveur (`service_planning.dart:164`), qui peuvent se contredire vers minuit.
  - Un second helper de ville, non traduit (`villeDeFuseau`, `horloge_supabase.dart:26`), sert toutes les cartes de séance.
  - Aucune heure courante qui avance : seulement un compte à rebours.
- À faire :
  - serveur : `horloge_classe` et `horloge_seance` donnent le fuseau, le titre et le pays de l'interlocuteur (l'enseignant pour la famille, chaque famille pour l'enseignant). Numéro : **20261108800000** ;
  - client : un seul composant d'heure double à la place de `bloc_seance`, `carte_groupe` et des `toLocal`, `villeDeFuseau` remplacé par `villeDuFuseauLibelle`, une ligne d'heure courante animée qui s'arrête si l'appareil demande moins de mouvement ;
  - `pubspec.yaml` est gelé, donc aucune conversion IANA côté client : tout vient du serveur.

**SUPPRIMER : la demande de l'intéressé est branchée, la suppression par la direction ou le tuteur ne l'est pas.**
- En production : « Mes données » (`/compte/mes-donnees`, `demander_suppression_compte`) et Personnes > Suppressions (`SuppressionsPage`, `traiter_demande_suppression`, `private.cpt_anonymiser`).
- Branche `claude/supprimer-serveur` (20261108600000) : retrait, anonymisation à 30 jours par pg_cron, `direction_supprimer_comptes(uuid[])` (aal2, 200 au plus), `tuteur_supprimer_profil_enfant(uuid)`. **Écart à corriger avant la PR** : pas de restauration pendant le délai, ni de liste des retraits. Ajouter `direction_restaurer_comptes(uuid[])` et une liste paginée des retraits, avec leurs tests.
- Client à brancher ensuite :
  - un port et un adaptateur sur le modèle de `MesDonneesSupabase`, branchés dans `main.dart` ;
  - dans Comptes, `SelectionCollection` (`data_collection.dart:158`) et `BarreSelection` (`barre_selection.dart:42`), comme dans les candidatures, une entrée dans le menu de ligne (`comptes_page.dart:1060-1084`) et `ConfirmDestructive` avec le nombre de profils ;
  - dans la fiche enfant du tuteur (`fiche_eleve_page.dart:549-601`), une ligne « Supprimer ce profil » ;
  - la restauration se fait depuis Personnes > Suppressions.

## 13. Fiche ANTI-ROBOT : un contrôle « je ne suis pas un robot » aux portes ouvertes (garde-cap, 03/11/2026 vers 20:00 UTC)

Mot du directeur, 03/11 vers 19:55 : « Oui pour la sécurité ». C'est sa réponse à la proposition d'ajouter Cloudflare Turnstile et des plafonds d'envoi. Le contrôle était noté « ouvert, pour plus tard » dans `DECISION-DOMAINE-2026-10-23.md` §4. Il est décidé désormais.

### Constat (lecture sur main e2a25bf45)

- Le site et l'application sont des fichiers fixes chez Vercel. La protection contre la saturation est automatique, sur tous les plans. Aucune règle de pare-feu personnalisée n'est posée, et ce n'est pas nécessaire.
- Le DNS est chez Cloudflare, sans le proxy : les enregistrements A pointent directement sur Vercel. On ne change rien.
- Les portes ouvertes à un robot sont chez Supabase, appelé directement par le navigateur :
  - la connexion par lien e-mail (`signInWithOtp`, qui crée aussi le compte) ;
  - la connexion par mot de passe (`signInWithPassword`), dans `lib/core/auth/service_auth.dart:56-60`.
  Un robot peut y créer des comptes et faire envoyer des e-mails en masse.
- Déjà fermés :
  - le formulaire d'avis, ouvert seulement par un lien de la direction (`DECISION-AVIS`) ;
  - les webhooks signés (Stripe, LiveKit) ;
  - les fonctions publiques en lecture seule (tarifs, langues).
- Aucune politique de sécurité des contenus (CSP) dans `vercel.json` ni dans `web/index.html`. Le script de Turnstile se charge donc sans toucher à la zone du directeur.

### ANTI-ROBOT (M, `lib/` + `web/index.html` + une migration de réglage ; numéro 20261109000000)

- **Client :**
  - le widget Turnstile en mode « géré », presque invisible, devant l'envoi du lien de connexion et la connexion par mot de passe ;
  - le jeton passe à Supabase par `captchaToken` ;
  - le script `challenges.cloudflare.com/turnstile` se charge dans `web/index.html`, par `dart:js_interop` et `dart:ui_web` du SDK, sans nouveau paquet (`pubspec.yaml` est gelé) ;
  - les états chargement, erreur et hors ligne sont présents, avec des textes FR/AR passés par `mots-rewayah`. En cas d'échec : « La vérification n'a pas abouti. Réessayez. », sans jamais parler de robot à une famille.
- **Rien en dur :**
  - la clé publique du site est un réglage de la console, `securite.turnstile_cle_site`, lu sans compte par une fonction publique en lecture seule ;
  - réglage vide = contrôle absent côté client. C'est ce qui permet de livrer le client AVANT d'activer le contrôle.
  - La clé secrète ne va jamais dans le dépôt : le directeur la pose dans Supabase.
- **Ordre obligatoire, sinon plus personne ne peut se connecter :**
  1. fusion et déploiement du client, avec le réglage vide ;
  2. le directeur crée le widget Turnstile dans Cloudflare (noms d'hôte `app.rewayahacademy.com` et `rewayahacademy.com`) ;
  3. le directeur colle la clé publique dans la console, puis vérifie qu'il se connecte ;
  4. le directeur colle la clé secrète dans Supabase (Authentication, protection contre les attaques) et active le captcha ;
  5. le pilote vérifie une connexion réelle. En cas d'échec, désactiver le captcha dans Supabase rétablit tout à l'instant.
  Le pilote fait une seule page pour ces gestes.
- **Aperçus Vercel :** la clé de test publique de Cloudflare, qui passe toujours, puisque les aperçus visent la même base.
- **Plafonds :** relevé des fonctions Edge qui envoient un e-mail ou écrivent sans compte. Chacune a un plafond par adresse et par heure, réglable dans la console. Celles qui n'en ont pas en reçoivent un. La liste va dans la PR.
- **Données personnelles :** Cloudflare traite l'adresse IP et des signaux du navigateur. La phrase de la politique de confidentialité est proposée dans la PR, et le directeur la valide avant la mise en production. Pas de cookie de suivi publicitaire.
- **Hors périmètre :** pare-feu personnalisé Vercel, proxy Cloudflare, plan payant.
- **R3 :** la connexion par lien et la connexion par mot de passe à 390 et à 1440, avec le réglage vide (aucun widget) et avec la clé de test (widget présent).

