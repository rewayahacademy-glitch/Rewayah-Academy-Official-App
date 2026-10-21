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
produit), une comparaison ligne à ligne avec la première version, et une lecture des
formulaires Drive limitée à leur structure et à des comptes agrégés (section 2).
Chaque fait porte sa preuve selon la taxonomie de `docs/current/00_LIRE_D_ABORD.md` :
**[S]** spécifié seulement, **[C]** présent dans le code, **[T]** testé.

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
   (`M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:47-50`), et un
   refus fait passer l'enseignant à `disabled` (`:51-60`). La garde
   `M/0089_teacher_contract_activation_guard.sql` empêche bien d'activer sans
   contrat ni accusé signés [C][T] ; mais aucun entretien, aucun engagement, aucun
   contrôle de paiement ne s'intercale. **C'est le conflit central** avec la
   « salle 3 » (question `CAND-Q01`). Circonstance favorable : la décision est
   aujourd'hui **fermée en production côté Flutter** (AD-M3-PROD,
   `lib/features/admin_dossiers/revue_dossier.dart:33-36`). Personne n'est donc
   admis par l'application en ce moment : c'est le bon moment pour séparer les deux
   décisions.

3. **« Frontend seul » est faisable, mais rien ne sera utilisable.** Le dépôt a
   déjà le motif qui respecte la spec §1.2 : un port, un pont de démonstration, et
   `CapaciteIndisponible` en production (« Disponible au branchement serveur »,
   `C/CATALOGUE_ECRANS_DIRECTION.md:9-11`). Mais §7 (un candidat ne voit que sa
   candidature) et §13 (la salle 3 se refuse) ne tiennent qu'en base : « une UI
   cachée ne remplace jamais une policy » (`C/02_ARCHITECTURE_ET_SECURITE.md:19`).
   Depuis le 17/10, Claude fait aussi le backend, migrations sur la base de test
   seulement et sur feu vert explicite (`CLAUDE.md:30`, `CLAUDE.md:45-46`). La
   spec, plus récente, l'interdit sans autorisation : il faut cette autorisation
   (`CAND-Q02`).

4. **Les 418 candidats des formulaires n'ont ni compte ni invitation.** La
   candidature commence donc **avant** l'invitation : une ligne importée,
   préexaminée par la direction sur ses réponses, puis invitée. Or l'invitation
   exige un courriel, et 32 réponses n'en ont pas (section 2). `CAND-Q03`.

5. **L'entretien en visio ne peut pas réutiliser la salle tel quel.** Le jeton
   vidéo exige un compte `active` ou `provisional_active`
   (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`),
   donc un candidat `pending_kyc` n'entre pas. Et une ligne `sessions` qui servirait
   d'entretien déclencherait la paie de l'intervieweur à la clôture
   (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`), la clôture
   automatique, et l'exclusion de chevauchement. Deux voies, section 6.3
   (`CAND-Q06`).

6. **Le paiement est un référentiel à créer, pas un prestataire à brancher.**
   Aucun prestataire de versement n'est choisi (`C/07_MEMOIRE_PEDAGOGIE_FINANCE.md:20`,
   `:38`) ; le dossier maître dit de pawaPay « envisagé », « candidat par
   corridor », « aucune activation constatée » (`DM:7497`, `DM:7941`, `DM:7953`).
   « pawaPay confirmé » (spec §4.4) demande une décision datée. Le client a déjà
   les types (`CorridorPayout`, `CapacitePayout`,
   `lib/core/capacites/port_capacite_payout.dart:17-48`) ; il leur manque une
   source serveur (`CPT-BR-10`). Et la liste des pays proposés ne contient ni
   l'Arabie saoudite ni le Yémen, alors qu'environ la moitié des candidats y
   indiquent leur numéro (`CAND-Q05`).

7. **Le vocabulaire de la spec entre en collision avec des mots décidés.**
   « Vivier » désigne la réserve d'élèves d'une offre horaire (`M/0043`,
   `lib/core/offres/offre_horaire.dart:133`) ; « salle » est la salle de cours
   unique `/salle` ; « engagement » est l'engagement envers une classe ; « Je
   certifie » heurte la décision M-10 ; « admin » ne s'écrit pas à l'écran
   (`.claude/skills/mots-rewayah/SKILL.md`). `CAND-Q12`.

8. **Ce que la spec a raison d'exiger et qui est déjà tenu** : polices DM Sans et
   Plus Jakarta Sans (M-15, `lib/core/theme/app_typography.dart:33-36`), thème
   sombre complet, cloisonnement par genre de la lecture des pièces en base,
   import sans création de compte, trace chaînée des décisions.

---

## 1. Sources lues

Gouvernance : `CLAUDE.md`, `AGENTS.md`, `C/00_LIRE_D_ABORD.md`, `C/08` (§5 bis),
`C/04`, `C/06`, `C/DESIGN-GOV-2026-09-26.md`, `C/DECISION-ENTREE-2026-10-17.md`,
`C/REVUE-DIRECTEUR-2026-10.md`, `C/REGISTRE-RECONCILIATION-2026-10-14.md`,
`docs/orchestration/PASSATION-2026-10-17.md`, compétences `mots-rewayah` et
`programme-rewayah`. Décisions : toutes les `C/DECISION-*.md`, le dossier maître
du 14/10, `C/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md`. Finance :
`C/DECISION-TARIFS-2026-10-18.md`, `C/tarifs-2026-10-18.json`, `C/07`,
`C/CATALOGUE_ECRANS_COMPTABLE.md`, `C/ENS-PAYS-1_BR.md`. Interface :
`C/03_DESIGN_SYSTEM_ET_UX.md`, `C/AD-X_DECOUPAGE.md`, `C/UX_REVIEW_FILTRES-1.md`,
`lib/core/widgets/`. Puis le code et les migrations cités ligne à ligne.

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
| Consentement au contact | WhatsApp, 100 % | non |
| Pièce d'identité | non | photo, sous forme de lien Drive |

**Conséquence directe** : aucune des 418 personnes ne peut être admissible en
salle 2 à partir de ses seules réponses. Pays de paiement, moyens de réception,
publics, fuseau et engagement manquent partout. L'import sert à **préexaminer et
inviter**, pas à préqualifier.

### 2.3 Les chiffres qui changent la spec

**Pays (déduits de l'indicatif, donc indicatifs) :** Arabie saoudite environ 210,
Nigeria 131 (une dizaine de plus au format national nigérian), Yémen 12, Tchad 7,
Sénégal 5, Niger 5, Guinée 3 dans A (et 6 numéros de B au format guinéen
probable), Burkina Faso 3, Kenya 3 ; une vingtaine d'autres pays à moins de trois
chacun.

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
| Courriels absents ou suspects | 32 absents, quelques fautes de domaine, une adresse jetable, un numéro saisi à la place | un courriel invalide n'est ni une clé de rapprochement ni une adresse d'invitation |
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
| 3. Portail d'attente | `/attente`, confiné par le routeur ; état lu dans `etat_dossier()` (statut, pièce, contrat, accusé, usage) ; `EtapeDossier` à cinq valeurs | [C][T] `lib/core/router/redirection.dart:149-174`, `M/20261017180000_l5_01_usage_inscription.sql:115-125`, `lib/core/dossier/etat_dossier.dart:217-245` |
| 4. Accords | une seule page `/attente/accords`, une case par texte, « Suivant » inactif tant qu'il en manque une : texte d'information, contrat `teacher_nda` (version `2026-10-jur`, signature par nom tapé et empreinte), article 9 | [C][T] `lib/features/dossier/accords_page.dart:55-97`, `C/DECISION-ENTREE-2026-10-17.md:28-33`, `M/0086_signature_contrat_versionnee.sql`, `M/0092_publish_teacher_contract_2026_10_jur.sql:43` |
| 5. Pièce d'identité | dépôt vers le coffre R2 par fonction Edge, 8 Mo | [C] `supabase/functions/piece-identite-depot/index.ts`, `lib/core/dossier/service_dossier.dart:105` |
| 6. Revue et décision | ADM-02 : lecture cloisonnée par genre (exception super-admin journalisée), une seule décision par pièce, motif obligatoire au refus ; approbation : `active` ; refus d'un enseignant : `disabled`. **Décision fermée en production côté Flutter** (AD-M3-PROD) | [C][T] `M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:21-65`, `M/0088_kyc_super_admin_gender_exception.sql`, `lib/features/admin_dossiers/revue_dossier.dart:33-36` |
| 7. Garde d'activation | aucune activation sans `teacher_nda` et `recording_and_control_notice` signés aux versions requises ; le code de conduite n'y figure pas | [C][T] `M/0089_teacher_contract_activation_guard.sql:24-82`, `T/scenarios_etape3.sql:862-892`, `M/20261018160000_pe_protection_enfants.sql:19-22` |
| 8. Prérequis de travail | photo, langues, fuseau, disponibilités, calculés en base | [C][T] `M/20261016100500_contrats_travail_prerequis.sql:49-74`, `T/scenarios_contrats_seance.sql` |
| 9. Code de conduite | sorte `teacher_conduct_code`, version `2026-10-19`, accepté depuis le profil par un enseignant **actif** | [C][T] `M/20261019100000_pe_code_conduite_v2.sql:16-20`, `M/20261018160000_pe_protection_enfants.sql:363-374` |
| 10. Affectation à une classe | prédicat commun : statut valide, `access_until`, KYC approuvé ; `tc_verifier_affectation_enseignant` ajoute langue, genre de la classe, plafond hebdomadaire | [C][T] `M/0082_teachers_for_class.sql:54-77` |

Ce que le parcours **ne contient pas** : préqualification, questionnaire,
évaluation de l'enseignant, entretien, engagement religieux, compatibilité de
paiement, décision finale distincte de la pièce, pause, retrait, réouverture.
`lib/features/demo/recrutement_demo.dart` n'est qu'une démonstration
d'invitations et de signatures, avec des données fictives jamais envoyées au
serveur (`:1-4`).

### 3.2 Défauts trouvés en passant, hors du périmètre de ce module

Ils comptent parce que « prêt à être affecté » n'a pas aujourd'hui de chemin
serveur fiable. Aucun n'est corrigé ici (`CAND-Q15`).

- `creer_groupe` à huit arguments, seul chemin vivant pour poser un enseignant sur
  une classe, ne vérifie que le rôle, la suppression et `account_status` : ni KYC,
  ni langue, ni genre (`M/0045_disambiguate_creer_groupe_overloads.sql:24-32`) [C].
- `affecter_enseignant_classe` est révoquée
  (`M/20261017120600_af_l3_06_rpc_uniques.sql:19-20`), et sa remplaçante
  `affecter_enseignant_classe_c11bis` lève toujours « compatibilite enseignant non
  verifiable » (`M/0079_c11bis_admin_wrappers.sql:126-129`) [C].
- Le franc guinéen compte zéro décimale côté client
  (`lib/core/finance/format_montant.dart:37`) mais pas côté serveur
  (`M/20261012120101_x2_17_treasury_triggers.sql:142`) [C].
- `provisional_active` n'est posé par aucune RPC du parcours enseignant ; la
  colonne `kyc_completion_deadline` de l'ancien ADR-014 n'existe pas.
- La plupart des scénarios SQL de ce domaine ne sont pas rejoués en CI
  (`af_l1_11`, `af_l1_05`, `contrats_invitations`, `pe_*`, `imm_*`) : la CI ne cite
  qu'une liste fixe, et ne tourne que pour une PR vers `main`, `ccr-*` ou `ui/**`
  (`.github/workflows/ci.yml:8-17`).

### 3.3 Compétences de l'enseignant : ce que la base sait dire

| Donnée de la spec | État |
| :--- | :--- |
| Langues | `teacher_profiles.languages text[]`, choisies côté client dans `langues_cours` (trois langues), comparées à `langue_code` à l'affectation [C] |
| Pays | `teacher_profiles.country`, texte, saisi parmi 19 pays ; destiné à l'affichage public sur la carte de l'enseignant (`C/ENS-PAYS-1_BR.md:3`) [C][S] |
| Fuseau | `timezone_iana` [C] |
| Genre | `profiles.gender`, colonne privilégiée réservée à la direction (`M/20261017100700_af_l1_07_genre_colonne_privilegiee.sql:27`) [C] |
| Disponibilités | `weekly_availability`, déclarées par un enseignant actif [C] |
| Photo, titre Sayyid ou Sayyida | `M/0030_tc_socle.sql:180-183` [C] |
| Mémorisation, tajwid, ijaza, riwaya, expérience, publics, pays de paiement, pays d'origine | **absents** |

### 3.4 Interface d'administration

| Besoin de la spec | Ce qui existe | Écart |
| :--- | :--- | :--- |
| Placement | domaine **Personnes**, six onglets : Dossiers, Comptes, Invitations, Reprises, Import, Suppressions (`lib/core/admin/admin_domaine.dart:266-293`) ; huit domaines au plus (`lib/core/widgets/admin_shell.dart:90-94`) | un septième onglet, ou l'onglet Invitations élargi (`CAND-Q04`) |
| Liste dense | `DataCollection<T>`, rendu paresseux, `piedDePage` pour charger la suite (`lib/core/widgets/data_collection.dart:100-188`) | **pas de tri par colonne**, pas de multisélection native |
| Recherche | `ChampRecherche` (`lib/core/widgets/champ_recherche.dart:20`), page `/recherche`, recherche exacte par matricule avec quota | réutilisable tel quel |
| Filtres | `FilterPill`, `RangeeFiltres` (trois puces puis « Plus »), `MenuFiltre<T>` à une valeur par axe | onze axes de filtre (spec §8.1) sur trois puces visibles : hiérarchiser |
| Filtres dans l'adresse | au cas par cas (`?filtre=echus` sur Comptes) ; l'identifiant d'une personne n'entre jamais dans l'URL (`C/AD-X_DECOUPAGE.md:117`) | les raccourcis d'Accueil vers un filtre d'étape sont possibles, le dossier passe par `extra` |
| Pagination | par page avec total (Regroupements, testé à 10 000 lignes, `test/features/admin_regroupements/echelle_listes_test.dart`) ou par curseur (Bibliothèque CAP29-A) | réutilisable |
| Tri | `MenuFiltre<TriFile>` côté client (`lib/features/admin_traitement/traitement_page.dart:176-190`) | réutilisable |
| Actions groupées | **précédent complet dans le Comptable** (CPT-02) : case par ligne via une colonne `rendu`, `BarreSelection` annoncée au lecteur d'écran, contrôle préalable serveur qui rend les éligibles et les **exclus avec leur raison**, clé d'idempotence, suivi ligne par ligne, issue inconnue dite honnêtement (`lib/features/comptable/paiements/`) | propre au Comptable : à promouvoir en composant partagé, jamais à recopier (DESIGN-GOV : composants jamais forkés) |
| Historique d'un dossier | `journal_audit()` ne filtre pas par ligne ; précédent par objet : `historique_classe(uuid)` (`M/20261016100100_contrats_fusion_classes.sql:227`) | une RPC `historique_candidature` sur ce modèle |
| Modale | `showDialog` interdit hors deux fichiers (`tool/verifier_jetons.dart:306-316`) ; `AppBottomSheet.ouvrir` ; `ConfirmDestructive` sans champ motif | l'aperçu d'un lot et le mappage d'import sont des pages |
| CTA d'entretien sur chaque ligne | règles : toute la carte est cliquable (`C/DECISION-ENTREE-2026-10-17.md:17`), un seul bouton plein par écran (K-56, `C/REVUE-DIRECTEUR-2026-10.md`), `ctaSeance` existe pour les états de séance | le CTA visio devient un lien secondaire de la ligne, pas un bouton plein (`CAND-Q14`) |

### 3.5 Import

L'import des inscriptions du 12/10 existe et sert de modèle [C][T] :
analyse du CSV **côté serveur**, essai à blanc avec motifs de rejet ligne par
ligne, confirmation idempotente, journalisation, capacité réservée à la direction
en double vérification (aal2)
(`M/20261012184501_imm_accueil_dry_run.sql`,
`M/20261012185025_imm_accueil_confirmation_idempotente.sql`,
`M/20261018200000_imm_import_ecran.sql:14-40`,
`lib/features/admin_import_inscriptions/`). Il n'active rien, ce qui est conforme
à la spec §9.

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
  désactivé, aucune fonction Edge d'envoi, aucun jeton push. Les notifications
  internes, les messages métier et les annonces exigent un compte valide : un
  candidat `pending_kyc` ne reçoit rien [C].
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
  48 h après modification [S] (`C/sources-directeur-2026-10/OFFRE_ET_TARIFS_2026-10-18.md:148`) ;
  aucune de ces règles n'est dans le code.
- Prestataire : **aucun choisi** (`C/07_MEMOIRE_PEDAGOGIE_FINANCE.md:20`, `:38`).
  Stripe ne sert qu'à l'encaissement des familles.
- `payout_methods(kind text, details jsonb not null)` : ni pays, ni opérateur, ni
  devise, ni état ; `details` obligatoire, donc aucune « déclaration sans
  coordonnées » possible ; **l'enseignant ne lit ni n'écrit ses propres moyens**
  [C][T] (`M/20261017100200_af_l1_02_policies_foyer_role_tuteur.sql:43-58`).
- `payouts` pend d'un portefeuille de foyer et aucune RPC n'en crée [C].
- Client : `PortMesMoyensPaiement` (saisie par jeton opaque, jamais de numéro),
  `CorridorPayout`, `CapacitePayout`, `DestinationMasquee` existent ; en
  production, `CapaciteIndisponible('CPT-BR-16')` et `CPT-BR-10` sans source [C].

---

## 4. Écarts entre la pointe, les décisions en vigueur et la spec

| # | Écart | La spec | La pointe | Proposition |
| :-- | :--- | :--- | :--- | :--- |
| E1 | Admission | salle 3 = pièce **et** entretien **et** engagement **et** paiement **et** décision finale | approbation de la pièce = compte `active` | séparer : la pièce pose `kyc_status`, l'activation devient l'entrée en « prêts », garde `0089` conservée (`CAND-Q01`) |
| E2 | Refus | « refusé avec motif », réouvrable ; « à compléter » distinct | refus de la pièce d'un enseignant = `disabled` ; aucun « à corriger » | le refus de pièce devient « à corriger » ; le refus de candidature est un état de la candidature, réouvrable (`CAND-Q01`) |
| E3 | Ordre candidature / compte | la candidature précède le compte | le compte `pending_kyc` naît à la consommation de l'invitation | la candidature importée précède l'invitation ; après l'invitation, candidature et compte avancent ensemble (`CAND-Q03`) |
| E4 | Portail candidat | portail confidentiel | `/attente`, partagé avec le tuteur, déjà confiné | le portail candidat **est** `/attente`, avec des pas de plus |
| E5 | Frontend seul | aucun backend sans autorisation | Claude fait le backend depuis le 17/10, base de test, feu vert explicite | autorisation d'un lot borné (`CAND-Q02`) |
| E6 | Hiérarchie des sources | §1.1 cite la Bible V2 au rang 4 | Bible V2 archivée ; autorité visuelle : DESIGN-GOV, puis DECISION-ENTREE qui prévaut ; la demande la plus récente du directeur prévaut | la spec étant la demande la plus récente, elle prévaut là où elle tranche ; DESIGN-GOV et DECISION-ENTREE régissent le reste |
| E7 | Prestataire | pawaPay « confirmé et utilisable » | « envisagé », « candidat par corridor », « aucune activation constatée » | décision datée à verser dans `docs/current/` (`CAND-Q05`) |
| E8 | Pays | Nigeria, Côte d'Ivoire, Sénégal | 19 pays proposés, sans Arabie saoudite ni Yémen ; pays unique, public | pays de résidence et pays de versement distincts, liste ISO élargie (`CAND-Q05`) |
| E9 | Paiement éliminatoire | aucune méthode compatible = pas de salle 3 | proposition E04 du dossier maître : dette enseignant enregistrée à défaut (`DM:7943`), au statut de proposition | la spec, décision du 21/10, prévaut sur une proposition ; à acter |
| E10 | Évaluation | « selon le référentiel existant » | le seul référentiel évalue des élèves | constat d'entretien structuré (`CAND-Q08`) |
| E11 | Entretien vidéo | CTA « Rejoindre la visio » | jeton refusé à `pending_kyc` ; effets de bord d'une `sessions` | deux voies, section 6.3 (`CAND-Q06`) |
| E12 | Notifications | modèle de notification, messages individuels | aucun canal, rien pour un compte en attente | constat manuel « prévenu le » (`CAND-Q10`) |
| E13 | Engagement | texte proposé, version, date | quatre sortes d'accord ; le code de conduite n'est acceptable que par un enseignant actif | cinquième sorte, acceptable en attente, sur la page unique des accords (`CAND-Q11`) |
| E14 | Import | 400 candidatures, mappage de colonnes | import du 12/10 : en-têtes figés, deux CSV, B déjà dans son périmètre | un import « candidatures » sur le même motif serveur, B exclu (section 7) |
| E15 | Vocabulaire | salles, vivier, engagement, « Je certifie » | mots déjà pris ou interdits | `CAND-Q12` |
| E16 | Langues | « compétences » | trois langues de cours ; offre du 18/10 plus large | la langue se choisit dans le référentiel ; une langue absente est une décision, pas une saisie libre |
| E17 | CTA par ligne | CTA séparé, immédiatement visible | carte entièrement cliquable, un seul bouton plein | lien secondaire dans la ligne (`CAND-Q14`) |
| E18 | Polices et thème | DM Sans, Plus Jakarta Sans, clair et sombre | identique (M-15, LT-THEME) | rien à faire |

---

## 5. Doublons, risques et dépendances

### 5.1 Doublons à ne pas créer

| Tentation | Ce qui existe | Règle |
| :--- | :--- | :--- |
| Un portail `/candidature` | `/attente` et `/attente/accords` | étendre `etat_dossier()` ; jamais recalculer l'étape à l'écran |
| Un second mécanisme d'invitation | `invitations_enseignant` et ses quatre RPC ; le même motif existe pour le comptable | l'invitation devient une **action** sur une candidature |
| Une table « engagements » | `contract_acceptances` et `contract_required_versions` | une sorte d'accord de plus |
| Un second import | l'import du 12/10 | même motif serveur (analyse, essai à blanc, confirmation idempotente, aal2) ; nouveau type de fichier, pas nouveau mécanisme |
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
| R3 | Changer `decider_dossier()` affaiblit la garde des contrats | élevé | l'activation reste soumise à `0089`, par déclencheur, quelle que soit la RPC qui l'opère |
| R4 | Un entretien posé en `sessions` paie l'intervieweur, se ferme seul ou apparaît dans la Journée | élevé | type de séance dédié, exclu de la paie, de la clôture, du chevauchement et des vues (voie 2) |
| R5 | Données personnelles dans les listes, les journaux ou l'import | élevé | colonnes masquées en base ; le journal porte la référence source, pas le nom |
| R6 | Un état laisse croire qu'un message est parti | moyen | « à prévenir » tant que la direction n'a pas noté « prévenu le » |
| R7 | Un critère change après l'arrivée des candidatures | moyen | réponses versionnées par questionnaire |
| R8 | La matrice passe « confirmé » sur une liste marketing | moyen | « confirmé » exige une date et un responsable |
| R9 | Le genre décide d'un droit à l'écran | élevé | cloisonnement en base, comme `read_kyc_documents()` |
| R10 | Une candidate ne trouve pas d'intervieweuse | moyen | règle de genre et exception super-admin décidées avant le premier entretien (`CAND-Q07`) |
| R11 | Les scénarios SQL du module ne tournent pas en CI | moyen | `.github/` est une zone interdite aux agents : la direction les ajoute à `ci.yml`, sinon `tool/rejouer_scenarios.sh` |

### 5.3 Dépendances backend (à autoriser, pas à contourner)

1. Tables candidature et type de candidature, réponses versionnées, décisions,
   entretiens ; RLS : le candidat ne lit que sa candidature, la direction selon
   son genre.
2. RPC de transition, une par geste, chacune motivée quand il le faut et
   journalisée, avec contrôle des prérequis **en base**.
3. RPC de confirmation qui active le compte, et modification de
   `decider_dossier()` pour le rôle enseignant (`CAND-Q01`).
4. Sorte d'accord `teacher_religious_commitment` (nom à valider), version requise,
   insertion autorisée à un compte `pending_kyc` invité.
5. Import « candidatures » : analyse serveur, essai à blanc, confirmation
   idempotente par référence source, capacité aal2.
6. Invitation par lot depuis des candidatures, sur le contrôle préalable du
   Comptable (éligibles, exclus avec raison, idempotence).
7. Référentiel de compatibilité de paiement, source de `CPT-BR-10`.
8. RPC `historique_candidature`.
9. Si la voie 2 de l'entretien est retenue : type de séance, rôles de
   participants, règle de jeton pour un candidat convoqué, exclusions (paie,
   clôture, vues, mention de contrôle).
10. Un canal d'envoi, si l'invitation doit partir de l'application.

---

## 6. Modèle proposé et alternatives

### 6.1 Le moteur générique

| Option | Ce que c'est | Verdict |
| :--- | :--- | :--- |
| A. Constructeur de formulaires | étapes, champs, critères et transitions entièrement en données | écartée : c'est le « constructeur prématuré » que refuse la spec §0, et un critère éliminatoire ne se vérifie plus en base |
| B. Pipeline enseignant codé en dur | tables et écrans propres à l'enseignant | écartée par la décision 1 de la spec §15 |
| **C. Squelette générique, règles par type** | une candidature porte un **type** ; le type désigne un jeu d'étapes fermé et une liste de **contrôles nommés**, calculés en base ; les réponses sont un document versionné par type | **recommandée** |

Le type « enseignant » exige six contrôles : `piece_validee`, `accords_signes`
(contrat, accusé, engagement), `entretien_conclu`, `paiement_compatible`,
`profil_unique`, `aucune_restriction`. Un type « comptable » en exigerait
d'autres ; aucun contrôle d'un type ne s'applique à un autre (spec §2.2). Le
précédent de l'invitation comptable (`M/20261017160200_bf1_03_invitation_comptable.sql`)
montre que deux types partagent déjà le même mécanisme d'entrée.

### 6.2 Étape, état, et dimensions séparées

La liste de onze statuts de la spec mélange l'étape et ce qui l'arrête. Les
séparer rend les transitions vérifiables.

| Dimension | Valeurs proposées | Porté par |
| :--- | :--- | :--- |
| Étape | `recue`, `invitee`, `prequalification`, `verifications`, `confirmee` | la candidature |
| État dans l'étape | `a_completer`, `en_examen`, `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente` | la candidature |
| Issue | `en_cours`, `refusee`, `retiree` ; terminales mais réouvrables par geste motivé | la candidature |
| Pause | drapeau, motif, date de reprise facultative ; ne change pas l'étape | la candidature |
| Pièce d'identité | lue dans `kyc_documents`, jamais recopiée | existant |
| Paiement | `inconnu`, `compatible`, `incompatible`, `a_verifier`, calculé | réponses et référentiel |
| Disponibilité opérationnelle | après confirmation seulement | `teacher_profiles` |
| Affectation | lue dans les classes | existant |
| Coordonnées financières | `absentes`, `enregistrees` ; jamais exigées avant le premier cours | CPT-13 |

Correspondance : « Invitation envoyée » = `invitee` ; « Informations à
compléter » = `a_completer` ; « Préqualification » et « Vérifications » = les
étapes du même nom en `en_examen` ; les trois états d'entretien et « décision
finale en attente » appartiennent à `verifications` ; « Confirmé / prêt à être
affecté » = `confirmee` ; « Refusé », « Retiré » = l'issue ; « En pause » = le
drapeau. `recue` est l'étape que la spec n'a pas : la candidature importée, avant
toute invitation.

### 6.3 L'entretien vidéo : deux voies

| Voie | Ce qu'il faut | Pour | Contre |
| :--- | :--- | :--- | :--- |
| 1. Hors de l'application, par WhatsApp | l'application enregistre date, heure, fuseaux, intervieweur, issue et compte rendu ; aucun bouton visio | aucun changement de la salle ni du jeton ; les 418 candidats ont tous consenti au contact WhatsApp ; utilisable pour la première vague | contredit la décision 8 de la spec §15 (CTA visio dans la vue d'entretien) ; aucun contrôle de qui entre |
| 2. Dans `/salle` | type de séance `entretien`, rôles candidat et intervieweur ; jeton autorisé à un candidat `pending_kyc` convoqué ; exclusion de la paie, de la clôture automatique, du chevauchement, de `mes_seances_v`, de l'observation par le contrôleur ; mention de séance propre à l'entretien ; chemin du routeur depuis `/attente` | aucun lien partageable ; même salle que les cours ; l'état « session disponible » se mesure | touche la garde du jeton et le déclencheur de paie : migration et revue de sécurité |

**Recommandation :** voie 1 pour la première vague, sans bouton qui prétendrait
ouvrir une visio (« un bouton qui ne peut pas aboutir n'est pas rendu ») ; voie 2
comme lot daté, si le directeur maintient le CTA intégré. Ni l'une ni l'autre ne
refond LiveKit.

L'enregistrement audio est supprimé pour l'instant
(`C/DECISION-ENTREE-2026-10-17.md:33`) : un entretien n'est pas enregistré, et doit
le dire. La mention de contrôle de la salle ne s'y applique pas (`CAND-Q09`).

### 6.4 La compatibilité de paiement

Un référentiel serveur sur le motif de `langues_cours` : pays (ISO), méthode
(`virement_bancaire`, `mobile_money`), opérateur, devise, type de décaissement,
état (`confirme`, `en_verification`, `indisponible`), date et responsable de la
vérification, notes ; écriture par la direction et la comptabilité, lecture par
un candidat des seules lignes confirmées de son pays de versement. Il devient la
source de `CorridorPayout` et `CapacitePayout`, déjà dans le client. Le
prestataire est une colonne de données (« aucun prestataire n'est codé comme
obligatoire », `lib/core/capacites/port_capacite_payout.dart:5-8`).

- Le candidat **déclare des capacités** (pays de résidence, pays de versement,
  compte bancaire oui ou non, opérateurs accessibles), choisies parmi les lignes
  confirmées : c'est une réponse de candidature, jamais une ligne de
  `payout_methods`.
- `paiement_compatible` est vrai si une capacité déclarée, puis confirmée par la
  direction, croise une ligne `confirme`. Une ligne `en_verification` ne prouve
  rien.
- La préférence bancaire est un **tri secondaire nommé**, jamais un score.
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
   rejets et avertissements ligne par ligne, confirmation idempotente, capacité
   aal2, journal portant la référence source (classeur, onglet, horodatage), jamais
   le nom.
4. **Rapprochement** par courriel **ou** téléphone normalisés, proposé, appliqué
   par un geste ; pour un groupe aux réponses divergentes, la ligne la plus récente
   est proposée (`CAND-Q16`).
5. **Ce qu'une ligne importée ne fait jamais** : créer un compte, émettre une
   invitation, valider une pièce, accepter un accord, entrer en `prequalification`.
   Elle entre en `recue`. L'invitation est un geste ultérieur, et il exige un
   courriel valide.

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
| `prequalification/a_completer` | `prequalification/en_examen` | le candidat | questionnaire complet pour la version courante ; accords signés, engagement compris | non |
| `prequalification/en_examen` | `prequalification/a_completer` | direction | ce qui manque est nommé au candidat | **oui** |
| `prequalification/en_examen` | `verifications` | direction | engagement accepté à la version requise | non |
| `verifications/*` | `entretien_planifie` | direction | date, heure, fuseau connu, intervieweur nommé (genre selon `CAND-Q07`) | non |
| `entretien_planifie` | `entretien_a_planifier` | direction | entretien annulé ou manqué ; la trace reste | **oui** |
| `entretien_planifie` | `decision_en_attente` | intervieweur | compte rendu enregistré | non |
| `decision_en_attente` | `confirmee` | direction | les six contrôles vrais ; active le compte sous la garde `0089` | non |
| tout état en cours | `refusee` | direction | motif interne ; message au candidat par modèle distinct | **oui** |
| tout état en cours | `retiree` | le candidat ou la direction | entretien planifié annulé | facultatif |
| tout état | pause activée ou levée | direction | l'étape ne change pas | **oui** à l'activation |
| `refusee`, `retiree` | étape d'origine | direction | contrôles revérifiés | **oui** |
| `confirmee` | `confirmee` + restriction | direction, ou automatique si un contrôle tombe | sort de l'affectabilité ; l'historique reste | **oui** |

**Blocages durs** : entrer en `confirmee` avec un contrôle faux ; confirmer ou
inviter en lot une ligne non éligible ; importer ailleurs qu'en `recue` ; exposer
une pièce d'identité dans une liste.

**Ce qui ne rétrograde jamais** : une indisponibilité temporaire, une pause, un
critère changé après une décision.

---

## 9. Questions au directeur

Format du registre de marque : une question ouverte n'est tranchée par aucun
agent ; quand le directeur tranche, une décision datée est versée dans
`docs/current/` et une ligne datée s'ajoute au §5 bis de `C/08`. Les questions
marquées **bloquante** empêchent tout lot du module.

| ID | Question | Pourquoi elle compte | Recommandation | Ce qui débloque |
| :--- | :--- | :--- | :--- | :--- |
| `CAND-Q01` **bloquante** | Pour un enseignant, l'approbation de la pièce cesse-t-elle d'activer le compte, l'activation devenant l'entrée en « prêts à être affectés » ? Le refus de la pièce devient-il « à corriger » plutôt que `disabled` ? | Sans cela, l'enseignant est affectable avant tout entretien ; la salle 3 n'a pas de sens | Oui aux deux, garde `0089` conservée ; la décision étant fermée en production, aucun enseignant n'est admis entre-temps | Décision datée |
| `CAND-Q02` **bloquante** | Le module reste-t-il « frontend seul », ou un lot backend borné (section 5.3, points 1 à 8) est-il autorisé sur la base de test ? | §7 et §13 de la spec ne tiennent qu'en base | Autoriser le lot borné ; en attendant, seulement des fiches et des maquettes | Feu vert explicite |
| `CAND-Q03` **bloquante** | La candidature commence-t-elle avant l'invitation (`recue`, préexamen sur les réponses importées), l'invitation devenant une action ? Le courriel est-il obligatoire pour être invité ? | 418 personnes sans compte ; 32 sans courriel | Oui ; le courriel manquant se demande par WhatsApp | Décision datée |
| `CAND-Q04` | Le module est-il un septième onglet de Personnes, ou l'onglet Invitations devient-il « Candidatures », l'invitation y étant une étape ? | Personnes a déjà six onglets ; deux listes pour la même personne divergeraient | Élargir Invitations en Candidatures | Décision datée |
| `CAND-Q05` **bloquante pour la salle 3** | pawaPay : décision datée « choisi » ou « candidat par corridor » ? Quels pays vérifier d'abord ? Comment verse-t-on à un candidat résidant en Arabie saoudite ? L'absence de méthode compatible reste-t-elle éliminatoire (spec) face à la proposition E04 d'une dette enseignant ? | Sans corridor confirmé pour l'Arabie saoudite, la moitié du vivier réel n'atteint pas la salle 3 | Ordre : Arabie saoudite, Nigeria, puis Guinée, Sénégal, Côte d'Ivoire ; la spec prévaut sur E04 ; élargir la liste des pays (ISO) | Décision datée et liste de corridors vérifiés |
| `CAND-Q06` | Entretien : voie 1 (WhatsApp, rien dans la salle) pour la première vague, puis voie 2 (dans `/salle`) ? | La décision 8 de la spec demande un CTA visio intégré | Voie 1 maintenant, voie 2 en lot daté | Décision datée |
| `CAND-Q07` | La séparation femmes/hommes s'applique-t-elle aux entretiens et à la lecture des candidatures, avec l'exception super-admin du KYC ? | 89 candidates ; une règle d'écran n'est pas une protection | Oui, en base, même règle que le KYC | Décision datée |
| `CAND-Q08` | Qu'est-ce que l'évaluation de lecture, tajwid et mémorisation d'un enseignant : un constat d'entretien structuré, ou un référentiel neuf ? | 89 candidats se disent « prêts à un test de niveau » | Constat structuré (niveau observé, riwaya, ijaza présentée) | Décision datée |
| `CAND-Q09` | L'entretien est-il annoncé « non enregistré », et quelle mention remplace « Visite de contrôle possible » ? | La mention de la salle serait fausse | « Entretien non enregistré » ; aucune visite de contrôle | Décision datée |
| `CAND-Q10` | Tant qu'aucun SMTP n'est posé, la direction prévient-elle par WhatsApp et l'application enregistre-t-elle « prévenu le » ? | Aucun canal ; aucun état ne doit prétendre un envoi | Oui | Décision datée |
| `CAND-Q11` | Engagement religieux : texte validé juridiquement, en français et en arabe, version `2026-10` ; « Je confirme » au lieu de « Je certifie » ; accepté sur la page unique des accords par un candidat en attente ; distinct du code de conduite ? | Nouvelle sorte d'accord ; M-10 ; la mention des Compagnons est nouvelle (la doctrine écrite dit « voie d'Ahl as-Sunna », `C/REGISTRE-RECONCILIATION-2026-10-14.md:139`) | Oui ; texte distinct du code de conduite | Texte validé, décision datée |
| `CAND-Q12` | Les mots : comment nomme-t-on les trois salles, le vivier, la candidature ? | « salle », « vivier », « engagement » sont pris | « Premier examen », « Vérifications et entretien », « Prêts à enseigner » ; « Cadre religieux et pédagogique » pour l'engagement | Ajout dans `mots-rewayah` |
| `CAND-Q13` | Le parcours candidat est-il livré en arabe ? | La population des formulaires est arabophone ; `recrutement` est traduit à 16 % | Oui, pour les clés du parcours candidat | Décision datée |
| `CAND-Q14` | Le CTA d'entretien de chaque ligne est-il un lien secondaire (et non un bouton plein) ? | K-56 et la carte entièrement cliquable | Oui | Décision datée |
| `CAND-Q15` | Les défauts trouvés hors module (`creer_groupe` sans contrôle de pièce ni de genre, `c11bis` qui lève toujours, décimales du GNF, code de conduite hors de la garde d'activation) se corrigent-ils dans des lots séparés ? | « Prêts à être affectés » n'a pas de chemin serveur fiable | Oui, lots séparés et courts | Feu vert |
| `CAND-Q16` | Pour un doublon aux réponses divergentes, quelle ligne l'emporte ? | 14 groupes sur 27 | La plus récente, les autres en historique | Décision datée |

---

## 10. Plan d'écrans et de composants

Codes **proposés**, à inscrire dans un `C/CATALOGUE_ECRANS_RECRUTEMENT.md` avec
leurs fiches (Tâche, Contenu, Entrée, États, Droits, Contrat serveur à demander)
**après** les questions bloquantes et **avant** tout fichier `.dart`. Libres à la
pointe : `ADM-20` et au-delà, préfixe `CAND-` (éviter `REC-`, déjà pris).

### 10.1 Côté candidat : des pas de plus dans `/attente`

| Code proposé | Écran | Réutilise |
| :--- | :--- | :--- |
| `CAND-01` | Questionnaire de candidature, en cartes, choix dans des listes (jamais de saisie à la main pour ce qui se choisit) | coquille du parcours d'inscription ; `etat_dossier()` étendu |
| (case de plus) | Engagement religieux : une case de plus sur `/attente/accords`, pas une page | `accords_page.dart`, `contract_required_versions` |
| `CAND-02` | Mon entretien : date, heure et fuseaux ; selon `CAND-Q06`, « prévu par WhatsApp » ou « Rejoindre » au moment autorisé | `EmplacementEntree`, `ctaSeance` |

Le portail ne montre jamais un autre candidat, ni compteur, ni liste (spec §7).

### 10.2 Côté direction : Personnes

| Code proposé | Écran | Réutilise ou étend |
| :--- | :--- | :--- |
| `ADM-20` | Candidatures : recherche, filtres d'étape en puces avec compteur, autres axes sous « Plus », tri par menu, pagination, sélection multiple | `DataCollection`, `ChampRecherche`, `RangeeFiltres`, `BarreSelection` promue ; pagination de Regroupements |
| `ADM-21` | Candidature : réponses, contrôles nommés, lien vers ADM-02 pour la pièce, entretien, historique, décision | `StatusPill`, `MenuActions`, `historique_candidature` |
| `ADM-22` | Aperçu et suivi d'une action groupée (inviter, refuser, mettre en pause) : éligibles, exclus avec leur raison, résultat ligne par ligne | motif du Comptable (contrôle préalable, idempotence, issue inconnue) |
| `ADM-23` | Import de candidatures : fichier, association des colonnes, essai à blanc, confirmation, rapport | motif de l'import du 12/10 ; **route distincte de `/admin/personnes/import`** pour éviter la confusion |
| `ADM-24` | Compatibilité de paiement par pays | référentiel ; place selon `CAND-Q05` (Finance ou Configuration) |

Les « salles » sont des **filtres d'étape** de `ADM-20`, pas un kanban : un kanban
de quatre cents cartes n'est ni dense ni filtrable, et le dépôt n'en a aucun motif
(spec §10 le permet). La vue « Entretiens » est le filtre `verifications` trié par
date d'entretien ; le nom ouvre `ADM-21`, le lien d'entretien est à part (spec §6).

### 10.3 Composants

| Composant | Statut |
| :--- | :--- |
| `BarreSelection` | à **promouvoir** du Comptable vers `lib/core/widgets/` |
| Contrôle préalable groupé et suivi ligne par ligne | à extraire du Comptable comme motif partagé |
| Ligne d'historique d'un dossier | **neuf** (`TimelineRow` est la journée de l'enseignant) |
| `DataCollection`, `ChampRecherche`, `RangeeFiltres`, `FilterPill`, `MenuFiltre`, `MenuActions`, `StatusPill`, `EmptyState`, `Skeleton`, `ConfirmDestructive`, `AppBottomSheet` | réutilisés tels quels |

Chaque écran porte une `UX_REVIEW_CAND-<n>.md` (DESIGN-GOV) et ses états
loading, content, empty, error, offline, plus les états propres à la spec §11.

---

## 11. Scénarios de la spec §12.2

| Scénario | Comportement retenu | Existe | Manque |
| :--- | :--- | :--- | :--- |
| Candidature complète | `prequalification/en_examen`, file par ancienneté | file ADM-02 par ancienneté | tout le reste |
| Candidature partielle | `a_completer`, la liste de ce qui manque | `PieceManquante` | questionnaire |
| Doublon à l'import | proposé, jamais fusionné sans geste | rapprochement par courriel exact | téléphone, référence source |
| Candidat qui ne répond pas | reste en `recue`, `invitee` ou `a_completer` ; filtre « sans activité depuis N jours » ; invitation expirée à 14 jours | expiration de l'invitation | date de dernière activité |
| Pièce absente, en attente, refusée | contrôle `piece_validee` faux ; refus : « à corriger » | ADM-02, `motif_refus` | `CAND-Q01` |
| Pièce expirée | **n'existe pas** : aucune date de validité, pièce purgée à 90 jours | — | décision |
| Engagement non accepté | bloque l'entrée en `verifications` | page unique des accords | la sorte d'accord |
| Sans compte bancaire, mobile money compatible | `paiement_compatible` vrai | types client | référentiel |
| Compte bancaire non compatible avec le pays | faux pour cette méthode, vrai si une autre l'est | — | référentiel |
| Aucune méthode confirmée | bloque `confirmee` ; filtre visible | — | référentiel, `CAND-Q05` |
| Entretien à planifier, annulé, manqué, en cours, terminé | états de 6.2 ; annulé et manqué gardent la trace et proposent de reprogrammer | `PhaseSeance` (voie 2) | entretien |
| Visio sans lien valide | une phrase à la place du bouton | règle du bouton qui ne peut pas aboutir | — |
| Décision positive avec un prérequis manquant | refusée par la base, contrôle manquant nommé | garde `0089` pour les contrats | RPC de confirmation |
| Confirmé mais indisponible | `confirmee` + indisponibilité, hors affectation | — | colonne, et prédicat d'affectation |
| Profil suspendu après confirmation | restriction motivée ; historique conservé | `disabled` | RPC de suspension (aucune n'existe) |
| Réactivation après résolution | geste motivé, contrôles revérifiés | — | RPC |
| Affectation occupée ou conflit | inchangé : langue, genre, plafond hebdomadaire vérifiés par `tc_verifier` | oui | `creer_groupe` à aligner (`CAND-Q15`) |
| Critère changé après coup | version du questionnaire | — | versionnage |
| Matrice modifiée | une ligne passée `indisponible` alerte sur les confirmés concernés, sans les rétrograder seule | — | vue d'alerte |
| Action groupée partiellement refusée | rapport ligne par ligne ; les réussites restent | motif du Comptable | RPC de lot |
| Dossier ou pièce sans permission | refus en base, « hors portée » distinct d'« absent » | motif d'ADM-02 | RLS candidature |
| Desktop, tablette, mobile | tableau dense, cartes ; bureau 1440 en file et détail (DESIGN-GOV) | oui | — |
| Chargement, vide, erreur, hors ligne | `Skeleton`, `EmptyState`, bandeau hors ligne | oui | — |

**Scénarios ajoutés par cette revue**

| Scénario | Comportement retenu |
| :--- | :--- |
| Une ligne du formulaire B, déjà importée le 12/10 | signalée « déjà connue », rien n'est écrit |
| Un candidat sans courriel | reste en `recue`, marqué « courriel à obtenir » ; jamais invité |
| Un candidat importé crée lui-même un compte avec un autre courriel | impossible sans invitation ; rapprochement proposé par téléphone si la direction l'invite |
| Une invitation expire avant d'être consommée | la candidature revient en `recue` avec la trace ; réinvitation possible |
| Un contrôleur postule comme enseignant | refus : un contrôleur n'est jamais enseignant |
| Un candidat retire sa candidature pendant un entretien planifié | l'entretien est annulé, la trace reste, l'intervieweur le voit |
| Le texte de l'engagement change de version | les candidats en cours la ré-acceptent avant `confirmee` ; les confirmés gardent la leur |
| Le fuseau du candidat est inconnu | l'entretien ne se planifie pas ; aucune heure dans un fuseau deviné |
| Les créneaux importés sont en heure de La Mecque | convertis à l'import, jamais recopiés dans `weekly_availability` |

---

## 12. Plan de recette et de non-régression

**Base** : un fichier `T/scenarios_candidatures.sql` rejoué sur Postgres nu par
`tool/rejouer_scenarios.sh`, et proposé à la direction pour `ci.yml` (zone
interdite aux agents) :

- impossible d'entrer en `confirmee` avec un des six contrôles faux, un cas par
  contrôle ;
- `decider_dossier()` n'active plus un enseignant (si `CAND-Q01`), et la garde
  `0089` refuse toujours une activation sans contrats ;
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

**Flutter** : tests de widget par écran neuf, dans les cinq états, en RTL et à
200 %, au clavier ; portail `/attente` étendu ; composants promus dans la galerie
(`test/widgets/catalogue_galerie_test.dart`).

**Non-régression** : référence du 18/10, 107 scénarios SQL sur 107 et 15 218 tests
Flutter (`C/08:94`) ; invitations, inscription sur invitation, accords, ADM-02,
import du 12/10, Comptable (CPT-02), affectation par `tc_verifier` gardent leurs
tests ; `dart analyze --fatal-infos` propre ; `tool/verifier_jetons.dart` sans
violation nouvelle.

---

## 13. Ce qui peut avancer sans attendre

1. **Fait par ce lot** : la spécification versionnée, cette revue, `LIRE_D_ABORD.md`.
2. **Après `CAND-Q01` à `CAND-Q03`** : la spécification verticale consolidée,
   puis `C/CATALOGUE_ECRANS_RECRUTEMENT.md` avec ses fiches, puis les maquettes
   (bureau, tablette, mobile, clair et sombre).
3. **Après `CAND-Q02`** : le lot backend borné sur la base de test, avec ses
   scénarios, puis les écrans.
4. **Après `CAND-Q05`** : le référentiel de compatibilité de paiement.

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
  pièce, langue, genre et plafond (le défaut réel est ailleurs, section 3.2) ;
- elle proposait l'entretien en salle « sans toucher au service de jetons » : le
  jeton refuse un compte en attente, et une séance déclenche la paie ;
- elle disait qu'aucun import, aucune recherche partagée et aucune action groupée
  n'existaient : l'import du 12/10, `ChampRecherche` et le motif du Comptable
  existent ;
- elle tenait le domaine Finance pour inerte et la traduction arabe pour vide ;
- elle rangeait ses fichiers et ses questions dans des documents archivés
  (`HANDOFF`, `PROGRESS`, `decisions.md`).
