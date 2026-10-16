# L2-V - Vérification croisée de la vague 2 (raccordements)

Vague 2. Dernier lot de la vague. Agent qui n'a écrit aucun des lots L2-01 à L2-10.

## 1. But et pourquoi

La vague 2 branche des promesses : jeton du remplaçant, aperçu KYC, file des cahiers, écran des offres, observation, matricule, réglages, Storage, annonces. Chacune a été testée par son auteur avec un faux client ou un rejeu local. Ce lot vérifie de bout en bout, sur la préversion de la PR et sur STAGING en lecture, que les écrans et le serveur se parlent, et il écrit les cinq niveaux de preuve.

## 2. Critère de réussite

C'est fini quand `docs/audit-final/verifications/L2-V-2026-10.md` contient :

1. le SHA vérifié, la liste des lots fusionnés, les migrations appliquées sur STAGING (lecture de `supabase_migrations.schema_migrations` ou `list_migrations`, en lecture seule) ;
2. le rejeu SQL complet (74 scénarios + `af_*`), nominatif ;
3. le résultat des six commandes Flutter du dépôt sur la branche, avec les totaux (`flutter test` : nombre de tests, rouges nommés ; `verifier_jetons` : nombre ; `verifier_revue` : par règle contre le socle) ; c'est ici que `MESURES` section 5.3 reçoit enfin un total définitif de `test/features` ;
4. pour chaque lot, une recette sur la préversion de la PR (URL inscrite en commentaire de la PR par `flutter-deploy.yml`) : L2-05 l'écran des offres s'ouvre et crée une offre de démonstration ; L2-07 le matricule est visible dans Mon compte de démonstration ; L2-10 pas de doublon d'annonce ; L2-03 la confirmation « cahiers envoyés » dans un test, parce que la démonstration ne met rien en file ; captures 390 et 1440 nommées `L2-V_<lot>_<largeur>_<thème>.png` ;
5. pour les lots serveur (L2-01, L2-08, L2-09), si les migrations sont appliquées sur STAGING : requêtes catalogue qui le prouvent (`pg_get_functiondef('public.autoriser_jeton_video(...)')` contient `c29_enseignant_effectif_session` ; `select * from app_config where key in (...)` ; `pg_policies` du schéma `storage`) ; sinon `testé localement` ;
6. si un compte administrateur et un compte enseignant de test sont fournis par le directeur (`rewayahacademy+direction@gmail.com`, `+enseignant`), une recette réelle : publier une offre, voir la vitrine en tant que tuteur de test, demander un horaire ; ouvrir l'aperçu d'une pièce KYC de test ; sinon le dire ;
7. la liste des défauts avec une fiche de reprise `L2-xx-reprise.md` par défaut.

## 3. Ce qu'il faut lire

- Les onze fiches `L2-*.md`, le rapport section 3 (écarts) et la matrice (lignes citées par chaque fiche).
- `docs/audit-final/MESURES-2026-10-16.md` sections 5 et 6 (état avant la vague).
- `docs/current/DESIGN-GOV-2026-09-26.md` (pour juger les captures du nouvel écran L2-05).

## 4. Fichiers autorisés et interdits

Autorisés : `docs/audit-final/verifications/L2-V-2026-10.md`, `docs/audit-final/captures/lots/L2-V_*.png`, `docs/audit-final/lots/L2-xx-reprise.md`, et une mise à jour de `docs/audit-final/MESURES-2026-10-16.md` section 5.3 (totaux définitifs).

Interdits : tout code, toute migration, STAGING en écriture, `.github/**`.

## 5. Étapes

1. Rejeu SQL complet (script de `MESURES` section 2).
2. Les six commandes Flutter sur un poste avec Flutter stable ; consigner les totaux.
3. Recette de la préversion avec Playwright (Chromium préinstallé, ne jamais lancer `playwright install`) : `localStorage presentation.vue=oui`, routes en `/#/...`, `?demo=admin` et `?demo=tuteur`, 390 x 844 et 1440 x 900, clair et sombre, arabe sur l'écran L2-05.
4. Juger l'écran L2-05 avec DESIGN-GOV : un seul bouton plein, cinq états, contrat D, K-58 sur les options, K-59 sur l'état vide, RTL propre.
5. STAGING en lecture (si accès) : les requêtes du critère 5.
6. Recette réelle (critère 6) si les mots de passe sont fournis par le directeur ; sinon écrire « non vérifiable : mot de passe non fourni ».
7. Rédiger ; une fiche de reprise par défaut.

## 6. Vérifications

- Aucune affirmation sans commande et sortie ; aucun `PASS` pour une recette non jouée.
- `git status` : seulement `docs/audit-final/`.

## 7. Pièges connus

- La préversion est compilée sans `OBSERVATION_TUTEUR_REELLE=true` tant que A-10 n'est pas appliqué : L2-06 ne se voit pas sur la préversion ; le dire plutôt que de le marquer en échec.
- L'écran des offres en démonstration ne prouve pas la vitrine réelle : seule la recette réelle (critère 6) le fait.
- `flutter test` complet dure longtemps (plus de 10 000 tests) : le lancer en arrière-plan avec un journal, lire le journal, pas la console.

## 8. Quand s'arrêter et demander

- Un lot fusionné a cassé un test d'un autre lot : s'arrêter, nommer les deux lots.
- La préversion n'a pas été déployée pour la PR : s'arrêter, c'est un problème de CI (A-10).

## 9. Commit

- Branche : `lots/L2-V-verification`, partie de `claude/backend-reprise` après fusion des lots de la vague.
- Message : `docs(audit): verification croisee de la vague 2 raccordements (L2-V)`.
- Jamais de push sur `main`. PR brouillon vers `claude/backend-reprise`.

## 10. Modèle conseillé

Sonnet ou plus. Agent différent des auteurs.

Esprit : recette de bout en bout ou rien ; une capture par affirmation visuelle ; un statut ne change qu'avec une preuve.
