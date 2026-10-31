# Constats UX/UI des parcours joués

Tenu par le robot de bout en bout (`METHODE-2026-11-01.md`, § « Revue UX/UI »), décision du
directeur du 31/10/2026. Le robot **consigne, il ne corrige pas**.

Règles pour que rien ne se perde :

- Chaque constat reçoit un identifiant suivi : UX-001, UX-002, … jamais réutilisé.
- Un constat ne se ferme **que** par une capture Playwright datée qui montre la correction ; la
  colonne Statut dit alors « corrigé le JJ/MM » et le chemin de la capture.
- Une consigne de worker qui touche un écran cite les UX-xxx ouverts de cet écran.
- Aucune pull request ne retire une ligne de ce fichier.
- L'ancien pilote vérifie chaque matin qu'aucun constat n'a disparu ni n'a été fermé sans capture.

Classe : Manquant · Mal placé · Doublon · Taille · Non branché · Cassé · Texte · Interprétation · Détour · Conforme.
Gravité : Bloquant (objectif impossible) · Gênant (possible mais difficile) · Finition.
Code : statut (absent, non routé, non branché, cassé, mal placé) et `fichier:ligne` probable.

Standards de référence (repris du mandat d'audit UX du 27/10, branche
`claude/admiring-brown-r6ai72-audit`, non fusionnée) : Material 3 (navigation, actions,
formulaires, cibles 48 × 48), Apple HIG, Google Meet (commandes et centre de la salle), Google
Classroom (espace de l'enseignant), Quran.com et Tarteel (lecteur du Coran, glisser pour tourner),
Baymard (formulaires), WCAG 2.2 AA (contraste 4,5:1, cible 24 × 24, texte à 200 %, focus visible).

| ID | Écran | Élément | Attendu (spec + standard) | Constaté | Preuve | Classe | Gravité | Code | Statut |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| UX-001 | Direction › Opérations › Classes › Nouvelle classe | Créneaux de la semaine | Carnet (parcours 2) : « Ajouter un créneau » ajoute un créneau ; Baymard : ne pas imposer de champs à vider | Le formulaire ouvre d'office 3 créneaux (le 1er + 2 lignes vides) ; « Créer la classe » refuse tant qu'ils ne sont ni remplis ni retirés (« Choisissez le jour et l'heure du créneau 2, ou retirez-le ») | captures/E2E/parcours-2/05_direction_creneau_2.png (31/10 20:07 UTC) | Interprétation | Gênant | `lib/features/admin_groupes/groupes_page.dart:1118` (`_autres` initialisé à 2 lignes) | ouvert |
| UX-002 | Enseignant › toutes pages | Barre de navigation (Aujourd'hui, Classes, Disponibilités, Profil) | WCAG 2.2 AA 4.1.2 (nom, rôle, valeur) : chaque onglet lisible par un lecteur d'écran, comme la barre de la direction (« Classes Onglet 2 sur 4 ») | Sur ordinateur, aucun onglet de la barre de l'enseignant n'est dans l'arbre d'accessibilité (21 nœuds sur Aujourd'hui, aucun pour la barre) ; le test ouvre « Classes » par son adresse | captures/E2E/parcours-2/09_enseignant_aujourdhui.png (31/10 20:07 UTC) | Cassé | Gênant | `lib/core/widgets/nav_shell.dart` (rail repliable de l'enseignant ; à confirmer) | ouvert |
| UX-003 | Inscription › récapitulatif (étape « Voici ce que nous avons compris ») | Ligne « Langue du cours » | Mots compris du premier coup (mots-rewayah) : « Français » | Affiche « francais » (code brut, sans majuscule ni cédille) ; « Poular » et « English » s'affichent bien | captures/E2E/parcours-3/11_famille_identite_2.png (31/10 20:32 UTC) | Texte | Gênant | `lib/features/inscription/etapes/recapitulatif_etape.dart:382` (`_nomLangue`) | ouvert |
| UX-004 | Direction › Personnes › Demandes › boîte d'une demande | État de la demande après « Accepter la demande … » | Material 3 : l'état affiché suit l'action (« Acceptée ») | La phrase dit « … est acceptée ; l'e-mail est en route » mais la ligne État de la même boîte reste « À traiter » (la liste dit « Acceptée ») | captures/E2E/parcours-3/31_direction_acceptee_Familles.png (31/10 20:32 UTC) | Cassé | Gênant | `lib/features/admin_admissions/admissions_page.dart:449` (`_fait` posé, état de la boîte non relu) | ouvert |
| UX-005 | Direction › Personnes › Demandes | Champ « Rechercher » | Baymard : la saisie garde le focus pendant le filtrage | Sous Playwright (arbre d'accessibilité actif), seule la 1re lettre entre : le champ perd le focus à chaque frappe. Non reproduit au clavier réel | capture de la session d'exploration (31/10 20:25 UTC), à refaire | Cassé | Gênant | `lib/features/admin_admissions/admissions_page.dart:196` (`setState` à chaque frappe) | à confirmer au clavier réel |
| UX-006 | Direction › Opérations › Classes | « Ajouter un élève » | Carnet (parcours 4) : « ouvrir la classe, Ajouter un élève » ; Material 3 : l'action est sur l'objet ouvert | L'action n'est pas dans la fiche de la classe (qui montre « Aucun élève ») ; elle est dans le menu « Actions » de la ligne | captures/E2E/parcours-4/02_direction_ajouter_un_eleve.png (31/10 20:39 UTC) | Mal placé | Finition | `lib/features/admin_groupes/groupes_page.dart` (fiche de classe sans action) | ouvert |
| UX-007 | Famille (tuteur) › Accueil, pendant la séance | Bloc de la séance | Un seul message vrai à la fois (K-59) | « Rejoindre la salle avec Yanis… » ET « Ouverture de la salle non confirmée pour l'instant » affichés ensemble, séance en cours | captures/E2E/parcours-4/12_famille_accueil.png (31/10 20:40 UTC) | Cassé | Gênant | `lib/features/accueil_famille/bloc_seance.dart:137` (`horaireIncertain`) | ouvert |
| UX-008 | Salle (/salle), enseignant sur ordinateur 1200 x 760 | « Page suivante » du Coran | Quran.com / Tarteel : flèches à côté de la page ; carnet (parcours 5) : « Page suivante » | Les grandes flèches ne s'affichent pas (elles ne « tiennent » pas à côté de la page avec les deux panneaux) ; « Page suivante » n'est que dans « Plus » | captures/E2E/parcours-5/09_enseignant_commandes_plus.png (31/10 20:49 UTC) | Mal placé | Gênant | `lib/features/salle_seance/zone_support.dart:508` (`_avecFleches`, condition de largeur) | ouvert |
| UX-009 | Salle, tuteur (téléphone) après « Rejoindre la salle avec … » | Bandeau du haut | Ne pas proposer de revenir là où l'on est déjà | Bandeau « Séance toujours en direct · Retourner dans la salle → » affiché alors que le tuteur est dans la salle et voit l'enseignant | captures/E2E/parcours-5/06_tuteur_salle_enseignant_visible.png (31/10 20:49 UTC) | Cassé | Gênant | `lib/features/salle_seance/barre_seance_en_direct.dart:241` | ouvert |
| UX-010 | Salle, tuteur (téléphone) | Pastille « État inconnu » | Mots compris du premier coup : dire ce qui est connu (présence de l'enfant) | « État inconnu » sous « En ligne », sans explication | captures/E2E/parcours-5/06_tuteur_salle_enseignant_visible.png (31/10 20:49 UTC) | Texte | Gênant | `lib/core/widgets/ligne_presence.dart:75` | ouvert |
| UX-011 | Inscription enseignant (« J'ai un code d'invitation ») | Retour du lien d'e-mail | Le parcours reprend où il en était (carnet parcours 1) | Après le lien, « Pour qui créez-vous ce compte ? » revient (famille, adulte) : la personne doit retrouver et retoucher « J'ai un code d'invitation » ; si elle choisit « Je m'inscris pour moi », elle devient demandeuse famille (vu en exploration) | captures/E2E/parcours-1/journal.txt (31/10 21:09 UTC) | Détour | Gênant | `lib/features/inscription/inscription_page.dart` (paramètre `invitation=1` perdu au retour du lien) | ouvert |
| UX-012 | Partout (Classes de l'enseignant, Compte, Comptabilité) | Libellé « Messages métier » | Le directeur : « aucune personne au monde ne comprendra cela » ; mots compris du premier coup | « Messages métier » (`com.socle.lexique.messagesMetier`) et « … dans les Messages métier » (`comptable.beneficiaires.profil.relancerDetail`) | captures/E2E/parcours-2/10_enseignant_classes.png (31/10 20:07 UTC) | Texte | Gênant | `assets/i18n/fr.i18n.json:9925` et `:11547` | ouvert |
| UX-013 | Direction › Personnes › Demandes › boîte d'une demande | Fermeture de la boîte | Material 3 / WCAG 2.1.2 : une boîte se ferme par Échap ou un bouton Fermer | Aucune croix ni « Fermer » ; Échap sans effet sous Playwright ; seul un toucher hors de la boîte la ferme | captures/E2E/parcours-3/31_direction_acceptee_Familles.png (31/10 20:32 UTC) | Manquant | Gênant | `lib/features/admin_admissions/admissions_page.dart` | ouvert |
| UX-014 | Direction › Personnes | Page « Invitations » (inviter un enseignant) | Carnet / Material 3 : section visible dans « Sections de la page » | « Invitations » n'est pas dans le menu des sections ; on l'atteint par Candidatures › bouton « Invitations » | captures/E2E/parcours-1/01_direction_invitation_creee.png (31/10 21:09 UTC) | Mal placé | Finition | `lib/core/router/routes.dart:776` (onglet remplacé par Candidatures) | ouvert |

## Constats fonctionnels

Bug, donnée fausse, e-mail absent, paie ou facture fausse, erreur serveur, faille, chose « non
branchée ». Mêmes règles que la table du dessus : une ligne par défaut, jamais supprimée, fermée
seulement par une preuve datée.

| ID | Où | Constat | Gravité | Preuve du constat | Qui corrige | Statut |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| FN-001 | Enseignant › Aujourd'hui ; base : clôture des séances | Deux séances du même enseignant qui s'enchaînent (enfants 20:15-21:15 UTC, adultes 21:15-22:45 UTC) : la première reste `in_progress` après sa fin, même après « Quitter et ouvrir le cahier de transmission » ; « Aujourd'hui » la garde en « Séance en direct · Temps prévu écoulé » et ne propose pas la salle suivante (seul l'onglet Classes le fait), jusqu'à la clôture automatique à fin + 30 min (`seances.cloture_auto_marge_minutes`, tâche `ses_cloture_auto` toutes les 15 min). Code probable : `lib/core/enseignant/cta_seance.dart:152` (`seanceDeLaCarte`), `private.ses_cloturer_seances_echues` | Bloquant | `captures/E2E/parcours-8/02_enseignant_aujourdhui_sans_salle_adultes.png` (31/10 21:19 UTC), journal du parcours 8 | pilote (lot après PR 100) | ouvert |
