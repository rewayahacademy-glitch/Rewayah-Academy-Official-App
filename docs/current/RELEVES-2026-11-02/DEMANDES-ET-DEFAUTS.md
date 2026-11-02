# Relevé des demandes non faites et des blocages (lecture seule, 02/11/2026)

Dépôt lu : `/home/user/wt-releve`, `origin/main` = `58f6b7978` (PR 137, 02/11 16:54). Aucune base,
aucun Vercel, aucun GitHub consultés : tout ce qui touche la production vient des documents et des
messages de commit, et est marqué comme tel.

**Ce qui est faux ou non prouvé, d'abord :**
- La colonne « Recette prod (directeur) » de `docs/current/ETAT-OUVERTURE.md` est **vide pour
  toutes les lignes**, et le « Journal du directeur » de `PARCOURS-OUVERTURE-2026-11-01.md` aussi.
  Aucun parcours n'est noté « prouvé par le directeur en production » dans le dépôt. Le journal
  de `BOUCLE-1_PLAN_2026-10-24.md` §6 s'arrête au 24/10 (« Étape 1 codée, non fusionnée »).
- L'essai du directeur du 01/11 **n'est consigné nulle part comme un tout**. On le reconstitue
  par les messages de la PR 122 (`ab7a16e4c`) : « Le directeur était bloqué à la création d'une
  classe » (FN-113), « il ne trouvait pas comment clôturer une classe », « sans motif choisi, rien
  ne part » (journaux lus par le pilote : aucun appel à `cloturer_groupe`). **Rien sur
  l'invitation** : quel geste d'invitation a échoué le 01/11 est inconnu (voir « Inconnu »).
- **FN-113 n'a pas de ligne dans `UX-CONSTATS.md`** (le registre passe de FN-112 à rien) alors
  que la PR 122 et `ETAT-OUVERTURE.md` le citent. Règle du registre violée.
- Registre en retard sur `main` : FN-028 est encore « ouvert » alors que la PR 118 (`d44380717`)
  l'a codé ; UX-025 « ouvert » alors que la PR 136 (`2310e1f12`) le corrige ; UX-044/045 « ouvert »
  alors que la PR 135 (`5348c3c61`) les traite ; `ETAT-OUVERTURE.md` dit « (B) en cours » alors
  que (B) est fusionné (PR 136). Rien de cela n'est « fait » au sens du directeur (pas de capture
  de fermeture, pas de preuve en production).
- **Écart dépôt / production** : d'après les commits de la branche de la PR 50 (`4d8e418cb`
  « fichier 18 en production », `c4e656819` « fichier 19 (prévenir par e-mail) en production »),
  `20261024000000_cand_nom_latin.sql` et `20261024010000_cand_prevenir_par_courriel.sql` sont en
  production mais **absentes de `main`**. Le tableau d'écart de `ETAT-OUVERTURE.md` ne les cite pas.

---

## 1. Blocages de l'essai du 01/11

### 1.1 Créer une classe

(a) Demande : « La direction crée une classe avec cet enseignant, un jour, une heure, un public »
(K2, `BOUCLE-1_PLAN_2026-10-24.md`, 24/10 ; parcours 2 de `PARCOURS-OUVERTURE-2026-11-01.md`).
Bloqué le 01/11 (message de la PR 122).

(b) État réel sur `main` :
- **Cause du 01/11 : plafond de 3 classes par enseignant** (`enseignant.classes_max`, migration
  `20261022000200_classes_plafond_par_enseignant.sql`, décision du 22/10). L'écran affichait la
  phrase générique. **Corrigé côté client** par la PR 122 (`ab7a16e4c`, 01/11 23:38) :
  `lib/core/admin/creation_classe_refusee.dart` reconnaît `plafond_classes_atteint`, dit « cet
  enseignant tient déjà N classes actives, pour un maximum de M. Clôturez une de ses classes, ou
  relevez le maximum dans les Règles » avec un lien vers `/admin/configuration/regles`
  (réglage éditable : `lib/core/admin/config_edition.dart:87`). Une classe close ne compte plus.
  Codé, test local et robot `tool/e2e/fn113_plafond.mjs` verts ; **non prouvé par le directeur**.
- **Reste ouvert, peut encore bloquer :**
  - **UX-003** : la feuille « Nouvelle classe » ouvre d'office 3 créneaux (`_autres` initialisé à
    deux lignes vides, `lib/features/admin_groupes/groupes_page.dart:1294`) ; « Créer la classe »
    refuse tant qu'elles ne sont ni remplies ni retirées. Toujours dans le code.
  - **FN-103 + UX-020** : voir 1.2 ; un chevauchement avec une séance fantôme d'une classe close
    donne « cette personne a déjà une séance prévue à la même heure » (motif
    `chevauchementSeance`), sans dire laquelle ; une violation brute de
    `sessions_no_teacher_overlap` (23P01) n'est reconnue par aucun préfixe et tombe sur la phrase
    générique « le serveur a refusé ces choix » (`creation_classe_refusee.dart:95-109`).
  - **UX-030** (fuseau affiché en code IANA, `groupes_page.dart` `_fuseau`), **UX-031** (Échap
    perd toute la saisie sans prévenir) : ouverts.
  - Décision du 25/10 (noms de classe automatiques, plan §5) : **rien dans le code** (voir 2.8) ;
    le formulaire demande toujours un nom.

(c) Fichiers : `lib/features/admin_groupes/groupes_page.dart`, `lib/core/admin/creation_classe_refusee.dart`,
`lib/features/admin_groupes/refus_creation_classe_libelles.dart`,
`supabase/migrations/20261023000000_classes_duree_bout_en_bout.sql`
(`verifier_horaire_contre_seances_planifiees`, message « chevauchement avec une séance existante »),
`supabase/migrations/20261030100000_classe_plusieurs_creneaux.sql` (`creer_classe_creneaux_admin`).

(d) À faire : client (UX-003 : un seul créneau par défaut ; UX-031 : confirmation d'abandon ;
UX-030 : ville en clair) ; migration (DETAIL du refus qui nomme la classe et l'heure en conflit)
+ client (afficher ce DETAIL ; mapper 23P01) pour UX-020. Aucune décision manquante.

(e) S (UX-003) + S (UX-031) + S (UX-030) + M (UX-020, migration + client).

(f) UX-020 dépend de FN-103 (1.2) pour le cas « classe close ».

### 1.2 Clôturer (ou « supprimer ») une classe pour libérer l'horaire de l'enseignant

(a) Demande du directeur, 01/11, en production : clôturer une classe pour libérer l'enseignant
(message de la PR 122 ; « il faut masquer les classes clôturées », `DECISION-LISTES-2026-10-23.md`
§5 quater). Le mot « supprimer » n'a aucun geste : rien ne s'efface (décision de la PR 122 et de
la D3).

(b) État réel :
- **Fait sur `main` (code)** : `cloturer_groupe` annule les séances `planned` **à venir** de la
  classe close et l'enseignant redevient libre à cet horaire (D3,
  `supabase/migrations/20261024150000_cloture_annule_seances.sql`, commits `5bd8e7ced`,
  `db7059ba8`, 24/10) ; le prédicat d'affectation et le plafond n'ont plus la classe close
  (`ended_at IS NULL`). PR 122 (`ab7a16e4c`) : « Clôturer la classe » en dernier dans la
  fiche-page, bouton destructif plein, message « il manque le motif » au-dessus du bouton, vue
  « Ouvertes » par défaut (clôturées masquées, migration `20261103800000_classes_admin_ouvertes.sql`).
  Non prouvé par le directeur.
- **Reste ouvert : FN-103 (Gênant)** : une classe clôturée **pendant** sa séance garde cette
  séance `planned` (le `UPDATE` ne prend que `started_at > now()`), qui continue de bloquer
  l'enseignant par la contrainte `sessions_no_teacher_overlap` (statuts `planned`, `preflight`,
  `in_progress`, `0005_dashboards_affectation_regles.sql:641`). Prouvé en local le 31/10 22:17 UTC.
  C'est exactement le cas d'un essai où l'on clôture une classe pour en créer une autre « dans
  l'heure qui vient ». **Aucun geste de la direction n'annule une séance seule** (aucune RPC
  `annuler_seance*` dans `supabase/migrations`).
- FN-015 (36 séances annulées de classes fermées rattachées à Hakim) : `canceled` ne bloque pas
  la contrainte ; nettoyage seulement, sur feu vert.

(c) `supabase/migrations/20261024150000_cloture_annule_seances.sql`, `lib/core/admin/service_groupes.dart:353`,
`lib/features/admin_groupes/groupes_page.dart:808`.

(d) Migration : `cloturer_groupe` traite aussi la séance commencée de la classe (et
`preflight`). **Décision manquante (une ligne)** : « Clôturer une classe pendant sa séance :
on arrête la séance en cours (tout le monde sort) ou on la laisse finir et seules les suivantes
sont annulées ? » ; question annexe : « Voulez-vous un vrai “Supprimer” pour les classes d'essai,
ou la clôture suffit ? ». Plus un scénario SQL.

(e) S/M (une migration courte + scénario ; M si la séance en cours doit être fermée côté LiveKit).

(f) Aucune ; débloque UX-020 pour ce cas.

### 1.3 Inviter quelqu'un

(a) Demande implicite des parcours 1 et 3 (`PARCOURS-OUVERTURE-2026-11-01.md`) et de B3.3.
Quelle invitation a échoué le 01/11 : **inconnu**. Trois gestes d'invitation existent, aucun ne
part par e-mail.

(b) État réel sur `main` :
1. **Enseignant (et comptable)** : `lib/features/admin_invitations/invitations_page.dart`,
   RPC `inviter_enseignant` (`20261016100300_contrats_invitations_enseignant.sql`). Le code est
   créé, **jamais envoyé** : texte affiché « Transmettez-le à la personne : il n'est pas envoyé
   automatiquement » (`recrutement.invitations.aideEmail`). Aucun modèle de courriel
   d'invitation enseignant dans `supabase/functions/_shared/courriel/` (seul `invitation_foyer`
   existe). **UX-015** : la page « Invitations » n'est pas dans les sections de Personnes ; on
   l'atteint par Candidatures › « Invitations » (`lib/core/router/routes.dart:776`). **UX-016** :
   le code tapé en minuscules **avec des espaces** est refusé (`verifier_invitation_enseignant`
   ne fait que `upper(btrim())`). **UX-013 / UX-017** : après le lien d'e-mail ou un
   rechargement, retour à « Pour qui créez-vous ce compte ? », code perdu ; si la personne choisit
   « Je m'inscris pour moi » elle devient demandeuse famille. **UX-018** : lien déjà utilisé mal
   expliqué. Parcours 1 vert en local sur le chemin prévu seulement.
2. **Familles importées (inscrits actuels)** : après « Importer les inscriptions », la carte
   « Invitations à envoyer » dit « Chaque nouveau foyer attend votre invitation » mais **n'a aucun
   bouton ni envoi** (`lib/features/admin_import_inscriptions/import_inscriptions_page.dart:1071-1091`) ;
   la migration B2.1 (`20261101000000_b2_1_import_foyers.sql`) n'appelle pas `courriel_enfiler`.
   La famille ne retrouve son compte que si elle vient d'elle-même se connecter avec la même
   adresse (`reclamer_preinscription_apres_preuve`, commit `2e2b7ba5c`).
3. **Candidat depuis sa candidature** : la capacité `inviter` est figée à `false`
   (`20261022000600_cand_l3_inscription_import_rapprochement.sql:2884`) ; « Prévenir par e-mail »
   n'existe que sur la PR 50 (et part à tout le monde, pas aux retenus, voir 2.4).

(c) Fichiers ci-dessus ; `supabase/functions/_shared/courriel/modeles_*.ts` ;
`lib/features/inscription/inscription_page.dart` (UX-013, UX-017).

(d) Migration + Edge (modèle) : `inviter_enseignant` met en file un e-mail avec le code et le
lien ; client : « Invitations » dans les sections (UX-015) ; normalisation du code (client ou
RPC, UX-016) ; garder `invitation=1` et le code à travers lien et rechargement (UX-013/017).
Familles importées : **décision manquante** : « L'import confirmé envoie-t-il tout de suite un
e-mail d'accueil à chaque foyer, ou la direction l'envoie-t-elle par un bouton, famille par
famille ? ».

(e) M (e-mail d'invitation enseignant) ; S (UX-015) ; S (UX-016) ; M (UX-013+017) ; M
(invitation des familles importées, après décision).

(f) Invitation des familles importées dépend de la décision ci-dessus ; B3.3 (2.4) dépend de 1.3.

---

## 2. Demandes du directeur

### 2.1 Les « trois salles »

(a) Ce sont les trois salles du **recrutement des enseignants**, pas des familles : « Salle
d'examen », « Salle de vérification et d'entretien », « Salle des prêts à enseigner »
(`DECISION-CANDIDATURES-2026-10-21.md`, CAND-Q12, 21/10 ; spec
`docs/current/CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md` §2.2 ;
`docs/orchestration/PILOTAGE-BOUCLES-2026-10-24.md` §2 : « tri sur la liste sans compte, puis
compte et pièce pour les seuls retenus » ; `DECISION-ADMISSION-2026-10-27.md` §6 : « La
spécification des trois salles des enseignants et ses lots L4 et L5 à écrire »). Les noms sont
encore « proposés » (CAND-Q12 ouvert, §3). « Salle d'attente » désigne ailleurs le portail
`/attente` du candidat (§1 bis) ou l'attente dans `/salle` avant l'arrivée de l'enseignant.

(b) État réel sur `main` :
- **Salle 1 (Salle d'examen)** : construite côté candidat (`lib/features/candidature/`,
  `/attente/candidature`, CAND-01, commits `12ccfb5a7`, `f8a5bca0d`, 22/10) et côté direction
  (ADM-20 `lib/features/admin_candidatures/`, ADM-21 `lib/features/admin_candidature/`,
  `47ce9dba1`, 23/10) ; tuiles « partage » (CAND-06) et « talents » (CAND-07) construites.
  **L'entrée publique sans code (CAND-04) n'est que sur la PR 50** ; la clé
  `candidatures.inscription_publique_ouverte` est `false` (`cand_l3`, ligne 161). Lot D
  d'admission (« entrée enseignant depuis le site ») non fusionné.
- **Salle 2 (vérification et entretien)** : le geste « Admettre en Salle de vérification et
  d'entretien » existe (L2A2) ; accords et pièce passent par le portail existant ; **l'entretien
  n'existe pas** (voir 2.2).
- **Salle 3 (prêts à enseigner)** : « valider la pièce fait entrer en salle 3 » (CAND-Q01) n'est
  **pas** construit côté candidature : capacité `validerPiece` à `false`, et `decider_dossier`
  (K1, `20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql`) ne touche pas `candidatures`.
  La validation K1 active le compte par Dossiers, hors du module.
- **Captures** : des tests de capture existent sur `main` (`test/capture/cand01_capture_test.dart`,
  `adm20_capture_test.dart`, `adm21_capture_test.dart`, `partage_capture_test.dart`,
  `talents_capture_test.dart`) ; le catalogue renvoie à `captures-ecrans/QUESTIONNAIRE/`, **absent
  du dépôt**. Le directeur a vu au moins la carte de partage (il l'a rejetée le 22/10,
  `DECISION-CANDIDATURES` §1 bis). **Qu'il ait reçu des captures des trois salles : inconnu.**
  Toutes les fiches du catalogue `CATALOGUE_ECRANS_RECRUTEMENT.md` sauf CAND-06, CAND-07, ADM-20,
  ADM-21 sont « proposée, à valider par le directeur ».

(c) `lib/features/candidature/`, `lib/features/admin_candidatures/`, `lib/features/admin_candidature/`,
`lib/core/candidature/`, migrations `20261021200000` à `20261022000600` (`cand_*`).

(d) Décision manquante : « Les trois noms de salle (examen / vérification et entretien / prêts à
enseigner) sont-ils validés ? » et « Les fiches CAND-02, ADM-20E, ADM-21R, ADM-22, ADM-23 sont-elles
validées telles quelles ? ». Puis migration (salle 3 : la validation de la pièce passe la
candidature en `confirmee` dans la même transaction, spec §2.2) + client.

(e) Salle 3 : M/L (migration avec ses contrôles + scénario). Salle 1 entrée publique : voir 2.4.

(f) Salle 2 dépend de 2.2 ; salle 1 publique dépend de la PR 50 (2.4) et de l'avis du directeur
sur la contradiction 2.4.

### 2.2 La visioconférence d'entretien avec un candidat enseignant

(a) « Pas de WhatsApp pour l'entretien… un espace dédié dans l'app » (CAND-Q06, 21/10) ; « Seule
la direction mène les entretiens » (CAND-Q19) ; aucune mention à l'écran, rien d'enregistré
(CAND-Q09) ; constat structuré (CAND-Q08). Mise en œuvre écrite : « une séance “entretien”,
jamais payée, ouverte au seul candidat convoqué, sans enregistrement »
(`DECISION-CANDIDATURES-2026-10-21.md` §2).

(b) **Rien de construit.** Besoin `CAND-BR-08` (`CANDIDATURES/DEPENDANCES_BACKEND.md:48`) sans
statut (= spécifié). Capacités `planifierEntretien` et `consignerEntretien` figées à `false`
(`20261022000100_cand_l2a2_gestes_direction.sql:1611-1612`, repris par `cand_l3:2888`). Aucune
table d'entretien, aucun `session_type` « entretien » (seuls `standard` et `child` sont gardés,
`20261021220000_cand_l1b_forme_compte_candidat.sql:359`). Écrans CAND-02 « Mon entretien »,
ADM-20E « Entretiens », ADM-21R « Compte rendu », mode entretien de `/salle` : fiches
« proposées » seulement. Les états `entretien_a_planifier`, `entretien_planifie` existent dans le
CHECK de `candidatures` (L1).

(c) `supabase/migrations/20261021200000_cand_l1_socle_candidatures.sql`, `..._l2a2_...`,
`supabase/functions/create-room-token/index.ts`, RPC `autoriser_jeton_video`,
`lib/features/salle/`, `lib/features/candidature/portail_candidature.dart`,
`CATALOGUE_ECRANS_RECRUTEMENT.md` (CAND-02 l.1000, ENS-03/ELV-03 mode entretien l.1452,
ADM-20E l.1762, ADM-21R l.2156).

(d) Migration (table des entretiens, `session_type` entretien exclu de la paie, de la présence,
de la clôture et des vues ; RPC planifier / consigner / mes entretiens ; jeton pour un compte
`pending_kyc` convoqué, cloisonnement femmes/hommes) + Edge (`create-room-token` admet le
candidat convoqué) + client (geste dans ADM-21, CAND-02 sur `/attente`, ADM-21R). Décision
manquante : validation des fiches (voir 2.1).

(e) L (au moins deux lots : serveur, puis écrans).

(f) Validation des fiches ; 2.1 (salle 2).

### 2.3 « Un bouton qui ouvre une session pour chaque personne »

(a) **Aucune trace de cette phrase dans le dépôt** (recherche sur `docs/current`,
`docs/orchestration`, commits). Deux lectures possibles, à faire trancher :
1. l'entretien : un bouton « Planifier l'entretien » / « Rejoindre l'entretien » par candidat
   (CAND-02, ADM-20E ; spec : « Rejoindre l'entretien » en lien secondaire sur la ligne, CAND-Q14) ;
2. les cours individuels actuels : « classes d'un seul élève en vague 1 »
   (`docs/orchestration/PASSATION-PILOTE-2026-10-25.md:93`), avec le prix d'une classe d'un élève
   à décider.

(b) Lecture 1 : rien (voir 2.2). Lecture 2 : une classe d'un élève se crée déjà par « Nouvelle
classe » ; aucun bouton « une séance pour chaque élève » ; prix non décidé.

(d) Décision manquante : « Le bouton “une session pour chaque personne”, c'est l'entretien de
chaque candidat retenu, ou un cours individuel pour chaque élève ? ».

(e) selon la réponse (L si entretien, cf. 2.2).

### 2.4 La liste des candidats (568) : trier, retenir, inviter les seuls retenus (B3.3), et la PR 50

(a) « B3.3 Preuve : la direction voit les 568 dans une liste, trie, n'invite que les retenus à
créer un compte, et seuls ceux-là déposent une pièce » (`PILOTAGE-BOUCLES-2026-10-24.md` §3,
24/10) ; ordre du 24/10 : tableau de direction, tri des 568, espace admin, paiement en dernier
(plan Boucle 1 §6).

(b) État réel :
- **Sur `main`** : ADM-20 liste la table `candidatures` (pas les réponses importées), sans mode
  sélection (ADM-22 non construit, catalogue l.1727). Le serveur L3 sert
  `lister_formulaires_importes`, `lister_a_prevenir_candidats`, `consigner_prevenu_candidat`
  (`cand_l3`, l.2282, 2508, 2596) mais **aucun écran de `main` ne les appelle**. **La notion de
  « retenu » n'existe nulle part** (ni sur `main`, ni sur la PR 50 : le mot n'y désigne que la ligne
  gardée d'un groupe de doublons).
- **PR 50** (`origin/claude/lucid-mccarthy-qpk6yq`, 17 commits au-dessus de la base `cfc3d0eaa`
  du 24/10, dernier `0acc35bd0` 24/10 03:25 UTC ; 577 fichiers différents de sa base). Le socle
  LISTES-1 et Comptes ont déjà été portés sur `main` (`7fb16ae8c`, 30/10). **Ce qui n'est que sur
  la PR 50** : CAND-04 inscription sans code (`lib/core/candidature/inscription_candidat_supabase.dart`,
  `port_inscription_candidat.dart`, `lib/features/inscription/etapes/telephone_etape.dart`,
  `lib/core/i18n/indicatifs_telephoniques.dart`) ; ADM-23 import des formulaires
  (`lib/features/admin_import_formulaires/`, 12 fichiers ; `import_candidatures_supabase.dart`) ;
  action groupée (`lib/features/admin_candidatures/lot_candidatures.dart`,
  `synthese_candidatures.dart`, `menu_ligne_candidature.dart`, `modeles_lot_candidatures.dart`) ;
  « Prévenir par e-mail » (`prevenir_candidats.dart`, `prevenir_candidats_supabase.dart`,
  migration `20261024010000_cand_prevenir_par_courriel.sql`) ; nom latin
  (`nom_latin*.dart`, `lib/features/candidature/nom_latin_etape.dart`, migration
  `20261024000000_cand_nom_latin.sql`) ; tests et captures associés. D'après ses commits, les deux
  migrations sont déjà en production. **Défaut connu** (`PLAN-LOTS-BOUCLES-2-4-2026-10-30.md`) :
  `prevenir_par_courriel` met en file le lien d'inscription pour **toutes** les réponses avec
  adresse, pas pour les seuls retenus ; elle refuse tant que l'inscription publique est fermée.
  Le plan du 30/10 prévoit de porter la PR 50 en deux lots (LISTES fait, CANDIDATURES à faire)
  puis de la fermer.
- **B3.1** (e-mail d'attente aux candidats) : modèle `attente_candidat` construit ; mise en file
  préparée pour 524 adresses (`PILOTAGE-BOUCLES` journal 24/10) ; `LISTE-ATTENTE-2026-10-27.md`
  dit « e-mail d'attente du 26/10 » reçu par des candidats : **envoyé, au moins en partie**.

(c) Ci-dessus ; `supabase/migrations/20261022000600_cand_l3_inscription_import_rapprochement.sql`.

(d) Migration (marque « retenu » / « écarté » sur une réponse importée, journalisée, cloisonnée
par genre ; `prevenir_par_courriel` et l'invitation limités aux retenus ; versionner sur `main`
les deux fichiers déjà en production) + client (porter ADM-23 et la liste des réponses importées
depuis la PR 50 sur les composants de liste de `main` : tri, filtres, sélection, « Retenir »,
« Inviter les retenus »). **Contradiction à faire trancher** : `DECISION-ADMISSION-2026-10-27.md`
veut l'inscription publique sans invitation (lot D), B3.3 veut que seuls les retenus créent un
compte. Question : « Pour les 568 : seuls les retenus reçoivent un lien nominatif, et
l'inscription publique des enseignants reste fermée jusqu'à nouvel ordre, oui ? ».

(e) L (portage ADM-23 + liste + sélection + migration).

(f) Décision ci-dessus ; 1.3 (e-mail d'invitation) ; nouvelle numérotation des migrations de la
PR 50 (elles sont datées du 24/10, avant 60 migrations de `main`).

### 2.5 Avis de l'élève après une séance (27/10)

(a) « très simple, pas à chaque séance » (`LISTE-ATTENTE-2026-10-27.md`). (b) Code présent non
branché (`session_feedback`, `lib/features/tc_flux_academique/carte_feedback_seance.dart`). (d)
client (brancher). (e) M. (f) hors ligne d'arrivée : attend un ordre.

### 2.6 Porte d'entrée fermée aux non-invités (27/10)

(a) Constat de production du 27/10 (`LISTE-ATTENTE-2026-10-27.md`). (b) Traité par la décision
d'admission (lots B et C : `ADMISSION-LOT-B-2026-10-29.md`, `ADMISSION-LOT-C-2026-10-30.md`) ;
lots D et E non faits ; tableau « Prouvé par le directeur » de `DECISION-ADMISSION-2026-10-27.md`
§8 **vide**. (d) preuve du directeur (B, C), puis lot D (lié à 2.4). (e) D : M/L.

### 2.7 Remboursements (FN-115, 01/11)

(a) « oui pour les 7 points » (`DECISION-TARIFS-2026-10-18.md`, 01/11). (b) FN-115a (PR 130,
`25a84dc83`) et FN-115b (PR 131, `9ffbacf17`) fusionnés. **Reste** : bouton « Rembourser » de
Finance (FN-115c), ajout des événements `charge.refunded`, `charge.dispute.*` au webhook Stripe
de production (geste du directeur), texte « remboursé en entier » encore sur
`site-public/content/pages.json`. (d) client + Edge (FN-115c) ; geste du directeur (webhook).
(e) M. (f) FN-011 (clés Stripe).

### 2.8 Noms de classe automatiques (25/10)

(a) « Les classes sont nommées automatiquement… noms féminins / masculins… la direction ne saisit
pas de nom » (`BOUCLE-1_PLAN_2026-10-24.md` §5, 25/10). (b) **Rien** : aucune bibliothèque de noms
ni fonction dans `supabase/`, `lib/`, `assets/`. (d) fichier de données versionné + migration
(choix dans `creer_classe_creneaux_admin`) + client (champ nom facultatif) ; **la liste de noms est
à proposer au directeur** avant versionnement (décision du 25/10). (e) M. (f) validation de la
liste par le directeur.

---

## 3. Boucles

### B2.3 — « Séance tenue sur Meet : marquer présents » (enseignant)

(a) « Tant qu'une classe reste sur Meet, l'enseignant marque les présences dans l'application »
(`PILOTAGE-BOUCLES-2026-10-24.md` §2 et §3 B2.3, 24/10) ; lot planifié
(`PLAN-LOTS-BOUCLES-2-4-2026-10-30.md`, ordre 3, agent 1).
(b) **Rien de spécifique.** Briques existantes : la correction de présence
(`lib/features/presence_correction/`, ouverte depuis `lib/features/cahier/cahier_page.dart:46`),
l'exception du cahier qui écrit `session_presence_override` (PR 106, `480a19ca3`). Mais la
présence se calcule désormais aux minutes LiveKit (décision du 31/10, `08` l.111) : une séance
tenue sur Meet donne « absent » à tous, et le cahier hebdomadaire n'offre pas « tous présents en
un geste ».
(c) `lib/features/presence_correction/`, `lib/features/cahier/`, migration de la PR 106,
`20261102900000_presence_minutes.sql`.
(d) migration (une RPC « séance tenue hors application » : marque la séance tenue et pose
`present` pour les inscrits choisis, garde enseignant de la séance / effectif ; paie : à
préciser) + client (bouton sur la séance passée d'Aujourd'hui / Classes). Décision manquante :
« Une séance marquée “tenue sur Meet” est-elle payée à l'enseignant comme une séance dans
l'application ? ».
(e) M. (f) décision ; FN-006 (Aujourd'hui des séances qui s'enchaînent) touche le même écran.

### B2.4 — Tableau de la direction (actif, à jour, régulier, à surveiller, ponctuel, enseignant de chaque élève, emploi du temps)

(a) Définitions décidées par Claude par délégation (`PILOTAGE-BOUCLES` §2, 24/10) ; preuve
« le directeur compare avec son WhatsApp sur dix élèves ».
(b) **Rien** (« n'a aucun écran », `PLAN-LOTS` 30/10 ; aucun terme ni calcul dans
`supabase/migrations` ni `lib/`). Le centre de commande `lib/features/admin_tableau/` n'a que des
compteurs. « À jour de paiement » : la définition du 24/10 (marque posée par la direction) est
dépassée par le paiement Stripe et le lot (B) (`private.acces_paye`) : à réaligner.
(c) `lib/features/admin_tableau/`, `lib/features/admin_pilotage/`, futur RPC.
(d) migration (vue ou RPC paginée par élève : actif, à jour via `acces_paye`, régulier, à
surveiller, ponctuel, enseignant, créneaux) + client (liste de bureau, `DECISION-LISTES`).
Décision à confirmer en une ligne : « “À jour de paiement” = accès payé du mois (Stripe ou accès
offert), et non plus une marque manuelle, d'accord ? ».
(e) L. (f) lot (A) tarifs particuliers (accès offert) pour « à jour » ; B2.3 pour les classes Meet.

### Communauté

(a) « ça existe déjà » ; salons aux heures d'affluence, pas en cours, aucun enfant
(`DECISION-BIBLIOTHEQUE-ET-RESTES-2026-10-30.md` §4, 30/10).
(b) Écrans présents (`lib/features/com_communaute/`, 12 fichiers), port `PortCommunaute` avec
un double de démonstration seulement ; **aucune table, aucune RPC, aucun adaptateur** ; l'entrée
d'Aujourd'hui est masquée en production (R-27, `entree_communaute.dart`). La mesure d'affluence et
les salons (adultes hommes / femmes / parents) n'existent pas. Note : l'écran existant est la
« Communauté enseignants », pas les salons des familles.
(d) migration (tables, RLS, RPC, règle « pas en cours », compteur agrégé par heure) + adaptateur
Supabase + écran des salons. (e) L (mesure d'abord : M). (f) hors ligne d'arrivée.

### PR 95 — factures le 1er, relances

(a) B4 (`PLAN-LOTS`, agent 2 ordre 4). (b) Branche `origin/claude/b4-factures-cron` (2 commits,
`adcd3ce3b`) : `supabase/migrations/20261102600000_b4_factures_et_relances_planifiees.sql`,
`supabase/tests/scenarios_b4_factures_cron.sql`, `lib/main.dart`. **Retenue** par le pilote
(02/11) jusqu'au lot (A) en ligne et à la saisie des prix spéciaux et accès offerts des inscrits
actuels (`ETAT-OUVERTURE.md`). Lot (A) : branche `origin/claude/a-tarifs-particuliers`
(serveur, client, captures R3), **non fusionnée**. Numéro de migration de B4 antérieur à ~40
migrations de `main` : à vérifier avant installation.
(d) fusion de (A), installation de ses migrations, saisie par la direction, puis PR 95. (e) S
(rebase et vérification). (f) lot (A), saisie du directeur.

### A3-bis

**Inconnu** : « A3-bis » n'apparaît nulle part (documents, code, commits). A3 = délais du
remplacement automatique (PR 98 `b4dbd2b27`, PR 128 `5625be893`, fusionnées). Candidat possible :
« Message aux familles dans la salle d'attente » marqué **bloqué** dans
`UX_REVIEW_REMPL-1.md:99`. À faire préciser par le pilote.

### Autres points de boucle encore ouverts

- K1 à K4 : aucune preuve du directeur consignée (journal du plan, `ETAT-OUVERTURE`).
- FN-006 (Bloquant) : séances qui s'enchaînent ; règle décidée le 01/11 (« à l'heure de fin plus
  la grâce, Aujourd'hui montre la séance suivante ; “Quitter et ouvrir le cahier” clôt la
  précédente ») ; **aucun code** (commits `20946407f`, `1bca17aa6`, `0489e9cce` : documentation).
  Client + migration ; M.
- FN-011 (Bloquant) : clés Stripe de production ; geste du directeur ; état actuel inconnu.

---

## 4. Défauts ouverts (UX-CONSTATS.md)

Tous au statut « ouvert » sauf mention. « Code » = ce que le relevé a vérifié sur `main`.

### Bloquants

| ID | Constat | Vérifié sur `main` | À faire | Taille |
|---|---|---|---|---|
| FN-006 | séances qui s'enchaînent (Aujourd'hui, cahier) | aucun code | client + migration | M |
| FN-011 | clés Stripe absentes (prod) | non vérifiable | directeur | — |
| FN-023, FN-024, FN-025 | chrono, fin annoncée, refus motivé | codés (PR 113 `09fd8b983`, PR 117 `607cc199e`) | preuve du directeur | — |
| FN-028 | aucune notification de fin | codé PR 118 (`d44380717`), registre pas à jour | preuve + fermer la ligne | — |
| FN-109 | détail de la paie : uuid composite `<enseignant>_2026-10-01` envoyé | ouvert | client | S |
| FN-002 | cahier du remplaçant | codé PR 108 (`428b162b6`), migration en prod | preuve du directeur | — |
| UX-045 | consentements qui « se battent » (Bloquant si incliquable) | hypothèse traitée PR 135 | reproduire en prod | — |

### Gênants (écrans)

| ID | Écran / constat | Vérifié / code | Taille |
|---|---|---|---|
| UX-001 | « Messages métier » incompréhensible | `assets/i18n` | S |
| UX-003 | 3 créneaux d'office | `groupes_page.dart:1294` toujours là | S |
| UX-004 | barre enseignant hors arbre d'accessibilité | `nav_shell.dart` à confirmer | S/M |
| UX-005 | « francais » brut au récapitulatif | `recapitulatif_etape.dart:382` | S |
| UX-006 | état « À traiter » après « Accepter » | `admissions_page.dart:449` | S |
| UX-007 | recherche perd le focus (à confirmer au clavier) | `admissions_page.dart:196` | S |
| UX-009 | deux messages contradictoires (Accueil tuteur) | `bloc_seance.dart:137` | S |
| UX-010 | « Page suivante » seulement dans « Plus » (bureau) | `zone_support.dart:508` | S/M |
| UX-011 | « Retourner dans la salle » alors qu'on y est | `barre_seance_en_direct.dart:241` | S |
| UX-012 | « État inconnu » | `ligne_presence.dart:75` | S |
| UX-013, UX-017 | parcours invitation perdu (lien, rechargement) | `inscription_page.dart` | M |
| UX-014 | boîte de demande sans Fermer ni Échap | `admissions_page.dart` | S |
| UX-016 | code en minuscules + espaces refusé | RPC `upper(btrim())` seulement | S |
| UX-018 | lien expiré mal expliqué | page d'erreur de route | S |
| UX-019 | message brut « cet eleve appartient deja a un groupe actif… P0001 » | `groupes_page.dart:1994-1998` affiche `_message(erreur)` | S |
| UX-020 | refus de chevauchement sans dire avec quoi | voir 1.1 | M |
| UX-021, UX-027 | bouton et clavier de code sans nœud accessible | `PinPad`, écran Appareils | S/M |
| UX-023 | Foyer « Aucun profil élève » pour l'adulte élève | `lib/features/foyer/` | M |
| UX-024 | « Comment vous appelez-vous ? » ambigu (parent) | `lib/features/inscription/etapes/` | S |
| UX-025 | Recharger invisible / Payer grisé | corrigé dans le code PR 136 ; registre pas à jour | — |
| UX-026 | e-mails sans classe, enfant, fuseau | `_shared/courriel/modeles.ts` | M |
| UX-028 | cahier « Obligatoire après chaque séance », compteurs faux | écran du cahier | S |
| UX-029 | revenus : octobre non consultable | `revenus_enseignant` | S |
| UX-030, UX-031 | fuseau IANA ; Échap perd la saisie | `groupes_page.dart` | S + S |
| UX-032 | « 5 ans » accepté | questionnaire | S |
| UX-033, UX-034 | salle téléphone : bouton sur le texte ; puce « Commandes » | `salle_seance/` | S/M |
| UX-038, UX-039, UX-040 | salle en double onglet ; « séance terminée » faux au tuteur ; écran de fin avec une autre barre | `lib/features/salle/` | M |
| UX-041 | cahier : position perdue au Retour | écran du cahier | S |
| UX-042, UX-043 | pastille « En direct » après la fin ; « Retourner dans la salle » proposé après clôture | `salle_page.dart`, `resultat_seance.dart` | S |
| UX-044 | carte de choix sans retour visuel | traité PR 135 (`5348c3c61`) ; preuve à faire | — |
| UX-046 | style de l'inscription inchangé : cause à établir (PR 1 et 2 de `PARCOURS-ENTREE-2026-10-25.md` sont sur `main` : `d4076f79e`, `43b0ac50e` ; PR 3 et 4 non) | enquête | S |

Finition : UX-002 (`web/manifest.json`, zone protégée), UX-008 (« Ajouter un élève » : **le bouton
est désormais dans la fiche-page**, `groupes_page.dart:797`, PR 122 ; non fermé faute de capture),
UX-015 (Invitations hors menu), UX-022, UX-035, UX-036, UX-037.

### Gênants (fonctionnels)

| ID | Constat | À faire | Taille |
|---|---|---|---|
| FN-001 | CI : 30 scénarios sur 154 | ligne de `ci.yml` (directeur, zone interdite) | S |
| FN-003 | 1 799 minutes affichées | migration de bornage | S |
| FN-004, FN-005, FN-020, FN-021 | scénarios SQL rouges sur `main` | à attribuer | M |
| FN-007 | aperçus Vercel écrivent en production | décision du directeur | — |
| FN-008 | staging en retard depuis le 23/10 | décision du directeur | — |
| FN-009, FN-010 | foyers A et B en production | migration de données, feu vert | S |
| FN-013 | bandeau « nouvelle version » | client | M |
| FN-014 | polices arabes dans `pubspec.yaml` | geste du directeur | S |
| FN-017 | trois langues manquent | décision du directeur | L |
| FN-018 | adaptateur temps réel avale les erreurs | client | S |
| FN-019 | remplaçant absent de `mes_seances_enseignant_v`, `cahier_semaine_depose` | migration | M |
| FN-027 | aucun temps restant sur les cartes de classe | client | M |
| FN-101 | PDF accepté comme pièce | Edge `piece-identite-depot` + client | S |
| FN-102 | signature au nom d'un autre | client + RPC | S |
| FN-103 | classe close pendant sa séance bloque l'enseignant | migration (voir 1.2) | S/M |
| FN-104 | doublon de profil élève non contrôlé | migration + client | M |
| FN-106, FN-107 | Accueil montre une séance annulée de l'ancienne classe ; « Classe non disponible » dans l'historique | migration de lecture + client | M |
| FN-108 | e-mails « eleve_inscrit », « enseignant_affecte » au mauvais public | migration (`notifier_classe`) | S |
| FN-110 | Finance : Vue globale, Réserve, Délégation, reçus famille non branchés | client + serveur | L |
| FN-111 | lien d'e-mail ouvert sur un autre appareil perd le questionnaire | client (+ PKCE) | M |
| FN-112 | rechargement de l'adulte | corrigé PR 125/127, vert en local ; preuve à faire | — |

Finition : FN-012 (sons, décision), FN-015 (36 séances, feu vert), FN-016 (notifications des
mineurs), FN-022 (pile E2E), FN-105.

---

## 5. Inconnu

1. **Quelle invitation a échoué le 01/11** (enseignant, famille importée, candidat ?) et avec quel
   message : non consigné. À demander au directeur en une ligne : « Le 01/11, vous vouliez inviter
   qui : un enseignant, une famille déjà inscrite, ou un candidat ? ».
2. Le texte exact de l'essai du 01/11 (« ne marche pas » + capture) : le journal de
   `PARCOURS-OUVERTURE-2026-11-01.md` est vide.
3. « Un bouton qui ouvre une session pour chaque personne » : sens non établi (2.3).
4. « A3-bis » : introuvable (3).
5. Si le directeur a reçu des captures des trois salles (2.1) : aucune trace dans le dépôt.
6. Production (non lisible ici) : présence des 568 réponses importées en base ; clés Stripe
   (FN-011) ; installation des migrations FN-114a (`20261103700000`, dite « non installée » dans
   `DECISION-NOTIFICATIONS-COURRIEL-2026-11-01.md` §5) et NOTIFS-L6 (fichier
   `20261104700000_notifications_a_faire.sql` ; le message du commit `58f6b7978` dit
   « 20261104500000 », qui est en fait `acces_paye_motif_bourse.sql` ; dite « appliquée par le
   pilote ») ; nombre réel d'e-mails d'attente
   partis (B3.1).
7. Numéro de la PR du lot (A) (`origin/claude/a-tarifs-particuliers`) et son état de revue.
8. Si l'entrée en salle 3 doit passer par la candidature (spec §2.2) ou si le directeur se
   contente de K1 par Dossiers pour la première vague.
