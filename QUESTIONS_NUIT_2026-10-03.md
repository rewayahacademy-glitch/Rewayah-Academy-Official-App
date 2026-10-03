# Questions de la nuit du 2 au 3 octobre (directeur absent)

La session de nuit n'a attendu aucune réponse : pour chaque question, elle a pris le choix le plus sûr
et continué. Chaque ligne dit la question et le choix pris. Répondre « d'accord » ou donner l'autre choix.

## Tableau de bord en résumé (DASH-1, docs/current/DASH_STRATEGIE.md sur corrections/c2-dash1)

| # | Question | Choix pris |
|---|---|---|
| D-Q1 | Retirer du Centre de commande la longue liste « À traiter en premier », puisque chaque tuile ouvre sa propre liste ? | Oui. Les 3 dossiers les plus anciens restent dans la grande tuile, et chaque nom ouvre son propre dossier. |
| D-Q2 | La direction n'a pas de page « Planning ». | Aucun lien tant qu'elle n'existe pas ; un raccourci « Groupes » à la place. |
| D-Q3 | En Mode Accessibilité, une seule colonne simple plutôt que des tuiles de tailles variées ? | Oui (un seul ordre de lecture). |
| D-Q4 | Sur « Aujourd'hui » de l'enseignant, garder toute la journée plutôt que 3 lignes et « Voir tout » ? | Oui (la journée est le sujet de l'écran). |

## Grille Bento (BENTO-1b, branche corrections/c2-bento1b)

| # | Question | Choix pris |
|---|---|---|
| B-Q1 | Sous la tuile « Dossiers à valider », la phrase « Ouvrir la file, le plus ancien en premier. » ; sous « Demandes à trancher », « Familles et enseignants attendent une réponse. » : ces deux textes vous conviennent ? | Gardés, marqués « à faire valider ». |
| B-Q2 | Quand le texte est agrandi sur ordinateur, la grille garde 4 colonnes tant que chaque colonne a au moins 112 px × l'agrandissement. Préférez-vous passer plus tôt à 2 colonnes, avec des tuiles plus larges ? | 4 colonnes gardées (captures `docs/current/captures/BENTO-1b`). |

## Réunion des branches de rôle (INTEG-RC-1, fusion de l'accessibilité, 760802c)

| # | Question | Choix pris |
|---|---|---|
| I-Q1 | En Mode Accessibilité, le Coran revient dans la barre du bas (4 onglets), comme le dit la décision déléguée du 02/10 (« le Coran reste »). Mais votre revue (MA-NAV-1, §326 et §344) disait 3 onglets : Accueil, Ma classe, Mon espace. Lequel gardez-vous ? | 4 onglets gardés pour l'instant (décision la plus récente). Recommandation : confirmer les 4 onglets, puis corriger la revue. |
| I-Q2 | En Mode Accessibilité, quand le texte dépasse 130 %, les boutons de la salle (micro, caméra) n'affichent plus le mot d'état (« Micro ouvert ») : il n'apparaît qu'au survol. La décision déléguée disait « le mot d'état reste ». | Pas tranché. Essai fait puis retiré : garder le mot fait déborder la salle à 390 px ×2 (34 à 51 px) et dépasse la hauteur demandée par MA-CMD-1 (292 au lieu de 253). Deux choix, mesures dans `docs/current/REVUE-DIRECTEUR-2026-10.md` (« Décision à valider », branche corrections/c1-integ @ 4a4fbe7) : (a) le mot reste et les commandes passent sur deux rangées ; (b) MA-CMD-1 l'emporte, le mot est dans l'infobulle et lu par le lecteur d'écran. Recommandation : (a). |

## Cahier de l'enseignant (EN-7c-200, EN-7c-SUGG-T, branche commune @ d57ed2b1)

| # | Question | Choix pris |
|---|---|---|
| C-Q1 | La feuille « Ajuster » disait « Ajustez la suggestion » alors qu'aucun devoir n'est jamais suggéré (l'application ne connaît que le devoir de la séance précédente). D'où doit venir une vraie suggestion : recopier le devoir précédent, ou une proposition préparée côté serveur (d'après la page de lecture ou le plan de cours) ? | Aucune des deux pour l'instant : la phrase ne s'affiche que pour une vraie suggestion. Recommandation : une proposition préparée côté serveur, au moment du branchement (BR-1), plutôt que recopier le devoir précédent. |
| C-Q2 | Quand l'enseignant rouvre la feuille sur un devoir qu'il a déjà écrit, la phrase affichée est « Vous avez déjà noté ce devoir. Modifiez-le ou laissez-le tel quel. » Elle vous convient ? | Gardée, marquée « à faire valider ». |

## Finance (FI-1a, 17_finance/UX_REVIEW_08_FINANCE.md)

| # | Question | Choix pris |
|---|---|---|
| Q-FI-1 | Que contient l'onglet « Apprentissage » de la fiche élève (maquette 02) ? | Ne pas l'afficher : deux onglets, Général et Finances. |
| Q-FI-2 | Foyer : « Recharger plusieurs profils » devient le seul bouton principal, « Ajouter un profil élève » passe en second ? | Oui (guide §5.1). |
| Q-FI-3 | Ordinateur : retirer le panneau « Actions rapides » (doublon de Recharger, et « Gérer les accès » trompeur) ? | Le retirer, place aux dernières transactions. |
| Q-FI-4 | « Paiement sécurisé et chiffré » seulement quand le vrai paiement sera branché ? | Retiré pour cette vague. |
| Q-FI-5 | Nom de la page : « Recharge » ou « Paiement du foyer » ? | « Recharge » partout. |
| Q-FI-6 | Bandeau « Accès à régulariser » sans croix tant que ce n'est pas réglé ? | Sans croix. |
| Q-FI-7 | Garder les compteurs du Foyer retirés par la vague Élèves adultes ? | Les garder (guide §5.1). |
| Q-FI-8, Q-FI-9 | Voir le document (répétition « Paiements du mois », refus faits sans question). | Choix écrits dans le document. |

| Q-FI-10 | Revenus de l'enseignant : on les ouvre depuis le Profil (revue) ou depuis le Compte (découpage) ? | Pas tranché ; recommandation : depuis le Profil, comme la revue. |
| X-1 à X-12 | Douze points où la revue Finance contredit le plan Finance (teinte de profil, confettis, « groupe » ou « classe », etc.). | Rien n'est tranché : liste dans `17_finance/00_REPRISE.md` §4 bis D, chaque point avec les deux versions. |

Toujours en attente (déjà posées) : les 3 maquettes Finance manquantes (A-q-FI-1), le business plan (A-q-FI-2).

## Supports du tableau (TB-1a, 18_supports_tableau/UX_REVIEW_TB.md)

| # | Question | Choix pris |
|---|---|---|
| A-q-TB-1 (déjà posée) | Panneau « Commandes » : deux onglets « Support / Outils » comme les images, ou une seule liste comme le plan ? | Pas tranché (TB-4 et TB-7b attendent). Recommandation : deux onglets, Bibliothèque en tête de « Support », Pointeur en tête de « Outils », liste simple pour l'élève. |
