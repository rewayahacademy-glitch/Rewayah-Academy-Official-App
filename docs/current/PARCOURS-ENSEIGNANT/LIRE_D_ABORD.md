# Parcours de l'enseignant, du courriel à son espace : où tout est écrit

Ordre du directeur (19/11/2026) : « retravailler tout le parcours d'un candidat jusqu'à ce qu'il
devienne un enseignant » ; « que tu inscrives les problèmes et tes solutions et le plan sur les
documents […] pour ne pas qu'on traite à 70 ou à 80 % et qu'il y ait un problème de token et on
oublie. C'est ce qui se passe depuis 3 mois ».

**Ce qui est faux ou non prouvé aujourd'hui (19/11/2026)** : rien de ce chantier n'est codé. Ce
dossier contient une recherche, un plan et une check-liste. Le plan n'est pas encore validé par le
directeur. Ce chantier sort de la Boucle 1 (`../BOUCLE-1_PLAN_2026-10-24.md`) : il est lancé par la
demande explicite la plus récente du directeur, qui prévaut.

| Quoi | Où |
| :--- | :--- |
| **La check-liste lot par lot (à tenir à jour à chaque PR, dans la PR même)** | `SUIVI.md` |
| Ce que le directeur a demandé, les constats prouvés, les arbitrages, les standards, le modèle du bureau | `PLAN.md` |
| Le manuscrit du directeur, transcrit mot à mot | `MANUSCRIT-2026-11-19.md` |
| Les problèmes vécus par les candidats (messages et courriels lus le 19/11), avec la colonne « Pour les élèves » | `../RETOURS-TERRAIN-INSCRIPTIONS.md`, lignes R27 à R42 |
| Le bureau de l'équipe, déjà commencé (file, dossier, liste, Praxis) | `../BUREAU-EQUIPE/LIRE_D_ABORD.md` |
| La messagerie, déjà commencée | `../MESSAGERIE-ETAT-ET-PLAN-2026-11-16.md`, `../MESSAGERIE-MATRICE.md` |

## Règles pour tout agent qui reprend ce chantier

1. Lire ce fichier, puis `SUIVI.md`, puis la section de `PLAN.md` qui porte le lot. Rien d'autre.
2. Un lot, une pull request. La PR qui livre un lot coche sa ligne dans `SUIVI.md` et y écrit son
   numéro. Un lot sans ligne à jour n'existe pas.
3. Avant d'écrire un lot, chercher dans `../REGISTRE-LOTS.md` et dans la colonne « Déjà commencé »
   de `SUIVI.md` : plusieurs morceaux existent déjà sur des branches. On les reprend, on ne les
   réécrit pas.
4. Statuts permis dans `SUIVI.md` : `pas commencé`, `en cours` (branche), `PR ouverte` (numéro),
   `dans main` (numéro), `prouvé par le directeur` (date). « Fait » veut dire « prouvé par le
   directeur en production ».
5. Tout nouveau problème vécu par une vraie personne s'ajoute à `../RETOURS-TERRAIN-INSCRIPTIONS.md`
   (consigne 20), sans nom ni adresse.
6. Les questions ouvertes au directeur sont dans `PLAN.md` §9. Un lot qui dépend d'une question
   sans réponse ne démarre pas ; on le dit au directeur le jour même.
