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
| 5 | N2 : foyer et élève adulte (E1, FA5, FA1-FA3), puis NIV1 (niveau demandé une fois, UX-032), même agent | M + M | |
| 6 | ADM-UX (UX-006, 007, 014) | S | |
| 7 | N3 : pause programmée, mission du contrôleur, photo de l'enseignant | M | |
| 8 | CAHIER-UX (UX-028, 041 ; UX-029 vérifié d'abord en lecture) | S | |
| 9 | N4 : Bibliothèque, coffre R2 de la pièce, publication des évaluations, interface standard, Interface guidée | L | r2-selftest lu avant |
| 10 | FN-SERVEUR (FN-106 et 107 d'abord, puis FN-003, 019, 104) | M | |
| 11 | Double vérification à la publication de la politique commerciale (aal2) | M | après REMB-14 |
| 12 | A11Y-1 (UX-004, 010, 021, 027) | S/M | |
| 13 | Captures des trois salles (noms côté candidat du 02/11) | S | |
| 14 | SALLE-UX (UX-011, 033, 034, 038 à 040, 042, 043) | M | après O1 |
| 15 | FOYER-UX (UX-009, 023, 024) | S/M | après N2 et NIV1 |
| 16 | M1 : liste des doublons à supprimer, soumise au directeur | S | rien n'est supprimé sans son « oui » |
| 17 | COURRIELS-UX (UX-026, FN-108) | M | après A3-bis et SNT |
| 18 | Scénarios SQL rouges (FN-004, 005, 020, 021, bf1_finance_backend) | M | |
| 19 | V1 puis V2 : entretien et réunion dans `/salle`, sans les outils de cours | L + L | |
| 20 | FN-DIVERS, un point par lot : FN-102, FN-101, FN-018, puis FN-111, FN-027 (FN-013 rattaché à RECHARGE-1) | S, puis M | |

En cours hors de cette liste : O1 (secrets du directeur avant ouverture), PAY-UX puis REMB-14, A3-bis.
Estimation : environ 14 jours-agent, soit 3 jours et demi à 4 agents ; avec la fusion une à une comme goulot, 4 à 5 jours.
