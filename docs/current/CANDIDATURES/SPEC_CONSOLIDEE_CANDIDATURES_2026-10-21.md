# Spécification verticale consolidée du module des candidatures (enseignant d'abord)

## 0. Statut, sources, ce que ce document remplace

**Statut :** `spécifié` seulement. Aucune ligne de code, aucune migration, aucun
port n'est écrit par ce document. Rédigé le 21/10/2026, après les 22 réponses du
directeur. C'est le pas 4 de l'ordre de la spécification : arbitrage, puis cette
spécification consolidée, puis maquettes et leur contrôle, handoff,
implémentation, recette (`SPEC §14`).

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
| `PORTS`, `BR` | contrat proposé, à mettre à jour par le lot qui écrit les ports : `geste(confirmer)` disparaît (l'entrée en salle 3 est la validation de la pièce dans ADM-02, donc plus de confirmation en lot) ; `EntretienCandidat.mode` perd `whatsapp` ; `consignerPrevenu` ne constate plus qu'un lien envoyé par WhatsApp ; `CAND-BR-16` devient la file des courriels ; `CAND-BR-13` est déclaratif ; l'import écrit des réponses importées, pas des candidatures (3.2) |

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
| « Viviers » | mot non affiché ; « Salle des prêts à enseigner » | `DEC:35`, `REVUE §0` point 7 |
| Tri par adéquation et priorité (`SPEC §8.1`) | clés en clair, jamais un score | `DEC:43` |
| Confirmation groupée encadrée (`SPEC §8.2`) | aucune : une pièce se valide une à une | `DEC:24` (conséquence) |

### 0.3 Ce qui reste ouvert

| Question | Ce qui manque | Effet tant que c'est ouvert |
| :--- | :--- | :--- |
| `CAND-Q05` | pays et moyens qui fonctionnent en Afrique (par exemple le mobile money par pawaPay) ; sort d'un candidat qui vit en Afrique et a un compte bancaire (`DEC:80-83`) | toutes les lignes d'Afrique du référentiel restent `en_verification` : aucun candidat dont le pays de versement est en Afrique n'entre en salle 2 |
| `CAND-Q12` | accord du directeur sur les trois noms de salle (`DEC:87-88`) | les noms proposés sont les valeurs des clés i18n ; un changement ne touche que les textes |
| `CAND-Q21` | durée de conservation, avis du juriste (`DEC:90`) | aucune purge automatique des candidatures ; `CAND-BR-14` n'est pas commencé |

Deux points d'application se fixent dans leur lot, sans question au directeur :
la forme en base du compte candidat (L3, section 3.1) et la liste des pays
d'Afrique du référentiel (L6, avec `CAND-Q05`). L'écran du référentiel va dans
Finance, sauf avis contraire (`DEC:85`).

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
5. **Pas de seconde source de vérité** (`REVUE §5.1`) : invitation, accords,
   pièce et ADM-02, `/attente` et `etat_dossier()`, messagerie métier,
   `notifications`, `audit_logs`, motif d'import du 12/10, `BarreSelection`
   (promue), salle vidéo `/salle` sont réutilisés.
6. **Hors périmètre** : intégration d'un prestataire de paiement (`DEC:28`), envoi
   de courriels (`DEC:33`), refonte LiveKit, production sans feu vert (`DEC:25`),
   les cinq défauts hors module (section 13).

---

## 2. Le parcours en salles

Les salles sont des **étapes de recrutement**, jamais des communautés : aucun
candidat ne voit un autre candidat (`SPEC §15` point 2). Les codes restent
internes ; seuls les noms s'affichent (noms proposés, `CAND-Q12`).

| Code d'étape | Nom affiché | Objet |
| :--- | :--- | :--- |
| `recue` | aucun (vue de la direction) | ligne gardée par la direction pour suivre une personne des formulaires ; pas encore de compte |
| `invitee` | aucun (vue de la direction) | invitation émise, pas encore consommée |
| `prequalification` | **Salle d'examen** | savoir si la candidature mérite les vérifications, et si l'académie peut payer |
| `verifications` | **Salle de vérification et d'entretien** | vérifier, rencontrer, réunir les accords et la pièce |
| `confirmee` | **Salle des prêts à enseigner** | compte actif, affectable |

### 2.1 Ce qui se demande, à quel moment

Mise à jour de `REVUE §6.2` par `DEC:28`, `:34`, `:45`, `:63-64`.

| Moment | Demandé | Jamais avant |
| :--- | :--- | :--- |
| Inscription (lien public ou code) | courriel confirmé, nom affiché, genre, langue de l'interface (`fr` ou `ar`), accord de confidentialité | - |
| Salle d'examen | langue maternelle et langues d'explication (codes) ; niveau de mémorisation déclaré ; riwaya ; ijaza présentable oui ou non ; expérience avec les débutants ; disponibilités déclarées (créneaux et fuseau) ; heures par semaine ; date de début ; publics enseignables ; pays de résidence ; pays de versement ; fuseau IANA ; compte bancaire oui ou non ; opérateurs accessibles ; accord de rémunération ; cadre religieux et pédagogique | - |
| Salle de vérification et d'entretien | contrat `teacher_nda`, avis `recording_and_control_notice`, pièce d'identité ; à l'entretien : constat (niveau observé, riwaya, ijaza présentée), compte rendu, avis | salle d'examen terminée et paiement compatible |
| Après l'entrée en salle 3 | photo, titre, `weekly_availability` ; code de conduite tant que le lot `conduite` n'est pas passé (section 13) | l'entrée en salle 3 |
| Premier versement | coordonnées financières, par CPT-13 | salle 3 et début des cours |

Ijaza, diplôme et attestation se **présentent à l'entretien** et se constatent
dans le compte rendu ; aucun dépôt dans l'app pour l'instant (`DEC:45`).

La page d'accords existante montre les textes requis **à l'étape courante** : le
cadre religieux en salle d'examen, le contrat et l'avis en salle 2. Chaque texte
s'accepte une fois ; l'app ne renvoie jamais en arrière pour cocher après coup
(`C/DECISION-ENTREE-2026-10-17.md:30-32`).

### 2.2 Les trois salles

| | Salle d'examen (`prequalification`) | Salle de vérification et d'entretien (`verifications`) | Salle des prêts à enseigner (`confirmee`) |
| :--- | :--- | :--- | :--- |
| **Qui entre** | toute personne inscrite par le lien public ou une invitation consommée, de tout pays (`DEC:28`) | la candidature admise par la direction, cadre religieux accepté et paiement compatible (4.2, ligne 10) | seule la validation de la pièce dans ADM-02, acceptée quand les sept autres contrôles sont vrais (section 5) : « affectable à 100 % » (`DEC:24`) |
| **Le candidat voit** | `/attente` étendu et `CAND-01` : d'abord les conditions de rémunération, lues au serveur, jamais écrites en dur (`CAND-BR-12`) ; le questionnaire en cartes, choix dans des listes ; la case du cadre religieux ; son état ; sa conversation | la page d'accords (contrat, avis) ; le dépôt de pièce existant (`supabase/functions/piece-identite-depot/index.ts`) et son état (« à corriger » avec quoi) ; « Mon entretien » (`CAND-02`) ; sa conversation | son espace enseignant ; `/attente` ne le retient plus ; les prérequis de travail existants (`M/20261016100500_contrats_travail_prerequis.sql:49-74`) |
| **La direction voit** | `ADM-20` filtré sur la salle ; `ADM-21` : réponses, déclaration de paiement, contrôle `paiement_compatible` | la vue Entretiens d'`ADM-20` ; dans `ADM-21`, les huit contrôles (vrai ou faux, cause) et le lien vers ADM-02 | le filtre de la salle ; les alertes « bloquées » et « confirmées indisponibles », jamais confondues |
| **Gestes** | demander un complément ; confirmer ou infirmer le moyen de paiement ; admettre en salle 2 ; pause ; refus | planifier, consigner, reprogrammer l'entretien ; pièce à corriger ; valider la pièce ; pause ; refus | restreindre, lever la restriction ; noter ou lever une indisponibilité |
| **Sorties** | salle 2 ; à compléter ; maintenue faute de moyen de paiement (jamais un refus, libre de partir) ; refusée ; retirée ; pause | salle 3 ; entretien à replanifier ; pièce à corriger ; refus (dont refus définitif de pièce) ; retrait ; pause | jamais de retour d'étape ; restriction (manuelle, ou automatique quand un contrôle tombe) ; indisponibilité ; l'historique reste |

**Entrée en salle 3, dans une seule transaction** : pièce `approved`, compte
`active` sous la garde d'activation étendue, candidature `confirmee`, profil
enseignant unique. Le refus d'une nouvelle pièce d'une enseignante déjà active
**ne change pas** : `disabled` sans autre pièce approuvée
(`M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:51-60`, `DEC:24`) ;
la candidature trace une restriction « pièce ».

---

## 3. Entrées

### 3.1 Le lien public (`CAND-Q03`, `CAND-Q17`)

Un lien partageable, sur la page « recrutement » du site public, ouvre la page
d'inscription de l'app (`CAND-04`). C'est l'entrée ordinaire après l'import ; plus
d'imports périodiques (`DEC:26`, `:40`). Il rouvre une entrée publique fermée
depuis le 17/10 (`C/DECISION-ENTREE-2026-10-17.md`) : les six conditions de
`DEC:49-66` deviennent des règles.

| # | Condition (`DEC`) | Règle | Lot |
| :-- | :--- | :--- | :--- |
| 1 | Compte candidat seulement (`:50-51`) | l'inscription crée un compte `pending_kyc` confiné à `/attente` et une candidature `prequalification/a_completer` de type `enseignant` ; aucune capacité ni RPC d'enseignant, aucun jeton de cours, absent de toute liste d'enseignants. Aujourd'hui `inscrire_enseignant_invite` crée un profil `teacher` `pending_kyc` avec une fiche `teacher_profiles` vide (`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`) : L3 fixe la forme en base, la même pour les deux portes | L3 |
| 2 | Contre les robots (`:52-53`) | la candidature n'existe qu'après confirmation du courriel (aujourd'hui `enable_confirmations = false`, `supabase/config.toml:229`) ; plafond d'inscriptions par heure dans `app_config`, refus neutre au-delà ; la limite par adresse IP reste (`sign_in_sign_ups = 30` par 5 minutes, `config.toml:210`) ; captcha possible (`config.toml:216-219`) | L3 |
| 3 | Courriel obligatoire (`:54-56`) | l'app se connecte par courriel (`lib/core/auth/service_auth.dart:52-56`) : pas de courriel, pas d'inscription ; le message WhatsApp aux personnes sans courriel leur dit d'en créer un | L3 |
| 4 | Personnes des formulaires (`:57-62`) | reconnues et pré-remplies (3.4) ; aucune candidature créée à leur place ; tout le monde complète pays, paiement et cadre religieux | L3 |
| 5 | Confidentialité (`:63-64`) | accord de confidentialité versionné, accepté à l'inscription, enregistré avec version et date | L3 |
| 6 | Mise en ligne (`:65-66`) | le lien ne va sur le site qu'une fois L1 à L3 livrés, la confirmation de courriel en service (SMTP, 7.3) et le feu vert du directeur | - |

### 3.2 L'import ponctuel des formulaires Google

Une seule fois, pour les personnes des formulaires (`DEC:40`). Même motif serveur
que l'import du 12/10 : analyse au serveur, essai à blanc, confirmation
idempotente, aal2 exigée **en base**, journal portant la référence source
(classeur, onglet, horodatage), jamais le nom (`REVUE §7`).

| Source | Traitement |
| :--- | :--- |
| A1 et A2 (questionnaire arabe, 14 colonnes) | importées : 440 lignes, 409 personnes après rapprochement des doublons de A (`MAP §6`) |
| B (« Enseignants (Réponses) », 11 lignes) | `dejaConnue`, rien n'est écrit : déjà dans l'import du 12/10 (`MAP §1`) |
| Liens Drive vers des photos d'identité | jamais importés |

**Ce que l'import écrit** : des **réponses importées**, une par référence source,
qui servent à reconnaître et à pré-remplir (3.4). Ni compte, ni invitation, ni
pièce, ni accord, ni candidature à la place de la personne (`DEC:60`).
**Exception voulue par la direction** : pour suivre une personne (l'inviter, ou
noter le lien envoyé par WhatsApp), elle peut **garder une ligne `recue`**. C'est
une ligne de suivi, pas une candidature déposée : elle n'entre en salle d'examen
que quand la personne s'inscrit et y est rattachée.

**Les huit pas d'`ADM-23`** (`SPEC §9`, `REVUE §7`) : (1) dépôt d'un export CSV,
sans connexion à l'API Google ; (2) aperçu, contacts masqués ; (3) association des
colonnes sur en-têtes normalisés, avec la table des libellés (`MAP §2`, `§3`) ;
(4) doublons probables et lignes incomplètes ; (5) erreurs et avertissements ligne
par ligne ; (6) quatre compteurs (nouvelles, déjà connues, ignorées, à corriger),
un écart avec les comptes de référence se lit avant de confirmer ;
(7) confirmation idempotente ; (8) rapport final ligne par ligne, sans nom.

| Donnée (`MAP §4`, `§5`) | Règle |
| :--- | :--- |
| Doublon | clé courriel **ou** téléphone normalisés, jamais le nom ; la ligne la plus récente est proposée, les autres restent en historique (`DEC:39`) ; la direction choisit par groupe, un groupe sans choix reste « à corriger » |
| Téléphone, courriel | téléphone jamais complété ni deviné, sinon « indicatif à confirmer » ; courriel absent ou mal formé : « courriel à obtenir », ni clé ni adresse d'invitation |
| Créneaux | heure locale et fuseau `Asia/Riyadh` gardés, jamais convertis, jamais recopiés dans `weekly_availability` (`C/02_ARCHITECTURE_ET_SECURITE.md:23`) |
| Réponses contradictoires (24 lignes) | importées telles quelles, avec avertissement |

### 3.3 L'invitation, une étape (`CAND-Q04`)

L'onglet Invitations de Personnes devient « Candidatures » (`ADM-20`) : pas de
septième onglet, une seule liste par personne (`DEC:27`,
`lib/core/admin/admin_domaine.dart:266-293`).

| Cas | Règle |
| :--- | :--- |
| Ligne `recue` au courriel valide | le serveur émet l'invitation existante (`inviter_enseignant`, code lié au courriel, 14 jours, `M/20261016100300_contrats_invitations_enseignant.sql:111-161`) et écrit un courriel à envoyer (modèle `invitation`, 7.3) qui mène à la page d'inscription ; le code se saisit sur la page, jamais dans l'adresse. Tant que l'envoi n'existe pas, la direction voit le code comme aujourd'hui (`lib/features/admin_invitations/invitations_page.dart:128-129`) et l'écran dit « Courriel pas encore envoyé » |
| Sans courriel valide | `courrielAbsent` ; la direction envoie le lien public par WhatsApp, hors de l'app (7.4) |
| Expiration à 14 jours | retour en `recue`, trace gardée, réinvitation possible |
| Invitation consommée ou lien public | **même compte et même candidature** ; seule la provenance diffère |
| Reprise (L3) | invitations déjà émises : lignes `invitee` ; comptes `pending_kyc` nés d'une invitation : candidature en `prequalification/a_completer`, accords signés et pièce déposée gardés |

### 3.4 Reconnaissance et pré-remplissage

| Correspondance avec des réponses importées | Effet |
| :--- | :--- |
| même courriel, **confirmé** à l'inscription | rattachement automatique ; pré-remplissage du questionnaire, à relire ; une ligne `recue` éventuelle devient cette candidature |
| même téléphone seulement | rien n'est montré à la personne ; rattachement **proposé à la direction**, appliqué par un geste journalisé, puis pré-remplissage |
| nom seul | jamais |

Le téléphone ne suffit pas : aucun canal ne le vérifie (SMS désactivé,
`REVUE §3.6`). Montrer d'anciennes réponses sur un numéro tapé exposerait les
données d'une autre personne.

Pré-remplis : colonnes C et E à L de A (`MAP §2`). Jamais pré-remplis : pays,
fuseau, publics, paiement, cadre religieux, riwaya. Le genre se déclare à
l'inscription (obligatoire) et fixe la portée de lecture dès la première ligne ;
`profiles.gender` reste écrit par la direction seule
(`M/20261017100700_af_l1_07_genre_colonne_privilegiee.sql:27`) ; L1 fixe comment le
genre déclaré l'alimente.

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
| Pièce | lue dans `kyc_documents`, jamais recopiée ; deux issues de refus : `a_corriger`, refus définitif (`DEC:41`) | existant, étendu |
| Paiement | `inconnu`, `a_verifier`, `compatible`, `incompatible`, calculé (5.1) | réponses et référentiel |
| Entretien | état (6.2) ; issue `tenu`, `annule`, `manque_candidat`, `manque_intervieweur` | entretien |
| Courriel | `a_envoyer`, `envoye`, `echec` | file des courriels |
| Coordonnées financières | `absentes`, `enregistrees` ; jamais exigées avant le premier versement | CPT-13 |

Une pièce n'expire pas tant qu'aucune date de validité n'est saisie (`DEC:41`).
Elle est purgée à 90 jours (`kyc_retention_days`,
`M/0004_inscription_kyc_appairage.sql:117`).

### 4.2 Transitions

Chaque transition passe par une RPC qui vérifie la règle en base, exige le motif
quand la colonne le dit, prend `versionAttendue` et `cleIdempotence`, rend
`TransitionInterdite` depuis un état qui ne le permet pas, et journalise ancien
état, nouvel état, auteur, horodatage et motif. « Direction » veut dire la
capacité `candidatures.decider`, dans la portée de genre (section 8).

| # | De | Vers | Qui | Vérifié en base | Motif |
| :-- | :--- | :--- | :--- | :--- | :--- |
| 1 | import confirmé | réponses importées | direction (`candidatures.importer`) | aal2 ; référence source unique ; rien d'autre n'est écrit | non |
| 2 | réponses importées | `recue` | direction (« garder pour suivi ») | une ligne par référence ; aucun compte | non |
| 3 | `recue` | `invitee` | direction, ligne ou lot | courriel valide ; aucun compte existant ; `inviter_enseignant` ; un courriel `a_envoyer` | non |
| 4 | `invitee` expirée | `recue` | automatique | la trace de l'invitation reste | non |
| 5 | rien, `recue` ou `invitee` | `prequalification/a_completer` | la personne, en s'inscrivant | courriel confirmé ; accord de confidentialité à la version courante ; plafond horaire ; aucune autre candidature en cours du même type pour ce compte ; rattachement selon 3.4 | non |
| 6 | `a_completer` | `en_examen` | le candidat (envoi) | questionnaire complet à la version courante ; accord de rémunération ; cadre religieux à la version requise | non |
| 7 | `en_examen` | `a_completer` | direction | éléments manquants nommés au candidat | **oui** |
| 8 | `en_examen` | `paiement_non_disponible` | automatique | aucun moyen déclaré ne croise une ligne `confirme` du pays de versement ; cause tracée | non |
| 9 | `paiement_non_disponible` | `a_completer` | automatique | une ligne du pays passe `confirme` ; « moyen de paiement à déclarer » nommé ; notification et courriel | non |
| 10 | `en_examen` | `verifications/entretien_a_planifier` | direction (« admettre en salle de vérification ») | `paiement_compatible` vrai ; cadre religieux à la version requise ; questionnaire complet | non |
| 11 | `entretien_a_planifier` | `entretien_planifie` | direction | début UTC futur, durée ; intervieweur de la direction du même côté (ou super-admin, journalisé) ; fuseau du candidat connu ; séance `entretien` créée ; notification et courriel | non |
| 12 | `entretien_planifie` | `entretien_a_planifier` | direction | issue `annule`, `manque_candidat` ou `manque_intervieweur` gardée ; séance annulée | **oui** |
| 13 | `entretien_planifie` | `decision_en_attente` | l'intervieweur désigné | issue `tenu` ; compte rendu ; constat (niveau observé, riwaya, ijaza présentée) ; avis | non |
| 14 | `decision_en_attente` | `confirmee` | direction, en **validant la pièce** dans ADM-02 | les sept autres contrôles vrais (section 5), sinon `ControlesNonSatisfaits` nommés et rien n'est écrit ; validation, activation sous la garde et entrée en salle 3 en une transaction | non |
| 15 | `verifications`, tout état | même état, pièce `a_corriger` | direction (ADM-02) | ce qui est à corriger dit par modèle ; le candidat redépose | **oui** |
| 16 | toute étape en cours | `refusee` | direction | motif interne et modèle de message ; le refus définitif de pièce (pièce fausse, identité discordante) y mène ; entretien planifié annulé | **oui** |
| 17 | toute étape en cours | `retiree` | le candidat (`CAND-03`) ; ou la direction, pour une demande reçue par la conversation ou par courriel | entretien planifié annulé, son issue reste ; canal et date tracés | **oui** si direction |
| 18 | tout état | pause posée ou levée | direction | l'étape ne change pas ; modèle de message à la pose | **oui** à la pose |
| 19 | `refusee`, `retiree` | étape et état d'origine | direction (« rouvrir ») | contrôles de l'étape revérifiés ; questionnaire à la version courante | **oui** |
| 20 | `confirmee` | `confirmee` + restriction | direction, ou automatique quand un contrôle tombe (ligne du référentiel, nouvelle pièce refusée) | sort de l'affectabilité ; étape et historique gardés | **oui** |
| 21 | `confirmee` + restriction | `confirmee` | direction | contrôles revérifiés | **oui** |
| 22 | `confirmee` | indisponibilité notée ou levée | direction | étape inchangée ; exclue de l'affectation, comptée à part | non |

Une sortie décidée par la direction sans demande du candidat est un **refus
motivé**, jamais un retrait. Le candidat ne voit jamais le motif interne, seulement
le texte du modèle (`PORTS §5` point 4). **Gestes groupables** (`ADM-22`) :
inviter, mettre en pause, lever la pause, refuser, consigner le lien envoyé par
WhatsApp. Tout autre geste rend `GesteNonGroupable`.

### 4.3 Règles de blocage

**Refusés en base :**
- entrer en salle 2 sans `paiement_compatible` ou sans cadre religieux ;
- entrer en salle 3 avec un contrôle faux, **par quelque voie que ce soit** : la
  garde `guard_teacher_activation_signatures()`
  (`M/0089_teacher_contract_activation_guard.sql:24-82`), étendue aux contrôles,
  joue sur toute activation, `decider_dossier()` compris ;
- inviter une ligne sans courriel valide ; importer ailleurs qu'en réponses
  importées ; exposer une pièce, un contact ou un genre dans une liste ;
- planifier sans fuseau connu ou avec un intervieweur hors portée ; donner un jeton
  d'entretien à un autre que le candidat convoqué et l'intervieweur ;
- pendant une pause, tout geste autre que lever la pause, refuser ou retirer.

**Ne rétrograde jamais** : une indisponibilité, une pause, un critère ou une
version de questionnaire changés après une décision, un contrôle qui tombe après la
salle 3 (il pose une restriction, `PORTS §5` point 2). En salle 2, un contrôle qui
tombe bloque l'entrée en salle 3 et compte dans « bloquées », sans retour en
salle 1. **Nouvelle version d'un texte** : les candidatures en cours la
ré-acceptent avant la salle 3 ; les personnes en salle 3 gardent la leur
(`REVUE §11`).

---

## 5. Les huit contrôles nommés

Une seule fonction en base (nom indicatif `private.candidature_controles`) les
calcule. Elle est lue par `ADM-21`, par la validation de pièce et par la garde
d'activation. Chaque bascule est journalisée avec sa cause (décision ADM-02, ligne
du référentiel, entretien consigné). Un autre type porte sa propre liste.

| Contrôle | Vrai quand | Lu dans | Exigé pour |
| :--- | :--- | :--- | :--- |
| `paiement_compatible` | un moyen déclaré, confirmé par la direction, croise une ligne `confirme` du pays de versement | réponses et référentiel (L6) | salle 2 et salle 3 |
| `accords_signes` | contrat `teacher_nda`, avis `recording_and_control_notice` et cadre religieux acceptés aux versions requises ; plus `teacher_conduct_code` dès le lot `conduite` (section 13) | `contract_acceptances`, `contract_required_versions` | cadre : salle 2 ; tous : salle 3 |
| `profil_renseigne` | langues (codes), niveau déclaré, publics, fuseau IANA, disponibilités déclarées avec leur fuseau, pays de résidence et de versement | réponses ; jamais `weekly_availability`, écrit par un enseignant actif seulement | salle 3 |
| `entretien_conclu` | un entretien `tenu`, compte rendu enregistré, avis favorable, mené par un intervieweur autorisé de ce côté | entretiens (L4) | salle 3 |
| `evaluation_validee` | constat structuré présent : niveau observé, riwaya, ijaza présentée ou non (`DEC:31`, `:45`) | constat de l'entretien | salle 3 |
| `profil_unique` | aucun autre compte ni candidature en cours du même type pour la même personne (courriel confirmé, téléphone normalisé) sans décision de la direction ; aucun profil enseignant déjà actif | profils, candidatures | salle 3 |
| `aucune_restriction` | ni restriction ni pause active | candidature | salle 3 |
| `piece_validee` | pièce `approved` | `kyc_documents` | c'est le geste d'entrée en salle 3 ; refusé tant qu'un des sept autres est faux (`DEC:24`) |

La décision finale humaine de la spec (`SPEC §3`) est cette validation, prise après
l'entretien. Un avis défavorable laisse `entretien_conclu` faux ; la direction
refuse alors avec motif.

### 5.1 Compatibilité de paiement (`CAND-Q05`)

**Un référentiel déclaratif** : il dit, pays par pays, quel moyen fonctionne, sans
rien verser ni appeler aucun prestataire (`DEC:28`). Une ligne : pays (ISO 3166),
méthode (`virement_bancaire`, `mobile_money`), opérateur, prestataire (une
colonne, `lib/core/capacites/port_capacite_payout.dart:5-8`), devise, état
(`confirme`, `en_verification`, `indisponible`), vérifié le, par, notes ;
`confirme` exige une date et un responsable (`PORTS §4`).

**État initial, posé par la décision du 21/10** : chaque pays **hors d'Afrique**,
Arabie saoudite comprise, a `virement_bancaire` à `confirme`, vérifié le
21/10/2026 par le directeur (`DEC:28`). Chaque pays **d'Afrique** a toutes ses
lignes à `en_verification`, compte bancaire compris, jusqu'à la réponse ouverte
de `CAND-Q05`.

**Ce que le candidat déclare** (`CAND-01`) : pays de résidence ; pays de versement
(liste ISO complète, Arabie saoudite et Yémen compris, `REVUE §4` E8) ; compte
bancaire oui ou non ; opérateurs, parmi les seules lignes `confirme` de son pays
de versement ; la case « J'accepte de recevoir ma rémunération par au moins un
moyen validé par Rewayah » (`SPEC §4.2`). Sans ligne confirmée dans son pays, il
lit une phrase à la place des opérateurs, jamais une liste vide. Jamais demandé :
numéro de compte, IBAN, numéro de portefeuille, identifiant, code ; le numéro
WhatsApp n'est jamais réutilisé comme numéro de portefeuille.

| État | Quand |
| :--- | :--- |
| `inconnu` | aucune déclaration |
| `a_verifier` | la déclaration croise une ligne `confirme` ; la direction ne l'a pas encore confirmée |
| `compatible` | la direction a confirmé le moyen (`confirmerMoyenPaiement`) |
| `incompatible` | moyen infirmé, ou aucune ligne `confirme` croisée |

- Hors d'Afrique sans compte bancaire : `incompatible` ; la candidature reste en
  salle d'examen (`paiement_non_disponible`), issue `en_cours`.
- En Afrique, tant que `CAND-Q05` est ouvert : `incompatible`, même avec un compte
  bancaire. Une ligne `en_verification` ne rend jamais `compatible`.
- **Ligne qui quitte `confirme`** (`ADM-24`) : restriction automatique « paiement
  à revérifier » pour les personnes en salle 3 qui n'avaient qu'elle ; en salle 2,
  le contrôle passe faux et la candidature compte dans « bloquées » ; les autres ne
  bougent pas. `enregistrer` rend l'`impact` (nombre de restrictions) ; alerte à la
  direction et à la comptabilité.
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
réception, dernière activité, date d'entretien.

---

## 6. L'entretien dans l'app (`CAND-Q06`, `Q08`, `Q09`, `Q19`, `Q22`)

### 6.1 La séance d'entretien (L4, `CAND-BR-08`)

| Règle | Aujourd'hui | Ce que L4 pose |
| :--- | :--- | :--- |
| Type | `session_type` n'admet que `standard` et `child` (`M/0001_fondations.sql:170`) | type `entretien` |
| Qui entre | jeton refusé à un compte `pending_kyc` (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`) | le seul candidat convoqué, `pending_kyc` admis pour cette séance ; l'intervieweur ; personne d'autre |
| Intervieweur | `entretiens.mener` sans titulaire | un membre de la direction (`DEC:42`), du même côté que le candidat ; le super-admin par exception journalisée (`DEC:30`) |
| Paie | une séance close déclenche la paie (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`) | **jamais payée** : exclue du déclencheur |
| Effets de bord | clôture automatique (`M/20261018180000_ses_cloture_auto.sql:67-97`), chevauchement sur `teacher_id` (`M/0005_dashboards_affectation_regles.sql:640-645`), `mes_seances_v` (`M/20261017100400_af_l1_04_mes_seances_v_par_role.sql:28-43`), observation par le contrôleur | exclue de chacun ; la forme de `teacher_id`, obligatoire aujourd'hui, est fixée par L4 |
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
  d'intervieweur de l'autre côté, hors l'exception du super-admin.

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
complément demandé ; admise en salle de vérification ; pièce à corriger ;
entretien planifié, annulé ou reprogrammé ; pause posée ou levée ; refus ; retrait
enregistré ; entrée en salle des prêts à enseigner ; moyen de paiement désormais
possible ; nouveau message. Texte tiré d'un modèle validé, en `fr` ou `ar`.

### 7.3 La file des courriels (`CAND-Q10`, `CAND-BR-16` révisé)

Ce module **n'envoie aucun courriel**. Il écrit la liste des courriels à envoyer ;
l'envoi, construit par la session du site public, la lit (`DEC:33`).

| Champ | Règle |
| :--- | :--- |
| destinataire | le profil ; pour une ligne `recue`, le courriel importé valide |
| modèle | liste fermée : `lien_inscription`, `invitation`, et les événements de 7.2 |
| langue | `fr` ou `ar` : celle de l'interface choisie, sinon `ar` pour une ligne importée de A |
| paramètres | dates, liens ; jamais un texte libre, un motif interne, une réponse ni un constat |
| état | `a_envoyer` (écrit par ce module), puis `envoye` avec la date ou `echec` avec la cause (écrits par l'envoi seul) |
| droits | ce module écrit par RPC, l'envoi par sa fonction serveur ; aucun candidat ne lit la file |
| à l'écran | « Courriel pas encore envoyé » tant que `a_envoyer` ; « Courriel envoyé le … » seulement sur `envoye` ; « Courriel non parti » sur `echec` ; jamais « reçu », jamais « lu » |

Ce tableau est le **contrat à remettre à la session du site public**. La
confirmation du courriel à l'inscription (3.1, condition 2) demande le même
service d'envoi ; le SMTP est commenté (`supabase/config.toml:239-247`) : le lien
public attend.

### 7.4 La seule exception WhatsApp

Le directeur n'admet WhatsApp que pour **envoyer le lien d'inscription aux
personnes des formulaires sans courriel** (`DEC:26`, `:29`) : un message par
personne, jamais un groupe ni une liste de diffusion ; le message dit de créer un
courriel (`DEC:56`) ; la direction le consigne par `consignerPrevenu` (canal
`whatsapp`, modèle `lien_inscription`, date), jamais un texte libre. L'accord de
contact donné dans A (colonne M) ne vaut que pour ce contact (`MAP §2`).

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
| `candidatures.lire` | direction, de son côté ; super-admin les deux côtés, journalisé | réponses, contrôles, étape, historique, réponses importées | pièce hors ADM-02 |
| `candidatures.contact` | direction nommée, de son côté | courriel, téléphone, recherche par téléphone ; chaque lecture journalisée | - |
| `candidatures.importer` | direction, aal2 exigée en base | import, essai à blanc, rapport | réponses hors de son côté |
| `candidatures.decider` | direction, de son côté | transitions, pièce dans ADM-02, lots | - |
| `entretiens.mener` | direction (`DEC:42`), de son côté ; super-admin par exception journalisée | réponses utiles à l'entretien, date, fuseaux, constat, compte rendu | téléphone, pièce, autres candidatures |
| `candidatures.messages` | direction, de son côté | le fil `candidature` | les fils de l'autre côté |
| `paiement.referentiel.ecrire` | direction, comptabilité | référentiel, impact d'un changement | réponses, identité |
| candidat | le titulaire | sa candidature, son fil, son entretien, ses notifications | tout autre candidat ; listes ; compteurs ; motifs internes ; compte rendu ; constat |
| contrôleur, enseignant, tuteur, élève | - | rien | tout |

### 8.2 Séparation femmes et hommes, en base (`CAND-Q07`)

La RLS et chaque RPC du module bornent la direction à son côté, sur le modèle de
`read_kyc_documents()` : filtre par genre du lecteur, refus si ce genre est
inconnu, journal de chaque lecture de liste. Le super-admin lit les deux côtés,
par l'exception journalisée de `M/0088_kyc_super_admin_gender_exception.sql`
(`DEC:30`). Portée : candidatures, réponses, réponses importées, contacts,
entretiens, conversation, historique **et compteurs**. « Hors portée » et
« absente » sont deux erreurs distinctes. Un masquage à l'écran ne compte pas
(`SPEC §7`).

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
- B n'a recueilli aucun consentement, A un accord de contact seulement
  (`REVUE §2.2`) ; l'accord de confidentialité de l'inscription couvre la suite.

---

## 9. Langues

**Le parcours candidat est livré en français et en arabe** (`DEC:36`) :
inscription, questionnaire, page d'accords (texte du cadre religieux dans les deux
langues, soumis au directeur avant publication, `DEC:34`), états de `/attente`,
« Mon entretien », retrait, conversation, notifications, modèles de courriel.
Aujourd'hui l'espace `recrutement` n'a que 17 clés traduites sur 106
(`REVUE §3.6`). Les écrans de la direction suivent la règle générale : le
français fait référence, les autres langues suivent le sens.

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
- l'équivalence `ff` (peul) et `poular` reste à valider (`MAP §3.2`) : d'ici là,
  `ff` s'importe hors référentiel.

Les réponses du module sont en codes dès le premier jour ; `teacher_profiles`
reste en noms jusqu'au lot `langue` (section 13).

---

## 10. Écrans à inscrire au catalogue

À inscrire dans `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md` (prochain document),
chacun avec sa fiche (Tâche, Contenu, Entrée, États, Droits, Contrat serveur)
**avant tout fichier `.dart`**, puis une `UX_REVIEW_CAND-<n>.md` (DESIGN-GOV).
Codes libres : `ADM-20` et au-delà, préfixe `CAND-` (`REVUE §10`).

**Règles communes :**
- cinq états obligatoires : `loading` (`Skeleton`), `content`, `empty`
  (`EmptyState`), `error` (avec reprise), `offline` (bandeau, rien d'écrit sans
  réseau) ; selon l'écran : hors portée, données partielles (« Disponible au
  branchement serveur »), action en cours, succès seulement après la réponse du
  serveur ;
- **un seul bouton plein par écran** (K-56, `C/REVUE-DIRECTEUR-2026-10.md:12`,
  `DEC:37`), vérifié par `verifierUnSeulBoutonPlein` ; le lien d'entretien d'une
  ligne est secondaire ; un état critique porte texte et icône, jamais la couleur
  seule ;
- bureau : file et détail ; tablette : deux volets ; mobile : cartes ; 360, 768,
  1440 ; clair et sombre ; aperçu de lot et mappage d'import en pages, pas en
  modales (`tool/verifier_jetons.dart:306-316`).

**Côté candidat :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `CAND-04` | Postuler (page d'inscription du lien public ; route publique proposée `/postuler`) | créer le compte candidat | créer le compte | courriel à confirmer ; plafond atteint ; courriel déjà utilisé ; code d'invitation invalide ou expiré ; lien pas encore ouvert | L3 |
| `/attente` (existant, étendu) | portail de la candidature | dire où en est la candidature et la prochaine action | la prochaine action | à compléter (liste) ; en examen ; versement pas encore possible ; pièce à corriger ; en pause (modèle, reprise) ; refusée (modèle) ; retirée | L2 |
| `CAND-01` | Questionnaire de la salle d'examen | conditions de rémunération, puis réponses | « Envoyer ma candidature » | pré-rempli à relire ; questionnaire périmé ; aucun moyen confirmé dans le pays ; réponses incomplètes nommées | L2 ; opérateurs L6 ; pré-remplissage L3 |
| Page d'accords (existante) | une case « Cadre religieux et pédagogique » de plus | accepter les textes de l'étape | « Suivant » existant | nouvelle version à ré-accepter | L2 |
| `CAND-02` | Mon entretien | voir et rejoindre | « Rejoindre l'entretien » à l'ouverture | les sept états de 6.2 | L4 |
| `CAND-03` | Retirer ma candidature | retrait, effet dit avant (entretien annulé, réouverture par l'académie seulement) | aucun (`ConfirmDestructive`) | retrait en cours ; déjà retirée | L2 |
| `CAND-05` | Écrire à l'académie (fil « Ma candidature ») | conversation | envoyer | fil vide ; message non parti (hors ligne) | L5 |
| `/salle` (existante, mode entretien) | l'entretien | - | celui de la salle | aucune mention ; jeton refusé ; fin de séance | L4 |

**Côté direction (Personnes, sauf `ADM-24`) :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADM-20` | Candidatures (remplace l'onglet Invitations) | file dense : recherche, puces des salles avec compteur, autres axes sous « Plus », tri au serveur, pagination, sélection multiple, quatre alertes, vue Entretiens | aucun ; « Agir sur la sélection » quand une sélection existe | recherche sans résultat (filtres rappelés) ; hors portée ; alertes à zéro | L1 ; gestes L2 |
| `ADM-21` | Candidature | dans l'ordre : étape et issue, blocages, prochaine action, réponses, contrôles nommés, pièce (lien ADM-02), entretien, historique | la prochaine action, une seule | bloquée (contrôle nommé) ; contact masqué ; hors portée ou absente | L1 ; gestes L2 ; entretien L4 |
| `ADM-21F` | Fil « Candidature » | conversation côté direction | envoyer | fil vide | L5 |
| `ADM-22` | Action groupée | liste ciblée (nom, étape, aucun contact), effet exact, exclus avec raison, saisie du nombre, rapport ligne par ligne | confirmer | jeton périmé ; nombre discordant ; lot partiellement refusé ; issue inconnue | L2 ; inviter L3 |
| `ADM-23` | Import des formulaires | les huit pas de 3.2 ; route distincte de `/admin/personnes/import` | importer, au pas 7 | fichier illisible ; mappage incomplet ; doublons à choisir ; écart des compteurs ; double vérification requise | L3 |
| `ADM-24` | Compatibilité de paiement par pays (Finance, `DEC:85`) | référentiel | enregistrer | confirmation sans date ni responsable refusée ; impact (N restrictions) | L6 |
| ADM-02 (existant, étendu) | revue de pièce | valider (entrée en salle 3), « à corriger », refus définitif | valider | contrôles manquants nommés ; validation refusée par le serveur | L2 |

**Quatre alertes d'`ADM-20`, jamais confondues** (`REVUE §10.2`) : bloquées
(contrôle faux nommé ou restriction) ; entretiens en retard ; informations
manquantes (`a_completer`, « courriel à obtenir », « indicatif à confirmer ») ;
confirmées indisponibles. Une pause n'entre dans aucune. **Composants** :
`BarreSelection` à promouvoir du Comptable vers `lib/core/widgets/`, jamais
recopiée ; ligne d'historique neuve ; le reste réutilisé tel quel (`REVUE §10.3`).

---

## 11. Lots serveur

Tous sur la **base de test** ; aucune application en production sans le feu vert
du directeur (`DEC:25`). Chaque lot livre son fichier de scénarios, rejoué sur
Postgres nu. L'ajout à `.github/workflows/ci.yml` demande un ordre du directeur
(`.claude/hooks/garde.py:22-27`) ; d'ici là, `tool/rejouer_scenarios.sh`.

| Lot | Contenu | `CAND-BR` | Questions | Statut au 21/10 | Prérequis |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **L1** socle | tables (type, candidature, questionnaire versionné, réponses, réponses importées) ; lectures cloisonnées par genre (RLS, liste paginée, détail, contact journalisé) ; historique sans nom | `01`, `02`, `03`, `07` | `Q02`, `Q04`, `Q07`, `Q20` | **en cours d'écriture** dans une autre session ; aucune migration du module sur cette branche à la rédaction | - |
| **L2** transitions et contrôles | une RPC par geste ; les huit contrôles ; `decider_dossier()` : validation acceptée seulement salle 2 terminée ; garde `0089` étendue ; deux issues de pièce ; lots ; `etat_dossier()` étendu, questionnaire, envoi, retrait ; sorte d'accord du cadre religieux ; conditions de rémunération lisibles en attente | `04`, `05`, `06`, `10`, `11`, `12` | `Q01`, `Q08`, `Q11`, `Q18` | à écrire | L1 ; `CAND-BR-11` après le lot `conduite` (`CORR §7`) |
| **L3** inscription publique et import | compte candidat ; courriel confirmé ; plafond horaire ; accord de confidentialité ; rattachement ; alignement de `inscrire_enseignant_invite` ; geste `inviter` ; reprise des invitations ; import ponctuel | `17`, `09`, part de `04` | `Q03`, `Q04`, `Q16`, `Q17` | à écrire | L1, L2 ; mise en ligne : service d'envoi et feu vert |
| **L4** entretiens dans l'app | type `entretien`, rôles, jeton du candidat convoqué, exclusions (paie, clôture, chevauchement, vues, contrôleur), mode sans mention, planification, constat, compte rendu | `08` | `Q06`, `Q07`, `Q08`, `Q09`, `Q19`, `Q22` | à écrire | L2 ; revue de sécurité (jeton, déclencheur de paie) |
| **L5** conversation, notifications, file des courriels | objet `candidature` dans la messagerie ; compte en attente admis pour cet objet ; notifications ; file `a_envoyer` | `18`, `16` | `Q06`, `Q07`, `Q10` | à écrire | L1 ; contrat de la file remis à la session du site public |
| **L6** référentiel de paiement | lignes, droits, état initial du 21/10, déclencheur de restriction, alerte, part de `CPT-BR-10` | `13` | `Q05` | à écrire ; lignes d'Afrique `en_verification` tant que `Q05` est ouvert | L1 |
| Transverse | conservation et anonymisation | `14` | `Q21` | en attente du juriste | - |
| Transverse | scénarios du module | `15` | - | un fichier par lot | ordre du directeur pour la CI |

**Ordre et parallèle.** Avant L6, `paiement_compatible` est faux pour tous : aucune
candidature n'entre en salle 2. L6 est court ; il peut avancer en parallèle de L2
et doit être livré avant la première admission en salle 2.

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
| L2-1 | validation de pièce, un des sept contrôles faux | 7 refus, chacun nommé ; après chacun : pièce en attente, compte `pending_kyc`, étape inchangée |
| L2-2 | validation, les sept vrais | pièce `approved`, compte `active`, étape `confirmee`, en 1 transaction |
| L2-3 | activation par une autre voie (mise à jour de `account_status`), sans contrôles ; puis sans contrat | 2 refus de la garde |
| L2-4 | entrée en salle 2 sans `paiement_compatible`, puis sans cadre religieux | 2 refus nommés |
| L2-5 | pièce « à corriger » ; refus définitif | étape inchangée ; issue `refusee`, 0 motif interne dans `etat_dossier()` |
| L2-6 | nouvelle pièce refusée d'une enseignante active, sans autre pièce approuvée | `disabled` (inchangé) et 1 restriction `piece` |
| L2-7 | lot de 10 pauses dont 3 sur des candidatures `refusee` | 7 réussies, 3 exclues avec raison, 3 inchangées |
| L2-8 | même clé d'idempotence rejouée ; version périmée | 1 effet ; 0 écriture |
| L2-9 | geste en pause autre que lever, refuser, retirer | refus |
| L2-10 | chaque geste marqué « oui » en 4.2, sans motif | refus, 0 écriture |
| L2-11 | chaque transition | 1 ligne `audit_logs` ; chaîne vérifiable |
| L3-1 | inscription sans courriel confirmé | 0 candidature |
| L3-2 | inscription au-delà du plafond horaire de `app_config` | refus |
| L3-3 | inscription par le lien | 1 compte `pending_kyc` ; 0 capacité enseignant ; jeton de cours refusé ; 0 apparition dans une liste d'enseignants |
| L3-4 | essai à blanc sur A | 0 écriture ; compteurs rendus ; écart avec 440 lignes et 409 personnes lu avant de confirmer |
| L3-5 | confirmation de l'import, puis second import identique | 0 ligne dans `profiles`, `invitations_enseignant`, `kyc_documents`, `contract_acceptances` ; 0 candidature hors `recue` ; puis 0 ajout |
| L3-6 | B | 11 lignes `dejaConnue`, 0 écriture |
| L3-7 | rattachement par courriel confirmé, par téléphone seul, par nom | pré-remplissage ; 0 donnée montrée et 1 proposition à la direction ; 0 |
| L3-8 | lot de 10 invitations dont 3 sans courriel valide | 7 codes émis, 3 exclues, 3 inchangées |
| L3-9 | invitation expirée | retour en `recue`, trace gardée |
| L3-10 | créneaux importés | fuseau `Asia/Riyadh` ; 0 ligne `weekly_availability` |
| L3-11 | groupe de doublons sans choix | reste « à corriger » ; 0 fusion |
| L4-1 | jeton d'entretien : candidat convoqué à l'ouverture, avant l'ouverture, autre candidat | accepté, refusé, refusé |
| L4-2 | séance d'entretien close | 0 ligne `tresorerie_mouvements` ; 0 clôture automatique ; 0 ligne `mes_seances_v` |
| L4-3 | intervieweur de l'autre côté ; super-admin | refus ; accepté avec 1 ligne de journal |
| L4-4 | fuseau du candidat inconnu | planification refusée |
| L4-5 | `tenu` sans compte rendu ; `annule` sans motif ; retour à `entretien_a_planifier` | refus ; refus ; issue gardée |
| L5-1 | candidat `pending_kyc` et son fil `candidature` ; autres objets | lecture et écriture ; 0 accès |
| L5-2 | une directrice et le fil d'un candidat homme | 0 accès |
| L5-3 | planification d'un entretien | 1 notification et 1 courriel `a_envoyer` |
| L5-4 | paramètres des courriels de refus et de pause | 0 motif interne |
| L5-5 | un candidat lit la file des courriels | 0 ligne |
| L6-1 | Arabie saoudite, compte bancaire oui, moyen confirmé | `compatible` ; admission en salle 2 acceptée |
| L6-2 | hors d'Afrique, compte bancaire non | `incompatible`, `paiement_non_disponible`, issue `en_cours` |
| L6-3 | Afrique, compte bancaire oui, `Q05` ouvert | `incompatible` |
| L6-4 | ligne `en_verification` | 0 cas `compatible` |
| L6-5 | `confirme` sans date ni responsable | refus |
| L6-6 | ligne passée `indisponible` | K restrictions pour les K personnes en salle 3 qui n'avaient qu'elle ; 0 changement pour les autres ; `impact` = K |
| L6-7 | un candidat lit le référentiel | 0 ligne non confirmée, 0 note interne |

### 12.2 Flutter

- Chaque écran neuf ou étendu : cinq états et états propres ; clair et sombre ;
  360, 768, 1440 ; `fr` et `ar` (droite à gauche) ; texte à 200 % ; clavier, focus.
- `verifierUnSeulBoutonPlein` dans chaque état ; la ligne d'`ADM-20` a 2 cibles.
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
- Restent verts : invitations, inscription sur invitation, accords, ADM-02, import
  du 12/10, Comptable (CPT-02), affectation par `tc_verifier`.
- **Garde étendue** : 28 fichiers de scénarios signent puis activent un enseignant
  (`CORR §7`, recette), dont `scenarios_etape3.sql`, premier de la CI. Chacun
  reçoit les fixtures des nouveaux contrôles dans le même lot ; le nombre de
  fichiers touchés s'écrit.

### 12.4 Critères de la spec

| `SPEC §13` | Preuve |
| :--- | :--- |
| Autre type sans copier le pipeline ; critères étanches | L1-7 |
| Champs au bon moment ; rien de postérieur exigé (coordonnées, photo, `weekly_availability`) | L2-4, L3-10, widget `CAND-01` |
| Salle 3 impossible sans pièce, contrôles, paiement | L2-1, L2-3 |
| Sans compte bancaire mais moyen compatible : admis ; préférence bancaire à égalité seulement | L6-1 (en Afrique, après `Q05`) ; tri 5.2 au widget |
| Confirmé indisponible distinct de prêt à être affecté | transition 22 ; widget `ADM-20` |
| Nom et entretien : deux cibles ; état réel ; lien absent sans bouton | 12.2, L4-1 |
| Un candidat ne lit pas les autres ; pièces hors des listes | L1-1, L1-5 |
| Lots : portée et erreurs partielles | L2-7, L3-8 |
| Import sans compte ni contrôle validé | L3-5 |
| Clair et sombre, largeurs, clavier | 12.2 |

---

## 13. Hors module (`CAND-Q15`)

Les cinq défauts trouvés hors du module sont confiés à des agents (`DEC:38`).
**Recherche du 21/10** sur 584 branches distantes et 34 PR ouvertes : **aucun des
cinq n'est corrigé, sur aucune branche** (`CORR §0 bis`). Les correctifs
s'écrivent d'après `CORR`, chacun sur sa branche, jamais par `main`, avec son
scénario et un horodatage de migration propre.

| Lot | Défaut | Lien avec ce module |
| :--- | :--- | :--- |
| `langue` | la langue de l'enseignant est enregistrée par son nom et comparée à un code (`CORR §3`) | sans lui, une personne en salle 3 n'est affectable à aucune classe dont la langue est renseignée |
| `c11bis` | `affecter_enseignant_classe_c11bis` lève toujours : aucune classe en attente ne reçoit d'enseignant (`CORR §4`) | sans lui, « affectable » n'a pas de chemin serveur |
| `creer_groupe` | pose un enseignant sans vérifier pièce, genre, langue, plafond ni collisions (`CORR §5`) | une personne hors salle 3 pourrait recevoir une classe |
| `conduite` | le code de conduite n'est exigé par aucune garde (`CORR §7`) | entre dans `accords_signes` ; `CAND-BR-11` s'écrit après, sur la garde redéfinie |
| `gnf` | 0 décimale côté client, 2 côté serveur (`CORR §6`) | aucun direct ; paie et versements en GNF |

**Ordre** (`CORR §2`) : `langue`, puis `c11bis`, puis `creer_groupe`. `conduite`
passe à part, après les migrations `20261018160000` et `20261019100000` ; `gnf` est
indépendant. Ajustements relevés par la recherche : le seed de staging de la PR
#40 écrit `array['fr','ar']`, à corriger avant sa fusion ; `creer_groupe` retient
la variante `app_private.verifier_affectation_enseignant(uuid, uuid, boolean)`
(`CORR §0 bis`).
