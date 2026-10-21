# Candidatures et viviers de recrutement — revue critique avant codage

**Statut :** revue bloquante exigée par la section 12 de la spécification.
**Aucune ligne de code n'est écrite par ce lot**, et aucune ne doit l'être avant
les arbitrages de la section 9 (« Claude ne doit pas implémenter immédiatement
après lecture », spec §12.3).

**Origine :** spécification produit/UX « Module de gestion des candidatures et
viviers de recrutement », version 1.0 du 21 octobre 2026, remise par
l'opérateur. Versionnée telle quelle dans
[`docs/produit/candidatures-spec-v1.md`](../produit/candidatures-spec-v1.md)
pour que la session suivante la lise sans dépendre d'un fichier joint.

**Méthode :** lecture du dépôt (migrations `0001` à `0043`, `lib/`, catalogue,
Bible V2, ADR-001 à ADR-031), puis lecture des formulaires de candidature et de
leurs feuilles de réponses sur le Drive de l'académie, **en n'en retenant que la
structure et des comptes agrégés** (section 2). Chaque affirmation sur le code
porte sa référence `fichier:ligne` ; ce qui n'est que documenté est marqué
**[doc seulement]**.

---

## 0. Le verdict en une page

La spécification est saine dans ses intentions et compatible avec le dépôt sur
l'essentiel : séparer étape, KYC, paiement, disponibilité et affectation est
exactement ce que le schéma actuel ne fait pas encore, et ce qui lui manque.
Mais **sept constats changent sa forme** avant qu'un écran puisse être fiché.

1. **« Frontend only » ne peut livrer aucun écran fonctionnel.** Le dépôt n'a
   **aucune** entité candidature, préqualification, entretien ou vivier
   enseignant : zéro occurrence de `candidature`, `entretien`, `interview`,
   `préqualif` ou `ijaza` dans `lib/`, `supabase/` et `docs/`. Toute liste,
   tout dossier, tout statut demande une table, une RLS et des RPC. Sans
   autorisation backend, la phase actuelle ne peut produire que les fiches, les
   maquettes, le contrat de données et des composants testés contre des faux —
   jamais branchés sur des données fictives en production (spec §1.2).

2. **Aujourd'hui, valider une pièce d'identité rend un enseignant affectable sur
   le champ.** `decider_dossier()` passe le compte de `pending_kyc` à `active`
   dès l'approbation du document
   (`supabase/migrations/0004_inscription_kyc_appairage.sql:557-560`), et
   `active` est **le seul** critère d'affectabilité de `enseignants_pour`,
   `attribuer_eleve`, `prendre_eleve` et `creer_groupe` (section 3.4). La
   « salle 3 » de la spec existe donc déjà, sans entretien, sans engagement,
   sans paiement : c'est le bouton « Approuver » d'`ADM-02`. **C'est le conflit
   central**, et il se tranche avant tout le reste (décision D1).

3. **Le portail candidat existe : c'est `/attente`.** La fiche `ENS-01`
   l'interdit en toutes lettres : « Ce que cette fiche n'autorise pas :
   construire un second tunnel d'entrée » (`docs/design/08-catalogue-ecrans.md`,
   fin de la fiche `ENS-01`). La préqualification, l'engagement et l'entretien
   deviennent des pas du portail d'attente, calculés en base comme le reste de
   `etat_dossier()`, pas une application dans l'application.

4. **Le paiement est une décision d'architecture, pas un formulaire.** La
   finance est reportée en V1 (ADR-003), aucun code métier ne doit connaître le
   nom d'un prestataire (ADR-007), et pawaPay n'apparaît **nulle part** dans le
   dépôt ni dans le registre ADR. La matrice de compatibilité demandée est
   faisable comme **référentiel neutre** (pays, méthode, opérateur, état), mais
   le choix de pawaPay doit d'abord être écrit dans un ADR. Et la spec oublie la
   **Guinée (GNF)**, que l'ADR-007 rend éliminatoire (section 3.6).

5. **Un entretien dans la salle Rewayah est possible, mais ce n'est pas du
   frontend.** La salle n'émet un jeton que pour une ligne `sessions` dont
   l'appelant est participant, et un candidat `pending_kyc` est enfermé dans
   `/attente` et ne lit aucune séance. Deux voies, chiffrées en section 6.3 ;
   recommandation : l'entretien est une `sessions` d'un type nouveau, ouverte
   par une porte dédiée, **sans toucher au service de jetons**.

6. **Les polices de la spec ne sont pas celles du dépôt.** La spec écrit « DM
   Sans pour les titres ; Plus Jakarta Sans pour le reste, conformément aux
   règles existantes ». Les règles existantes disent **Bricolage Grotesque** et
   **Instrument Sans** (`docs/produit/design-tokens.md:212-217`,
   `lib/core/theme/app_typography.dart:15-30`), « quatre familles, pas une de
   plus » (`design-tokens.md:258`). Par la hiérarchie de la spec elle-même
   (§1.1 : Bible et design system avant la présente spécification), **le dépôt
   gagne**. Aucune décision à prendre, seulement à acter.

7. **Les candidatures existantes ne remplissent pas la préqualification.** Les
   formulaires Drive ne demandent ni pays de résidence, ni fuseau, ni moyen de
   paiement, ni publics, ni engagement (section 2). Un import ne peut donc
   produire que des candidatures « à compléter » par la personne elle-même,
   jamais des candidatures admissibles en salle 2.

---

## 1. Ce que cette revue a lu, et dans quel ordre

`docs/HANDOFF.md`, `docs/PROGRESS.md` (DÉMARRER ICI),
`docs/architecture/decisions.md` (ADR-002, 003, 005, 007, 011, 014, 016, 021,
023, 027, registre des questions), `docs/design/08-catalogue-ecrans.md`
(registre, fiches `TUT-00b`, `TUT-00c/b`, `ADM-02`, `ENS-01`),
`docs/design/00-bible-frontend-v2.md` (§2.2, §5.6, §38, §39, §41),
`docs/design/README.md` §4 BIS, `docs/produit/design-tokens.md`,
`docs/architecture/ADMIN_IA_AUDIT.md`, `ADMIN_UX_PLACEMENT_AUDIT.md`,
`ADMIN_FINANCE_CONFIGURATION.md`, `ADMIN_SECURITE_DIRECTION.md`,
`TEACHER_PREMERGE_REPORT.md`, `TEACHER_SHARED_CONTRACTS.md`, `lib/CLAUDE.md`,
puis les migrations et le code cités ligne à ligne plus bas.

---

## 2. Ce que disent les formulaires et leurs réponses (Drive)

**Règle suivie.** Les feuilles ont été lues en lecture seule, et seuls des
**comptes agrégés** sont reportés ici : aucun nom, aucun numéro, aucune adresse,
aucune réponse libre citée. Les fichiers temporaires du calcul ont été
supprimés. Les pays de moins de trois occurrences sont regroupés.

### 2.1 Les sources

| Source | Forme | Lignes réelles | Période |
| :--- | :--- | :-: | :--- |
| A1 — questionnaire « تعليم القرآن عن بعد », premier lien | Google Forms en arabe, 14 questions | 279 | 18 au 21 octobre 2026 |
| A2 — même questionnaire, second lien | identique | 161 | même période |
| B — formulaire « Enseignant Rewayah Academy » | Google Forms en français, 17 questions | 11 | juillet 2025 à avril 2026 |

A1 et A2 ne sont **pas** un formulaire papier et un formulaire en ligne,
malgré leur titre : ce sont deux liens du même questionnaire diffusés à deux
publics (A1 : 68 % d'indicatifs saoudiens, arabe majoritaire ; A2 : 79 %
d'indicatifs nigérians, haoussa majoritaire). Le questionnaire a été modifié
en cours de collecte (question courriel ajoutée, libellés de genre changés).

**451 lignes, 418 personnes distinctes** une fois les doublons rapprochés par
téléphone ou courriel normalisés : c'est la population « quelque 400
candidatures » de la spec §9. Aucun recoupement entre A1, A2 et B.

### 2.2 Ce que les formulaires demandent, et ce qu'ils ne demandent pas

| Donnée de préqualification (spec §3, §4.2) | A | B |
| :--- | :-: | :-: |
| Identité, contact | nom, WhatsApp, courriel (ajouté en cours de route : 28 lignes sans) | prénom, nom, courriel, téléphone |
| Genre | oui | oui |
| **Pays de résidence, fuseau** | **non** (seul l'indicatif téléphonique le laisse deviner) | **non** |
| Langues | maternelle + langues d'explication | parlées + d'enseignement |
| Mémorisation | niveau en cinq paliers | terminée oui/non |
| Ijaza, diplôme | « présentable à l'entretien » oui/non/test | cases (attestation, ijaza, diplôme) |
| Riwaya | non | oui |
| Expérience | avec les débutants, oui/non | texte libre |
| Disponibilités | créneaux **en heure de La Mecque**, heures par semaine, date de début | créneaux **en UTC**, jours |
| **Publics** (enfants, adultes, femmes, hommes) | **non** | **non** |
| **Moyen de paiement** (banque, mobile money) | **non** | **non** |
| **Engagement religieux** | **non** | **non** |
| Consentement au contact | WhatsApp, 100 % | — |
| Pièce d'identité | non | photo, sous forme de lien Drive |

**Conséquence directe** : aucune des 418 personnes ne peut être admissible en
salle 2 à partir de ses seules réponses. Toutes passent par « à compléter » :
pays de paiement, moyens de réception, publics, fuseau et engagement manquent
partout. L'import sert à **inviter**, pas à préqualifier (section 7).

### 2.3 Les chiffres qui changent la spec

**Pays (déduits de l'indicatif, donc indicatifs) :** Arabie saoudite environ
210, Nigeria 131 (une dizaine de plus au format national nigérian), Yémen 12, Tchad 7, Sénégal 5, Niger 5, Guinée 3 dans
A (et 6 numéros de B au format guinéen probable), Burkina Faso 3, Kenya 3 ;
une vingtaine d'autres pays à moins de trois chacun.

- La spec cite le Nigeria, la Côte d'Ivoire et le Sénégal comme pays à
  examiner pour le paiement. **Le premier groupe de candidats indique
  l'Arabie saoudite**, où le mobile money africain ne s'applique pas, et la
  Côte d'Ivoire ne compte que trois personnes. La matrice doit d'abord couvrir
  l'Arabie saoudite et le Nigeria (décision D5).
- La **Guinée** (ADR-007, GNF) est le pays des enseignants déjà en place
  (source B, poular majoritaire), pas celui des nouveaux candidats.

**Genre :** 351 hommes, 89 femmes dans A ; aucune femme dans B. Si la
séparation s'applique aux entretiens (D6), il faut des intervieweuses.

**Langues d'explication (choix multiple, A) :** arabe 400, anglais 240, français
55, ourdou 26, autres sous 15. Le référentiel des langues de cours de `0043`
ne connaît que poular, français et anglais (`0043:67`). L'ADR-029 dit qu'une
langue s'ouvre « quand l'académie recrute un enseignant qui la parle » : ces
chiffres sont la matière de cette décision, et la langue du candidat doit être
saisie **dans le référentiel**, pas en texte libre comme
`teacher_profiles.languages` aujourd'hui.

**Mémorisation (A) :** Coran entier 263, ijaza de lecture et d'enseignement 84,
plus de dix juz' 50, moins de dix juz' 15, non mémorisé mais bonne lecture
28. **Ijaza présentable à l'entretien :** oui 334, « non, mais prêt à un test
de niveau » 89, non 17 — ce test de niveau est exactement le constat
d'entretien de la décision D7.

**Disponibilité (A) :** début immédiat 375, le mois prochain 53 ; 3 à 5 heures
par semaine 154, 6 à 10 heures 130, plus de 10 heures 99, moins de 3 heures 57.
Les créneaux sont exprimés en heure de La Mecque (UTC+3), ceux de B en UTC : un
import qui les recopierait sans conversion décalerait tout de trois heures.

### 2.4 Qualité des données, pour l'import

| Constat | Ampleur | Règle d'import qui en découle |
| :--- | :--- | :--- |
| Doublons (renvois, corrections) | 27 groupes, dont 14 aux réponses **différentes** | proposer la ligne la plus récente, garder les autres comme historique de la référence source ; jamais de fusion silencieuse |
| Nom différent dans un groupe relié par téléphone ou courriel | 5 groupes (écriture arabe/latine, élément ajouté, contact partagé) | le rapprochement s'appuie sur le contact, et l'écran montre les deux noms |
| Téléphones sans indicatif ou mal formés | 55 sur 451 (format national, `0` en trop après l'indicatif, longueur fausse), et 71 autres dont l'indicatif n'a ni `+` ni `00` ; certaines cellules stockées comme nombres | normaliser sans deviner : un numéro sans indicatif reste « à confirmer » par la personne |
| Courriels absents ou suspects | 32 absents, quelques fautes de domaine, une adresse jetable, un numéro saisi à la place | un courriel invalide n'est jamais une clé de rapprochement |
| « Autre » sans précision | 46 langues maternelles, 72 langues d'explication | importé comme « autre, à préciser », jamais comme une langue |
| Choix multiples contenant une virgule, en-têtes avec apostrophe ou espace en tête | plusieurs colonnes | découper selon la liste d'options, et faire le mappage sur l'en-tête normalisé |
| Variantes d'un même libellé (deux graphies du genre ; « Hasf » pour « Hafs ») | deux colonnes | table de correspondance des libellés dans l'écran de mappage |
| Réponses contradictoires (« disponible à toute heure » avec des créneaux précis ; « pas après 20 h » avec des créneaux de nuit) | 24 lignes | signalées en avertissement, importées telles quelles |
| Liens Drive vers des photos d'identité (B) | 4 | **jamais importés** : la pièce passe par le dépôt KYC de l'application, cloisonné par genre |

---

## 3. Cartographie de l'existant réutilisable

### 3.1 Le tunnel d'entrée de l'enseignant (confirmé dans le code)

| Surface | Route | Fichier | Base |
| :--- | :--- | :--- | :--- |
| `TUT-00c` Création de profil (rôle, nom, genre, récapitulatif) | `/inscription` | `lib/features/inscription/inscription_page.dart` | `creer_profil_inscription` crée **toujours** `pending_kyc` (`0004:405`) |
| `TUT-00b` Portail d'attente | `/attente` | `lib/features/dossier/attente_page.dart` | `etat_dossier()` (`0004:431`) : `profil`, `role`, `statut`, `piece_deposee`, `piece_statut`, `motif_refus`, `depose_le`, `contrat_signe`, `accuse_signe` |
| `TUT-00c/a` Accusé enregistrement et contrôle | `/attente/accuse` | `lib/features/dossier/signature_page.dart` | `contract_acceptances`, sorte `recording_and_control_notice` |
| `TUT-00c/b` Contrat | `/attente/contrat` | même fichier | `contract_acceptances`, sorte `teacher_nda` ; version courante `2026-09` (`lib/core/dossier/versions_contrat.dart`) |
| `TUT-00c/c` Dépôt de la pièce | `/attente/piece` | `lib/features/dossier/depot_piece_page.dart` | seau privé `kyc`, `kyc_documents` ; 8 Mo maximum |
| `ADM-02` Validation des dossiers | `/admin/personnes/dossiers` | `lib/features/admin_dossiers/dossiers_page.dart` | `dossiers_en_attente()` (une ligne par **personne** depuis `0015`), `decider_dossier()`, `read_kyc_documents()` cloisonnée par genre et journalisée |
| `ADM-08` Comptes | `/admin/personnes/comptes` | `lib/features/admin_comptes/comptes_page.dart` | `comptes_admin()` (`0015:126`) |
| `ENS-01` Bienvenue | `/enseignant/bienvenue` | `lib/features/bienvenue_enseignant/bienvenue_page.dart` | lecture seule ; **aucun écran n'y mène** (seule la déclaration de route, `app_router.dart:348`) |
| `ENS-05` Profil enseignant | `/enseignant/profil` | `lib/features/profil_enseignant/profil_enseignant_page.dart` | `maj_profil_enseignant(p_country, p_languages, p_timezone)` (`0027`) ; le client n'envoie jamais `p_timezone` |
| `ENS-06` Disponibilités et matching | `/enseignant/creneaux` | `lib/features/creneaux/creneaux_page.dart` | `weekly_availability`, `eleves_en_attente_v`, `prendre_eleve` |

Les états affichés au candidat existent déjà, calculés en base et jamais à
l'écran : `EtapeDossier {incomplet, enVerification, refuse, suspendu}` et
`PieceManquante {accuse, contrat, pieceIdentite}`
(`lib/core/dossier/etat_dossier.dart`). La garde du routeur confine
`pending_kyc` et `disabled` à `/attente/*` (`lib/core/router/redirection.dart:64-68`).

### 3.2 Les objets de base réutilisables

| Besoin de la spec | Ce qui existe | Limite |
| :--- | :--- | :--- |
| Identité centrale, sans doublon | `profiles` (`immutable_id` `TEACHER-XX-000001`, rôle, statut, genre) | une candidature **sans compte** n'a aucune place |
| Profil métier enseignant | `teacher_profiles` : `country` (texte libre), `languages text[]` (texte libre, **non relié** au référentiel `langues_cours` de `0043:67`), `timezone_iana`, `kyc_status`, `weekly_hours_cap` (jamais appliqué) | aucun champ tajwid, hifz, ijaza, riwaya, publics |
| KYC soumis, examiné, validé | `kyc_documents` (`pending`/`approved`/`rejected`, `verified_by`, `verified_at`, `rejection_reason`), `decider_dossier()`, cloisonnement par genre **en base** | pas d'expiration ; la checklist « lisible, nom, validité » d'`ADM-02` n'est **pas enregistrée** (`dossiers_page.dart:49`) |
| Engagement accepté, versionné, daté | `contract_acceptances` : unique sur (profil, sorte, version), immuable par déclencheur (`0004:221`) | la sorte est une énumération fermée : `guardian_terms`, `teacher_nda`, `recording_and_control_notice` |
| Historique traçable | `log_sensitive_access()` chaîné par hachage, `audit_logs` en ajout seul, vérifiable (ADR-022) | `journal_audit()` ne filtre **pas** par ligne (`row_id`) : aucun historique par dossier n'est lisible aujourd'hui |
| Disponibilités et fuseau | `weekly_availability`, `mon_fuseau`, `instant_creneau` | réservés à un enseignant `active` via `ENS-06` |
| Conservation des données | `kyc_retention_days = 90`, `purge_at`, réglable dans `ADM-17` | `purge_at` part du **dépôt**, pas de la décision ; **aucune tâche de purge n'existe** |
| Visio | `create-room-token`, `autoriser_jeton_video` (`0033:1643-1781`), `FenetreSeance`/`PhaseSeance`, `ServiceVideo`, portes d'observation (`entrer_observation`, `0037:56-179`) | tout est ancré sur une ligne `sessions` (section 6.3) |
| Référentiel administrable | motif `langues_cours` / `cohortes_age` (`0043:67-138`) : code, libellé, ordre, actif, lu par tout authentifié, écrit par l'admin | c'est la bonne forme pour la matrice de paiement, pas `app_config` |

### 3.3 Les briques d'administration

| Besoin | Ce qui existe | Écart |
| :--- | :--- | :--- |
| Placement | domaine **Personnes** (`ADM-02` fonction primaire, `ADM-08`), `lib/core/admin/admin_domaine.dart:12-49` | huit domaines au plus, `assert` dans `admin_shell.dart:57-61` : « Recrutement » ne peut **pas** être un neuvième domaine. Personnes n'a pas de `SousNavigationDomaine`, choix opérateur délibéré (`ADMIN_UX_PLACEMENT_AUDIT.md:91-115`) |
| Liste dense | `DataCollection<T>` (`lib/core/widgets/data_collection.dart:17-180`) | une seule ligne sélectionnable, **ni tri, ni case à cocher, ni barre de sélection** ; or `05-regles-responsive.md:58` exige le tri par colonne |
| Filtres | `FilterPill`, `MenuFiltre<T>` | une valeur par axe ; état local `setState`, **jamais dans l'URL**, perdu à chaque navigation ; règle 2 du gel (`ADMIN_IA_AUDIT.md`) exige un filtre sérialisable pour les raccourcis d'Accueil |
| Pagination | `ADM-04` seul : curseur `(avantDate, avantId)`, 50 par page, plafond 200 (`service_journal.dart:207-244`) | `ADM-08` et `ADM-09` chargent tout et filtrent côté client |
| Recherche | aucune recherche partagée ; la barre d'`AdminShell` ne cherche que des libellés de navigation (`admin_shell.dart:438-457`) | à construire |
| Actions groupées | **aucune** : chaque mutation est une RPC sur un objet | aperçu, portée, rapport d'échec partiel : tout est neuf |
| Modale | `AppBottomSheet.ouvrir` est le seul point d'entrée ; `showDialog` est refusé par `tool/verifier_jetons.dart:351-356` ; la Bible §5.6 interdit la feuille pour une tâche complexe | l'aperçu d'un lot et le mappage d'import sont des **pages**, pas des modales |
| Confirmation | `ConfirmDestructive.demander` | une confirmation, pas un rapport ligne par ligne |
| États | `Skeleton`, `EmptyState` (`actionnable`/`subi`/`bonneNouvelle`), `OfflineBanner` via `PageShell`, `StatusPill` (couleur **et** mot) | suffisants |
| Capacités | `peutEcrire` (jamais lu par un widget), `peutVoirDirection` (codé `false`) | aucune capacité par fonction ; « l'équipe qui n'accède qu'aux champs nécessaires » n'a pas de support |
| Import | aucun paquet CSV, Excel ou Google ; `file_picker` sert au seul KYC | tout est neuf |

### 3.4 Ce qui rend un enseignant affectable aujourd'hui

Un seul test, partout : `role = 'teacher'`, `account_status in ('active',
'provisional_active')`, `deleted_at is null`.

- `enseignants_pour` (`0008:188-190`) et `attribuer_eleve` (`0008:239-247`), donc `ADM-05` ;
- `prendre_eleve` (`0005:1029`, via `app_account_valid`), donc le fil d'`ENS-06` ;
- `creer_groupe` (`0019:61-66`), donc `ADM-09`.

`teacher_profiles.kyc_status`, les langues, le genre et la signature du contrat
**ne sont jamais vérifiés**. Pire : `decider_dossier()` ne vérifie pas que
`teacher_nda` ni l'accusé ADR-011 sont signés avant d'activer le compte
(`0004:523-571`). Un administrateur peut donc rendre affectable un enseignant
qui n'a signé ni le contrat ni l'accusé d'enregistrement — ce que la fiche
`ENS-01` déclare pourtant « obligatoire », et ce que l'ADR-011 qualifie de
litige s'il est découvert après coup.

Aucun écran ni aucune RPC ne pose `disabled` ou `provisional_active`. La
colonne `kyc_completion_deadline` que décrivent l'ADR-014 et la fiche `ENS-01`
**n'existe pas** (zéro occurrence dans `supabase/` et `lib/`) : l'ADR et la
fiche sont en avance sur le schéma.

### 3.5 Les autres briques que la spec suppose

| La spec suppose | État réel |
| :--- | :--- |
| « évaluations de lecture, tajwid et mémorisation selon le référentiel existant » | le seul référentiel est celui des **élèves** (`0020`-`0024`, `ADM-10` à `ADM-14`) ; rien n'évalue un enseignant |
| un moyen de prévenir le candidat | **aucun canal d'envoi** : SMTP externe commenté (`supabase/config.toml:239-247`), SMTP intégré limité à deux courriels par heure et aux membres de l'organisation, `device_tokens` vide, aucune fonction Edge d'envoi |
| une interface lisible par un candidat arabophone | le fichier de traduction arabe existe, **vide** (`docs/HANDOFF.md` §10.3) |
| un rôle comptable qui révise la matrice | `accountant` existe en base ; `/comptable` rend un écran de compte générique, `CPT-01` est hors MVP-0, et le comptable **ne lit pas** `app_config` (RLS admin seule) |
| une séparation femmes/hommes | elle n'existe **qu'à la lecture du KYC** (`read_kyc_documents`, genre du lecteur obligatoire) ; aucun appariement par genre entre enseignant et élèves |

### 3.6 Paiements : ce que le schéma porte, et ce qu'il interdit

- `payout_methods` (`0001:263-271`) : `profile_id`, `kind` en **texte libre**,
  `details jsonb`. Ni pays, ni opérateur, ni devise.
- `payouts` (`0001:273-280`) pend d'un `wallet_id`, et `wallets` est **un par
  foyer**. Un enseignant a `household_id` nul (`0004:40-45`) : **il ne peut pas
  recevoir de ligne `payouts`** dans le schéma actuel.
- `payout_methods_family_read` (`0001:1122-1128`) filtre par foyer : un
  enseignant **ne lit pas ses propres moyens**, contrairement à
  `etape-0-1-fondations.md:136` [doc seulement]. Le verrou de 48 heures sur un
  changement de moyen (`etape-0-1-fondations.md:88`) n'a pas de déclencheur
  [doc seulement].
- ADR-007 : abstraction `PayoutProvider` obligatoire, aucun code métier ne
  connaît un prestataire, et la grille éliminatoire commence par « payout vers
  GNF et XOF ». `docs/architecture/audit-initial.md:48-59` fait de la Guinée le
  cas bloquant de Flutterwave.
- `ADMIN_FINANCE_CONFIGURATION.md:74` : `/admin/finance/remuneration` est
  bloquée par ADR-003 et ADR-007 ; aucune fonction Finance ne se construit
  sans décision opérateur écrite (lignes 94-97). `docs/HANDOFF.md:2857` : « Ne
  choisis aucun prestataire ou seuil financier sans décision écrite. »

**Ce que cela veut dire pour la spec.** La règle produit de la section 4
(préférence bancaire, mobile money recevable, coordonnées financières
demandées au moment opérationnel) est **compatible** avec tout ce qui précède,
à une condition : la matrice est un référentiel de capacités, dont le
prestataire n'est qu'une colonne. La déclaration en préqualification
(« j'ai un compte bancaire », « j'ai accès à Wave ») est une **réponse de
candidature**, pas une ligne de `payout_methods` : la spec interdit justement
d'y mettre un numéro, et `payout_methods` n'existe que pour porter des
coordonnées.

### 3.7 Collision de vocabulaire

**« Vivier » existe déjà, et désigne autre chose.** La migration `0043` appelle
vivier l'ensemble des **élèves** en attente d'une offre horaire
(`0043:348, 664, 993-1037, 1168`, `lib/core/offres/offre_horaire.dart:133,572`,
`decisions.md:1757`). Un second « vivier » côté enseignants rendrait les
journaux, les RPC et les fiches ambigus. Proposition : l'étape finale s'appelle
**« Prêts à être affectés »** à l'écran, `confirme` dans le code ; le mot vivier
reste aux élèves (décision D11).

---

## 4. Écarts entre le dépôt, les specs existantes et ce document

| # | Écart | Spec candidatures | Dépôt ou spec existante | Proposition |
| :-- | :--- | :--- | :--- | :--- |
| E1 | Activation à la validation KYC | Salle 3 = KYC **et** entretien **et** engagement **et** paiement | `decider_dossier()` active le compte à l'approbation de la pièce (`0004:557-560`) | Pour l'enseignant, l'approbation KYC ne pose plus que `kyc_status` ; l'activation devient l'entrée en « Prêts à être affectés » (D1) |
| E2 | Contrat non vérifié à l'activation | prérequis tous validés | `decider_dossier()` ne lit pas `contract_acceptances` | Défaut existant, indépendant de la spec : à corriger dans le premier lot backend, quoi qu'il arrive |
| E3 | « Refusé » vs « à compléter » | deux sorties distinctes | `EtapeDossier.refuse` porte les deux ; question ouverte de la fiche `ENS-01` et de `TEACHER_PREMERGE_REPORT.md:198-216` | La spec **tranche** cette question ouverte : deux états distincts (à acter, D2) |
| E4 | Second tunnel | « portail candidat confidentiel » | fiche `ENS-01` : pas de second tunnel | Le portail candidat **est** `/attente`, étendu de trois pas |
| E5 | Polices | DM Sans, Plus Jakarta Sans | Bricolage Grotesque, Instrument Sans | Le dépôt gagne, par la hiérarchie §1.1 de la spec |
| E6 | Thème sombre | « support des thèmes clair et sombre » | tenu (`AppPalette.sombre()`, lot T3) | rien à faire |
| E7 | Prestataire de paiement | pawaPay « confirmé et utilisable » | absent du dépôt et des ADR ; ADR-007 interdit tout nom de prestataire dans le code métier | ADR à écrire avant le premier écran de la matrice (D5) |
| E8 | Pays couverts | Nigeria, Côte d'Ivoire, Sénégal | ADR-007 : GNF **et** XOF éliminatoires ; la Guinée est le cas qui a fait tomber Flutterwave. Les candidatures réelles indiquent d'abord l'Arabie saoudite, puis le Nigeria (section 2.3) | Vérifier d'abord Arabie saoudite et Nigeria, puis Guinée, Sénégal, Côte d'Ivoire (D5) |
| E18 | Langues du candidat | « compétences » | `teacher_profiles.languages` en texte libre, non relié à `langues_cours` (poular, français, anglais) ; les candidats expliquent surtout en arabe et en anglais | la langue se choisit dans le référentiel ; une langue absente nourrit la décision d'ADR-029, elle ne s'invente pas en texte libre |
| E9 | Évaluation de l'enseignant | « selon le référentiel existant » | le référentiel existant est celui des élèves | Un référentiel enseignant est à définir, ou la salle 2 se contente d'un constat d'entretien structuré (D7) |
| E10 | Vivier | vivier confirmé enseignant | vivier = élèves en attente (`0043`) | Libellé « Prêts à être affectés », code `confirme` (D11) |
| E11 | Notification et invitation | « Invitation envoyée », « Informations à compléter » | aucun canal d'envoi | Sans SMTP, « invitation envoyée » est un **constat manuel** de l'administration, pas un envoi (D9) |
| E12 | Disponibilités en salle 3 | « disponibilités suffisamment renseignées » | `weekly_availability` n'est accessible qu'à un compte `active` (`ENS-06`) | En candidature, la disponibilité est **déclarée** (réponse) ; la grille opérationnelle se remplit après activation, dans `ENS-06`, jamais en double |
| E13 | ADR-014 et import | « import des 400 candidatures, aucun compte actif » | ADR-014 : l'import d'enseignants **déjà actifs** produit `provisional_active` | Deux imports distincts, jamais confondus : les candidats n'obtiennent jamais `provisional_active` (section 7) |
| E14 | `kyc_completion_deadline` | — | décrite par ADR-014 et `ENS-01`, absente du schéma | Écart documentaire à corriger dans l'ADR, hors périmètre de ce lot |
| E15 | Historique par dossier | « accès rapide à l'historique » | `journal_audit()` sans filtre par ligne | Une RPC de lecture bornée à un dossier, et sa trace de consultation (question 27 du registre) |
| E16 | Actions groupées | aperçu, portée, rapport partiel | rien ; modale complexe interdite | Une page d'aperçu et un composant de rapport ligne par ligne, neufs |
| E17 | Recherche par téléphone « selon les permissions » | capacité par champ | aucune capacité par fonction ou par champ | Le masquage se fait en base (comme `comptes_admin()`), jamais par un `if` d'écran |

---

## 5. Doublons, risques et dépendances

### 5.1 Doublons à ne pas créer

| Tentation | Ce qui existe | Règle |
| :--- | :--- | :--- |
| Un portail `/candidature` | `/attente` et ses quatre sous-écrans | étendre `etat_dossier()` et `PieceManquante`, jamais recalculer à l'écran |
| Une table « engagements » | `contract_acceptances`, immuable et versionnée | une **sorte** de plus, `teacher_religious_commitment`, et c'est tout |
| Un « statut candidat » sur `profiles` | `account_status` (quatre valeurs) | l'étape vit sur la candidature ; `account_status` reste la seule source de l'accès |
| Un second journal | `audit_logs` | chaque transition appelle `log_sensitive_access()`, comme `cloturer_groupe` (`0017:312-342`) |
| Une seconde grille de disponibilités | `weekly_availability`, `ENS-06` | la candidature déclare, `ENS-06` opère |
| Un écran de validation KYC dans le pipeline | `ADM-02`, cloisonné par genre en base | le dossier de candidature **renvoie** vers `ADM-02`, il ne rejoue pas la pièce |
| Un « profil candidat » | `teacher_profiles` | les réponses de candidature ne recopient pas le profil : le profil se remplit à l'activation, une fois |
| `app_config` pour la matrice | référentiels `langues_cours` / `cohortes_age` | une table de référence, pas des clés scalaires |

### 5.2 Risques

| # | Risque | Gravité | Parade |
| :-- | :--- | :--- | :--- |
| R1 | Un import transforme des candidats en comptes actifs ou provisoires | critique | l'import n'écrit **que** des candidatures ; aucune RPC d'import ne touche `profiles` ; scénario SQL qui le prouve |
| R2 | Le rapprochement fusionne deux personnes sur un nom | élevé | rapprochement par **courriel ou téléphone normalisé**, proposé, jamais appliqué sans geste humain (spec §9) |
| R3 | Changer `decider_dossier()` bloque des enseignants déjà en cours de dossier | élevé | les dossiers `pending_kyc` antérieurs gardent l'ancienne règle, ou reçoivent une candidature créée d'office en salle 2 (D1) |
| R4 | Un entretien posé dans `sessions` apparaît dans la Journée, le planning du contrôleur et la présence | élevé | un `session_type` dédié, exclu explicitement de `mes_seances_v`, du contrôle et des vues enseignant (section 6.3) |
| R5 | Données personnelles dans les tableaux, les journaux ou un export | élevé | colonnes masquées en base ; aucune pièce KYC ni numéro complet dans une liste ; la spec §7 le demande déjà |
| R6 | Un rejet « silencieux » parce qu'aucun canal n'existe | moyen | l'écran dit « à prévenir » tant que l'administration n'a pas confirmé avoir prévenu ; aucun état ne prétend qu'un message est parti |
| R7 | Un critère change après l'arrivée de candidatures | moyen | les réponses portent la **version** du questionnaire ; un critère nouveau ne réécrit jamais une décision passée |
| R8 | La matrice passe « confirmé » sur une liste marketing | moyen | « confirmé » exige une date et un responsable de vérification (spec §4.4) |
| R9 | Le genre décide d'un droit à l'écran | élevé | même règle que le KYC : le cloisonnement vit en base (`lib/CLAUDE.md`, « ce qui décide d'un droit se pose en base ») |
| R10 | `0035`-`0037` (portes d'observation) ne sont pas appliquées en production | moyen | toute réutilisation du motif de porte attend leur application (`supabase/migrations/LISEZ-MOI-0035-0037-non-appliquees.md`) |

### 5.3 Dépendances backend (à autoriser, pas à contourner)

1. Tables candidature, type, réponses versionnées, décisions, entretiens ;
   RLS candidat (soi seul) et administration.
2. Extension de `etat_dossier()` et de `PieceManquante` (questionnaire,
   engagement, entretien).
3. Une sorte de contrat `teacher_religious_commitment`.
4. La règle d'activation de `decider_dossier()` (D1), et le contrôle des
   contrats signés (E2).
5. Une RPC de transition par geste, chacune journalisée et motivée, avec le
   contrôle des prérequis **en base**.
6. Une RPC de lot qui rend un résultat **par ligne**, sans transaction
   globale (un échec partiel ne défait pas les réussites, spec §8.2).
7. Une RPC d'import idempotente, clé = référence source.
8. Le référentiel de la matrice de paiement et sa RLS (lecture candidat :
   lignes `confirme` seulement).
9. Une `sessions` d'entretien et ses deux portes (section 6.3).
10. Une RPC d'historique bornée à un dossier.
11. Un canal d'envoi (SMTP ou autre), si l'invitation doit partir de
    l'application (D9).

---

## 6. Modèle proposé, alternatives étudiées

### 6.1 Le moteur générique : trois options

| Option | Ce que c'est | Pour | Contre | Verdict |
| :--- | :--- | :--- | :--- | :--- |
| A. Constructeur de formulaires | types, étapes, champs, critères et transitions entièrement en données | aucun code par type | c'est exactement le « constructeur de formulaires complexe et prématuré » que la spec §0 refuse ; règles éliminatoires impossibles à vérifier en base | écartée |
| B. Pipeline enseignant codé en dur | tables et écrans propres à l'enseignant | simple | la décision 1 de la spec §15 l'interdit ; tout type suivant recopie le moteur | écartée |
| **C. Squelette générique, règles par type** | une candidature porte un **type** ; le type désigne un **jeu d'étapes fermé** et une liste de **contrôles nommés** ; les réponses sont un document versionné par type | un nouveau type = une ligne de référentiel et sa liste de contrôles ; les contrôles restent du SQL vérifiable | chaque nouveau contrôle reste du code serveur | **recommandée** |

Dans l'option C, un **contrôle** est un prédicat nommé, calculé en base comme
`etat_dossier()` l'est déjà : `kyc_valide`, `engagement_accepte`,
`entretien_conclu`, `paiement_compatible`, `profil_unique`,
`aucune_restriction`. Le type « enseignant » en exige six ; un type
« comptable » en exigerait d'autres, et **aucun contrôle d'un type ne
s'applique à un autre** (spec §2.2). Le questionnaire est versionné : une
réponse garde la version à laquelle elle a été donnée (risque R7).

### 6.2 Étape, état, et dimensions séparées

La liste de onze statuts de la spec mélange deux choses : **où** en est la
candidature (l'étape) et **ce qui l'arrête** dans cette étape. Les séparer rend
la matrice de transitions vérifiable.

| Dimension | Valeurs | Porté par |
| :--- | :--- | :--- |
| Étape | `invitation`, `prequalification`, `verifications`, `confirme` | la candidature |
| État dans l'étape | `a_completer`, `en_examen`, `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente` | la candidature, calculé quand c'est possible |
| Issue | `en_cours`, `refusee`, `retiree` | la candidature ; `refusee` et `retiree` sont terminales mais **réouvrables** par geste motivé |
| Pause | drapeau + motif + date de reprise facultative | la candidature, **orthogonal** : une pause ne change pas l'étape |
| KYC | `aucun`, `depose`, `valide`, `refuse` | `kyc_documents`, lu, jamais recopié |
| Paiement | `inconnu`, `compatible`, `incompatible`, `a_verifier` | calculé : réponses × matrice |
| Disponibilité opérationnelle | `disponible`, `indisponible_jusqu_au` | `teacher_profiles`, **après** confirmation |
| Affectation | nombre d'affectations actives | `assignments`, lu |
| Coordonnées financières | `absentes`, `enregistrees` | `payout_methods`, **jamais** exigées avant le premier cours |

Correspondance avec la liste de la spec : « Invitation envoyée » =
`invitation` ; « Informations à compléter » = `a_completer` ;
« Préqualification » = `prequalification/en_examen` ; « Vérifications » =
`verifications/en_examen` ; « Entretien à planifier », « Entretien planifié »,
« Décision finale en attente » = les trois états de `verifications` ;
« Confirmé » = `confirme` ; « Refusé », « Retiré » = l'issue ; « En pause » = le
drapeau.

### 6.3 L'entretien vidéo : deux voies

Contrainte mesurée : `create-room-token` n'accepte qu'un `session_id` ;
`autoriser_jeton_video` (`0033:1643-1781`) exige une ligne `sessions` non close
et l'appartenance de l'appelant à `session_participants` ;
`session_video_route` et `video_token_grants` ont une clé étrangère vers
`sessions`. Un entretien qui réutilise la salle **doit donc être une ligne
`sessions`** — toute autre table serait la refonte LiveKit que la spec interdit.

| Voie | Ce qu'il faut | Pour | Contre |
| :--- | :--- | :--- | :--- |
| **1. Salle Rewayah** | `session_type = 'entretien'` (la contrainte n'admet aujourd'hui que `standard` et `child`, `0001:170`) ; une porte candidat et une porte intervieweur sur le motif d'`entrer_observation` ; une lecture de l'entretien autorisée à un compte `pending_kyc` ; l'exclusion explicite de `mes_seances_v`, du planning contrôleur et de la Journée ; un `teacher_id` qui ne bloque pas deux entretiens simultanés (exclusion de chevauchement, `0005:640-645`) | aucun lien partageable (ADR-005), même salle que les cours, présence et horloge déjà écrites, aucun paquet neuf | une migration réelle, et quatre surfaces à protéger d'une fuite |
| 2. Lien externe | un champ « lien de visio » sur l'entretien, ouvert hors de l'application ; un paquet `url_launcher` | presque rien côté base | contredit l'ADR-005 (« aucun lien partageable ») ; aucun contrôle de qui entre ; l'état « session disponible » ne se mesure plus |

**Recommandation : voie 1.** Elle ne touche ni au service de jetons, ni au
fournisseur, ni à la salle : elle ajoute un type de séance et deux portes. La
voie 2 reste l'issue de secours **affichée** quand la voie 1 n'est pas
disponible (« lien absent ou indisponible : explication et solution de
secours », spec §6), jamais un bouton inopérant.

Deux questions qui ne s'inventent pas : l'entretien est-il **enregistré**
(ADR-002 rend l'audio systématique pour les cours ; un entretien d'adulte n'est
pas un cours) — D8 ; et un intervieweur peut-il être d'un **autre genre** que
le candidat (le KYC l'interdit déjà à la lecture) — D6.

### 6.4 La matrice de paiement

Un référentiel, sur le motif de `langues_cours` : pays (ISO), méthode
(`virement_bancaire`, `mobile_money`), opérateur (Wave, Orange Money, Moov
Money…), type de décaissement, état (`confirme`, `en_verification`,
`indisponible`), date et responsable de la vérification, notes. Le prestataire
est une **colonne de données**, jamais un nom dans le code métier (ADR-007).

- Le candidat déclare des **capacités** (« compte bancaire : oui/non »,
  « opérateurs accessibles »), choisies parmi les seules lignes `confirme` de
  son pays de paiement.
- `paiement_compatible` est vrai si au moins une capacité déclarée **et**
  confirmée par l'administration croise une ligne `confirme`. Une ligne
  `en_verification` ne prouve rien (spec §4.4).
- La préférence bancaire n'est **pas un score** : c'est un critère de tri
  secondaire visible et nommé dans la liste (« à égalité, compte bancaire
  d'abord »), désactivable (spec §4.3).
- Placement : la matrice est de la **finance** au sens du contrat de
  séparation (`ADMIN_FINANCE_CONFIGURATION.md`). Or Finance est un domaine
  inerte. Deux issues, D5.

---

## 7. Import contrôlé des candidatures existantes

Le parcours de la spec §9 (source, aperçu, mappage, doublons, erreurs,
confirmation, import, rapport) tient tel quel, avec quatre précisions tirées du
dépôt et des formulaires.

1. **Deux imports, jamais un.** L'ADR-014 décrit l'import d'enseignants **déjà
   actifs** vers `provisional_active` ; ce lot décrit l'import de
   **candidats**. Le second n'écrit que des candidatures, à l'étape
   `invitation`, et aucune RPC d'import ne touche `profiles`.
2. **Source : un fichier exporté, lu côté client.** L'administration exporte la
   feuille (CSV) ; l'application la lit, propose le mappage, montre l'aperçu,
   puis envoie des lignes **déjà mappées** à une RPC idempotente. Une
   intégration directe à l'API Google demanderait un compte de service et une
   fonction Edge : plus lourd, sans bénéfice pour un import ponctuel.
3. **Clé de rapprochement.** La référence source (identifiant de la feuille +
   onglet + horodatage de la réponse) rend l'import rejouable sans doublon. Le
   rapprochement de personnes se fait par courriel ou téléphone **normalisés**,
   proposé à l'écran, appliqué seulement par un geste.
4. **Ce qu'une ligne importée ne fait jamais** : créer un compte, valider un
   KYC, accepter un engagement au nom de la personne, ou entrer en
   `prequalification` sans les réponses manquantes (section 2).

Le mappage est une **page** (pas une feuille modale, Bible §5.6) ; le rapport
final liste les erreurs ligne par ligne, sans aucune donnée personnelle dans le
journal (le journal porte la référence source, pas le nom).

---

## 8. Matrice de transitions et règles de blocage

Toutes les transitions passent par une RPC qui vérifie la règle **en base**,
exige un motif quand la colonne « Motif » le dit, et journalise l'ancien et le
nouvel état, l'auteur et l'horodatage.

| De | Vers | Qui | Conditions vérifiées en base | Motif |
| :--- | :--- | :--- | :--- | :--- |
| (import ou création admin) | `invitation` | admin | référence source unique | non |
| `invitation` | `prequalification/a_completer` | le candidat, en créant son compte par `/inscription` puis en réclamant sa candidature | courriel ou téléphone rapproché, **confirmé par un geste** | non |
| (inscription publique) | `prequalification/a_completer` | le candidat | rôle enseignant à l'inscription (`creer_profil_inscription`) | non |
| `prequalification/a_completer` | `prequalification/en_examen` | le candidat | questionnaire complet pour la version courante | non |
| `prequalification/en_examen` | `prequalification/a_completer` | admin | — | **oui**, et ce qui manque est nommé au candidat |
| `prequalification/en_examen` | `verifications` | admin | engagement religieux accepté (version courante) | non |
| `verifications/*` | `verifications/entretien_planifie` | admin | entretien daté, intervieweur nommé | non |
| `entretien_planifie` | `entretien_a_planifier` | admin | entretien annulé ou manqué, **état conservé** | **oui** |
| `verifications/entretien_planifie` | `verifications/decision_en_attente` | intervieweur | compte rendu enregistré | non |
| `verifications/decision_en_attente` | `confirme` | admin | les six contrôles de la section 6.1, **tous** vrais ; **active le compte** (D1) | non |
| tout état en cours | `refusee` | admin | — | **oui** (interne) ; le message au candidat est un modèle professionnel distinct |
| tout état en cours | `retiree` | le candidat ou l'admin | — | facultatif |
| tout état | pause activée / levée | admin | ne change pas l'étape | **oui** à l'activation |
| `refusee` / `retiree` | étape d'origine | admin | — | **oui** |
| `confirme` | `confirme` + restriction | admin, ou automatique si un contrôle tombe (KYC révoqué, méthode de paiement passée `indisponible`) | l'enseignant sort de l'affectabilité ; **l'historique reste** | **oui** |

**Blocages durs** (aucun geste ne les contourne, y compris en lot) : entrer en
`confirme` avec un contrôle faux ; confirmer en masse une ligne non éligible ;
importer vers une autre étape qu'`invitation` ; exposer une pièce KYC dans une
liste.

**Ce qui ne rétrograde jamais** : une indisponibilité temporaire (spec §3) ;
une pause ; un changement de critère postérieur à une décision.

---

## 9. Décisions à arbitrer par le directeur

Chaque ligne porte une recommandation. Rien n'est construit sur une ligne non
tranchée.

| # | Question | Recommandation | Conséquence si oui |
| :-- | :--- | :--- | :--- |
| D1 | Pour un enseignant, l'approbation KYC cesse-t-elle d'activer le compte, l'activation devenant l'entrée en « Prêts à être affectés » ? | **Oui.** Sinon la salle 3 n'a aucun sens : l'enseignant serait affectable avant l'entretien | modifie `decider_dossier()` pour le seul rôle `teacher` ; les dossiers `pending_kyc` existants reçoivent une candidature créée d'office en `verifications`, ou gardent l'ancienne règle (à choisir) |
| D2 | « À compléter » et « refusé » deviennent-ils deux états distincts, y compris pour la pièce KYC ? | **Oui** ; ferme la question ouverte de la fiche `ENS-01` | une valeur d'état de plus côté candidature, et un message distinct au candidat |
| D3 | Le premier lot reste-t-il frontend seulement, ou un lot backend est-il autorisé ? | **Autoriser un lot backend borné** à la section 5.3, points 1 à 7 ; sans lui, rien n'est utilisable | sinon : fiches, maquettes et contrat seulement |
| D4 | Où vit le module : troisième fonction de Personnes (atteinte depuis Accueil seulement, choix actuel), ou Personnes reçoit une sous-navigation ? | **Sous-navigation pour Personnes** (Dossiers, Candidatures, Comptes) : trois fonctions sans navigation locale deviennent introuvables | modifie un choix opérateur documenté (`ADMIN_UX_PLACEMENT_AUDIT.md:91-115`) |
| D5 | pawaPay : ADR écrit, et où vit la matrice — Finance (domaine inerte à activer pour cette seule fonction) ou Configuration ? Quels pays vérifier en premier ? Et comment paie-t-on un candidat résidant en Arabie saoudite, où le mobile money africain ne s'applique pas ? | ADR « pawaPay, capacités confirmées pays par pays, aucun nom dans le code métier » ; **Finance > Moyens de paiement**, seule fonction active du domaine ; pays dans l'ordre des candidatures réelles : **Arabie saoudite, Nigeria**, puis Guinée, Sénégal, Côte d'Ivoire | lève ADR-003/007 **pour ce seul référentiel**, pas pour le payout ; sans canal confirmé pour l'Arabie saoudite, environ la moitié du vivier réel ne peut pas entrer en salle 3 |
| D6 | La séparation femmes/hommes s'applique-t-elle aux entretiens et à la lecture des dossiers de candidature, comme au KYC ? | **Oui, en base**, même règle que `read_kyc_documents()` | l'intervieweur est choisi parmi le même genre ; un admin dont le genre est inconnu ne lit rien |
| D7 | Qu'est-ce qu'« évaluation de lecture, tajwid, mémorisation » pour un enseignant ? | Un **constat d'entretien structuré** (niveau observé, riwaya, ijaza présentée) plutôt qu'un référentiel neuf | sinon, un référentiel enseignant entier à concevoir |
| D8 | L'entretien est-il enregistré (audio, comme les cours) ? | **Non par défaut**, annoncé au candidat ; ADR-002 vise la protection des mineurs | une ligne de l'engagement ou de l'invitation à l'entretien |
| D9 | Comment le candidat est-il prévenu ? | Tant qu'aucun SMTP n'est posé : **WhatsApp manuel**, l'application enregistre « prévenu le » ; un canal applicatif plus tard | aucun état ne prétend qu'un message est parti |
| D10 | Le texte de l'engagement religieux : version, langue (français **et** arabe), validation juridique | publier `2026-10` après validation juridique, en deux langues | la sorte `teacher_religious_commitment`, version `2026-10` |
| D11 | Le mot « vivier » | « Prêts à être affectés » à l'écran, `confirme` dans le code ; vivier reste aux élèves | aucune |
| D12 | Les candidats arabophones : le parcours candidat est-il livré en arabe ? | **Oui**, c'est la population des formulaires (section 2) ; le reste de l'application peut attendre | traduction des seules clés du parcours candidat, RTL déjà outillé |
| D13 | Le défaut E2 (activation sans contrat signé) se corrige-t-il tout de suite, hors de ce module ? | **Oui**, c'est un défaut de sécurité du processus actuel | une migration courte, un scénario SQL |

---

## 10. Plan d'écrans et de composants

Codes **proposés**, non inscrits au catalogue tant que les décisions D1 à D5 ne
sont pas prises : le catalogue est le registre de ce qui est décidé.

### 10.1 Côté candidat : trois pas de plus dans `/attente`

| Code proposé | Écran | Route | Réutilise |
| :--- | :--- | :--- | :--- |
| `TUT-00c/d` | Questionnaire de candidature, en cartes (ADR-013), une question par carte, `ChoiceCardGroup` avec « Autre » | `/attente/questionnaire` | coquille de `TUT-00c` ; `etat_dossier()` étendu |
| `TUT-00c/e` | Engagement religieux, pédagogique et professionnel | `/attente/engagement` | **la page de contrat existante**, sorte de plus (`SorteContrat`) |
| `TUT-00c/f` | Mon entretien : date, heure et fuseaux, « Rejoindre la visio » au moment autorisé | `/attente/entretien` | `FenetreSeance`/`PhaseSeance`, `ServiceVideo.acces` |

Le portail `TUT-00b` gagne trois pièces manquantes et deux états
(`a_completer` avec la liste, `refusee` distinct de `a_completer`) ; il ne
montre **jamais** d'autre candidat, ni compteur, ni liste (spec §7).

### 10.2 Côté administration : une fonction de Personnes

| Code proposé | Écran | Route | Réutilise / étend |
| :--- | :--- | :--- | :--- |
| `ADM-20` | Candidatures : recherche, filtres combinables, étapes en `FilterPill` avec compteur, tri, pagination par curseur, sélection multiple | `/admin/personnes/candidatures` | `DataCollection` **étendu** (tri, cases, barre de sélection) ; curseur d'`ADM-04` ; filtres **dans l'URL** |
| `ADM-21` | Dossier de candidature : réponses, contrôles nommés, KYC (lien vers `ADM-02`), entretien, historique, décision | `/admin/personnes/candidatures/:id` | `StatusPill`, `SectionHeader`, `MenuActions` ; historique par RPC bornée |
| `ADM-22` | Aperçu et rapport d'une action groupée | `/admin/personnes/candidatures/lot` | composant neuf `RapportLot` |
| `ADM-23` | Import de candidatures (source, mappage, doublons, confirmation, rapport) | `/admin/personnes/candidatures/import` | `file_picker` existant ; parcours en pages |
| `ADM-24` | Moyens de paiement par pays | selon D5 | motif des référentiels `0043` |

Les « salles » sont des **filtres d'étape** de `ADM-20`, pas un kanban : un
kanban de quatre cents cartes n'est ni dense ni filtrable, et le dépôt n'en a
aucun motif (spec §10 le permet). La vue « Entretiens » est le filtre
`verifications` trié par date d'entretien, avec le CTA visio **dans la ligne**,
séparé du nom qui ouvre `ADM-21` (spec §6).

### 10.3 Composants

| Composant | Statut | Pourquoi |
| :--- | :--- | :--- |
| `DataCollection` | **à étendre** : tri par colonne, sélection multiple, barre de sélection | exigé par `05-regles-responsive.md:58` et Bible §38, absent aujourd'hui |
| `ChampRecherche` | **neuf** | aucune recherche partagée n'existe ; une seule, pas une par écran |
| `RapportLot` | **neuf** | réussites et échecs ligne par ligne ; `LocalFeedback` ne porte qu'un message |
| `HistoriqueDossier` | **neuf** | `TimelineRow` est la journée de l'enseignant, pas un historique |
| `FilterPill`, `MenuFiltre`, `StatusPill`, `EmptyState`, `Skeleton`, `ConfirmDestructive`, `PageShell`, `AppCard` | réutilisés tels quels | — |

Chaque composant neuf entre dans la galerie et dans
`test/widgets/catalogue_galerie_test.dart`, et passe `tool/verifier_jetons.dart`.

---

## 11. Scénarios de la spec §12.2

| Scénario | Comportement retenu | Existe | Manque |
| :--- | :--- | :--- | :--- |
| Candidature complète | `en_examen`, en tête de file par ancienneté | file par ancienneté (`dossiers_en_attente`) | tout le reste |
| Candidature partielle | `a_completer`, la liste de ce qui manque dite au candidat | motif `PieceManquante` | questionnaire |
| Doublon à l'import | proposé, jamais fusionné sans geste | — | RPC d'import, normalisation |
| Candidat qui ne répond pas | reste en `invitation` ou `a_completer` ; filtre « sans activité depuis N jours » ; jamais de refus automatique | — | date de dernière activité |
| KYC absent | contrôle `kyc_valide` faux ; renvoi vers `/attente/piece` | `PieceManquante.pieceIdentite` | — |
| KYC en attente | idem, état « en examen » ; renvoi admin vers `ADM-02` | `ADM-02` | — |
| KYC refusé | contrôle faux, motif rendu au candidat | `motif_refus` | distinction « à corriger » (D2) |
| KYC expiré | **n'existe pas** : aucune date de validité n'est enregistrée, et la pièce est purgée à 90 jours | — | décision : la validité se constate-t-elle et s'enregistre-t-elle ? |
| Engagement non accepté | bloque l'entrée en `verifications` | `contract_acceptances` | la sorte |
| Sans compte bancaire, mobile money compatible | `paiement_compatible` vrai | — | matrice |
| Compte bancaire non compatible avec le pays | faux pour cette méthode, vrai si une autre l'est | — | matrice |
| Aucune méthode confirmée | bloque `confirme` ; visible en filtre | — | matrice |
| Entretien à planifier, annulé, manqué, en cours, terminé | états de la section 6.2 ; « manqué » et « annulé » gardent la trace et proposent de reprogrammer | `PhaseSeance` | type de séance, portes |
| Visio sans lien valide | phrase et solution de secours à la place du bouton | règle « un bouton qui ne peut pas aboutir n'est pas rendu » | — |
| Décision positive avec un prérequis manquant | **refusée par la base**, le contrôle manquant nommé | — | RPC de confirmation |
| Confirmé mais indisponible | `confirme` + `indisponible_jusqu_au` ; hors des quatre RPC d'affectation | — | colonne et filtre dans les quatre RPC |
| Profil suspendu après confirmation | `disabled` ; sort de l'affectabilité ; historique conservé | portail `suspendu` | RPC de suspension (aucune n'existe) |
| Réactivation après résolution | geste motivé, contrôles revérifiés | — | RPC |
| Affectation déjà occupée / conflit | inchangé : plafond `assignments_cap`, motif hors disponibilité (ADR-021) | oui | — |
| Critère changé après coup | version du questionnaire ; aucune décision passée réécrite | — | versionnage |
| Matrice modifiée | une ligne passée `indisponible` lève une **alerte** sur les confirmés concernés, sans les rétrograder seule | — | vue d'alerte |
| Action groupée partiellement échouée | rapport par ligne ; les réussites restent | — | RPC de lot, `RapportLot` |
| Dossier ou document sans permission | refus en base, état « hors portée » distinct d'« absent » | motif d'`ADM-02` (`non_visible`) | RLS candidature |
| Desktop, tablette, mobile | tableau dense / cartes, selon `DataCollection` | oui | — |
| Chargement, vide, erreur, hors ligne | `Skeleton`, `EmptyState`, `OfflineBanner` | oui | — |

**Scénarios ajoutés par cette revue**

| Scénario | Comportement retenu |
| :--- | :--- |
| Un candidat importé crée lui-même un compte avec un autre courriel | aucune fusion automatique ; rapprochement proposé par téléphone, confirmé par l'admin |
| Un enseignant déjà actif (ADR-014) figure aussi dans la feuille de candidatures | l'import le signale comme « déjà enseignant » et ne crée rien |
| Un contrôleur postule comme enseignant | refus : ADR-011 interdit d'être les deux |
| Un candidat retire sa candidature pendant un entretien planifié | l'entretien est annulé, la trace reste, l'intervieweur le voit |
| Le texte de l'engagement change de version | les candidats en cours la ré-acceptent avant `confirme` ; les confirmés gardent la leur |
| Une confirmation est tentée par un admin dont le genre est inconnu | refus en base, comme `read_kyc_documents()` (D6) |
| Le fuseau du candidat est inconnu | l'entretien ne se planifie pas ; l'heure ne s'affiche jamais dans un fuseau deviné |

---

## 12. Plan de recette et de non-régression

**Base (sur Postgres nu, comme la CI)** — un fichier
`supabase/tests/scenarios_candidatures.sql`, ajouté **au workflow CI dans le
même lot** (`docs/PROGRESS.md`, ligne E : un fichier de scénarios ne s'ajoute
pas tout seul), joué avant `scenarios_adm04.sql` qui reste dernier :

- impossible d'entrer en `confirme` avec un des six contrôles faux (un
  contrôle par cas) ;
- l'absence de compte bancaire ne bloque pas si une méthode mobile money
  confirmée croise la déclaration ;
- une ligne `en_verification` de la matrice ne rend jamais `paiement_compatible` vrai ;
- l'import n'écrit aucune ligne de `profiles`, ne touche pas `kyc_documents`
  ni `contract_acceptances`, et un second import identique n'ajoute rien ;
- un candidat ne lit que sa candidature (RLS) ; un candidat ne lit aucune
  ligne de la matrice non confirmée ;
- un lot de dix confirmations dont trois inéligibles rend sept réussites, trois
  échecs motivés, et laisse les trois dossiers inchangés ;
- chaque transition laisse une entrée `audit_logs`, et `verifier_chaine_audit()`
  reste vert ;
- `decider_dossier()` n'active plus un enseignant (si D1), et refuse sans
  contrat signé (D13).

**Flutter** : tests de widget par écran neuf, dans les cinq états, en RTL et à
200 %, au clavier ; test du portail `TUT-00b` étendu ; tests des trois
composants neufs dans la galerie.

**Non-régression** : les sept échecs de test déjà connus restent les seuls
(`docs/HANDOFF.md`, mesure du 19 septembre 2026 : 684/691) ; les parcours
tuteur de `/inscription` et `/attente` ne changent pas ; `ADM-02`, `ADM-05`,
`ADM-08`, `ADM-09`, `ENS-06` gardent leurs tests verts ; `dart analyze
--fatal-infos` propre ; `tool/verifier_jetons.dart` sans violation nouvelle.

---

## 13. Ce qui peut avancer sans attendre

Seulement ce qui ne préjuge d'aucune décision de la section 9 :

1. **Fait par ce lot** : la spécification versionnée, cette revue, les
   décisions inscrites au registre (`decisions.md`, questions 36 à 48).
2. **Après D1 à D5** : les fiches `TUT-00c/d-f` et `ADM-20` à `ADM-24` au
   catalogue, **avant** tout fichier `.dart` ; les maquettes desktop, tablette,
   mobile, clair et sombre.
3. **Après D3** : le lot backend borné, avec ses scénarios SQL, puis les écrans.

Rien d'autre ne commence, et en particulier aucun écran branché sur des données
fictives.
