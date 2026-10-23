# Intégrer le programme dans l'application : proposition UX/UI

**14 octobre 2026. Statut : PROPOSITION, à valider par le directeur avant toute fiche de catalogue ou tout code.**

**Ce que le directeur a demandé.** Chaque personne ne voit que ce qui la concerne, jamais tout le programme. Par exemple, le tuteur d'un enfant de 8 ans voit, dans le profil de son enfant, la partie des 6-9 ans. La lecture doit être intuitive, facile à comprendre, avec des mots simples et sans langage inventé.

**À quoi s'appuie cette proposition :**

- **Les règles du programme** : la compétence `programme-rewayah`, le vocabulaire de la compétence `mots-rewayah`, et le registre `REGISTRE-RECONCILIATION-2026-10-14.md`.
- **Les écrans qui existent déjà** : on ne crée aucune nouvelle destination de navigation. La spécification `PED-PROGRESSION/PED_PROGRESSION_SPEC_VERTICALE_V1.md` (écrans `PED-PROG-*`) fixe déjà les pages, les états et les textes. Cette proposition y ajoute **le contenu du programme**.

## 1. Le principe : le programme est une donnée, pas une page

- Le serveur garde le programme découpé **par tranche d'âge et par étape**. Pour chaque étape :
  - la phrase de bénéfice ;
  - l'objectif ;
  - la matière principale et la matière secondaire ;
  - la durée prévue et la date limite ;
  - le travail à la maison ;
  - la façon dont l'étape est vérifiée ;
  - les lignes des supports.
- L'application demande seulement **l'étape de cet élève-là** et la montre. Elle ne télécharge jamais le programme entier pour le filtrer sur l'appareil.
- Une donnée absente reste absente : pas de date inventée, pas de barre de progression calculée par l'application.
- **Conflit tranché** : la spécification du 11/10 interdit de montrer une « date estimée » calculée par l'application. La décision du 14/10 impose une **date limite**. Les deux tiennent ensemble : la date limite est **calculée et servie par le serveur**, puis affichée telle quelle.

## 2. Ce que voit chaque personne

### Tuteur (vouvoiement)

| Où (écran existant) | Ce qu'il voit en plus | Mots à l'écran |
|---|---|---|
| **Accueil**, carte de l'enfant | Une seule ligne : l'étape en cours et la date limite | « Étape 2 sur 4 : Lire avec les voyelles · à finir avant le 12 mars » |
| **Foyer → enfant → Classe → Progression** (`ProgressionClassePage`, PED-PROG-TUT-01) | Le bloc **« Où il en est »** : l'étape, ce qu'il saura faire (le bénéfice), la matière principale et la matière secondaire, la durée prévue et la date limite. En dessous, **« Son parcours »** : les 4 étapes de sa tranche d'âge, la sienne mise en avant, les autres repliées. Rien des autres tranches. | « Où il en est », « Ce qu'il saura faire », « Ce qu'il apprend », « Matière principale », « Matière secondaire », « À finir avant le… », « Son parcours » |
| **Classe → Travail à préparer** (`TravailClassePage`) | Les 3 actions du prochain cours, plus **« Emploi du temps de révision »**, consultable dans l'app ou imprimable, jour par jour. Il est tiré du travail donné dans le cahier. | « À faire avant le prochain cours », « Emploi du temps de révision », « Imprimer » |
| **Historique → Détail de séance** (`DetailSeancePage`) | Si l'enfant était absent : **« Rattraper ce cours »**, avec la ligne exacte où la classe s'est arrêtée, la lecture enregistrée de la leçon et le travail donné | « Il était absent. Voici ce qu'il doit rattraper avant le prochain cours. » |
| **Foyer → enfant** | **« Demander une pause »** : un mois entier, au moins 7 jours avant. L'écran montre la règle avant la demande | « Demander une pause d'un mois », « Ce mois n'est pas facturé. La date limite recule d'un mois. » |
| Notification | Seulement trois cas : la date limite approche, l'étape est validée, il y a un cours à rattraper | Phrases courtes, avec un seul bouton qui ouvre le bon écran |

### Élève enfant, Interface guidée (tutoiement)

L'espace de sa Classe (`EspaceGroupePage`, PED-PROG-ELV-01) affiche trois informations au plus, toujours **après** le bouton « Rejoindre » :

- « Ce que j'apprends » : le nom simple de l'étape ;
- « Mon prochain travail » : ses lignes, avec un bouton « Écouter » ;
- « Ce que je sais faire » : la dernière étape validée.

Pas de date limite, ni de compétences ou de mots d'évaluation. C'est le tuteur qui porte la date.

### Élève adulte (vouvoiement, sans infantiliser)

L'onglet **Suivi** montre ce que voit un tuteur, à la première personne : « Où j'en suis », « À finir avant le… », « Mon parcours », « Emploi du temps de révision », « Demander une pause », « Rattraper un cours ».

### Enseignant

- **Rien de nouveau à saisir.** Le cahier K-45 reste gelé.
- Dans la préparation de la Classe : l'étape de la classe, la ligne de reprise (support, page, ligne) et **une alerte quand un élève approche de sa date limite**.
- Depuis la fiche d'un élève : « Proposer à l'évaluation », comme prévu le 12/10.

### Administration

- **Pédagogie → Progression** (`ADM-11`) : une colonne « À finir avant », et un filtre « Date limite dépassée » qui forme la file des élèves à revoir avec la famille.
- **Configuration**, une seule page de réglages du programme :
  - les tranches d'âge ;
  - les durées et dates limites par étape ;
  - le nombre de leçons avant consolidation ;
  - les dates de fermeture de l'année ;
  - les versions du programme.

## 3. Les mots

On n'invente pas de langage. Le tableau complet est dans `.claude/skills/mots-rewayah/SKILL.md`. L'essentiel :

| On écrit | On n'écrit pas |
|---|---|
| étape, les bases, Classe | palier, module, cycle, Fondations, groupe |
| matière principale, matière secondaire | essentiel, en plus, fil |
| à finir avant le… | deadline, échéance académique |
| Étape validée · Quelques points sont à renforcer · Une nouvelle vérification est nécessaire | Réussi, Échec |
| À renforcer · Acquis · Stable | En progrès, Maîtrisé, À revoir |
| rattraper ce cours | rattrapage offert, cours de remplacement pour l'élève |
| lire tout le Coran, mémoriser le Coran | Tilawah, Hifz, T1, H0 |

## 4. Ce qu'il faudra au serveur (Codex, après validation)

1. **Le programme**, rangé par tranche d'âge et par étape et versionné. La table `programme_niveaux` est vide aujourd'hui.
2. **Une projection par élève** : l'étape, la date prévue et la date limite (repoussée par les fermetures et les pauses accordées), et la matière principale et secondaire du moment.
3. **La reprise** : support, page et ligne, tirés de la page affichée en classe, sans saisie de l'enseignant.
4. **La demande de pause**, avec ses règles : un mois entier, 7 jours avant.
5. **L'emploi du temps de révision**, tiré du travail donné dans le cahier.
6. **Les réglages** : tranches 6-9 / 10-13 / 14-17 / 18+, dates limites, consolidation, calendrier des fermetures.

## 5. Ordre proposé

1. Validation de cette proposition par le directeur.
2. Ajout des fiches au catalogue : enrichissement de PED-PROG-TUT-01, ELV-01, ENS-01 et ADM-01, plus « Rattraper ce cours », « Demander une pause » et « Emploi du temps de révision ».
3. Contrats serveur pour Codex.
4. Écrans, un par un, avec leurs états de chargement, contenu, vide, erreur et hors connexion.
