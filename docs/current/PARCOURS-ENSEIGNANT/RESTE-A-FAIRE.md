# RESTE À FAIRE du parcours de l'enseignant et des maquettes — ALERTE PERMANENTE

**Écrit le 21/11/2026 à l'arrêt du pilote, sur ordre du directeur : « tu les mets quelque part où chaque
agent sera obligé de les voir même après 2 mois ».** `CLAUDE.md` y renvoie dans « Toujours, avant tout ».
Tout agent qui touche au parcours du candidat ou de l'enseignant, au bureau de la direction, à Praxis, à
une page de connexion, de chargement ou de mise à jour, à une liste ou à une icône lit ce fichier AVANT
d'écrire une ligne, et y raye ce qu'il livre (statut + numéro de PR + date), le jour même.

Règle (directeur, 21/11/2026 : « Ce qui doit rester consigné doit être les tâches programmées mais jamais
faites encore ») : ce fichier ne garde **que ce qui est prévu et pas encore fait**. Ce qui est livré dans
`main` en sort le jour même (son historique reste dans `SUIVI.md` et dans git). Rien n'est « fait » tant
que le directeur ne l'a pas prouvé en production : au 21/11/2026, **un seul lot est prouvé** (PE-A5, lien de
connexion par courriel, PR 656) ; tout le reste de ce qui est dans `main` attend sa preuve.
Le détail de chaque lot est dans `PLAN.md` ; la check-liste et le journal dans `SUIVI.md` ; les maquettes
validées dans `maquettes/` (et les adresses des pages remises au directeur dans `SUIVI.md`).

## 1. Ce qui reste des MAQUETTES validées, pas encore dans l'application

| Maquette | Ce qui manque | Lot |
| :--- | :--- | :--- |
| « Praxis vous accueille » (version 3, confirmée le 20/11) | **Écran de chargement** avec Praxis (rien) ; **écran de mise à jour** avec Praxis (rien) ; la page de connexion est faite (#664, #671) mais pendant l'écriture de sa phrase, un mot passe sur la toque de Praxis (défaut vu en production le 21/11) | PE-F8 |
| Tableau de bord (validé le 20/11, « on valide cette maquette pour aller vite ») | Visages sur les tuiles de plus de 50 personnes (tri serveur par ancienneté manquant) ; la pile des pièces se feuillette mais **ne décide pas** (pas d'annulation côté serveur) ; cases « candidats vus en 24 h » et « retraits » remplacées par des cases d'alerte en ambre (compteurs serveur manquants) ; boutons sans icône ; coins de 24 ; tuile bloquée en rouge sombre ; au téléphone, une case « Outils » à la place de la liste de raccourcis ; **le Praxis du tableau de bord n'est pas celui de la maquette « Praxis vous accueille »** (à unifier sur `lib/core/vivant/praxis_vivant.dart`) | PE-C6, PE-F5 |
| Composants vivants (§13 du plan) | File d'avatars, bulle, capsule liquide | PE-F7 |
| Langage de mouvement | La décision datée qui amende `DECISION-MOUVEMENT` n'est pas écrite ; la compétence du mouvement n'existe pas | PE-F3, PE-F6 |
| Icônes | Nouvelle famille d'icônes fixes ; une quinzaine d'icônes animées (paquet Lottie : `pubspec.yaml`, licence) | PE-F1, PE-F2 |
| En-tête du bureau | Panneaux légers (messages avec réponse rapide, notifications, annonces) ; recherche qui trouve les personnes | PE-C7 |
| Accueil du candidat | Fusionné (#662) après une première version jugée non fidèle : **fidélité à la maquette jamais confirmée par le directeur** ; question ouverte : que garde l'onglet « Académie » | PE-B4, PE-B5 |
| Trois pages : Accueil, Personnes, Messages, le reste dans « Plus » | « Plus » n'existe pas (le menu réduit, le menu « Outils » et les retours vers Personnes sont dans `main` depuis le 21/11, PR 683) | PE-C8 |
| Gestes | Retour par glissement, glisser une ligne pour agir, glisser pour répondre | PE-D10 |
| Interface de l'enseignant (vague E) | **Rien de construit.** Ne rien lancer sans ordre du directeur ; relire d'abord la maquette recadrée et ses commentaires | PE-E1, PE-E2 |

## 2. Lots du plan pas commencés ou en partie

- Vague P (fluidité) : PE-P1 mesure sur les trois appareils du directeur, PE-P3, PE-P4 ; PE-P2 éclair coloré non corrigé.
- Vague A : PE-A2 (adresse préremplie et marque dans le lien : serveur), PE-A4 (geste « ce compte est un candidat enseignant »), PE-A7 (PR 655 : **ne pas fusionner** sans décision ; sa migration 942000 est à renuméroter après 966000), PE-A9 (rôle associé côté serveur).
- Vague B : PE-B2 (un seul nom par élément), PE-B6 (partage), PE-B7 (modifier après envoi), PE-B9 (réponses toutes prêtes : le guide de l'enseignant est dans `main` depuis le 21/11, PR 665 ; **reste** la partie serveur des avis « J'aime » / « Pas clair » et des commentaires (`commenter_guide`, `commentaires_guide_direction` avec les « Pas clair » par partie, `repondre_commentaire_guide`), sans laquelle la barre d'avis ne s'affiche pas ; la liste de la direction, triée par « Pas clair » ; Praxis qui clarifie seulement depuis le texte validé ; les trois promesses du guide que l'application ne tient pas (45 % enfants, absent payé à moitié, arabe langue de cours), `docs/current/CANDIDATURES/LETTRE-CANDIDATS/REGLES-NOUVELLES.md`), PE-B10 seconde moitié (ranger une image du chat comme pièce). Côté direction : la ville et la langue du candidat ne sont pas encore lues par le serveur ; le téléphone n'est pas relu par le candidat.
- Vague C : PE-C3 (pièce toujours affichée de la même façon), PE-C5 (épingler), PE-C9 en partie.
- Vague D : PE-D2 (supprimer un message), PE-D5 (profil dans la conversation), PE-D6 (annoncer à ces N personnes), PE-D7 (aperçu de lien, PDF), PE-D12 en partie.
- Vague G (Praxis) : PE-G3 (valider par pile) ; PE-G4 **arrêté** depuis le 20/11 à 10 h 32 UTC, ne pas rallumer sans ordre.

## 3. Page « Personnes » : ce qui reste (21/11)

- Les quatre anciennes listes (Candidatures, Enseignants, Comptes, Dossiers à valider) restent, en doublon. Elles font encore ce que la page unique ne fait pas : files avec leurs nombres, carte des attentes, marques de Praxis et non-lus par ligne (Candidatures) ; classes, heures, prochaine séance, remplacements, ce qui manque (Enseignants) ; bandeaux des villes incohérentes et des changements d'heure (Comptes) ; pièces des comptes qui ne sont pas des enseignants (Dossiers à valider). Les porter dans la page unique, puis **demander au directeur** la suppression des anciennes pages (une suppression de fichier exige son accord). L'associé n'a que la page Candidatures.
- « Actifs » lit le serveur cinq fois (une par phase) : il manque un filtre serveur à plusieurs phases.
- Élèves, familles, équipe sont filtrés dans le navigateur (`comptes_admin_page` installée, non utilisée).
- Dix filtres des candidats ne sont prouvés que jusqu'à l'envoi au serveur.

## 4. Petits lots et dettes connus

- **Clé de la routine de Praxis : expire le 24/11/2026 à 11 h 53 UTC** (le directeur seul peut en émettre une).
- Notification « pièce déposée » : la référence part à toute la direction sans filtre de genre (à corriger avant une seconde personne à la direction).
- Test instable `test/features/com_messages/images_messagerie_test.dart` (« glisser vers le bas ferme »), rouge aussi sur `main`.
- Scénarios SQL non rejoués par `ci.yml` ; `deno test` de `kyc-confirme` absent de la CI.
- « Les chiffres de l'académie » : mesure de légèreté à refaire après les dernières corrections ; arabe à faire relire.
- Le dépôt GitHub est **public** : aucun nom ni adresse de personne ne doit y entrer (le texte du guide, salaires compris, y est entré sur décision du directeur du 21/11 : « Fusionner tel quel »).

## 5. Décisions qui attendent le directeur

Rattrapage de la langue sur les comptes existants · règle de l'avis de créneau (PR 655) · dépôt public ou
privé · contenu de « À savoir » · téléphone en clair · remise en route de Praxis · garder « L'académie
aujourd'hui » · trois règles du guide · pièces orphelines · journal côté client · suppression des
anciennes listes de Personnes · « Supprimer ce compte » sur les lignes d'enseignants (retiré le 21/11 pour
les comptes de famille, remis pour les seuls comptes d'enseignant : dans `main` depuis la PR 683, à confirmer).
