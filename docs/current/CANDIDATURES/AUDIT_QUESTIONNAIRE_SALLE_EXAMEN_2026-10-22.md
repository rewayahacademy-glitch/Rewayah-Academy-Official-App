# Salle d'examen enseignants : le questionnaire `salle-examen-1` répond-il aux besoins de l'académie ?

22/10/2026. Audit demandé par le directeur (« il faut que tu sois sûr que les choix que tu proposes sont pertinents et qu'ils soient capables de capter tous les besoins de l'académie »). **Constat et propositions, rien n'est appliqué** : les huit questions de la section 5 attendent sa réponse.

Lecture seule, pour le directeur. Rien n'est appliqué sur staging ni déployé, donc tout se corrige dans le fichier, sans coût. Après publication, la version est figée (`L2A1:419-442`) et il faudrait publier `salle-examen-2`.

Sigles :
- `L2A1` = `supabase/migrations/20261022000000_cand_l2a1_moteur_salle_examen.sql`
- `L2A2` = `…20261022000100_cand_l2a2_gestes_direction.sql`
- `L6` = `…20261021220100_cand_l6_referentiel_paiement.sql`
- `PRED` = `…20261021210200_creer_groupe_predicat_affectation.sql`
- `SC` = `docs/current/CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md`
- `MAP` = `…/MAPPAGE_IMPORT_FORMULAIRES.md`
- `CAT` = `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`

## Verdict

Le questionnaire couvre bien le paiement, la langue, le fuseau et le pays. Mais :
- 15 champs sur 16 sont obligatoires, et 11 n'ont **aucun lecteur** aujourd'hui. Je l'ai vérifié en cherchant chaque clé dans `supabase/` et `lib/` : seule la définition (`L2A1:459-483`) les cite.
- Quatre exigences du dossier maître avant affectation n'ont aucune question : continuité, connexion, outil, référence (`DM:7669`).
- Trois listes posent un piège : poular et ff, l'absence de « autre langue », et l'ijaza.

## Ce que j'ai écarté ou corrigé dans les deux audits

- **Champs lus.** Ils sont 4, pas 5 : `paysResidence`, `paysVersement`, `compteBancaire` et `operateurs`. `fuseauIana` est recopié dans `candidatures.fuseau_iana` (`L2A1:1978`), mais aucune fonction ne relit cette colonne.
- **Opérateurs.** Le champ est vide pour **tous** les pays, pas seulement l'Afrique. `L6:1080` est le seul `INSERT` du référentiel et ne pose que le virement. Les opérateurs existent (`L6:1075-1077`), mais aucune ligne `mobile_money` n'est posée.
- **Citation fausse.** `REG:57-58` ne parle pas des langues de l'application. La bonne source est `SKILL:132`.
- **Espagnol.** Il est seulement « en attente » (`DM:7557`), pas annoncé comme langue de cours. Je le propose comme langue à compter, pas comme langue ouverte.
- **Quatre cohortes** (6-9, 10-13, 14-17, 18+). Rien ne les lit non plus (`PRED:109-118`). Je ne les retiens pas pour l'instant.
- **Non vérifié.** Le texte juridique du cadre religieux et du contrat, pour savoir si la continuité y figure. Les chiffres du fichier A viennent de la revue, je n'ai pas relu le fichier.

## 1. Champ par champ

| Champ | Verdict | Qui le lit | Pourquoi |
|---|---|---|---|
| `langueMaternelle` (`:459`) | Rendre facultatif | Fiche d'entretien (à écrire) | Aucune règle ne la lit. Ne jamais la recopier dans `teacher_profiles.languages`, que l'affectation compare à la langue de la classe (`PRED:109`, `SC:246`). |
| `languesExplication` (`:460`) | Garder, changer la liste | Copie au profil en salle 3 (`SC:246`), puis affectation | C'est la seule langue qui décide d'une classe. Le maximum est 10 pour 26 options (`:461`). |
| `niveauMemorisationDeclare` (`:462`) | Changer | Tri « niveau » (`SC:866`, non codé) | Il mélange quantité mémorisée et ijaza. Exactement 10 juz' n'a pas de case, et rien n'ordonne les valeurs. |
| `niveauLectureTajwid` (`:465`) | Garder, facultatif | Comparaison avec le constat | À condition d'ajouter « tajwid observé » au constat, qui n'a qu'un niveau (`CAT:1640-1644`). Sinon, retirer. |
| `riwayat` (`:467`) | Garder les 20 codes | Fiche d'entretien et signal | La liste est complète. Seul Hafs compte pour le produit (`0013:5-9`). Signal « ne déclare pas Hafs » calculé sur la réponse, sans élimination. |
| `ijazaPresentable` (`:471`) | Changer | Fiche d'entretien | Ajouter « prêt à un test » : 89 réponses sur 440. L'import produit cette valeur (`MAP:121`) et le serveur la rejetterait. |
| `experienceDebutants` (`:473`) | Garder, facultatif | Fiche d'entretien (ou filtre de la liste) | Utile aux premières étapes. L'import de la colonne I donne une valeur impossible (`MAP:123-124`). |
| `disponibilitesDeclarees` (`:475`) | Remplacer en salle 1 (voir 4) | Personne | La grille n'est copiée nulle part (`SC:677`). Un seul créneau suffit, les chevauchements passent (`:1003-1033`). Le pré-remplissage est impossible : le validateur exige un jour (`:1013-1018`), les formulaires n'en donnent aucun (`MAP:132-141`). |
| `fuseauIana` (`:477`) | Garder, un seul fuseau | Planification de l'entretien (`CAT:687-693`) | La grille porte un second fuseau (`:995-997`), et rien ne vérifie qu'ils sont égaux. |
| `heuresParSemaine` (`:478`) | Codes gardés, libellés changés | Tri (`SC:866`) | Ne fixe pas le plafond, qui reste à 40 h par défaut (`0001:94`, `PRED:122,167`). « Moins de 3 h » ne tient pas une classe (3 × 60 min, `TARIFS:45`). |
| `debutPossible` (`:480`) | Garder, libellés sans recouvrement | Tri (`SC:866`) | « Le mois prochain » est compris dans « dans 3 mois ». |
| `publics` (`:482`) | Garder, lui donner une destination | À écrire : `enseignants_pour_public` | Aujourd'hui il ne filtre rien (`20261016100900_enseignants_pour_public.sql:14-16`). Une enseignante « adulte seulement » serait proposée pour des enfants. |
| `paysResidence` (`:484`) | Garder | Colonne et filtre de la liste (`L2A2:1756,1775`) | Le paiement ne le lit pas. |
| `paysVersement` (`:485`) | Garder | Calcul du paiement (`L6:694-706`) | Décisif. |
| `compteBancaire` (`:486`) | Garder, reformuler | Paiement | Un « non » mal compris classe la candidature en paiement non disponible. |
| `operateurs` (`:487`) | Garder pour l'éligibilité | Paiement | Vide partout aujourd'hui (voir 5). |

Seuls 3 filtres existent côté serveur : 8 clés de filtre (`L2A2:1754-1756`) et 3 tris, activité, récente et nom (`L2A2:1792`). `lireEntretien` n'existe pas dans le code. Ces « lecteurs » sont donc **prévus, pas codés**. La règle que je propose : tout champ obligatoire nomme son lecteur, sinon il devient facultatif ou sort.

## 2. Besoins non couverts

| Besoin et question | Choix proposés |
|---|---|
| **Continuité** : « Tenez-vous la même classe, aux mêmes jours et heures ? » (`REG:56,67`) | **A. Clause dans le texte de conditions** : aucune case en plus, preuve dans `contract_acceptances`. Exemple : « Je tiens ma classe chaque semaine, sauf absence annoncée. » **B. Case séparée** : plus visible, mais une friction de plus. **C. Rien en salle 1** : rien n'est prouvé. Recommandé : A. |
| **Connexion, outil, référence** (`DM:7669`) | **A. Au constat d'entretien**, qui se tient dans la salle vidéo de l'app : connexion observée, outil maîtrisé, référence demandée (oui/non). **B. Question déclarative en salle 1** : donnée non vérifiée. Recommandé : A. |
| **Assiette de la paie** : la candidate accepte 47 % sans lire les règles | Faire entrer dans le texte de la version de politique : paie à l'élève présent, absent non payé, séance due à 45 min (enfant) ou 70 min (adulte), versement avant le 5, paie en attente si le cahier manque (`TARIFS:29-31,47`). Aucun montant, selon la décision du 22/10. |
| **Moyens de versement hors catalogue** : le champ ne propose que les moyens confirmés, donc rien aujourd'hui | Voir la question 7. |

## 3. Listes à compléter

- **Langues.**
  - Une seule entrée « Poular / peul » enregistrée sous `poular`. Aujourd'hui `ff` est une langue à part (`L2A1:456`) et ne rend jamais affectable à une classe de poular (`PRED:109`).
  - Ajouter `es`.
  - Ajouter une sortie « autre langue » : 46 et 72 personnes avaient coché « autre » (`REVUE`).
  - Relever le maximum de 10 ou le justifier.
  - Kanouri, zarma et dioula sont plausibles d'après les indicatifs, mais à confirmer sur le comptage de « autre ».
- **Mémorisation.** Aucune, moins de 10 juz', de 10 à 29 juz', Coran entier. L'ijaza reste portée par `ijazaPresentable` et `riwayat`.
- **Ijaza.** Trois valeurs : oui, prêt à un test, non.
- **Heures par semaine**, en classes : moins de 3 h (pas encore une classe entière), 3 à 5 h (une), 6 à 10 h (deux), plus de 10 h (trois ou plus).
- **Publics.** « Enfants (6 à 17 ans) » et « Adultes (18 ans et plus) ».
- **Opérateurs.** Ajouter MTN et YAS (`DM:7941`) par migration, sur ta décision.
- **Pays.** Les 249 codes sont complets. Ajouter le Yémen à la liste « à signaler » (`SC:725-728`) : son virement est « confirmé » par la règle (`L6`).

## 4. À déplacer

- **Salle 1.** On garde heures par semaine, début possible, un seul fuseau, et 3 ou 4 blocs de référence : soirs de semaine, fins de semaine, nuit, journée.
- **Salle 3, à l'entrée.**
  - La grille fine, en brouillon de `weekly_availability` que l'enseignante confirme (`SC:214`). C'est la table que lit l'affectation, et elle évite la double saisie. Il reste à trancher le grain : la table ne connaît que des heures entières (`0005:380-388`), alors que les séances adultes durent 90 min.
  - Les publics acceptés.
  - Le plafond d'heures, fixé par la direction à partir de la tranche déclarée, par un geste journalisé.
- **Salle 2, au constat d'entretien.** Mémorisation observée, tajwid observé, riwaya observée, ijaza présentée (mêmes codes que la déclaration), connexion, outil, référence.
- **Premier versement.** Le titulaire du compte, qui doit être l'enseignant. Aucune coordonnée avant (`V1:274-279`).

## 5. Questions à trancher

1. **Poular = peul ?** Recommandé : oui, une seule entrée sous `poular`.
2. **L'arabe entre-t-il dans les langues de cours** (sous `ar`) ? Recommandé : oui. L'offre l'annonce (`OFFRE:33`), et sinon l'écran affiche « Langue pas encore proposée » (`CAT:757`).
3. **Grille complète en salle 1, ou blocs en salle 1 et grille en salle 3 ?** Recommandé : blocs. La grille ne décide aucune entrée, et pour la mesure du vivier par horaire (`DECISION-CLASSES-SIMULTANEES R7,R19`) aucun lecteur n'existe.
4. **Enfant et adulte, ou quatre cohortes ?** Recommandé : enfant et adulte, les seuls publics du tarif et de la paie. À rouvrir quand l'affectation lira la cohorte.
5. **Séparer mémorisation et ijaza ?** Recommandé : oui, tant que la version n'est pas publiée. Il faudra une table de conversion pour les 440 lignes importées.
6. **Continuité : clause du texte de conditions ?** Recommandé : oui.
7. **Champ informatif « moyens accessibles non encore pris en charge »** ? Il déroge à `V1:317-318` (« les candidats ne voient que les options confirmées »). Il ne compte jamais pour le contrôle de paiement. Recommandé : oui, pour choisir les pays à vérifier en Afrique.
8. **Plafond d'heures fixé par la direction à partir de la tranche déclarée ?** Recommandé : oui.

**À corriger dans les documents d'import :**
- `SC:372-374` et `MAP:40` annoncent un pré-remplissage de la colonne J, impossible faute de jour.
- Le consentement WhatsApp (`MAP:43`) n'a aucun champ d'arrivée : à conserver dans le document d'import, avec la date de la colonne A.
