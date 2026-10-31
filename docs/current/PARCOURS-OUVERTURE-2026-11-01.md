# Ligne d'arrivée : les parcours qui suffisent pour ouvrir l'académie (carnet de test du directeur, 01/11/2026)

Décision du directeur du 31/10 au soir : ces parcours sont la ligne d'arrivée. Toute ligne que le
directeur marque « ne marche pas » passe **avant** tout autre lot. Rien de nouveau hors de ces
parcours et du branchement de l'existant (`INVENTAIRE-NON-BRANCHE-2026-10-31.md`).

Adresse : https://app.rewayahacademy.com. Relevé du pilote le 31/10 à 19 h 15 (UTC), sur `main`
(`c749bab36`) et dans la base de production, en lecture seule.

## Ce qui est faux, bloqué ou non prouvé, d'abord

- **Paiement (parcours 7, fin) : bloqué.** Sans la clé Stripe dans les fonctions de production,
  « Recharger » répond « Recharge pas encore disponible ». Aucun paiement réel n'a jamais été fait.
- **Valider un enseignant (parcours 1) ne peut pas être rejoué tel quel** : le seul compte
  enseignant de production est déjà actif. Il faut un nouveau compte enseignant en attente.
- **Inscription (parcours 3)** : l'envoi réel des e-mails de confirmation n'a jamais été prouvé.
- **Cahier hebdomadaire (parcours 6)** : pas encore en ligne (PR 103, tests en cours). Aujourd'hui,
  l'application demande un cahier **par séance**.
- **Coran dans la salle** : on change de page avec les flèches, **pas en glissant le doigt** (lacune
  connue, lot après l'ouverture).
- **La prochaine séance prévue en production est le 4 novembre.** Pour tester la salle le 1er,
  créer d'abord une classe dont la séance commence dans l'heure (parcours 2).

## Comptes et appareils

Comptes présents en production le 31/10 : 1 direction, 1 enseignant (actif), 3 tuteurs (dont
2 apprennent eux-mêmes : élèves adultes), 4 élèves enfants, 3 classes actives d'un élève chacune.
Les adresses ne sont pas écrites ici : le directeur les connaît.

Appareils : **un ordinateur** (direction, puis enseignant) et **un téléphone** (famille, élève ou
élève adulte). Pour la salle, il faut deux appareils en même temps : l'enseignant sur l'un,
l'élève sur l'autre. Une fenêtre de navigation privée sur l'ordinateur permet d'ouvrir un second
compte sans se déconnecter du premier.

## Les parcours

État : **marche** (déjà fait en production, preuve en base), **à essayer** (branché et installé,
jamais joué par le directeur), **bloqué**.

### 1. La direction valide un enseignant — à essayer

Qui : direction (ordinateur), puis enseignant. Compte : un **nouveau** compte enseignant en attente.

1. Direction : Personnes, onglet « Dossiers à valider » (ou la tuile du même nom sur l'Accueil).
2. Ouvrir le dossier, « Voir la pièce » : la photo s'affiche.
3. Cocher « La pièce est lisible », « Le nom correspond à celui du compte », « La pièce n'est pas
   expirée ».
4. « Valider le dossier ». Message attendu : « Dossier validé. »
5. Se connecter avec le compte enseignant : il arrive sur « Aujourd'hui », plus sur la page
   d'attente.

Preuve lue : `decider_dossier` et la fonction `piece-identite-acces` présentes en production.

### 2. La direction crée une classe à plusieurs séances — à essayer

Qui : direction (ordinateur), puis enseignant. Comptes : direction, enseignant actif.

1. Opérations, onglet « Classes », « Nouvelle classe ».
2. Choisir le public, le genre, l'enseignant. « Ajouter un créneau » : un jour et une heure.
   Pour tester la salle le jour même, **une heure dans l'heure qui vient**. Ajouter un second
   créneau pour avoir plusieurs séances par semaine.
3. « Créer la classe ». La classe apparaît, active, avec son enseignant.
4. Enseignant : onglet « Classes » : la classe et sa prochaine séance.

Preuve lue : `creer_classe_creneaux_admin` en production ; 3 classes déjà créées ainsi.

### 3. Une famille et un élève adulte s'inscrivent, la direction les accepte — à essayer

Qui : famille et adulte (téléphone), puis direction (ordinateur). Comptes : **deux nouvelles
adresses e-mail** à vous.

1. Téléphone : « Créer un compte ». Choisir « J'inscris mon enfant » (famille) ou « Je m'inscris
   pour moi » (adulte).
2. Ouvrir le lien reçu par e-mail, remplir nom et genre, « Envoyer ma demande ».
3. L'écran dit « Votre demande est en cours » et ce que la demande contient.
4. Direction : Personnes, onglet « Demandes », liste « Familles » ou « Élèves adultes ».
   « Accepter la demande … ».
5. La famille se reconnecte : elle arrive sur son Accueil. **C'est à ce moment que le profil de
   l'enfant est créé** : la famille doit ouvrir son Accueil une fois avant qu'on place l'enfant
   (parcours 4).

Preuve lue : `inscrire_titulaire`, `ma_demande_admission`, `accepter_admission` en production.
Risque : l'e-mail de confirmation (point 2) n'a jamais été prouvé.

### 4. La direction place un élève dans une classe — à essayer

Qui : direction (ordinateur), puis famille (téléphone).

1. Opérations, « Classes », ouvrir la classe, « Ajouter un élève », choisir l'élève, « Ajouter ».
2. Famille : son Accueil montre l'enfant, sa classe et l'heure de la prochaine séance.
   Élève adulte : son Accueil montre sa classe.

Preuve lue : `ajouter_eleve_groupe` en production ; 3 élèves déjà placés ainsi.

### 5. Tenir la séance : Rejoindre, vidéo, page du Coran — marche

Qui : enseignant (ordinateur) et élève (téléphone), **en même temps**.

1. La salle s'ouvre **20 minutes avant** l'heure, pas avant.
2. Enseignant : « Aujourd'hui », « Rejoindre la salle ».
3. Élève enfant : sur l'appareil connecté au code du foyer, Accueil, « Rejoindre ». Ou le tuteur,
   sur son propre Accueil : « Rejoindre la salle avec … ». Élève adulte : son Accueil, « Rejoindre ».
4. Chacun voit et entend l'autre.
5. Enseignant : « Outils », « Page », choisir une page ; l'élève la voit. Changer de page avec
   « Page suivante » (le glissement du doigt ne marche pas encore).

Preuve lue : 10 séances déjà closes et 117 entrées en salle enregistrées en production.

### 6. Présence et cahier — à essayer

Qui : enseignant (ordinateur), après une séance tenue.

1. Rien à cocher : la présence se calcule seule sur les minutes passées en salle. Présent à 50 %
   du temps prévu ou plus, partiel au-dessous, absent à zéro.
2. « Aujourd'hui », section « À terminer », ligne « Cahier de transmission … ».
3. Remplir, puis « Valider le cahier de transmission ».

Preuve lue : présence aux minutes installée le 31/10 (réglage `presence.seuil_present_pourcentage`
à 50) ; `brouillon_cahier` en production. Le cahier hebdomadaire arrive avec la PR 103.

### 7. La famille voit la classe, la présence, et paie — à essayer, paiement bloqué

Qui : tuteur (téléphone).

1. Accueil : chaque enfant, sa classe, sa prochaine séance. « Voir la classe ».
2. Onglet « Historique », ouvrir une séance passée : heure d'arrivée, de sortie, minutes, présence.
3. Onglet « Foyer », « Recharger », « Payer … » : **bloqué** tant que la clé Stripe n'est pas
   posée dans les fonctions de production.

Preuve lue : `presence_temps_seance` en production. Reçu ou facture à télécharger : non branché.

### 8. L'élève adulte suit sa classe — à essayer

Qui : tuteur qui apprend lui-même (téléphone). Compte : l'un des deux tuteurs qui ont un profil
élève, placé dans une classe.

1. Se connecter : l'Accueil de l'élève adulte s'ouvre, avec son prénom et **sa** classe.
2. « Rejoindre » à l'heure (parcours 5).
3. Après une séance : « Dernières séances », « Voir tout ».

Preuve lue : lectures de l'élève adulte installées en production le 31/10 (PR 99). L'écran
« Ma classe » de l'adulte n'a pas encore d'entrée. L'onglet Profil ouvre le compte du tuteur.

## Journal du directeur

| Date | Parcours | Marche / ne marche pas | Capture ou phrase affichée |
|---|---|---|---|
| | | | |
