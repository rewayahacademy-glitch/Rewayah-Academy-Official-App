# C09 - Règles métier canoniques pour le rôle Tuteur

Agent C09, 24/09/2026. Phase **lecture seule** : aucun fichier du dépôt modifié, aucune branche changée
(checkout `c0/configuration-baseline-2026-09-23`). Les autres branches sont lues par `git show` / `git grep`.
Convention : `fichier:ligne` ; `@branche` quand le fichier n'existe que sur une branche non fusionnée.
« main » vaut HEAD pour `lib/` et `supabase/` : le diff `main..HEAD` sur ces dossiers ne réécrit que des liens
de commentaires (constat `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md:88`).

Abréviations : **M** = mandat `D:\RA _APP\docs de lancement\REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md`
(partie principale L1-321, partie « observation » L325-501) ; **DC** = `docs/current/` ;
**ADR** = `docs/archive/2026-09-pre-remise-a-plat/architecture/decisions.md` ;
**ARB** = `docs/architecture/CORE24_CLASSES_ARBITRATION_FINAL.md@docs/core24-classes-arbitration` (commit `196eb06`) ;
**CXC** = `D:\RA _APP\Maestro Vague\codex cohorting.txt` (prompt directeur Classes V2, 23/09 00:42) ;
**S24** = `D:\RA _APP\Maestro Vague\REWAYAH_SPRINT24H_CORE_CONTRACT_V2.md` (21/09) ;
**OQE** = `docs/archive/2026-09-pre-remise-a-plat/produit/onboarding-questions-expliquees.md`.

Aucun statut « PASS » n'est affirmé ici : ce rapport établit ce que disent les textes et ce que le code fait,
rien n'a été exécuté.

---

## 1. Ordre d'autorité applicable à ce lot

| Rang (M §2, L19-26) | Source | Date | Remarque |
|---|---|---|---|
| 1 | Mandat directeur M (deux parties) | fichier du 24/09 02:35 | La partie « observation » remplace M L150 (« 1 visite, 120 s ») par M L372-379 |
| 2 | Sécurité et contrats existants (RLS, RPC, migrations appliquées) | code | Ne peut être affaibli pour une image |
| 3 | Maquettes high-fi | 24/09 | Hors domaine C09 |
| 4 | Décisions métier canoniques les plus récentes | DC `08` (23/09, §5 bis jusqu'au 24/09) > DC `00` (23/09) > DC `01`-`07` (22/09) ; décisions directeur Classes V2 (ARB 22/09, CXC 23/09) **non intégrées à DC** | DC `00:12` : « demande explicite la plus récente du directeur, puis `08`, puis `00`... puis archive » |
| 5 | Bible V2, tokens, composants | archive | Référence d'exécution |
| 6 | Archive, anciennes captures | archive | `CLAUDE.md:23-25` : une règle archivée qui contredit DC est caduque |

Point de méthode : les décisions Classes V2 (ARB, CXC) sont des consignes **du directeur**, postérieures ou
contemporaines de DC `01`-`07` (22/09), mais elles vivent sur des branches CORE24 **gelées**
(`08:5-7`, `08:90` : « V0, V1 et CORE24 restent suspendus ») et ne figurent pas dans DC. Le mandat les invoque
nommément (M L192 « vérifier notamment les décisions Classes V2 plus récentes » ; M L140, L193 « si confirmées »).
Je les classe donc **« décision directeur récente, non intégrée à DC, non implémentée sur main »** : elles
gouvernent le comportement attendu par le mandat, mais leur support serveur n'existe pas sur `main`.

---

## 2. Docs de lancement contre `docs/current` (empreintes SHA-256)

| Fichier | `docs de lancement` | `docs/current` | Verdict |
|---|---|---|---|
| `00_LIRE_D_ABORD.md` | version **22/09** (`lancement/00:2`) | version **23/09** (`00:2`) | **Différents, DC plus récent.** 5 lignes changent : lecture (`00:5` ajoute `08`/`09`), autorité (`00:12` insère `08`), capacités (`lancement/00:27` « par défaut 4 élèves enfants et 5 adultes » remplacé par `00:27` « ne pas présumer d'une valeur par défaut avant arbitrage ; 5/60 et 6/90 contre 4/45 et 5/90 »). La copie du directeur est **périmée** sur ce point. |
| `01_PRODUIT_ET_PARCOURS.md` | `DB5BB76E` | `DB5BB76E` | Identiques |
| `02_ARCHITECTURE_ET_SECURITE.md` | `7CC27FD4` | `7CC27FD4` | Identiques |
| `03_DESIGN_SYSTEM_ET_UX.md` | `FCC2FBCC` | `FCC2FBCC` | Identiques |
| `04_EXECUTION_GIT_CI_ET_MIGRATION.md` | `61066F31` | `61066F31` | Identiques |
| `05_PROMPT_AGENT_INTEGRATEUR.md` | présent | **absent de DC** ; archivé sous `docs/archive/2026-09-pre-remise-a-plat/racine/` | Contenu identique hors fins de ligne (`git diff --ignore-cr-at-eol` vide). Archivé le 23/09 (`08:77`, commit `2a8b847`). Ne plus l'appliquer. |
| `06_SPEC_FONCTIONNELLE_MVP.md` | `A508910C` | `A508910C` | Identiques |
| `07_MEMOIRE_PEDAGOGIE_FINANCE.md` | `87C1C811` | `87C1C811` | Identiques |
| `08_...`, `09_...`, `CONFIGURATION_BASELINE_...` | absents | présents (23-24/09) | Seulement dans le dépôt, plus récents |

Conclusion : pour ce lot, lire **DC** (00 du 23/09) et non la copie `docs de lancement/00`.

---

## 3. Décisions récentes retrouvées hors DC

| Document | Date | Où | Statut |
|---|---|---|---|
| ARB « Arbitrage canonique Core24 Classes » | 22/09 17:35 (`196eb06`) | branches `docs/core24-classes-arbitration`, `integration/core24-classes-v2*` ; absent de `main` et de DC | Normatif selon son en-tête (ARB:3-5), directeur ; chantier gelé |
| CXC « codex cohorting » (prompt de remédiation Classes V2) | 23/09 00:42 | hors dépôt | Consigne directeur, « Politique définitive » (CXC:357) ; antérieure au gel du 23/09 |
| `CORE24_CLASSES_IMPLEMENTATION_REPORT.md@integration/core24-classes-v2` | 22/09 21:05 (`e8beeb7`) | branche | Code **NON CONFORME** (DC `00:34`, `04:5`) ; remédiation `3c0cb1c` gate A BLOCKED_INFRA (`CORE24_CLASSES_REMEDIATION_REPORT.md@...-remediation:207-214`) |
| FABLE onboarding + contrat 0043 (`FABLE_ONBOARDING_CLASSES_REPORT.md`, `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md`, OQE, ADR-029/030/031) | 22/09 | **fusionné dans `main`** (`4a7aa2b`) | Code présent ; **migration `0043` non appliquée en production** (`CONFIGURATION_BASELINE_2026-09-23.md:17`, `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md:8-10`) |
| Règle observation « 2 visites de 2 min » | 21/09 | `supabase/migrations/0036_...:2-10` (main, appliquée) | Code aligné sur M |
| Règle visibilité du tuteur (enseignant + son enfant seulement) | 21/09 | `0040_...@observation/lot-2026-09-21:1-16` | Appliquée en production, **absente de `main`** (`08:79`, `08:83`) |
| S24 « photo mineur avant Salle » | 21/09 | hors dépôt ; code `@astra/core24-v2` | Consigne sprint gelée, non intégrée |

---

## 4. Règles extraites

Colonnes demandées : règle | source `fichier:ligne` | date | statut. Sous chaque thème, ce que le **code fait**
(main sauf mention) et ce que les commentaires ou docs **prétendent**.

### 4.1 Cohortes d'âge

| Règle | Source | Date | Statut |
|---|---|---|---|
| Cohortes 6-9, 10-13, 14-17, 18+ « si confirmée par les décisions en vigueur » ; prévoir anniversaire en cours de flux, âge manquant, borne, politique indisponible ; ne pas deviner un âge | M L193 | 24/09 | Mandat (conditionnel) |
| Cohortes actives 6-9, 10-13, 14-17, 18+ ; adultes = population unique en V1 ; anciennes 5-7/8-10/11-14/15-17 obsolètes, à désactiver sans remap destructif | ARB:45, ARB:110-117, ARB:259 ; CXC:357-377 | 22-23/09 | Décision directeur non intégrée à DC |
| Moins de 6 ans : hors dispatch standard, jamais forcé en 6-9 | ARB:130-131 ; CXC:412-416 | 22-23/09 | Idem |
| Cohorte indépendante de l'Interface guidée ; `child_ui_mode_max_age` ne décide ni cohorte ni dispatch | ARB:134-136 | 22/09 | Idem |
| Anniversaire 9 à 10 ans : aucun transfert automatique de groupe | ARB:132 | 22/09 | Idem |
| Cohortes 5-7, 8-10, 11-14, 15-17, 18+ (`enfant_5_7`...`adulte_18_plus`) | `supabase/migrations/0043_offres_horaires_et_intentions.sql:112-118` ; `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md:86` | 22/09 | **Code main**, migration non appliquée en prod |
| DC : aucune cohorte définie | DC `00`-`07` (recherche négative) | - | Silence de DC |

Code : la question d'âge du parcours propose une **tranche** fermée servie par `cohortes_age`
(`assets/i18n` `parcours.ageQuestion`, `lib/core/i18n/strings_fr.g.dart:8169-8170` : « Nous ne demandons pas de date
de naissance : une tranche suffit »). Rien n'est câblé en production tant que `0043` n'est pas appliquée.

### 4.2 Date de naissance

| Règle | Source | Date | Statut |
|---|---|---|---|
| Fiche élève : « Identité, date de naissance, photo » | M L74 | 24/09 | Mandat |
| Pour un mineur, `date_naissance` = source canonique ; âge et cohorte dérivés ; pas trois vérités ; legacy sans date : ne rien inventer, solliciter le tuteur une fois ; date protégée par RLS | ARB:46, ARB:119-139 ; CXC:381-409 | 22-23/09 | Décision directeur non intégrée |
| « Le produit ne stocke de date de naissance nulle part » ; l'âge se demande en tranche | OQE:52-62 ; `FABLE_ONBOARDING_CLASSES_REPORT.md:128-137` | 22/09 | Historique (archive) / rapport à la racine ; **caduc face à ARB** (ARB:252 « Le présent prompt gagne ») |
| Création d'un profil élève par **âge entier** (3 à 99 côté serveur) | `supabase/migrations/0004_inscription_kyc_appairage.sql:862-864` ; `supabase/functions/creer-profil-enfant/index.ts:33-37` | 06/09 | Code main |
| Borne client 3 à 18 ans | `lib/features/appareils/ajouter_enfant_page.dart:44` | - | Code main |

Code : aucune colonne `date_naissance`/`birth_date` sur main (`git grep` négatif sur `lib/` et `supabase/migrations/`).
La colonne n'existe que sur les branches CORE24 (`CORE24_CLASSES_REMEDIATION_REPORT.md@...:34-37`, non rejouée).

### 4.3 Parcours débutant et diagnostic

| Règle | Source | Date | Statut |
|---|---|---|---|
| Débutant déclaré : dernière décision canonique de parcours débutant direct, suppression du diagnostic inutile ; aucune autodéclaration ne devient certification | M L192 | 24/09 | Mandat |
| Carte « Je débute » (« Je ne peux pas encore lire seul des mots ou des versets en arabe, même si je connais déjà quelques lettres. ») ; aucun D0 imposé ; `diagnostic_status` jamais falsifié en `completed` ; `placement_basis` traçable (`self_declared_beginner`) | ARB:82-83, ARB:146-157 ; CXC:451-472 | 22-23/09 | Décision directeur non intégrée |
| Diagnostic à l'entrée ; débutant : parcours de base | DC `01:19` | 22/09 | Canonique DC (ambigu : ne dit pas si le débutant passe un diagnostic) |
| Pré-diagnostic déclaratif puis diagnostic humain ; débutant en F1 | DC `06:13` | 22/09 | Canonique DC |
| « Diagnostic D0 en deux temps : déclaratif, puis lecture/récitation réelle » | DC `07:8` | 22/09 | Mémoire DC (après MVP) ; contredit ARB pour le débutant |

Code (main) : `diagnostic_statut` vaut `'a_planifier'` **par défaut pour tout le monde**
(`0043_offres_horaires_et_intentions.sql:242`) et `choisir_offre_horaire` repasse `non_requis` en `a_planifier`
(`0043:810-811`). L'accueil affiche alors « Préférence enregistrée... Il reste un échange avec un enseignant pour
situer le niveau » (`lib/core/i18n/strings_fr.g.dart:8218-8221`) même pour un débutant. Ce que prétend OQE:175
(« Le diagnostic qui suit corrige ») est cohérent avec le code, pas avec ARB.

### 4.4 Pré-diagnostic non-débutant

| Règle | Source | Date | Statut |
|---|---|---|---|
| Non-débutant : pré-diagnostic court et décision pédagogique selon le processus existant | M L192 | 24/09 | Mandat |
| 2 à 4 questions adaptatives maximum ; aucun niveau officiel écrit ; `diagnostic_required` puis tâche « Finaliser mon niveau », diagnosticien qualifié, résultat structuré, validation serveur ; le diagnostic ne bloque pas l'accès général à l'app, seulement l'affectation définitive | ARB:159-178 ; CXC:475-497 | 22-23/09 | Décision directeur non intégrée |
| Niveau déclaré ≠ niveau officiel ; le client n'écrit que 5 colonnes (`langue_cours`, `cohorte`, `niveau_declare`, `objectif`, `onboarding_fait_le`), jamais `level` | `0043` (GRANT colonne) cité par `FABLE_ONBOARDING_CLASSES_REPORT.md:67-74` ; OQE:144-176, OQE:333-336 | 22/09 | Code main (non appliqué) ; conforme à ARB:78-79 |
| Aucun code académique interne à l'écran (F1, F2...) | M L191 ; DC `03:12` ; DC `01:35` ; OQE:165-167 | 22-24/09 | Canonique |

Code : le parcours actuel pose **5 niveaux déclarés** identiques pour tous (`strings_fr.g.dart:8176-8182`) et une
question « objectif » (`8183-8188`) ; il n'existe pas de branche « non-débutant » à 2-4 questions sur main.

### 4.5 Interface guidée

| Règle | Source | Date | Statut |
|---|---|---|---|
| « Mode enfant » devient `Interface guidée`, activable selon les besoins, y compris par un adulte | DC `00:28` ; DC `03:12` ; DC `06:30` ; `CLAUDE.md:78-79` | 22-23/09 | Canonique DC |
| Conserver la valeur stockée `child`, afficher `Interface guidée`, option accessible aux adultes par capacité ou préférence | DC `08:39` | 23/09 | Canonique DC |
| Libellé neutre ; politique actuelle « demande de standard à partir de 10 ans et activation par le tuteur si confirmées dans le dépôt » ; aucune bascule locale qui élève les droits | M L140 | 24/09 | Mandat (conditionnel) |
| Tuteur voit toujours l'option et peut activer/revenir ; enfant < 10 ans : pas de bouton de demande ; ≥ 10 ans révolus : peut demander ; la demande n'active rien ; le tuteur accepte ou décline ; l'enfant n'approuve jamais lui-même ; écriture client directe de `interface_mode` interdite ; date inconnue : aucune supposition ; notice tuteur visible même sans demande | CXC:751-791 ; ARB:119-128, ARB:337-346 | 22-23/09 | Décision directeur non intégrée |
| Modes `enfant` (≈ 6-8 ans) / `standard` (≈ 9+), seuil configurable | ADR `decisions.md:277-286` | 06/09 | Historique |
| « Le seuil du mode enfant est employé à 8 », à confirmer par l'opérateur | ADR `decisions.md:592-599`, `decisions.md:1812` | 06/09 | Historique, « résolu par défaut, pas par décision » |

Code (main) :
- Création d'un profil : `interface_mode = child` si âge ≤ `child_ui_mode_max_age` (8)
  (`0001_fondations.sql:959`, `0004_inscription_kyc_appairage.sql:869-874`).
- `0043` (non appliquée) **réécrit `interface_mode` depuis la cohorte à chaque enregistrement du parcours**
  (`0043:628-636`, cohortes `child` jusqu'à 10 ans inclus `0043:114-115`) : un réglage posé par le tuteur serait
  écrasé en silence dès qu'il « modifie ses réponses ».
- Le tuteur écrit directement `interface_mode` par `GRANT UPDATE (interface_mode, camera_policy, avatar_storage_key)`
  (`0005_dashboards_affectation_regles.sql:562-564`) sous la policy `student_profiles_family_update`
  (`0005:535-556`). **Cette policy filtre le foyer, pas le rôle** : un compte élève du même foyer disposant d'un
  JWT `authenticated` pourrait écrire son propre `interface_mode`/`camera_policy`. **PLAUSIBLE, non vérifié** (dépend
  de la forme du jeton émis à l'appareil élève) : à confier à la revue sécurité, hors lot frontend.
- Aucun mécanisme « demande de l'enfant » sur main ; il n'existe que sur
  `integration/core24-classes-v2` (`supabase/migrations/20260923000400_core24_interface_guidee.sql`, non rejouée).
- Libellé visible encore « Mode enfant » : `lib/features/compte/compte_page.dart:547`, `:590-592`
  (clé `compte.modeEnfant`, `strings_fr.g.dart:8333`).

### 4.6 Photo

| Règle | Source | Date | Statut |
|---|---|---|---|
| Blocage « photo requise » seulement si confirmé par les données ; respecter les règles réelles de photo avant première visio sans inventer une obligation KYC ; ne pas mélanger portrait et pièce d'identité | M L119, M L138 | 24/09 | Mandat |
| Photo enfant réelle, gérée par le tuteur, visible du seul foyer et de l'appareil de l'enfant, jamais du roster enseignant ; URL signée courte | ADR `decisions.md:379-409` | 06/09 | Historique, repris par l'UI (`strings_fr.g.dart:8453-8454`) |
| Mineur : l'entrée en Salle Live exige une photo d'identification téléversée ; consultation, choix de classe, inscription possibles avant ; adulte jamais bloqué par la photo si aucune règle ne l'impose | S24:57-63 | 21/09 | Consigne sprint gelée |
| Photo enseignant **obligatoire** et publique, distincte du KYC (D-01) | `0030_tc_socle.sql:178-189` ; DC `01:25` ; DC `03:12` | 20-22/09 | Canonique DC + code main |

Code : aucune vérification de photo dans `supabase/functions/` sur main (`git grep photo` négatif). La précondition
« photo mineur » n'existe que sur `astra/core24-v2`
(`supabase/migrations/20260921000200_core24_conformite.sql:93-161`,
`supabase/functions/create-room-token/index.ts:73-76` sur cette branche). **Sur main, aucune donnée ne confirme une
« photo requise » : le blocage ne doit pas être affiché.**
Commentaire trompeur : `lib/core/tc_groupe/group_summary_vm.dart:105` affirme que `teacher_profiles` n'a « aucune
colonne de photo », alors que `0030_tc_socle.sql:180-181` l'ajoute (`photo_storage_key`) et que
`mes_groupes_famille_v` la sert (`0033_tc_vues_rpc.sql:157`).

### 4.7 Consentements requis (liste)

| # | Consentement / pièce | Source | Date | Statut | Code (main) |
|---|---|---|---|---|---|
| 1 | Conditions d'utilisation du tuteur (`guardian_terms`) | ADR `decisions.md:413-429`, `:585-590` | 06/09 | Historique repris par le code | `0004:224-228` ; signé par `lib/features/dossier/signature_page.dart:46-69` ; version `2026-09` (`lib/core/dossier/versions_contrat.dart:13`) |
| 2 | Carte « enregistrement et visite de contrôle » (`recording_and_control_notice`), accusée avant le contrat | ADR `decisions.md:334-352`, `:585-590` | 06/09 | Historique | `0004:227` ; `signature_page.dart:29-41`. **Son texte affirme un enregistrement audio de 30 jours** (`strings_fr.g.dart:7440`) qui n'existe pas (`CONFIGURATION_BASELINE_2026-09-23.md:139` ; DC `08:37`) |
| 3 | Pièce d'identité du tuteur (KYC), coffre privé, rétention 90 j ; l'enfant n'en dépose aucune | DC `06:12` ; DC `02:21-22` | 22/09 | Canonique DC | `0004:114-156`, `0004:886-888` |
| 4 | Consentement photo de l'enfant « ajouté au même consentement que la pièce d'identité et l'enregistrement » | ADR `decisions.md:405` | 06/09 | Historique | **Aucune sorte dédiée** : `contract_kind` n'accepte que 3 valeurs (`0004:224-228`) |
| 5 | Consentement d'observation parentale (formulations responsable légal / élève adulte ; accord explicite non précoché ; comptes existants non réputés d'accord) | M L423-429 | 24/09 | **Mandat (nouveau)** | **Absent.** Nouvelle sorte = migration du `CHECK` (`0004:224`) ; nouvelle version = re-signature de tout le monde (`versions_contrat.dart:1-9`) |
| 6 | Enregistrement audio : jamais activé sans décision écrite sur finalité, consentement, rétention | DC `06:33` ; DC `01:32` | 22/09 | Canonique DC (arbitrage ouvert DC `07:35`) | Aucun Egress démarré (`CONFIGURATION_BASELINE_2026-09-23.md:139`) |
| 7 | Mineurs : consentements et retenues configurables, validation légale avant ouverture réelle ; compatibilité de l'observation tuteur avec la protection des mineurs à vérifier avant ouverture | DC `02:22` ; DC `01:30` | 22/09 | Canonique DC | Non outillé |
| 8 | Contrat enseignant (`teacher_nda`) | `0004:226` | 06/09 | Hors rôle tuteur | - |

### 4.8 Capacités et durées de classe

| Règle | Source | Date | Statut |
|---|---|---|---|
| Ne pas présumer de valeur par défaut avant arbitrage : référentiel 5 enfants/60 min et 6 adultes/90 min contre Control System 4/45 et 5/90 ; afficher la capacité réelle | DC `00:27` ; DC `07:10`, `07:34` | 22-23/09 | Canonique DC (arbitrage **déclaré ouvert**) |
| « par défaut 4 élèves enfants et 5 élèves adultes » | `docs de lancement/00:27` | 22/09 | **Périmé** (remplacé par DC `00:27`) |
| Au plus 5 enfants ou 6 adultes, enseignant en sus (`max_participants_per_session = 7`) | ADR-028 `decisions.md:1534-1561` | 19-20/09 | Historique, mesuré en base |
| Enfants 5 max, 3 séances/sem, 60 min, pause 5-7 min configurable ; adultes 6, 3/sem, 90 min ; minimum de lancement 3 ; 4/45 et 5/90 obsolètes | ARB:98-108 ; CXC:541-560 | 22-23/09 | Décision directeur non intégrée |
| `groupe.capacite_enfant` 5, `_adulte` 6, `minimum_lancement` 3, `seances_par_semaine` 3, durées 60/90, pause 6/0 | `0043:532-539` | 22/09 | Code main non appliqué |
| Noms, capacités, métriques des maquettes jamais constantes métier | M L264 ; M L130 | 24/09 | Mandat |

Code : places réelles X/Y d'un groupe rejoint = `seuil_max` et `nb_membres` de `mes_groupes_famille_v`
(`0033_tc_vues_rpc.sql:147`, `:158`). `app_config` n'est lisible que par l'admin (`0001_fondations.sql:969-970`) ;
`regles_academie()` (0043) l'expose aux familles, mais n'existe pas en production.

### 4.9 Fenêtre d'ouverture T-20

| Règle | Source | Date | Statut |
|---|---|---|---|
| « À environ T-20 configurable, `Rejoindre` devient disponible » ; séance prolongée : « Cours toujours en cours », jamais un temps négatif | DC `01:25` ; DC `06:18` | 22/09 | Canonique DC |
| Ouverture selon fenêtre existante/configurable, généralement T-20 ; « Cours dans 3 h 28 » ; prolongée « Cours toujours en cours » | M L117 | 24/09 | Mandat |
| Serveur : `join_window_minutes = 20`, `grace_after_end_minutes = 15`, lus par `autoriser_jeton_video`, `etat_presence`, `entrer_observation` | `0030_tc_socle.sql:34-35` ; `0033_tc_vues_rpc.sql:290`, `:1553`, `:1643` ; `0037:66-67` | 20-21/09 | Code main |
| Ancienne fenêtre T-10 en dur | `0010_video_jeton_presence.sql:304-307` | - | Remplacée par `0033:1643` |

Code client : `seuilOuvertureSalle = Duration(minutes: 10)` en dur (`lib/core/video/pre_vol.dart:22`), employé par
la journée enseignant (`lib/features/journee/journee_page.dart:403`) ; le commentaire (`pre_vol.dart:9-10`) le
reconnaît comme « commodité » non autoritative. Divergence client 10 min / serveur 20 min.

### 4.10 Politique d'observation

| Règle | Source | Date | Statut |
|---|---|---|---|
| Défaut « activé, une visite, 120 secondes cumulées par séance », configurable et audité | DC `01:30` | 22/09 | **Canonique DC mais obsolète** (M L372 le déclare obsolète) |
| « Référence historique 1 visite et 120 secondes cumulées » | M L150 | 24/09 | Remplacé par M L372-379 |
| 2 visites max ; 120 s max par visite ; 240 s au total, jamais une visite de 4 min ; configurable par l'administration ; l'UI consomme la politique effective | M L357, M L374-379 | 24/09 | Mandat (prévaut) |
| Observer seulement si l'enfant est présent ; présence incertaine = vérification, jamais absence inventée | M L381 | 24/09 | Mandat |
| Le tuteur entend l'enseignant et les micros actifs, voit support, enseignant et son enfant ; ni micro, caméra, chat, réactions, annotations, commandes ; pas de roster | M L383-388 ; DC `01:30` ; DC `06:20` | 22-24/09 | Mandat + DC |
| Notice discrète pour l'enseignant et l'enfant concerné seulement ; « Votre maman... » seulement si lien connu, sinon « Votre parent... » | M L390 | 24/09 | Mandat |
| Quotas et fins de visite garantis par le serveur ; le timer n'est pas une garantie | M L392 ; DC `06:20` | 22-24/09 | Mandat + DC |
| Historique des observations conservé, consultable tuteur + admin ; ni édition ni suppression ; pas de durée de conservation décidée | M L447-470 | 24/09 | Mandat |
| Points ouverts : quota partagé/individuel entre responsables, plusieurs enfants dans une séance, visite écourtée, déconnexion de l'enfant | M L482 | 24/09 | Mandat (ne pas trancher) |
| « Assister : l'enseignant le voit arriver » | archive `design/08-catalogue-ecrans.md:413-414`, `:476-477` | 08/09 | Historique, caduc |

Code (main + production) :
- Défauts `2 / 120 / 240`, `policy_version "a2"`, plafond par visite tenu par le serveur (`0036:16-45`, `:191-194`) :
  **le code est déjà conforme à M**, DC `01:30` est en retard.
- `entrer_observation` vérifie fenêtre, rôle, **appartenance** d'un enfant du foyer au groupe
  (`motif_refus 'lien_tuteur_absent'`), politique et budget (`0037:83-131`) ; **aucune vérification de présence de
  l'enfant** : la règle M L381 n'est pas garantie par le serveur.
- Quota compté **par observateur** (`observateur_profile_id = auth.uid()`, `0033_tc_vues_rpc.sql:1035`, `:1049`,
  `:1170`) : deux tuteurs d'un même foyer auraient chacun 2 visites (point ouvert M L482, tranché de fait par le code).
- Un seul enfant retenu par visite (`limit 1`, `0037:104-109`) : cas « plusieurs enfants » non traité.
- Visibilité réservée à l'enseignant et à l'enfant : `0040@observation/lot-2026-09-21:1-16`, appliquée en production,
  **absente de main**.
- Journal persistant : table `guardian_session_visit` et RPC `visites_observation(p_session_id)` (observateur ou
  admin), **par séance** uniquement (`0033_tc_vues_rpc.sql:1235-1257`) ; aucune liste inter-séances ni filtre admin
  par tuteur/élève/période sur main.

### 4.11 Présence et retard

| Règle | Source | Date | Statut |
|---|---|---|---|
| Présence : événements LiveKit validés + DB ; distinguer connexion, présence académique, incident réseau ; webhooks idempotents ; retard ; temps connecté distinct du temps de cours ; correction admin auditée | DC `02:11` ; DC `06:21` ; DC `01:25`, `01:32` | 22/09 | Canonique DC |
| Aucune absence déduite d'une simple déconnexion ; « réseau bon » seulement si mesuré ; historique : présence/retard **validé** ; « En cours de vérification » si preuve ambiguë | M L121, M L156-158 | 24/09 | Mandat |
| Ne pas confondre caméra coupée, coupure temporaire et absence | M L381 | 24/09 | Mandat |

Code : `presence.seuil_retard_secondes = 300`, `presence.fenetre_reconnexion_secondes = 120`,
`presence.fenetre_connexion_secondes = 90` (`0007:146-147`, `0010:166`, `0033:1550-1552`) ;
`absence_threshold_minutes = 5` (`0001:960`). La présence Core24 signée (`730b7b7`, `astra/core24-presence-safeguard`)
n'est pas intégrée (ARB:55, ARB:261).

### 4.12 Appareils (limites)

| Règle | Source | Date | Statut |
|---|---|---|---|
| Deux appareils appairés par élève, **un seul en séance** | ADR-010 `decisions.md:318-330` | 06/09 | Historique repris par le code |
| Limites d'appareils viennent du contrat, pas du « 1/2 » d'une capture ; restriction de retrait en séance seulement si la politique existe | M L130 | 24/09 | Mandat |
| Gestion des appareils dans Foyer ; aucun accès à une autre famille via cache | DC `06:11`, `06:29` ; DC `02:23` | 22/09 | Canonique DC |
| QR par caméra reporté ; seul le code à 6 caractères fonctionne partout | ADR `decisions.md:601-608`, `:1820` | 06/09 | Historique, **remplacé** par M §7 (scanner réel exigé, M L216-226) |

Code : `max_devices_per_student = 2`, `max_concurrent_sessions_per_profile = 1` (`0001:965-966`), contrôlés par
`creer_code_appairage` (`0004:608-615`) ; code 6 caractères, TTL `pairing_code_ttl_minutes` = 10
(`0004:623-629`), un seul code vivant par élève (`0004:617-621`), usage unique (`consumed_at`, `0004:674-677`,
`:710`). Côté client, `appareilsParEleve = 2` en dur (`lib/core/appairage/service_appairage.dart:184-189`) : le
commentaire admet que la valeur de référence est serveur ; l'élève n'a pas le droit de lire `app_config`. Le modèle
lie un appareil **à un élève** (`device_pairing_codes.student_profile_id`, `0004:270-282`) ; le « choix de profil »
d'un appareil passe par `profils_du_foyer_v` (`0004:907-926`) : la notion d'« appareil partagé du foyer » de M L80,
L130, L230 n'a pas d'objet serveur propre (à confirmer par C05).

### 4.13 PIN (code personnel de l'élève)

| Règle | Source | Date | Statut |
|---|---|---|---|
| Code personnel local, jamais transmis, pas de « code oublié » : le tuteur révoque et réappaire | ADR `decisions.md:575-583` | 06/09 | Historique repris par le code |
| « Entrer mon code PIN : vérification existante, récupération assistée » ; « PIN selon protocole existant, sans accès au compte tuteur » | M L85, M L230 | 24/09 | Mandat |

Code : 4 chiffres (`lib/core/appairage/code_local.dart:28-29`), empreinte salée dans le coffre du système, jamais en base
(`code_local.dart:7-26`) ; test de non-fuite `test/appairage/code_local_test.dart` (cité par `lib/CLAUDE.md:54-55`).
« Récupération assistée » = révocation + réappairage par le tuteur ; aucun reset distant n'existe ni ne doit exister.

### 4.14 Accès, abonnement, paiements manuels

| Règle | Source | Date | Statut |
|---|---|---|---|
| Premier onboarding avec paiement hors application consigné par l'admin et accès daté ; jamais de facture ou paiement simulé présenté comme réglé | DC `01:37` ; DC `06:28` ; DC `07:20` | 22/09 | Canonique DC |
| Afficher seulement montants, devises, statuts, dates fournis ; accès offert/daté/paiement externe ≠ abonnement récurrent ; pas de prestataire ni tarif fixe ; actions financières absentes = indisponibles | M L168 ; M L98-99 | 24/09 | Mandat |
| Statuts de compte `pending_kyc`, `provisional_active` (import seulement), `active`, `suspended` | ADR-014 `decisions.md:439-452` ; ADR-015 `:509-520` | 06/09 | Historique repris par le code |
| Tarifs anciens (50/90/40 USD) jamais constantes Flutter | DC `07:23` | 22/09 | Canonique DC |

Code : `profiles.access_until` (`0001_fondations.sql:79`), vérifié par `app_account_valid()` (`0001:421`), modifiable
par l'admin seul (`0001:539-550`). **Aucune table de paiement famille** (liste des `create table` : seules
`wallets`, `wallet_entries`, `payout_methods`, `payouts`, `fx_rates` côté rémunération, `0001:246-282`) : la page
« Paiements » n'a aucune source.

### 4.15 Notifications

| Règle | Source | Date | Statut |
|---|---|---|---|
| Notification cours, changement et validation ; annonces/messages selon droits | DC `06:26` | 22/09 | Canonique DC (M) |
| Route « Notifications » : liste, détail, destination liée ; ne pas créer de messagerie | M L70, M L105 | 24/09 | Mandat |
| Rappels J-7 / J-1 de l'échéance de migration, dans l'app et par notification | ADR-014 `decisions.md:456-459` | 06/09 | Historique |
| Canal de notification inexistant (`device_tokens` vide) | ADR `decisions.md:1833` | 12/09 | Historique, toujours vrai en code |

Code : table `device_tokens` seule (liste des tables), aucune table de notifications. Les interrupteurs
« notifications cours/foyer » du compte (`lib/features/compte/compte_page.dart:301-315`) écrivent un modèle **en
mémoire** (`lib/core/preferences/preferences_locales.dart:18-22`, `:30-31`) : réglage perdu au redémarrage, sans
aucun envoi derrière. Le commentaire « sans faire croire qu'une écriture distante a réussi » (`:21-22`) est exact pour
l'écriture, mais l'écran laisse croire qu'un réglage de notification existe.

### 4.16 Sayyid / Sayyida

| Règle | Source | Date | Statut |
|---|---|---|---|
| `Sayyid`/`Sayyida` dans l'espace cours ; photo publique de l'enseignant | DC `00:28` ; DC `01:25` ; DC `03:12` | 22-23/09 | Canonique DC |
| Bloc classe : nom **et** photo publique de l'enseignant, titre Sayyid/Sayyida ; ne pas confondre portrait élève et photo enseignant | M L116 ; M L263 | 24/09 | Mandat |
| D-02 : jamais « Ustaz » ; colonne `teacher_profiles.titre` ∈ {`sayyid`,`sayyida`}, nullable | `0030_tc_socle.sql:178-183` | 20/09 | Code main |

Code : `mes_groupes_famille_v` sert `teacher_titre` (`0033:156`). Commentaire périmé
`lib/core/tc_groupe/group_summary_vm.dart:11-12` (« Aucune colonne de la base ne porte ce titre ») contredit par
`0030:182`. Sur `v0/verite-produit`, `groupes_supabase.dart:44-50` **replie un titre absent sur `Sayyid`** alors que
son propre commentaire dit « pas une valeur à deviner » : repli à proscrire (risque de mal genrer).

### 4.17 Vocabulaire interdit ou encadré

| Terme | Règle et source | Présence dans le code (main) |
|---|---|---|
| « Mode enfant » | Interdit : DC `00:28`, DC `08:39`, M L263 | `compte.modeEnfant` (`strings_fr.g.dart:8333`) utilisé `compte_page.dart:547`, `:590-592` ; `galerie.modeEnfant` (outil dev) |
| « Cours en cours » | **Interdit** : M L356 (« Séance en direct », « En direct », « En séance ») ; recette M L489 | `enseignant.journee.coursEnCours` (`journee_page.dart:427`) ; `tc.groupe.temps.enCours` « Cours en cours · {reste} » (`libelles_tc_groupe.dart:147`) ; `tc.classe.barre.titre` (`barre_cours_en_cours.dart:63`) |
| « Cours toujours en cours » | **Prescrit** pour la séance prolongée : DC `01:25`, M L117 | `tc.groupe.temps.prolongee`, `tc.classe.entete.coursEnCours` (`strings_fr.g.dart:8814`, `:8957`). Pas littéralement le libellé interdit : voir contradiction K9 |
| « Cours enregistré », « enregistré en audio » | Interdit tant que faux : DC `08:37`, DC `06:33`, `CONFIGURATION_BASELINE_2026-09-23.md:139` | `salle.bandeauPermanent` (`permanent_notice.dart:61`), `contrat.pointEnregistrement` (`signature_page.dart:39`, `:61`). Corrigé seulement sur `v0/verite-produit` (`33503fe`) |
| Codes internes (`F1-PHO-01`, `CORE24`, F1/F2...) | DC `03:12`, DC `01:35`, DC `00:18`, M L191 | Non observé dans le parcours tuteur (hors périmètre de recherche exhaustive) |
| « Ustaz » | D-02 (`0030:179`) | Non |
| « Votre classe est réservée » avant groupe réel | ADR-031 `decisions.md:1761-1762` ; OQE:259-260 | Non (test cité `FABLE_ONBOARDING_CLASSES_REPORT.md:255`) |
| « Enfant » pour le propre profil du parent | M L115, M L128 | Fonction et écran nommés « enfant » (`creer-profil-enfant`, `ajouter_enfant_page.dart`) |
| « Réseau bon » sans mesure ; compteur négatif | M L121, M L156 ; DC `01:25` | - |
| Emoji, M-dash | `lib/CLAUDE.md:34` | Vérifié par `tool/verifier_jetons.dart` (non exécuté ici) |

---

## 5. Contradictions et source qui prévaut

Ordre du mandat : 1 mandat > 2 sécurité/contrats > 3 high-fi > 4 décisions métier récentes > 5 Bible/tokens > 6 historique.

| # | Sujet | Mandat | Specs (DC / directeur hors DC) | Code connu | Prévaut | Conséquence frontend / dépendance |
|---|---|---|---|---|---|---|
| K1 | **Catalogue : classe réelle ou offre vitrine** | Classe précréée avec enseignant, toutes les séances, **places réelles** (M L86, L152, L195) | DC `00:17`, `00:26`, `01:20` : classe précréée, enseignant, places. **ARB:52** : « Marketplace famille DEPRECATE : une famille choisit une Offre, pas une Classe réelle » ; ADR-031 `decisions.md:1729` : ni enseignant, ni places sur la carte | `parcours_offres` + `offres_horaires` sans enseignant ni places (`0043`, non appliquée) ; aucune RPC famille de catalogue de groupes ; seulement `mes_groupes_famille_v` pour les groupes déjà rejoints (`0033:140-170`) | Rang 1 (mandat) et DC concordent ; mais **contradiction métier réelle avec la décision directeur ARB** : M L30 interdit de trancher en silence | **À faire trancher par le directeur.** Aucune source serveur pour un catalogue de classes réelles : dépendance backend. Ne pas afficher enseignant/places sur une offre vitrine (contrat de modèle) |
| K2 | Quota d'observation | 2 × 120 s, 240 s total (M L372-379) | DC `01:30` : 1 visite / 120 s | `0036:16-19`, `:191-194` : 2/120/240 (prod) | Mandat | Code déjà aligné ; DC `01:30` à corriger par le directeur (hors lot) |
| K3 | Cohortes | 6-9/10-13/14-17/18+ si confirmées (M L193) | ARB/CXC : oui, définitif ; DC silencieux | 5-7/8-10/11-14/15-17/18+ (`0043:114-118`, non appliquée) | Mandat + décision directeur (rang 4) | L'UI lit `cohortes_age` du serveur, aucune tranche codée ; nouvelles cohortes = dépendance backend |
| K4 | Date de naissance | DOB dans la fiche (M L74) | ARB:119-139 DOB canonique ; OQE:57-62 « jamais de DOB » (archive) | Âge entier à la création (`0004:862`), tranche à l'onboarding ; aucune colonne DOB | Mandat + ARB | Champ DOB = dépendance backend ; ne jamais dériver une date d'une tranche (ARB:127-128) |
| K5 | Débutant sans diagnostic | Débutant direct (M L192) | ARB:146-157 ; DC `07:8` (D0 pour tous) ; DC `01:19`, `06:13` ambigus | `diagnostic_statut` `a_planifier` pour tous (`0043:242`, `:810-811`) ; libellés « Rendez-vous prévu » (`strings_fr.g.dart:8218-8221`) | Mandat (renvoie explicitement à la décision la plus récente = ARB) | Carte « Je débute » : UI possible, mais l'état « diagnostic à planifier » restera affiché tant que le serveur l'écrit : dépendance (`placement_basis`) |
| K6 | Interface guidée à 10 ans | Demande de standard à 10 ans + activation tuteur « si confirmées dans le dépôt » (M L140) | CXC:751-791 ; ARB:337-346 (hors main) ; ADR seuil 8 (`decisions.md:592-599`) | Seuil 8 à la création (`0004:869-874`) ; 0043 réécrit le mode par cohorte (`0043:634`) ; tuteur écrit directement (`0005:562-564`) ; pas de demande enfant | Mandat (comportement) ; rang 2 : garantie serveur requise | Bascule tuteur existante utilisable ; « demande de l'enfant » = dépendance ; signaler l'écrasement par 0043 et la policy non bornée au rôle (PLAUSIBLE) |
| K7 | Photo requise avant visio | Seulement si confirmé par les données (M L119, L138) | S24:57-63 (mineur, gelé) ; DC silencieux | Aucun contrôle sur main ; contrôle sur `astra/core24-v2` seulement | Mandat + rang 2 (contrat réel de main) | **Ne pas afficher de blocage photo** sur main ; dépendance si le directeur confirme S24 |
| K8 | T-20 | T-20 configurable (M L117) | DC `01:25` | Serveur 20 min (`0030:34`) ; client 10 min en dur (`pre_vol.dart:22`) | Serveur (rang 2) + DC | L'UI tuteur doit lire la fenêtre serveur (`join_opens_at`, `0037:89`), jamais `seuilOuvertureSalle` |
| K9 | « Cours en cours » / « Cours toujours en cours » | Interdit « Cours en cours » (M L356) mais prescrit « Cours toujours en cours » (M L117) | DC `01:25` prescrit « Cours toujours en cours » | Les deux libellés existent (4.17) | Mandat, partie observation plus récente | Remplacer « Cours en cours » ; pour la prolongation, garder « Cours toujours en cours » (non interdit littéralement) **ou** demander au directeur s'il préfère « Séance toujours en direct » : point à confirmer |
| K10 | « Mode enfant » | Interdit (M L263) | DC `00:28`, `08:39` | `compte_page.dart:547`, `:590-592` | Mandat + DC | Correction frontend (propriétaire Compte/Foyer) |
| K11 | Texte de consentement « cours enregistré » | Aucun faux succès (M L50) ; consentement existant préservé (M L194) | DC `06:33`, `08:37` | Texte faux signé par les tuteurs (`strings_fr.g.dart:7440`) ; correctif sur `v0/verite-produit` seulement | DC + mandat | Changer le texte impose un bump `VersionsContrat.courante` (`versions_contrat.dart:1-13`) donc re-signature générale : **décision directeur** ; dépend aussi du sort de `33503fe` (DC `08:66`, `08:82`) |
| K12 | Consentement d'observation | Nouveau consentement explicite, non précoché, comptes existants non réputés d'accord (M L423-429) | DC `01:30` (vérifier la protection des mineurs) | 3 sortes seulement (`0004:224-228`) | Mandat | Dépendance backend (nouvelle sorte ou mécanisme de version) ; l'UI ne peut que rendre le texte |
| K13 | Qui voit le tuteur | Enseignant + enfant concerné (M L390) | Archive TUT-01 : « l'enseignant le voit arriver » (`08-catalogue-ecrans.md:413-414`) | `0040@observation/...` appliquée en prod, absente de main | Mandat | Frontend conforme possible ; intégration de 0039-0042 dans main en attente (DC `08:79`, `08:83`) |
| K14 | Enfant présent requis | Oui (M L381) | - | Non vérifié par `entrer_observation` (`0037:102-113`) | Mandat, mais garantie serveur absente | Dépendance backend ; ne pas activer l'observation réelle sur une protection locale (M L368) |
| K15 | Quota individuel ou partagé ; plusieurs enfants | Point ouvert (M L482) | - | Individuel par observateur (`0033:1035`, `:1170`) ; un seul enfant (`0037:104-109`) | Non tranché | Afficher la politique effective renvoyée ; ne pas promettre un quota foyer |
| K16 | Mot de passe | « Méthodes existantes, mot de passe, sessions » (M L97) | ADR-016 : « Aucun mot de passe, nulle part » (`decisions.md:537-542`) | Lien courriel + Google ; mot de passe seulement sous `DEMO_AUTH` (`lib/core/auth/service_auth.dart:17-24`, `:50-64`) | Rang 2 + M L13 (« ne réécris pas l'authentification ») | Pas d'écran de mot de passe ; « sessions » sans service = indisponible |
| K17 | Propre profil élève du parent, proches adultes | Possible à tout moment, jamais « enfant », adultes pas mineurs (M L128, L142, L185) | ADR-009 adulte = foyer d'une personne (`decisions.md:271-275`) | Borne client 3-18 (`ajouter_enfant_page.dart:44`) ; `student_type = 'minor'` forcé à la création (`0004:892-893`), corrigé seulement par 0043 via cohorte 18+ | Mandat | Frontend : bornes et libellés ; dépendance : type d'élève adulte et droits/consentements d'un proche adulte |
| K18 | Limite d'appareils | Vient du contrat (M L130) | ADR-010 | Serveur 2 ; client 2 en dur (`service_appairage.dart:189`) ; config illisible hors admin (`0001:969-970`) | Serveur | Garder le message « limite atteinte » déclenché par la réponse serveur ; valeur affichée = dépendance (lecture de config) |
| K19 | Scanner QR | Caméra réelle exigée (M L216-226) | ADR-016 : QR caméra reporté (`decisions.md:601-608`) | Pas de scanner | Mandat | Frontend + dépendance de paquet (coordinateur) ; aucun changement serveur requis pour le format du code |
| K20 | Notifications | Route et liste (M L70) | DC `06:26` | Aucun backend ; bascules en mémoire (`preferences_locales.dart:18-22`) | Mandat (M L50 : état indisponible honnête) | Écran « indisponible » ; retirer ou qualifier les bascules trompeuses |
| K21 | Paiements | Historique réel (M L99, L168) | DC `01:37`, `06:28` | Aucune table paiement famille | Mandat + DC | Écran indisponible ; `access_until` seul affichable |
| K22 | Titre enseignant absent | Sayyid/Sayyida (M L116) | D-02 | Repli `Sayyid` sur `v0/verite-produit` (`groupes_supabase.dart:44-50`) | Mandat + règle « ne pas deviner » | Titre absent = pas de titre affiché, jamais un repli |
| K23 | Capacités | Jamais de constante (M L264) | DC `00:27` : arbitrage ouvert ; ARB : 5/60, 6/90 définitif ; `lancement/00:27` : 4/5 | 0043 : 5/6, 60/90 (non appliquée) | Donnée serveur | Afficher `seuil_max`/`regles_academie()` ; aucune valeur écrite dans un widget |
| K24 | Typographie | DM Sans titres, Jakarta corps, « Jakarta déjà déclarée » (M L333-336) | - | Instrument Sans / Bricolage Grotesque, aucune trace de Jakarta (BRIEF L16) | Mandat | Hors domaine C09 (voir C02) |
| K25 | Copie `docs de lancement/00` | - | DC `00` du 23/09 | - | DC (plus récent) | Ne pas citer `lancement/00:27` (4/5) |

---

## 6. Dépendances backend issues des règles (sans modifier le backend)

1. Catalogue de classes réelles avec enseignant, séances, places (K1), ou décision directeur confirmant l'offre vitrine.
2. Application de `0043` en production (tout le parcours `parcours_offres` appelle des RPC absentes, `FABLE_BACKEND_CONTRACT_ONBOARDING_CLASSES.md:8-10`).
3. Cohortes 6-9/10-13/14-17/18+ et date de naissance canonique pour les mineurs (K3, K4).
4. Placement débutant sans diagnostic (`placement_basis`) et pré-diagnostic 2-4 questions (K5).
5. Demande d'affichage standard par l'enfant ≥ 10 ans, validation tuteur, écriture client directe de `interface_mode` fermée ; ne plus écraser le mode depuis la cohorte (K6).
6. Consentement d'observation parentale et mécanisme de re-consentement des comptes existants (K12) ; texte de consentement « enregistrement » véridique (K11).
7. Observation : garde « enfant présent » (K14) ; intégration dans `main` de `0039`-`0042` déjà en production (K13) ; historique inter-séances filtrable tuteur/admin (4.10).
8. Notifications (K20) et paiements famille (K21).
9. Profil élève adulte (parent ou proche) : type `autonomous`, droits et consentements d'un proche adulte (K17).
10. Lecture de la limite d'appareils et de la fenêtre T-20 par l'UI sans `app_config` admin (K8, K18).

## 7. Points à faire trancher par le directeur (changent le produit)

- K1 : la famille choisit-elle une **classe réelle** (mandat, DC) ou une **offre vitrine** (ARB, code main) ?
- K9 : libellé de la séance prolongée.
- K11 : réécriture du texte de consentement « enregistrement » et re-signature générale.
- K15 : quota d'observation par responsable ou par foyer ; plusieurs enfants dans une séance.
- DC `01:30` (1 visite) à mettre à jour vers la règle 2 × 120 s.
- Statut des décisions Classes V2 (ARB/CXC) : à intégrer dans `docs/current` pour cesser d'être « hors DC ».

## 8. Navigation tuteur : que disent les specs du 4e onglet

DC ne fixe pas les destinations de navigation du tuteur. DC `01:11` place la **présence** et la **progression**
parmi les actions majeures du tuteur, DC `03:12` résume l'accueil tuteur en « foyer, inscription et échéances », et
le mandat rend **obligatoire** un historique des observations réutilisant l'Historique existant (M L447-453, avec
séparation « Séances / Observations »). Aucune spec ne justifie une autre 4e destination : l'inscription et le
choix de classe partent du Foyer (M L72-76), les échéances et paiements du Compte (M L98-99), la classe de l'Accueil
(M L118). « Historique » est la seule destination de premier niveau que les specs soutiennent en plus
d'Accueil, Foyer, Compte. En revanche, « Disponibilités » (ancien onglet TUT-04, `08-catalogue-ecrans.md:1417-1427`)
ne doit pas revenir en navigation (DC `00:26`, DC `08:38`, M L132).
