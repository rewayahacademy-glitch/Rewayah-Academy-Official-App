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

