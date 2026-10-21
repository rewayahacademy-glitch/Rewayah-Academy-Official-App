# Candidatures et viviers de recrutement : revue critique avant tout code

**Statut :** revue bloquante exigée par la section 12 de la spécification
(`REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md`). **Aucune ligne de code n'est
écrite par ce lot.** Aucun point ne se construit avant la réponse du directeur aux
questions de la section 9.

**Base mesurée :** la pointe de la pile de PR du 21/10/2026
(`claude/youthful-davinci-raugwe`, commit `9cf88561`), et non `main`, qui a plus de
2 500 commits de retard. Une première version de cette revue, écrite contre `main`
le même jour, est retirée : la section 14 dit ce qu'elle affirmait de faux.

**Méthode :** six cartographies indépendantes de la pointe (gouvernance,
recrutement, finance, interface d'administration, visio et notifications, décisions
produit), une comparaison ligne à ligne avec la première version, une lecture des
formulaires Drive limitée à leur structure et à des comptes agrégés (section 2),
puis une vérification adverse de chaque référence (292 confirmées, 38 corrigées) et
une critique de complétude contre la spécification (20 manques comblés). Chaque
fait porte sa preuve selon les trois premiers niveaux de la taxonomie de
`docs/current/00_LIRE_D_ABORD.md:23` : **[S]** spécifié seulement, **[C]** présent
dans le code, **[T]** testé localement.

Abréviations : `M/` = `supabase/migrations/`, `T/` = `supabase/tests/`,
`C/` = `docs/current/`, `DM` =
`C/sources-directeur-2026-10/REWAYAH_DOSSIER_MAITRE_SPECS_PRODUIT_COMPLET_2026-10-14.md`.

---

## 0. Le verdict en une page

La spécification arrive sur un terrain **à moitié construit**. Le recrutement
existe déjà par sa porte d'entrée (l'invitation) et par sa porte de sortie (la
validation du dossier, la signature, le code de conduite, les prérequis de
l'enseignant). Ce qui manque, c'est tout l'entre-deux : la candidature elle-même,
la préqualification, l'entretien, la compatibilité de paiement, et une décision
d'admission distincte de la pièce d'identité. Huit constats commandent la suite.

1. **Le recrutement n'est pas à créer, il est à prolonger.** Depuis le 17/10, un
   enseignant n'entre que par invitation (arbitrage A-07) : code lié à un
   courriel, émis par la direction, consommé une seule fois à l'inscription
   [C][T] (`M/20261016100300_contrats_invitations_enseignant.sql`,
   `M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql`). L'état
   « Invitation envoyée » de la spec existe donc déjà, avec ses écrans
   (`lib/features/admin_invitations/`, `lib/features/recrutement/`). Le module
   doit s'y brancher, pas le dupliquer.

2. **Approuver la pièce d'identité vaut encore admission.** `decider_dossier()`
   passe le compte de `pending_kyc` à `active` dès l'approbation
   (`M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:47-50`) ; un
   refus fait passer à `disabled` un enseignant déjà `active` ou
   `provisional_active` sans autre pièce approuvée (`:51-60`), tandis qu'un
   candidat encore `pending_kyc` refusé garde ce statut et peut redéposer. La
   garde `M/0089_teacher_contract_activation_guard.sql` empêche bien d'activer
   sans contrat ni accusé signés [C][T] ; mais aucun entretien, aucune évaluation,
   aucun engagement, aucun contrôle de paiement ne s'intercale. **C'est le conflit
   central** avec la « salle 3 » (`CAND-Q01`). Circonstance favorable : la
   décision est aujourd'hui **fermée en production côté Flutter** (AD-M3-PROD,
   `lib/features/admin_dossiers/revue_dossier.dart:33-36`). Personne n'est donc
   admis par l'application en ce moment : c'est le bon moment pour séparer les
   deux décisions.

3. **« Frontend seul » est faisable, mais rien ne sera utilisable.** Le dépôt a
   déjà le motif qui respecte la spec §1.2 : un port, un pont de démonstration, et
   `CapaciteIndisponible` en production (« Disponible au branchement serveur »,
   `C/CATALOGUE_ECRANS_DIRECTION.md:9-11`). Mais §7 (un candidat ne voit que sa
   candidature) et §13 (la salle 3 se refuse) ne tiennent qu'en base : « une UI
   cachée ne remplace jamais une policy » (`C/02_ARCHITECTURE_ET_SECURITE.md:19`).
   Depuis le 17/10, Claude fait aussi le backend (`CLAUDE.md:30`) ; une migration
   distante exige inventaire, sauvegarde et feu vert explicite (`CLAUDE.md:45-46`),
   et seule la base de test est visée, le garde-fou refusant toute écriture sur la
   production (`docs/orchestration/PASSATION-2026-10-17.md:26`,
   `.claude/hooks/garde.py:715-716`). La spec, plus récente, interdit le backend
   sans autorisation : il faut cette autorisation (`CAND-Q02`).

4. **Les 418 candidats des formulaires n'ont ni compte ni invitation.** La
   candidature commence donc **avant** l'invitation : une ligne importée,
   préexaminée par la direction sur ses réponses, puis invitée. Or l'invitation
   exige un courriel, et 32 lignes n'en ont pas (section 2). Et après cet import
   ponctuel, aucune porte n'existe pour une nouvelle candidature (`CAND-Q03`,
   `CAND-Q17`).

5. **L'entretien en visio ne peut pas réutiliser la salle tel quel.** Le jeton
   vidéo exige un compte `active` ou `provisional_active`
   (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`),
   donc un candidat `pending_kyc` n'entre pas. Et une ligne `sessions` qui servirait
   d'entretien déclencherait la paie à la clôture
   (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`), la clôture
   automatique, et l'exclusion de chevauchement. Deux voies, section 6.3
   (`CAND-Q06`).

6. **Le paiement est un référentiel à créer, pas un prestataire à brancher.** Le
   directeur indique le compte marchand pawaPay « confirmé et utilisable » (spec
   §4.4) ; cette revue ne rouvre pas sa validation générale. Mais
   `docs/current/` ne choisit aucun prestataire de versement
   (`C/07_MEMOIRE_PEDAGOGIE_FINANCE.md:20`, `:38`), et le dossier maître dit de
   pawaPay « envisagé » (`DM:7497`) et « candidat par corridor » (`DM:7941`), et
   constate « aucune activation Stripe, PayPal, Verto ou pawaPay » (`DM:7953`).
   L'indication du directeur doit donc être versée comme décision datée, et la
   couverture vérifiée corridor par corridor. Le client a déjà les types
   (`CorridorPayout` et le port `PortCapacitePayout`,
   `lib/core/capacites/port_capacite_payout.dart:17-48` ; l'énumération
   `CapacitePayout`, `lib/core/comptable/statuts_comptable.dart:141-156`) ; il
   leur manque une source serveur (`CPT-BR-10`). La liste des pays proposés ne
   contient ni l'Arabie saoudite ni le Yémen, alors qu'environ la moitié des
   candidats y indiquent leur numéro (`CAND-Q05`).

7. **Le vocabulaire de la spec entre en collision avec des mots déjà employés ou
   interdits.** « Vivier » désigne dans le code la réserve d'élèves d'une offre
   horaire (`M/0043`, `lib/core/offres/offre_horaire.dart:133`) ; ce n'est ni un
   mot affiché ni un mot de `mots-rewayah`, et le dossier maître parle déjà d'un
   « vivier d'enseignants » (`DM:7776`). « Salle » est la salle de cours unique
   `/salle` (`CLAUDE.md:91`). « Engagement » sert, dans les textes de l'app, à
   l'engagement envers une classe. « Je certifie » heurte la décision M-10.
   « Admin » ne s'écrit pas à l'écran. `CAND-Q12`.

8. **Ce que la spec a raison d'exiger et qui est déjà tenu** : polices DM Sans et
   Plus Jakarta Sans (M-15, `lib/core/theme/app_typography.dart:33-36`), thème
   sombre complet, cloisonnement par genre de la lecture des pièces en base,
   import sans création de compte, trace chaînée des décisions.

---

## 1. Sources lues

Gouvernance : `CLAUDE.md`, `AGENTS.md`, `C/00_LIRE_D_ABORD.md`, `C/08` (§1 et
§5 bis), `C/04`, `C/06`, `C/DESIGN-GOV-2026-09-26.md`,
`C/DECISION-ENTREE-2026-10-17.md`, `C/REVUE-DIRECTEUR-2026-10.md`,
`C/REGISTRE-RECONCILIATION-2026-10-14.md`, `C/marque/REGISTRE-DECISIONS-MARQUE.md`,
`docs/orchestration/PASSATION-2026-10-17.md`, compétences `mots-rewayah` et
`programme-rewayah`. Décisions : toutes les `C/DECISION-*.md`, le dossier maître
du 14/10, `C/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md`. Finance :
`C/DECISION-TARIFS-2026-10-18.md`, `C/tarifs-2026-10-18.json`, `C/07`,
`C/CATALOGUE_ECRANS_COMPTABLE.md`, `C/ENS-PAYS-1_BR.md`. Interface :
`C/03_DESIGN_SYSTEM_ET_UX.md`, `C/AD-X_DECOUPAGE.md`, `C/UX_REVIEW_FILTRES-1.md`,
`C/recherche/RECH_BACK_6_SECURITY_PERFORMANCE.md`, `lib/core/widgets/`. Puis le
code et les migrations cités ligne à ligne.

`docs/archive/` n'est cité que pour dire qu'une règle a été remplacée
(`CLAUDE.md:32-34`).

---

## 2. Ce que disent les formulaires et leurs réponses (Drive)

**Règle suivie.** Lecture seule, et seuls des **comptes agrégés** sont reportés :
aucun nom, aucun numéro, aucune adresse, aucune réponse libre citée. Les fichiers
temporaires du calcul ont été supprimés. Les pays de moins de trois occurrences
sont regroupés.

### 2.1 Les sources

| Source | Forme | Lignes réelles | Période |
| :--- | :--- | :-: | :--- |
| A1 : questionnaire « تعليم القرآن عن بعد », premier lien | Google Forms en arabe, 14 questions | 279 | 18 au 21/10/2026 |
| A2 : même questionnaire, second lien | identique | 161 | même période |
| B : formulaire « Enseignant Rewayah Academy », onglet « Enseignants (Réponses) » | Google Forms en français, 17 questions | 11 | 07/2025 à 04/2026 |

A1 et A2 ne sont pas un formulaire papier et un formulaire en ligne, malgré leur
titre : ce sont deux liens du même questionnaire, diffusés à deux publics (A1 : 68 %
d'indicatifs saoudiens, arabe majoritaire ; A2 : 79 % d'indicatifs nigérians,
haoussa majoritaire). Le questionnaire a été modifié en cours de collecte (question
courriel ajoutée, libellés de genre changés).

**451 lignes, 418 personnes distinctes** une fois les doublons rapprochés par
téléphone ou courriel normalisés : c'est la population « quelque 400 candidatures »
de la spec §9. Aucun recoupement entre A1, A2 et B.

**B est déjà dans le périmètre de l'import du 12/10.** La décision
`C/DECISION-IMMATRICULATION-2026-10-12.md:68-70` importe l'onglet « Enseignants
(Réponses) » comme pré-inscrits enseignants [C][T]. A1 et A2, créés le 18/10, n'y
sont pas. Section 7.

### 2.2 Ce que les formulaires demandent, et ce qu'ils ne demandent pas

| Donnée de préqualification (spec §3, §4.2) | A | B |
| :--- | :-: | :-: |
| Identité, contact | nom, WhatsApp, courriel (ajouté en cours de route : 31 lignes sans, dont 28 antérieures à l'ajout de la question) | prénom, nom, courriel, téléphone |
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
| Consentement au contact | WhatsApp, 100 % | non demandé |
| Pièce d'identité | non | photo, sous forme de lien Drive |

**Conséquence directe** : aucune des 418 personnes ne peut être admissible en
salle 2 à partir de ses seules réponses. Pays de versement, moyens de réception,
publics, fuseau et engagement manquent partout. L'import sert à **préexaminer et
inviter**, pas à préqualifier.

### 2.3 Les chiffres qui changent la spec

**Pays (déduits de l'indicatif, donc indicatifs) :** Arabie saoudite environ 210,
Nigeria 131 (une dizaine de plus au format national nigérian), Yémen 12, Tchad 7,
Sénégal 5, Niger 5, Guinée 3 dans A (et 6 numéros de B au format guinéen
probable), Burkina Faso 3, Côte d'Ivoire 3 (dont 1 dans B), Kenya 3 ; une
vingtaine d'autres pays à moins de trois chacun.

- La spec cite le Nigeria, la Côte d'Ivoire et le Sénégal. **Le premier groupe de
  candidats indique l'Arabie saoudite**, où le mobile money africain ne s'applique
  pas, et la Côte d'Ivoire n'en compte que trois. La liste `paysProposes` du profil
  enseignant (19 pays, `lib/features/profil_enseignant/declaration_choix.dart:40-60`)
  ne contient ni l'Arabie saoudite ni le Yémen.
- La **Guinée**, dont la couverture de versement reste non confirmée (`DM:7941`),
  est le pays des enseignants déjà en place (B, poular majoritaire), pas celui des
  nouveaux candidats.

**Genre :** 351 hommes et 89 femmes dans A ; aucune femme dans B. Les classes de
femmes exigent une enseignante du même genre (`M/0082_teachers_for_class.sql:60-73`)
[C] : ces 89 candidates sont la ressource rare.

**Langues d'explication (choix multiple, A) :** arabe 400, anglais 240, français
55, ourdou 26, autres sous 15. Le référentiel `langues_cours` ne compte que poular,
français et anglais (`M/0043_offres_horaires_et_intentions.sql:67-79`), alors que
l'offre du 18/10 élargit les langues à l'arabe et à d'autres
(`C/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md:21,33`). Ces chiffres
nourrissent cette tension ; ils ne la tranchent pas.

**Mémorisation (A) :** Coran entier 263, ijaza de lecture et d'enseignement 84,
plus de dix juz' 50, moins de dix juz' 15, non mémorisé mais bonne lecture 28.
**Ijaza présentable à l'entretien :** oui 334, « non, mais prêt à un test de
niveau » 89, non 17.

**Disponibilité (A) :** début immédiat 375, le mois prochain 53 ; 3 à 5 heures par
semaine 154, 6 à 10 heures 130, plus de 10 heures 99, moins de 3 heures 57. Les
créneaux de A sont en heure de La Mecque (UTC+3), ceux de B en UTC.

### 2.4 Qualité des données, pour l'import

| Constat | Ampleur | Règle d'import qui en découle |
| :--- | :--- | :--- |
| Doublons (renvois, corrections) | 27 groupes, dont 14 aux réponses **différentes** | proposer la ligne la plus récente, garder les autres comme historique de la référence source ; jamais de fusion silencieuse (`CAND-Q16`) |
| Nom différent dans un groupe relié par téléphone ou courriel | 5 groupes (écriture arabe ou latine, élément ajouté, contact partagé) | le rapprochement s'appuie sur le contact, et l'écran montre les deux noms |
| Téléphones sans indicatif ou mal formés | 55 sur 451, et 71 autres dont l'indicatif n'a ni `+` ni `00` ; certaines cellules stockées comme nombres | normaliser sans deviner : un numéro sans indicatif reste « à confirmer » |
| Courriels absents ou suspects | 32 absents sur 451 lignes (31 dans A, 1 dans B), quelques fautes de domaine, une adresse jetable, un numéro saisi à la place | un courriel invalide n'est ni une clé de rapprochement ni une adresse d'invitation |
| « Autre » sans précision | 46 langues maternelles, 72 langues d'explication | importé comme « autre, à préciser », jamais comme une langue |
| Choix multiples contenant une virgule, en-têtes avec apostrophe ou espace en tête | plusieurs colonnes | découper selon la liste d'options, et faire le mappage sur l'en-tête normalisé |
| Variantes d'un même libellé (deux graphies du genre, « Hasf » pour « Hafs ») | deux colonnes | table de correspondance des libellés dans l'écran de mappage |
| Réponses contradictoires (« disponible à toute heure » avec des créneaux précis ; « pas après 20 h » avec des créneaux de nuit) | 24 lignes | signalées en avertissement, importées telles quelles |
| Liens Drive vers des photos d'identité (B) | 4 | **jamais importés** : la pièce passe par le dépôt de l'application, cloisonné par genre |

---

## 3. Cartographie de l'existant à la pointe

### 3.1 Le parcours d'entrée de l'enseignant, tel qu'il est

| Pas | Ce qui existe | Preuve |
| :--- | :--- | :--- |
| 1. Invitation | `inviter_enseignant(p_email)`, réservé à la direction active ; code de 12 signes lié au courriel ; durée `recrutement.invitation_duree_jours` (14 jours par défaut) ; refus `email_invalide`, `compte_existant`, `deja_invite` ; révocation ; journalisation. **Aucun envoi** : le code s'affiche à la direction, qui le transmet | [C][T] `M/20261016100300_contrats_invitations_enseignant.sql:111-161`, `lib/features/admin_invitations/invitations_page.dart:128-129`, `T/scenarios_contrats_invitations.sql` |
| 2. Inscription | `creer_profil_inscription('teacher')` est refusé ; seule porte : `inscrire_enseignant_invite`, qui verrouille l'invitation, crée le profil en `pending_kyc` avec une fiche `teacher_profiles` vide, marque l'invitation utilisée | [C][T] `M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`, `T/scenarios_af_l1_11_inscription_enseignant_invitation.sql` |
| 3. Portail d'attente | `/attente`, confiné par le routeur ; état lu dans `etat_dossier()` (statut, pièce, contrat, accusé, usage) ; `EtapeDossier` à cinq valeurs (`incomplet`, `enVerification`, `accesEnPreparation`, `refuse`, `suspendu`) | [C][T] `lib/core/router/redirection.dart:149-174`, `M/20261017180000_l5_01_usage_inscription.sql:115-125`, `lib/core/dossier/etat_dossier.dart:217-245` |
| 4. Accords | une seule page `/attente/accords`, une case par texte, « Suivant » inactif tant qu'il en manque une : texte d'information, contrat `teacher_nda` (version `2026-10-jur`, signature par nom tapé et empreinte), article 9 | [C][T] `lib/features/dossier/accords_page.dart:55-97`, `C/DECISION-ENTREE-2026-10-17.md:28-33`, `M/0086_signature_contrat_versionnee.sql`, `M/0092_publish_teacher_contract_2026_10_jur.sql:43` |
| 5. Pièce d'identité | dépôt vers le coffre R2 par fonction Edge, 8 Mo | [C] `supabase/functions/piece-identite-depot/index.ts`, `lib/core/dossier/service_dossier.dart:105` |
| 6. Revue et décision | ADM-02 : lecture cloisonnée par genre (exception super-admin journalisée), une seule décision par pièce, motif obligatoire au refus ; approbation : `active` ; refus : `disabled` pour un enseignant `active` ou `provisional_active` sans autre pièce approuvée, `pending_kyc` conservé pour un candidat (étape `refuse`, pièce à redéposer). **Décision fermée en production côté Flutter** (AD-M3-PROD) | [C][T] `M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:21-65`, `M/0088_kyc_super_admin_gender_exception.sql`, `lib/core/dossier/etat_dossier.dart:136-138`, `lib/features/admin_dossiers/revue_dossier.dart:33-36` |
| 7. Garde d'activation | aucune activation sans `teacher_nda` et `recording_and_control_notice` signés aux versions requises ; le code de conduite n'y figure pas | [C][T] `M/0089_teacher_contract_activation_guard.sql:24-82`, `T/scenarios_etape3.sql:862-892`, `M/20261018160000_pe_protection_enfants.sql:19-22` |
| 8. Prérequis de travail | photo, langues, fuseau, disponibilités, calculés en base | [C][T] `M/20261016100500_contrats_travail_prerequis.sql:49-74`, `T/scenarios_contrats_seance.sql` |
| 9. Code de conduite | sorte `teacher_conduct_code`, version `2026-10-19`, accepté depuis le profil par un enseignant **actif** | [C][T] `M/20261019100000_pe_code_conduite_v2.sql:16-20`, `M/20261018160000_pe_protection_enfants.sql:363-374` |
| 10. Affectation à une classe | prédicat commun : statut valide, `access_until`, KYC approuvé ; `tc_verifier_affectation_enseignant` ajoute langue, genre de la classe, plafond hebdomadaire | [C][T] `M/0082_teachers_for_class.sql:54-77` |

Ce que le parcours **ne contient pas** : préqualification, questionnaire,
évaluation de l'enseignant, entretien, engagement religieux, compatibilité de
paiement, décision finale distincte de la pièce, refus définitif distinct d'une
pièce à corriger, pause, retrait, réouverture.
`lib/features/demo/recrutement_demo.dart` n'est qu'une démonstration
d'invitations et de signatures, avec des données fictives jamais envoyées au
serveur (`:1-4`).

### 3.2 Défauts trouvés en passant, hors du périmètre de ce module

Ils comptent parce que « prêt à être affecté » n'a pas aujourd'hui de chemin
serveur fiable. Aucun n'est corrigé ici (`CAND-Q15`). Le correctif proposé pour
chacun, avec sa recette, sa reprise et ce que le directeur doit trancher, est dans
`CORRECTIFS_HORS_MODULE_PROPOSES.md`.

- **Langue de l'enseignant : nom contre code.** Le client enregistre le **nom**
  d'une langue (« Français »), jamais son code
  (`lib/features/profil_enseignant/declaration_choix.dart:201-206`), alors que
  l'affectation compare le code de la classe (`francais`) à ce tableau
  (`M/0082_teachers_for_class.sql:64`, codes en `M/0043:75-78`). Une langue choisie
  dans l'app ne correspond donc à aucun code, et une classe dont la langue est
  renseignée refuse l'enseignant [C].
- `creer_groupe` à huit arguments, seul chemin vivant pour poser un enseignant sur
  une classe, ne vérifie que le rôle, la suppression et `account_status` : ni KYC,
  ni langue, ni genre (`M/0045_disambiguate_creer_groupe_overloads.sql:24-32`) [C].
- `affecter_enseignant_classe` est révoquée
  (`M/20261017120600_af_l3_06_rpc_uniques.sql:19-20`), et sa remplaçante
  `affecter_enseignant_classe_c11bis` n'affecte jamais : sur une classe en attente
  d'enseignant, elle lève toujours « compatibilite enseignant non verifiable »
  (`M/0079_c11bis_admin_wrappers.sql:126-129`) ; elle rend seulement
  `deja_affecte` si la classe a déjà un enseignant (`:119-121`) [C].
- Le franc guinéen compte zéro décimale côté client
  (`lib/core/finance/format_montant.dart:37`) mais pas côté serveur
  (`M/20261012120101_x2_17_treasury_triggers.sql:142`) [C].
- Le code de conduite n'est pas exigé par la garde d'activation `0089`.
- `provisional_active` n'est posé par aucune RPC du parcours enseignant ; la
  colonne `kyc_completion_deadline` de l'ancien ADR-014 n'existe pas.
- La CI ne cite qu'une liste fixe de quinze fichiers de scénarios (sur 109), et
  son job SQL `migrate-check` ne tourne que pour une PR vers `main` ou vers la
  branche `ccr-1b1bfa0b-m1kvkk`, ou sur lancement manuel
  (`.github/workflows/ci.yml:8-17`). Les scénarios de ce domaine (`af_l1_11`,
  `af_l1_05`, `contrats_invitations`, `pe_*`, `imm_*`) n'y sont pas.

### 3.3 Compétences de l'enseignant : ce que la base sait dire

| Donnée de la spec | État |
| :--- | :--- |
| Langues | `teacher_profiles.languages text[]`, texte libre : le client propose les noms de `langues_cours` (trois langues) et « Autre », et enregistre le nom, jamais le code (défaut de 3.2) [C] |
| Pays | `teacher_profiles.country`, texte libre : le nom d'un des 19 pays proposés, ou le texte saisi dans « Autre » (`C/ENS-PAYS-1_BR.md:9`) ; destiné à l'affichage public sur la carte de l'enseignant (`C/ENS-PAYS-1_BR.md:3`) [C][S] |
| Fuseau | `timezone_iana` [C] |
| Genre | `profiles.gender`, colonne privilégiée réservée à la direction (`M/20261017100700_af_l1_07_genre_colonne_privilegiee.sql:27`) [C] |
| Disponibilités | `weekly_availability`, déclarées par un enseignant actif [C] |
| Photo, titre Sayyid ou Sayyida | `M/0030_tc_socle.sql:180-183` [C] |
| Mémorisation, tajwid, ijaza, riwaya, expérience, publics, pays de versement, pays d'origine | **absents** |

### 3.4 Interface d'administration

| Besoin de la spec | Ce qui existe | Écart |
| :--- | :--- | :--- |
| Placement | domaine **Personnes**, six onglets : Dossiers à valider, Comptes, Invitations, Reprises, Importer, Suppressions (`lib/core/admin/admin_domaine.dart:266-293`) ; huit domaines au plus (`lib/core/widgets/admin_shell.dart:90-94`) | un septième onglet, ou l'onglet Invitations élargi (`CAND-Q04`) |
| Liste dense | `DataCollection<T>`, rendu paresseux, `piedDePage` pour charger la suite (`lib/core/widgets/data_collection.dart:100-188`) | **pas de tri par colonne**, pas de multisélection native |
| Recherche | `ChampRecherche` (`lib/core/widgets/champ_recherche.dart:20`) ; règles de `/recherche` : non-énumération, quotas (`C/recherche/RECH_BACK_6_SECURITY_PERFORMANCE.md`) | nom partiel normalisé (arabe et latin) ; identifiant de candidature exact (`CAND-` et un numéro, distinct du matricule RA, jamais réattribué) ; courriel et téléphone exacts seulement, le téléphone réservé à la capacité `candidatures.contact` et journalisé ; recherche au serveur dans la portée de genre ; aucun moteur « Candidatures » dans `/recherche` sans décision |
| Filtres | `FilterPill`, `RangeeFiltres` (trois puces puis « Plus »), `MenuFiltre<T>` à une valeur par axe | onze axes de filtre (spec §8.1) sur trois puces visibles : hiérarchiser |
| Axes et sources | - | type, étape, état, issue, pause, responsable (candidature) ; pays de résidence, langues d'explication, niveau de mémorisation, heures par semaine, date de début (réponses) ; pièce (lue dans `kyc_documents`) ; paiement (`inconnu`, `compatible`, `incompatible`, `a_verifier`) ; entretien (état, date) ; date de réception et de dernière activité. Filtrage, tri, pagination et compteurs des puces au serveur, dans la portée de genre |
| Filtres dans l'adresse | au cas par cas (`?filtre=echus` sur Comptes) ; le dossier s'ouvre par `extra`, jamais par l'URL, et l'identifiant de personne n'entre jamais dans l'URL de l'Espace de traitement (invariant ADM-18, `C/AD-X_DECOUPAGE.md:117`, `:256`) | les raccourcis d'Accueil vers un filtre d'étape sont possibles ; la candidature s'ouvre par `extra` |
| Filtres enregistrés | aucune capacité équivalente à la pointe | non construits : la spec §8.1 les conditionne à une capacité existante |
| Pagination | par page avec total (Regroupements, testé à 10 000 lignes, `test/features/admin_regroupements/echelle_listes_test.dart`) ou par curseur (Bibliothèque CAP29-A) | réutilisable |
| Tri | `MenuFiltre<TriFile>` côté client (`lib/features/admin_traitement/traitement_page.dart:176-190`) | à porter au serveur pour 400 lignes et plus |
| Actions groupées | **précédent d'interface dans le Comptable** (CPT-02) : case par ligne via une colonne `rendu`, `BarreSelection` annoncée au lecteur d'écran, contrat client d'un contrôle préalable qui rendrait les éligibles et les **exclus avec leur raison**, clé d'idempotence, suivi ligne par ligne, issue inconnue dite honnêtement (`lib/features/comptable/paiements/`). **Aucune source serveur** : `PortPayout` n'est servi que par la démonstration (`lib/core/capacites/port_payout.dart:265`, CPT-BR-02) | motif d'interface à promouvoir en composant partagé, jamais à recopier (DESIGN-GOV : composants jamais forkés) ; RPC de lot entièrement à écrire |
| Historique d'un dossier | `journal_audit()` ne filtre pas par ligne ; précédent par objet : `historique_classe(uuid)` (`M/20261016100100_contrats_fusion_classes.sql:227`) | une RPC `historique_candidature` sur ce modèle (section 5.3) |
| Modale | `showDialog` interdit hors deux fichiers (`tool/verifier_jetons.dart:306-316`) ; `AppBottomSheet.ouvrir` ; `ConfirmDestructive` sans champ motif | l'aperçu d'un lot et le mappage d'import sont des pages |
| CTA d'entretien sur chaque ligne | toute la carte est cliquable (`C/DECISION-ENTREE-2026-10-17.md:17`), un seul bouton plein par écran (K-56, `C/REVUE-DIRECTEUR-2026-10.md`), `ctaSeance` existe pour les états de séance | le CTA visio devient un lien secondaire de la ligne, pas un bouton plein (`CAND-Q14`) |

### 3.5 Import

L'import des inscriptions du 12/10 existe et sert de modèle [C][T] : analyse du
CSV **côté serveur**, essai à blanc avec motifs de rejet ligne par ligne,
confirmation idempotente, journalisation
(`M/20261012184501_imm_accueil_dry_run.sql`,
`M/20261012185025_imm_accueil_confirmation_idempotente.sql`,
`lib/features/admin_import_inscriptions/`). La double vérification (aal2) n'y est
qu'une capacité lue par l'écran (`capacites_import_inscriptions()`,
`M/20261018200000_imm_import_ecran.sql:31-38`) : `confirmer_import_inscriptions`
ne l'exige pas en base (`M/20261012185025_imm_accueil_confirmation_idempotente.sql:244-248`).
Il n'active rien, ce qui est conforme à la spec §9.

Ce qu'il ne fait pas pour des candidatures : il exige deux CSV (élèves et
enseignants), lit des en-têtes figés (pas d'association de colonnes), ne garde
pour un enseignant que prénom, nom et courriel, rapproche par courriel exact
seulement, et suit une logique de foyer. Section 7.

### 3.6 Visio et notifications

- Une salle n'existe que pour une ligne `sessions` ; `create-room-token` n'accepte
  que `{session_id}` ; `session_type` n'admet que `standard` et `child`
  (`M/0001_fondations.sql:170`) ; `teacher_id` est obligatoire ; aucun rôle de
  participant ne convient à un candidat ou à un intervieweur [C].
- Le jeton exige un compte valide (`active` ou `provisional_active`) : un candidat
  `pending_kyc` est refusé, et le routeur le confine à `/attente` [C][T].
- Effets de bord d'une `sessions` d'entretien : paie déclenchée à la clôture
  (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`), clôture automatique
  (`M/20261018180000_ses_cloture_auto.sql:67-97`), chevauchement sur `teacher_id`
  (`M/0005_dashboards_affectation_regles.sql:640-645`), invisibilité dans
  `mes_seances_v` qui exige un participant élève
  (`M/20261017100400_af_l1_04_mes_seances_v_par_role.sql:28-43`) [C].
- La salle affiche en permanence « Visite de contrôle possible. »
  (`lib/features/salle_seance/mention_seance.dart:20-24`) : la mention serait
  inexacte pendant un entretien.
- **Aucun canal d'envoi** : SMTP commenté (`supabase/config.toml:239-247`), SMS
  désactivé, aucune fonction Edge d'envoi, aucun jeton push collecté (la table
  `device_tokens` existe, `M/0001_fondations.sql:348`, mais rien ne l'alimente).
  Les notifications internes, les messages métier et les annonces exigent un
  compte valide : un candidat `pending_kyc` ne reçoit rien [C].
- **Arabe** : 7 533 clés traduites sur 8 782 (86 %). Le portail d'attente, les
  accords, l'inscription et le dépôt de pièce sont traduits en entier ; l'espace
  `recrutement` ne l'est qu'à 17 sur 106 (signature et statuts à zéro).

### 3.7 Paiement et versement

- Paie : 47 % du prix, soit 1,99 $ (enfant) et 1,57 $ (adulte) par élève présent
  et par heure, calculée au serveur à la clôture et écrite dans
  `tresorerie_mouvements` [S][C][T] (`C/DECISION-TARIFS-2026-10-18.md:9-16`,
  `M/20261019130000_fac_e_03_paie_47_pour_cent.sql`,
  `T/scenarios_fac_e_paie_par_eleve.sql`). L'enseignant lit ses « Revenus
  estimés » (`mes_revenus_enseignant`, branché en production).
- Versement : entre le 1er et le 5 du mois, par virement international ou mobile
  money selon le pays, frais à la charge de l'académie, coordonnées verrouillées
  48 h après modification [S]
  (`C/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md:148`) ; aucune de ces
  règles n'est dans le code.
- Prestataire : **aucun choisi dans `docs/current/`** (`C/07_MEMOIRE_PEDAGOGIE_FINANCE.md:20`,
  `:38`). Stripe ne sert qu'à l'encaissement des familles.
- `payout_methods(kind text, details jsonb not null)` : ni pays, ni opérateur, ni
  devise, ni état. `details` est `not null` mais sans contrainte de contenu, un
  objet vide passe (`T/scenarios_af_l1_02_foyer_role.sql:41-43`) : ce n'est pas le
  schéma qui empêche une déclaration sans coordonnées, c'est la nature de la
  table, faite pour porter des coordonnées. **L'enseignant ne lit ni n'écrit ses
  propres moyens** [C] (`M/20261017100200_af_l1_02_policies_foyer_role_tuteur.sql:43-58`
  pour la lecture, `M/0001_fondations.sql:1119-1121` pour l'écriture ; les
  scénarios testent l'enfant, le tuteur et l'adulte autonome, pas l'enseignant).
- `payouts` pend d'un portefeuille de foyer et aucune RPC n'en crée [C].
- Client : `PortMesMoyensPaiement` (saisie par jeton opaque, jamais de numéro),
  `CorridorPayout`, `CapacitePayout`, `DestinationMasquee` existent ; en
  production, `CapaciteIndisponible('CPT-BR-16')` et `CPT-BR-10` sans source [C].

---

## 4. Écarts entre la pointe, les décisions en vigueur et la spec

| # | Écart | La spec | La pointe | Proposition |
| :-- | :--- | :--- | :--- | :--- |
| E1 | Admission | salle 3 = pièce **et** évaluation **et** entretien **et** engagement **et** paiement **et** profil renseigné **et** décision finale | approbation de la pièce = compte `active` | séparer : la pièce pose `kyc_status`, l'activation devient l'entrée en « prêts », garde `0089` conservée (`CAND-Q01`) |
| E2 | Refus | « refusé avec motif », réouvrable ; « à compléter » distinct ; un refus KYC bloque l'accès au vivier | refus de la pièce : un enseignant déjà `active` ou `provisional_active` sans autre pièce approuvée passe à `disabled` ; un candidat `pending_kyc` reste `pending_kyc` (`kyc_status = 'rejected'`), `/attente` affiche l'étape `refuse` avec le motif et redemande la pièce. Le serveur n'a pas d'état « à corriger » distinct d'un refus définitif | deux issues de pièce (à corriger, refus définitif) ; le refus de candidature est un état de la candidature, réouvrable (`CAND-Q01`, `CAND-Q18`) |
| E3 | Ordre candidature / compte | la candidature précède le compte | le compte `pending_kyc` naît à la consommation de l'invitation | la candidature importée précède l'invitation ; après l'invitation, candidature et compte avancent ensemble (`CAND-Q03`) |
| E4 | Portail candidat | portail confidentiel | `/attente`, partagé avec le tuteur, déjà confiné | le portail candidat **est** `/attente`, avec des pas de plus |
| E5 | Frontend seul | aucun backend sans autorisation | Claude fait le backend depuis le 17/10, base de test, feu vert explicite | autorisation d'un lot borné (`CAND-Q02`) |
| E6 | Hiérarchie des sources | §1.1 cite la Bible V2 au rang 4 | Bible V2 archivée ; autorité visuelle : DESIGN-GOV, puis DECISION-ENTREE qui prévaut ; la demande la plus récente du directeur prévaut | la spec étant la demande la plus récente, elle prévaut là où elle tranche ; DESIGN-GOV et DECISION-ENTREE régissent le reste |
| E7 | Prestataire | compte marchand pawaPay « confirmé et utilisable » | `docs/current/` ne choisit aucun prestataire ; le dossier maître dit « envisagé », « candidat par corridor » (`DM:7497`, `DM:7941`) | verser l'indication du directeur comme décision datée et vérifier chaque corridor (`CAND-Q05`) |
| E8 | Pays | Nigeria, Côte d'Ivoire, Sénégal | 19 pays proposés, sans Arabie saoudite ni Yémen ; un seul champ pays, public | pays de résidence et pays de versement distincts, liste ISO élargie (`CAND-Q05`) |
| E9 | Paiement éliminatoire | aucune méthode compatible = pas de salle 3 | proposition E04 du dossier maître : dette enseignant enregistrée à défaut (`DM:7943`), au statut de proposition | la spec, décision du 21/10, prévaut sur une proposition |
| E10 | Évaluation | « selon le référentiel existant » | le seul référentiel évalue des élèves | constat d'entretien structuré (`CAND-Q08`) |
| E11 | Entretien vidéo | CTA « Rejoindre la visio » | jeton refusé à `pending_kyc` ; effets de bord d'une `sessions` | deux voies, section 6.3 (`CAND-Q06`) |
| E12 | Notifications | modèle de notification, messages individuels | aucun canal, rien pour un compte en attente | constat manuel « prévenu le » (`CAND-Q10`) |
| E13 | Engagement | texte proposé, version, date | quatre sortes d'accord ; le code de conduite n'est acceptable que par un enseignant actif | cinquième sorte, acceptable en attente (`CAND-Q11`) |
| E14 | Import | 400 candidatures, mappage de colonnes | import du 12/10 : en-têtes figés, deux CSV, B déjà dans son périmètre | un import « candidatures » sur le même motif serveur, B exclu (section 7) |
| E15 | Vocabulaire | salles, vivier, engagement, « Je certifie » | mots déjà employés ou interdits | `CAND-Q12` |
| E16 | Langues | « compétences » | trois langues de cours, enregistrées par leur nom ; offre du 18/10 plus large | la langue se choisit dans le référentiel et s'enregistre par son code (`CAND-Q15`) |
| E17 | CTA par ligne | CTA séparé, immédiatement visible | carte entièrement cliquable, un seul bouton plein | lien secondaire dans la ligne (`CAND-Q14`) |
| E18 | Polices et thème | DM Sans, Plus Jakarta Sans, clair et sombre | identique (M-15, LT-THEME) | rien à faire |

---

## 5. Doublons, risques, dépendances et permissions

### 5.1 Doublons à ne pas créer

| Tentation | Ce qui existe | Règle |
| :--- | :--- | :--- |
| Un portail `/candidature` | `/attente` et `/attente/accords` | étendre `etat_dossier()` ; jamais recalculer l'étape à l'écran |
| Un second mécanisme d'invitation | `invitations_enseignant` et ses cinq RPC (`invitations_enseignant_admin`, `inviter_enseignant`, `revoquer_invitation_enseignant`, `verifier_invitation_enseignant`, `inscrire_enseignant_invite`) | l'invitation devient une **action** sur une candidature |
| Une table « engagements » | `contract_acceptances` et `contract_required_versions` | une sorte d'accord de plus |
| Un second import | l'import du 12/10 | même motif serveur (analyse, essai à blanc, confirmation idempotente) ; pour le nouvel import, l'aal2 s'exige en base ; nouveau type de fichier, pas nouveau mécanisme |
| Un « profil candidat » | `teacher_profiles` | les réponses de candidature ne recopient pas le profil ; le profil se remplit une fois, à l'activation et aux prérequis |
| Une seconde file de validation des pièces | ADM-02, cloisonné par genre en base | le dossier de candidature renvoie vers ADM-02 |
| Un second journal | `audit_logs` et `log_sensitive_access()` | chaque transition journalise, comme les autres RPC de la direction |
| Une barre de sélection propre au module | `BarreSelection` du Comptable | la promouvoir en composant partagé |
| Une table de moyens de paiement pour candidats | `payout_methods`, `PortMesMoyensPaiement` | la déclaration de capacités est une **réponse de candidature** ; les coordonnées viennent plus tard, par CPT-13 |

### 5.2 Risques

| # | Risque | Gravité | Parade |
| :-- | :--- | :--- | :--- |
| R1 | Un import crée des comptes ou des invitations en masse | critique | l'import n'écrit que des candidatures ; l'invitation reste un geste de la direction, ligne par ligne ou par lot confirmé |
| R2 | Le rapprochement fusionne deux personnes sur un nom | élevé | contact normalisé, proposé, appliqué par un geste |
| R3 | Changer `decider_dossier()` affaiblit la garde des contrats | élevé | l'activation reste soumise à `0089`, par déclencheur, quelle que soit la RPC qui l'opère ; les huit contrôles d'admission y sont ajoutés de la même façon |
| R4 | Un entretien posé en `sessions` paie l'intervieweur, se ferme seul ou apparaît dans la Journée | élevé | type de séance dédié, exclu de la paie, de la clôture, du chevauchement et des vues (voie 2) |
| R5 | Données personnelles dans les listes, les journaux ou l'import | élevé | colonnes masquées en base ; le journal porte la référence source, pas le nom |
| R6 | Un état laisse croire qu'un message est parti | moyen | « à prévenir » tant que la direction n'a pas noté « prévenu le » |
| R7 | Un critère change après l'arrivée des candidatures | moyen | réponses versionnées par questionnaire |
| R8 | La matrice passe « confirmé » sur une liste marketing | moyen | « confirmé » exige une date et un responsable |
| R9 | Le genre décide d'un droit à l'écran | élevé | cloisonnement en base, comme `read_kyc_documents()` |
| R10 | Une candidate ne trouve pas d'intervieweuse | moyen | règle de genre, exception super-admin et titulaires de l'entretien décidés avant le premier entretien (`CAND-Q07`, `CAND-Q19`) |
| R11 | Les scénarios SQL du module ne tournent pas en CI | moyen | `.github/` est une zone interdite aux agents (`.claude/hooks/garde.py:22-27`) : la direction les ajoute à `ci.yml`, sinon `tool/rejouer_scenarios.sh` |
| R12 | Un message WhatsApp groupé expose les numéros d'autres candidats (spec §7) | élevé | un message par candidat, jamais de groupe ni de liste de diffusion visible ; « prévenu le » note le canal et le modèle, jamais un contenu libre |

### 5.3 Dépendances backend (à autoriser, pas à contourner)

1. Tables candidature et type de candidature, réponses versionnées, décisions,
   entretiens ; RLS : le candidat ne lit que sa candidature, la direction selon
   son genre (section 5.4).
2. RPC de transition, une par geste, motivée quand il le faut et journalisée,
   avec contrôle des prérequis **en base**.
3. RPC de confirmation qui active le compte ; modification de `decider_dossier()`
   pour le rôle enseignant ; garde d'activation étendue aux huit contrôles
   (`CAND-Q01`).
4. Sorte d'accord pour l'engagement (nom à valider), version requise, insertion
   autorisée à un compte `pending_kyc` invité.
5. Import « candidatures » : analyse serveur, essai à blanc, confirmation
   idempotente par référence source, aal2 exigée en base.
6. Invitation, pause, refus et confirmation par lot, avec contrôle préalable
   serveur (éligibles, exclus avec leur raison) et idempotence : la source que le
   Comptable n'a pas encore.
7. Référentiel de compatibilité de paiement, source de `CPT-BR-10`, et alerte
   quand une ligne change d'état.
8. `historique_candidature`, sans nom dans le journal (R5) : chaque transition
   (ancien et nouvel état, auteur, horodatage, motif) ; la décision d'entretien et
   son compte rendu ; l'acceptation de l'engagement, sa version et sa date ;
   chaque bascule d'un contrôle calculé avec sa cause (décision ADM-02, ligne du
   référentiel modifiée) ; l'import d'origine, ses avertissements et chaque
   correction ; chaque lecture hors portée et chaque lecture du téléphone.
9. Si la voie 2 de l'entretien est retenue : type de séance, rôles de
   participants, règle de jeton pour un candidat convoqué, exclusions (paie,
   clôture, vues, mention de contrôle).
10. Un canal d'envoi, si l'invitation doit partir de l'application.

### 5.4 Permissions par capacité

Un écran lit une capacité, jamais un rôle ; la capacité vient du serveur. Les
équipes n'accèdent qu'aux champs nécessaires (spec §7).

| Capacité | Qui | Accède à | N'accède jamais à |
| :--- | :--- | :--- | :--- |
| `candidatures.lire` | direction, cloisonnée par genre (`CAND-Q07`) | réponses, contrôles, étape, historique | pièce hors ADM-02 |
| `candidatures.contact` | direction nommée | courriel, téléphone, recherche par téléphone ; chaque lecture journalisée | - |
| `candidatures.importer` | direction, en double vérification (aal2 exigée en base, sur le modèle de `capacites_import_inscriptions()`) | import, essai à blanc, rapport | réponses d'une candidature hors portée |
| `candidatures.decider` | direction | transitions, refus, confirmation, lots | - |
| `entretiens.mener` | intervieweur désigné (`CAND-Q19`) | réponses utiles à l'entretien, date, fuseaux | téléphone, pièce, autres candidatures |
| `paiement.referentiel.ecrire` | direction, comptabilité | référentiel, compatibilité calculée | réponses de candidature, identité |
| lecture hors genre | super-admin | exception journalisée, comme pour les pièces | - |
| contrôleur, enseignant, tuteur, élève | - | rien | tout |

---

## 6. Modèle proposé et alternatives

### 6.1 Le moteur générique

| Option | Ce que c'est | Verdict |
| :--- | :--- | :--- |
| A. Constructeur de formulaires | étapes, champs, critères et transitions entièrement en données | écartée : c'est le « constructeur prématuré » que refuse la spec §0, et un critère éliminatoire ne se vérifie plus en base |
| B. Pipeline enseignant codé en dur | tables et écrans propres à l'enseignant | écartée par la décision 1 de la spec §15 |
| **C. Squelette générique, règles par type** | une candidature porte un **type** ; le type désigne un jeu d'étapes fermé et une liste de **contrôles nommés**, calculés en base ; les réponses sont un document versionné par type | **recommandée** |

Le type « enseignant » exige **huit contrôles**, un par prérequis de la spec §3 :
`piece_validee`, `accords_signes` (contrat, accusé, engagement),
`evaluation_validee` (constat de lecture, tajwid et mémorisation, `CAND-Q08`),
`entretien_conclu`, `paiement_compatible`, `profil_renseigne` (compétences,
publics enseignables, fuseau et disponibilités **déclarés dans les réponses**,
puisque `weekly_availability` n'est écrit que par un enseignant actif),
`profil_unique`, `aucune_restriction`. La décision finale humaine est la
transition elle-même. Ces contrôles sont vérifiés par la RPC de confirmation
**et** par la garde d'activation, sur le modèle de `0089`, pour qu'aucune autre
voie n'active un enseignant sans eux. Un type « comptable » en exigerait
d'autres ; aucun contrôle d'un type ne s'applique à un autre (spec §2.2).

Le précédent de l'invitation comptable montre ce qu'il faut éviter : le motif
d'entrée y a été **recopié** pour un second type, avec une table distincte
`invitations_comptable` et cinq RPC propres, pour qu'un code de comptable ne crée
jamais un enseignant (`M/20261017160200_bf1_03_invitation_comptable.sql:11-13`) ;
l'émission y exige en plus l'aal2. Le squelette générique garde cette étanchéité
par le **type**, sans recopier le moteur.

### 6.2 Étape, état, et dimensions séparées

La liste de onze statuts de la spec mélange l'étape et ce qui l'arrête. Les
séparer rend les transitions vérifiables.

| Dimension | Valeurs proposées | Porté par |
| :--- | :--- | :--- |
| Étape | `recue`, `invitee`, `prequalification`, `verifications`, `confirmee` | la candidature |
| État dans l'étape | `a_completer`, `en_examen`, `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente` | la candidature |
| Issue | `en_cours`, `refusee`, `retiree` ; terminales mais réouvrables par geste motivé | la candidature |
| Pause | drapeau, motif, date de reprise facultative ; ne change pas l'étape | la candidature |
| Responsable | membre de la direction chargé du dossier, facultatif, changé par geste journalisé | la candidature |
| Pièce d'identité | lue dans `kyc_documents`, jamais recopiée | existant |
| Paiement | `inconnu`, `compatible`, `incompatible`, `a_verifier`, calculé | réponses et référentiel |
| Disponibilité opérationnelle | après confirmation seulement | `teacher_profiles` |
| Affectation | lue dans les classes | existant |
| Coordonnées financières | `absentes`, `enregistrees` ; jamais exigées avant le premier cours | CPT-13 |

Correspondance : « Invitation envoyée » = `invitee` ; « Informations à
compléter » = `a_completer` ; « Préqualification » et « Vérifications » = les
étapes du même nom en `en_examen` ; les deux états d'entretien (« Entretien à
planifier », « Entretien planifié ») et « Décision finale en attente »
appartiennent à `verifications` ; « Confirmé / prêt à être affecté » =
`confirmee` ; « Refusé », « Retiré » = l'issue ; « En pause » = le drapeau.
`recue` est l'étape que la spec n'a pas : la candidature importée, avant toute
invitation.

**Ce qui se demande à quelle étape** (spec §2.1 et §13 : « les champs
apparaissent au bon moment ») :

| Étape | Demandé | Jamais avant |
| :--- | :--- | :--- |
| Candidature initiale (`recue`) | nom, contact, genre, langues, mémorisation et disponibilités déclarées (le formulaire) | - |
| Préqualification | pays de résidence et de versement, fuseau, publics, compte bancaire oui ou non, opérateurs accessibles, accord de rémunération, cadre religieux | - |
| Vérifications | pièce d'identité, contrat, accusé | la préqualification : la spec §5 n'exige que l'engagement avant la salle 2. **Conséquence** : pour l'enseignant, `/attente` demande aujourd'hui accords et pièce dès l'inscription ; ils passent après la préqualification. Le parcours du tuteur ne change pas |
| Entretien | constat de niveau, compte rendu | - |
| Après confirmation | photo, titre, `weekly_availability`, code de conduite (prérequis existants) | la confirmation |
| Premier versement | coordonnées financières (CPT-13) | la salle 3 |

### 6.3 L'entretien vidéo : deux voies

| Voie | Ce qu'il faut | Pour | Contre |
| :--- | :--- | :--- | :--- |
| 1. Hors de l'application, par WhatsApp | l'application enregistre date, heure, fuseaux, intervieweur, issue et compte rendu ; aucun bouton visio | aucun changement de la salle ni du jeton ; les candidats de A ont tous consenti au contact WhatsApp (B ne le demande pas) ; utilisable pour la première vague | contredit la décision 8 de la spec §15 (CTA visio dans la vue d'entretien) ; aucun contrôle de qui entre |
| 2. Dans `/salle` | type de séance `entretien`, rôles candidat et intervieweur ; jeton autorisé à un candidat `pending_kyc` convoqué ; exclusion de la paie, de la clôture automatique, du chevauchement, de `mes_seances_v`, de l'observation par le contrôleur ; mention de séance propre à l'entretien ; chemin du routeur depuis `/attente` | aucun lien partageable ; même salle que les cours ; l'état « session disponible » se mesure | touche la garde du jeton et le déclencheur de paie : migration et revue de sécurité |

**Recommandation :** voie 1 pour la première vague, sans bouton qui prétendrait
ouvrir une visio (« un bouton qui ne peut pas aboutir n'est pas rendu ») ; voie 2
comme lot daté, si le directeur maintient le CTA intégré. Ni l'une ni l'autre ne
refond LiveKit.

L'enregistrement audio est supprimé pour l'instant
(`C/DECISION-ENTREE-2026-10-17.md:33`) : un entretien n'est pas enregistré, et doit
le dire. La mention de contrôle de la salle ne s'y applique pas (`CAND-Q09`).

### 6.3 bis États de l'entretien, des deux côtés

| État | Candidat (`CAND-02`) | Direction (`ADM-20`, vue Entretiens) | Voie 1 | Voie 2 |
| :--- | :--- | :--- | :--- | :--- |
| À planifier | « Votre entretien sera planifié prochainement » | lien « Planifier un entretien » (`ChampDate`) | identique | identique |
| Planifié | date, heure, fuseau du candidat et de l'intervieweur ; « Voir les détails » | date, heure, fuseaux, intervieweur ; « Voir les détails » | « Prévu par WhatsApp » | « Rejoindre » à l'ouverture autorisée |
| Session disponible, en cours | - | - | aucun bouton ; « Entretien en cours » | « Rejoindre la visio », accès immédiat |
| Terminé | « Entretien terminé, l'académie vous répondra » (jamais le résultat interne) | résultat, compte rendu, durée si connue, action suivante | identique | identique |
| Annulé | état explicite, nouvelle date à venir | « Annulé le … par … » ; « Reprogrammer » | identique | identique |
| Manqué | état explicite | « Manqué (candidat ou intervieweur) » ; « Reprogrammer » | identique | identique |
| Lien absent ou indisponible | « Le lien n'est pas encore disponible ; l'académie vous contactera par WhatsApp » | même phrase, solution de secours, aucun bouton inopérant | - | identique |

L'entretien garde son issue (`annule`, `manque_candidat`, `manque_intervieweur`,
`tenu`) : le retour à `entretien_a_planifier` n'efface jamais l'état explicite.
Aucune donnée sensible (genre, pièce, téléphone, réponses) dans la salle
d'entretien. `CAND-Q14` nuance la décision 8 de la spec §15 et l'exigence
« immédiatement identifiables » du §10 : il le dit.

### 6.4 La compatibilité de paiement

Un référentiel serveur sur le motif de `langues_cours` : pays (ISO), méthode
(`virement_bancaire`, `mobile_money`), opérateur, devise, type de décaissement,
état (`confirme`, `en_verification`, `indisponible`), date et responsable de la
vérification, notes ; écriture par la direction et la comptabilité, lecture par
un candidat des seules lignes confirmées de son pays de versement. Il devient la
source de `CorridorPayout` et `CapacitePayout`, déjà dans le client. Le
prestataire est une colonne de données (« aucun prestataire n'est codé comme
obligatoire », `lib/core/capacites/port_capacite_payout.dart:5-8`).

- Le candidat voit d'abord les **conditions de rémunération** (carte de
  `CAND-01`, section 10.1), puis **déclare des capacités** (pays de résidence,
  pays de versement, compte bancaire oui ou non, opérateurs accessibles),
  choisies parmi les lignes confirmées : c'est une réponse de candidature,
  jamais une ligne de `payout_methods`.
- La déclaration comprend la case « J'accepte de recevoir ma rémunération par au
  moins un moyen validé par Rewayah » (spec §4.2), datée et versionnée avec le
  questionnaire. Elle ne demande jamais de numéro de compte, d'IBAN, de numéro
  de portefeuille complet, d'identifiant ni de code ; le numéro WhatsApp de
  contact n'est jamais présenté ni réutilisé comme numéro de portefeuille.
- `paiement_compatible` est vrai si une capacité déclarée, puis confirmée par la
  direction, croise une ligne `confirme`. Une ligne `en_verification` ne prouve
  rien.
- La préférence bancaire est un **critère de tri nommé**, jamais un score ; sa
  place dans le tri est une règle écrite par la direction (`CAND-Q20`).
- Les coordonnées se saisissent plus tard par CPT-13 (« Recevoir mes paiements »),
  par jeton opaque, quand les cours commencent.

---

## 7. Import contrôlé des candidatures existantes

1. **Ne pas réimporter B.** Les 11 lignes de l'onglet « Enseignants (Réponses) »
   sont déjà dans le périmètre de l'import du 12/10 (pré-inscrits enseignants).
   L'import « candidatures » les signale comme « déjà connues » et n'écrit rien.
2. **A1 et A2 sont le vrai périmètre**, avec des en-têtes en arabe que l'import du
   12/10 ne lit pas : il faut une étape d'association des colonnes, une page et non
   une feuille modale.
3. **Même motif serveur que le 12/10** : analyse côté serveur, essai à blanc avec
   rejets et avertissements ligne par ligne, confirmation idempotente, aal2
   exigée en base, journal portant la référence source (classeur, onglet,
   horodatage), jamais le nom.
4. **Rapprochement** par courriel **ou** téléphone normalisés, proposé, appliqué
   par un geste ; pour un groupe aux réponses divergentes, la ligne la plus récente
   est proposée (`CAND-Q16`).
5. **Ce qu'une ligne importée ne fait jamais** : créer un compte, émettre une
   invitation, valider une pièce, accepter un accord, entrer en `prequalification`.
   Elle entre en `recue`. L'invitation est un geste ultérieur, et il exige un
   courriel valide.
6. **Les huit pas de la spec §9**, dans `ADM-23` : (1) export CSV du classeur,
   déposé par la direction, sans connexion à l'API Google ; (2) aperçu des
   premières lignes, contacts masqués ; (3) association des colonnes sur en-têtes
   normalisés, avec la table de correspondance des libellés ; (4) doublons
   probables et lignes incomplètes ; (5) erreurs et avertissements ligne par
   ligne ; (6) quatre compteurs avant confirmation : nouvelles, déjà connues,
   ignorées, à corriger ; (7) confirmation idempotente ; (8) rapport final ligne
   par ligne, référence source sans nom. Une ligne « à corriger » se corrige dans
   le classeur et se réimporte ; la correction est tracée sur la même référence
   source.

---

## 8. Transitions et règles de blocage

Toute transition passe par une RPC qui vérifie la règle en base, exige un motif
quand la colonne le dit, et journalise ancien état, nouvel état, auteur et
horodatage.

| De | Vers | Qui | Conditions vérifiées en base | Motif |
| :--- | :--- | :--- | :--- | :--- |
| (import confirmé) | `recue` | direction | référence source unique | non |
| `recue` | `invitee` | direction, une ligne ou un lot confirmé | courriel valide ; aucun compte existant ; `inviter_enseignant` | non |
| `invitee` | `prequalification/a_completer` | le candidat, en consommant son code | `inscrire_enseignant_invite` ; invitation non expirée | non |
| `invitee` (invitation expirée) | `recue` | automatique | la trace de l'invitation reste ; réinvitation possible | non |
| `prequalification/a_completer` | `prequalification/en_examen` | le candidat | questionnaire complet pour la version courante ; accord de rémunération ; engagement accepté | non |
| `prequalification/en_examen` | `prequalification/a_completer` | direction | ce qui manque est nommé au candidat | **oui** |
| `prequalification/en_examen` | `verifications` | direction | engagement accepté à la version requise | non |
| `verifications/*` | `entretien_planifie` | direction | date, heure, fuseau connu, intervieweur nommé (genre selon `CAND-Q07`) | non |
| `entretien_planifie` | `entretien_a_planifier` | direction | entretien annulé ou manqué ; son issue reste | **oui** |
| `entretien_planifie` | `decision_en_attente` | intervieweur | compte rendu enregistré | non |
| `decision_en_attente` | `confirmee` | direction | les **huit** contrôles vrais ; active le compte sous la garde d'activation | non |
| tout état en cours | `refusee` | direction | motif interne ; message au candidat par modèle distinct, jamais le motif | **oui** |
| tout état en cours | `retiree` | le candidat depuis `/attente` ; la direction seulement pour consigner une demande du candidat reçue hors de l'application | entretien planifié annulé ; demande et canal tracés | **oui** si c'est la direction |
| tout état | pause activée ou levée | direction | l'étape ne change pas | **oui** à l'activation |
| `refusee`, `retiree` | étape d'origine | direction | contrôles revérifiés | **oui** |
| `confirmee` | `confirmee` + restriction | direction, ou automatique si un contrôle tombe | sort de l'affectabilité ; l'historique reste | **oui** |

Une sortie décidée par la direction sans demande du candidat est un **refus
motivé**, jamais un retrait.

**Blocages durs** : entrer en `confirmee` avec un contrôle faux ; confirmer ou
inviter en lot une ligne non éligible ; importer ailleurs qu'en `recue` ; exposer
une pièce d'identité dans une liste.

Un contrôle qui tombe après confirmation (pièce, paiement, restriction) pose
toujours une restriction motivée ; il ne change jamais l'étape et n'efface rien.

**Ce qui ne rétrograde jamais** : une indisponibilité temporaire, une pause, un
critère changé après une décision.

---

## 9. Questions au directeur

> **Réponses du 21/10** : voir `docs/current/DECISION-CANDIDATURES-2026-10-21.md`.
> Après les remarques du directeur, les recommandations de `CAND-Q01`, `CAND-Q03`,
> `CAND-Q05`, `CAND-Q06`, `CAND-Q10`, `CAND-Q17` et `CAND-Q21` ont été révisées
> dans la page d'arbitrage : plus de WhatsApp, sauf pour envoyer le lien
> d'inscription à qui n'a pas de courriel. Le tableau ci-dessous garde les
> recommandations d'origine.

Format du registre de marque (`C/marque/REGISTRE-DECISIONS-MARQUE.md:7-9`) : une
question ouverte n'est tranchée par aucun agent ; quand le directeur tranche, une
décision datée est versée dans `docs/current/` et, selon la règle de `C/08` §1,
une ligne datée s'ajoute à son §5 bis. Les questions marquées **bloquante**
empêchent tout lot du module.

| ID | Question | Pourquoi elle compte | Recommandation | Ce qui débloque |
| :--- | :--- | :--- | :--- | :--- |
| `CAND-Q01` **bloquante** | Pour un enseignant, l'approbation de la pièce cesse-t-elle d'activer le compte, l'activation devenant l'entrée en « prêts à être affectés » sous les huit contrôles ? Le refus de la pièce d'un enseignant déjà actif cesse-t-il de le passer à `disabled` ? (Pour un candidat `pending_kyc`, le refus le laisse déjà en attente, à l'étape `refuse`, avec la pièce à redéposer.) | Sans cela, l'enseignant est affectable avant tout entretien ; la salle 3 n'a pas de sens | Oui aux deux, garde `0089` conservée et étendue ; la décision étant fermée en production, aucun enseignant n'est admis entre-temps | Décision datée |
| `CAND-Q02` **bloquante** | Le module reste-t-il « frontend seul », ou un lot backend borné (section 5.3, points 1 à 8) est-il autorisé sur la base de test ? | §7 et §13 de la spec ne tiennent qu'en base | Autoriser le lot borné ; en attendant, seulement des fiches et des maquettes | Feu vert explicite |
| `CAND-Q03` **bloquante** | La candidature commence-t-elle avant l'invitation (`recue`, préexamen sur les réponses importées), l'invitation devenant une action ? Le courriel est-il obligatoire pour être invité ? | 418 personnes sans compte ; 32 lignes sans courriel | Oui ; le courriel manquant se demande par WhatsApp | Décision datée |
| `CAND-Q04` | Le module est-il un septième onglet de Personnes, ou l'onglet Invitations devient-il « Candidatures », l'invitation y étant une étape ? | Personnes a déjà six onglets ; deux listes pour la même personne divergeraient | Élargir Invitations en Candidatures | Décision datée |
| `CAND-Q05` **bloquante pour la salle 3** | L'indication « compte marchand pawaPay confirmé et utilisable » est-elle versée comme décision datée, sans rouvrir sa validation générale ? Quels corridors vérifier d'abord ? Comment verse-t-on à un candidat résidant en Arabie saoudite ? L'absence de méthode compatible reste-t-elle éliminatoire (spec) face à la proposition E04 d'une dette enseignant ? Où vit l'écran du référentiel : Finance ou Configuration ? | Sans corridor confirmé pour l'Arabie saoudite, la moitié du vivier réel n'atteint pas la salle 3 | Décision datée ; ordre : Arabie saoudite, Nigeria, puis Guinée, Sénégal, Côte d'Ivoire ; la spec prévaut sur E04 ; liste des pays élargie (ISO) ; écran dans Finance | Décision datée et liste de corridors vérifiés |
| `CAND-Q06` | Entretien : voie 1 (WhatsApp, rien dans la salle) pour la première vague, puis voie 2 (dans `/salle`) ? | La décision 8 de la spec demande un CTA visio intégré | Voie 1 maintenant, voie 2 en lot daté | Décision datée |
| `CAND-Q07` | La séparation femmes/hommes s'applique-t-elle aux entretiens et à la lecture des candidatures, avec l'exception super-admin des pièces ? | 89 candidates ; une règle d'écran n'est pas une protection | Oui, en base, même règle que les pièces | Décision datée |
| `CAND-Q08` | Qu'est-ce que l'évaluation de lecture, tajwid et mémorisation d'un enseignant : un constat d'entretien structuré, ou un référentiel neuf ? | 89 candidats se disent « prêts à un test de niveau » | Constat structuré (niveau observé, riwaya, ijaza présentée) | Décision datée |
| `CAND-Q09` | L'entretien est-il annoncé « non enregistré », et quelle mention remplace « Visite de contrôle possible » ? | La mention de la salle serait fausse | « Entretien non enregistré » ; aucune visite de contrôle | Décision datée |
| `CAND-Q10` | Tant qu'aucun SMTP n'est posé, la direction prévient-elle par WhatsApp, un message par personne, et l'application enregistre-t-elle « prévenu le » ? | Aucun canal ; aucun état ne doit prétendre un envoi ; R12 | Oui | Décision datée |
| `CAND-Q11` | Engagement religieux : texte validé juridiquement, en français et en arabe, version `2026-10` ; « Je confirme » au lieu de « Je certifie » ; accepté en préqualification par un candidat en attente ; distinct du code de conduite ? | Nouvelle sorte d'accord ; M-10 ; la mention des Compagnons est nouvelle : la doctrine écrite dit « voie d'Ahl as-Sunna » (`C/REGISTRE-RECONCILIATION-2026-10-14.md:139`) et « à la lumière des salafs » (M-21, `C/marque/REGISTRE-DECISIONS-MARQUE.md:35`), sans nommer les Compagnons | Oui ; texte distinct du code de conduite | Texte validé, décision datée |
| `CAND-Q12` | Les mots : comment nomme-t-on les trois salles, le vivier, la candidature ? | « salle », « vivier », « engagement » ont déjà un sens dans le dépôt | « Premier examen », « Vérifications et entretien », « Prêts à enseigner » ; « Cadre religieux et pédagogique » pour l'engagement | Ajout dans `mots-rewayah` |
| `CAND-Q13` | Le parcours candidat est-il livré en arabe ? | La population des formulaires est arabophone ; `recrutement` est traduit à 16 % | Oui, pour les clés du parcours candidat | Décision datée |
| `CAND-Q14` | Le CTA d'entretien de chaque ligne est-il un lien secondaire (et non un bouton plein) ? | K-56 et la carte entièrement cliquable ; nuance la décision 8 de la spec §15 | Oui | Décision datée |
| `CAND-Q15` | Les défauts trouvés hors module (langue enregistrée par son nom et comparée à un code, `creer_groupe` sans contrôle de pièce ni de genre, `c11bis` qui n'affecte jamais, décimales du GNF, code de conduite hors de la garde d'activation) se corrigent-ils dans des lots séparés ? | « Prêts à être affectés » n'a pas de chemin serveur fiable | Oui, lots séparés et courts, la langue d'abord | Feu vert |
| `CAND-Q16` | Pour un doublon aux réponses divergentes, quelle ligne l'emporte ? | 14 groupes sur 27 | La plus récente, les autres en historique | Décision datée |
| `CAND-Q17` **bloquante pour l'après-import** | Après l'import initial, par où arrive une nouvelle candidature, de tout type : imports périodiques du formulaire Google, formulaire public sur le site (sans compte, donc sans RLS candidat), ou lien personnel pour postuler ? | A-07 ferme l'inscription enseignant ; la spec §0 veut un moteur réutilisable | Imports périodiques par `ADM-23` tant qu'aucun formulaire public n'est décidé ; aucun formulaire public sans revue de sécurité (abus, consentement) | Décision datée |
| `CAND-Q18` | À côté de « à corriger » (pièce illisible ou incomplète), garde-t-on un refus définitif (pièce fausse, identité discordante) qui fait passer la candidature en `refusee` avec motif interne ? Une pièce a-t-elle une date de validité qui sortirait un confirmé de « prêts », sachant qu'elle est purgée à 90 jours (`kyc_retention_days`) ? | Spec §3 (un refus de pièce bloque l'accès au vivier) et §12.2 (pièce expirée) | Les deux issues ; aucune expiration tant qu'aucune date de validité n'est saisie | Décision datée |
| `CAND-Q19` | Qui peut être intervieweur : la direction seulement, ou un enseignant confirmé désigné ? | `entretiens.mener` n'a pas de titulaire | Direction seulement pour la première vague | Décision datée |
| `CAND-Q20` | Qu'est-ce que le tri « adéquation » et la « priorité » de la spec §8.1, et quand la préférence bancaire départage-t-elle ? | Sans règle écrite, ce tri serait un score inventé (spec §4.3) | Clés affichées en clair, jamais un score : besoin ouvert (genre, langue), puis niveau constaté, puis disponibilité, puis compte bancaire, à égalité des clés précédentes seulement | Décision datée |
| `CAND-Q21` | Combien de temps garde-t-on une candidature refusée, retirée ou jamais invitée, et sur quelle base pour les 418 personnes importées (B ne recueille aucun consentement) ? Les réponses entrent-elles dans `mes_donnees_export()` (motifs internes exclus) et dans `demander_suppression_compte()` (`M/20261018150000_cpt_suppression_export.sql:174`, `:385`) ? Comment une personne sans compte (`recue`) demande-t-elle l'effacement ? | Spec §1.1, rang 1 | Durée dans `app_config`, anonymisation sur le modèle de `traiter_demande_suppression` (`:587`), demande reçue par WhatsApp consignée par la direction | Avis du juriste, décision datée |
| `CAND-Q22` | Les pièces autres que l'identité (ijaza, diplôme, attestation) se déposent-elles dans l'application, ou sont-elles présentées à l'entretien et constatées dans le compte rendu ? | 334 candidats disent pouvoir présenter une ijaza ; aucun dépôt n'existe hors `piece-identite-depot` | Constat à l'entretien pour la première vague ; tout dépôt futur passe par le coffre R2 cloisonné par genre, jamais par un lien Drive | Décision datée |

---

## 10. Plan d'écrans et de composants

Codes **proposés**, à inscrire dans un `C/CATALOGUE_ECRANS_RECRUTEMENT.md` avec
leurs fiches (Tâche, Contenu, Entrée, États, Droits, Contrat serveur à demander)
**après** les questions bloquantes et **avant** tout fichier `.dart`. Libres à la
pointe : `ADM-20` et au-delà, préfixe `CAND-` (éviter `REC-`, déjà pris).

### 10.1 Côté candidat : des pas de plus dans `/attente`

| Code proposé | Écran | Réutilise |
| :--- | :--- | :--- |
| `CAND-01` | Questionnaire de préqualification, en cartes, choix dans des listes (jamais de saisie à la main pour ce qui se choisit). Première carte : **conditions de rémunération**, lues avant l'envoi : part de l'enseignant (47 % du prix), montants par élève présent et par heure **lus au serveur** et jamais écrits en dur (`C/DECISION-TARIFS-2026-10-18.md`), élève absent non payé, versement du 1er au 5 du mois, frais à la charge de l'académie, coordonnées demandées seulement au premier versement | coquille du parcours d'inscription ; `etat_dossier()` étendu ; politique de paie en base |
| (case de plus) | Cadre religieux et pédagogique : une case sur la page d'accords, présentée en préqualification | `accords_page.dart`, `contract_required_versions` |
| `CAND-02` | Mon entretien : états de 6.3 bis | `EmplacementEntree`, `ctaSeance` (voie 2) |
| `CAND-03` | Retirer ma candidature : action discrète dans `/attente`, effet dit avant (entretien annulé, réouverture par l'académie seulement) | `ConfirmDestructive` |

`etat_dossier()` s'étend au serveur (aujourd'hui `incomplet`, `enVerification`,
`accesEnPreparation`, `refuse`, `suspendu`) pour : à compléter (avec la liste de
ce qui manque), en examen, entretien planifié, annulé ou manqué, en pause (motif
public, date de reprise si connue), refusée (message issu d'un modèle validé,
jamais le motif interne), retirée. Le portail ne montre jamais un autre candidat,
ni compteur, ni liste (spec §7).

### 10.2 Côté direction : Personnes

| Code proposé | Écran | Réutilise ou étend |
| :--- | :--- | :--- |
| `ADM-20` | Candidatures : recherche, filtres d'étape en puces avec compteur, autres axes sous « Plus », tri, pagination au serveur, sélection multiple. Colonnes : nom, étape, état, pays de résidence, entretien, paiement, responsable, dernière activité ; ni courriel, ni téléphone, ni pièce | `DataCollection`, `ChampRecherche`, `RangeeFiltres`, `BarreSelection` promue ; pagination de Regroupements |
| `ADM-21` | Candidature : dans l'ordre, étape et issue, blocages, prochaine action, puis réponses, contrôles nommés, lien vers ADM-02 pour la pièce, entretien, historique, décision | `StatusPill`, `MenuActions`, `historique_candidature` |
| `ADM-22` | Action groupée : chaque candidature ciblée listée (nom et étape, aucun contact), leur nombre, l'effet exact, les exclus avec leur raison. Actions : inviter, mettre en pause, lever la pause, refuser, consigner « prévenu le », confirmer. Refuser et mettre en pause exigent un motif interne commun et un modèle de message, puis une confirmation explicite (saisie du nombre de dossiers). La confirmation en lot n'admet que les dossiers aux huit contrôles vrais au contrôle préalable. Rapport ligne par ligne, issue inconnue dite, les réussites jamais annulées par un refus voisin | motif d'interface du Comptable, RPC de lot neuve |
| `ADM-23` | Import de candidatures : les huit pas de la section 7 | motif de l'import du 12/10 ; **route distincte de `/admin/personnes/import`** pour éviter la confusion |
| `ADM-24` | Compatibilité de paiement par pays | référentiel ; place selon `CAND-Q05` |

**Quatre alertes, jamais confondues**, en compteurs distincts en tête d'`ADM-20`
et en filtres (spec §8.3) : **bloquées** (contrôle faux nommé ou restriction) ;
**entretiens en retard** (date passée sans compte rendu depuis plus de 24 h, ou
« à planifier » depuis plus de N jours, N dans `app_config`) ; **informations
manquantes** (`a_completer`, « courriel à obtenir », « indicatif à confirmer ») ;
**confirmées indisponibles** (`confirmee` avec indisponibilité déclarée, sans
restriction). Une pause n'entre dans aucune des quatre. Le seuil « sans activité
depuis N jours » se règle aussi dans `app_config`.

Les « salles » sont des **filtres d'étape** de `ADM-20`, pas un kanban : un kanban
de quatre cents cartes n'est ni dense ni filtrable, et le dépôt n'en a aucun motif
(spec §10 le permet). La vue « Entretiens » est le filtre `verifications` trié par
date d'entretien ; le nom ouvre `ADM-21`, le lien d'entretien est à part (spec §6).

### 10.3 Composants et états

| Composant | Statut |
| :--- | :--- |
| `BarreSelection` | à **promouvoir** du Comptable vers `lib/core/widgets/` |
| Contrôle préalable groupé et suivi ligne par ligne | motif d'interface à extraire du Comptable ; source serveur neuve |
| Ligne d'historique d'un dossier | **neuf** (`TimelineRow` est la journée de l'enseignant) |
| `DataCollection`, `ChampRecherche`, `RangeeFiltres`, `FilterPill`, `MenuFiltre`, `MenuActions`, `StatusPill`, `EmptyState`, `Skeleton`, `ConfirmDestructive`, `AppBottomSheet`, `ChampDate` | réutilisés tels quels |

Chaque écran porte une `UX_REVIEW_CAND-<n>.md` (DESIGN-GOV) et, dans sa fiche,
la table des états de la spec §11 : chargement ; données présentes ; aucun
résultat ; recherche sans résultat (filtres rappelés) ; données partielles
(dépendance absente nommée sans bloquer le reste) ; erreur de validation ; erreur
serveur ; accès interdit (« hors portée » distinct d'« absent ») ; action en
cours ; succès affiché seulement après la réponse du serveur ; lot partiellement
refusé ; bloquée avec raison ; en pause ; retirée ou refusée ; entretien annulé,
manqué ou sans lien ; paiement inconnu, compatible, incompatible, à vérifier. Un
état critique porte un texte et une icône, jamais la couleur seule. Bureau : file
et détail (DESIGN-GOV) ; tablette : liste et détail en deux volets ; mobile :
cartes.

---

## 11. Scénarios de la spec §12.2

| Scénario | Comportement retenu | Existe | Manque |
| :--- | :--- | :--- | :--- |
| Candidature complète | `prequalification/en_examen`, file par ancienneté | file ADM-02 par ancienneté | tout le reste |
| Candidature partielle | `a_completer`, la liste de ce qui manque | `PieceManquante` | questionnaire |
| Doublon à l'import | proposé, jamais fusionné sans geste | rapprochement par courriel exact | téléphone, référence source |
| Candidat qui ne répond pas | reste en `recue`, `invitee` ou `a_completer` ; alerte « sans activité depuis N jours » ; invitation expirée à 14 jours | expiration de l'invitation | date de dernière activité |
| Pièce absente ou en attente | contrôle `piece_validee` faux ; renvoi vers ADM-02 | ADM-02 | - |
| Pièce refusée | « à corriger » ou refus définitif (`CAND-Q18`) | `motif_refus`, étape `refuse` | refus définitif distinct |
| Pièce expirée | **n'existe pas** : aucune date de validité, pièce purgée à 90 jours | - | `CAND-Q18` |
| Engagement non accepté | bloque l'entrée en `verifications` | page unique des accords | la sorte d'accord |
| Sans compte bancaire, mobile money compatible | `paiement_compatible` vrai | types client | référentiel |
| Compte bancaire non compatible avec le pays | faux pour cette méthode, vrai si une autre l'est | - | référentiel |
| Aucune méthode confirmée | bloque `confirmee` ; filtre visible | - | référentiel, `CAND-Q05` |
| Entretien à planifier, annulé, manqué, en cours, terminé | états de 6.3 bis ; annulé et manqué gardent leur issue et proposent de reprogrammer | `PhaseSeance` (voie 2) | entretien |
| Visio sans lien valide | une phrase et une solution de secours à la place du bouton | règle du bouton qui ne peut pas aboutir | - |
| Décision positive avec un prérequis manquant | refusée par la base, contrôle manquant nommé | garde `0089` pour les contrats | RPC de confirmation, garde étendue |
| Confirmé mais indisponible | `confirmee` + indisponibilité, hors affectation, compté à part | - | colonne, prédicat d'affectation |
| Profil suspendu après confirmation | restriction motivée ; historique conservé | `disabled` | RPC de suspension (aucune n'existe) |
| Réactivation après résolution | geste motivé, contrôles revérifiés | - | RPC |
| Affectation occupée ou conflit | inchangé : langue, genre, plafond hebdomadaire vérifiés par `tc_verifier` | oui | défaut de langue et `creer_groupe` à corriger (`CAND-Q15`) |
| Critère changé après coup | version du questionnaire ; aucune décision passée réécrite | - | versionnage |
| Matrice modifiée | une ligne passée `indisponible` (ou revenue `en_verification`) rend `paiement_compatible` faux pour les confirmés qui n'avaient qu'elle : restriction automatique « paiement à revérifier », motif tracé, sortie de l'affectabilité, étape `confirmee` et historique conservés ; les confirmés qui gardent une autre méthode confirmée ne bougent pas ; alerte à la direction et à la comptabilité | - | déclencheur sur le référentiel, vue d'alerte |
| Action groupée partiellement refusée | rapport ligne par ligne ; les réussites restent | motif d'interface du Comptable | RPC de lot |
| Dossier ou pièce sans permission | refus en base, « hors portée » distinct d'« absent » | motif d'ADM-02 | RLS candidature |
| Desktop, tablette, mobile | tableau dense, deux volets, cartes ; bureau 1440 en file et détail (DESIGN-GOV) | oui | - |
| Chargement, vide, erreur, hors ligne | `Skeleton`, `EmptyState`, bandeau hors ligne | oui | - |

**Scénarios ajoutés par cette revue**

| Scénario | Comportement retenu |
| :--- | :--- |
| Une ligne du formulaire B, déjà importée le 12/10 | signalée « déjà connue », rien n'est écrit |
| Un candidat sans courriel | reste en `recue`, marqué « courriel à obtenir » ; jamais invité |
| Un candidat importé crée lui-même un compte avec un autre courriel | impossible sans invitation ; rapprochement proposé par téléphone si la direction l'invite |
| Une invitation expire avant d'être consommée | la candidature revient en `recue` avec la trace ; réinvitation possible |
| Un contrôleur postule comme enseignant | aucune règle en vigueur ne l'interdit : un contrôleur peut aussi enseigner, et le tirage exclut alors ses propres classes (R18, BR-CT-02, `C/DECISION-CLASSES-SIMULTANEES-2026-10-10.md:39`). Comme `profiles.role` ne porte qu'un rôle, `inviter_enseignant` rend `compte_existant` pour son courriel : le cumul attend la capacité Contrôle (C6) ; à trancher par le directeur le jour où le cas se présente |
| Un candidat retire sa candidature pendant un entretien planifié | l'entretien est annulé, son issue reste, l'intervieweur le voit |
| Le texte de l'engagement change de version | les candidats en cours la ré-acceptent avant `confirmee` ; les confirmés gardent la leur |
| Le fuseau du candidat est inconnu | l'entretien ne se planifie pas ; aucune heure dans un fuseau deviné |
| Les créneaux importés sont en heure de La Mecque | conservés comme créneaux récurrents avec leur heure locale et leur fuseau IANA (`Asia/Riyadh` pour A, `UTC` pour B), selon la règle « Fuseaux IANA en stockage, UTC pour les instants » (`C/02_ARCHITECTURE_ET_SECURITE.md:23`) ; jamais convertis en heure absolue, jamais recopiés dans `weekly_availability` |

---

## 12. Plan de recette et de non-régression

**Base** : un fichier `T/scenarios_candidatures.sql` rejoué sur Postgres nu par
`tool/rejouer_scenarios.sh`, et proposé à la direction pour `ci.yml` (zone
interdite aux agents) :

- impossible d'entrer en `confirmee` avec un des huit contrôles faux, un cas par
  contrôle ;
- `decider_dossier()` n'active plus un enseignant (si `CAND-Q01`), et la garde
  d'activation refuse toujours une activation sans contrats ni contrôles ;
- l'absence de compte bancaire ne bloque pas si une méthode mobile money
  confirmée croise la déclaration ; une ligne `en_verification` ne rend jamais
  `paiement_compatible` vrai ;
- l'import n'écrit aucune ligne de `profiles` ni d'invitation, ne touche ni
  `kyc_documents` ni `contract_acceptances` ; un second import identique n'ajoute
  rien ; une ligne de B est signalée « déjà connue » ;
- un candidat ne lit que sa candidature ; il ne lit aucune ligne non confirmée du
  référentiel ;
- un lot de dix invitations dont trois inéligibles rend sept réussites, trois
  exclus motivés, et laisse les trois candidatures inchangées ;
- chaque transition laisse une entrée `audit_logs`, et la chaîne reste
  vérifiable.

**Traçabilité des critères de la spec §13**

| Critère §13 | Preuve |
| :--- | :--- |
| Un type autre qu'enseignant (fixture « comptable ») se définit sans copier le pipeline ; ses contrôles ne touchent pas l'enseignant, et inversement | `T/scenarios_candidatures.sql` |
| Aucune donnée d'une étape ultérieure n'est exigée (ni coordonnées, ni photo, ni `weekly_availability`) | SQL et widget |
| Compte bancaire devant à clés d'adéquation égales, jamais sinon | SQL |
| Confirmé indisponible exclu de l'affectation et compté à part | SQL et widget |
| Nom et CTA d'entretien : deux cibles ; chaque état de 6.3 bis ; lien absent sans bouton | widget |
| Aucune pièce ni contact dans la liste ni dans un export | SQL (colonnes de la RPC de liste) et widget |
| Clair et sombre, 360, 768 et 1440 | widget |
| Navigation au clavier, focus visible, libellés accessibles | widget |

**Flutter** : tests de widget par écran neuf, dans les états de la section 10.3,
en RTL et à 200 %, au clavier ; portail `/attente` étendu ; composants promus
dans la galerie (`test/widgets/catalogue_galerie_test.dart`).

**Non-régression** : la référence est remesurée sur `9cf88561` avant le lot et
le chiffre écrit. La dernière mesure écrite (19/10, `C/08:96`) donne 108 scénarios
SQL sur 109, `af_liste_blanche_volatiles` en échec connu, antérieur ; celle du
18/10 (`C/08:94`) donnait 107 sur 107 et 15 218 tests Flutter. Invitations,
inscription sur invitation, accords, ADM-02, import du 12/10, Comptable (CPT-02),
affectation par `tc_verifier` gardent leurs tests ; `dart analyze --fatal-infos`
propre ; `tool/verifier_jetons.dart` sans violation nouvelle.

---

## 13. Ce qui peut avancer sans attendre

1. **Fait par ce lot** : la spécification versionnée, cette revue, `LIRE_D_ABORD.md`,
   et le contrat attendu (`CONTRAT_PORTS_CANDIDATURES.md`,
   `DEPENDANCES_BACKEND.md`), que la spec §1.2 autorise pendant la phase
   « frontend seul » : une proposition, sans code, dont chaque méthode cite la
   question qui la conditionne.
2. **Après `CAND-Q01` à `CAND-Q03`** : la spécification verticale consolidée,
   puis `C/CATALOGUE_ECRANS_RECRUTEMENT.md` avec ses fiches, puis les maquettes
   (bureau, tablette, mobile, clair et sombre).
3. **Après `CAND-Q02`** : le lot backend borné sur la base de test, avec ses
   scénarios, puis les écrans.
4. **Après `CAND-Q05`** : le référentiel de compatibilité de paiement.
5. **Après `CAND-Q15`**, indépendamment du module : les correctifs courts, la
   langue enregistrée par son code d'abord, puis l'affectation `c11bis`, puis
   `creer_groupe` (ordre et raisons dans `CORRECTIFS_HORS_MODULE_PROPOSES.md`,
   section 2).

Rien d'autre ne commence, et aucun écran ne se branche sur des données fictives
hors du mode démonstration.

---

## 14. Ce que la première version de cette revue disait de faux

Écrite contre `main` (22/09) avant d'avoir vu la pile, elle est retirée. Ses
erreurs, pour que personne ne les reprenne :

- elle affirmait que l'inscription publique d'un enseignant existait : elle est
  fermée depuis le 17/10, seule l'invitation ouvre la porte ;
- elle affirmait que l'activation ne vérifiait pas le contrat : la garde `0089` le
  fait, testée ;
- elle opposait aux polices de la spec Bricolage Grotesque et Instrument Sans : la
  règle en vigueur est bien DM Sans et Plus Jakarta Sans (M-15) ;
- elle tenait `active` pour seul critère d'affectabilité : `tc_verifier` vérifie
  pièce, langue, genre et plafond (les défauts réels sont ailleurs, section 3.2) ;
- elle proposait l'entretien en salle « sans toucher au service de jetons » : le
  jeton refuse un compte en attente, et une séance déclenche la paie ;
- elle disait qu'aucun import, aucune recherche partagée et aucune action groupée
  n'existaient : l'import du 12/10, `ChampRecherche` et le motif d'interface du
  Comptable existent ;
- elle tenait le domaine Finance pour inerte et la traduction arabe pour vide ;
- elle rangeait ses fichiers et ses questions dans des documents archivés
  (`HANDOFF`, `PROGRESS`, `decisions.md`).

La version intermédiaire de ce document, avant vérification adverse, contenait
aussi trente-huit imprécisions, corrigées ici. Les plus lourdes : un refus de
pièce ne désactive pas un candidat encore en attente ; aucune règle en vigueur
n'interdit à un contrôleur d'enseigner ; le contrôle préalable groupé du
Comptable n'a pas de source serveur ; trois citations du dossier maître étaient
des paraphrases.
