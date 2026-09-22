# Badges et grades — ce que chaque chose signifie, et ce qu'elle donne

**Document de spécification, écrit le 22 septembre 2026. Rien de ce qui suit
n'est implémenté.** Le lot « onboarding et offres horaires » s'arrête
explicitement avant les badges ; ce document existe pour que la décision soit
prise sur du papier avant d'être prise dans du code.

Aucune table, aucune colonne, aucun écran de ce document n'existe en base au
22 septembre 2026. Une recherche sur `badge`, `grade` dans le dépôt ne rend que
des usages du mot « badge » au sens visuel (une pastille d'état), sans rapport.

---

## 1. Pourquoi ce document existe avant le code

Un système de badges est le mécanisme le plus facile à livrer et le plus
difficile à retirer. Dès qu'un élève a vu « Niveau 3 », le lui reprendre est
vécu comme une sanction, même quand c'est une correction de bug. Trois questions
doivent donc être tranchées **avant** la première ligne :

1. **Qu'est-ce qu'un badge mesure ?** Une compétence validée, ou une assiduité ?
   Les deux ne se mélangent pas : mélanger « il sait » et « il vient » produit un
   grade que personne ne sait lire.
2. **Un badge donne-t-il un privilège ?** Si oui, il devient un objet de
   sécurité : il faut alors une porte serveur, pas un affichage.
3. **Un badge peut-il se perdre ?** Si oui, il faut dire dans quelles conditions,
   à l'avance, et en langage clair.

Ce document répond aux trois. Le tableau de la section 4 est la réponse à votre
demande : « quel privilège espérer pour chaque grade ».

---

## 2. Deux familles qui ne se mélangent jamais

Le produit a besoin de deux choses différentes, et la confusion des deux est
l'erreur la plus courante des systèmes de badges scolaires.

### 2.1 Le grade académique — ce que l'élève SAIT

Le grade est la position de l'élève dans le programme de l'académie. Il est
**attribué par l'académie après diagnostic ou évaluation**, jamais par un
compteur automatique.

- Source de vérité : `student_profiles.level`, qui référence
  `programme_niveaux`.
- **Le client n'a aucun droit d'écriture sur cette colonne.** Vérifié le
  22 septembre 2026 : `authenticated` a `INSERT` mais **pas** `UPDATE` sur
  `student_profiles.level`. Une famille ne peut donc pas se promouvoir.
- Le niveau **auto-déclaré** de l'onboarding vit dans une colonne séparée,
  `student_profiles.niveau_declare`, et n'a jamais valeur de grade. Voir
  `docs/produit/onboarding-questions-expliquees.md`.

⚠️ **Contrainte actuelle** : `programme_versions` et `programme_niveaux` sont
**vides en production**. Il n'existe donc aujourd'hui aucun grade académique à
afficher. Tout écran de badge construit avant l'import du curriculum
afficherait du vide.

### 2.2 Les badges de parcours — ce que l'élève A FAIT

Un badge de parcours reconnaît un comportement observable et vérifiable :
être venu, avoir terminé, avoir persévéré. Il ne dit rien du niveau.

- Il se calcule à partir de données déjà présentes : `session_participants`,
  `presence_state`, `lesson_reports`, `evaluations`.
- Il **ne donne aucun privilège pédagogique**. C'est une reconnaissance, pas
  une clé.

---

## 3. Les grades académiques

Les noms ci-dessous sont des **propositions**, à valider par l'académie au
moment de l'import du curriculum. Ils suivent la règle déjà posée pour
l'onboarding : **une appellation humaine, jamais un code de référentiel.** Un
parent ne doit jamais lire `F1`, `F2` ni `F3` à l'écran ; ces codes restent
`programme_niveaux.code_technique`, réservés à l'administration.

| Ordre | Nom humain proposé | `code_technique` | Ce que l'élève sait faire |
| :--- | :--- | :--- | :--- |
| 1 | Découverte des lettres | `F1` | Reconnaître les lettres isolées, les distinguer deux à deux |
| 2 | Lettres et voyelles | `F2` | Lire une syllabe vocalisée, sans assemblage long |
| 3 | Premiers mots | `F3` | Assembler des mots courts, lire lentement une ligne |
| 4 | Lecture guidée | `L1` | Lire un verset court avec correction du professeur |
| 5 | Lecture courante | `L2` | Lire une page sans assistance permanente |
| 6 | Lecture appliquée | `L3` | Appliquer les règles de tajwid en lisant |
| 7 | Mémorisation en cours | `M1` | Mémoriser et réciter un juz' |
| 8 | Mémorisation avancée | `M2` | Réciter plusieurs juz' avec stabilité |

**Le grade ne se perd pas.** Un élève qui régresse est accompagné, pas
rétrogradé : l'académie peut l'inscrire dans un groupe d'un niveau inférieur
sans toucher à son grade. C'est une décision de produit, et elle est
délibérée — un grade réversible transforme chaque évaluation en menace.

**Le grade n'est visible que de l'élève, de son foyer, de son enseignant et de
l'administration.** Jamais des autres élèves du groupe. Un groupe de cinq
enfants dont les grades sont publics devient un classement.

---

## 4. Ce que chaque grade donne — le tableau des privilèges

C'est le cœur de la décision. Un privilège qui change ce que l'élève **peut
faire** est une porte de sécurité et doit être tenu par le serveur ; un
privilège qui change ce que l'élève **voit** peut rester un affichage.

| Grade | Privilège ouvert | Nature | Tenu par |
| :--- | :--- | :--- | :--- |
| Découverte des lettres | Accès aux ressources de sa matière et de son groupe | **Sécurité** | `library_access_policy` = `groupe_assigne` (existe) |
| Lettres et voyelles | — | — | — |
| Premiers mots | Lecture libre du Mushaf hors classe | **Sécurité** | `/tc/mushaf`, déjà ouvert au rôle élève (existe) |
| Lecture guidée | Position de lecture conservée entre les séances | Affichage | `student_reading_position` (existe) |
| Lecture courante | Téléchargement hors ligne des ressources autorisées | **Sécurité** | `library_offline_policy` = `sur_demande` (existe) |
| Lecture appliquée | Peut être proposé comme lecteur de référence à son groupe | Affichage | À construire |
| Mémorisation en cours | Suivi de mémorisation par juz' dans son espace | Affichage | À construire |
| Mémorisation avancée | Éligible au certificat de récitation de l'académie | **Sécurité** | À construire |

### Ce que ce tableau dit, et qu'il faut lire deux fois

**Cinq des huit privilèges reposent sur des mécanismes qui existent déjà.** Le
produit n'a pas besoin d'un système de badges pour les accorder : il a besoin de
*brancher les politiques existantes sur le grade*. C'est beaucoup moins de code,
et c'est déjà sécurisé.

**Trois seulement demandent du neuf**, et le seul qui soit un objet de sécurité
est le certificat. Un système de badges complet — table de badges, règles
d'attribution, moteur d'évaluation, écran de collection — serait donc du travail
essentiellement décoratif posé sur un mécanisme d'autorisation qui existe déjà.

**Recommandation** : ne pas construire de « système de badges ». Brancher les
politiques existantes sur `student_profiles.level`, et traiter les trois lignes
restantes comme trois fonctions distinctes, chacune justifiée à part.

---

## 5. Les badges de parcours

Si l'académie veut de la reconnaissance visible, elle coûte peu **à condition de
rester de l'affichage**. Aucune des lignes ci-dessous n'ouvre de porte.

| Badge | Condition | Source de données | Se perd ? |
| :--- | :--- | :--- | :--- |
| Première séance | Une séance terminée | `presence_state` = `finalisee` | Non |
| Dix séances | Dix séances terminées | idem | Non |
| Assidu du mois | Aucune absence non excusée sur un mois | `presence_state` | **Oui**, il est mensuel et se recalcule |
| Retour | Une séance terminée après trente jours sans séance | `sessions.started_at` | Non |
| Sourate achevée | Une sourate lue en entier en classe | `lesson_reports` | Non |
| Juz' mémorisé | Un juz' validé par l'enseignant | `evaluations` | Non |

**Règles non négociables**, quelle que soit la suite :

1. **Aucun badge de parcours n'ouvre un privilège.** Sinon l'assiduité devient
   une condition d'accès pédagogique, ce qui punit l'enfant malade.
2. **Aucun badge n'est comparatif.** Pas de classement, pas de « meilleur que »,
   pas de compteur visible des autres élèves du groupe.
3. **Un badge qui se perd le dit à l'avance.** « Assidu du mois » doit annoncer
   qu'il est mensuel avant d'être obtenu, pas au moment de disparaître.
4. **Le mode enfant n'en reçoit pas plus que le mode standard.** Un enfant de
   six ans n'a pas besoin d'une collection à compléter pour venir en cours, et
   une mécanique de collection transforme l'apprentissage en jeu de récompense.

---

## 6. Ce qui reste à trancher par l'académie

| Question | Pourquoi elle bloque |
| :--- | :--- |
| Les noms humains des huit grades | Ils s'afficheront à des parents ; ils ne peuvent pas être choisis par un agent |
| L'import du curriculum dans `programme_niveaux` | Sans lui, aucun grade n'existe et tout écran de badge est vide |
| Le certificat de récitation : qui le signe, sur quoi | C'est le seul privilège réellement nouveau, et il engage l'académie |
| « Assidu du mois » : le garde-t-on ? | C'est le seul badge qui se perd, donc le seul qui peut blesser |

---

## 7. Références dans le dépôt

- `student_profiles.level`, `programme_niveaux`, `programme_versions` — le grade
- `student_profiles.niveau_declare` — l'auto-déclaration, jamais le grade
- `library_access_policy`, `library_offline_policy` — les politiques d'accès qui
  portent déjà cinq des huit privilèges
- `presence_state`, `lesson_reports`, `evaluations` — les sources des badges de
  parcours
- `docs/produit/onboarding-questions-expliquees.md` — la séparation
  auto-déclaration / diagnostic / grade
