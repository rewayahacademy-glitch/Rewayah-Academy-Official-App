# Registre des constats (UX et fonctionnels)

Tout ce qui est trouvé est consigné ici et suivi un par un (directeur, 31/10 au soir : « sans
check-list ça se perd comme les premières fois »). Deux tables : UX-xxx pour les écrans, FN-xxx
pour le reste (bugs, données, paie, e-mails, sécurité, dette). Un worker qui trouve quelque chose
hors de son lot ne le corrige pas : il ouvre une ligne.

## Constats UX/UI des parcours joués

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
| UX-001 | Comptabilité, profil d'un bénéficiaire (relance) ; lexique commun | « Messages métier » (`com.socle.lexique.messagesMetier`, `comptable.beneficiaires.profil.relancerDetail`) | Un mot que tout le monde comprend (mots-rewayah) : « Messages », ou « Messages de l'académie » si le contexte ne suffit pas | Le directeur a jugé le texte incompréhensible le 31/10 | Lecture par le directeur, 31/10 (relayée par le garde-cap) | Texte | Gênant | `assets/i18n` (clés ci-contre) | ouvert ; corrigé dans la prochaine PR qui touche déjà les textes |
| UX-002 | Démarrage de la PWA (Android) | Écran de démarrage | Liste d'attente du 29/10, ligne 4 | L'écran blanc, puis le carré violet, avant l'écran d'ouverture. Écran de démarrage Android de la PWA : `web/manifest.json` (`background_color` `#6538E4`) et ses icônes ; à reprendre dans la zone protégée, sur décision. | `LISTE-ATTENTE-2026-10-29.md`, ligne 4 | Cassé | Finition | `web/manifest.json` | ouvert |

## Constats fonctionnels

Mêmes règles que la table UX : identifiant FN-001, FN-002, … jamais réutilisé ; aucune PR ne retire
une ligne ; une ligne ne se ferme que par une preuve datée. La preuve est une capture Playwright,
le nom d'un scénario SQL qui passe sur la pile locale, ou une lecture de la production faite par le
garde-cap. Le Statut dit alors « corrigé le JJ/MM, PR n° ».

| ID | Où | Constat (une phrase simple) | Gravité | Preuve du constat | Qui corrige (PR ou lot) | Statut |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| FN-001 | CI (`ci.yml`) | La CI ne rejoue que 30 des 154 scénarios SQL ; présence aux minutes, cahier hebdomadaire et remplacements n'y sont pas. | Gênant | Décompte des noms listés dans `ci.yml`, 31/10 | Décision du directeur (`.github/` interdit aux agents) | ouvert |
| FN-002 | Cahier, séance remplacée | Le remplaçant ne peut déposer aucun cahier : la RLS de `lesson_reports`, `brouillon_cahier` et `mes_rapports_en_attente` ne lisent que le titulaire. | Bloquant | Prouvé sur la pile locale, 31/10 | Lot CAHIER-REMPLACANT (session du 31/10) | ouvert ; règle décidée 01/11 (directeur) : le remplaçant seul dépose, le titulaire lit et ne dépose pas ; PR 108 ; **corrigé dans le code** : PR 108 fusionnée (428b162), migration 20261101031410 installée en production le 01/11 (corps identiques au fichier, md5) ; preuve locale : capture du 31/10 ; preuve du directeur en production à faire |
| FN-003 | Présence aux minutes (`private.pai_minutes_enseignant`, 20261102900000) | Un enseignant entré sans jamais sortir compte jusqu'à 1799 minutes pour une séance d'1 h : affichage faux, argent juste (paie plafonnée à la durée prévue). | Gênant | `scenarios_ses_cloture_auto`, cas 4, pile locale, 31/10 | Lot à lancer : nouvelle migration bornant à la fin prévue plus la grâce | ouvert |
| FN-004 | Tests SQL | `scenarios_fac_e_paie_par_eleve` échoue sur `main` (« pending trigger events »). | Gênant | Pile locale, 31/10 (agent de la PR 100) | À attribuer | ouvert |
| FN-005 | Tests SQL | `scenarios_af_liste_blanche_volatiles` échoue sur `main` (`ajouter_creneau_classe_admin`, `seance_a_rejoindre`). | Gênant | Pile locale, 31/10 (agent de la PR 106) | À attribuer | ouvert |
| FN-006 | Aujourd'hui (enseignant), séances qui s'enchaînent | La séance précédente reste « Séance en direct · Temps prévu écoulé » jusqu'à la clôture automatique ; la suivante n'est proposée que dans Classes ; « Quitter et ouvrir le cahier » laisse la séance en cours. | Bloquant | Parcours 8 joué sur la pile locale, 31/10 21:24 (PR 107) | Lot à lancer après la PR 100 | ouvert ; règle décidée 01/11 (directeur) : à l'heure prévue de fin plus la grâce, Aujourd'hui montre la séance suivante ; « Quitter et ouvrir le cahier » clôt la précédente |
| FN-007 | Aperçus Vercel des PR | Les aperçus écrivent dans la base de production (même `SUPABASE_URL`). | Gênant | Configuration relevée par le pilote (F1) | Décision du directeur | ouvert |
| FN-008 | Base staging | La base staging est en retard sur les migrations depuis le 23/10. | Gênant | Relevé du pilote (F2) | Décision du directeur | ouvert |
| FN-009 | Production, foyer A | Une adulte inscrite pour elle-même est devenue tutrice, avec un profil mineur à son nom. | Gênant | Relevé du directeur, semaine du 27/10 | Migration tracée, sur décision du directeur | ouvert |
| FN-010 | Production, foyer B | Une mère a créé le compte tuteur au nom de son enfant, puis deux profils en double. | Gênant | Relevé du directeur, semaine du 27/10 | Migration tracée, sur décision du directeur | ouvert |
| FN-011 | Paiement en production | Les clés Stripe (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`) sont absentes des secrets des fonctions Edge : aucune famille ne peut payer. | Bloquant | ETAT-OUVERTURE, parcours 7 | Le directeur (tableau de bord Supabase, secrets des fonctions) | ouvert |
| FN-012 | Sons de l'application | Les sons de l'application : à définir : où (salle, accueil, notifications), quand, quels types de sons, quelle bibliothèque. Aucun son aujourd'hui. | Finition | `LISTE-ATTENTE-2026-10-29.md`, ligne 1 | Décision du directeur | ouvert |
| FN-013 | Application restée ouverte | Le bandeau « nouvelle version » : une application restée ouverte garde l'ancienne version ; le bandeau doit le dire et proposer de recharger. | Gênant | `LISTE-ATTENTE-2026-10-29.md`, ligne 5 | À attribuer | ouvert |
| FN-014 | `pubspec.yaml` | Les polices arabes à déplacer dans `pubspec.yaml` : environ 3 s de moins à l'ouverture (rapport `OUVERTURE-RAPIDE-2026-10-29.md`) ; fichier protégé, geste du directeur. | Gênant | `LISTE-ATTENTE-2026-10-29.md`, ligne 6 | Décision du directeur | ouvert |
| FN-015 | Données de production | Les 36 séances annulées de classes fermées encore rattachées à Hakim : à nettoyer ou à détacher. | Finition | `LISTE-ATTENTE-2026-10-29.md`, ligne 7 | Après inventaire et feu vert sur la liste précise | ouvert |
| FN-016 | Notifications | Les notifications créées au nom des élèves mineurs : le serveur en écrit (portée « soi ») alors que le mineur n'a pas de cloche (réponse Q5) ; le tuteur est déjà prévenu. Rapport `LOT-B2-2026-10-29.md`. | Finition | `LISTE-ATTENTE-2026-10-29.md`, ligne 8 | À attribuer | ouvert |
| FN-017 | Langues | Les cinq langues de l'application : seuls le français et l'arabe existent ; anglais, espagnol et portugais manquent. | Gênant | `LISTE-ATTENTE-2026-10-29.md`, ligne 9 | Décision du directeur | ouvert |
| FN-018 | Adaptateur temps réel | L'adaptateur temps réel avale les erreurs : une erreur du canal ne doit jamais disparaître en silence (voir `ELEVE-APPAREIL-2026-10-29.md`). | Gênant | `LISTE-ATTENTE-2026-10-29.md`, ligne 10 | À attribuer | ouvert |
| FN-019 | Séance remplacée (`mes_seances_enseignant_v`, `cahier_semaine_depose`) | Ces deux lectures ne connaissent que le titulaire : le remplaçant ne voit pas la séance remplacée dans la vue ; son bouton de fin de séance ignore l'état du cahier de la semaine ; après le dépôt, l'en-tête du cahier perd le nom de la Classe. | Gênant | Pile locale, 31/10 (agent du lot cahier du remplaçant, PR 108) | À attribuer (suite du lot cahier du remplaçant) | ouvert |
| FN-020 | Tests SQL | Cinq scénarios échouent sur `main`, avec ou sans la PR 108 : `cand_l1b_forme_compte`, `classes_duree_affectation`, `classes_duree_bout_en_bout`, `classes_plafond_par_enseignant`, `fac_c_paiements`. Aucun n'est rejoué par la CI. | Gênant | Rejeu complet sur Postgres 16 nu, 31/10 (agent de la PR 108) | À attribuer | ouvert |
| FN-021 | Tests SQL | `scenarios_ses_cloture_auto` échoue sur `main` : son cas 4 attend l'ancienne règle de paie, d'avant la présence aux minutes. | Gênant | Pile locale, 31/10 (agents des PR 100 et 108) | PR 100 (attente du cas 4 mise à jour, 21/21 en local) | ouvert ; se ferme à la fusion de la PR 100 avec le scénario vert ; PR 100 fusionnée (f710324), migration 20261101031052 installée le 01/11 ; se ferme quand le scénario est vert sur la pile locale ou en CI |
| FN-022 | Pile locale `tool/e2e/` | Le registre d'images ECR répond « Data limit exceeded ». Le contournement retague des images de Docker Hub. Le script cherche « Cahier de transmission E2E », mais le libellé réel est « Cahier de transmission d'E2E ». Flutter peut manquer dans `/opt/flutter`. | Finition | Pile locale, 31/10 (agent de la PR 108) | Agent E2E (PR 107) | ouvert |
| FN-023 | Salle | Aucun chrono du temps restant n'est affiché : le chrono LIVE-CHRONO-01 existe (`lib/core/tc_horloge/chrono_seance.dart`, `chrome_seance.dart:412`, `vue_seance.dart` `BornesChrono? chrono`), mais `lib/features/salle_seance/depuis_salle.dart` (lignes 86 et 174) ne passe jamais `chrono:`. | Bloquant | Lecture du code par le garde-cap sur origin/claude/parcours-ouverture, 01/11 ; vécu du directeur, classe du vendredi 31/10 | Lot « Fin de séance » : brancher, pas réécrire (`BornesChrono.depuisFenetre`, comme `journee_page.dart:700`) | ouvert |
| FN-024 | Salle | À la fin (`ended_at` + `grace_after_end_minutes` = 15, RPC `autoriser_jeton_video`, migration 0040), l'écran ne dit pas que la séance est terminée : le client ne connaît que quittée, connexion perdue et retiré (`salle_page.dart:391-394`, `766`). | Bloquant | Lecture du code par le garde-cap, 01/11 ; vécu du directeur, 31/10 (séance finie sans que personne le sache). Non prouvé : la cause physique de la sortie du groupe (durée du jeton `video_config.token_ttl_seconds`, sinon 300 s ; LiveKit ; clôture automatique toutes les 15 min) ; capture demandée au directeur | Lot « Fin de séance » : un état « Séance terminée » annoncé par le serveur, avec l'heure de fin et la suite (cahier pour l'enseignant, Travail à préparer pour l'élève), textes `salle.fin.*` existants | ouvert |
| FN-025 | Salle, ré-entrée | Le refus de ré-entrée ne dit pas pourquoi : `supabase/functions/create-room-token/index.ts:88-89` change toute exception SQL (« salle fermee », « salle pas encore ouverte », « seance close », « non inscrit a cette seance ») en un seul 403 « acces a la salle refuse » ; le client affiche `salle.refusAcces` « Ce cours ne vous est pas ouvert en ce moment » pour tout. | Bloquant | Lecture du code par le garde-cap, 01/11 ; vécu du directeur, 31/10 (tout le monde réessaie d'entrer, refus sans raison) | Lot « Fin de séance » : renvoyer la raison et l'heure de fin ; texte du type « La séance s'est terminée à {heure}. La salle a fermé un quart d'heure après. » | ouvert |
| FN-026 | Textes de la salle | `salle.refusAccesDetail` dit « dix minutes avant », alors que la configuration dit 20 (`join_window_minutes`, `0030_tc_socle.sql:34`) ; `salle.expiree` n'est utilisé nulle part. | Gênant (« Majeur » pour le garde-cap ; l'échelle du registre n'a pas ce mot) | Lecture du code par le garde-cap, 01/11 | Lot « Fin de séance » | ouvert |
| FN-027 | Carte de classe (Aujourd'hui, Accueil de la famille, Journée de l'enseignant) | Pendant la séance, aucun temps restant ; après, aucun état « Séance terminée à {heure} ». `EtatSeanceFamille.prolongee` n'a pas de compte à rebours (`seance_famille.dart:13`). | Gênant (« Majeur » pour le garde-cap) | Lecture du code par le garde-cap, 01/11 | Lot « Fin de séance » | ouvert |
| FN-028 | Notifications | Aucune notification de fin de séance : `private.notifier_classe` a 12 événements, aucun pour la fin. La spec existait avant la remise à plat (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md:121`, TUT-06). À ajouter : événement `seance_terminee`, FR et AR, **dans l'application seulement, jamais par courriel** (décision du directeur du 01/11, `DECISION-NOTIFICATIONS-COURRIEL-2026-11-01.md`), tuteur seulement si l'élève est mineur. Élève adulte ou tuteur : « La séance de {classe} du {quand} est terminée. {Travail à préparer en une ligne ; sinon : aucun travail à préparer.} » Enseignant : « La séance de {classe} du {quand} est terminée. {n} élèves présents sur {total}. Le cahier de transmission attend vos informations. » (ou « Cahier déposé, merci. »). Direction : rien de plus. Déclencheur : la clôture (`ses_cloturer_seances_echues` ou « Quitter et ouvrir le cahier »), et le dépôt du cahier pour le Travail à préparer si la notification part avant. | Bloquant | Lecture du code par le garde-cap, 01/11 ; demande du directeur, 01/11 | Lot « Fin de séance » | ouvert |
