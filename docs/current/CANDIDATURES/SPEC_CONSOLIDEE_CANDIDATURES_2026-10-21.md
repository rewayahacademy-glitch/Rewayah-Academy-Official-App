# Spécification verticale consolidée du module des candidatures (enseignant d'abord)

## 0. Statut, sources, ce que ce document remplace

**Statut :** `spécifié` seulement. Aucune ligne de code, aucune migration, aucun
port n'est écrit par ce document. Rédigé le 21/10/2026, après les 22 réponses du
directeur, puis révisé le même jour après une relecture critique : les corrections
retenues sont intégrées, et ce qui reste à soumettre est en 0.2 bis et 0.3. C'est
le pas 4 de l'ordre de la spécification : arbitrage, puis cette spécification
consolidée, puis maquettes et leur contrôle, handoff, implémentation, recette
(`SPEC §14`).

**À qui il sert.** C'est le seul document à partir duquel le développeur et le
designer construisent. Quand il contredit le contrat proposé (`PORTS`, `BR`), il
s'applique, et le lot qui écrit les ports met le contrat à jour.

| Sigle | Fichier |
| :--- | :--- |
| `SPEC` | `docs/current/CANDIDATURES/REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md` (spec du directeur, v1.0) |
| `REVUE` | `docs/current/CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md` |
| `DEC` | `docs/current/DECISION-CANDIDATURES-2026-10-21.md` (les 22 réponses) |
| `PORTS` | `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md` |
| `BR` | `docs/current/CANDIDATURES/DEPENDANCES_BACKEND.md` (`CAND-BR-01` à `CAND-BR-18`) |
| `MAP` | `docs/current/CANDIDATURES/MAPPAGE_IMPORT_FORMULAIRES.md` |
| `CORR` | `docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md` |
| `M/`, `C/` | `supabase/migrations/`, `docs/current/` |

`DEC:24` renvoie à la ligne 24 du fichier ; `REVUE §8` à sa section.

### 0.1 Ce que ce document remplace

| Document | Ce qu'il devient |
| :--- | :--- |
| `SPEC` | reste la référence du directeur, intacte ; là où elle diffère d'une décision datée du 21/10, ce document applique la décision (0.2) |
| `REVUE` | reste la cartographie de l'existant et des preuves ; ses recommandations d'origine (`§9`) cèdent là où `DEC` répond autrement : plus de WhatsApp sauf l'envoi du lien d'inscription (`DEC:29`), plus de voie 1 pour l'entretien (`§6.3`), plus de « prévenu le » comme canal ordinaire |
| `PORTS`, `BR` | contrat proposé, à mettre à jour par le lot qui écrit les ports, selon la liste ci-dessous |
| `MAP` | §1 : l'import écrit des réponses importées, pas des lignes `recue` (3.2) ; les règles de §4 normalisent aussi le téléphone donné à l'inscription (2.1) |

**Changements à porter dans `PORTS` et `BR` :**
- `geste(confirmer)` disparaît : l'entrée en salle 3 est la validation de la pièce
  dans `ADM-02`, donc plus de confirmation en lot.
- `Geste` gagne `garderPourSuivi` (transition 2) et `rattacher` (rattachement par
  téléphone, transition 27) ; `demanderComplement` vaut aussi en salle 2
  (transition 23).
- `consignerPrevenu` ne constate plus qu'un lien envoyé par WhatsApp (7.4).
- `consignerRetrait` : demande reçue par la conversation ou par courriel, et non
  plus « hors de l'application » (transition 17).
- `inviter` : le code part dans le courriel `invitation` (3.3) ; il ne s'affiche à
  la direction que si le directeur nomme un canal pour l'intervalle (0.3).
- `LigneCandidature`, `Candidature`, `FiltreCandidatures` : état
  `paiement_non_disponible` ; dimensions provenance, cause de restriction et
  affectation (4.1) ; filtre « sans activité depuis N jours » (section 10).
- `EtatEntretien` : `sessionDisponible` et `enCours` fusionnés ;
  `lienIndisponible` devient « inaccessible » (6.2). `EntretienCandidat.mode`
  perd `whatsapp`.
- `CapacitesCandidatures` : `peutImporter` au super-admin seul (3.2) ;
  `peutMenerEntretien` du même côté que le candidat (6.1) ; capacité neuve
  `candidatures.messages` (8.1).
- Un port pour `CAND-04` (inscription sans code) ; la lecture de l'état d'un
  courriel (`a_envoyer`, `envoye`, `echec`, 7.3).
- `CAND-BR-11` : insertion ouverte au compte candidat de la forme fixée en L1,
  invité ou non (3.1).
- `CAND-BR-13` est déclaratif.
- `CAND-BR-15` : six fichiers de scénarios (`scenarios_cand_l1.sql` à
  `scenarios_cand_l6.sql`), et non un seul.
- `CAND-BR-16` devient la file des courriels (7.3).
- `CAND-BR-17` : genre et téléphone avec indicatif obligatoires à l'inscription ;
  clé de mise en ligne (3.1).
- L'import écrit des réponses importées, pas des candidatures (3.2) ; les
  Garanties de `PORTS §2` changent en conséquence.

### 0.2 Où ce document s'écarte de la spec v1

| Spec v1 | Ce document | Source |
| :--- | :--- | :--- |
| Salle 3 : décision finale distincte ; la pièce est un prérequis parmi d'autres (`SPEC §3`) | valider la pièce **est** le geste d'entrée en salle 3 ; le serveur le refuse tant que la salle 2 n'est pas terminée | `DEC:24` |
| Paiement compatible exigé avant la salle 3 (`SPEC §4.1`) | exigé dès l'entrée en salle 2 ; sans moyen, la candidature reste en salle 1, jamais refusée | `DEC:28` |
| Matrice pawaPay, corridors à vérifier (`SPEC §4.4`) | référentiel déclaratif ; hors d'Afrique, Arabie saoudite comprise : virement bancaire ; aucune intégration | `DEC:28` |
| « Rejoindre la visio » (`SPEC §6`) | « Rejoindre l'entretien », dans la salle vidéo de l'app ; lien secondaire sur une ligne | `DEC:29`, `:35`, `:37` |
| Mention de séance non traitée | aucune mention à l'écran pendant l'entretien | `DEC:32` |
| Texte qui nomme les Compagnons, « Je certifie » (`SPEC §5`) | doctrine écrite : « voie d'Ahl as-Sunna », « à la lumière des salafs » ; « Je confirme » | `DEC:34` |
| Import de quelque 400 candidatures (`SPEC §9`) | import ponctuel qui reconnaît et pré-remplit ; la candidature naît à l'inscription par le lien | `DEC:26`, `:40`, `:57-62` |
| Frontend seul (`SPEC §1.2`) | lot serveur borné, base de test seulement | `DEC:25` |
| Ordre obligatoire (`SPEC §14`) | les lots serveur avancent en parallèle des maquettes, sur la base de test seulement | `DEC:25`, `SPEC §12.3`, `C/CANDIDATURES/LIRE_D_ABORD.md:30-32` |
| « Viviers » | mot non affiché ; « Salle des prêts à enseigner » | `DEC:35`, `REVUE §0` point 7 |
| Tri par adéquation et priorité (`SPEC §8.1`) | clés en clair, jamais un score | `DEC:43` |
| Confirmation groupée encadrée (`SPEC §8.2`) | aucune : une pièce se valide une à une | `DEC:24` (conséquence) |
| « Pays d'origine si utile » (`SPEC §3`, salle 1) | non demandé : aucune règle ne le lit, c'est une donnée personnelle de plus sans usage | à soumettre au directeur |
| « Sauvegarde des filtres si une capacité équivalente existe » (`SPEC §8.1`) | non construite | aucune capacité équivalente (`REVUE §3.4`) ; à soumettre au directeur |

### 0.2 bis Où ce document précise ou s'écarte d'une décision, à soumettre au directeur

| Décision | Ce document | Raison |
| :--- | :--- | :--- |
| Les anciennes réponses servent à reconnaître, « même courriel ou même téléphone » (`DEC:58-59`) | téléphone seul : rattachement proposé à la direction, appliqué par un geste journalisé (transition 27) ; rien n'est montré au candidat | aucun canal ne vérifie un téléphone (SMS désactivé, `REVUE §3.6`) ; montrer d'anciennes réponses sur un numéro tapé exposerait les données d'une autre personne |
| Les anciennes réponses servent à pré-remplir (`DEC:58`) | personnes de B : reconnues par courriel confirmé, sans pré-remplissage (3.4) | l'import du 12/10 ne garde que prénom, nom et courriel (`REVUE §3.5`) |
| « Le super admin doit voir les deux côtés » (`DEC:30`) | le super-admin lit les deux côtés ; il ne mène un entretien que du même côté que le candidat | `DEC:30` ne parle que de lecture ; un entretien face à face avec une personne de l'autre genre n'est pas décidé (0.3) |
| Les anciennes réponses « ne créent pas de candidature à leur place » (`DEC:60`) | la direction peut garder une ligne `recue` de suivi (transition 2) | porter l'invitation (`DEC:27`) ou consigner l'envoi du lien par WhatsApp (`DEC:26`) ; choix de mise en oeuvre (3.2) |
| Une seule page d'accords ; l'app « ne renvoie jamais en arrière pour cocher après coup » (`C/DECISION-ENTREE-2026-10-17.md:30-32`) | accords en trois moments : confidentialité à l'inscription, cadre religieux en salle d'examen, contrat et avis en salle 2 ; une version neuve se ré-accepte (4.3) | ne pas demander trop tôt (`SPEC §2.1`) ; contrat et pièce après la salle d'examen : proposition de `REVUE §6.2`, pas une décision |

### 0.3 Ce qui reste ouvert

| Question | Ce qui manque | Qui tranche | Effet tant que c'est ouvert |
| :--- | :--- | :--- | :--- |
| `CAND-Q05` | pays et moyens qui fonctionnent en Afrique (par exemple le mobile money par pawaPay) ; sort d'un candidat qui vit en Afrique et a un compte bancaire (`DEC:80-83`) | directeur | toutes les lignes d'Afrique du référentiel restent `en_verification` : aucun candidat dont le pays de versement est en Afrique n'entre en salle 2 |
| Liste des pays d'Afrique | la liste du référentiel ; c'est elle qui décide qui entre en salle 2 (`DEC:28`) | proposée en L6 avec sa source nommée, puis soumise au directeur avec `CAND-Q05` | même effet que `CAND-Q05` |
| `CAND-Q12` | accord sur les trois noms de salle (`DEC:87-88`) ; forme du côté des femmes pour « Salle des prêts à enseigner », en français et en arabe ; « Salle d'examen » croise « examen de fin des bases », mot du programme (`mots-rewayah` §3) | directeur | les noms proposés sont les valeurs des clés i18n ; un changement ne touche que les textes |
| `CAND-Q21` | durée de conservation, avis du juriste (`DEC:90`) ; base des courriels envoyés avant l'inscription et conservation des réponses importées de qui ne s'inscrit pas (8.4) | directeur, après le juriste | aucune purge automatique des candidatures ; `CAND-BR-14` n'est pas commencé |
| Super-admin intervieweur | le super-admin peut-il mener l'entretien d'une personne de l'autre côté ? | directeur | refus : l'intervieweur est du même côté que le candidat, super-admin compris |
| Ligne `recue` de suivi | confirmation du choix de mise en oeuvre (3.2) | directeur | le geste « garder pour suivi » s'écrit en L3 sur la base de test ; il ne s'ouvre pas en production sans réponse |
| Canal du code d'invitation | tant que l'envoi de la file manque (7.3), par où la direction transmet-elle un code ? WhatsApp est exclu hors lien d'inscription (`DEC:29`) | directeur | aucune invitation n'est émise en production |
| Accords en trois moments | l'écart à la page unique (0.2 bis) | directeur | L2 suit ce document sur la base de test ; rien en production |
| Pays de la carte publique | recopier le pays de résidence déclaré dans `teacher_profiles.country`, public sur la carte (`C/ENS-PAYS-1_BR.md:3`) ? | directeur | non recopié ; l'enseignant le pose dans son profil, comme aujourd'hui (2.2) |
| Personne de B sans courriel | 1 personne (`REVUE §2.4`), sans réponse importée ni ligne : où consigner l'envoi du lien par WhatsApp ? | L3, puis directeur si un geste neuf est nécessaire | l'envoi n'est pas consigné dans l'app |
| Durée de conservation des pièces | point de départ : dépôt (aujourd'hui) ou décision (4.1) | directeur | `purge_at` vaut dépôt plus 90 jours ; aucune purge programmée |
| Forme de `teacher_id` pour la séance d'entretien | `teacher_id` est obligatoire aujourd'hui (6.1) | L4 | L4 n'écrit pas ses scénarios sans elle |
| `ff` et `poular` | équivalence du peul et du poular (`MAP §3.2`, section 9) | directeur | `ff` s'importe hors référentiel |
| Forme en base du compte candidat | rôle et `account_status`, les mêmes pour les deux portes (3.1) | L1, sans question au directeur | L2 ne s'écrit pas |

L'écran du référentiel va dans Finance, sauf avis contraire (`DEC:85`).

Les points à trancher par le directeur (sections 0.2, 0.2 bis et 0.3) lui sont
posés dans la page d'arbitrage comme questions de suivi `CAND-S01` à `CAND-S11`.
Ses réponses s'y enregistrent comme les 22 premières.

---

## 1. Périmètre et principes

1. **Moteur générique, option C** (`REVUE §6.1`) : une candidature porte un
   **type** ; le type désigne un jeu d'étapes **fermé** et une liste de
   **contrôles nommés**, calculés en base ; les réponses sont un document versionné
   par questionnaire. Ni constructeur de formulaires, ni pipeline codé pour le
   seul enseignant.
2. **Le type `enseignant` d'abord.** Aucun autre type sans décision ; une fixture
   `comptable` prouve en SQL qu'un type ne touche pas l'autre (`SPEC §2.2`, `§13`).
3. **Une candidature ne crée jamais un compte actif par elle-même.** Seule la
   validation de la pièce, en fin de salle 2 et sous la garde du serveur, fait
   d'un candidat un enseignant actif (`DEC:24`, `:50-51`). Elle ne valide jamais une
   pièce et ne signe jamais un accord au nom de la personne.
4. **Tout droit se décide en base.** L'écran lit des capacités et l'état rendu par
   le serveur, ne recalcule rien, ne lit jamais un rôle
   (`C/02_ARCHITECTURE_ET_SECURITE.md:19`).
5. **Pas de seconde source de vérité** (`REVUE §5.1`). Sont réutilisés :
   invitation et parcours d'inscription (`/inscription`, `UsageEtape`,
   `InvitationCandidatPage`) ; accords ; pièce et `ADM-02` ; `/attente` et
   `etat_dossier()` ; messagerie métier ; `notifications` ; `audit_logs` ; motif
   d'import du 12/10 et réclamation après preuve du courriel
   (`reclamer_preinscription_apres_preuve()`) ; table des pays
   `lib/core/i18n/pays_iso.dart` ; `BarreSelection` (promue) ; salle vidéo
   `/salle`.
6. **Hors périmètre** : intégration d'un prestataire de paiement (`DEC:28`), envoi
   de courriels (`DEC:33`), refonte LiveKit, production sans feu vert (`DEC:25`),
   les cinq défauts hors module (section 13).

---

## 2. Le parcours en salles

Les salles sont des **étapes de recrutement**, jamais des communautés : aucun
candidat ne voit un autre candidat (`SPEC §15` point 2). Les codes restent
internes ; seuls les noms s'affichent, toujours en entier (noms proposés,
`CAND-Q12`). Dans ce document, « salle 1 », « salle 2 » et « salle 3 » sont des
raccourcis internes, jamais affichés.

| Code d'étape | Nom affiché | Objet |
| :--- | :--- | :--- |
| `recue` | aucun (vue de la direction) | ligne gardée par la direction pour suivre une personne des formulaires ; pas encore de compte (choix à confirmer, 0.2 bis) |
| `invitee` | aucun (vue de la direction) | invitation émise, pas encore consommée |
| `prequalification` | **Salle d'examen** | savoir si la candidature mérite les vérifications, et si l'académie peut payer |
| `verifications` | **Salle de vérification et d'entretien** | vérifier, rencontrer, réunir les accords et la pièce |
| `confirmee` | **Salle des prêts à enseigner** | compte actif, affectable |

### 2.1 Ce qui se demande, à quel moment

Mise à jour de `REVUE §6.2` par `DEC:28`, `:34`, `:45`, `:63-64`.

| Moment | Demandé | Jamais avant |
| :--- | :--- | :--- |
| Inscription (lien public ou code) | courriel confirmé, nom affiché, genre (obligatoire en base, 3.4), téléphone avec indicatif (indicatif choisi dans une liste, normalisé selon `MAP §4`), langue de l'interface (`fr` ou `ar`), accord de confidentialité | - |
| Salle d'examen | langue maternelle et langues d'explication (codes) ; niveau de mémorisation déclaré ; niveau de lecture et de tajwid déclaré ; riwaya ; ijaza présentable oui ou non ; expérience avec les débutants ; disponibilités déclarées (créneaux et fuseau) ; heures par semaine ; date de début ; publics enseignables ; pays de résidence ; pays de versement ; fuseau IANA ; compte bancaire oui ou non ; opérateurs accessibles ; accord de rémunération ; cadre religieux et pédagogique | - |
| Salle de vérification et d'entretien | contrat `teacher_nda`, avis `recording_and_control_notice`, pièce d'identité ; à l'entretien : constat (niveau observé, riwaya, ijaza présentée), compte rendu, avis | salle d'examen terminée et paiement compatible |
| Après l'entrée en salle 3 | photo, titre, pays de la carte, `weekly_availability` ; code de conduite tant que le lot `conduite` n'est pas passé (section 13) | l'entrée en salle 3 |
| Premier versement | coordonnées financières, par `CPT-13` | salle 3 et début des cours |

Le téléphone n'est lu que par `candidatures.contact`, jamais dans une liste (8.3).
Il sert au rattachement (3.4) et à `profil_unique` (section 5). Sans lui, une
personne des formulaires qui crée un courriel neuf (`DEC:54-56`) ne serait jamais
reconnue, et un candidat refusé reviendrait sous un autre courriel sans être vu.

Ijaza, diplôme et attestation se **présentent à l'entretien** et se constatent
dans le compte rendu ; aucun dépôt dans l'app pour l'instant (`DEC:45`).

La page d'accords existante montre les textes requis **à l'étape courante** : le
cadre religieux en salle d'examen, le contrat et l'avis en salle 2. Elle garde
la règle « une case par texte, un seul bouton Suivant »
(`C/DECISION-ENTREE-2026-10-17.md:30-31`). Le découpage en trois moments s'écarte
de la page unique de cette décision ; il vient de `SPEC §2.1` et d'une proposition
de `REVUE §6.2`, pas d'une décision (0.2 bis).

### 2.2 Les trois salles

| | Salle d'examen (`prequalification`) | Salle de vérification et d'entretien (`verifications`) | Salle des prêts à enseigner (`confirmee`) |
| :--- | :--- | :--- | :--- |
| **Qui entre** | toute personne inscrite par le lien public ou une invitation consommée, de tout pays (`DEC:28`) | la candidature admise par la direction, cadre religieux accepté et paiement compatible (4.2, ligne 10) | seule la validation de la pièce dans `ADM-02`, acceptée quand les sept autres contrôles sont vrais (section 5) : « affectable à 100 % » (`DEC:24`), une fois les lots `langue` et `c11bis` passés (section 11) |
| **Le candidat voit** | `/attente` étendu et `CAND-01` : d'abord les conditions de rémunération, lues au serveur, jamais écrites en dur (`CAND-BR-12`) ; le questionnaire en cartes, choix dans des listes ; la case du cadre religieux ; son état ; sa conversation | la page d'accords (contrat, avis) ; le dépôt de pièce existant (`supabase/functions/piece-identite-depot/index.ts`) et son état (« à corriger » avec quoi) ; « Mon entretien » (`CAND-02`) ; ce qui lui est demandé en complément ; sa conversation | son espace enseignant ; `/attente` ne le retient plus ; les prérequis de travail existants (`M/20261016100500_contrats_travail_prerequis.sql:49-74`) |
| **La direction voit** | `ADM-20` filtré sur la salle ; `ADM-21` : réponses, déclaration de paiement, contrôle `paiement_compatible` | la vue Entretiens d'`ADM-20` ; dans `ADM-21`, les huit contrôles (vrai ou faux, cause) et le lien vers `ADM-02` | le filtre de la salle, affectée ou non ; les alertes « bloquées » et « confirmées indisponibles », jamais confondues |
| **Gestes** | demander un complément ; confirmer ou infirmer le moyen de paiement ; admettre en Salle de vérification et d'entretien ; pause ; refus | demander un complément ; planifier, consigner, reprogrammer l'entretien ; pièce à corriger ; valider la pièce ; pause ; refus | restreindre, lever la restriction ; noter ou lever une indisponibilité |
| **Sorties** | salle 2 ; à compléter ; maintenue faute de moyen de paiement (jamais un refus, libre de partir) ; refusée ; retirée ; pause | salle 3 ; à compléter (transition 23) ; entretien à replanifier ; pièce à corriger ; refus (dont refus définitif de pièce) ; retrait ; pause | jamais de retour d'étape ; restriction (manuelle, ou automatique quand un contrôle tombe) ; indisponibilité ; l'historique reste |

**Entrée en salle 3, dans une seule transaction :**
- pièce `approved` et `teacher_profiles.kyc_status = 'approved'` (déjà posé par
  `decider_dossier()`,
  `M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:63-65`) ;
- langues (codes) et fuseau IANA copiés des réponses vers
  `teacher_profiles.languages` et `teacher_profiles.timezone_iana` ;
- genre non nul vérifié ;
- compte `active` sous la garde d'activation étendue (4.3) ;
- candidature `confirmee` ; profil enseignant unique.

L'affectation exige une pièce approuvée, la langue de la classe dans
`teacher_profiles.languages` et un genre connu (`M/0082_teachers_for_class.sql:54-66`).
Une fiche vide, comme celle que crée l'inscription aujourd'hui
(`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`),
n'est affectable à aucune classe dont la langue est renseignée. Les langues ne se
recopient en codes qu'après le lot `langue` (section 13).

Le pays de résidence n'est pas recopié dans `teacher_profiles.country`.
L'affectation ne le lit pas ; cette colonne est publique sur la carte de
l'enseignant (`C/ENS-PAYS-1_BR.md:3`) et porte un nom, pas un code (`:9`).
L'enseignant le pose dans son profil avec les prérequis de travail
(`M/20261016100500_contrats_travail_prerequis.sql:70`) ; question en 0.3.

Le refus d'une nouvelle pièce d'une enseignante déjà active **ne change pas** :
`disabled` sans autre pièce approuvée
(`M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:51-60`, `DEC:24`) ;
la candidature trace une restriction « pièce », levée par la transition 21.

---

## 3. Entrées

### 3.1 Le lien public (`CAND-Q03`, `CAND-Q17`)

Un lien partageable, sur la page « recrutement » du site public, ouvre le
parcours d'inscription existant, étendu d'une entrée sans code (`CAND-04`). C'est
l'entrée ordinaire après l'import ; plus d'imports périodiques (`DEC:26`, `:40`).
Il rouvre une entrée publique fermée depuis le 17/10
(`C/DECISION-ENTREE-2026-10-17.md`) : les six conditions de `DEC:49-66` deviennent
des règles.

| # | Condition (`DEC`) | Règle | Lot |
| :-- | :--- | :--- | :--- |
| 1 | Compte candidat seulement (`:50-51`) | l'inscription crée un compte `pending_kyc` confiné à `/attente` et une candidature `prequalification/a_completer` de type `enseignant`. **Refusé** : jeton de cours, affectation, prérequis de travail, présence dans une liste d'enseignants. **Permis** : accords de l'étape, dépôt de pièce en salle 2, fil `candidature`. Aujourd'hui `inscrire_enseignant_invite` crée un profil `teacher` `pending_kyc` avec une fiche `teacher_profiles` vide (`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`) ; le dépôt de pièce (policy `kyc_staff_self_insert`, `M/0004_inscription_kyc_appairage.sql:169-174`), la garde `0089` (`NEW.role = 'teacher'`) et la policy du code de conduite (`CORR §7`) sont réservés au rôle `teacher`. L1 fixe donc la forme en base (rôle et `account_status`), la même pour le lien public et l'invitation, avant que L2 ne s'écrive | L1 (forme), L3 |
| 2 | Contre les robots (`:52-53`) | la candidature n'existe qu'après confirmation du courriel (aujourd'hui `enable_confirmations = false`, `supabase/config.toml:229`) ; plafond d'inscriptions par heure dans `app_config`, refus neutre au-delà : la réponse est la même qu'en cas de succès (`CAND-04`) ; la limite par adresse IP reste (`sign_in_sign_ups = 30` par 5 minutes, `config.toml:210`) ; captcha possible (`config.toml:216-219`) | L3 |
| 3 | Courriel obligatoire (`:54-56`) | l'app se connecte par courriel (`lib/core/auth/service_auth.dart:52-56`) : pas de courriel, pas d'inscription ; le message WhatsApp aux personnes sans courriel leur dit d'en créer un | L3 |
| 4 | Personnes des formulaires (`:57-62`) | reconnues et pré-remplies (3.4) ; aucune candidature créée à leur place ; tout le monde complète pays, paiement et cadre religieux | L3 |
| 5 | Confidentialité (`:63-64`) | accord de confidentialité versionné, accepté à l'inscription, enregistré avec version et date | L3 |
| 6 | Mise en ligne (`:65-66`) | une clé `app_config` (nom fixé en L3), fausse par défaut : tant qu'elle est fausse, l'inscription sans code est refusée en base. Le lien ne va sur le site, et la clé ne passe à vrai, qu'une fois L1 à L3 livrés, le SMTP d'authentification en production avec `enable_confirmations = true` (7.3, dépendance 1), et le feu vert du directeur | L3 (clé) |

### 3.2 L'import ponctuel des formulaires Google

**Ponctuel** (`DEC:40`) : pour les seules personnes des formulaires, jamais
périodique. Un fichier corrigé se rejoue ; l'import reste idempotent et la
correction s'inscrit sur la même référence source (`REVUE §7` point 6,
`PORTS §2`, `SPEC §8.3`). Même motif serveur que l'import du 12/10 : analyse au
serveur, essai à blanc, confirmation idempotente, aal2 exigée **en base**, journal
portant la référence source (classeur, onglet, horodatage), jamais le nom
(`REVUE §7`).

**Réservé au super-admin.** Le fichier A mêle les deux côtés (351 hommes et
89 femmes, `REVUE §2.3`) ; l'aperçu, les doublons et le rapport ligne par ligne
montrent noms et réponses. Une directrice qui importerait lirait les lignes des
hommes, contre la portée de 8.2. Le super-admin lit déjà les deux côtés
(`DEC:30`).

| Source | Traitement |
| :--- | :--- |
| A1 et A2 (questionnaire arabe, 14 colonnes) | importées : 440 lignes, 409 personnes après rapprochement des doublons de A (`MAP §6`) |
| B (« Enseignants (Réponses) », 11 lignes) | `dejaConnue`, rien n'est écrit : déjà dans l'import du 12/10 (`MAP §1`) ; reconnue à l'inscription par 3.4 |
| Liens Drive vers des photos d'identité | jamais importés |

**Ce que l'import écrit** : des **réponses importées**, une par référence source,
qui servent à reconnaître et à pré-remplir (3.4). Ni compte, ni invitation, ni
pièce, ni accord, ni candidature à la place de la personne (`DEC:60`).
**Choix de mise en oeuvre, à confirmer par le directeur** : pour porter
l'invitation (`DEC:27`) ou consigner l'envoi du lien par WhatsApp (`DEC:26`), la
direction peut garder une ligne `recue` (transition 2). C'est une ligne de suivi,
pas une candidature déposée : elle n'entre en salle d'examen que quand la personne
s'inscrit et y est rattachée (0.2 bis, 0.3).

**Les huit pas d'`ADM-23`** (`SPEC §9`, `REVUE §7`) : (1) dépôt d'un export CSV,
sans connexion à l'API Google ; (2) aperçu, contacts masqués ; (3) association des
colonnes sur en-têtes normalisés, avec la table des libellés (`MAP §2`, `§3`) ;
(4) doublons probables et lignes incomplètes ; (5) erreurs et avertissements ligne
par ligne ; (6) quatre compteurs (nouvelles, déjà connues, ignorées, à corriger),
un écart avec les comptes de référence se lit avant de confirmer ;
(7) confirmation idempotente ; (8) rapport final ligne par ligne, sans nom.

| Donnée (`MAP §4`, `§5`) | Règle |
| :--- | :--- |
| Doublon | clé courriel **ou** téléphone normalisés, jamais le nom ; la ligne la plus récente est proposée, les autres restent en historique (`DEC:39`) ; le super-admin choisit par groupe, un groupe sans choix reste « à corriger » |
| Téléphone, courriel | téléphone jamais complété ni deviné, sinon « indicatif à confirmer » ; courriel absent ou mal formé : « courriel à obtenir », ni clé ni adresse d'invitation |
| Créneaux | heure locale et fuseau `Asia/Riyadh` gardés, jamais convertis, jamais recopiés dans `weekly_availability` (`C/02_ARCHITECTURE_ET_SECURITE.md:23`) |
| Réponses contradictoires (24 lignes) | importées telles quelles, avec avertissement |
| Ligne « à corriger » | corrigée dans le classeur, puis fichier rejoué : 0 réponse nouvelle, la correction tracée sur la même référence source |

### 3.3 L'invitation, une étape (`CAND-Q04`)

L'onglet Invitations de Personnes devient « Candidatures » (`ADM-20`) : pas de
septième onglet, une seule liste par personne (`DEC:27`,
`lib/core/admin/admin_domaine.dart:266-293`).

| Cas | Règle |
| :--- | :--- |
| Ligne `recue` au courriel valide | le serveur émet l'invitation existante (`inviter_enseignant`, code lié au courriel, 14 jours, `M/20261016100300_contrats_invitations_enseignant.sql:111-161`) et écrit un courriel à envoyer (modèle `invitation`, 7.3). Le code est un paramètre de ce seul modèle, lu par la seule fonction d'envoi. Le lien mène au parcours d'inscription existant et peut porter le code, comme aujourd'hui (`lib/core/router/app_router.dart:323-326`) |
| Tant que l'envoi n'existe pas | **aucune invitation n'est émise en production**, sauf canal nommé par le directeur pour l'intervalle (0.3). Dans ce cas seulement, la direction voit le code comme aujourd'hui (`lib/features/admin_invitations/invitations_page.dart:128-129`), et l'écran dit « Courriel pas encore envoyé » |
| Sans courriel valide | `courrielAbsent` ; la direction envoie le lien public par WhatsApp, hors de l'app, et le consigne (7.4, transition 26) |
| Expiration à 14 jours | retour en `recue`, trace gardée, réinvitation possible |
| Invitation consommée ou lien public | **même compte et même candidature** ; seule la provenance diffère |
| Reprise (L3) | invitations déjà émises : lignes `invitee` ; comptes `pending_kyc` nés d'une invitation : candidature en `prequalification/a_completer`, accords signés et pièce déposée gardés |

Le modèle `lien_inscription` ne part jamais par courriel : c'est le modèle du
message WhatsApp consigné (7.4). Une personne des formulaires qui a un courriel
valide reçoit une invitation.

### 3.4 Reconnaissance et pré-remplissage

| Correspondance | Effet |
| :--- | :--- |
| même courriel qu'une réponse importée, **confirmé** à l'inscription | rattachement automatique ; pré-remplissage du questionnaire, à relire ; une ligne `recue` éventuelle devient cette candidature |
| même téléphone qu'une réponse importée, seulement (téléphone donné à l'inscription, 2.1) | rien n'est montré à la personne ; rattachement **proposé à la direction**, appliqué par un geste journalisé (transition 27), puis pré-remplissage |
| personne de B (déjà dans l'import du 12/10) | courriel confirmé égal à `private.preinscription_households.email_normalise` d'une personne `teacher` (`PORTS §2`), sur le modèle de `reclamer_preinscription_apres_preuve()` (`M/20261012185327_imm_accueil_reclamation_apres_preuve_email.sql`) : reconnue et rattachée, sans pré-remplissage (l'import du 12/10 ne garde que prénom, nom et courriel, `REVUE §3.5`) |
| nom seul | jamais |

Le téléphone ne suffit pas : aucun canal ne le vérifie (SMS désactivé,
`REVUE §3.6`). Montrer d'anciennes réponses sur un numéro tapé exposerait les
données d'une autre personne. C'est un écart à `DEC:58-59`, porté en 0.2 bis.

La personne de B sans courriel (`REVUE §2.4`) n'a ni réponse importée ni ligne :
l'envoi du lien par WhatsApp n'a pas où se consigner (0.3).

Pré-remplis : colonnes C et E à L de A (`MAP §2`). Jamais pré-remplis : pays,
fuseau, publics, paiement, cadre religieux, riwaya, niveau de lecture et de
tajwid.

**Le genre.** Le genre déclaré à l'inscription est écrit dans `profiles.gender` à
la création du profil, par le même chemin qu'aujourd'hui
(`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:169`).
Ensuite seule la direction le change (`af_l1_07`,
`M/20261017100700_af_l1_07_genre_colonne_privilegiee.sql:27`, déclencheur
`before update`, `M/0001_fondations.sql:558-560`). Pour la porte candidat, il est
obligatoire en base : sans lui, l'inscription est refusée, sinon le dépôt de
pièce échoue (`M/0004_inscription_kyc_appairage.sql:145-147`). Aujourd'hui
`p_gender` vaut `NULL` par défaut (`af_l1_11:134`). Le genre fixe la portée de
lecture dès la première ligne.

---

## 4. États, transitions et règles de blocage

### 4.1 Dimensions

| Dimension | Valeurs | Porté par |
| :--- | :--- | :--- |
| Étape | `recue`, `invitee`, `prequalification`, `verifications`, `confirmee` | candidature |
| État dans l'étape | salle 1 : `a_completer`, `en_examen`, `paiement_non_disponible` ; salle 2 : `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente` | candidature |
| Issue | `en_cours`, `refusee`, `retiree` (terminales, réouvrables par geste motivé) | candidature |
| Pause | drapeau, motif interne, modèle de message, reprise facultative | candidature |
| Restriction | drapeau, cause (`piece`, `paiement`, `manuelle`), motif ; après la salle 3 | candidature |
| Indisponibilité | drapeau, « jusqu'au » facultatif ; après la salle 3 | candidature |
| Provenance | `lien_public`, `invitation`, `import` | candidature |
| Responsable | membre de la direction, du même côté, facultatif, changé par geste journalisé (transition 28) | candidature |
| Pièce | lue dans `kyc_documents`, jamais recopiée ; deux issues de refus : `a_corriger`, refus définitif (`DEC:41`) | existant, étendu |
| Paiement | `inconnu`, `a_verifier`, `compatible`, `incompatible`, calculé (5.1) | réponses et référentiel |
| Entretien | état (6.2) ; issue `tenu`, `annule`, `manque_candidat`, `manque_intervieweur` | entretien |
| Affectation | lue dans les classes (`groupes.teacher_id`), jamais recopiée ; « déjà affectée » reste distinct de « confirmée », « active » et « disponible » (`SPEC §2.3`) | existant |
| Courriel | `a_envoyer`, `envoye`, `echec` | file des courriels |
| Coordonnées financières | `absentes`, `enregistrees` ; jamais exigées avant le premier versement | `CPT-13` |

Une pièce n'expire pas tant qu'aucune date de validité n'est saisie (`DEC:41`).
`purge_at` vaut dépôt plus `kyc_retention_days` (90 jours,
`M/0004_inscription_kyc_appairage.sql:117`, `:136-139`) ; aucune purge n'est
programmée aujourd'hui. Quand elle le sera, elle efface le fichier et garde la
décision (`status`), que lit `piece_validee`. Sinon, une pièce déposée tôt en
salle 2 atteindrait `purge_at` avant la fin de l'entretien, et chaque enseignant
passerait en restriction. Le point de départ de la durée (dépôt ou décision) est
en 0.3.

### 4.2 Transitions

Chaque transition passe par une RPC qui vérifie la règle en base, exige le motif
quand la colonne le dit, prend `versionAttendue` et `cleIdempotence`, rend
`TransitionInterdite` depuis un état qui ne le permet pas, et journalise ancien
état, nouvel état, auteur, horodatage et motif. « Direction » veut dire la
capacité `candidatures.decider`, dans la portée de genre (section 8). Les
numéros 1 à 22 ne changent pas ; les lignes 23 à 28 sont ajoutées à la révision.

| # | De | Vers | Qui | Vérifié en base | Motif |
| :-- | :--- | :--- | :--- | :--- | :--- |
| 1 | import confirmé | réponses importées | super-admin (`candidatures.importer`) | aal2 ; référence source unique ; rien d'autre n'est écrit | non |
| 2 | réponses importées | `recue` | direction (« garder pour suivi », choix à confirmer, 0.2 bis) | une ligne par référence ; aucun compte | non |
| 3 | `recue` | `invitee` | direction, ligne ou lot | courriel valide ; aucun compte existant ; `inviter_enseignant` ; un courriel `a_envoyer` (modèle `invitation`, code en paramètre) ; en production, fermé tant que l'envoi manque (3.3) | non |
| 4 | `invitee` expirée | `recue` | automatique | la trace de l'invitation reste | non |
| 5 | rien, `recue` ou `invitee` | `prequalification/a_completer` | la personne, en s'inscrivant | courriel confirmé ; accord de confidentialité à la version courante ; genre non nul ; téléphone avec indicatif ; plafond horaire ; sans code : clé de mise en ligne vraie (3.1) ; aucune autre candidature en cours du même type pour ce compte ; rattachement selon 3.4 | non |
| 6 | `a_completer` | `en_examen` | le candidat (envoi) | questionnaire complet à la version courante ; accord de rémunération ; cadre religieux à la version requise | non |
| 7 | `en_examen` | `a_completer` | direction | éléments manquants nommés au candidat | **oui** |
| 8 | `en_examen` | `paiement_non_disponible` | automatique | aucun moyen déclaré ne croise une ligne `confirme` du pays de versement ; ou moyen infirmé par la direction (25) ; ou ligne qui quitte `confirme` (5.1) ; cause tracée | non |
| 9 | `paiement_non_disponible` | `a_completer` | automatique | une ligne du pays passe `confirme` ; « moyen de paiement à déclarer » nommé ; notification et courriel | non |
| 10 | `en_examen` | `verifications/entretien_a_planifier` | direction (« admettre en Salle de vérification et d'entretien ») | `paiement_compatible` vrai ; cadre religieux à la version requise ; questionnaire complet | non |
| 11 | `entretien_a_planifier` | `entretien_planifie` | direction | début UTC futur, durée ; intervieweur de la direction, du même côté que le candidat, super-admin compris (0.3) ; fuseau du candidat connu ; séance `entretien` créée ; notification et courriel | non |
| 12 | `entretien_planifie` | `entretien_a_planifier` | direction | issue `annule`, `manque_candidat` ou `manque_intervieweur` gardée ; séance annulée | **oui** |
| 13 | `entretien_planifie` | `decision_en_attente` | l'intervieweur désigné | issue `tenu` ; compte rendu ; constat (niveau observé, riwaya, ijaza présentée) ; avis | non |
| 14 | `decision_en_attente` | `confirmee` | direction, en **validant la pièce** dans `ADM-02` | les sept autres contrôles vrais (section 5), sinon `ControlesNonSatisfaits` nommés et rien n'est écrit ; validation, activation sous la garde et entrée en salle 3 en une transaction (2.2). La règle ne vaut que pour un profil porteur d'une candidature `enseignant` ; les autres profils, tuteur compris, gardent l'approbation actuelle (`af_l1_05:47-50`) | non |
| 15 | `verifications`, tout état | même état, pièce `a_corriger` | direction (`ADM-02`) | ce qui est à corriger dit par modèle ; le candidat redépose | **oui** |
| 16 | toute étape en cours | `refusee` | direction | motif interne et modèle de message ; le refus définitif de pièce (pièce fausse, identité discordante) y mène ; entretien planifié annulé | **oui** |
| 17 | toute étape en cours | `retiree` | le candidat (`CAND-03`) ; ou la direction, pour une demande reçue par la conversation ou par courriel | entretien planifié annulé, son issue reste ; canal et date tracés | **oui** si direction |
| 18 | tout état | pause posée ou levée | direction | l'étape ne change pas ; modèle de message à la pose | **oui** à la pose |
| 19 | `refusee`, `retiree` | étape et état d'origine | direction (« rouvrir ») | contrôles de l'étape revérifiés, sinon `ControlesNonSatisfaits` ; questionnaire à la version courante | **oui** |
| 20 | `confirmee` | `confirmee` + restriction | direction, ou automatique quand un contrôle tombe (ligne du référentiel, nouvelle pièce refusée) | sort de l'affectabilité : le prédicat d'affectation la lit (4.3) ; étape et historique gardés | **oui** |
| 21 | `confirmee` + restriction | `confirmee` | direction | contrôles revérifiés. Lever une restriction `piece` exige une nouvelle pièce `approved` et remet le compte de `disabled` à `active` sous la garde étendue, dans la même transaction | **oui** |
| 22 | `confirmee` | indisponibilité notée ou levée | direction | étape inchangée ; le prédicat d'affectation la refuse (4.3) ; comptée à part | non |
| 23 | `verifications`, tout état | même état, complément demandé | direction (`demanderComplement`) | éléments manquants nommés au candidat ; la candidature compte dans « informations manquantes » | **oui** |
| 24 | `en_examen`, paiement `a_verifier` | paiement `compatible` | direction (`confirmerMoyenPaiement`) | méthode et opérateur déclarés croisent une ligne `confirme` du pays de versement ; une ligne `en_verification` ne se confirme jamais | non |
| 25 | `en_examen`, paiement `a_verifier` ou `compatible` | paiement `incompatible` | direction (`infirmerMoyenPaiement`) | moyen nommé ; la transition 8 suit | **oui** |
| 26 | `recue` sans courriel valide | même étape, lien envoyé consigné | direction (`consignerPrevenu`), ligne ou lot | canal `whatsapp`, modèle `lien_inscription`, date ; jamais un texte libre (7.4) | non |
| 27 | `prequalification/a_completer` et réponses importées proposées | réponses rattachées | direction (`rattacher`) | proposition existante (même téléphone normalisé, 3.4) ; réponses rattachées à aucune autre candidature ; pré-remplissage ensuite | non |
| 28 | toute étape en cours | responsable posé ou retiré | direction (`definirResponsable`) | membre de la direction, du même côté que le candidat | non |

Une sortie décidée par la direction sans demande du candidat est un **refus
motivé**, jamais un retrait. Le candidat ne voit jamais le motif interne, seulement
le texte du modèle (`PORTS §5` point 4). **Gestes groupables** (`ADM-22`) :
inviter, mettre en pause, lever la pause, refuser, consigner le lien envoyé par
WhatsApp. Tout autre geste rend `GesteNonGroupable`.

### 4.3 Règles de blocage

**Refusés en base :**
- entrer en salle 2 sans `paiement_compatible` ou sans cadre religieux ;
- entrer en salle 3 avec un contrôle faux. La garde
  `guard_teacher_activation_signatures()`
  (`M/0089_teacher_contract_activation_guard.sql:24-82`), étendue aux contrôles,
  joue vers `active` **et** vers `provisional_active` : sa condition (`:38-41`) et
  sa clause `WHEN` (`:81`) sont élargies. Aujourd'hui elle ne joue que vers
  `active`, alors que l'affectation accepte `provisional_active`
  (`M/0082_teachers_for_class.sql:60`) ; `CORR §7` le note déjà pour le contrat.
  Elle joue sur toute activation, `decider_dossier()` compris ;
- affecter une personne en restriction ou indisponible : le prédicat d'affectation
  la refuse, sans changer son étape ; un enseignant sans candidature n'est pas
  touché. Ce prédicat est celui que centralise le lot `creer_groupe`
  (`app_private.verifier_affectation_enseignant`, `CORR §0 bis`), lu par
  `tc_verifier_affectation_enseignant` et `creer_groupe` ;
- s'inscrire sans genre, sans téléphone, ou sans code quand la clé de mise en
  ligne est fausse (3.1) ;
- inviter une ligne sans courriel valide ; importer sans être super-admin, ou
  ailleurs qu'en réponses importées ; exposer une pièce, un contact ou un genre
  dans une liste ;
- planifier sans fuseau connu ou avec un intervieweur hors portée (de l'autre
  côté, super-admin compris) ; donner un jeton d'entretien à un autre que le
  candidat convoqué et l'intervieweur ;
- pendant une pause, tout geste autre que lever la pause, refuser ou retirer.

**Ne rétrograde jamais** : une indisponibilité, une pause, un critère ou une
version de questionnaire changés après une décision, un contrôle qui tombe après la
salle 3 (il pose une restriction, `PORTS §5` point 2). En salle 2, un contrôle qui
tombe bloque l'entrée en salle 3 et compte dans « bloquées », sans retour en
salle 1 ; si `profil_renseigne` devient faux, la direction demande le complément
(transition 23). **Nouvelle version d'un texte** : les candidatures en cours la
ré-acceptent avant la salle 3 ; les personnes en salle 3 gardent la leur
(`REVUE §11`).

---

## 5. Les huit contrôles nommés

Une seule fonction en base (nom indicatif `private.candidature_controles`) les
calcule. Elle est lue par `ADM-21`, par la validation de pièce et par la garde
d'activation. Chaque bascule est journalisée avec sa cause (décision `ADM-02`,
ligne du référentiel, entretien consigné). Un autre type porte sa propre liste.

| Contrôle | Vrai quand | Lu dans | Exigé pour |
| :--- | :--- | :--- | :--- |
| `paiement_compatible` | un moyen déclaré, confirmé par la direction, croise une ligne `confirme` du pays de versement | réponses et référentiel (L6) | salle 2 et salle 3 |
| `accords_signes` | contrat `teacher_nda`, avis `recording_and_control_notice` et cadre religieux acceptés aux versions requises ; plus `teacher_conduct_code` dès le lot `conduite` (section 13) | `contract_acceptances`, `contract_required_versions` | cadre : salle 2 ; tous : salle 3 |
| `profil_renseigne` | langues (codes), niveau déclaré, publics, fuseau IANA, disponibilités déclarées avec leur fuseau, pays de résidence et de versement | réponses ; jamais `weekly_availability`, écrit par un enseignant actif seulement | salle 3 |
| `entretien_conclu` | un entretien `tenu`, compte rendu enregistré, avis favorable, mené par un intervieweur autorisé de ce côté | entretiens (L4) | salle 3 |
| `evaluation_validee` | constat structuré présent : niveau observé, riwaya, ijaza présentée ou non (`DEC:31`, `:45`) | constat de l'entretien | salle 3 |
| `profil_unique` | aucun autre compte ni candidature en cours du même type pour la même personne (courriel confirmé, téléphone normalisé donné à l'inscription) sans décision de la direction ; aucun profil enseignant déjà actif | profils, candidatures | salle 3 |
| `aucune_restriction` | ni restriction ni pause active | candidature | salle 3 |
| `piece_validee` | pièce `approved` | `kyc_documents` | c'est le geste d'entrée en salle 3 ; refusé tant qu'un des sept autres est faux (`DEC:24`) |

La décision finale humaine de la spec (`SPEC §3`) est cette validation, prise après
l'entretien. Un avis défavorable laisse `entretien_conclu` faux ; la direction
refuse alors avec motif.

### 5.1 Compatibilité de paiement (`CAND-Q05`)

**Un référentiel déclaratif** : il dit, pays par pays, quel moyen fonctionne, sans
rien verser ni appeler aucun prestataire (`DEC:28`). Une ligne : pays (ISO 3166),
méthode (`virement_bancaire`, `mobile_money`), opérateur, prestataire (une
colonne, `lib/core/capacites/port_capacite_payout.dart:5-8`), devise, type de
décaissement (`SPEC §4.4`, `PORTS §4`), état (`confirme`, `en_verification`,
`indisponible`), vérifié le, par, notes ; `confirme` exige une date et un
responsable (`PORTS §4`, `REVUE §5.2` R8).

**État initial, déduit de `DEC:28`** : chaque pays **hors d'Afrique**, Arabie
saoudite comprise, a `virement_bancaire` à `confirme`. La note dit « décision du
directeur du 21/10, `DEC:28` » ; « vérifié par » est le compte qui enregistre la
ligne. Le directeur a décidé une règle, il n'a pas vérifié chaque pays : un pays
où l'académie ne peut pas verser se signale au directeur. Chaque pays
**d'Afrique** a toutes ses lignes à `en_verification`, compte bancaire compris,
jusqu'à la réponse ouverte de `CAND-Q05` ; la liste de ces pays est proposée en L6
avec sa source (0.3).

**Ce que le candidat déclare** (`CAND-01`) : pays de résidence ; pays de
versement ; compte bancaire oui ou non ; opérateurs, parmi les seules lignes
`confirme` de son pays de versement ; la case « J'accepte de recevoir ma
rémunération par au moins un moyen validé par Rewayah » (`SPEC §4.2`). Les deux
pays se choisissent dans la table existante `lib/core/i18n/pays_iso.dart` :
249 pays ISO 3166-1, noms en français et en arabe, Arabie saoudite et Yémen
compris (`REVUE §4` E8). Le serveur ne reçoit que le code à deux lettres. Sans
ligne confirmée dans son pays, le candidat lit une phrase à la place des
opérateurs, jamais une liste vide. Jamais demandé : numéro de compte, IBAN, numéro
de portefeuille, identifiant, code ; le numéro WhatsApp n'est jamais réutilisé
comme numéro de portefeuille.

| État | Quand |
| :--- | :--- |
| `inconnu` | aucune déclaration |
| `a_verifier` | la déclaration croise une ligne `confirme` ; la direction ne l'a pas encore confirmée |
| `compatible` | la direction a confirmé le moyen (`confirmerMoyenPaiement`, transition 24) |
| `incompatible` | moyen infirmé (transition 25), ou aucune ligne `confirme` croisée |

- Hors d'Afrique sans compte bancaire : `incompatible` ; la candidature reste en
  salle d'examen (`paiement_non_disponible`), issue `en_cours`.
- En Afrique, tant que `CAND-Q05` est ouvert : `incompatible`, même avec un compte
  bancaire. Une ligne `en_verification` ne rend jamais `compatible`.
- **Ligne qui quitte `confirme`** (`ADM-24`) : restriction automatique « paiement
  à revérifier » pour les personnes en salle 3 qui n'avaient qu'elle ; en salle 2,
  le contrôle passe faux et la candidature compte dans « bloquées » ; en salle
  d'examen, la transition 8 s'applique ; les personnes qui gardent une autre ligne
  `confirme` ne bougent pas. `enregistrer` rend l'`impact` (nombre de
  restrictions) ; alerte à la direction et à la comptabilité.
- **Ligne qui passe `confirme`** : les candidatures `paiement_non_disponible` du
  pays passent `a_completer` (transition 9).

Écrivent : la direction et la comptabilité (`paiement.referentiel.ecrire`). Le
référentiel devient la source de compatibilité par corridor de `CPT-BR-10`, sans
remplacer `PortCapacitePayout` (`PORTS §4`).

### 5.2 Tri : des clés en clair (`CAND-Q20`)

Clés affichées sur la ligne, dans cet ordre, jamais un score (`DEC:43`,
`SPEC §4.3`) : (1) besoin ouvert, genre et langue que la direction cherche, posés
en filtre ; (2) niveau constaté à l'entretien, ou déclaré avant ; (3) disponibilité
(heures par semaine, date de début) ; (4) compte bancaire, **seulement** à égalité
des trois premières. Aucune élimination automatique. Autres tris : date de
réception, dernière activité, date d'entretien. Le tri se fait au serveur ; un
scénario SQL le prouve (L1-9).

---

## 6. L'entretien dans l'app (`CAND-Q06`, `Q08`, `Q09`, `Q19`, `Q22`)

### 6.1 La séance d'entretien (L4, `CAND-BR-08`)

| Règle | Aujourd'hui | Ce que L4 pose |
| :--- | :--- | :--- |
| Type | `session_type` n'admet que `standard` et `child` (`M/0001_fondations.sql:170`) | type `entretien` |
| Qui entre | jeton refusé à un compte `pending_kyc` (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`) | le seul candidat convoqué, `pending_kyc` admis pour cette séance ; l'intervieweur ; personne d'autre |
| Intervieweur | `entretiens.mener` sans titulaire | un membre de la direction (`DEC:42`), du même côté que le candidat, super-admin compris. Le super-admin lit les deux côtés (`DEC:30`) ; il ne mène que du sien tant que la question est ouverte (0.3) |
| Paie | une séance close déclenche la paie (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`) | **jamais payée** : exclue du déclencheur |
| Effets de bord | clôture automatique (`M/20261018180000_ses_cloture_auto.sql:67-97`), chevauchement sur `teacher_id` (`M/0005_dashboards_affectation_regles.sql:640-645`), `mes_seances_v` (`M/20261017100400_af_l1_04_mes_seances_v_par_role.sql:28-43`), observation par le contrôleur | exclue de chacun ; la forme de `teacher_id`, obligatoire aujourd'hui, est fixée par L4 (0.3) |
| Enregistrement | supprimé pour l'instant (`C/DECISION-ENTREE-2026-10-17.md:33`) | aucun enregistrement, aucune visite de contrôle |
| Mention | « Visite de contrôle possible. » en permanence (`lib/features/salle_seance/mention_seance.dart:20-24`) | **aucune mention** : ni celle-ci, ni « Entretien non enregistré » (`DEC:32`) |
| Données | - | ni genre, ni pièce, ni téléphone, ni réponses dans la salle |
| Écran | salle unique `/salle` | même salle, aucune refonte LiveKit ; chemin du routeur depuis `/attente`, un seul routeur |

Il ne reste de l'entretien que le compte rendu, le constat et les données de la
personne : « c'est éphémère » (`DEC:32`).

### 6.2 États, des deux côtés

Mise à jour de `REVUE §6.3 bis` : la voie WhatsApp disparaît, le secours passe par
la conversation.

| État | Candidat (`CAND-02`) | Direction (vue Entretiens d'`ADM-20`, `ADM-21`) |
| :--- | :--- | :--- |
| À planifier | « Votre entretien sera planifié prochainement. » | lien « Planifier un entretien » |
| Planifié | date, heure, fuseau du candidat et de l'intervieweur ; « Voir les détails » | date, heure, fuseaux, intervieweur ; « Voir les détails » |
| Ouvert, en cours | « Rejoindre l'entretien », bouton plein de l'écran | « Rejoindre l'entretien » : lien secondaire sur la ligne (`DEC:37`), action principale dans `ADM-21` |
| Terminé | « Entretien terminé. L'académie vous répondra. » Jamais le résultat | résultat, compte rendu, constat, durée si connue, action suivante |
| Annulé | état dit ; « Une nouvelle date vous sera proposée. » | « Annulé le … par … » ; « Reprogrammer » |
| Manqué | état dit, et la suite | « Manqué » (candidat ou intervieweur) ; « Reprogrammer » |
| Inaccessible (jeton ou salle) | « L'entretien n'est pas accessible pour le moment. » et un lien vers la conversation ; aucun bouton qui ne peut pas aboutir | même phrase ; « Reprogrammer » |

### 6.3 Règles

- Sur une ligne, le nom ouvre le dossier, le lien d'entretien est une cible à part
  (`SPEC §6`, `DEC:37`) ; la carte entière reste cliquable. L'ouverture suit la
  fenêtre de la salle existante (`ctaSeance`), appliquée par le jeton.
- L'issue reste au retour à `entretien_a_planifier`. `tenu` : compte rendu
  obligatoire, écrit par l'intervieweur désigné seul ; `annule`, `manque_*` : motif
  obligatoire. Fuseau du candidat inconnu : planification refusée.
- Alerte « entretiens en retard » : date passée sans compte rendu depuis plus de
  24 h, ou « à planifier » depuis plus de N jours (N dans `app_config`). Sans
  intervieweur de son côté, la candidature attend et compte dans l'alerte ; jamais
  d'intervieweur de l'autre côté, super-admin compris (0.3).

---

## 7. Contact et messages

### 7.1 La conversation dans l'app (L5, `CAND-BR-18`)

Le contact entre la direction et un candidat passe par **la messagerie métier
existante** : un fil toujours lié à un objet, entre une personne et l'équipe
(`M/20261016090000_com_back_1_messages_metier.sql`, `DEC:72-75`).

| Point | Aujourd'hui | Ajout |
| :--- | :--- | :--- |
| Objet | `com_fils.type_objet` : `classe`, `eleve`, `dossier`, `remplacement`, `profilPaiement` (`:61-62`) ; `TypeObjetLie` (`lib/core/communications/modeles_communication.dart:112`) | objet `candidature` |
| Paire | profil ou foyer, face à l'équipe | profil du candidat, face à l'équipe |
| Compte admis | `com_appelant()` exige `app_account_valid()` (`:155-165`) | compte `pending_kyc` admis **pour ce seul objet** |
| Lecture par la direction | équipe d'administration | bornée par genre ; le super-admin lit les deux côtés |
| Écran | `FilContextuel` (`lib/features/com_messages/fil_contextuel.dart:59`) ; précédent « fil seul » `CPT-12F` (`C/CATALOGUE_ECRANS_COMPTABLE.md:37`) | `CAND-05` côté candidat, `ADM-21F` côté direction |

Un fil par candidature. Jamais de fil entre candidats, de liste de destinataires
ni de message groupé visible (`SPEC §7`, `REVUE §5.2` R12). Le fil sert aux
questions et aux compléments ; une décision (refus, pause) reste un geste à modèle,
et un motif interne ne s'y écrit pas.

### 7.2 Notifications dans l'app

Table existante `public.notifications` (`M/0063_notifications_privatives.sql:4`) ;
un compte `pending_kyc` y est admis pour les seuls événements de sa candidature
(aujourd'hui, rien pour un compte en attente, `REVUE §3.6`). Liste fermée :
complément demandé (Salle d'examen ou Salle de vérification et d'entretien) ;
admise en Salle de vérification et d'entretien ; pièce à corriger ; entretien
planifié, annulé ou reprogrammé ; pause posée ou levée ; refus ; retrait
enregistré ; entrée en Salle des prêts à enseigner ; moyen de paiement désormais
possible ; nouveau message. Texte tiré d'un modèle validé, en `fr` ou `ar`.

### 7.3 La file des courriels (`CAND-Q10`, `CAND-BR-16` révisé)

Ce module **n'envoie aucun courriel**. Il écrit la liste des courriels à envoyer ;
l'envoi, construit par la session du site public, la lit (`DEC:33`).

| Champ | Règle |
| :--- | :--- |
| destinataire | le profil ; pour une ligne sans compte, le courriel importé valide |
| modèle | liste fermée : `invitation` et les événements de 7.2 ; `lien_inscription` est le modèle du message WhatsApp consigné (7.4), jamais un courriel |
| langue | `fr` ou `ar` : celle de l'interface choisie, sinon `ar` pour une ligne importée de A |
| paramètres | dates, liens ; pour le seul modèle `invitation`, le code d'invitation, lu par la seule fonction d'envoi ; jamais un texte libre, un motif interne, une réponse ni un constat |
| état | `a_envoyer` (écrit par ce module), puis `envoye` avec la date ou `echec` avec la cause (écrits par l'envoi seul) |
| droits | ce module écrit par RPC, l'envoi par sa fonction serveur ; aucun candidat ne lit la file ; la direction ne change jamais un état |
| à l'écran | « Courriel pas encore envoyé » tant que `a_envoyer` ; « Courriel envoyé le … » seulement sur `envoye` ; « Courriel non parti » sur `echec` ; jamais « reçu », jamais « lu » |

Ce tableau est le **contrat à remettre à la session du site public**. Deux
dépendances distinctes :
1. **L'envoi de Supabase Auth** : SMTP d'authentification en production et
   `enable_confirmations = true` (`supabase/config.toml:229`, `[auth.email.smtp]`
   commenté en `:239-247`). C'est l'envoi qui part déjà pour le lien de connexion
   (`signInWithOtp`, `lib/core/auth/service_auth.dart:52`). Il confirme le courriel
   à l'inscription : condition de mise en ligne du lien (3.1, condition 6).
2. **L'envoi de la file**, construit par la session du site public (`DEC:33`) :
   condition du seul état « Courriel envoyé le … », et de l'émission des
   invitations en production (3.3).

### 7.4 La seule exception WhatsApp

Le directeur n'admet WhatsApp que pour **envoyer le lien d'inscription aux
personnes des formulaires sans courriel** (`DEC:26`, `:29`) : un message par
personne, jamais un groupe ni une liste de diffusion ; le message dit de créer un
courriel (`DEC:56`) ; la direction le consigne par `consignerPrevenu` (canal
`whatsapp`, modèle `lien_inscription`, date, transition 26), jamais un texte libre.
L'accord de contact donné dans A (colonne M) ne vaut que pour ce contact
(`MAP §2`).

### 7.5 Ce que le module ne prétend jamais

« Envoyé » avant que l'envoi l'ait écrit ; « lu » ; une décision avant la réponse
du serveur ; un entretien « enregistré » ; un message au candidat qui contient un
motif interne, un compte rendu ou un constat.

---

## 8. Confidentialité et droits

### 8.1 Capacités

Mise à jour de `REVUE §5.4` par `DEC:30`, `:42`.

| Capacité | Qui | Accède à | N'accède jamais à |
| :--- | :--- | :--- | :--- |
| `candidatures.lire` | direction, de son côté ; super-admin les deux côtés, journalisé | réponses, contrôles, étape, historique, réponses importées | pièce hors `ADM-02` |
| `candidatures.contact` | direction nommée, de son côté | courriel, téléphone, recherche par téléphone ; chaque lecture journalisée | - |
| `candidatures.importer` | super-admin seul, aal2 exigée en base (3.2) | import, essai à blanc, rapport | - |
| `candidatures.decider` | direction, de son côté | transitions, pièce dans `ADM-02`, lots | - |
| `entretiens.mener` | direction (`DEC:42`), du même côté que le candidat, super-admin compris | réponses utiles à l'entretien, date, fuseaux, constat, compte rendu | téléphone, pièce, autres candidatures |
| `candidatures.messages` | direction, de son côté | le fil `candidature` | les fils de l'autre côté |
| `paiement.referentiel.ecrire` | direction, comptabilité | référentiel, impact d'un changement | réponses, identité |
| candidat | le titulaire | sa candidature, son fil, son entretien, ses notifications | tout autre candidat ; listes ; compteurs ; motifs internes ; compte rendu ; constat |
| contrôleur, enseignant, tuteur, élève | - | rien | tout |

L'exception du super-admin (`DEC:30`) est une exception **de lecture** : listes,
dossier, compte rendu. Elle ne lui donne pas l'entretien d'une personne de l'autre
côté (0.3).

### 8.2 Séparation femmes et hommes, en base (`CAND-Q07`)

La RLS et chaque RPC du module bornent la direction à son côté, sur le modèle de
`read_kyc_documents()` : filtre par genre du lecteur, refus si ce genre est
inconnu, journal de chaque lecture de liste. Le super-admin lit les deux côtés,
par l'exception journalisée de `M/0088_kyc_super_admin_gender_exception.sql`
(`DEC:30`). Portée : candidatures, réponses, réponses importées, contacts,
entretiens, conversation, historique **et compteurs**. « Hors portée » et
« absente » sont deux erreurs distinctes. Un masquage à l'écran ne compte pas
(`SPEC §7`). L'import, dont le fichier mêle les deux côtés, est réservé au
super-admin (3.2).

### 8.3 Ce que les listes ne montrent jamais

Ni courriel, ni téléphone, ni genre, ni pièce, ni motif interne, ni compte rendu,
ni constat, ni réponse libre, dans une liste, un aperçu de lot ou un export
(`PORTS §1`, `LigneCandidature`). Le contact se lit par `lireContact`, journalisé.
Le journal porte la référence `CAND-` et un numéro, jamais le nom ; chaque lecture
hors portée et chaque lecture du contact y laissent une entrée.

### 8.4 Conservation, anonymisation, effacement (`CAND-Q21`)

- Durée réglable dans `app_config`, **valeur en attente du juriste** : aucune
  purge automatique avant la décision datée.
- Anonymisation sur le modèle de `traiter_demande_suppression`
  (`M/20261018150000_cpt_suppression_export.sql:587`) ; réponses dans
  `mes_donnees_export()` (`:174`), motifs internes exclus. Effacement demandé
  depuis l'app (`demander_suppression_compte`, `:385`), ou reçu par courriel et
  noté par la direction pour une personne sans compte.
- **À soumettre au juriste avec `CAND-Q21`** : la base des courriels envoyés aux
  personnes des formulaires avant leur inscription, et la conservation des
  réponses importées de qui ne s'inscrit pas. B n'a recueilli aucun consentement,
  A un accord de contact par WhatsApp seulement (`REVUE §2.2`, `MAP §2`
  colonne M). Rien n'est affirmé sur leur couverture avant l'avis.

---

## 9. Langues

**Le parcours candidat est livré en français et en arabe** (`DEC:36`) :
inscription, questionnaire, page d'accords, états de `/attente`, « Mon
entretien », retrait, conversation, notifications, modèles de courriel. Le texte
du cadre religieux et pédagogique, dans les deux langues, est **validé
juridiquement** (`SPEC §5`) **et soumis au directeur** (`DEC:34`) ; L2 ne publie sa
version requise qu'après les deux. Aujourd'hui l'espace `recrutement` n'a que
17 clés traduites sur 106 (`REVUE §3.6`). Les écrans de la direction suivent la
règle générale : le français fait référence, les autres langues suivent le sens.

**Codes de langue** (`CORR §3`, `MAP §3.2`) :
- on **enregistre le code**, on affiche le nom lu dans le référentiel ; les codes
  de `langues_cours` ne changent pas : `poular`, `francais`, `english`
  (`M/0043_offres_horaires_et_intentions.sql:75-78`) ;
- hors référentiel : code ISO 639 (`ar`, `ha`, `ur`…), marqué « hors
  référentiel », qui nourrit la décision d'ouvrir une langue sans l'ouvrir ; une
  langue ajoutée à `langues_cours` prend le code du mappage (l'arabe sous `ar`) ;
  `autre_a_preciser` n'est jamais une langue ;
- **un code ne s'affiche jamais tel quel** : le module porte la table des libellés
  ISO 639 du mappage, en français et en arabe ; en chargement ou en erreur, la
  ligne montre son état, jamais « francais » ;
- l'équivalence `ff` (peul) et `poular` reste à valider (`MAP §3.2`, 0.3) : d'ici
  là, `ff` s'importe hors référentiel.

Les réponses du module sont en codes dès le premier jour ; `teacher_profiles`
reste en noms jusqu'au lot `langue` (section 13).

---

## 10. Écrans à inscrire au catalogue

À inscrire dans `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md` (prochain document),
chacun avec sa fiche (Tâche, Contenu, Entrée, États, Droits, Contrat serveur)
**avant tout fichier `.dart`**, puis une `UX_REVIEW_CAND-<n>.md` (`DESIGN-GOV`).
Codes libres : `ADM-20` et au-delà, préfixe `CAND-` (`REVUE §10`).

**Les mots du module** (noms de salle, « Rejoindre l'entretien », « Cadre
religieux et pédagogique ») entrent dans `.claude/skills/mots-rewayah/SKILL.md`
dans le commit des écrans (`DEC:35`). Les noms de salle s'écrivent en entier,
jamais sous une forme courte ; la forme du côté des femmes et la collision avec
« examen de fin des bases » sont jointes à `CAND-Q12` (0.3).

**Règles communes :**
- cinq états obligatoires : `loading` (`Skeleton`), `content`, `empty`
  (`EmptyState`), `error` (avec reprise), `offline` (bandeau, rien d'écrit sans
  réseau) ; selon l'écran : erreur de validation (le champ nommé, ce qui manque,
  quoi faire), hors portée, données partielles (« Disponible au branchement
  serveur »), action en cours, succès seulement après la réponse du serveur ;
- **un seul bouton plein par écran** (`K-56`, `C/REVUE-DIRECTEUR-2026-10.md:12`,
  `DEC:37`), vérifié par `verifierUnSeulBoutonPlein` ; le lien d'entretien d'une
  ligne est secondaire ; un état critique porte texte et icône, jamais la couleur
  seule ;
- cibles de 48 et contrastes conformes, mesurés (`SPEC §10`) ;
- bureau : file et détail ; tablette : deux volets ; mobile : cartes ; 360, 768,
  1440 ; clair et sombre ; aperçu de lot et mappage d'import en pages, pas en
  modales (`tool/verifier_jetons.dart:306-316`).

**Côté candidat :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `CAND-04` | Inscription sans code : extension du parcours d'inscription existant (`/inscription`, `UsageEtape`, `InvitationCandidatPage`, `lib/core/router/routes.dart:44`, `:59`), une entrée sans code à côté du code d'invitation. Une route neuve pour le lien du site ne se crée que justifiée dans la fiche, et mène au même écran (`SPEC §1.3`) | créer le compte candidat | créer le compte | courriel à confirmer ; réponse unique et neutre, la même qu'en cas de succès, pour un courriel déjà utilisé ou un plafond atteint (un lien de confirmation part si l'adresse peut servir ; texte dans la fiche, selon `mots-rewayah`) ; code d'invitation invalide ou expiré ; inscription sans code pas encore ouverte (clé de 3.1) | L3 |
| `/attente` (existant, étendu) | portail de la candidature | dire où en est la candidature et la prochaine action | la prochaine action | à compléter (liste) ; en examen ; versement pas encore possible ; pièce à corriger ; en pause (modèle, reprise) ; refusée (modèle) ; retirée | L2 |
| `CAND-01` | Questionnaire de la salle d'examen | conditions de rémunération, puis réponses | « Envoyer ma candidature » | pré-rempli à relire ; questionnaire périmé ; aucun moyen confirmé dans le pays ; réponses incomplètes nommées ; paiement inconnu, à vérifier, compatible, incompatible | L2 ; opérateurs L6 ; pré-remplissage L3 |
| Page d'accords (existante) | une case « Cadre religieux et pédagogique » de plus | accepter les textes de l'étape | « Suivant » existant | nouvelle version à ré-accepter | L2 |
| `CAND-02` | Mon entretien | voir et rejoindre | « Rejoindre l'entretien » à l'ouverture | les sept états de 6.2 | L4 |
| `CAND-03` | Retirer ma candidature | retrait, effet dit avant (entretien annulé, réouverture par l'académie seulement) | aucun (`ConfirmDestructive`) | retrait en cours ; déjà retirée | L2 |
| `CAND-05` | Écrire à l'académie (fil « Ma candidature ») | conversation | envoyer | fil vide ; message non parti (hors ligne) | L5 |
| `/salle` (existante, mode entretien) | l'entretien | - | celui de la salle | aucune mention ; jeton refusé ; fin de séance | L4 |

**Côté direction (Personnes, sauf `ADM-24`) :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADM-20` | Candidatures (remplace l'onglet Invitations) | file dense : recherche, puces des salles avec compteur, autres axes sous « Plus » (dont responsable ; affectée ou non, en salle 3 ; sans activité depuis N jours, N dans `app_config`), tri au serveur, pagination, sélection multiple, quatre alertes, vue Entretiens | aucun ; « Agir sur la sélection » quand une sélection existe | recherche sans résultat (filtres rappelés) ; hors portée ; alertes à zéro | L1 ; gestes L2 |
| `ADM-21` | Candidature | dans l'ordre : étape et issue, blocages, prochaine action, réponses, contrôles nommés, pièce (lien `ADM-02`), entretien, responsable, affectation (lue dans les classes), historique | la prochaine action, une seule | bloquée (contrôle nommé) ; contact masqué ; hors portée ou absente ; paiement inconnu, à vérifier, compatible, incompatible | L1 ; gestes L2 ; entretien L4 |
| `ADM-21F` | Fil « Candidature » | conversation côté direction | envoyer | fil vide | L5 |
| `ADM-22` | Action groupée | liste ciblée (nom, étape, aucun contact), effet exact, exclus avec raison, saisie du nombre, rapport ligne par ligne | confirmer | jeton périmé ; nombre discordant ; lot partiellement refusé ; issue inconnue | L2 ; inviter L3 |
| `ADM-23` | Import des formulaires | réservé au super-admin (3.2) ; les huit pas de 3.2 ; route distincte de `/admin/personnes/import` | importer, au pas 7 | fichier illisible ; mappage incomplet ; doublons à choisir ; écart des compteurs ; double vérification requise | L3 |
| `ADM-24` | Compatibilité de paiement par pays (Finance, `DEC:85`) | référentiel | enregistrer | confirmation sans date ni responsable refusée ; impact (N restrictions) | L6 |
| `ADM-02` (existant, étendu) | revue de pièce | valider (entrée en salle 3), « à corriger », refus définitif | valider | contrôles manquants nommés ; validation refusée par le serveur | L2 |

**Quatre alertes d'`ADM-20`, jamais confondues** (`REVUE §10.2`) : bloquées
(contrôle faux nommé ou restriction) ; entretiens en retard ; informations
manquantes (`a_completer`, complément demandé en salle 2, « courriel à obtenir »,
« indicatif à confirmer ») ; confirmées indisponibles. Une pause n'entre dans
aucune. Le candidat qui ne répond pas (`SPEC §12.2`) se lit par le filtre « sans
activité depuis N jours », pas par une cinquième alerte. **Composants** :
`BarreSelection` à promouvoir du Comptable vers `lib/core/widgets/`, jamais
recopiée ; ligne d'historique neuve ; le reste réutilisé tel quel (`REVUE §10.3`).

---

## 11. Lots serveur

Tous sur la **base de test** ; aucune application en production sans le feu vert
du directeur (`DEC:25`). Chaque lot livre son fichier de scénarios, rejoué sur
Postgres nu. L'ajout à `.github/workflows/ci.yml` demande un ordre du directeur
(`.claude/hooks/garde.py:22-27`) ; d'ici là, `tool/rejouer_scenarios.sh`.

La décision d'`ADM-02` est fermée en production côté Flutter (`AD-M3-PROD`,
`lib/features/admin_dossiers/revue_dossier.dart:33-36`, `REVUE §0` point 2). Sa
réouverture en production fait partie du feu vert du directeur, après L2 et les
lots `langue` et `c11bis`.

| Lot | Contenu | `CAND-BR` | Questions | Statut au 21/10 | Prérequis |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **L1** socle | tables (type, candidature, questionnaire versionné, réponses, réponses importées) ; **forme en base du compte candidat** (rôle et `account_status`, la même pour le lien public et l'invitation, 3.1) ; lectures cloisonnées par genre (RLS, liste paginée et triée au serveur, détail, contact journalisé) ; historique sans nom | `01`, `02`, `03`, `07` | `Q02`, `Q04`, `Q07`, `Q20` | **en cours d'écriture** dans une autre session ; aucune migration du module sur cette branche à la rédaction ; si L1 est livré sans la forme du compte, un complément de L1 la fixe avant L2 | - |
| **L2** transitions et contrôles | une RPC par geste ; les huit contrôles ; `decider_dossier()` : pour un profil porteur d'une candidature `enseignant`, validation acceptée seulement salle 2 terminée, les autres profils gardent l'approbation actuelle ; transaction d'entrée en salle 3 (2.2) ; garde `0089` étendue, vers `active` et `provisional_active` ; deux issues de pièce et levée de la restriction `piece` (transition 21) ; prédicat d'affectation qui refuse restriction et indisponibilité (4.3) ; lots ; `etat_dossier()` étendu, questionnaire, envoi, retrait ; sorte d'accord du cadre religieux, version requise publiée seulement après validation juridique et accord du directeur (section 9) ; conditions de rémunération lisibles en attente | `04`, `05`, `06`, `10`, `11`, `12` | `Q01`, `Q08`, `Q11`, `Q18` | à écrire | L1 (forme du compte) ; `CAND-BR-11` : L1 et lot `conduite` (`CORR §7`) ; prédicat d'affectation : lot `creer_groupe` |
| **L3** inscription publique et import | compte candidat ; courriel confirmé ; genre et téléphone obligatoires ; plafond horaire et réponse neutre ; clé de mise en ligne ; accord de confidentialité ; rattachement (courriel, téléphone, B) ; alignement de `inscrire_enseignant_invite` ; geste `inviter` ; reprise des invitations ; import ponctuel, rejouable, réservé au super-admin | `17`, `09`, part de `04` | `Q03`, `Q04`, `Q16`, `Q17` | à écrire | L1, L2 ; mise en ligne : SMTP d'authentification, `enable_confirmations`, feu vert (3.1, condition 6) |
| **L4** entretiens dans l'app | type `entretien`, forme de `teacher_id`, rôles, jeton du candidat convoqué, exclusions (paie, clôture, chevauchement, vues, contrôleur), mode sans mention, planification, constat, compte rendu | `08` | `Q06`, `Q07`, `Q08`, `Q09`, `Q19`, `Q22` | à écrire | L2 ; revue de sécurité (jeton, déclencheur de paie) |
| **L5** conversation, notifications, file des courriels | objet `candidature` dans la messagerie ; compte en attente admis pour cet objet ; notifications ; file `a_envoyer` | `18`, `16` | `Q06`, `Q07`, `Q10` | à écrire | L1 ; contrat de la file remis à la session du site public |
| **L6** référentiel de paiement | lignes (avec type de décaissement), droits, état initial déduit de `DEC:28`, liste des pays d'Afrique proposée avec sa source, déclencheur de restriction, transitions 8 et 9, alerte, part de `CPT-BR-10` | `13` | `Q05` | à écrire ; lignes d'Afrique `en_verification` tant que `Q05` est ouvert | L1 |
| Transverse | conservation et anonymisation | `14` | `Q21` | en attente du juriste | - |
| Transverse | scénarios du module | `15` | - | un fichier par lot | ordre du directeur pour la CI |

**Ordre et parallèle.**
- Avant L6, `paiement_compatible` est faux pour tous : aucune candidature n'entre
  en salle 2. L6 est court ; il peut avancer en parallèle de L2 et doit être livré
  avant la première admission en salle 2.
- **Chemin critique.** La transition 6 (envoi du questionnaire) exige le cadre
  religieux à la version requise. Il faut donc, dans l'ordre : le lot `conduite`,
  le texte validé (section 9), puis `CAND-BR-11`, avant le premier envoi de
  questionnaire. Aucun candidat ne peut envoyer sa candidature avant.
- **Salle 3.** Aucune validation en salle 3 avant les lots `langue` et `c11bis`
  (puis `creer_groupe`) : sinon « affectable à 100 % » (`DEC:24`) est faux.

---

## 12. Recette

Un contrôle qui n'a pas tourné n'est pas vert. Chaque chiffre se mesure sur base
neuve et s'écrit. Fichiers proposés : `supabase/tests/scenarios_cand_l1.sql` à
`scenarios_cand_l6.sql`.

### 12.1 Scénarios SQL

| # | Cas | Attendu, mesuré |
| :-- | :--- | :--- |
| L1-1 | un candidat lit les candidatures | 1 (la sienne), 0 autre |
| L1-2 | une directrice, un directeur, le super-admin lisent la liste | 0 candidature d'homme pour elle, 0 de femme pour lui ; les deux côtés pour le super-admin ; 1 ligne `audit_logs` par lecture de liste |
| L1-3 | lecteur de genre inconnu | refus, 0 ligne |
| L1-4 | candidature hors portée, puis inconnue | deux erreurs distinctes, 0 donnée |
| L1-5 | colonnes de la RPC de liste ; appel de `lireContact` | 0 colonne courriel, téléphone, genre ou pièce ; 1 ligne de journal par appel |
| L1-6 | historique | 0 nom ; référence `CAND-` seulement |
| L1-7 | fixture `comptable` | 0 contrôle enseignant appliqué, et inversement |
| L1-8 | compteurs d'une directrice | son côté seulement |
| L1-9 | tri de la liste : clés égales sauf le compte bancaire ; puis clés différentes | compte bancaire devant ; puis ordre des clés, le compte bancaire sans effet |
| L2-1 | validation de pièce, un des sept contrôles faux | 7 refus, chacun nommé ; après chacun : pièce en attente, compte `pending_kyc`, étape inchangée |
| L2-2 | validation, les sept vrais, sans photo, sans `weekly_availability`, sans coordonnées financières | pièce `approved`, compte `active`, étape `confirmee`, langues et fuseau copiés dans `teacher_profiles`, en 1 transaction |
| L2-3 | activation par une autre voie (mise à jour de `account_status`), sans contrôles ; puis sans contrat ; puis passage manuel en `provisional_active` sans contrôles | 3 refus de la garde |
| L2-4 | entrée en salle 2 sans `paiement_compatible`, puis sans cadre religieux | 2 refus nommés |
| L2-5 | pièce « à corriger » ; refus définitif | étape inchangée ; issue `refusee`, 0 motif interne dans `etat_dossier()` |
| L2-6 | nouvelle pièce refusée d'une enseignante active, sans autre pièce approuvée | `disabled` (inchangé) et 1 restriction `piece` |
| L2-7 | lot de 10 pauses dont 3 sur des candidatures `refusee` | 7 réussies, 3 exclues avec raison, 3 inchangées |
| L2-8 | même clé d'idempotence rejouée ; version périmée | 1 effet ; 0 écriture |
| L2-9 | geste en pause autre que lever, refuser, retirer | refus |
| L2-10 | chaque geste marqué « oui » en 4.2, sans motif | refus, 0 écriture |
| L2-11 | chaque transition | 1 ligne `audit_logs` ; chaîne vérifiable |
| L2-12 | après L2-2, `tc_verifier_affectation_enseignant` pour une classe de la langue et du genre de la personne | aucune erreur levée |
| L2-13 | approbation d'une pièce de tuteur `pending_kyc` | compte `active`, comme avant |
| L2-14 | confirmée indisponible ; puis enseignant actif sans candidature | affectation refusée, étape inchangée ; affectation acceptée |
| L2-15 | confirmée en restriction ; puis restriction levée | affectation refusée ; puis acceptée |
| L2-16 | après L2-6 : nouvelle pièce déposée par le compte `disabled`, approuvée, restriction levée | compte `active` et affectable, en 1 transaction ; 1 ligne de journal |
| L2-17 | rouvrir une candidature refusée, un contrôle de l'étape faux | `ControlesNonSatisfaits` nommé ; 0 écriture |
| L2-18 | complément demandé en salle 2 | même état ; comptée dans « informations manquantes » ; 1 notification |
| L3-1 | inscription sans courriel confirmé | 0 candidature |
| L3-2 | inscription au-delà du plafond horaire de `app_config` | refus |
| L3-3 | inscription par le lien | 1 compte `pending_kyc` ; 0 capacité enseignant ; jeton de cours refusé ; 0 apparition dans une liste d'enseignants |
| L3-4 | essai à blanc sur A, par le super-admin | 0 écriture ; compteurs rendus ; écart avec 440 lignes et 409 personnes lu avant de confirmer |
| L3-5 | confirmation de l'import, puis second import identique | 0 ligne dans `profiles`, `invitations_enseignant`, `kyc_documents`, `contract_acceptances` ; 0 ligne de candidature, `recue` comprise ; N réponses importées ; puis 0 ajout |
| L3-6 | B | 11 lignes `dejaConnue`, 0 écriture |
| L3-7 | rattachement par courriel confirmé, par téléphone seul, par nom | pré-remplissage ; 0 donnée montrée et 1 proposition à la direction ; 0 |
| L3-8 | lot de 10 invitations dont 3 sans courriel valide | 7 codes émis, 7 courriels `a_envoyer`, 3 exclues, 3 inchangées |
| L3-9 | invitation expirée | retour en `recue`, trace gardée |
| L3-10 | créneaux importés | fuseau `Asia/Riyadh` ; 0 ligne `weekly_availability` |
| L3-11 | groupe de doublons sans choix | reste « à corriger » ; 0 fusion |
| L3-12 | inscription avec un courriel neuf et le téléphone d'une réponse importée | 1 proposition à la direction ; 0 donnée montrée au candidat |
| L3-13 | inscription sans genre | refus ; 0 profil |
| L3-14 | seconde candidature du même compte, même type | refus |
| L3-15 | une directrice lance l'essai à blanc sur A | refus ; 0 nom ni réponse d'homme rendu |
| L3-16 | réimport d'une ligne corrigée | 0 réponse nouvelle ; 1 correction tracée sur la même référence source |
| L3-17 | inscription avec un courriel existant ; puis au-delà du plafond | même réponse que le succès, deux fois |
| L3-18 | inscription sans code, clé de mise en ligne fausse ; puis vraie | refus ; acceptée |
| L3-19 | personne de B, courriel confirmé | reconnue ; 0 champ pré-rempli |
| L4-1 | jeton d'entretien : candidat convoqué à l'ouverture, avant l'ouverture, autre candidat | accepté, refusé, refusé |
| L4-2 | séance d'entretien close | 0 ligne `tresorerie_mouvements` ; 0 clôture automatique ; 0 ligne `mes_seances_v` ; 0 conflit de chevauchement ; 0 observation du contrôleur |
| L4-3 | intervieweur de la direction de l'autre côté ; super-admin de l'autre côté ; super-admin du même côté | refus ; refus ; accepté, 1 ligne de journal |
| L4-4 | fuseau du candidat inconnu | planification refusée |
| L4-5 | `tenu` sans compte rendu ; `annule` sans motif ; retour à `entretien_a_planifier` | refus ; refus ; issue gardée |
| L5-1 | candidat `pending_kyc` et son fil `candidature` ; autres objets | lecture et écriture ; 0 accès |
| L5-2 | une directrice et le fil d'un candidat homme | 0 accès |
| L5-3 | planification d'un entretien | 1 notification et 1 courriel `a_envoyer` |
| L5-4 | paramètres des courriels de refus et de pause | 0 motif interne |
| L5-5 | un candidat lit la file des courriels | 0 ligne |
| L5-6 | la direction tente de passer un courriel à `envoye` | refus |
| L5-7 | un candidat lit les notifications | 0 notification hors de sa candidature |
| L6-1 | Arabie saoudite, compte bancaire oui, moyen confirmé | `compatible` ; admission en salle 2 acceptée |
| L6-2 | hors d'Afrique, compte bancaire non | `incompatible`, `paiement_non_disponible`, issue `en_cours` |
| L6-3 | Afrique, compte bancaire oui, `Q05` ouvert | `incompatible` |
| L6-4 | ligne `en_verification` | 0 cas `compatible` |
| L6-5 | `confirme` sans date ni responsable | refus |
| L6-6 | ligne passée `indisponible` | K restrictions pour les K personnes en salle 3 qui n'avaient qu'elle ; 0 changement pour qui garde une autre ligne `confirme` ; `impact` = K |
| L6-7 | un candidat lit le référentiel | 0 ligne non confirmée, 0 note interne |
| L6-8 | pays de fixture, compte bancaire non, ligne `mobile_money` `confirme`, moyen confirmé | `compatible` ; admission en salle 2 acceptée |
| L6-9 | ligne passée `confirme` | candidatures `paiement_non_disponible` du pays en `a_completer` ; 1 notification et 1 courriel chacune |
| L6-10 | candidat `en_examen` dont la seule ligne quitte `confirme` ; puis moyen infirmé par la direction | `paiement_non_disponible` ; puis `paiement_non_disponible` avec motif tracé |

### 12.2 Flutter

- Chaque écran neuf ou étendu : cinq états, erreur de validation et états
  propres ; clair et sombre ; 360, 768, 1440 ; `fr` et `ar` (droite à gauche) ;
  texte à 200 % ; clavier, focus ; cibles de 48 et contrastes mesurés.
- `verifierUnSeulBoutonPlein` dans chaque état ; la ligne d'`ADM-20` a 2 cibles.
- `ADM-20` à 1 000 lignes, sur le modèle de
  `test/features/admin_regroupements/echelle_listes_test.dart`.
- Salle d'examen : 0 case de contrat, 0 dépôt de pièce.
- Mode entretien de `/salle` : 0 mention de séance, 0 donnée sensible. `/attente` :
  0 motif interne, 0 compte rendu, 0 constat. Courriel `a_envoyer` : « Courriel
  pas encore envoyé », 0 « envoyé le ». Composants promus dans la galerie
  (`test/widgets/catalogue_galerie_test.dart`).
- Commandes : `dart run slang`, `dart run build_runner build
  --delete-conflicting-outputs`, `dart analyze --fatal-infos` (0 problème),
  `flutter test`, `dart run tool/verifier_jetons.dart` (0 violation nouvelle).

### 12.3 Non-régression

- Référence remesurée sur la branche avant chaque lot, chiffre écrit. Dernières
  mesures écrites : 108 scénarios SQL sur 109 le 19/10
  (`af_liste_blanche_volatiles` rouge connu, antérieur), 15 218 tests Flutter
  le 18/10 (`REVUE §12`).
- Restent verts : invitations, inscription sur invitation, accords, `ADM-02`,
  import du 12/10, Comptable (`CPT-02`), affectation par `tc_verifier`,
  approbation de la pièce d'un tuteur (L2-13).
- **Garde étendue** : 28 fichiers de scénarios signent puis activent un enseignant
  (`CORR §7`, recette), dont `scenarios_etape3.sql`, premier de la CI. Chacun
  reçoit les fixtures des nouveaux contrôles dans le même lot ; le nombre de
  fichiers touchés s'écrit.

### 12.4 Critères de la spec

| `SPEC §13` | Preuve |
| :--- | :--- |
| Autre type sans copier le pipeline ; critères étanches | L1-7 |
| Champs au bon moment ; rien de postérieur exigé (coordonnées, photo, `weekly_availability`) | test de widget de la salle d'examen (12.2 : 0 case de contrat, 0 dépôt de pièce) ; L2-2 (sans photo, sans `weekly_availability`, sans coordonnées) ; L3-10 |
| Salle 3 impossible sans pièce, contrôles, paiement | L2-1, L2-3 |
| Sans compte bancaire mais moyen compatible confirmé : admis | L6-8 |
| Préférence bancaire à égalité seulement | L1-9 |
| Coordonnées financières pas exigées avant les cours | L2-2 |
| Confirmé indisponible distinct de prêt à être affecté | L2-14 ; widget `ADM-20` |
| Nom et entretien : deux cibles ; état réel ; lien absent sans bouton | 12.2, L4-1 |
| Compte rendu et décision traçables | L2-11, L4-5 |
| Un candidat ne lit pas les autres ; pièces hors des listes | L1-1, L1-5 |
| Lots : portée et erreurs partielles | L2-7, L3-8 |
| Décisions sensibles traçables | L2-11, L1-5, L4-3 |
| Import sans compte ni contrôle validé | L3-5 |
| Cohérence avec la Bible et les jetons | `tool/verifier_jetons.dart` (0 violation nouvelle), 12.2 |
| États loading, empty, error, offline, accès refusé définis | 12.2 |
| Clair et sombre, largeurs, clavier | 12.2 |
| Non-régression | 12.3 |

---

## 13. Hors module (`CAND-Q15`)

Les cinq défauts trouvés hors du module sont confiés à des agents (`DEC:38`).
**Recherche du 21/10** sur 584 branches distantes et 34 PR ouvertes : **aucun des
cinq n'est corrigé, sur aucune branche** (`CORR §0 bis`). Les correctifs
s'écrivent d'après `CORR`, chacun sur sa branche, jamais par `main`, avec son
scénario et un horodatage de migration propre.

| Lot | Défaut | Lien avec ce module |
| :--- | :--- | :--- |
| `langue` | la langue de l'enseignant est enregistrée par son nom et comparée à un code (`CORR §3`) | sans lui, une personne en salle 3 n'est affectable à aucune classe dont la langue est renseignée ; aucune validation en salle 3 avant lui (section 11) |
| `c11bis` | `affecter_enseignant_classe_c11bis` lève toujours : aucune classe en attente ne reçoit d'enseignant (`CORR §4`) | sans lui, « affectable » n'a pas de chemin serveur ; aucune validation en salle 3 avant lui (section 11) |
| `creer_groupe` | pose un enseignant sans vérifier pièce, genre, langue, plafond ni collisions (`CORR §5`) | une personne hors salle 3 pourrait recevoir une classe ; le prédicat qu'il centralise refuse aussi restriction et indisponibilité (4.3) |
| `conduite` | le code de conduite n'est exigé par aucune garde (`CORR §7`) | entre dans `accords_signes` ; `CAND-BR-11` s'écrit après, sur la garde redéfinie ; sur le chemin critique du premier envoi (section 11) |
| `gnf` | 0 décimale côté client, 2 côté serveur (`CORR §6`) | aucun direct ; paie et versements en GNF |

**Ordre** (`CORR §2`) : `langue`, puis `c11bis`, puis `creer_groupe`. `conduite`
passe à part, après les migrations `20261018160000` et `20261019100000` ; `gnf` est
indépendant. Ajustements relevés par la recherche : le seed de staging de la PR
#40 écrit `array['fr','ar']`, à corriger avant sa fusion ; `creer_groupe` retient
la variante `app_private.verifier_affectation_enseignant(uuid, uuid, boolean)`
(`CORR §0 bis`).
