# Salle d'examen enseignants : le questionnaire `salle-examen-1` répond-il aux besoins de l'académie ?

22/10/2026. Audit demandé par le directeur (« il faut que tu sois sûr que les choix que tu proposes sont pertinents et qu'ils soient capables de capter tous les besoins de l'académie »). **Constat et propositions, rien n'est appliqué** : les huit questions de la section 5 attendent sa réponse.

Lecture seule, pour le directeur. Rien n'est appliqué sur staging ni déployé, donc tout se corrige dans le fichier, sans coût. Après publication, la version est figée (`L2A1:419-442`) et il faudrait publier `salle-examen-2`.

## Statut : décisions du directeur appliquées (22/10/2026)

Le directeur a répondu le 22/10 (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 ter). Les décisions sont **appliquées dans la définition** de `salle-examen-1` (`présent dans le code`, `testé localement`, ni staging ni production), corrigée sur place dans L2A1 (réf. C17) parce que la version n'est appliquée nulle part ; elles ne sont pas déployées. Les numéros de ligne de cet audit (`L2A1:…`) citent la version d'**avant** la correction ; la spec consolidée porte les numéros à jour.

| Question | Réponse du directeur | Appliqué |
|---|---|---|
| 1. Poular = peul ? | Oui, une seule langue, le code `poular` ; poular, peul et fulfulde sont une seule entrée | Plus de `ff` dans la liste ; l'import convertit `ff`, peul et fulfulde en `poular` (`MAPPAGE_IMPORT_FORMULAIRES.md` §3.2) |
| 2. L'arabe, langue de cours ? | **Non** (réponse inverse de la recommandation) : le public principal est la diaspora africaine ; la langue de cours se choisit parmi les langues disponibles et l'académie affecte un enseignant qui la parle ; **aucun plafond** de langues | `ar` exclu de `languesExplication` (clé `exclure`) mais gardé en `langueMaternelle` (facultative) ; pas de `max` ; liste du public visé (`man`, `sus`, `sw`, `ha`, `wo`, `bm`, `snk`, `mnk`, plus poular, français et anglais) et « autre langue » (`autre`) |
| 3. Grille ou blocs ? | Pas tranché : **la grille construite reste** ; puis, le même jour, la question du directeur : peut-elle déterminer réellement les créneaux de l'enseignant et les faire correspondre à ceux de l'élève ? | **Format corrigé le 22/10** (`présent dans le code`, `testé localement`, ni staging ni production) : `disponibilitesDeclarees` est une liste de **plages par jour ISO à bornes en heures entières**, sans chevauchement (refus nommé), dans le fuseau unique `fuseauIana` (plus de second fuseau ni de demi-heure) ; règle de conversion en lignes de `weekly_availability` (une par heure couverte) documentée, copie non écrite ; ce qui manque pour un cours d'adultes de 90 minutes : spec consolidée 2.1 bis |
| 4. Enfant et adulte, ou quatre cohortes ? | **Quatre tranches au choix**, plusieurs possibles : 6-9, 10-13, 14-17, adultes | `publics` : `6_9`, `10_13`, `14_17`, `adultes`, une à quatre |
| 5. Séparer mémorisation et ijaza ? | Oui : « qui a une ijaza a mémorisé, mais toute personne qui a mémorisé n'a pas une ijaza » | `niveauMemorisationDeclare` : `aucune`, `moins_10_juz`, `de_10_a_29_juz`, `coran_entier` ; `ijazaPresentable` : `oui`, `pret_test`, `non` ; table de conversion des 440 lignes (`MAPPAGE…` §3.3 et §3.4) |
| 6. Continuité ? | Oui, l'engagement à tenir sa Classe aux mêmes jours et heures | Clause du texte des conditions acceptées : **rien côté serveur** (spec consolidée 2.1) |
| 7. Champ « moyens accessibles » ? | « Il faut s'assurer que les gens qui vont s'engager avec nous vont pouvoir être payés » : la réponse ne parle pas du champ ; le contrôle de paiement reste la condition d'entrée en salle 2. **Le champ (facultatif, informatif) est la recommandation de l'audit, retenue faute d'objection : à confirmer** | `moyensAccessibles`, tous les moyens connus du catalogue de L6 ; jamais lu par le paiement ni par un contrôle (scénarios de L2A1 et L2A2) |
| 8. Plafond d'heures fixé par la direction ? | Trois Classes au plus par enseignant pour l'instant, réglable par la direction dans les réglages | `heuresParSemaine` remplacé par `classesSouhaitees` ; **réglage posé le 22/10 (lot CLASSES-PLAFOND)** : `enseignant.classes_max` (3 par défaut, 1 à 80), vérifié par le serveur à chaque Classe donnée à un enseignant ; la question propose de 1 à ce maximum (voir ci-dessous) |

Aussi appliqué : `langueMaternelle` devient facultative (verdict du tableau 1), et la valeur `pret_test` de l'import (`pret_a_un_test` dans le mappage) est celle du serveur.

**Pas encore fait, parce que non décidé ou hors de ce lot :**
- ~~le réglage de la direction du plafond de Classes~~ **fait le 22/10** (`testé localement`, ni staging ni production : migrations `20261022000200` et `20261022000300`) : le serveur refuse `plafond_classes_atteint` au-delà du maximum en vigueur ; `classesSouhaitees` propose de 1 à ce maximum **sans publier de version** (l'écran propose de 1 au maximum ; l'examen accepte tout entier de 1 à 80 quel que soit le maximum, pour qu'une réponse déjà envoyée ne devienne jamais invalide par un réglage). Reste : l'écran du réglage (clé à ajouter à `clesRegles` et à la page Règles) et les phrases de refus du client (`core/offres/affectation_refusee.dart`, `core/admin/creation_classe_refusee.dart`) ;
- les lecteurs prévus restent à écrire (fiche d'entretien, `enseignants_pour_public` pour les publics, tri), et la règle « tout champ obligatoire nomme son lecteur » n'est pas appliquée aux autres champs ;
- connexion, outil et référence au constat d'entretien ; assiette de la paie dans le texte de la politique ; tajwid observé au constat ; la copie de la grille vers `weekly_availability` en salle 3 (le **format** est posé le 22/10, une ligne par heure couverte ; la copie n'est pas écrite, lot L2B) ; ~~la comparaison d'un cours d'adultes de 90 minutes par l'affectation~~ **faite le 22/10** (`testé localement`, ni staging ni production : migration `20261022000400` ; reste ouvert : le côté élève, les créneaux libres affichés et la durée des séances matérialisées, spec consolidée 2.1 bis) ; plafond d'heures fixé par la direction à partir de la tranche ; titulaire du compte au premier versement ;
- `experienceDebutants` facultatif, libellés sans recouvrement de `debutPossible` ; ~~un seul fuseau dans la grille~~ **fait le 22/10** (plages par jour ISO, heures entières, fuseau de `fuseauIana`, spec consolidée 2.1 bis) ;
- MTN et YAS dans le catalogue des opérateurs ; le Yémen dans la liste « à signaler » ; l'espagnol (non ajouté : il n'est pas dans les réponses, « autre langue » le couvre) ;
- les deux corrections de documents d'import de la fin de l'audit : ~~pré-remplissage de la colonne J impossible~~ **fait le 22/10** (`MAP §2`, §3.5 ; spec consolidée 3.2, 3.4 et L3-10), consentement WhatsApp sans champ d'arrivée **reste à faire** ;
- la fiche d'écran `CAND-01` (`CATALOGUE_ECRANS_RECRUTEMENT.md`, lignes sur les heures par semaine et l'ijaza « oui, non ») et les écrans, les clés i18n et les faux du côté Flutter, qui lisent encore les anciens codes (`heuresParSemaine`, `enfant`, `adulte`, `ff`) ;
- le code du malinké (`man`, macrolangue ISO 639-3) et l'écriture des codes de valeur par un chiffre (`6_9`, `1`) : à confirmer.

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
