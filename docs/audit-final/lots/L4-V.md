# L4-V - Vérification croisée de la vague 4 (finition visuelle) et clôture de l'audit

Vague 4. Dernier lot du plan. Agent qui n'a écrit aucun des lots L4-01 à L4-06.

## 1. But et pourquoi

La vague 4 touche ce que les familles voient. La vérification est visuelle, par rôle, à 390 et 1440, clair et sombre, en arabe et en texte agrandi, contre DESIGN-GOV et les consignes K-54 à K-59. Elle clôt aussi l'audit : elle met la matrice de conformité à jour (statuts qui changent avec preuve) et écrit la page de synthèse finale.

## 2. Critère de réussite

C'est fini quand `docs/audit-final/verifications/L4-V-2026-10.md` contient :

1. SHA, lots fusionnés, rejeu SQL complet, six commandes Flutter avec totaux ; `verifier_jetons` 0 ; `verifier_revue` 0 au-dessus du socle, socle en baisse (diff) ;
2. pour chaque écran touché par la vague (connexion, Mon compte tuteur, Classes à ouvrir, Tirage, accueil famille, Ajouter un profil, Pédagogie) : captures 390 et 1440, clair et sombre, arabe à 390, texte x2 à 320 (par test de capture), et un jugement en une ligne par règle : un seul bouton plein, états complets, K-58, K-59, RTL, hiérarchie ;
3. une comparaison avant/après avec les captures de `docs/audit-final/captures/` (16/10) ;
4. la mise à jour de `docs/audit-final/MATRICE-CONFORMITE.md` : chaque ligne dont le statut change reçoit sa nouvelle preuve (nom du scénario, du test, de la capture) et son niveau (`testé localement` ou `testé sur staging`) ; aucune ligne ne change sans preuve ; les totaux de la section 1 du rapport sont recalculés et une note datée est ajoutée en tête du rapport (« Mise à jour L4-V du <date> : N conformes, ... ») sans réécrire le corps du rapport du 16/10 ;
5. la liste des arbitrages du directeur restés sans réponse (A-01 à A-10), pour que rien ne se perde ;
6. défauts et fiches de reprise `L4-xx-reprise.md`.

## 3. Ce qu'il faut lire

Les sept fiches `L4-*.md` ; `docs/AUDIT-FINAL-2026-10.md` sections 1, 2, 6, 7 ; `docs/audit-final/MATRICE-CONFORMITE.md` ; `DESIGN-GOV-2026-09-26.md` ; K-54 à K-59, K-42, K-55 ; `docs/audit-final/captures/`.

## 4. Fichiers autorisés et interdits

Autorisés : `docs/audit-final/verifications/L4-V-2026-10.md`, `docs/audit-final/captures/lots/L4-V_*.png`, `docs/audit-final/MATRICE-CONFORMITE.md` (statuts avec preuve), `docs/AUDIT-FINAL-2026-10.md` (note datée en tête et totaux de la section 1 seulement), fiches de reprise.

Interdits : code, migrations, STAGING en écriture, `.github/**`, le corps du rapport du 16/10.

## 5. Étapes

1. Rejeu SQL complet ; six commandes Flutter ; outils.
2. Préversion : Playwright, 390 x 844, 1440 x 900, clair, sombre, `ar`, `?demo=tuteur`, `?demo=admin`, `localStorage presentation.vue=oui`.
3. Texte x2 à 320 : par les tests de capture du dépôt (`test/core` ; chercher `textScaler` 2.0).
4. Juger chaque écran avec la grille (critère 2) ; écrire une ligne par règle, pas un paragraphe.
5. Mettre à jour la matrice ligne par ligne avec preuve ; recalculer les totaux ; note datée en tête du rapport.
6. Lister les arbitrages sans réponse.
7. Rédiger ; fiches de reprise si besoin.

## 6. Vérifications

- Chaque changement de statut de la matrice cite une preuve nommée.
- Aucun tiret cadratin, aucun symbole de section, aucune flèche typographique, aucun emoji dans `docs/AUDIT-FINAL-2026-10.md`, `docs/audit-final/MATRICE-CONFORMITE.md` et `docs/audit-final/verifications/L4-V-2026-10.md` (vérifier par `grep -c` sur ces trois caractères : 0 partout).
- `git status` : `docs/audit-final/` et `docs/AUDIT-FINAL-2026-10.md` seulement.

## 7. Pièges connus

- Un écran conforme en clair peut casser en sombre (contraste d'une puce active) : les deux thèmes à chaque fois.
- Le texte x2 ne se voit pas sur la préversion : seul le test de capture le prouve ; ne pas écrire « vérifié » sans lui.
- Les totaux de la section 1 du rapport (43 / 47 / 19 / 20 / 3) datent du 16/10 : les recalculer depuis la matrice, pas de tête.

## 8. Quand s'arrêter et demander

Une ligne de la matrice devrait passer `conforme` mais la seule preuve est une démonstration : laisser `partiel`, le dire ; un statut ne change qu'avec une preuve.

## 9. Commit

Branche `lots/L4-V-verification`, partie de `claude/backend-reprise`. Message `docs(audit): verification croisee de la vague 4 et mise a jour de la matrice (L4-V)`. Jamais `main`.

## 10. Modèle conseillé

Sonnet ou plus ; agent différent des auteurs.

Esprit : regarder chaque écran dans les deux thèmes et les deux sens ; une preuve par statut ; la synthèse recalculée, pas réécrite.
