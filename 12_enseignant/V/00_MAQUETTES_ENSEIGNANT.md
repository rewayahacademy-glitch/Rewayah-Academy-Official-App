# Vague Enseignant : planches du directeur, comparaison avec l'existant, rectifications

**Date.** 26/09/2026, poste B (orchestrateur).

**Sources.**
- `PLANCHE-1..5.png` (dans ce dossier).
- Document `projet/ressources:specs/04_enseignant/04_ENSEIGNANT.md`.
- Règles réutilisables `memoire/ENSEIGNANT-2026-09-26.md` (E1 à E20).

**Règle de la vague** (demande du directeur) : ne rien jeter sans comparer.
- On garde ce que les planches apportent de mieux, de plus joli ou de plus fonctionnel.
- On perfectionne l'existant sans le recommencer.
- On construit ce qui manque.
- Tout suit le style validé de l'entrée en classe (K-42, CL-4).

## 1. Classement par rôle

Les 5 planches sont toutes du rôle **enseignant**. Quatre éléments touchent pourtant d'autres rôles :

| Élément | Autre rôle concerné | Règle |
|---|---|---|
| Carte de séance (ENS-02, ENS-07) | Élève (CL-4.3) | Une seule carte et un seul `EmplacementEntree`, sans fork. |
| Salle (ENS-03) | Élève, parent observateur | Salle unique `/salle` (R1 à R21). Seules les extensions enseignant sont nouvelles. |
| « Appeler discrètement » | Élève | L'élève voit « Sayyid Ibrahim vous appelle » (E16). |
| Photo publique (ENS-05A) | Élève et famille (`photo_enseignant.dart`) | La photo déposée remplace « Photo à fournir » côté famille. |

## 2. Comparaison écran par écran

Légende :
- **G** = garder de l'existant ;
- **P** = prendre de la planche ;
- **R** = rectification (erreur de la planche ou contradiction avec une règle).

### Planche 1

**ENS-02 Aujourd'hui.** Existant : `JourneePage`, 840 lignes, branchée au serveur.
- G : la chronologie (`TimelineRow`, avec pauses et prières), les cahiers en retard, les alertes en séance.
- P :
  - le titre « Aujourd'hui » et la date ;
  - la carte « Prochaine séance » dominante ;
  - la section « À terminer » (3 au plus, « Voir tout » seulement si la destination existe) ;
  - la section « Alertes utiles », rendue seulement si elle n'est pas vide.
- R :
  1. « Élèves en attente » est retiré de l'écran (ancien matching, E1).
  2. « Cours individuel » devient « Classe ».
  3. La ligne « Bonjour Youssouf, 3 séances cette semaine » est supprimée : un bloc en moins (K-42).
  4. Pas de pastille « Confirmée » : c'est l'état normal (E12).
  5. La carte garde 4 données, pas 6 tuiles : heure, durée, élèves, et l'heure locale seulement si elle diffère.
  6. Les éléments « Réviser les supports » et « Écouter la récitation » ne sont pas des tâches permises. « À terminer » ne contient que des cahiers, des corrections demandées ou des actions demandées par le serveur.
  7. Le bouton suit E11 : « Préparer la séance », puis « Préparer l'entrée », puis « Finaliser le cahier ».
  8. La cloche de notification est retirée : les notifications ne sont pas garanties (doc §2).

**ENS-09 Mes Classes.** Existant : aucun écran enseignant. `MesGroupesPage` (`/tc/groupes`) est réservé à l'élève et au tuteur.
- P : une ligne par Classe avec niveau, langue, effectif et prochaine séance. Toute la carte ouvre la Classe.
- R :
  1. « + Nouvelle classe » est retiré (E18).
  2. Pas de filtres Toutes, Actives, Remplacements : le tri du doc §12.2 suffit, et « Remplacement » est une pastille d'exception.
  3. Des lignes groupées (`GroupeReglages`), pas une grande carte par Classe (K-42 point 4).
  4. Nouvelle route : `/enseignant/classes`. Les cartes du côté élève sont réutilisées.

**ENS-01 Premiers pas.** Existant : `BienvenueEnseignantPage`, 235 lignes.
- G : les deux mentions honnêtes (enregistrement et visite de contrôle), ramenées à une ligne chacune.
- P : la carte groupée « À compléter », avec le compteur « 0 sur 4 » et une ligne par prérequis manquant.
- R :
  1. Le bouton porte le premier prérequis manquant (« Ajouter ma photo »…), pas « Compléter mon profil ».
  2. La prose « groupes de cinq enfants ou six adultes » est retirée (E6).
  3. L'illustration du livre étoilé est retirée : on ne remplit pas un vide pour le remplir. À défaut, un simple en-tête d'identité.
  4. Pas de destination active dans la barre : c'est un flux d'activation.

### Planche 2

**ENS-07 Espace Classe.** Existant : `FicheGroupePage`, construite en CL-4.4, déjà dans le style de référence.
- G : l'en-tête `IdentiteGroupe`, la carte de séance partagée, « À préparer » et les élèves en `GroupeReglages`.
- P :
  - « Ressources récentes », 3 couvertures au plus ;
  - « Progression de la classe » en une ligne, avec une barre et une étape commune ;
  - un indicateur par élève (point de couleur doublé d'un mot, jamais la couleur seule) ;
  - toute la ligne d'un élève ouvre sa fiche (ENS-11).
- R :
  1. Pas d'onglets Vue d'ensemble, Élèves, Ressources sur mobile : des sections (E13).
  2. Le bloc « Vous enseignez cette classe · Sayyida Amina » est retiré : l'enseignant se voit lui-même.
  3. Sur bureau, « Nouvelle séance », « Actions rapides » (Ajouter un élève, Générer une évaluation, Imprimer le roster, Partager) et « Messages » sont retirés (E18).
  4. La barre latérale compte 4 destinations (E10).
  5. Sur bureau, deux colonnes : la Classe à gauche, le roster à droite. C'est ce que montre la planche, et c'est conforme à K-42.

**ENS-11 Fiche élève.** Existant : aucune fiche côté enseignant.
- P :
  - une feuille sur mobile, un panneau latéral sur bureau ;
  - en tête : photo de l'élève (initiales en repli), prénom, identifiant Académie ;
  - les tuiles Niveau, Objectif, Présence récente et Travail ;
  - la ligne « Dernière séance ».
- R :
  1. Pas d'onglets Aperçu, Parcours, Notes, Historique : une seule colonne.
  2. Les « Actions rapides » (Faire réciter, Appeler, Noter, Signaler) n'apparaissent **qu'en séance** (E14). Hors séance, seul « Signaler un besoin » reste.
  3. La pastille « Active » est retirée : c'est l'état normal.

### Planche 3

**ENS-03 Salle enseignant.** Existant, réparti sur deux surfaces :
- `/salle` : `panneau_enseignant`, qui présente le Coran avec la page précédente et suivante, et un lien réseau calme ;
- `/tc/classe` : le Teaching Dock (`tc_dock`, environ 4 300 lignes) et `ControleurRecitation`, dont le bloc « reste à construire ».

Détail :
- G : la salle unique `/salle`, et le rendu du Coran existant (zone interdite : on n'y touche pas).
- P :
  - le support dominant ;
  - sur bureau, un panneau à droite avec « Élèves » et la « File de récitation » (élève en cours, puis « À suivre ») ;
  - la notice discrète « Un parent observe cette séance » ;
  - sur mobile, le résumé « 4/4 » qui ouvre le roster en feuille ;
  - la barre compacte Supports, Micro, Caméra, Partager, avec « Ouvrir les outils d'enseignement ».
- R :
  1. Pas de navigation de l'app dans la salle, ni barre latérale ni barre en bas : la salle est une tâche focalisée.
  2. Le statut « Micro activé » affiché d'office est retiré : le micro est coupé à l'entrée (R1 à R21).
  3. Pas d'onglets « Tableau blanc », « Applications » ni « Discussion » : ils n'existent pas au contrat (E3). Il reste Coran et Documents, via le sélecteur de ressources.
  4. Pas de minuteur « 01:24 / 02:00 » par élève (E9), ni de « Évaluation en temps réel : Très bien » (E8).
  5. Les photos des élèves s'affichent (décision du directeur du 26/09, E5), avec les initiales en repli.
  6. Le Teaching Dock et la file de récitation sont **raccordés à `/salle`**, sans seconde salle.

### Planche 4

**ENS-04 Cahier de séance.** Existant : `CahierPage`, 1 009 lignes, prérempli et « tout est nominal ».
- G : le moteur prérempli, les exceptions en feuille, la file hors ligne et l'état déjà déposé.
- P :
  - l'ordre mobile : résumé, statut des élèves (Présents, Absents, En retard, en petites pastilles), travail à donner, position de reprise, puis « Valider le cahier » ;
  - sur bureau, deux colonnes : le résumé et les élèves, puis les exceptions et le travail.
- R :
  1. « Suggérer avec l'IA » et « Suggérer » sont retirés : le travail est déjà proposé (E8).
  2. « Justifiée » est retiré : l'enseignant ne juge pas une absence.
  3. « Ajouter un document » est retiré (E18).
  4. « Enregistrer brouillon » n'est proposé que si un brouillon durable existe, pas avant BR-1 (doc P-ENS-10).
  5. Pas de barre de navigation : c'est l'écran de sortie de séance.

**ENS-13 Absence et remplacement.** Existant : rien côté enseignant.
- P : une feuille « Déclarer une absence », qui reprend la séance (Classe, date, heure), puis un état de recherche.
- R :
  1. Pas de choix « Plusieurs séances » ni « Période personnalisée » : l'absence porte sur une séance (doc §17). Elle s'ouvre depuis cette séance.
  2. La fausse progression (« Analyse des disponibilités », « Recherche de professeurs », « Envoi des invitations ») est remplacée par les états serveur réels : Absence enregistrée, Recherche d'un remplaçant, Remplaçant confirmé, Aucun remplaçant confirmé, Séance annulée.
  3. « Vous serez notifié » est retiré : les notifications ne sont pas garanties. L'état reste visible dans Aujourd'hui.
  4. La notice « Votre affectation à la Classe reste inchangée. » est ajoutée.

**ENS-05 Profil.** Existant : `ProfilEnseignantPage`, 644 lignes, avec statut, déclaration, contrats, réglages et déconnexion.
- G : tout le contenu existant, et la déconnexion ici.
- P :
  - la photo publique en tête, avec « Changer la photo » ;
  - les informations professionnelles et les préférences en lignes groupées.
- R :
  1. Pas de badge « vérifié » à côté du nom (gamification) : le statut du compte suffit.
  2. « Biographie publique » est retirée, car elle n'est pas au contrat.
  3. « Spécialité » est retirée : les langues d'enseignement suffisent.

**ENS-05A Photo publique.** Nouveau sous-flux, textes du doc §24 : « Choisir une photo », « Utiliser cette photo », « Remplacer la photo ». La notice dit « N'utilisez pas votre pièce d'identité. »

### Planche 5

**ENS-06 Disponibilités.** Existant : `CreneauxPage`, 855 lignes, avec la grille de semaine et l'onglet « Élèves en attente ».
- G : la grille de semaine (`GrilleSemaine`) et l'alerte de conflit.
- P :
  - sur mobile, « Mes disponibilités », une liste par jour avec les plages, « Ajouter un créneau », puis « Classes disponibles » ;
  - sur bureau, deux colonnes : le planning hebdomadaire et les Classes compatibles.
- R :
  1. L'onglet « Élèves en attente » et le bouton « Prendre {jour} à {heure} » sont **retirés de l'écran** (E1). Le serveur n'est pas touché (BR-1).
  2. Pas de dates (« Lun 16 », « 16 – 22 septembre 2024 ») ni de navigation de semaine : les disponibilités sont hebdomadaires (E15).
  3. Sur bureau, « Limite atteinte » veut dire la charge de l'**enseignant**, pas la capacité de la Classe. Texte : « Votre charge actuelle ne permet pas de réserver une Classe supplémentaire. » La « liste d'attente » est retirée.

**ENS-06B Détail d'une Classe disponible.** Nouveau.
- P : la liste complète (récurrence, fuseau de référence, heure locale, durée, public, langue, capacité, date de début), puis « Réserver cette Classe ».
- R :
  1. Une confirmation « Confirmer cette Classe ? » rappelle tous les jours avant l'envoi (doc §16.4).
  2. Le succès se lit « Votre demande a été transmise. Elle apparaîtra dans vos Classes après confirmation. » La planche disait « Le professeur recevra une notification… », qui est la voix d'une famille, pas de l'enseignant (E7).

## 3. Données de démonstration communes (K-35, E20)

L'enseignant de démonstration est **Sayyid Ibrahim** ; la variante `&titre=sayyida` est conservée.

Il a quatre Classes :
- An-Nour : niveau 1, arabe, 4 élèves ;
- Al-Fatiha : niveau 2, en remplacement ;
- Al-Badr : niveau 1, français ;
- Al-Ikhlas : sans prochaine séance.

Les élèves ont un prénom, et une photo de démonstration non réelle (initiales en repli). Les dates sont en septembre et octobre 2026.

## 4. Mon avis sur le document 04 (droit de regard du directeur)

Je propose huit corrections au document. J'en assume la responsabilité face à l'auteur du document.

1. **§14.4 « Le professeur vous appelle ».** Le texte vu par l'élève nomme l'enseignant (« Sayyid Ibrahim vous appelle »). Deux raisons : c'est la leçon M2 de CL-4, et un titre générique ne dit pas le genre choisi (K-41).
2. **§11.2 et R4.** « Préparer la séance » avant la fenêtre et « Préparer l'entrée » dans la fenêtre sont les **deux états d'un même emplacement** (E11). Ce ne sont pas deux boutons. Le document ne le disait pas.
3. **§29 raccourcis M, V, R, B.** Une lettre seule sans modificateur tombe sous le critère WCAG 2.1.4 : l'utilisateur doit pouvoir la désactiver ou la changer. Elle est aussi un piège pendant une saisie. Ma proposition :
   - les raccourcis ne sont actifs que lorsque le focus est dans la salle ;
   - ils sont désactivables dans les réglages ;
   - ils ne sont codés qu'après la décision du directeur (E19).
4. **§18.5 file de récitation.** J'ajoute « aucun minuteur par élève ». Le directeur l'a dit pour le chrono : ce n'est pas une course (E9).
5. **Remplacement (P-ENS-12).** Le document décrit l'acceptation d'une offre mais ne lui donne pas d'emplacement. Je propose : l'offre arrive comme une « Alerte utile » dans Aujourd'hui, et ouvre une feuille « Assurer ce remplacement ? » (ENS-13B).
6. **§7 navigation.** La décision d'architecture ADR-027 fixait l'enseignant à 3 destinations. La demande du directeur, plus récente, en impose 4, et elle prime (DESIGN-GOV §1). ADR-027 sera noté comme remplacé.
7. **§38 maquettes.** Les planches ont une barre d'état « 9:41 » et des dates de 2024 : rien de cela n'est reproduit. Les photos d'élèves, elles, sont gardées (décision du directeur du 26/09).
8. **§4.2 fenêtre d'entrée.** Deux durées de 20 minutes existent dans le code : le billet de salle et l'horloge de démonstration. Le billet reste. L'horloge de démonstration est acceptable. Le calcul par le serveur viendra à BR-1.

Seuls les **raccourcis** (point 3) attendent l'accord du directeur. Les sept autres points sont appliqués par défaut, et le directeur peut les renverser.
