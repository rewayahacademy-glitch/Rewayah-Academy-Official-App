# Vision du recrutement, bout en bout — 14/11/2026

Demande du directeur (14/11) : « une vision globale de tout ce qui est recrutement pour
éviter les bricolages et va-et-vient : qu'as-tu trouvé qui doit être corrigé ou qui manque
pour bien gérer les personnes ? et en termes d'interface ? ».

Cette revue élargit `REVUE_PARCOURS_DIRECTION_2026-11-14.md` (gestes du dossier seulement)
au parcours entier, des deux côtés, et à la gestion des personnes par la direction.

- **Chiffres** : lus en production le 14/11 vers 21 h UTC, en lecture seule. Ils comptent
  les candidatures d'enseignant **en cours**. Toutes ont été reçues le 14/11.
- **Statuts** : `présent dans le code` et `testé localement` seulement. Rien n'est
  « fait » tant que le directeur ne l'a pas prouvé en production.
- **Priorités** :
  - **B** (bloquant) : une personne ou la direction ne peut pas avancer ;
  - **G** (gênant) : on avance, mais avec un va-et-vient ou un risque d'erreur ;
  - **C** (confort).

## 1. Ce qui est vrai en production, en chiffres (14/11)

| Où en sont les personnes | Nombre | Qui doit agir |
| :--- | ---: | :--- |
| Invitations « lien d'inscription » créées à 14 h 09 UTC | 1 601 | — |
| … dont envoyées | 300 | — |
| … dont encore en file (0 tentative) | 1 301 | le plafond : 300 courriels non essentiels par 24 h |
| Candidature commencée, pas envoyée (`a_completer`) | 18 (17 brouillons) | la personne |
| Envoyée, en examen (`en_examen`) | 41 (38 hommes, 3 femmes) | **l'académie** |
| … dont avec une pièce d'identité déposée, en attente | 13 | **l'académie** |
| … sans pièce | 28 | la personne (la pièce se dépose après l'envoi, PR #485) |
| Versement pas encore possible (`paiement_non_disponible`) | 11 | **une décision de l'académie** (CAND-Q05) |
| Entretien à planifier | 1 | **l'académie** |
| Créneaux d'entretien ouverts | **0** | **l'académie** |
| Confirmée (salle 3) | 1 | — |
| Candidatures avec un responsable nommé | **0 sur 72** | — |
| Comptes de connexion sans profil | 8 | personne ne les voit |
| Refus « hors de votre côté » subis par le super-admin | **0** | — |

Lecture de ces chiffres : **42 personnes attendent l'académie, 18 attendent d'elles-mêmes,
11 attendent une décision sur le versement**. Avant cette PR, aucun écran ne disait ça
d'un coup d'œil.

## 2. Le parcours, étape par étape

| Étape | Ce qui marche | Ce qui casse ou manque | Va-et-vient | Prio | Ici ? |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **Invitation** (courriel « lien d'inscription ») | File idempotente, pas de double envoi ; les messages individuels passent avant (migration 20261126100000) | 1 301 courriels en file ; à 300 par 24 h, les derniers partiront dans environ **5 jours**. Lien de connexion (magic link) en français seulement | Le directeur ne voit pas la file d'envoi dans l'app | **G** | Non : décision de quota (voir §5) |
| **Inscription** | Nom en lettres, genre, langue, confidentialité (PR #481) | 8 comptes de connexion sans profil, invisibles de la direction ; 1 personne aiguillée à tort comme tuteur (audit du matin) | Il faut une requête SQL pour les voir | **G** | Non : il faut une file « comptes incomplets », lot à part |
| **Salle 1** (cadre, accords, pièce, questionnaire, envoi) | Brouillon gardé ; pièce déposable dès la salle 1 et après l'envoi (#485) | Pas de correction des réponses après l'envoi ; pays de résidence vide tant que rien n'est envoyé (les 18 `a_completer`) | Une erreur de réponse oblige un échange de messages, puis « Demander une précision » | **G** | Non : décision (rouvrir le questionnaire après envoi ?) |
| **Examen par la direction** | Liste serveur triée, filtres, recherche ; dossier complet avec la conversation dans le dossier (#485) et l'aperçu dans Messages (#484) | **Aucune vue « qui attend quoi »** : il fallait poser les filtres un par un ; « À traiter » ne compte que 2 alertes sur 4 ; 0 responsable nommé | Filtre, retour, autre filtre | **B** | **Oui** : carte « Qui attend quoi » |
| **Super-admin hors côté** | Gestes un par un (décider, vérifier, « Valider la pièce », entretien) déjà permis depuis V1-a-bis (03/11), avec trace | Les **gestes en lot** (pause, reprise, refus) excluaient l'autre côté, même pour le super-admin | Refaire un par un | **B** | **Oui** : migration 20261126400000 |
| **Salle 2** (vérifications, entretien) | Planifier, participants, compte rendu, issue : sur place, en feuilles | **0 créneau ouvert** : aucun candidat ne peut réserver ; la sortie de la salle d'entretien menait à l'accueil, pas au dossier | Accueil, Personnes, Candidatures, recherche, dossier | **B** | **Oui** pour la sortie ; les créneaux sont un geste du directeur (« Créneaux d'entretien ») |
| **Versement** (CAND-Q05) | Référentiel des moyens par pays ; la candidature est gardée, jamais refusée en silence | 11 personnes sans moyen confirmé (Yémen 3, Tchad 2, Égypte, Ghana, Maroc, Bénin, Guinée, Liberia, Sénégal) | Aucune issue tant que rien n'est décidé | **B** | Non : décision métier (recommandation §5) |
| **Salle 3** puis accueil comme enseignant | « Valider la pièce » active le compte, pose langues, fuseau et disponibilités, envoie le courriel de bienvenue | 1 seule personne arrivée là : chaîne peu éprouvée en vrai | — | C | Non |

## 3. Gérer les personnes (côté direction)

| Besoin | État avant | Prio | Ce qui est fait ici, ou la suite |
| :--- | :--- | :---: | :--- |
| Savoir **qui attend quoi de qui** | Absent | **B** | **Fait** : carte « Qui attend quoi », en trois groupes (l'académie, la personne, un moyen de versement). Chaque ligne donne le nombre et l'ancienneté de la plus vieille attente. Toucher une ligne pose le filtre exact (en cours, hors pause, cet état), donc la liste compte ce que la ligne annonce |
| Pièces à valider | Seulement dans chaque dossier ; la file des dossiers ne les voit pas en salle 1 | **G** | Fait en partie : la ligne « Pièce d'identité à valider » (13) dit où les valider. Reste un filtre serveur « pièce en attente » dans la liste (lot suivant, sans décision) |
| Agir **en lot** des deux côtés | Le super-admin était borné | **B** | **Fait** (migration) |
| Responsable par dossier | Le geste existe ; personne ne l'emploie (0 sur 72) | C | Rien : outil utile à plusieurs ; seul, le directeur n'en a pas besoin |
| Relances | Le plafond retarde toute relance de masse ; pas de vue « invités sans inscription » dans la liste | **G** | Suite : une ligne « Invités, pas encore inscrits » dans « Qui attend quoi », quand la file d'envoi sera lue au serveur |
| Tri par ancienneté de l'attente | Tri par dernière activité seulement | C | La carte donne l'ancienneté ; le tri de la liste suffit pour l'instant |

## 4. Interface sur ordinateur (1366 à 1440)

| Constat | Règle | Prio | Ici ? |
| :--- | :--- | :---: | :--- |
| « Qui attend quoi » : trois cartes côte à côte au-dessus de la liste, denses ; empilées au téléphone | Material 3 (supporting pane), Nielsen n° 1 (visibilité de l'état) | — | **Fait** (captures `docs/current/captures/E2E/vision-recrutement/`) |
| La sous-navigation « Candidatures » de Personnes est un **menu déroulant** même à 1440 | Règle 19 (directeur, 14/11) : pas de menus déroulants de téléphone sur ordinateur | **G** | Non : `SousNavigationDomaine` et `SelecteurSection` sont partagés par tous les domaines ; à corriger une fois dans le composant (lot dédié, sans décision) |
| La colonne de contenu plafonne vers 1 136 points à 1440 : la liste a la place d'être plus dense | Densité de bureau | C | Non : réglage de `PageShell`, commun |
| Sortie de la salle d'entretien vers l'accueil | Nielsen n° 3 (contrôle et liberté) | **B** | **Fait** : elle ramène au dossier du candidat |
| Dossier : conversation, pièce, entretien et gestes sur place | « Ne pas faire sortir d'un dossier pour un geste simple » | — | Déjà fait (#485) |

## 5. Ce qui demande une décision, avec une recommandation

| Sujet | Recommandation (une seule) | Pourquoi |
| :--- | :--- | :--- |
| **CAND-Q05** : quel moyen de versement par pays (11 personnes bloquées) | **Le virement bancaire par Wise est la règle partout où Wise verse en monnaie locale. Ailleurs, la candidature est gardée en attente avec un message clair, sans refus.** Concrètement : le directeur vérifie dans Wise les 9 pays (YE, TD, EG, GH, MA, BJ, GN, LR, SN), puis marque « confirmé » ceux que Wise couvre dans le référentiel des moyens. Le serveur recalcule seul (`paiement_recalculer`) | Wise est déjà l'outil de la paie (fichier Wise du mois). Un seul moyen à opérer, c'est moins d'erreurs. La mobile money ajoute un prestataire par pays |
| **Plafond de 300 courriels par 24 h** (1 301 invitations en file) | **Garder le plafond.** Le fournisseur et la réputation du domaine l'imposent : un pic de 1 600 courriels envoie l'académie dans les indésirables. Il faut seulement le montrer à la direction : la file et sa date de fin dans « Qui attend quoi » (lot suivant) | Prudence anti-spam (décision DOMAINE du 23/10) |
| **Corriger ses réponses après l'envoi** | **Non.** La direction emploie « Demander une précision », qui rouvre seulement les champs nommés | Une réponse examinée ne change pas sans trace |
| **Magic link en français seulement** | **Le courriel de connexion dans la langue du compte** (fr, ar, en) : un modèle par langue chez Supabase Auth | 1 160 des 1 601 invitations sont en arabe |

## 6. Ce que cette PR change

1. **Migration `20261126400000_super_admin_lots_et_attentes.sql`**, sans mot d'effacement :
   - les gestes en lot du super-admin portent aussi sur l'autre côté ; le moteur écrit
     déjà chaque geste au journal (`super_admin_hors_cote`) ;
   - nouvelle lecture `attentes_recrutement()` : des nombres seulement, dans la portée du
     lecteur.
2. **Carte « Qui attend quoi »** au-dessus de la liste des candidatures. Sans la
   migration, la carte ne s'affiche pas et rien d'autre ne change.
3. **La salle d'entretien ramène au dossier** du candidat (le billet porte l'adresse de
   retour).
4. **Décision A15** écrite dans `docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md`.
5. **Tests** :
   - widget : `carte_attentes_test.dart` (9), plus le retour « Rejoindre »
     dans `entretien_direction_test.dart` ;
   - SQL : `scenarios_vision_recrutement.sql` (20 contrôles) ;
   - `scenarios_cand_l2a2_gestes_direction.sql` mis à jour pour la nouvelle règle
     (239 contrôles, même total).

   Ils ont été rejoués sur un Postgres 16 local. La CI tourne en Postgres 17, et
   `ci.yml` ne liste pas ces deux scénarios.

## 7. Ordre conseillé pour la suite (sans décision nouvelle)

1. Le directeur ouvre des créneaux d'entretien. C'est le seul blocage qui ne demande
   aucun code.
2. Un filtre serveur « pièce en attente » dans la liste.
3. La sous-navigation de Personnes en ligne sur ordinateur (composant partagé, une fois).
4. Une file « comptes incomplets » (8 comptes sans profil) et la ligne « invités pas
   encore inscrits ».
