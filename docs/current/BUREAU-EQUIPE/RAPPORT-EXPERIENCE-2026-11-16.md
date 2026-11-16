# Rapport d'expérience : chantier « candidatures et équipe », 15-16/11/2026

Demande du directeur (16/11/2026, soir) : « tu écris les rapports d'expérience pour les autres lots
élèves, et types de listes ». Ce document dit ce que le chantier des enseignants a appris, **en règles
applicables tout de suite** aux lots des élèves, des familles, de l'équipe et à toute liste. Chaque règle
cite le fait qui l'a fait naître. Il complète `SPEC-LISTE-PERSONNES-2026-11-16.md` §0 et
`../RETOURS-TERRAIN-INSCRIPTIONS.md` ; il ne les remplace pas.

## 1. Ce qui a coûté le plus cher (faits)

| Fait | Coût | Règle |
| :--- | :--- | :--- |
| Une règle serveur changée à 13:11 (VERSEMENT-QUESTIONS) n'a pas rattrapé les 4 candidats déjà coincés par l'ancienne règle | 4 personnes bloquées une demi-journée, plainte au directeur, une migration de rattrapage (#542) | **Toute nouvelle règle s'accompagne, dans la même PR, d'un rattrapage des dossiers que l'ancienne a laissés coincés, avec le compte avant/après.** |
| Le courriel d'admission à l'entretien promettait « choisissez votre créneau » sans qu'aucun créneau existe | plaintes des candidats toute la journée du 15-16/11 ; écran corrigé (#521) mais pas le courriel | **Un texte (écran, courriel, notification) ne promet jamais une action que l'état du serveur ne permet pas. Écran et courriel se corrigent ensemble.** |
| Le menu du dossier proposait « Accepter » sans versement possible, puis « Clore le complément » sans complément ouvert | deux refus serveur vus par le directeur | **Un geste n'est montré que si le serveur dit qu'il peut aboutir (K-56). L'écran ne devine pas : si l'information manque, le serveur l'ajoute à la ligne (`complementEnCours`), l'écran la lit.** |
| Le pilote a affirmé deux choses sans les vérifier (le candidat « peut changer son compte bancaire » ; le franc CFA « peut-être » possible) | perte de confiance, double travail | **Une affirmation sur une capacité (de l'application, d'un prestataire comme Wise) se vérifie avant d'être dite : code ou base pour l'application, page publique du prestataire pour le reste.** |
| Les fichiers générés de slang (`strings*.g.dart`) ont fait échouer 5 PR au moment de la fusion de `main` | heures de CI | **Après toute fusion de `main` dans une branche : `dart run slang` deux fois, `build_runner`, commit. Sans Flutter, on ne fusionne pas soi-même.** |
| Deux sessions ont pris le même numéro de migration (20261129400000) | collision évitée de justesse | **Chaque chantier a sa plage de numéros, écrite dans sa passation (candidatures 202611294…, messagerie 202611295…). Une nouvelle plage se réserve dans `REGISTRE-LOTS.md` avant la première migration.** |
| La page « Candidatures » montrait sept blocs avant le premier nom (572 pt) | « ça fait près de 20 fois » (directeur) | **Liste : le premier nom à moins de 300 pt sur un téléphone 360 × 800, mesuré et écrit dans la PR. Ce qui sert une fois (explication, bandeau) se voit une fois par compte (`lire_vus` / `marquer_vu`), jamais en permanence.** |
| Un agent est resté bloqué 5 h sans que le pilote le voie | demi-journée perdue | **Le pilote relit l'état de chaque agent au moins toutes les heures ; un agent muet depuis plus d'une heure est relancé.** |
| 61 courriels envoyés, dont 4 à des candidatures retirées | messages inutiles | **Toute liste d'envoi se filtre sur l'issue (`en_cours`) et se compte avant l'envoi.** |

## 2. Règles pour les lots des élèves et des familles

1. **Une population, une liste, une ligne par personne pour toute sa vie** (SPEC §1). Pour un élève :
   demande → inscription → en classe → absent → pause → parti. La phase est calculée par le serveur
   (patron `private.lp_phase` de LP-1), jamais par l'écran.
2. **Le dossier d'un élève ou d'une famille montre les réponses de sa demande** (R24, non fait : 9
   demandes en attente n'affichent que le nom et la date).
3. **Chaque état bloquant a deux sorties écrites avant le code** : ce que la famille peut faire elle-même,
   et le geste de la direction qui débloque (leçon du versement).
4. **Aucun refus pour un motif que la personne peut corriger** : on met en attente et on dit pourquoi en une
   phrase (règle du versement du 16/11 transposée aux paiements des familles).
5. **Les courriels et notifications de la famille suivent l'état réel**, comme l'écran (leçon du courriel
   d'entretien). Aucun « choisissez votre horaire » sans horaire ouvert.
6. **Les comptes égarés existent aussi côté familles** : une personne qui crée un compte sans retrouver sa
   demande. Le rattachement par courriel (#524) doit valoir pour les demandes de famille, et un compte sans
   dossier doit être compté à part dans la liste (patron `compteursPhases.sansDossier`).
7. **Adresses mal écrites** (R25) : la même vérification de forme (gmail.coma, gamil.com…) doit protéger le
   formulaire des familles.
8. **L'âge** : la déclaration « 18 ans ou plus » (MAJEUR) ne s'applique qu'aux candidats enseignants ; un
   élève adulte déclare son âge par sa date de naissance ; ne pas mélanger les deux règles.

## 3. Règles pour toute liste (types de listes)

| Type | Exemples | Règles |
| :--- | :--- | :--- |
| Liste de personnes (une population) | Enseignants, Élèves, Familles, Équipe | Pagination serveur (50), filtres serveur validés (clé inconnue = erreur), compteurs par phase au premier niveau, portée par genre côté serveur, audit de chaque lecture, badge « Nouveau » (7 jours et jamais ouvert, serveur), ligne qui suit la phase |
| File de travail | « À examiner », « Pièces à valider », « Entretiens » | Le geste qui débloque la file est **en tête de la file**, jamais dans « Outils » (43 candidats bloqués faute d'avoir vu « Créneaux d'entretien ») ; précédent / suivant et passage au suivant après une décision |
| Liste enregistrée (vague 3) | « ijaza, libres le soir » | Un filtre enregistré n'est qu'un filtre serveur nommé ; « écrire à la liste » passe par le circuit d'envoi existant, filtré sur `en_cours`, compté avant l'envoi |
| Imprimable | liste PDF ou CSV, fiche | Servi par le serveur, mêmes filtres que l'écran, jamais une copie de liste en mémoire |

Règles communes : une seule barre de défilement (la page) ; une rangée de commandes ; aucune liste entière
en mémoire (constat du 16/11 : le dossier chargeait toute la file des pièces, les comptes chargeaient 1 000
lignes) ; les actions groupées ne proposent que ce que le serveur déclare `groupable`, avec un aperçu puis un
rapport ligne par ligne.

## 4. Méthode qui a marché

- Une carte unique (`ETAT-ET-PLAN`) et une checklist visible tenue à chaque fusion.
- Le pilote vérifie en base **avant** d'affirmer et **après** chaque installation (compte, fonctions,
  droits).
- Migrations : fichier lu depuis `main`, comparé à la copie relue (`diff`), mots d'effacement comptés,
  colonnes lues en production avant l'installation d'une fonction qui lit d'autres tables.
- Les agents disent d'abord ce qui est faux ou non prouvé ; le pilote arbitre vite et par écrit.
