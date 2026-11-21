# RESTE À FAIRE du parcours de l'enseignant et des maquettes — ALERTE PERMANENTE

**Écrit le 21/11/2026 à l'arrêt du pilote, sur ordre du directeur : « tu les mets quelque part où chaque
agent sera obligé de les voir même après 2 mois ».** `CLAUDE.md` y renvoie dans « Toujours, avant tout ».
Tout agent qui touche au parcours du candidat ou de l'enseignant, au bureau de la direction, à Praxis, à
une page de connexion, de chargement ou de mise à jour, à une liste ou à une icône lit ce fichier AVANT
d'écrire une ligne, et y raye ce qu'il livre (statut + numéro de PR + date), le jour même.

Règle : rien ici n'est « fait » tant que le directeur ne l'a pas prouvé en production. Une ligne ne
disparaît jamais : elle passe à `prouvé par le directeur (date)` ou à `écarté par le directeur (date)`.
Le détail de chaque lot est dans `PLAN.md` ; la check-liste et le journal dans `SUIVI.md` ; les maquettes
validées dans `maquettes/` (et les adresses des pages remises au directeur dans `SUIVI.md`).

## 1. Prouvé par le directeur en production (21/11/2026)

- PE-A5 : le lien de connexion par courriel repart (PR 656, essai du 20/11 à 14 h 02 UTC). **C'est le seul.**

## 2. Dans `main`, jamais prouvé par le directeur

Formulaire du candidat (PE-B1, B8, A8 : #660) · courriels dans la langue (PE-A1 : #654) · accueil du
candidat (PE-B4, B5, A6 : #662) · messagerie fiable (PE-D1 : #657) · liste des candidatures et gestes
groupés (PE-C4 : #658) · feuilles à 90 %, tirer pour actualiser, barre du bas (PE-D3, D12, E3 : #659) ·
case de Cloudflare (#663) · un seul dossier, synthèse, complément précoché (PE-C1, C2, C10 : #661) · nom
latin et ville (PE-B3 : #666) · dépôt de pièce résistant aux pannes (PE-B10, première moitié : #667) ·
page d'entrée « Praxis vous accueille » (#664, #671) · tableau de bord vivant (PE-C6, F4, F7 en partie :
#642) · avis flottant et mise à jour au choix (PE-D8, D9 : #641, #648) · texte copiable (PE-D11 : #641) ·
retour du bureau (PE-D4 : #639, #674) · page unique « Personnes » (#670, #676 à #682) · vitesse de la base
(#672, #673 : conversations lues en 0,27 s au lieu de 1,5 s, mesuré le 21/11) · « Les chiffres de
l'académie » (#675, sous Opérations).

## 3. Ce qui reste des MAQUETTES validées, pas encore dans l'application

| Maquette | Ce qui manque | Lot |
| :--- | :--- | :--- |
| « Praxis vous accueille » (version 3, confirmée le 20/11) | **Écran de chargement** avec Praxis (rien) ; **écran de mise à jour** avec Praxis (rien) ; la page de connexion est faite (#664, #671) mais pendant l'écriture de sa phrase, un mot passe sur la toque de Praxis (défaut vu en production le 21/11) | PE-F8 |
| Tableau de bord (validé le 20/11, « on valide cette maquette pour aller vite ») | Visages sur les tuiles de plus de 50 personnes (tri serveur par ancienneté manquant) ; la pile des pièces se feuillette mais **ne décide pas** (pas d'annulation côté serveur) ; cases « candidats vus en 24 h » et « retraits » remplacées par des cases d'alerte en ambre (compteurs serveur manquants) ; boutons sans icône ; coins de 24 ; tuile bloquée en rouge sombre ; au téléphone, une case « Outils » à la place de la liste de raccourcis ; **le Praxis du tableau de bord n'est pas celui de la maquette « Praxis vous accueille »** (à unifier sur `lib/core/vivant/praxis_vivant.dart`) | PE-C6, PE-F5 |
| Composants vivants (§13 du plan) | File d'avatars, bulle, capsule liquide | PE-F7 |
| Langage de mouvement | La décision datée qui amende `DECISION-MOUVEMENT` n'est pas écrite ; la compétence du mouvement n'existe pas | PE-F3, PE-F6 |
| Icônes | Nouvelle famille d'icônes fixes ; une quinzaine d'icônes animées (paquet Lottie : `pubspec.yaml`, licence) | PE-F1, PE-F2 |
| En-tête du bureau | Panneaux légers (messages avec réponse rapide, notifications, annonces) ; recherche qui trouve les personnes | PE-C7 |
| Accueil du candidat | Fusionné (#662) après une première version jugée non fidèle : **fidélité à la maquette jamais confirmée par le directeur** ; question ouverte : que garde l'onglet « Académie » | PE-B4, PE-B5 |
| Trois pages : Accueil, Personnes, Messages, le reste dans « Plus » | Personnes est une page unique ; **le menu réduit, le menu « Outils » et les retours vers Personnes ne sont pas en ligne** (branche `claude/personnes-menu`, tête 81212522, poussée, jamais mise en ligne : confiée le 21/11 à la session « Informations salaires enseignants », qui s'est retirée le même jour ; **à reprendre** : fusionner main, conflit dans `test/capture/personnes_page_capture_test.dart`, espace insécable avant « : » dans deux textes fr, flèche à l'écran dans `test/router/personnes_retours_test.dart`, tests, PR) ; « Plus » n'existe pas | PE-C8 |
| Gestes | Retour par glissement, glisser une ligne pour agir, glisser pour répondre | PE-D10 |
| Interface de l'enseignant (vague E) | **Rien de construit.** Ne rien lancer sans ordre du directeur ; relire d'abord la maquette recadrée et ses commentaires | PE-E1, PE-E2 |

## 4. Lots du plan pas commencés ou en partie

- Vague P (fluidité) : PE-P1 mesure sur les trois appareils du directeur, PE-P3, PE-P4 ; PE-P2 éclair coloré non corrigé.
- Vague A : PE-A2 (adresse préremplie et marque dans le lien : serveur), PE-A4 (geste « ce compte est un candidat enseignant »), PE-A7 (PR 655 : **ne pas fusionner** sans décision ; sa migration 942000 est à renuméroter après 966000), PE-A9 (rôle associé côté serveur).
- Vague B : PE-B2 (un seul nom par élément), PE-B6 (partage), PE-B7 (modifier après envoi), PE-B9 (réponses toutes prêtes : le guide de l'enseignant, PR 665 puis 669 et 668, rendues par leur session le 21/11, **non fusionnées : le texte des salaires entrerait dans un dépôt public**, décision du directeur d'abord ; décisions du 21/11 dans `docs/current/CANDIDATURES/LETTRE-CANDIDATS/LOT.md`), PE-B10 seconde moitié (ranger une image du chat comme pièce). Côté direction : la ville et la langue du candidat ne sont pas encore lues par le serveur ; le téléphone n'est pas relu par le candidat.
- Vague C : PE-C3 (pièce toujours affichée de la même façon), PE-C5 (épingler), PE-C9 en partie.
- Vague D : PE-D2 (supprimer un message), PE-D5 (profil dans la conversation), PE-D6 (annoncer à ces N personnes), PE-D7 (aperçu de lien, PDF), PE-D12 en partie.
- Vague G (Praxis) : PE-G3 (valider par pile) ; PE-G4 **arrêté** depuis le 20/11 à 10 h 32 UTC, ne pas rallumer sans ordre.

## 5. Page « Personnes » : ce qui reste (21/11)

- Les quatre anciennes listes (Candidatures, Enseignants, Comptes, Dossiers à valider) restent, en doublon. Elles font encore ce que la page unique ne fait pas : files avec leurs nombres, carte des attentes, marques de Praxis et non-lus par ligne (Candidatures) ; classes, heures, prochaine séance, remplacements, ce qui manque (Enseignants) ; bandeaux des villes incohérentes et des changements d'heure (Comptes) ; pièces des comptes qui ne sont pas des enseignants (Dossiers à valider). Les porter dans la page unique, puis **demander au directeur** la suppression des anciennes pages (une suppression de fichier exige son accord). L'associé n'a que la page Candidatures.
- « Actifs » lit le serveur cinq fois (une par phase) : il manque un filtre serveur à plusieurs phases.
- Élèves, familles, équipe sont filtrés dans le navigateur (`comptes_admin_page` installée, non utilisée).
- Dix filtres des candidats ne sont prouvés que jusqu'à l'envoi au serveur.

## 6. Petits lots et dettes connus

- **Clé de la routine de Praxis : expire le 24/11/2026 à 11 h 53 UTC** (le directeur seul peut en émettre une).
- Notification « pièce déposée » : la référence part à toute la direction sans filtre de genre (à corriger avant une seconde personne à la direction).
- Test instable `test/features/com_messages/images_messagerie_test.dart` (« glisser vers le bas ferme »), rouge aussi sur `main`.
- Scénarios SQL non rejoués par `ci.yml` ; `deno test` de `kyc-confirme` absent de la CI.
- « Les chiffres de l'académie » : mesure de légèreté à refaire après les dernières corrections ; arabe à faire relire.
- Le dépôt GitHub est **public** : aucun texte réservé (salaires du guide, noms, adresses) ne doit y entrer avant décision du directeur.

## 7. Décisions qui attendent le directeur

Rattrapage de la langue sur les comptes existants · règle de l'avis de créneau (PR 655) · dépôt public ou
privé · contenu de « À savoir » · téléphone en clair · remise en route de Praxis · garder « L'académie
aujourd'hui » · trois règles du guide · pièces orphelines · journal côté client · suppression des
anciennes listes de Personnes · « Supprimer ce compte » sur les lignes d'enseignants (retiré le 21/11 pour
les comptes de famille, remis pour les seuls comptes d'enseignant dans la branche du menu).
