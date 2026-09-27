# Vague Contrôleur : planches du directeur, comparaison avec l'existant, rectifications

**Date.** 27/09/2026, étape CT-0.

**Sources.**
- `PLANCHE-1..5.png` (dans ce dossier, dans l'ordre des noms de fichiers reçus).
- Décisions du directeur du 27/09 : `projet/ressources:specs/08_controleur/00_DECISIONS_DIRECTEUR.md`. **Elles priment sur tout le reste.**
- Document `projet/ressources:specs/08_controleur/08_CONTROLEUR_V1_UX_SECURITE.md`.
- Règles réutilisables `memoire/CONTROLEUR-2026-09-27.md` (C1 à C21).

**Règle de la vague** : ne rien jeter sans comparer ; perfectionner l'existant sans le recommencer ; construire ce qui manque ; tout suit K-42 (style CL-4).

## 1. Classement

| Planche | Contenu | Rôle |
|---|---|---|
| 1 | Vue d'ensemble : 01A menu, 01B prochaine visite, 01C détails avant entrée, 02A salle en observation, 02B fin de séance (faits automatiques), 02C compte rendu étape 1, 03 tableau de bord web. | Contrôleur permanent |
| 2 | CTR-01A Contrôle (mobile clair), CTR-01B détail de la visite (mobile sombre), CTR-03A compte rendu étape 1 (mobile clair). | Contrôleur permanent |
| 3 | CTR-03B observation détaillée, CTR-03C récapitulatif, CTR-04 échanges avec l'administration. | Contrôleur permanent |
| 4 | CTR-01D Contrôle, web sombre (prochaine visite, couverture, mes observations, messages admin, visites récentes). | Contrôleur permanent |
| 5 | « Mission invitée » (contrôle invité, accès temporaire, périmètre autorisé). | **Contrôleur invité : hors lot** (doc §1.3, C20), gardée en réserve |

**Les deux décisions du directeur (27/09) qui corrigent toutes les planches.**
1. **La visite a lieu pendant le cours** (C1). Les planches montrent des visites planifiées à l'avance (« Visites à venir », « Voir le planning », « Mer 25 sept. »), un bouton « Plus tard » et un écran de détail avant l'entrée. Tout ce qui laisse le contrôleur choisir son moment est retiré : la mission n'est actionnable que lorsque la séance est en direct.
2. **Le rapport est transmis automatiquement** (C2). La planche 3 (CTR-03B) montre un interrupteur « Canal direct admin · Partager cette remarque avec l'administration » : il est **retiré**. Le rapport part toujours. Le bouton qui reste s'appelle « Écrire à l'administration » (libellé du doc P-CTR-06) et ouvre la discussion directe CTR-04.

## 2. Existant (inventaire détaillé dans `../00_REPRISE.md`)

- `CTR-01` = `lib/features/controleur/planning_page.dart` (498 lignes) + `vue_planning.dart` (255) : **planning global de toutes les séances** (heure locale et UTC, filtres), sans barre de navigation. Contredit le doc §3.2, §3.3, §5 : à refondre.
- `CTR-02` = `/salle` en rôle `RoleSalle.controleur` (`vue_salle.dart:60`, `salle_page.dart:726`) : rappel « Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal. » + `PermanentNotice`. À garder.
- `CTR-03` à `CTR-06` : rien. Aucun composant de fil de discussion dans `lib/`.
- `/compte` > Espaces : `_espacesPour(AppRole)` n'affiche que le rôle unique de la session (« SessionState porte un seul rôle effectif », `compte_page.dart:726`). La commutation Enseignant ou Admin → Contrôle n'existe pas.
- Côté admin (révision 2fac423) : `admin_observations/observations_admin_page.dart` (historique des observations, MAN #26) ; aucun écran de rapports contrôleur ni d'échanges.

## 3. Comparaison planche par planche

Légende : **G** garder de l'existant ; **P** prendre de la planche ; **C** corriger (erreur de la planche ou contradiction avec une règle).

### Planche 1 (vue d'ensemble)

**01A Menu principal.**
- P : le sélecteur d'espace en tête de la barre latérale (« Contrôleur ▾ »), comme raccourci qui ouvre **le même** sélecteur que `Compte > Espaces` (doc §4.2, C6) ; l'identité en pied avec la mention du contexte.
- C :
  1. Cinq destinations (Accueil, Mes visites, Historique, Échanges, Mon compte) → quatre : Contrôle, Historique, Échanges, Compte (C13).
  2. « Mes visites » est retiré : pas de planning (C1, C3).

**01B Prochaine visite / 03 Tableau de bord web.**
- P : la carte dominante (heure, Classe, enseignant avec photo, nombre d'élèves) ; la ligne d'invisibilité dans la carte ; deux colonnes sur bureau (mission à gauche, état et rapports à terminer à droite).
- C :
  1. Titre « Prochaine visite » → « Votre prochaine mission » (doc CTR-01).
  2. « Ouvrir la salle », « Voir la mission », « Rejoindre la salle » → un seul bouton « Commencer le contrôle », présent **seulement quand la séance est en direct** (C1, C14). Avant : ligne calme, jamais un bouton grisé (R4).
  3. Pastille « À effectuer aujourd'hui » retirée : l'emplacement dit déjà l'état (K-42 point 3).
  4. « Visites de cette semaine 1/4 · 25 % » et « Couverture cette semaine » (barre) retirés ; au plus « Cette semaine : N contrôles réalisés » (C11).
  5. « Mes observations » (0 Conforme, 1 Remarque, 0 À suivre) retiré : c'est un score (C11).
  6. « Messages admin » et « Mes visites récentes » retirés de CTR-01 : ils ont leur destination (Échanges, Historique ; doc §5, E3). La colonne de droite ne garde que « Compte rendu à terminer ».
  7. Cloche retirée (notifications non garanties, C13).
  8. « Arabe · Niveau 2 · Groupe B » : « Groupe » est interdit (E17) ; la ligne de contexte vient des données (objectif ou cycle, doc §8.1).
  9. « 18 élèves » : taille irréaliste ; elle vient des données de démonstration (C19).

**01C Détails avant entrée.**
- P : les rappels utiles (« Entrée en mode incognito », « Aucune interaction possible », « Compte rendu à compléter après la séance ») condensés **en une ligne** dans la carte de mission.
- C : l'écran intermédiaire est supprimé. Le cours a déjà commencé ; une page de plus retarde l'entrée (C1, C14). « Données enregistrées automatiquement » devient la notice des faits dans le compte rendu.

**02A Salle en observation.**
- G : `/salle` rôle contrôleur, le rappel existant et `PermanentNotice` ; le support dominant ; la reconnexion réelle (R12).
- P : zone haute visible du seul contrôleur avec « Quitter » ; la rangée des vignettes élèves avec « +N ».
- C :
  1. « Mode observation » → « Contrôle Rewayah » (doc CTR-02).
  2. « 14:08 » (heure) : la durée de présence personnelle est reportée avec LIVE-CHRONO-01 (question au directeur) ; jamais un grand compteur.
  3. Le texte « Vous observez en mode invisible. Aucune interaction possible. » ne remplace pas le rappel existant (G) : un seul rappel.
  4. Bouton « Quitter » rouge plein : c'est une sortie normale, pas une action destructive ; action secondaire (Contrat B).
  5. Commandes à ajouter : Son reçu, Agrandir le support. Rien d'autre (C5).
  6. Vignettes : flux en direct seulement selon la projection autorisée ; pas de photo d'élève hors flux (question).

**02B Fin de séance.**
- P : les faits automatiques en lecture seule (durée prévue et réelle, début prévu et réel, participants, connexions) ; « Plus tard » ramène au bloc « Compte rendu à terminer » (le rapport est déjà transmis, C2).
- C :
  1. Titre « Fin de séance » faux : le contrôleur sort **pendant** le cours ; la fin réelle peut ne pas exister. Cet écran devient l'en-tête des faits de CTR-03 « Compte rendu », avec « En cours » si la séance continue.
  2. « + 8 min » et « 41 min » en rouge seul → un mot (« 8 min de retard »), la couleur doublée (C4).
  3. Ligne « Enregistrement : Oui » retirée : absente des faits du doc §1.1 (C4).
  4. Deux écrans séparés (faits, puis question) → un seul : faits repliés en tête, question dessous (un écran de moins).

**02C Compte rendu (étape 1).**
- P : la question « Avez-vous quelque chose à signaler ? » et les trois cartes.
- C : « Suivant » sans sélection ; « Rien à signaler » s'envoie en une action (doc P-CTR-04, C15) ; le compteur d'étapes « 1 2 3 » varie selon le choix, il n'est montré qu'à partir de l'étape 2.

### Planche 2

**CTR-01A Contrôle (mobile clair).**
- P : le titre « Contrôle » et la carte de mission en tête ; la ligne « Visite en mode incognito · Votre présence n'est pas annoncée à l'enseignant » (condensée).
- C :
  1. Sous-titre « Suivez vos visites et contribuez à la qualité… » retiré (un bloc de moins, K-42).
  2. Tuile date « Lun 23 sept. 2024 » : la mission est celle d'une séance en direct ; l'heure suffit. Dates 2026 (C19).
  3. Anneau « 3/5 » et « Visites restantes, Total prévu » retirés (C11, C3).
  4. « Visites à venir » et « Voir le planning » retirés (C1, C3).
  5. Barre basse Accueil, Visites, Rapports, Compte → Contrôle, Historique, Échanges, Compte (C13).
  6. Cloche retirée.

**CTR-01B Détail de la visite (mobile sombre).**
- C : écran supprimé (voir 01C). « Objectif de la visite » générique retiré : c'est l'objectif de la séance qui compte (doc §8.1). Les coches « Fiche d'observation prête », « Connexion et matériel OK » sont de fausses vérifications (E7) : la préparation du contrôleur est silencieuse (R13, pas de micro ni caméra).

**CTR-03A Compte rendu (mobile clair).**
- P : en-tête « Compte rendu » + ligne de contexte (Classe · enseignant) ; les trois cartes avec icône, titre, une ligne.
- C : « Rien à signaler » présélectionné (bord vert) → aucune présélection (doc CTR-03) ; « Étape 1 · Retour sur la visite » retiré (bloc en trop) ; « 1/4 » faux (voir 02C).

### Planche 3

**CTR-03B Observation détaillée.**
- P : l'en-tête de parcours (titre, contexte, progression) ; le champ « Votre remarque » avec l'aide « Décrivez seulement ce que vous avez observé. » (placeholder du doc).
- C :
  1. **Interrupteur « Canal direct admin · Partager cette remarque avec l'administration » retiré** (directeur 27/09, C2). Aucune option de partage : le rapport part automatiquement.
  2. Tout sur une page → une question par page (doc P-CTR-05) : nature, domaine, personne concernée, texte, récapitulatif.
  3. « Type d'observation : Qualité pédagogique » (liste déroulante) → cartes de choix avec les libellés du doc (C16).
  4. « Rechercher une personne… » (enseignant, élève ou membre de l'équipe) retiré : choix Enseignant, Classe entière, Élève précis (roster autorisé), Aucun participant précis (C3, C8).
  5. Compteur « 168/500 » retiré tant que le serveur ne fixe pas de limite (C15).
  6. Texte obligatoire selon la gravité (doc étape 4) : question au directeur, choix provisoire consigné.

**CTR-03C Récapitulatif.**
- P : « Détails de l'observation » et « Informations automatiques » en lignes clé-valeur (`LigneCleValeur`) ; « Envoyer le compte rendu » dominant ; « Modifier » en lien, **avant envoi seulement**.
- C : incohérence des données (enseignant « Karim Belkacem » en tête, « Yusuf Diallo · Enseignant » mentionné) → données cohérentes (C19) ; une notice sous le bouton dit que le compte rendu est transmis automatiquement à l'administration (texte à valider, question).

**CTR-04 Échanges avec l'administration.**
- P : le fil de messages, l'identité de l'expéditeur, le champ « Répondre à l'administration… » et le bouton d'envoi.
- C :
  1. Onglets « Tous, Non lus, Mes demandes » retirés : une liste de fils par mission ou sujet, avec état « Réponse reçue » / « En attente » (C17).
  2. Contexte de la visite **épinglé en haut** du fil (Classe, date, heure), joint automatiquement (doc P-CTR-06).
  3. Trombone (pièce jointe) retiré : ni export ni fichier au contrat (doc CTR-02, §8.2).
  4. Les prénoms d'élèves dans les messages : minimisation (C8) ; la démonstration n'en cite pas.
  5. Le contrôleur « Karim Belkacem » est aussi l'enseignant d'une autre planche (C19).

### Planche 4 (CTR-01D web sombre)

- P : la barre latérale réelle, le titre « Contrôle » en tête, la carte de mission et son bouton à côté du contexte (R20).
- C :
  1. Barre latérale : Contrôle, Historique, Échanges, Mon compte (4), sans « Mes visites » (C13).
  2. Bascule de thème et icône profil en en-tête retirées : le thème est dans `/compte` (K-37).
  3. « Couverture de la semaine » (anneau 3/5, « Voir le planning ») et « Mes observations » (8 Conformes, 3 Remarques, 1 À suivre) retirés (C1, C3, C11).
  4. « Messages admin » : les fils sont titrés par des personnes (Sayyida Amina, Omar Bah, Fatima Zahra) → fils par mission ou sujet, dans Échanges seulement (C17).
  5. « Visites récentes » en tableau à 7 colonnes (Niveau coloré, Élèves, « … ») → Historique en lignes groupées (C18), hors de CTR-01. Statuts « Terminé, Remarque, À suivre » → « Envoyé, Complément ajouté, À terminer » (doc CTR-05).
  6. Identité « Admin · Contrôleur » en pied : bonne illustration du contexte de travail (P), à garder sous la forme « nom · Contrôle ».

### Planche 5 (Mission invitée)

Hors lot (doc §1.3, C20). Notes pour la future étape du contrôleur invité, sans rien construire :
- à garder : accès temporaire, actions journalisées, expiration automatique, périmètre autorisé en lignes clé-valeur ;
- à corriger le moment venu : « Invité par Karim Belkacem · Enseignant » (qui peut inviter n'est pas décidé), décompte « Valide encore 8 h 42 min » (R5 et C1 : la mission vaut pendant le cours), « Commencer la mission » soumis à C1, trois étapes « Vérifier votre matériel / Consulter les consignes / Commencer la séance » (fausses vérifications, E7), « Aucun profil créé » à vérifier juridiquement.

## 4. Ce qui touche d'autres rôles

| Élément | Rôle concerné | Règle, sans rouvrir de lot |
|---|---|---|
| Commutation Enseignant ou Admin → Contrôle | Compte partagé, Enseignant, Admin | `Compte > Espaces` seul point canonique ; en démonstration seulement jusqu'à BR-1 (projection serveur des capacités). |
| Exclusion de sa propre Classe | Enseignant-Contrôleur | Décidée par le serveur ; la démonstration montre le cas. |
| Aucune alerte de visite | Enseignant | Rien à construire ; test de non-régression : aucune annonce ni compteur côté enseignant. |
| Synthèse mensuelle « ENS - Qualité et parcours professionnel » | Enseignant | Backlog seulement (doc §12), ligne au tableau. |
| Rapports reçus, file, signalements urgents, fil avec le contrôleur, couverture, attribution de la capacité | Admin | Registre Administration finale (doc §13, 18 points), ligne au tableau ; MAN #26 (`admin_observations`) consomme les visites contrôleur dans le même domaine d'audit. |
| Signal « Suivi qualité Rewayah effectué ce mois-ci » | Tuteur, famille | Proposition du doc §3.4, en attente du directeur ; rien construit. |
| Porte `/tc/observation` | Tuteur | Reste au tuteur ; aucun partage de code d'écran avec le contrôleur. |
| Vignettes en salle | Élève | Rien ne change pour l'élève : le contrôleur est invisible. |
