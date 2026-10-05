# Prompt prêt à transmettre à Claude Code - remise à plat contrôlée

Tu es l'intégrateur du dépôt Rewayah existant. D'autres agents peuvent encore travailler sur des branches ou worktrees. Ta mission : installer les cinq spécifications canoniques jointes (`00` à `04`), raccourcir les instructions d'agent, inventorier et traiter les références historiques, clarifier les branches et réparer la chaîne de déploiement automatique Vercel après les push sur `main`.

## Directives impératives
1. Commence par `00_LIRE_D_ABORD.md`, puis `04_EXECUTION_GIT_CI_ET_MIGRATION.md`. Lis les autres documents uniquement par besoin du lot. Inspecte le dépôt réel avant toute modification et annonce les conflits entre les specs et le code ; n'efface jamais un fait historique utile ni le travail d'un agent actif.
2. Fais un inventaire lisible des worktrees, branches, PR, fichiers d'instructions, mémoires, docs, workflows, projet Vercel et état de CORE24. Identifie chaque élément par chemin ou branche et statut. Le rapport CORE24 indique que `integration/core24-classes-v2` à `e8beeb7a` n'est pas prêt à l'intégration ; retrouve le rapport et vérifie l'état depuis.
3. Crée une branche documentaire depuis la base stable. Ajoute les cinq specs sous `docs/current/`, remplace `CLAUDE.md` et les mémoires d'instructions actives par des index concis. Répare leurs liens entrants. Archive ou retire seulement les anciens documents clairement identifiés, après avoir vérifié qu'ils n'apportent aucune décision inédite. Ne supprime pas « TOUT » littéralement : préserve code, migrations, secrets configurés, historique Git, logs utiles et travail non fusionné. Une ancienne règle qui contredit `00` à `04` ne doit plus être chargée comme instruction active.
4. Analyse la cause précise du non déploiement `main -> Vercel` dans les logs et paramètres effectifs. Corrige le workflow, l'intégration Git, le build ou la configuration réellement fautive. Prouve le build local, l'aperçu puis le déploiement d'un commit `main` lorsque l'accès et le flux d'intégration le permettent. Si le dépôt ou la console n'est pas accessible, rédige la preuve manquante et la commande ou action minimale ; ne prétends pas avoir corrigé.
5. Produis le tableau complet des branches candidates au nettoyage. Aucune suppression distante, aucun `reset --hard`, aucun force push et aucun effacement de mémoire non sauvegardée avant mon accord explicite sur la liste exacte des cibles. Si tu as déjà une autorisation spécifique et vérifiable dans cette session, applique-la à son seul périmètre. Après accord, supprime uniquement les branches prouvées intégrées et conservées par l'historique de `main`, puis vérifie l'état final.
6. Ne fusionne aucune feature hors périmètre. Priorité à l'application existante, au parcours fonctionnel et à l'absence de régression. Ne recopie aucun secret dans un rapport. Un agent propriétaire d'un fichier ne doit pas être contourné pendant son travail.

## Livrables attendus
- PR ou diff documentaire avec index court et documents canoniques, liens réparés et inventaire des historiques archivés.
- Diagnostic CI fondé sur commit et logs, correctif, tests, preuve du déploiement ou blocage nommé.
- Tableau de branches classées « conserver », « intégration à terminer », « suppression proposée après accord ».
- Rapport final : ce qui était déjà présent, ce qui a changé, preuves, risques, actions en attente ; chaque état distingué entre spécifié, codé, testé et déployé.

Arrête-toi avant toute suppression irréversible dont la liste n'a pas été approuvée. N'attends pas cette approbation pour finir les inventaires, la documentation, le correctif CI testable et les autres opérations réversibles.
