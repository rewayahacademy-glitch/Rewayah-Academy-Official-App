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
| FN-002 | Cahier, séance remplacée | Le remplaçant ne peut déposer aucun cahier : la RLS de `lesson_reports`, `brouillon_cahier` et `mes_rapports_en_attente` ne lisent que le titulaire. | Bloquant | Prouvé sur la pile locale, 31/10 | Lot CAHIER-REMPLACANT (session du 31/10) | ouvert |
| FN-003 | Présence aux minutes (`private.pai_minutes_enseignant`, 20261102900000) | Un enseignant entré sans jamais sortir compte jusqu'à 1799 minutes pour une séance d'1 h : affichage faux, argent juste (paie plafonnée à la durée prévue). | Gênant | `scenarios_ses_cloture_auto`, cas 4, pile locale, 31/10 | Lot à lancer : nouvelle migration bornant à la fin prévue plus la grâce | ouvert |
| FN-004 | Tests SQL | `scenarios_fac_e_paie_par_eleve` échoue sur `main` (« pending trigger events »). | Gênant | Pile locale, 31/10 (agent de la PR 100) | À attribuer | ouvert |
| FN-005 | Tests SQL | `scenarios_af_liste_blanche_volatiles` échoue sur `main` (`ajouter_creneau_classe_admin`, `seance_a_rejoindre`). | Gênant | Pile locale, 31/10 (agent de la PR 106) | À attribuer | ouvert |
| FN-006 | Aujourd'hui (enseignant), séances qui s'enchaînent | La séance précédente reste « Séance en direct · Temps prévu écoulé » jusqu'à la clôture automatique ; la suivante n'est proposée que dans Classes ; « Quitter et ouvrir le cahier » laisse la séance en cours. | Bloquant | Parcours 8 joué sur la pile locale, 31/10 21:24 (PR 107) | Lot à lancer après la PR 100 | ouvert |
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
