# L1-V - Vérification croisée de la vague 1 (sécurité)

Vague 1. Dernier lot de la vague. Confié à un agent qui n'a écrit aucun des lots L1-01 à L1-09.

## 1. But et pourquoi

Un lot de sécurité qui se vérifie lui-même ne prouve rien. Ce lot rejoue tout de zéro, relit chaque migration de la vague avec les yeux d'un attaquant, et écrit un bilan avec les cinq niveaux de preuve (`spécifié` / `présent dans le code` / `testé localement` / `testé sur staging` / `déployé`). Il ne corrige rien : il ouvre une fiche de reprise par défaut trouvé.

## 2. Critère de réussite

C'est fini quand `docs/audit-final/verifications/L1-V-2026-10.md` existe et contient :

1. le SHA de la branche vérifiée et la liste des lots fusionnés ;
2. le rejeu complet sur PostgreSQL 17 neuf : nombre de migrations, 74 scénarios avec PASS/FAIL nominatifs, et la liste blanche L1-09 ;
3. pour chaque P0 et P1 du rapport (P0-1, P0-2, P1-1 à P1-7), une ligne : faille, lot, preuve rejouée (nom du scénario et extrait du message), statut `testé localement` ; `testé sur staging` seulement si une migration a été appliquée sur STAGING par celui qui en a le droit, avec la requête catalogue qui le prouve ;
4. une tentative de contournement par P0, écrite et jouée : par exemple pour P0-1, appeler `record_session_event` sous `service_role` depuis un scénario pour vérifier que le serveur peut encore, puis sous `authenticated` avec un jeton `admin` valide pour vérifier qu'il ne peut plus ; pour P0-2, un jeton `student` qui essaie `wallets`, `mes_seances_v`, `lesson_reports`, `student_profiles` en lecture et en écriture ;
5. la liste des défauts trouvés, chacun avec le lot responsable et une fiche de reprise `docs/audit-final/lots/L1-xx-reprise.md` (même structure que les fiches de la vague) ;
6. une ligne « Rien à reprendre » si c'est le cas, avec les preuves qui l'autorisent.

## 3. Ce qu'il faut lire

- `docs/AUDIT-FINAL-2026-10.md` section 4 (P0 à P3) et section 4.5 (ce qui était déjà sain, à ne pas casser).
- `docs/audit-final/MESURES-2026-10-16.md` sections 2 et 3 (état avant la vague).
- Les neuf fiches `docs/audit-final/lots/L1-01.md` à `L1-09.md` et leurs migrations `supabase/migrations/20261017100*_af_l1_*.sql`.
- `supabase/tests/scenarios_af_*.sql` (les nouveaux scénarios).

## 4. Fichiers autorisés et interdits

Autorisés : `docs/audit-final/verifications/L1-V-2026-10.md` (nouveau), `docs/audit-final/lots/L1-xx-reprise.md` (nouveaux, si défaut), un scénario de contournement `supabase/tests/scenarios_af_l1_v_contournements.sql` (nouveau, backend : à faire écrire par Codex si l'agent est une session Claude).

Interdits : toute migration, tout fichier de `lib/`, `.github/`, STAGING en écriture.

## 5. Étapes

1. `git fetch origin claude/backend-reprise && git log --oneline -15 origin/claude/backend-reprise` : noter le SHA et vérifier que les lots L1-01 à L1-09 y sont (messages de commit `(L1-0x`).
2. Rejeu complet sur PostgreSQL 17 neuf avec le script de `MESURES` section 2 (stub, migrations, 15 scénarios CI en suite, puis chaque scénario sur base neuve). Consigner les trois journaux.
3. Pour chaque fiche, vérifier que le scénario annoncé existe, qu'il passe, et qu'il ÉCHOUE quand on rejoue la base sans la migration du lot (`psql -f` de toutes les migrations sauf celle du lot : `ls supabase/migrations/*.sql | grep -v af_l1_0x`). Un scénario qui passe sans la migration ne prouve rien : défaut à noter.
4. Relire chaque migration avec trois questions : la garde est-elle positive (`coalesce(... and ..., false)`) ; `search_path = ''` sur toute fonction DEFINER ; la fonction ou la policy réduit-elle un droit sans en ouvrir un autre (comparer `has_function_privilege` et `pg_policies` avant et après pour les objets touchés).
5. Écrire et jouer le scénario de contournement (critère 4). Pour P0-2, essayer aussi un jeton `student` avec un `household_id` forgé dans les claims (le hook pose le vrai, mais le test prouve que les policies ne font pas confiance au seul `household_id`).
6. Comparer avec STAGING en lecture seule, si l'accès est donné : `select proname, has_function_privilege('authenticated', oid, 'execute') from pg_proc where proname in ('record_session_event','log_sensitive_access','materialiser_seances')` et `select policyname, qual from pg_policies where policyname in (...)`. Si les migrations n'ont pas été appliquées sur STAGING, écrire `testé localement` et rien d'autre.
7. Rédiger le bilan ; pour chaque défaut, une fiche de reprise.

## 6. Vérifications

- Le bilan ne contient aucun `PASS` sans le nom du scénario et la ligne de journal.
- Aucun fichier modifié hors `docs/audit-final/` (et le scénario de contournement) : `git status`.
- Aucune commande Flutter (la vague 1 est SQL).

## 7. Pièges connus

- Un scénario qui passe « avant » et « après » la migration ne teste rien : c'est le défaut le plus fréquent d'une suite SQL de refus, parce que le stub ne donne pas les privilèges de Supabase ; L1-09 est censé l'avoir corrigé, le vérifier en premier.
- Ne pas confondre `42501` (`insufficient_privilege`) et un `row_count = 0` : les deux sont des refus valides, mais un `update` qui rend 0 ligne sans erreur est le comportement REST ; un `select` qui rend 0 ligne alors qu'il devrait en rendre une pour un rôle légitime est une régression.
- `b09_remplacements.sql:106` est rouge avant la vague 2 (L2-01) : attendu, à noter comme tel.

## 8. Quand s'arrêter et demander

- Une migration de la vague ouvre un droit qui n'existait pas (étape 4) : s'arrêter, le signaler avant de rédiger.
- STAGING diffère du rejeu local sur un objet touché par la vague alors que la migration y est marquée appliquée : s'arrêter.

## 9. Commit

- Branche : `lots/L1-V-verification`, partie de `claude/backend-reprise` après fusion des neuf lots.
- Message : `docs(audit): verification croisee de la vague 1 securite (L1-V)`.
- Jamais de push sur `main`. PR brouillon vers `claude/backend-reprise`.

## 10. Modèle conseillé

Sonnet ou plus : la relecture adversariale ne se délègue pas à Haiku. Agent différent de tous les auteurs de la vague.

Esprit : chercher à casser avant de valider ; une preuve est une commande et sa sortie ; un statut ne change qu'avec une preuve.
